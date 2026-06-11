// lib/ecrans/proprietaire/reservations_sites.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/reservation.dart';

class EcranReservationsSites extends StatefulWidget {
  const EcranReservationsSites({super.key});

  @override
  State<EcranReservationsSites> createState() => _EcranReservationsSitesState();
}

class _EcranReservationsSitesState extends State<EcranReservationsSites> {
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
      final data = await ApiService.getReservationsMesSites();
      setState(() {
        _reservations = data
          .map((r) => Reservation.fromJson(r as Map<String, dynamic>))
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
      appBar: AppBar(title: const Text('Réservations reçues')),
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
                    Icon(Icons.event_busy, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune réservation reçue pour le moment.',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      color     : _couleurStatut(r.statut),
                                      fontSize  : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _ligne(Icons.person,         'Touriste',   r.utilisateur),
                            const SizedBox(height: 8),
                            _ligne(Icons.phone,           'Téléphone',
                              r.telephoneUtilisateur.isNotEmpty
                                ? r.telephoneUtilisateur
                                : 'Non renseigné'),
                            const SizedBox(height: 8),
                            _ligne(Icons.calendar_today, 'Date',       r.dateVisite),
                            const SizedBox(height: 8),
                            _ligne(Icons.people,         'Personnes',
                              '${r.nombrePersonnes} personne(s)'),
                            const SizedBox(height: 8),
                            _ligne(Icons.payments,       'Montant',
                              '${r.montantTotal.toStringAsFixed(0)} FCFA'),
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
        Expanded(
          child: Text(
            valeur,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
