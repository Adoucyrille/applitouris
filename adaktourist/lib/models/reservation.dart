// Représente une réservation
class Reservation {
  final int    id;
  final String utilisateur;
  final String site;
  final String dateVisite;
  final int    nombrePersonnes;
  final double montantTotal;
  final String statut;
  final String createdAt;

  Reservation({
    required this.id,
    required this.utilisateur,
    required this.site,
    required this.dateVisite,
    required this.nombrePersonnes,
    required this.montantTotal,
    required this.statut,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id             : json['id'],
      utilisateur    : json['utilisateur'],
      site           : json['site'],
      dateVisite     : json['date_visite'],
      nombrePersonnes: json['nombre_personnes'],
      montantTotal   : double.parse(json['montant_total'].toString()),
      statut         : json['statut'],
      createdAt      : json['created_at'],
    );
  }

  // Couleur selon le statut pour l'affichage
  String get statutAffichage {
    switch (statut) {
      case 'confirmee'  : return 'Confirmée ✅';
      case 'en_attente' : return 'En attente ⏳';
      case 'annulee'    : return 'Annulée ❌';
      case 'terminee'   : return 'Terminée 🏁';
      default           : return statut;
    }
  }
}