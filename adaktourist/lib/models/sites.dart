// Représente un site touristique
class Site {
  final int    id;
  final String nom;
  final String description;
  final String region;
  final String categorie;
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
    required this.categorie,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.prixEntree,
    required this.noteMoyenne,
    this.image,
    required this.estActif,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id          : json['id'],
      nom         : json['nom'],
      description : json['description'] ?? '',
      region      : json['region'] is Map ? json['region']['nom'] : json['region'],
      categorie   : json['categorie'] is Map ? json['categorie']['nom'] : json['categorie'] ?? '',
      adresse     : json['adresse'] ?? '',
      latitude    : double.parse(json['latitude'].toString()),
      longitude   : double.parse(json['longitude'].toString()),
      prixEntree  : double.parse(json['prix_entree'].toString()),
      noteMoyenne : (json['note_moyenne'] ?? 0.0).toDouble(),
      image       : json['image'],
      estActif    : json['est_actif'] ?? true,
    );
  }
}