// lib/models/paiement.dart
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
      id            : json['id'] ?? 0,
      reservation   : json['reservation'] ?? 0,
      montant       : double.tryParse(
                        json['montant']?.toString() ?? '0'
                      ) ?? 0.0,
      moyenPaiement : json['moyen_paiement']?.toString() ?? '',
      statut        : json['statut']?.toString() ?? 'en_attente',
      transactionId : json['transaction_id']?.toString() ?? '',
      createdAt     : json['created_at']?.toString() ?? '',
    );
  }
}