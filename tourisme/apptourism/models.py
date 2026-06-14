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
# CIRCUIT TOURISTIQUE
# ─────────────────────────────────────────
class CircuitTouristique(models.Model):
    NIVEAUX = [
        ('facile',   'Facile'),
        ('modere',   'Modéré'),
        ('difficile','Difficile'),
    ]
    nom        = models.CharField(max_length=200)
    description= models.TextField()
    regions    = models.ManyToManyField(Region, related_name='circuits', blank=True)
    duree_jours= models.PositiveIntegerField(default=1)
    prix       = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    niveau     = models.CharField(max_length=20, choices=NIVEAUX, default='facile')
    image      = models.ImageField(upload_to='circuits/', blank=True, null=True)
    est_actif  = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nom


class EtapeCircuit(models.Model):
    """Étape ordonnée d'un circuit touristique."""
    circuit           = models.ForeignKey(CircuitTouristique, on_delete=models.CASCADE, related_name='etapes')
    site              = models.ForeignKey(SiteTouristique,    on_delete=models.CASCADE, related_name='etapes_circuit')
    ordre             = models.PositiveIntegerField()
    description_etape = models.TextField(blank=True)

    class Meta:
        ordering        = ['ordre']
        unique_together = ('circuit', 'ordre')

    def __str__(self):
        return f"{self.circuit.nom} — Étape {self.ordre} : {self.site.nom}"


# ─────────────────────────────────────────
# GUIDE TOURISTIQUE
# ─────────────────────────────────────────
class GuideTouristique(models.Model):
    utilisateur       = models.OneToOneField(
                            Utilisateur, on_delete=models.CASCADE,
                            related_name='profil_guide', null=True, blank=True
                        )
    nom               = models.CharField(max_length=100)
    prenom            = models.CharField(max_length=100)
    telephone         = models.CharField(max_length=20)
    email             = models.EmailField(blank=True)
    photo             = models.ImageField(upload_to='guides/', blank=True, null=True)
    langues_parlees   = models.CharField(max_length=255, help_text="Ex: Français, Anglais, Espagnol, Chinois, Allemand")
    regions_couvertes = models.ManyToManyField(Region, related_name='guides', blank=True)
    specialites       = models.TextField(blank=True, help_text="Ex: Nature, Histoire, Gastronomie")
    tarif_journalier  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    annees_experience = models.PositiveIntegerField(default=0)
    est_certifie      = models.BooleanField(default=False)
    est_disponible    = models.BooleanField(default=True)
    est_actif         = models.BooleanField(default=True)
    created_at        = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.prenom} {self.nom}"


# ─────────────────────────────────────────
# TRANSPORT
# ─────────────────────────────────────────
class Transport(models.Model):
    TYPES = [
        ('woro_woro',    'Woro-woro (taxi collectif)'),
        ('gbaka',        'Gbaka (minibus)'),
        ('sotra',        'SOTRA (bus urbain Abidjan)'),
        ('taxi_lagune',  'Taxi-lagune (Abidjan)'),
        ('car_interurb', 'Car interurbain (longue distance)'),
        ('bateau',       'Bateau / Pirogue'),
        ('vol_interieur','Vol intérieur'),
        ('moto',         'Moto-taxi (Zemidjan)'),
    ]
    type_transport   = models.CharField(max_length=20, choices=TYPES)
    compagnie        = models.CharField(max_length=200, blank=True)
    region_depart    = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='transports_depart')
    region_arrivee   = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='transports_arrivee')
    ville_depart     = models.CharField(max_length=100)
    ville_arrivee    = models.CharField(max_length=100)
    prix             = models.DecimalField(max_digits=10, decimal_places=2)
    duree_minutes    = models.PositiveIntegerField(help_text="Durée estimée du trajet en minutes")
    horaires         = models.TextField(blank=True, help_text="Ex: Départs à 6h, 9h, 14h")
    telephone_contact= models.CharField(max_length=20, blank=True)
    est_actif        = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.get_type_transport_display()} : {self.ville_depart} → {self.ville_arrivee}"


