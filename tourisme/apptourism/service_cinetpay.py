# apptourism/service_cinetpay.py
# Service de communication avec l'API CinetPay
# CinetPay supporte : Orange Money, MTN MoMo, Wave, Moov Money

import requests
import uuid
from django.conf import settings

# URL de base de l'API CinetPay
URL_API_CINETPAY = "https://api-checkout.cinetpay.com/v2/payment"


def initier_paiement_cinetpay(reservation, moyen_paiement):
    """
    Envoie une demande de paiement à CinetPay.
    Retourne l'URL de paiement que Flutter ouvrira dans une WebView.
    """

    # Générer un identifiant unique pour cette transaction
    transaction_id = str(uuid.uuid4()).replace('-', '')[:20].upper()

    # Construire les données obligatoires exigées par CinetPay
    donnees_paiement = {
        # ── Authentification ──────────────────────────────
        "apikey"          : settings.CINETPAY_API_KEY,
        "site_id"         : settings.CINETPAY_SITE_ID,

        # ── Informations de la transaction ────────────────
        "transaction_id"  : transaction_id,
        "amount"          : int(reservation.montant_total),
        "currency"        : "XOF",
        "description"     : f"Reservation : {reservation.site.nom}",

        # ── URLs de redirection ───────────────────────────
        "return_url"      : settings.CINETPAY_URL_RETOUR,
        "cancel_url"      : settings.CINETPAY_URL_ANNULATION,
        "notify_url"      : settings.CINETPAY_URL_RETOUR,

        # ── Informations client (OBLIGATOIRES pour CinetPay) ──
        "customer_id"          : str(reservation.utilisateur.id),
        "customer_name"        : reservation.utilisateur.username,
        "customer_surname"     : reservation.utilisateur.username,
        "customer_email"       : reservation.utilisateur.email
                                 if reservation.utilisateur.email
                                 else "client@tourisme.ci",
        "customer_phone_number": reservation.utilisateur.telephone
                                 if reservation.utilisateur.telephone
                                 else "+2250000000000",
        "customer_address"     : "Abidjan",
        "customer_city"        : "Abidjan",
        "customer_country"     : "CI",
        "customer_state"       : "CI",
        "customer_zip_code"    : "00225",

        # ── Options supplémentaires ───────────────────────
        "channels"        : "ALL",
        "metadata"        : f"reservation_{reservation.id}",
        "lang"            : "fr",
        "invoice_data"    : {},
    }

    try:
        # Envoyer la requête à CinetPay
        reponse = requests.post(
            URL_API_CINETPAY,
            json=donnees_paiement,
            timeout=30
        )

        # Afficher la réponse complète pour débogage
        print("=== Réponse CinetPay ===")
        print(reponse.status_code)
        print(reponse.json())
        print("=======================")

        reponse_json = reponse.json()

        # Vérifier si CinetPay a accepté la demande
        if reponse_json.get('code') == '201':
            url_paiement = reponse_json['data']['payment_url']
            return {
                "succes"         : True,
                "url_paiement"   : url_paiement,
                "transaction_id" : transaction_id,
                "erreur"         : None
            }
        else:
            # Retourner le message d'erreur complet de CinetPay
            return {
                "succes"         : False,
                "url_paiement"   : None,
                "transaction_id" : None,
                "erreur"         : reponse_json.get('message', 'Erreur inconnue'),
                "details"        : reponse_json  # détails complets pour débogage
            }

    except requests.exceptions.Timeout:
        return {
            "succes" : False,
            "erreur" : "La connexion à CinetPay a expiré. Réessayez."
        }
    except requests.exceptions.ConnectionError:
        return {
            "succes" : False,
            "erreur" : "Impossible de contacter CinetPay. Vérifiez votre connexion."
        }
    except Exception as e:
        return {
            "succes" : False,
            "erreur" : f"Erreur inattendue : {str(e)}"
        }


def verifier_paiement_cinetpay(transaction_id):
    """
    Vérifie le statut d'un paiement auprès de CinetPay.
    """
    donnees_verification = {
        "apikey"         : settings.CINETPAY_API_KEY,
        "site_id"        : settings.CINETPAY_SITE_ID,
        "transaction_id" : transaction_id,
    }

    try:
        reponse = requests.post(
            "https://api-checkout.cinetpay.com/v2/payment/check",
            json=donnees_verification,
            timeout=30
        )
        reponse_json = reponse.json()
        code = reponse_json.get('data', {}).get('status', '')

        if code == 'ACCEPTED':
            return 'succes'
        elif code == 'PENDING':
            return 'en_attente'
        else:
            return 'echec'

    except Exception:
        return 'echec'