// lib/screens/reservations/ecran_mes_reservations.dart
// Écran affichant toutes les réservations de l'utilisateur connecté

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/reservation.dart';

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

  // Couleur selon le statut
  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'confirmee'  : return Colors.green;
      case 'en_attente' : return Colors.orange;
      case 'annulee'    : return Colors.red;
      case 'terminee'   : return Colors.grey;
      default           : return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
      ),
      body: _chargement
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF77F00)),
          )
        : _erreur != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(_erreur!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed : _chargerReservations,
                    child     : const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : _reservations.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_online,
                      size : 80,
                      color: Colors.grey,
                    ),
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
                      margin    : const EdgeInsets.only(bottom: 12),
                      elevation : 2,
                      shape     : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child  : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Nom du site et statut
                            Row(
                              mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.site,
                                    style: const TextStyle(
                                      fontSize   : 16,
                                      fontWeight : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding    : const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4,
                                  ),
                                  decoration : BoxDecoration(
                                    color        : _couleurStatut(r.statut)
                                                    .withOpacity(0.1),
                                    borderRadius : BorderRadius.circular(12),
                                    border       : Border.all(
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
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Détails
                            _ligneDetail(
                              Icons.calendar_today,
                              'Date de visite',
                              r.dateVisite,
                            ),
                            const SizedBox(height: 8),
                            _ligneDetail(
                              Icons.people,
                              'Personnes',
                              '${r.nombrePersonnes} personne(s)',
                            ),
                            const SizedBox(height: 8),
                            _ligneDetail(
                              Icons.payments,
                              'Montant',
                              '${r.montantTotal.toStringAsFixed(0)} FCFA',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _ligneDetail(IconData icone, String label, String valeur) {
    return Row(
      children: [
        Icon(icone, size: 16, color: const Color(0xFFF77F00)),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          valeur,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}