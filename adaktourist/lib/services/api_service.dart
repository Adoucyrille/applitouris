// lib/services/api_service.dart
// Service principal pour toutes les communications avec l'API Django
// Gère les tokens JWT automatiquement

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  // Stockage sécurisé des tokens JWT
  static const FlutterSecureStorage _stockage = FlutterSecureStorage();

  // ── Gestion des tokens ────────────────────────────────

  // Sauvegarder les tokens après connexion
  static Future<void> sauvegarderTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _stockage.write(key: 'access_token',  value: accessToken);
    await _stockage.write(key: 'refresh_token', value: refreshToken);
  }

  // Récupérer le token d'accès
  static Future<String?> getAccessToken() async {
    return await _stockage.read(key: 'access_token');
  }

  // Supprimer les tokens à la déconnexion
  static Future<void> supprimerTokens() async {
    await _stockage.delete(key: 'access_token');
    await _stockage.delete(key: 'refresh_token');
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> estConnecte() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Headers HTTP ──────────────────────────────────────

  // Headers sans authentification (inscription, connexion)
  static Map<String, String> get headersPublics => {
    'Content-Type': 'application/json',
  };

  // Headers avec token JWT (routes protégées)
  static Future<Map<String, String>> headersPrives() async {
    final token = await getAccessToken();
    return {
      'Content-Type' : 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Authentification ──────────────────────────────────

  // Inscription d'un nouvel utilisateur
  static Future<Map<String, dynamic>> inscrire({
    required String username,
    required String email,
    required String telephone,
    required String role,
    required String motDePasse,
  }) async {
    final reponse = await http.post(
      Uri.parse(ApiConfig.inscription),
      headers: headersPublics,
      body: jsonEncode({
        'username'                    : username,
        'email'                       : email,
        'telephone'                   : telephone,
        'role'                        : role,
        'mot_de_passe'                : motDePasse,
        'confirmation_mot_de_passe'   : motDePasse,
      }),
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // Connexion d'un utilisateur existant
  static Future<Map<String, dynamic>> connecter({
    required String username,
    required String password,
  }) async {
    final reponse = await http.post(
      Uri.parse(ApiConfig.connexion),
      headers: headersPublics,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    final data = jsonDecode(utf8.decode(reponse.bodyBytes));

    // Sauvegarder les tokens si connexion réussie
    if (reponse.statusCode == 200) {
      await sauvegarderTokens(
        accessToken  : data['access_token'],
        refreshToken : data['refresh_token'],
      );
    }
    return data;
  }

  // ── Sites touristiques ────────────────────────────────

  // Récupérer tous les sites actifs
  static Future<List<dynamic>> getSites({
    String? regionId,
    String? categorieId,
    String? recherche,
  }) async {
    String url = ApiConfig.sites;
    final params = <String>[];

    if (regionId    != null) params.add('region=$regionId');
    if (categorieId != null) params.add('categorie=$categorieId');
    if (recherche   != null) params.add('recherche=$recherche');
    if (params.isNotEmpty)   url += '?${params.join('&')}';

    final reponse = await http.get(
      Uri.parse(url),
      headers: headersPublics,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // Récupérer le détail d'un site
  static Future<Map<String, dynamic>> getDetailSite(int id) async {
    final reponse = await http.get(
      Uri.parse('${ApiConfig.sites}$id/'),
      headers: headersPublics,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Régions & Catégories ──────────────────────────────

  static Future<List<dynamic>> getRegions() async {
    final reponse = await http.get(Uri.parse(ApiConfig.regions));
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  static Future<List<dynamic>> getCategories() async {
    final reponse = await http.get(Uri.parse(ApiConfig.categories));
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Réservations ──────────────────────────────────────

  // Créer une réservation
  static Future<Map<String, dynamic>> creerReservation({
    required int siteId,
    required String dateVisite,
    required int nombrePersonnes,
  }) async {
    final headers = await headersPrives();
    final reponse = await http.post(
      Uri.parse(ApiConfig.reservations),
      headers: headers,
      body: jsonEncode({
        'site'             : siteId,
        'date_visite'      : dateVisite,
        'nombre_personnes' : nombrePersonnes,
      }),
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // Récupérer mes réservations
  static Future<List<dynamic>> getMesReservations() async {
    final headers = await headersPrives();
    final reponse = await http.get(
      Uri.parse(ApiConfig.reservations),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Paiements ─────────────────────────────────────────

  // Initier un paiement
  static Future<Map<String, dynamic>> initierPaiement({
    required int reservationId,
    required String moyenPaiement,
  }) async {
    final headers = await headersPrives();
    final reponse = await http.post(
      Uri.parse(ApiConfig.initierPaiement),
      headers: headers,
      body: jsonEncode({
        'reservation_id' : reservationId,
        'moyen_paiement' : moyenPaiement,
      }),
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // Confirmer un paiement simulé
  static Future<Map<String, dynamic>> confirmerPaiement(int paiementId) async {
    final reponse = await http.post(
      Uri.parse('${ApiConfig.simulerPaiement}$paiementId/confirmer/'),
      headers: headersPublics,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // Ajouter cette méthode dans ApiService
  static Future<Map<String, dynamic>> getProfil() async {
    final headers = await headersPrives();
    final reponse = await http.get(
      Uri.parse(ApiConfig.profil),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

}