from django.db import models
from django.contrib.auth.models import AbstractUser


class Utilisateur(AbstractUser):
    ROLES = [
        ('touriste',    'Touriste'),
        ('proprietaire','Propriétaire de site'),
        ('admin',       'Administrateur'),
    ]
    telephone = models.CharField(max_length=20, blank=True)
    photo     = models.ImageField(upload_to='utilisateurs/', blank=True, null=True)
    role      = models.CharField(max_length=20, choices=ROLES, default='touriste')

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"

    @property
    def est_admin(self):
        return self.role == 'admin'

    @property
    def est_proprietaire(self):
        return self.role == 'proprietaire'

    @property
    def est_touriste(self):
        return self.role == 'touriste'

# ─────────────────────────────────────────
# RÉGION DE CÔTE D'IVOIRE
# ─────────────────────────────────────────
class Region(models.Model):
    nom         = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.nom


# ─────────────────────────────────────────
# CATÉGORIE DE SITE TOURISTIQUE
# ─────────────────────────────────────────
class Categorie(models.Model):
    nom        = models.CharField(max_length=100)
    icone      = models.CharField(max_length=50, blank=True)  # ex: "beach", "museum"

    def __str__(self):
        return self.nom


# ─────────────────────────────────────────
# SITE TOURISTIQUE
# ─────────────────────────────────────────
class SiteTouristique(models.Model):
    nom          = models.CharField(max_length=200)
    description  = models.TextField()
    region       = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='sites')
    categorie    = models.ForeignKey(Categorie, on_delete=models.SET_NULL, null=True, related_name='sites')
    #  Lien vers le propriétaire
    proprietaire = models.ForeignKey(
        'Utilisateur',
        on_delete=models.CASCADE,
        related_name='mes_sites',
        null=True, blank=True,
        limit_choices_to={'role': 'proprietaire'}
    )
    adresse      = models.CharField(max_length=255)
    latitude     = models.DecimalField(max_digits=9, decimal_places=6)
    longitude    = models.DecimalField(max_digits=9, decimal_places=6)
    prix_entree  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    image        = models.ImageField(upload_to='sites/', blank=True, null=True)
    note_moyenne = models.FloatField(default=0.0)
    est_actif    = models.BooleanField(default=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nom

    def mettre_a_jour_note(self):
        avis = self.avis.all()
        if avis.exists():
            self.note_moyenne = sum(a.note for a in avis) / avis.count()
            self.save()

# ─────────────────────────────────────────
# PHOTOS D'UN SITE
# ─────────────────────────────────────────
class PhotoSite(models.Model):
    site  = models.ForeignKey(SiteTouristique, on_delete=models.CASCADE, related_name='photos')
    image = models.ImageField(upload_to='sites/photos/')
    legende = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return f"Photo de {self.site.nom}"


# ─────────────────────────────────────────
# AVIS / COMMENTAIRE
# ─────────────────────────────────────────
class Avis(models.Model):
    site        = models.ForeignKey(SiteTouristique, on_delete=models.CASCADE, related_name='avis')
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE)
    note        = models.IntegerField(choices=[(i, i) for i in range(1, 6)])  # 1 à 5
    commentaire = models.TextField()
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('site', 'utilisateur')  # 1 avis par user par site

    def __str__(self):
        return f"Avis de {self.utilisateur.username} sur {self.site.nom}"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self.site.mettre_a_jour_note()  # recalcule la note du site


# ─────────────────────────────────────────
# RÉSERVATION
# ─────────────────────────────────────────
class Reservation(models.Model):
    STATUTS = [
        ('en_attente',  'En attente'),
        ('confirmee',   'Confirmée'),
        ('annulee',     'Annulée'),
        ('terminee',    'Terminée'),
    ]
    utilisateur      = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='reservations')
    site             = models.ForeignKey(SiteTouristique, on_delete=models.CASCADE, related_name='reservations')
    date_visite      = models.DateField()
    nombre_personnes = models.PositiveIntegerField(default=1)
    montant_total    = models.DecimalField(max_digits=10, decimal_places=2)
    statut           = models.CharField(max_length=20, choices=STATUTS, default='en_attente')
    created_at       = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Reservation {self.id} - {self.utilisateur.username} -> {self.site.nom}" #  Utilisation de -> au lieu de →

    def save(self, *args, **kwargs):
        # Calcul automatique du montant
        self.montant_total = self.site.prix_entree * self.nombre_personnes
        super().save(*args, **kwargs)


# ─────────────────────────────────────────
# PAIEMENT
# ─────────────────────────────────────────
class Paiement(models.Model):
    STATUTS = [
        ('en_attente', 'En attente'),
        ('succes',     'Succès'),
        ('echec',      'Échec'),
        ('rembourse',  'Remboursé'),
    ]
    MOYENS = [
        ('orange_money', 'Orange Money'),
        ('mtn_momo',     'MTN MoMo'),
        ('wave',         'Wave'),
        ('moov_money',        'Moov Money'),
    ]
    reservation      = models.OneToOneField(Reservation, on_delete=models.CASCADE, related_name='paiement')
    montant          = models.DecimalField(max_digits=10, decimal_places=2)
    moyen_paiement   = models.CharField(max_length=20, choices=MOYENS)
    statut           = models.CharField(max_length=20, choices=STATUTS, default='en_attente')
    transaction_id   = models.CharField(max_length=255, blank=True)  # ID retourné par CinetPay
    created_at       = models.DateTimeField(auto_now_add=True)
    updated_at       = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Paiement {self.transaction_id} - {self.statut}"
