from django.contrib import admin
from django.contrib import admin
from .models import (
    Utilisateur, Region, Categorie,
    SiteTouristique, PhotoSite,
    Avis, Reservation, Paiement,
    Hotel, Restaurant, EvenementTouristique,
    CircuitTouristique, EtapeCircuit,
    GuideTouristique, Transport
)

admin.site.register(Utilisateur)
admin.site.register(Region)
admin.site.register(Categorie)
admin.site.register(SiteTouristique)
admin.site.register(PhotoSite)
admin.site.register(Avis)
admin.site.register(Reservation)
admin.site.register(Paiement)
admin.site.register(Hotel)
admin.site.register(Restaurant)
admin.site.register(EvenementTouristique)
admin.site.register(CircuitTouristique)
admin.site.register(EtapeCircuit)
admin.site.register(GuideTouristique)
admin.site.register(Transport)
