// lib/models/restaurant.dart
class Restaurant {
  final int     id;
  final String  nom;
  final String  description;
  final int     regionId;
  final String  regionNom;
  final String  adresse;
  final String  telephone;
  final double  latitude;
  final double  longitude;
  final String  typeCuisine;
  final String  specialites;
  final double  prixMoyen;
  final String? image;
  final bool    estActif;
  final double? distanceKm;

  Restaurant({
    required this.id,
    required this.nom,
    required this.description,
    required this.regionId,
    required this.regionNom,
    required this.adresse,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.typeCuisine,
    required this.specialites,
    required this.prixMoyen,
    this.image,
    required this.estActif,
    this.distanceKm,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id          : json['id'] ?? 0,
      nom         : json['nom']?.toString() ?? '',
      description : json['description']?.toString() ?? '',
      regionId    : json['region'] is int ? json['region'] : 0,
      regionNom   : json['region_nom']?.toString() ?? '',
      adresse     : json['adresse']?.toString() ?? '',
      telephone   : json['telephone']?.toString() ?? '',
      latitude    : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude   : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      typeCuisine : json['type_cuisine']?.toString() ?? 'ivoirienne',
      specialites : json['specialites']?.toString() ?? '',
      prixMoyen   : double.tryParse(json['prix_moyen']?.toString() ?? '0') ?? 0.0,
      image       : json['image']?.toString(),
      estActif    : json['est_actif'] ?? true,
      distanceKm  : json['distance_km'] != null
                      ? double.tryParse(json['distance_km'].toString())
                      : null,
    );
  }

  String get typeCuisineAffichage {
    const labels = {
      'maquis'        : 'Maquis',
      'ivoirienne'    : 'Cuisine Ivoirienne',
      'garba'         : 'Garba',
      'africaine'     : 'Cuisine Africaine',
      'libanaise'     : 'Cuisine Libanaise',
      'internationale': 'Internationale',
      'rapide'        : 'Restauration Rapide',
      'fruits_mer'    : 'Fruits de Mer',
      'vegetarienne'  : 'Végétarienne',
    };
    return labels[typeCuisine] ?? typeCuisine;
  }

  String get prixAffichage =>
      prixMoyen == 0 ? 'Prix variable' : '${prixMoyen.toStringAsFixed(0)} FCFA / personne';
}
