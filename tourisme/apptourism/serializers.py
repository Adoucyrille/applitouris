# tourisme/serializers.py
# Les sérialiseurs servent à deux choses :
# 1. Convertir les objets Django en JSON pour les envoyer à Flutter
# 2. Valider et convertir le JSON reçu de Flutter en objets Django

from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import (
    Utilisateur, Region, Categorie,
    SiteTouristique, PhotoSite,
    Avis, Reservation, Paiement
)


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : INSCRIPTION D'UN NOUVEL UTILISATEUR
# ─────────────────────────────────────────────────────────────
class SerialiseurInscription(serializers.ModelSerializer):
    """
    Utilisé lors de la création d'un nouveau compte.
    - Vérifie que les deux mots de passe sont identiques
    - Hache le mot de passe avant de l'enregistrer en base
    - Le champ 'role' permet de choisir entre touriste et propriétaire
    """
    mot_de_passe          = serializers.CharField(
                                write_only=True,
                                validators=[validate_password],
                                label="Mot de passe"
                            )
    confirmation_mot_de_passe = serializers.CharField(
                                write_only=True,
                                label="Confirmation du mot de passe"
                            )

    class Meta:
        modele  = Utilisateur
        model   = Utilisateur
        fields  = [
            'id', 'username', 'first_name', 'last_name',
            'email', 'telephone', 'role',
            'mot_de_passe', 'confirmation_mot_de_passe'
        ]

    def validate(self, donnees):
        """Vérifie que les deux mots de passe sont identiques"""
        if donnees['mot_de_passe'] != donnees['confirmation_mot_de_passe']:
            raise serializers.ValidationError({
                "mot_de_passe": "Les mots de passe ne correspondent pas."
            })
        return donnees

    def create(self, donnees_validees):
        """Crée l'utilisateur avec un mot de passe correctement hashé"""
        # Supprimer la confirmation car elle ne correspond à aucun champ
        donnees_validees.pop('confirmation_mot_de_passe')
        # Renommer le champ pour correspondre au modèle Django
        mot_de_passe = donnees_validees.pop('mot_de_passe')
        utilisateur  = Utilisateur.objects.create_user(
            password=mot_de_passe,
            **donnees_validees
        )
        return utilisateur


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : PROFIL UTILISATEUR
# ─────────────────────────────────────────────────────────────
class SerialiseurUtilisateur(serializers.ModelSerializer):
    """
    Utilisé pour afficher et modifier le profil d'un utilisateur.
    - Le mot de passe est exclu pour des raisons de sécurité
    - Le rôle est en lecture seule (seul l'admin peut le changer)
    - Un superutilisateur Django est automatiquement traité comme admin
    """
    role = serializers.SerializerMethodField()

    def get_role(self, obj):
        if obj.is_superuser:
            return 'admin'
        return obj.role

    class Meta:
        model  = Utilisateur
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'telephone', 'photo', 'role']
        read_only_fields = ['role']


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : RÉGION DE CÔTE D'IVOIRE
# ─────────────────────────────────────────────────────────────
class SerialiseurRegion(serializers.ModelSerializer):
    """
    Représente une région administrative de Côte d'Ivoire.
    Exemples : Abidjan, Yamoussoukro, Bouaké, Man, San-Pédro...
    """
    class Meta:
        model  = Region
        fields = ['id', 'nom', 'description']


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : CATÉGORIE DE SITE TOURISTIQUE
# ─────────────────────────────────────────────────────────────
class SerialiseurCategorie(serializers.ModelSerializer):
    """
    Représente une catégorie de site touristique.
    Exemples : Plage, Musée, Parc naturel, Monument historique...
    L'icône est le nom de l'icône Flutter (ex: 'beach_access')
    """
    class Meta:
        model  = Categorie
        fields = ['id', 'nom', 'icone']


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : PHOTO D'UN SITE TOURISTIQUE
# ─────────────────────────────────────────────────────────────
class SerialiseurPhoto(serializers.ModelSerializer):
    """
    Représente une photo associée à un site touristique.
    Un site peut avoir plusieurs photos (galerie d'images).
    """
    class Meta:
        model  = PhotoSite
        fields = ['id', 'image', 'legende']


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : AVIS — LECTURE
# ─────────────────────────────────────────────────────────────
class SerialiseurAvis(serializers.ModelSerializer):
    """
    Affiche les avis d'un site touristique.
    - Affiche le nom d'utilisateur au lieu de l'identifiant numérique
    - Utilisé pour la page de détail d'un site dans Flutter
    """
    # Afficher le nom de l'auteur lisiblement
    auteur = serializers.CharField(
        source='utilisateur.username',
        read_only=True
    )

    class Meta:
        model  = Avis
        fields = ['id', 'auteur', 'note', 'commentaire', 'created_at']


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : AVIS — CRÉATION
# ─────────────────────────────────────────────────────────────
class SerialiseurCreationAvis(serializers.ModelSerializer):
    """
    Utilisé quand un touriste soumet un avis sur un site.
    - L'auteur est automatiquement récupéré depuis le token JWT
    - Le site est récupéré depuis l'URL de la requête
    """
    class Meta:
        model  = Avis
        fields = ['note', 'commentaire']

    def create(self, donnees_validees):
        # Récupérer l'utilisateur connecté et le site depuis le contexte
        utilisateur = self.context['request'].user
        site        = self.context['site']
        return Avis.objects.create(
            utilisateur=utilisateur,
            site=site,
            **donnees_validees
        )


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : SITE TOURISTIQUE — LISTE (version allégée)
# ─────────────────────────────────────────────────────────────
class SerialiseurListeSites(serializers.ModelSerializer):
    """
    Version allégée du site touristique pour la liste et la carte.
    Flutter l'utilise sur la page d'accueil pour afficher
    les vignettes et les marqueurs sur Google Maps.
    Moins de données = chargement plus rapide sur mobile.
    """
    # Afficher les noms lisibles au lieu des identifiants
    region    = serializers.CharField(source='region.nom',    read_only=True)
    categorie = serializers.CharField(source='categorie.nom', read_only=True)

    class Meta:
        model  = SiteTouristique
        fields = [
            'id', 'nom', 'region', 'categorie',
            'image', 'note_moyenne', 'prix_entree',
            'latitude', 'longitude'
        ]


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : SITE TOURISTIQUE — DÉTAIL (version complète)
# ─────────────────────────────────────────────────────────────
class SerialiseurDetailSite(serializers.ModelSerializer):
    """
    Version complète du site avec toutes les informations.
    Flutter l'utilise sur la page de détail d'un site touristique.
    Inclut la galerie photos et tous les avis des visiteurs.
    """
    # Imbrication des sérialiseurs pour avoir les détails complets
    region       = SerialiseurRegion(read_only=True)
    categorie    = SerialiseurCategorie(read_only=True)
    photos       = SerialiseurPhoto(many=True, read_only=True)
    avis         = SerialiseurAvis(many=True, read_only=True)
    proprietaire = serializers.CharField(
                        source='proprietaire.username',
                        read_only=True
                    )

    class Meta:
        model  = SiteTouristique
        fields = [
            'id', 'nom', 'description', 'region', 'categorie',
            'proprietaire', 'adresse', 'latitude', 'longitude',
            'prix_entree', 'image', 'photos', 'note_moyenne',
            'avis', 'est_actif', 'created_at'
        ]


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : SITE TOURISTIQUE — CRÉATION / MODIFICATION
# ─────────────────────────────────────────────────────────────
class SerialiseurCreationSite(serializers.ModelSerializer):
    """
    Utilisé par le propriétaire pour ajouter ou modifier un site.
    - Le propriétaire est automatiquement assigné via le token JWT
    - Flutter envoie un formulaire avec ces champs
    """
    class Meta:
        model  = SiteTouristique
        fields = [
            'nom', 'description', 'region', 'categorie',
            'adresse', 'latitude', 'longitude',
            'prix_entree', 'image'
        ]

    def create(self, donnees_validees):
        """Assigne automatiquement le propriétaire connecté au nouveau site"""
        proprietaire = self.context['request'].user
        return SiteTouristique.objects.create(
            proprietaire=proprietaire,
            **donnees_validees
        )


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : RÉSERVATION — LECTURE
# ─────────────────────────────────────────────────────────────
class SerialiseurReservation(serializers.ModelSerializer):
    """
    Affiche les détails d'une réservation.
    Flutter l'utilise dans la page "Mes réservations" du touriste.
    """
    # Afficher les noms lisibles au lieu des identifiants
    site                  = serializers.CharField(source='site.nom',                read_only=True)
    utilisateur           = serializers.CharField(source='utilisateur.username',    read_only=True)
    telephone_utilisateur = serializers.CharField(source='utilisateur.telephone',   read_only=True)

    class Meta:
        model  = Reservation
        fields = [
            'id', 'utilisateur', 'telephone_utilisateur', 'site', 'date_visite',
            'nombre_personnes', 'montant_total', 'statut', 'created_at'
        ]


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : RÉSERVATION — CRÉATION
# ─────────────────────────────────────────────────────────────
class SerialiseurCreationReservation(serializers.ModelSerializer):
    """
    Utilisé quand un touriste effectue une réservation.
    - L'utilisateur est récupéré automatiquement via le token JWT
    - Le montant total est calculé automatiquement
    """
    class Meta:
        model  = Reservation
        fields = ['site', 'date_visite', 'nombre_personnes']

    def create(self, donnees_validees):
        """Crée la réservation avec calcul automatique du montant"""
        utilisateur  = self.context['request'].user
        site         = donnees_validees['site']
        nb_personnes = donnees_validees['nombre_personnes']

        # Calcul automatique : prix du site × nombre de personnes
        montant_total = site.prix_entree * nb_personnes

        return Reservation.objects.create(
            utilisateur=utilisateur,
            montant_total=montant_total,
            **donnees_validees
        )


# ─────────────────────────────────────────────────────────────
# SÉRIALISEUR : PAIEMENT
# ─────────────────────────────────────────────────────────────
class SerialiseurPaiement(serializers.ModelSerializer):
    """
    Affiche et crée les paiements liés à une réservation.
    - Le statut est mis à jour automatiquement par le webhook CinetPay
    - Le transaction_id est l'identifiant unique retourné par CinetPay
      après que le touriste a payé via Orange Money / MTN MoMo / Wave
    """
    class Meta:
        model  = Paiement
        fields = [
            'id', 'reservation', 'montant', 'moyen_paiement',
            'statut', 'transaction_id', 'created_at'
        ]
        # Ces champs sont mis à jour uniquement par CinetPay via webhook
        # Flutter ne peut pas les modifier directement
        read_only_fields = ['statut', 'transaction_id']