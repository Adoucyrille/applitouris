// lib/models/guide.dart
class Guide {
  final int          id;
  final String       nom;
  final String       prenom;
  final String       telephone;
  final String       email;
  final String?      photo;
  final String       languesParlees;
  final List<String> regionsCouvertes;
  final String       specialites;
  final double       tarifJournalier;
  final int          anneesExperience;
  final bool         estCertifie;
  final bool         estDisponible;

  Guide({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    this.photo,
    required this.languesParlees,
    required this.regionsCouvertes,
    required this.specialites,
    required this.tarifJournalier,
    required this.anneesExperience,
    required this.estCertifie,
    required this.estDisponible,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      id               : json['id'] ?? 0,
      nom              : json['nom']?.toString() ?? '',
      prenom           : json['prenom']?.toString() ?? '',
      telephone        : json['telephone']?.toString() ?? '',
      email            : json['email']?.toString() ?? '',
      photo            : json['photo']?.toString(),
      languesParlees   : json['langues_parlees']?.toString() ?? '',
      regionsCouvertes : (json['regions_couvertes'] as List? ?? [])
                           .map((r) => r.toString())
                           .toList(),
      specialites      : json['specialites']?.toString() ?? '',
      tarifJournalier  : double.tryParse(json['tarif_journalier']?.toString() ?? '0') ?? 0.0,
      anneesExperience : json['annees_experience'] ?? 0,
      estCertifie      : json['est_certifie'] ?? false,
      estDisponible    : json['est_disponible'] ?? true,
    );
  }

  String get nomComplet => '$prenom $nom';

  String get tarifAffichage =>
      tarifJournalier == 0
          ? 'Tarif sur demande'
          : '${tarifJournalier.toStringAsFixed(0)} FCFA / jour';

  String get experienceAffichage =>
      anneesExperience <= 1
          ? '$anneesExperience an d\'expérience'
          : '$anneesExperience ans d\'expérience';
}
