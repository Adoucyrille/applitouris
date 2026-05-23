// Représente un paiement
class Paiement {
  final int    id;
  final int    reservation;
  final double montant;
  final String moyenPaiement;
  final String statut;
  final String transactionId;
  final String createdAt;

  Paiement({
    required this.id,
    required this.reservation,
    required this.montant,
    required this.moyenPaiement,
    required this.statut,
    required this.transactionId,
    required this.createdAt,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id            : json['id'],
      reservation   : json['reservation'],
      montant       : double.parse(json['montant'].toString()),
      moyenPaiement : json['moyen_paiement'],
      statut        : json['statut'],
      transactionId : json['transaction_id'] ?? '',
      createdAt     : json['created_at'],
    );
  }
}