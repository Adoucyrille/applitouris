// lib/models/reservation.dart
class Reservation {
  final int    id;
  final String utilisateur;
  final String telephoneUtilisateur;
  final String site;
  final String dateVisite;
  final int    nombrePersonnes;
  final double montantTotal;
  final String statut;
  final String createdAt;

  Reservation({
    required this.id,
    required this.utilisateur,
    required this.telephoneUtilisateur,
    required this.site,
    required this.dateVisite,
    required this.nombrePersonnes,
    required this.montantTotal,
    required this.statut,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id                   : json['id'] ?? 0,
      utilisateur          : json['utilisateur']?.toString() ?? '',
      telephoneUtilisateur : json['telephone_utilisateur']?.toString() ?? '',
      site                 : json['site']?.toString() ?? '',
      dateVisite           : json['date_visite']?.toString() ?? '',
      nombrePersonnes      : json['nombre_personnes'] ?? 1,
      montantTotal         : double.tryParse(
                               json['montant_total']?.toString() ?? '0'
                             ) ?? 0.0,
      statut               : json['statut']?.toString() ?? 'en_attente',
      createdAt            : json['created_at']?.toString() ?? '',
    );
  }

  String get statutAffichage {
    switch (statut) {
      case 'confirmee' : return 'Confirmée ✅';
      case 'en_attente': return 'En attente ⏳';
      case 'annulee'   : return 'Annulée ❌';
      case 'terminee'  : return 'Terminée 🏁';
      default          : return statut;
    }
  }
}