# ─────────────────────────────────────────
# HÉBERGEMENT (HOTEL)
# ─────────────────────────────────────────
class Hotel(models.Model):
    GAMMES = [
        ('economique', 'Économique'),
        ('standard',   'Standard'),
        ('superieur',  'Supérieur'),
        ('luxe',       'Luxe'),
    ]
    nom          = models.CharField(max_length=200)
    description  = models.TextField(blank=True)
    region       = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='hotels')
    proprietaire = models.ForeignKey(
                       'Utilisateur',
                       on_delete=models.CASCADE,
                       related_name='mes_hotels',
                       null=True, blank=True,
                       limit_choices_to={'role': 'proprietaire'}
                   )
    adresse     = models.CharField(max_length=255)
    telephone   = models.CharField(max_length=20, blank=True)
    latitude    = models.DecimalField(max_digits=9, decimal_places=6)
    longitude   = models.DecimalField(max_digits=9, decimal_places=6)
    gamme       = models.CharField(max_length=20, choices=GAMMES, default='standard')
    prix_min    = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    image       = models.ImageField(upload_to='hotels/', blank=True, null=True)
    est_actif   = models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nom


# ─────────────────────────────────────────
# RESTAURANT / GASTRONOMIE
# ─────────────────────────────────────────
class Restaurant(models.Model):
    TYPES_CUISINE = [
        ('maquis',          'Maquis (resto ivoirien typique)'),
        ('ivoirienne',      'Cuisine Ivoirienne'),
        ('garba',           'Garba (attiéké + thon)'),
        ('africaine',       'Cuisine Africaine'),
        ('libanaise',       'Cuisine Libanaise'),
        ('internationale',  'Cuisine Internationale'),
        ('rapide',          'Restauration Rapide'),
        ('fruits_mer',      'Fruits de Mer'),
        ('vegetarienne',    'Végétarienne'),
    ]
    nom          = models.CharField(max_length=200)
    description  = models.TextField(blank=True)
    region       = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='restaurants')
    proprietaire = models.ForeignKey(
                       'Utilisateur',
                       on_delete=models.CASCADE,
                       related_name='mes_restaurants',
                       null=True, blank=True,
                       limit_choices_to={'role': 'proprietaire'}
                   )
    adresse      = models.CharField(max_length=255)
    telephone    = models.CharField(max_length=20, blank=True)
    latitude     = models.DecimalField(max_digits=9, decimal_places=6)
    longitude    = models.DecimalField(max_digits=9, decimal_places=6)
    type_cuisine = models.CharField(max_length=30, choices=TYPES_CUISINE, default='ivoirienne')
    specialites  = models.TextField(blank=True)
    prix_moyen   = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    image        = models.ImageField(upload_to='restaurants/', blank=True, null=True)
    est_actif    = models.BooleanField(default=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nom


# ─────────────────────────────────────────
# ÉVÉNEMENT TOURISTIQUE
# ─────────────────────────────────────────
class EvenementTouristique(models.Model):
    TYPES = [
        ('festival',    'Festival'),
        ('masque',      'Fête des Masques'),
        ('igname',      'Fête des Ignames'),
        ('dipri',       'Fête du Dipri'),
        ('masa',        'MASA'),
        ('exposition',  'Exposition'),
        ('concert',     'Concert'),
        ('culturel',    'Événement Culturel'),
        ('sportif',     'Événement Sportif'),
        ('gastronomie', 'Événement Gastronomique'),
        ('religieux',   'Événement Religieux'),
        ('autre',       'Autre'),
    ]
    nom         = models.CharField(max_length=200)
    description = models.TextField()
    type_event  = models.CharField(max_length=20, choices=TYPES, default='culturel')
    region      = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='evenements')
    site        = models.ForeignKey(
                      SiteTouristique,
                      on_delete=models.SET_NULL,
                      null=True, blank=True,
                      related_name='evenements'
                  )
    adresse     = models.CharField(max_length=255)
    latitude    = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude   = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    date_debut  = models.DateTimeField()
    date_fin    = models.DateTimeField()
    prix_entree = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    image       = models.ImageField(upload_to='evenements/', blank=True, null=True)
    est_actif   = models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date_debut']

    def __str__(self):
        return f"{self.nom} ({self.date_debut.strftime('%d/%m/%Y')})"


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
        ('orange_money', 'Orange Money CI'),
        ('mtn_momo',     'MTN MoMo'),
        ('wave',         'Wave'),
        ('moov_africa',  'Moov Africa'),
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
