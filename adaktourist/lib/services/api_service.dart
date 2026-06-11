// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static const FlutterSecureStorage _stockage = FlutterSecureStorage();

  // ── Gestion des tokens ────────────────────────────────
  static Future<void> sauvegarderTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _stockage.write(key: 'access_token',  value: accessToken);
    await _stockage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _stockage.read(key: 'access_token');
  }

  static Future<void> supprimerTokens() async {
    await _stockage.delete(key: 'access_token');
    await _stockage.delete(key: 'refresh_token');
  }

  static Future<bool> estConnecte() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Headers HTTP ──────────────────────────────────────
  static Map<String, String> get headersPublics => {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> headersPrives() async {
    final token = await getAccessToken();
    return {
      'Content-Type' : 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Authentification ──────────────────────────────────
  static Future<Map<String, dynamic>> inscrire({
    required String username,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String role,
    required String motDePasse,
  }) async {
    final reponse = await http.post(
      Uri.parse(ApiConfig.inscription),
      headers: headersPublics,
      body: jsonEncode({
        'username'                  : username,
        'first_name'                : prenom,
        'last_name'                 : nom,
        'email'                     : email,
        'telephone'                 : telephone,
        'role'                      : role,
        'mot_de_passe'              : motDePasse,
        'confirmation_mot_de_passe' : motDePasse,
      }),
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

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

    if (reponse.statusCode == 200) {
      await sauvegarderTokens(
        accessToken  : data['access_token'],
        refreshToken : data['refresh_token'],
      );
    }
    return data;
  }

  // ── Sites touristiques ────────────────────────────────
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

  static Future<Map<String, dynamic>> getDetailSite(int id) async {
    final connecte = await estConnecte();
    final headers  = connecte ? await headersPrives() : headersPublics;
    final reponse  = await http.get(
      Uri.parse('${ApiConfig.sites}$id/'),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Espace Propriétaire (Gestion des sites) ───────────
  
  // 1. Récupérer uniquement les sites du propriétaire connecté
  static Future<List<dynamic>> getMesSites() async {
    final headers = await headersPrives();
    final reponse = await http.get(
      Uri.parse(ApiConfig.mesSites),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // 2. Créer un site touristique
  static Future<Map<String, dynamic>> creerSite({
    required String nom,
    required String description,
    required String adresse,
    required String latitude,
    required String longitude,
    required String prixEntree,
    required int regionId,
    required int categorieId,
    XFile? image,
  }) async {
    final token   = await getAccessToken();
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.creerSite));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'nom'        : nom,
      'description': description,
      'adresse'    : adresse,
      'latitude'   : latitude,
      'longitude'  : longitude,
      'prix_entree': prixEntree,
      'region'     : regionId.toString(),
      'categorie'  : categorieId.toString(),
    });
    if (image != null) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    }
    final streamed = await request.send();
    final reponse  = await http.Response.fromStream(streamed);
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // 3. Modifier un site existant
  static Future<Map<String, dynamic>> modifierSite({
    required int siteId,
    required String nom,
    required String description,
    required String adresse,
    required String latitude,
    required String longitude,
    required String prixEntree,
    required int regionId,
    required int categorieId,
    XFile? image,
  }) async {
    final token   = await getAccessToken();
    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.sites}$siteId/'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'nom'        : nom,
      'description': description,
      'adresse'    : adresse,
      'latitude'   : latitude,
      'longitude'  : longitude,
      'prix_entree': prixEntree,
      'region'     : regionId.toString(),
      'categorie'  : categorieId.toString(),
    });
    if (image != null) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    }
    final streamed = await request.send();
    final reponse  = await http.Response.fromStream(streamed);
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // 4. Ajouter une photo supplémentaire à un site
  static Future<Map<String, dynamic>> ajouterPhotoSite({
    required int siteId,
    required XFile image,
    String legende = '',
  }) async {
    final token   = await getAccessToken();
    final request = http.MultipartRequest(
      'POST', Uri.parse(ApiConfig.photosSite(siteId)),
    );
    request.headers['Authorization'] = 'Bearer $token';
    if (legende.isNotEmpty) request.fields['legende'] = legende;
    final bytes = await image.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    final streamed = await request.send();
    final reponse  = await http.Response.fromStream(streamed);
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // 5. Supprimer une photo d'un site
  static Future<void> supprimerPhotoSite(int photoId) async {
    final headers = await headersPrives();
    await http.delete(
      Uri.parse(ApiConfig.supprimerPhoto(photoId)),
      headers: headers,
    );
  }

  // 6. Supprimer un site
  static Future<Map<String, dynamic>> supprimerSite(int siteId) async {
    final headers = await headersPrives();
    final reponse = await http.delete(
      Uri.parse('${ApiConfig.sites}$siteId/'),
      headers: headers,
    );
    if (reponse.statusCode == 204) {
      return {'message': 'Site supprimé avec succès'};
    }
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

  // ── Avis ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> soumettreAvis({
    required int    siteId,
    required int    note,
    required String commentaire,
  }) async {
    final headers = await headersPrives();
    final reponse = await http.post(
      Uri.parse(ApiConfig.avisSite(siteId)),
      headers: headers,
      body: jsonEncode({'note': note, 'commentaire': commentaire}),
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Réservations ──────────────────────────────────────
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

  static Future<List<dynamic>> getMesReservations() async {
    final headers = await headersPrives();
    final reponse = await http.get(
      Uri.parse(ApiConfig.reservations),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  static Future<List<dynamic>> getReservationsMesSites() async {
    final headers = await headersPrives();
    final reponse = await http.get(
      Uri.parse(ApiConfig.reservationsMesSites),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Paiements ─────────────────────────────────────────
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

  static Future<Map<String, dynamic>> confirmerPaiement(int paiementId) async {
    final reponse = await http.post(
      Uri.parse('${ApiConfig.simulerPaiement}$paiementId/confirmer/'),
      headers: headersPublics,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  // ── Profil utilisateur ────────────────────────────────
  static Future<Map<String, dynamic>> getProfil() async {
    final headers = await headersPrives();
    final reponse = await http.get(
      Uri.parse(ApiConfig.profil),
      headers: headers,
    );
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  static Future<Map<String, dynamic>> mettreAJourPhotoProfil(XFile photo) async {
    final token   = await getAccessToken();
    final request = http.MultipartRequest('PUT', Uri.parse(ApiConfig.profil));
    request.headers['Authorization'] = 'Bearer $token';
    final bytes = await photo.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: photo.name));
    final streamed = await request.send();
    final reponse  = await http.Response.fromStream(streamed);
    return jsonDecode(utf8.decode(reponse.bodyBytes));
  }

  static Future<String> getRoleUtilisateur() async {
    final profil = await getProfil();
    return profil['role'] ?? 'touriste';
  }
}