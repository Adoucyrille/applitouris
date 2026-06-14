// lib/models/circuit.dart
class EtapeCircuit {
  final int    ordre;
  final int    siteId;
  final String siteNom;
  final String? siteImage;
  final double siteLatitude;
  final double siteLongitude;
  final String descriptionEtape;

  EtapeCircuit({
    required this.ordre,
    required this.siteId,
    required this.siteNom,
    this.siteImage,
    required this.siteLatitude,
    required this.siteLongitude,
    required this.descriptionEtape,
  });

  factory EtapeCircuit.fromJson(Map<String, dynamic> json) {
    return EtapeCircuit(
      ordre           : json['ordre'] ?? 0,
      siteId          : json['site'] ?? 0,
      siteNom         : json['site_nom']?.toString() ?? '',
      siteImage       : json['site_image']?.toString(),
      siteLatitude    : double.tryParse(json['site_latitude']?.toString() ?? '0') ?? 0.0,
      siteLongitude   : double.tryParse(json['site_longitude']?.toString() ?? '0') ?? 0.0,
      descriptionEtape: json['description_etape']?.toString() ?? '',
    );
  }
}

class Circuit {
  final int              id;
  final String           nom;
  final String           description;
  final List<String>     regions;
  final int              dureeJours;
  final double           prix;
  final String           niveau;
  final String?          image;
  final bool             estActif;
  final List<EtapeCircuit> etapes;

  Circuit({
    required this.id,
    required this.nom,
    required this.description,
    required this.regions,
    required this.dureeJours,
    required this.prix,
    required this.niveau,
    this.image,
    required this.estActif,
    required this.etapes,
  });

  factory Circuit.fromJson(Map<String, dynamic> json) {
    return Circuit(
      id         : json['id'] ?? 0,
      nom        : json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      regions    : (json['regions'] as List? ?? [])
                     .map((r) => r.toString())
                     .toList(),
      dureeJours : json['duree_jours'] ?? 1,
      prix       : double.tryParse(json['prix']?.toString() ?? '0') ?? 0.0,
      niveau     : json['niveau']?.toString() ?? 'facile',
      image      : json['image']?.toString(),
      estActif   : json['est_actif'] ?? true,
      etapes     : (json['etapes'] as List? ?? [])
                     .map((e) => EtapeCircuit.fromJson(e as Map<String, dynamic>))
                     .toList(),
    );
  }

  String get niveauAffichage {
    const labels = {
      'facile'   : 'Facile',
      'modere'   : 'Modéré',
      'difficile': 'Difficile',
    };
    return labels[niveau] ?? niveau;
  }

  String get prixAffichage =>
      prix == 0 ? 'Gratuit' : '${prix.toStringAsFixed(0)} FCFA';

  String get dureAffichage =>
      dureeJours == 1 ? '1 jour' : '$dureeJours jours';
}
