// lib/models/transport.dart
class Transport {
  final int    id;
  final String typeTransport;
  final String typeLabel;
  final String compagnie;
  final String regionDepart;
  final String regionArrivee;
  final String villeDepart;
  final String villeArrivee;
  final double prix;
  final int    dureeMinutes;
  final String horaires;
  final String telephoneContact;

  Transport({
    required this.id,
    required this.typeTransport,
    required this.typeLabel,
    required this.compagnie,
    required this.regionDepart,
    required this.regionArrivee,
    required this.villeDepart,
    required this.villeArrivee,
    required this.prix,
    required this.dureeMinutes,
    required this.horaires,
    required this.telephoneContact,
  });

  factory Transport.fromJson(Map<String, dynamic> json) {
    return Transport(
      id              : json['id'] ?? 0,
      typeTransport   : json['type_transport']?.toString() ?? '',
      typeLabel       : json['type_label']?.toString() ?? '',
      compagnie       : json['compagnie']?.toString() ?? '',
      regionDepart    : json['region_depart']?.toString() ?? '',
      regionArrivee   : json['region_arrivee']?.toString() ?? '',
      villeDepart     : json['ville_depart']?.toString() ?? '',
      villeArrivee    : json['ville_arrivee']?.toString() ?? '',
      prix            : double.tryParse(json['prix']?.toString() ?? '0') ?? 0.0,
      dureeMinutes    : json['duree_minutes'] ?? 0,
      horaires        : json['horaires']?.toString() ?? '',
      telephoneContact: json['telephone_contact']?.toString() ?? '',
    );
  }

  String get prixAffichage => '${prix.toStringAsFixed(0)} FCFA';

  String get dureeAffichage {
    if (dureeMinutes < 60) return '$dureeMinutes min';
    final h = dureeMinutes ~/ 60;
    final m = dureeMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  String get trajetAffichage => '$villeDepart → $villeArrivee';
}
