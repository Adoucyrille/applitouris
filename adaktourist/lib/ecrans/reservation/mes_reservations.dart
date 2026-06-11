// lib/ecrans/reservation/mes_reservations.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/reservation.dart';
import '../paiement/paiement.dart';

class EcranMesReservations extends StatefulWidget {
  const EcranMesReservations({super.key});

  @override
  State<EcranMesReservations> createState() => _EcranMesReservationsState();
}

class _EcranMesReservationsState extends State<EcranMesReservations> {
  List<Reservation> _reservations = [];
  bool    _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerReservations();
  }

  Future<void> _chargerReservations() async {
    setState(() => _chargement = true);
    try {
      final data = await ApiService.getMesReservations();
      setState(() {
        _reservations = data
          .map((r) => Reservation.fromJson(r))
          .toList();
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  Future<void> _annulerReservation(Reservation r) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Annuler la réservation'),
        content: Text(
          'Voulez-vous annuler votre réservation pour "${r.site}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Non'),
          ),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child    : const Text(
              'Oui, annuler',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final resultat = await ApiService.annulerReservation(r.id);
      if (!mounted) return;
      if (resultat.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content         : Text('Réservation annulée avec succès.'),
            backgroundColor : Colors.green,
          ),
        );
        _chargerReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content         : Text(resultat['erreur'] ?? 'Erreur lors de l\'annulation.'),
            backgroundColor : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content         : Text('Impossible de contacter le serveur.'),
          backgroundColor : Colors.red,
        ),
      );
    }
  }

  bool _peutAnnuler(Reservation r) {
    final dateVisite = DateTime.tryParse(r.dateVisite);
    final createdAt  = DateTime.tryParse(r.createdAt);
    if (dateVisite == null) return true;

    final maintenant    = DateTime.now();
    final joursRestants = dateVisite.difference(
      DateTime(maintenant.year, maintenant.month, maintenant.day),
    ).inDays;

    if (joursRestants > 1) return true;

    if (createdAt == null) return false;
    return maintenant.isBefore(createdAt.toLocal().add(const Duration(hours: 2)));
  }

  String _messageDelai(Reservation r) {
    final dateVisite = DateTime.tryParse(r.dateVisite);
    final createdAt  = DateTime.tryParse(r.createdAt);
    if (dateVisite == null) return '';

    final maintenant    = DateTime.now();
    final joursRestants = dateVisite.difference(
      DateTime(maintenant.year, maintenant.month, maintenant.day),
    ).inDays;

    if (joursRestants > 1) {
      final veille = dateVisite.subtract(const Duration(days: 1));
      return 'Annulable jusqu\'au ${veille.day}/${veille.month}/${veille.year}';
    }

    if (createdAt == null) return 'Annulation sous 2h après réservation';
    final limite2h = createdAt.toLocal().add(const Duration(hours: 2));
    if (maintenant.isBefore(limite2h)) {
      final restant  = limite2h.difference(maintenant);
      final heures   = restant.inHours;
      final minutes  = restant.inMinutes % 60;
      return 'Annulable encore ${heures}h${minutes.toString().padLeft(2, '0')}min';
    }
    return 'Annulation impossible (délai dépassé)';
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'confirmee'  : return Colors.green;
      case 'en_attente' : return Colors.orange;
      case 'annulee'    : return Colors.red;
      default           : return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body  : _chargement
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF77F00)),
          )
        : _erreur != null
          ? Center(child: Text(_erreur!))
          : _reservations.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_online, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune réservation pour le moment.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _chargerReservations,
                child    : ListView.builder(
                  padding    : const EdgeInsets.all(16),
                  itemCount  : _reservations.length,
                  itemBuilder: (context, index) {
                    final r = _reservations[index];
                    return Card(
                      margin : const EdgeInsets.only(bottom: 12),
                      shape  : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child  : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.site,
                                    style: const TextStyle(
                                      fontSize  : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding   : const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color       : _couleurStatut(r.statut)
                                                    .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border      : Border.all(
                                      color: _couleurStatut(r.statut),
                                    ),
                                  ),
                                  child: Text(
                                    r.statutAffichage,
                                    style: TextStyle(
                                      color    : _couleurStatut(r.statut),
                                      fontSize : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _ligne(Icons.calendar_today, 'Date', r.dateVisite),
                            const SizedBox(height: 8),
                            _ligne(Icons.people, 'Personnes',
                              '${r.nombrePersonnes} personne(s)'),
                            const SizedBox(height: 8),
                            _ligne(Icons.payments, 'Montant',
                              '${r.montantTotal.toStringAsFixed(0)} FCFA'),

                            // Boutons payer + annuler (uniquement si en attente)
                            if (r.statut == 'en_attente') ...[
                              const SizedBox(height: 10),
                              // Message délai d'annulation
                              Row(
                                children: [
                                  Icon(
                                    _peutAnnuler(r)
                                      ? Icons.info_outline
                                      : Icons.lock_clock,
                                    size : 14,
                                    color: _peutAnnuler(r)
                                      ? Colors.blueGrey
                                      : Colors.red.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _messageDelai(r),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color   : _peutAnnuler(r)
                                          ? Colors.blueGrey
                                          : Colors.red.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Bouton Payer
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EcranPaiement(
                                              reservationId: r.id,
                                              montant      : r.montantTotal,
                                              nomSite      : r.site,
                                            ),
                                          ),
                                        );
                                        _chargerReservations();
                                      },
                                      icon : const Icon(
                                        Icons.payment,
                                        color: Colors.white,
                                        size : 18,
                                      ),
                                      label: const Text(
                                        'Payer',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF009A44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Bouton Annuler (affiché seulement si délai respecté)
                                  if (_peutAnnuler(r)) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _annulerReservation(r),
                                        icon : const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                          size : 18,
                                        ),
                                        label: const Text(
                                          'Annuler',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side : const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _ligne(IconData icone, String label, String valeur) {
    return Row(
      children: [
        Icon(icone, size: 16, color: const Color(0xFFF77F00)),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(color: Colors.grey)),
        Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}