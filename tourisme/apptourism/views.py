# apptourism/views.py
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404
from datetime import date, datetime, timedelta, timezone as dt_timezone
import math
from .models import (
    Utilisateur, Region, Categorie,
    SiteTouristique, PhotoSite, Avis, Reservation, Paiement,
    Hotel, Restaurant, EvenementTouristique,
    CircuitTouristique, GuideTouristique, Transport
)
from .serializers import (
    SerialiseurInscription, SerialiseurUtilisateur,
    SerialiseurRegion, SerialiseurCategorie,
    SerialiseurListeSites, SerialiseurDetailSite,
    SerialiseurCreationSite, SerialiseurPhoto,
    SerialiseurAvis, SerialiseurCreationAvis,
    SerialiseurReservation, SerialiseurCreationReservation,
    SerialiseurPaiement,
    SerialiseurHotel, SerialiseurRestaurant, SerialiseurEvenement,
    SerialiseurCircuit, SerialiseurGuide, SerialiseurTransport
)
from .permissions import (
    EstAdmin, EstProprietaire,
    EstProprietaireDuSite, LectureLibre
)


# ═══════════════════════════════════════════════
# SECTION 1 : AUTHENTIFICATION
# ═══════════════════════════════════════════════

class VueInscription(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serialiseur = SerialiseurInscription(data=request.data)
        if serialiseur.is_valid():
            utilisateur = serialiseur.save()
            refresh = RefreshToken.for_user(utilisateur)
            return Response({
                "message"       : "Compte créé avec succès.",
                "utilisateur"   : SerialiseurUtilisateur(utilisateur, context={'request': request}).data,
                "access_token"  : str(refresh.access_token),
                "refresh_token" : str(refresh),
            }, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


class VueConnexion(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return Response(
                {"erreur": "Veuillez fournir un nom d'utilisateur et un mot de passe."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            utilisateur = Utilisateur.objects.get(username=username)
        except Utilisateur.DoesNotExist:
            return Response(
                {"erreur": "Nom d'utilisateur ou mot de passe incorrect."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not utilisateur.check_password(password):
            return Response(
                {"erreur": "Nom d'utilisateur ou mot de passe incorrect."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(utilisateur)
        return Response({
            "message"       : "Connexion réussie.",
            "utilisateur"   : SerialiseurUtilisateur(utilisateur, context={'request': request}).data,
            "access_token"  : str(refresh.access_token),
            "refresh_token" : str(refresh),
        }, status=status.HTTP_200_OK)


class VueDeconnexion(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh_token')
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Déconnexion réussie."})
        except Exception:
            return Response(
                {"erreur": "Token invalide ou déjà expiré."},
                status=status.HTTP_400_BAD_REQUEST
            )


class VueProfil(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serialiseur = SerialiseurUtilisateur(request.user, context={'request': request})
        return Response(serialiseur.data)

    def put(self, request):
        serialiseur = SerialiseurUtilisateur(
            request.user, data=request.data, partial=True,
            context={'request': request}
        )
        if serialiseur.is_valid():
            serialiseur.save()
            return Response({
                "message"     : "Profil mis à jour avec succès.",
                "utilisateur" : serialiseur.data
            })
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


# ═══════════════════════════════════════════════
# SECTION 2 : RÉGIONS ET CATÉGORIES
# ═══════════════════════════════════════════════

class VueListeRegions(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        regions     = Region.objects.all()
        serialiseur = SerialiseurRegion(regions, many=True)
        return Response(serialiseur.data)


class VueListeCategories(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        categories  = Categorie.objects.all()
        serialiseur = SerialiseurCategorie(categories, many=True)
        return Response(serialiseur.data)


# ═══════════════════════════════════════════════
# SECTION 3 : SITES TOURISTIQUES
# ═══════════════════════════════════════════════

class VueListeSites(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        sites        = SiteTouristique.objects.filter(est_actif=True)
        region_id    = request.query_params.get('region')
        categorie_id = request.query_params.get('categorie')
        recherche    = request.query_params.get('recherche')

        if region_id:
            sites = sites.filter(region__id=region_id)
        if categorie_id:
            sites = sites.filter(categorie__id=categorie_id)
        if recherche:
            sites = sites.filter(nom__icontains=recherche)

        serialiseur = SerialiseurListeSites(sites, many=True, context={'request': request})
        return Response(serialiseur.data)


class VueDetailSite(APIView):
    permission_classes = [LectureLibre]

    def get(self, request, pk):
        site        = get_object_or_404(SiteTouristique, pk=pk)
        serialiseur = SerialiseurDetailSite(site, context={'request': request})
        return Response(serialiseur.data)

    def put(self, request, pk):
        site = get_object_or_404(SiteTouristique, pk=pk)
        self.check_object_permissions(request, site)
        serialiseur = SerialiseurCreationSite(
            site, data=request.data, partial=True,
            context={'request': request}
        )
        if serialiseur.is_valid():
            serialiseur.save()
            return Response({
                "message": "Site mis à jour avec succès.",
                "site"   : serialiseur.data
            })
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        site = get_object_or_404(SiteTouristique, pk=pk)
        self.check_object_permissions(request, site)
        site.delete()
        return Response(
            {"message": "Site supprimé avec succès."},
            status=status.HTTP_204_NO_CONTENT
        )


class VueCreationSite(APIView):
    permission_classes = [EstProprietaire]

    def post(self, request):
        serialiseur = SerialiseurCreationSite(
            data=request.data, context={'request': request}
        )
        if serialiseur.is_valid():
            site = serialiseur.save()
            return Response({
                "message": "Site touristique ajouté avec succès.",
                "site"   : SerialiseurDetailSite(site, context={'request': request}).data
            }, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


class VueMesSites(APIView):
    permission_classes = [EstProprietaire]

    def get(self, request):
        sites       = SiteTouristique.objects.filter(proprietaire=request.user)
        serialiseur = SerialiseurListeSites(sites, many=True, context={'request': request})
        return Response(serialiseur.data)


# ═══════════════════════════════════════════════
# SECTION 3b : PHOTOS D'UN SITE
# ═══════════════════════════════════════════════

class VuePhotossite(APIView):
    permission_classes = [LectureLibre]

    def get(self, request, pk):
        site        = get_object_or_404(SiteTouristique, pk=pk)
        photos      = site.photos.all()
        serialiseur = SerialiseurPhoto(photos, many=True, context={'request': request})
        return Response(serialiseur.data)

    def post(self, request, pk):
        site = get_object_or_404(SiteTouristique, pk=pk)
        if site.proprietaire != request.user:
            return Response(
                {"erreur": "Vous n'êtes pas le propriétaire de ce site."},
                status=status.HTTP_403_FORBIDDEN
            )
        serialiseur = SerialiseurPhoto(data=request.data, context={'request': request})
        if serialiseur.is_valid():
            serialiseur.save(site=site)
            return Response(serialiseur.data, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


class VueDetailPhotosite(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        photo = get_object_or_404(PhotoSite, pk=pk)
        if photo.site.proprietaire != request.user:
            return Response(
                {"erreur": "Vous n'êtes pas le propriétaire de ce site."},
                status=status.HTTP_403_FORBIDDEN
            )
        photo.delete()
        return Response(
            {"message": "Photo supprimée avec succès."},
            status=status.HTTP_204_NO_CONTENT
        )


# ═══════════════════════════════════════════════
# SECTION 4 : AVIS
# ═══════════════════════════════════════════════

class VueAvisSite(APIView):
    permission_classes = [LectureLibre]

    def get(self, request, pk):
        site        = get_object_or_404(SiteTouristique, pk=pk)
        avis        = site.avis.all().order_by('-created_at')
        serialiseur = SerialiseurAvis(avis, many=True)
        return Response(serialiseur.data)

    def post(self, request, pk):
        site = get_object_or_404(SiteTouristique, pk=pk)
        if Avis.objects.filter(site=site, utilisateur=request.user).exists():
            return Response(
                {"erreur": "Vous avez déjà laissé un avis sur ce site."},
                status=status.HTTP_400_BAD_REQUEST
            )
        serialiseur = SerialiseurCreationAvis(
            data=request.data,
            context={'request': request, 'site': site}
        )
        if serialiseur.is_valid():
            avis = serialiseur.save()
            return Response({
                "message": "Avis ajouté avec succès.",
                "avis"   : SerialiseurAvis(avis).data
            }, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


# ═══════════════════════════════════════════════
# SECTION 5 : RÉSERVATIONS
# ═══════════════════════════════════════════════

class VueReservations(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reservations = Reservation.objects.filter(
            utilisateur=request.user
        ).order_by('-created_at')
        serialiseur  = SerialiseurReservation(reservations, many=True)
        return Response(serialiseur.data)

    def post(self, request):
        serialiseur = SerialiseurCreationReservation(
            data=request.data, context={'request': request}
        )
        if serialiseur.is_valid():
            reservation = serialiseur.save()
            return Response({
                "message"     : "Réservation effectuée avec succès.",
                "reservation" : SerialiseurReservation(reservation).data
            }, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


class VueReservationsMesSites(APIView):
    permission_classes = [EstProprietaire]

    def get(self, request):
        reservations = Reservation.objects.filter(
            site__proprietaire=request.user
        ).order_by('-created_at')
        serialiseur = SerialiseurReservation(reservations, many=True)
        return Response(serialiseur.data)


class VueDetailReservation(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        reservation = get_object_or_404(
            Reservation, pk=pk, utilisateur=request.user
        )
        serialiseur = SerialiseurReservation(reservation)
        return Response(serialiseur.data)

    def delete(self, request, pk):
        reservation = get_object_or_404(
            Reservation, pk=pk, utilisateur=request.user
        )
        if reservation.statut != 'en_attente':
            return Response(
                {"erreur": "Seules les réservations en attente peuvent être annulées."},
                status=status.HTTP_400_BAD_REQUEST
            )

        aujourd_hui   = date.today()
        jours_restants = (reservation.date_visite - aujourd_hui).days

        if jours_restants > 1:
            # Visite dans plus d'un jour → annulation libre
            pass
        else:
            # Visite dans ≤ 1 jour → seulement dans les 2h suivant la réservation
            maintenant = datetime.now(dt_timezone.utc)
            limite_2h  = reservation.created_at + timedelta(hours=2)
            if maintenant > limite_2h:
                return Response(
                    {"erreur": "Annulation impossible : la visite est imminente et le délai de 2 heures après réservation est dépassé."},
                    status=status.HTTP_400_BAD_REQUEST
                )

        reservation.statut = 'annulee'
        reservation.save()
        return Response({"message": "Réservation annulée avec succès."})


# ═══════════════════════════════════════════════
# SECTION 6 : PAIEMENT SIMULÉ
# ═══════════════════════════════════════════════

class VueInitierPaiement(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        reservation_id = request.data.get('reservation_id')
        moyen_paiement = request.data.get('moyen_paiement')

        reservation = get_object_or_404(
            Reservation, pk=reservation_id, utilisateur=request.user
        )

        if hasattr(reservation, 'paiement') and reservation.paiement.statut == 'succes':
            return Response(
                {"erreur": "Cette réservation a déjà été payée."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Supprimer l'ancien paiement en attente s'il existe
            Paiement.objects.filter(
                reservation=reservation,
                statut='en_attente'
            ).delete()

            # Créer un nouveau paiement avec tous les champs obligatoires
            paiement = Paiement.objects.create(
                reservation    = reservation,
                montant        = reservation.montant_total,
                moyen_paiement = moyen_paiement,
                statut         = 'en_attente',
                transaction_id = f"SIM_{reservation.id}_{request.user.id}"
            )
        except Exception as e:
            return Response(
                {"erreur": f"Erreur : {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        url_paiement = f"http://127.0.0.1:8000/api/paiements/simuler/{paiement.id}/"

        return Response({
            "message"        : "Paiement initié avec succès.",
            "paiement_id"    : paiement.id,
            "montant"        : str(paiement.montant),
            "url_paiement"   : url_paiement,
            "transaction_id" : paiement.transaction_id,
            "mode"           : "simulation",
        }, status=status.HTTP_201_CREATED)


class VueWebhookCinetPay(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        transaction_id = request.data.get('cpm_trans_id')
        if not transaction_id:
            return Response(
                {"erreur": "Transaction ID manquant."},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            paiement = Paiement.objects.get(transaction_id=transaction_id)
        except Paiement.DoesNotExist:
            return Response(
                {"erreur": "Paiement introuvable."},
                status=status.HTTP_404_NOT_FOUND
            )
        paiement.statut = 'succes'
        paiement.reservation.statut = 'confirmee'
        paiement.save()
        paiement.reservation.save()
        return Response({"message": "Paiement mis à jour."})


class VueSimulerPaiement(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        paiement = get_object_or_404(Paiement, pk=pk)
        return Response({
            "message"        : "Page de paiement simulée",
            "paiement_id"    : paiement.id,
            "montant"        : str(paiement.montant),
            "moyen_paiement" : paiement.moyen_paiement,
            "statut"         : paiement.statut,
            "actions"        : {
                "confirmer" : f"POST /api/paiements/simuler/{pk}/confirmer/",
                "annuler"   : f"POST /api/paiements/simuler/{pk}/annuler/",
            }
        })


class VueConfirmerPaiementSimule(APIView):
    permission_classes = [AllowAny]

    def post(self, request, pk):
        paiement = get_object_or_404(Paiement, pk=pk)
        paiement.statut             = 'succes'
        paiement.reservation.statut = 'confirmee'
        paiement.save()
        paiement.reservation.save()
        return Response({
            "message"           : "Paiement confirmé avec succès !",
            "statut"            : "succes",
            "reservation_statut": "confirmee"
        })


class VueAnnulerPaiementSimule(APIView):
    permission_classes = [AllowAny]

    def post(self, request, pk):
        paiement = get_object_or_404(Paiement, pk=pk)
        paiement.statut             = 'echec'
        paiement.reservation.statut = 'annulee'
        paiement.save()
        paiement.reservation.save()
        return Response({
            "message": "Paiement annulé.",
            "statut" : "echec",
        })


# ═══════════════════════════════════════════════
# SECTION 7 : ADMINISTRATION
# ═══════════════════════════════════════════════

class VueGestionUtilisateurs(APIView):
    permission_classes = [EstAdmin]

    def get(self, request):
        utilisateurs = Utilisateur.objects.all()
        serialiseur  = SerialiseurUtilisateur(utilisateurs, many=True)
        return Response(serialiseur.data)


class VueTableauBordAdmin(APIView):
    permission_classes = [EstAdmin]

    def get(self, request):
        statistiques = {
            "nombre_sites"           : SiteTouristique.objects.count(),
            "nombre_utilisateurs"    : Utilisateur.objects.count(),
            "nombre_reservations"    : Reservation.objects.count(),
            "reservations_confirmees": Reservation.objects.filter(statut='confirmee').count(),
            "paiements_reussis"      : Paiement.objects.filter(statut='succes').count(),
            "revenus_total"          : sum(
                                          p.montant for p in
                                          Paiement.objects.filter(statut='succes')
                                       ),
        }
        return Response(statistiques)


# ═══════════════════════════════════════════════
# SECTION 8 : HÉBERGEMENTS (HÔTELS)
# ═══════════════════════════════════════════════

def _distance_km(lat1, lon1, lat2, lon2):
    """Calcule la distance en km entre deux points GPS (formule Haversine)."""
    R = 6371
    dlat = math.radians(float(lat2) - float(lat1))
    dlon = math.radians(float(lon2) - float(lon1))
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(float(lat1))) * math.cos(math.radians(float(lat2))) * math.sin(dlon / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


class VueListeHotels(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        hotels    = Hotel.objects.filter(est_actif=True)
        region_id = request.query_params.get('region')
        if region_id:
            hotels = hotels.filter(region__id=region_id)
        serialiseur = SerialiseurHotel(hotels, many=True, context={'request': request})
        return Response(serialiseur.data)

    def post(self, request):
        if not request.user.is_authenticated:
            return Response({'erreur': 'Connexion requise.'}, status=status.HTTP_401_UNAUTHORIZED)
        est_autorise = request.user.is_superuser or request.user.role in ('admin', 'proprietaire')
        if not est_autorise:
            return Response({'erreur': 'Accès réservé aux propriétaires et administrateurs.'}, status=status.HTTP_403_FORBIDDEN)
        serialiseur = SerialiseurHotel(data=request.data, context={'request': request})
        if serialiseur.is_valid():
            hotel = serialiseur.save(proprietaire=request.user)
            return Response(SerialiseurHotel(hotel, context={'request': request}).data, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


class VueMesHotels(APIView):
    """Hôtels appartenant au propriétaire connecté."""
    permission_classes = [EstProprietaire]

    def get(self, request):
        hotels      = Hotel.objects.filter(proprietaire=request.user)
        serialiseur = SerialiseurHotel(hotels, many=True, context={'request': request})
        return Response(serialiseur.data)


class VueHotelsProximiteSite(APIView):
    """Retourne les hôtels à moins de <rayon> km d'un site touristique (défaut 10 km)."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        site  = get_object_or_404(SiteTouristique, pk=pk)
        rayon = float(request.query_params.get('rayon', 10))

        hotels_proches = []
        for hotel in Hotel.objects.filter(est_actif=True):
            dist = _distance_km(site.latitude, site.longitude, hotel.latitude, hotel.longitude)
            if dist <= rayon:
                hotels_proches.append({'hotel': hotel, 'distance_km': round(dist, 2)})

        hotels_proches.sort(key=lambda x: x['distance_km'])

        data = []
        for item in hotels_proches:
            hotel_data = SerialiseurHotel(item['hotel'], context={'request': request}).data
            hotel_data['distance_km'] = item['distance_km']
            data.append(hotel_data)

        return Response(data)


# ═══════════════════════════════════════════════
# SECTION 9 : RESTAURANTS / GASTRONOMIE
# ═══════════════════════════════════════════════

class VueListeRestaurants(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        restaurants  = Restaurant.objects.filter(est_actif=True)
        region_id    = request.query_params.get('region')
        type_cuisine = request.query_params.get('type_cuisine')
        if region_id:
            restaurants = restaurants.filter(region__id=region_id)
        if type_cuisine:
            restaurants = restaurants.filter(type_cuisine=type_cuisine)
        serialiseur = SerialiseurRestaurant(restaurants, many=True, context={'request': request})
        return Response(serialiseur.data)

    def post(self, request):
        if not request.user.is_authenticated:
            return Response({'erreur': 'Connexion requise.'}, status=status.HTTP_401_UNAUTHORIZED)
        est_autorise = request.user.is_superuser or request.user.role in ('admin', 'proprietaire')
        if not est_autorise:
            return Response({'erreur': 'Accès réservé aux propriétaires et administrateurs.'}, status=status.HTTP_403_FORBIDDEN)
        serialiseur = SerialiseurRestaurant(data=request.data, context={'request': request})
        if serialiseur.is_valid():
            restaurant = serialiseur.save(proprietaire=request.user)
            return Response(SerialiseurRestaurant(restaurant, context={'request': request}).data, status=status.HTTP_201_CREATED)
        return Response(serialiseur.errors, status=status.HTTP_400_BAD_REQUEST)


class VueMesRestaurants(APIView):
    """Restaurants appartenant au propriétaire connecté."""
    permission_classes = [EstProprietaire]

    def get(self, request):
        restaurants = Restaurant.objects.filter(proprietaire=request.user)
        serialiseur = SerialiseurRestaurant(restaurants, many=True, context={'request': request})
        return Response(serialiseur.data)


class VueRestaurantsProximiteSite(APIView):
    """Retourne les restaurants à moins de <rayon> km d'un site touristique (défaut 10 km)."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        site  = get_object_or_404(SiteTouristique, pk=pk)
        rayon = float(request.query_params.get('rayon', 10))

        restaurants_proches = []
        for resto in Restaurant.objects.filter(est_actif=True):
            dist = _distance_km(site.latitude, site.longitude, resto.latitude, resto.longitude)
            if dist <= rayon:
                restaurants_proches.append({'restaurant': resto, 'distance_km': round(dist, 2)})

        restaurants_proches.sort(key=lambda x: x['distance_km'])

        data = []
        for item in restaurants_proches:
            resto_data = SerialiseurRestaurant(item['restaurant'], context={'request': request}).data
            resto_data['distance_km'] = item['distance_km']
            data.append(resto_data)

        return Response(data)


# ═══════════════════════════════════════════════
# SECTION 10 : ÉVÉNEMENTS TOURISTIQUES
# ═══════════════════════════════════════════════

class VueListeEvenements(APIView):
    """
    Liste les événements touristiques.
    Filtres disponibles : ?region=<id>, ?type_event=<type>, ?a_venir=1
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from django.utils import timezone
        evenements   = EvenementTouristique.objects.filter(est_actif=True)
        region_id    = request.query_params.get('region')
        type_event   = request.query_params.get('type_event')
        a_venir      = request.query_params.get('a_venir')

        if region_id:
            evenements = evenements.filter(region__id=region_id)
        if type_event:
            evenements = evenements.filter(type_event=type_event)
        if a_venir:
            evenements = evenements.filter(date_fin__gte=timezone.now())

        serialiseur = SerialiseurEvenement(evenements, many=True, context={'request': request})
        return Response(serialiseur.data)


class VueDetailEvenement(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        evenement   = get_object_or_404(EvenementTouristique, pk=pk)
        serialiseur = SerialiseurEvenement(evenement, context={'request': request})
        return Response(serialiseur.data)


class VueEvenementsSite(APIView):
    """Liste tous les événements liés à un site touristique donné."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        site        = get_object_or_404(SiteTouristique, pk=pk)
        evenements  = EvenementTouristique.objects.filter(site=site, est_actif=True)
        serialiseur = SerialiseurEvenement(evenements, many=True, context={'request': request})
        return Response(serialiseur.data)


# ═══════════════════════════════════════════════
# SECTION 11 : CIRCUITS TOURISTIQUES
# ═══════════════════════════════════════════════

class VueListeCircuits(APIView):
    """
    Liste les circuits touristiques.
    Filtres : ?niveau=facile|modere|difficile, ?duree=<nb_jours>, ?region=<id>
    """
    permission_classes = [AllowAny]

    def get(self, request):
        circuits = CircuitTouristique.objects.filter(est_actif=True).prefetch_related('etapes', 'regions')
        niveau   = request.query_params.get('niveau')
        duree    = request.query_params.get('duree')
        region_id= request.query_params.get('region')

        if niveau:
            circuits = circuits.filter(niveau=niveau)
        if duree:
            circuits = circuits.filter(duree_jours=duree)
        if region_id:
            circuits = circuits.filter(regions__id=region_id)

        serialiseur = SerialiseurCircuit(circuits, many=True, context={'request': request})
        return Response(serialiseur.data)


class VueDetailCircuit(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        circuit     = get_object_or_404(CircuitTouristique, pk=pk)
        serialiseur = SerialiseurCircuit(circuit, context={'request': request})
        return Response(serialiseur.data)


# ═══════════════════════════════════════════════
# SECTION 12 : GUIDES TOURISTIQUES
# ═══════════════════════════════════════════════

class VueListeGuides(APIView):
    """
    Liste les guides touristiques.
    Filtres : ?region=<id>, ?langue=<mot>, ?certifie=1, ?disponible=1
    """
    permission_classes = [AllowAny]

    def get(self, request):
        guides      = GuideTouristique.objects.filter(est_actif=True).prefetch_related('regions_couvertes')
        region_id   = request.query_params.get('region')
        langue      = request.query_params.get('langue')
        certifie    = request.query_params.get('certifie')
        disponible  = request.query_params.get('disponible')

        if region_id:
            guides = guides.filter(regions_couvertes__id=region_id)
        if langue:
            guides = guides.filter(langues_parlees__icontains=langue)
        if certifie:
            guides = guides.filter(est_certifie=True)
        if disponible:
            guides = guides.filter(est_disponible=True)

        serialiseur = SerialiseurGuide(guides, many=True, context={'request': request})
        return Response(serialiseur.data)


class VueDetailGuide(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        guide       = get_object_or_404(GuideTouristique, pk=pk)
        serialiseur = SerialiseurGuide(guide, context={'request': request})
        return Response(serialiseur.data)


# ═══════════════════════════════════════════════
# SECTION 13 : TRANSPORTS
# ═══════════════════════════════════════════════

class VueListeTransports(APIView):
    """
    Liste les moyens de transport disponibles.
    Filtres : ?depart=<region_id>, ?arrivee=<region_id>, ?type=bus|taxi|bateau...
    """
    permission_classes = [AllowAny]

    def get(self, request):
        transports   = Transport.objects.filter(est_actif=True)
        depart_id    = request.query_params.get('depart')
        arrivee_id   = request.query_params.get('arrivee')
        type_transp  = request.query_params.get('type')

        if depart_id:
            transports = transports.filter(region_depart__id=depart_id)
        if arrivee_id:
            transports = transports.filter(region_arrivee__id=arrivee_id)
        if type_transp:
            transports = transports.filter(type_transport=type_transp)

        serialiseur = SerialiseurTransport(transports, many=True, context={'request': request})
        return Response(serialiseur.data)