// lib/models/hotel.dart
class Hotel {
  final int     id;
  final String  nom;
  final String  description;
  final int     regionId;
  final String  regionNom;
  final String  adresse;
  final String  telephone;
  final double  latitude;
  final double  longitude;
  final String  gamme;
  final double  prixMin;
  final String? image;
  final bool    estActif;
  final double? distanceKm;

  Hotel({
    required this.id,
    required this.nom,
    required this.description,
    required this.regionId,
    required this.regionNom,
    required this.adresse,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.gamme,
    required this.prixMin,
    this.image,
    required this.estActif,
    this.distanceKm,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id         : json['id'] ?? 0,
      nom        : json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      regionId   : json['region'] is int ? json['region'] : 0,
      regionNom  : json['region_nom']?.toString() ?? '',
      adresse    : json['adresse']?.toString() ?? '',
      telephone  : json['telephone']?.toString() ?? '',
      latitude   : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude  : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      gamme      : json['gamme']?.toString() ?? 'standard',
      prixMin    : double.tryParse(json['prix_min']?.toString() ?? '0') ?? 0.0,
      image      : json['image']?.toString(),
      estActif   : json['est_actif'] ?? true,
      distanceKm : json['distance_km'] != null
                     ? double.tryParse(json['distance_km'].toString())
                     : null,
    );
  }

  String get gammeAffichage {
    const labels = {
      'economique': 'Économique',
      'standard'  : 'Standard',
      'superieur' : 'Supérieur',
      'luxe'      : 'Luxe',
    };
    return labels[gamme] ?? gamme;
  }

  int get nombreEtoiles {
    const etoiles = {
      'economique': 1,
      'standard'  : 2,
      'superieur' : 3,
      'luxe'      : 4,
    };
    return etoiles[gamme] ?? 2;
  }

  String get prixAffichage =>
      prixMin == 0 ? 'Prix sur demande' : '${prixMin.toStringAsFixed(0)} FCFA / nuit';
}
