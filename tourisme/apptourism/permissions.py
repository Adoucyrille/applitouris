
# Ce fichier définit les règles d'accès à l'API selon le rôle de l'utilisateur

from rest_framework.permissions import BasePermission, SAFE_METHODS


# PERMISSION 1 : ADMINISTRATEUR GÉNÉRAL
class EstAdmin(BasePermission):
    """
    Autorise uniquement les utilisateurs ayant le rôle 'admin'.
    Utilisé pour les actions critiques : gestion des utilisateurs,
    validation des sites, supervision générale de la plateforme.
    """

    message = "Accès refusé. Vous devez être administrateur pour effectuer cette action."

    def has_permission(self, request, view):
        # L'utilisateur doit être connecté ET avoir le rôle admin
        return (
            request.user.is_authenticated and
            request.user.role == 'admin'
        )


# PERMISSION 2 : PROPRIÉTAIRE DE SITE
class EstProprietaire(BasePermission):
    """
    Autorise uniquement les utilisateurs ayant le rôle 'proprietaire'.
    Utilisé pour permettre à un propriétaire d'ajouter un nouveau site
    touristique sur la plateforme.
    """

    message = "Accès refusé. Vous devez être propriétaire de site pour effectuer cette action."

    def has_permission(self, request, view):
        # L'utilisateur doit être connecté ET avoir le rôle propriétaire
        return (
            request.user.is_authenticated and
            request.user.role == 'proprietaire'
        )


# PERMISSION 3 : PROPRIÉTAIRE DE SON PROPRE SITE
class EstProprietaireDuSite(BasePermission):
    """
    Contrôle d'accès au niveau de chaque site touristique.

    Règles :
    - Tout le monde peut LIRE (GET) les sites
    - Seul le PROPRIÉTAIRE du site peut le modifier ou le supprimer
    - L'ADMIN peut tout modifier ou supprimer sans restriction
    """

    message = "Accès refusé. Vous n'êtes pas le propriétaire de ce site touristique."

    def has_permission(self, request, view):
        # L'utilisateur doit au minimum être connecté
        # (la vérification fine se fait dans has_object_permission)
        return request.user.is_authenticated

    def has_object_permission(self, request, view, obj):
        """
        Appelée automatiquement par Django REST Framework quand on accède
        à un objet spécifique (ex: /api/sites/5/).
        'obj' représente ici le site touristique concerné.
        """

        # Lecture autorisée pour tous les utilisateurs connectés
        if request.method in SAFE_METHODS:
            return True

        #  L'administrateur peut modifier ou supprimer n'importe quel site
        if request.user.role == 'admin':
            return True

        #  Le propriétaire ne peut modifier/supprimer QUE ses propres sites
        # On compare le propriétaire du site avec l'utilisateur connecté
        return obj.proprietaire == request.user


# PERMISSION 4 : LECTURE LIBRE, ÉCRITURE POUR CONNECTÉS

class LectureLibre(BasePermission):
    """
    Permission générale utilisée pour les ressources publiques
    comme la liste des sites, les avis, les régions, etc.

    Règles :
    - Lecture (GET) : accessible à tous, même sans compte
    - Écriture (POST, PUT, DELETE) : réservée aux utilisateurs connectés
    """

    message = "Accès refusé. Vous devez être connecté pour effectuer cette action."

    def has_permission(self, request, view):
        # Lecture libre sans authentification
        if request.method in SAFE_METHODS:
            return True

        # Toute modification nécessite d'être connecté
        return request.user.is_authenticated