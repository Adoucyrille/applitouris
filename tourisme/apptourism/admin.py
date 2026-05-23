from django.contrib import admin
from .models import (
    Utilisateur, Region, Categorie,
    SiteTouristique, PhotoSite,
    Avis, Reservation, Paiement
)

admin.site.register(Utilisateur)
admin.site.register(Region)
admin.site.register(Categorie)
admin.site.register(SiteTouristique)
admin.site.register(PhotoSite)
admin.site.register(Avis)
admin.site.register(Reservation)
admin.site.register(Paiement)
