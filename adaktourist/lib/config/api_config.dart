// lib/config/api_config.dart
// Configuration centrale de l'API Django
// Contient toutes les URLs de l'application

class ApiConfig {
  // URL de base — 10.0.2.2 est l'adresse de localhost pour l'émulateur Android
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ── Authentification ──────────────────────────────────
  static const String inscription  = '$baseUrl/auth/inscription/';
  static const String connexion    = '$baseUrl/auth/connexion/';
  static const String deconnexion  = '$baseUrl/auth/deconnexion/';
  static const String profil       = '$baseUrl/auth/profil/';
  static const String refreshToken = '$baseUrl/auth/refresh/';

  // ── Sites touristiques ────────────────────────────────
  static const String sites       = '$baseUrl/sites/';
  static const String creerSite   = '$baseUrl/sites/creer/';
  static const String mesSites    = '$baseUrl/sites/mes-sites/';

  // ── Régions & Catégories ──────────────────────────────
  static const String regions    = '$baseUrl/regions/';
  static const String categories = '$baseUrl/categories/';

  // ── Réservations ──────────────────────────────────────
  static const String reservations = '$baseUrl/reservations/';

  // ── Paiements ─────────────────────────────────────────
  static const String initierPaiement = '$baseUrl/paiements/initier/';
  static const String simulerPaiement = '$baseUrl/paiements/simuler/';
}