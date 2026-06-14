// lib/models/evenement.dart
class Evenement {
  final int     id;
  final String  nom;
  final String  description;
  final String  typeEvent;
  final String  regionNom;
  final String? siteNom;
  final String  adresse;
  final double? latitude;
  final double? longitude;
  final String  dateDebut;
  final String  dateFin;
  final double  prixEntree;
  final String? image;
  final bool    estActif;

  Evenement({
    required this.id,
    required this.nom,
    required this.description,
    required this.typeEvent,
    required this.regionNom,
    this.siteNom,
    required this.adresse,
    this.latitude,
    this.longitude,
    required this.dateDebut,
    required this.dateFin,
    required this.prixEntree,
    this.image,
    required this.estActif,
  });

  factory Evenement.fromJson(Map<String, dynamic> json) {
    return Evenement(
      id         : json['id'] ?? 0,
      nom        : json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      typeEvent  : json['type_event']?.toString() ?? 'culturel',
      regionNom  : json['region']?.toString() ?? '',
      siteNom    : json['site']?.toString(),
      adresse    : json['adresse']?.toString() ?? '',
      latitude   : json['latitude'] != null
                     ? double.tryParse(json['latitude'].toString())
                     : null,
      longitude  : json['longitude'] != null
                     ? double.tryParse(json['longitude'].toString())
                     : null,
      dateDebut  : json['date_debut']?.toString() ?? '',
      dateFin    : json['date_fin']?.toString() ?? '',
      prixEntree : double.tryParse(json['prix_entree']?.toString() ?? '0') ?? 0.0,
      image      : json['image']?.toString(),
      estActif   : json['est_actif'] ?? true,
    );
  }

  String get typeAffichage {
    const labels = {
      'festival'   : 'Festival',
      'masque'     : 'Fête des Masques',
      'igname'     : 'Fête des Ignames',
      'dipri'      : 'Fête du Dipri',
      'masa'       : 'MASA',
      'exposition' : 'Exposition',
      'concert'    : 'Concert',
      'culturel'   : 'Culturel',
      'sportif'    : 'Sportif',
      'gastronomie': 'Gastronomique',
      'religieux'  : 'Religieux',
      'autre'      : 'Autre',
    };
    return labels[typeEvent] ?? typeEvent;
  }

  String get prixAffichage =>
      prixEntree == 0 ? 'Gratuit' : '${prixEntree.toStringAsFixed(0)} FCFA';

  DateTime? get dateDebutParsee => DateTime.tryParse(dateDebut);
  DateTime? get dateFinParsee   => DateTime.tryParse(dateFin);

  bool get estAVenir {
    final fin = dateFinParsee;
    return fin != null && fin.isAfter(DateTime.now());
  }
}
