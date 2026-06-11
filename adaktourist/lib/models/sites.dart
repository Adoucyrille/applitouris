// lib/models/sites.dart

class Site {
  final int    id;
  final String nom;
  final String description;
  final String region;
  final int    regionId;      // <--- AJOUTÉ
  final String categorie;
  final int    categorieId;   // <--- AJOUTÉ
  final String adresse;
  final double latitude;
  final double longitude;
  final double prixEntree;
  final double noteMoyenne;
  final String? image;
  final bool   estActif;

  Site({
    required this.id,
    required this.nom,
    required this.description,
    required this.region,
    required this.regionId,   // <--- AJOUTÉ
    required this.categorie,
    required this.categorieId,// <--- AJOUTÉ
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.prixEntree,
    required this.noteMoyenne,
    this.image,
    required this.estActif,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
  // ── Extraction région ─────────────────────────────
  String regionNom = '';
  int    regionId  = 0;
  if (json['region'] is Map) {
    regionNom = json['region']['nom']?.toString() ?? '';
    regionId  = json['region']['id'] as int? ?? 0;
  } else if (json['region'] != null) {
    regionNom = json['region'].toString();
    regionId  = int.tryParse(json['region'].toString()) ?? 0;
  }

  // ── Extraction catégorie ──────────────────────────
  String categorieNom = '';
  int    categorieId  = 0;
  if (json['categorie'] is Map) {
    categorieNom = json['categorie']['nom']?.toString() ?? '';
    categorieId  = json['categorie']['id'] as int? ?? 0;
  } else if (json['categorie'] != null) {
    categorieNom = json['categorie'].toString();
    categorieId  = int.tryParse(json['categorie'].toString()) ?? 0;
  }

  return Site(
    id          : json['id'] ?? 0,
    nom         : json['nom']?.toString() ?? 'Sans nom',
    description : json['description']?.toString() ?? '',
    region      : regionNom,
    regionId    : regionId,
    categorie   : categorieNom,
    categorieId : categorieId,
    adresse     : json['adresse']?.toString() ?? '',
    latitude    : double.tryParse(
                    json['latitude']?.toString() ?? '0'
                  ) ?? 0.0,
    longitude   : double.tryParse(
                    json['longitude']?.toString() ?? '0'
                  ) ?? 0.0,
    prixEntree  : double.tryParse(
                    json['prix_entree']?.toString() ?? '0'
                  ) ?? 0.0,
    noteMoyenne : (json['note_moyenne'] ?? 0.0).toDouble(),
    image       : json['image']?.toString(),
    estActif    : json['est_actif'] ?? true,
  );
}
}