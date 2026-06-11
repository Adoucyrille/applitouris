# apptourism/views.py
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404
from datetime import date, datetime, timedelta, timezone as dt_timezone
from .models import (
    Utilisateur, Region, Categorie,
    SiteTouristique, PhotoSite, Avis, Reservation, Paiement
)
from .serializers import (
    SerialiseurInscription, SerialiseurUtilisateur,
    SerialiseurRegion, SerialiseurCategorie,
    SerialiseurListeSites, SerialiseurDetailSite,
    SerialiseurCreationSite, SerialiseurPhoto,
    SerialiseurAvis, SerialiseurCreationAvis,
    SerialiseurReservation, SerialiseurCreationReservation,
    SerialiseurPaiement
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