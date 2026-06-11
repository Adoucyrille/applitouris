# tourisme/urls.py
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [

    # ── Authentification ──────────────────────────────────
    path('auth/inscription/',  views.VueInscription.as_view(),  name='inscription'),
    path('auth/connexion/',    views.VueConnexion.as_view(),    name='connexion'),
    path('auth/deconnexion/',  views.VueDeconnexion.as_view(),  name='deconnexion'),
    path('auth/profil/',       views.VueProfil.as_view(),       name='profil'),
    path('auth/refresh/',      TokenRefreshView.as_view(),      name='refresh_token'),

    # ── Régions & Catégories ──────────────────────────────
    path('regions/',           views.VueListeRegions.as_view(),    name='regions'),
    path('categories/',        views.VueListeCategories.as_view(), name='categories'),

    # ── Sites touristiques ────────────────────────────────
    path('sites/',             views.VueListeSites.as_view(),    name='liste_sites'),
    path('sites/creer/',       views.VueCreationSite.as_view(),  name='creer_site'),
    path('sites/mes-sites/',   views.VueMesSites.as_view(),      name='mes_sites'),
    path('sites/<int:pk>/',    views.VueDetailSite.as_view(),    name='detail_site'),
    path('sites/<int:pk>/avis/',    views.VueAvisSite.as_view(),     name='avis_site'),
    path('sites/<int:pk>/photos/', views.VuePhotossite.as_view(),   name='photos_site'),
    path('sites/photos/<int:pk>/', views.VueDetailPhotosite.as_view(), name='detail_photo'),

    # ── Réservations ──────────────────────────────────────
    path('reservations/',             views.VueReservations.as_view(),           name='reservations'),
    path('reservations/mes-sites/',   views.VueReservationsMesSites.as_view(),   name='reservations_mes_sites'),
    path('reservations/<int:pk>/',    views.VueDetailReservation.as_view(),      name='detail_reservation'),

   # ── Paiements ─────────────────────────────────────────────────
    path('paiements/initier/',
        views.VueInitierPaiement.as_view(),
        name='initier_paiement'),

    path('paiements/webhook/',
        views.VueWebhookCinetPay.as_view(),
        name='webhook_cinetpay'),

    path('paiements/simuler/<int:pk>/',
        views.VueSimulerPaiement.as_view(),
        name='simuler_paiement'),

    path('paiements/simuler/<int:pk>/confirmer/',
        views.VueConfirmerPaiementSimule.as_view(),
        name='confirmer_paiement'),

    path('paiements/simuler/<int:pk>/annuler/',
        views.VueAnnulerPaiementSimule.as_view(),
        name='annuler_paiement'),
    # ── Administration ────────────────────────────────────
    path('admin/utilisateurs/',    views.VueGestionUtilisateurs.as_view(), name='admin_utilisateurs'),
    path('admin/tableau-de-bord/', views.VueTableauBordAdmin.as_view(),    name='tableau_bord'),
]