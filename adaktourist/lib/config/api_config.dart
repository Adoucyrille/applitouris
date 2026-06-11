// lib/config/api_config.dart

class ApiConfig {

  // ── URL de base ───────────────────────────────────────
  // Chrome Web        : http://localhost:8000/api
  // Émulateur Android : http://10.0.2.2:8000/api
  // Téléphone réel    : http://192.168.X.X:8000/api

  static const String baseUrl = 'http://localhost:8000/api';

  // ── Authentification ──────────────────────────────────

  static const String inscription  = '$baseUrl/auth/inscription/';
  static const String connexion    = '$baseUrl/auth/connexion/';
  static const String deconnexion  = '$baseUrl/auth/deconnexion/';
  static const String profil       = '$baseUrl/auth/profil/';
  static const String refreshToken = '$baseUrl/auth/refresh/';

  // ── Sites touristiques ────────────────────────────────

  static const String sites        = '$baseUrl/sites/';
  static const String creerSite    = '$baseUrl/sites/creer/';
  static const String mesSites     = '$baseUrl/sites/mes-sites/';

  // ── Régions & Catégories ──────────────────────────────

  static const String regions      = '$baseUrl/regions/';
  static const String categories   = '$baseUrl/categories/';

  // ── Réservations ──────────────────────────────────────

  static const String reservations        = '$baseUrl/reservations/';
  static const String reservationsMesSites = '$baseUrl/reservations/mes-sites/';

  // ── Paiements ─────────────────────────────────────────

  static const String initierPaiement = '$baseUrl/paiements/initier/';
  static const String simulerPaiement = '$baseUrl/paiements/simuler/';

  // ── Administration ────────────────────────────────────

  static const String tableauBord = '$baseUrl/admin/tableau-de-bord/';
  static const String gestionUtilisateurs =
      '$baseUrl/admin/utilisateurs/';

  // ── URLs dynamiques ───────────────────────────────────

  static String detailSite(int id) =>
      '$sites$id/';

  static String modifierSite(int id) =>
      '$sites$id/';

  static String supprimerSite(int id) =>
      '$sites$id/';

  static String avisSite(int id) =>
      '$sites$id/avis/';

  static String photosSite(int id) =>
      '$sites$id/photos/';

  static String supprimerPhoto(int id) =>
      '${sites}photos/$id/';

  static String detailReservation(int id) =>
      '$reservations$id/';

  static String simulerPaiementId(int id) =>
      '$simulerPaiement$id/';

  static String confirmerPaiement(int id) =>
      '$simulerPaiement$id/confirmer/';

  static String annulerPaiement(int id) =>
      '$simulerPaiement$id/annuler/';
}