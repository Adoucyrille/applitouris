// lib/screens/reservations/ecran_reservation.dart
// Écran de réservation d'un site touristique

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../paiement/paiement.dart';

class EcranReservation extends StatefulWidget {
  final Map<String, dynamic> site;
  const EcranReservation({super.key, required this.site});

  @override
  State<EcranReservation> createState() => _EcranReservationState();
}

class _EcranReservationState extends State<EcranReservation> {
  DateTime? _dateVisite;
  int       _nombrePersonnes = 1;
  bool      _chargement      = false;
  String?   _erreur;

  double get _montantTotal {
    final prix = double.parse(
      widget.site['prix_entree'].toString()
    );
    return prix * _nombrePersonnes;
  }

  Future<void> _selectionnerDate() async {
    final date = await showDatePicker(
      context    : context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate  : DateTime.now(),
      lastDate   : DateTime.now().add(const Duration(days: 365)),
      builder    : (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF77F00),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dateVisite = date);
  }

  Future<void> _effectuerReservation() async {
    if (_dateVisite == null) {
      setState(() => _erreur = 'Veuillez choisir une date de visite.');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur     = null;
    });

    try {
      final resultat = await ApiService.creerReservation(
        siteId         : widget.site['id'],
        dateVisite     : _dateVisite!.toIso8601String().split('T')[0],
        nombrePersonnes: _nombrePersonnes,
      );

      if (resultat.containsKey('reservation')) {
        final reservationId = resultat['reservation']['id'];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EcranPaiement(
                reservationId : reservationId,
                montant       : _montantTotal,
                nomSite       : widget.site['nom'],
              ),
            ),
          );
        }
      } else {
        setState(() => _erreur = resultat['erreur'] ?? 'Erreur.');
      }
    } catch (e) {
      setState(() => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body  : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Résumé du site
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.site['nom'],
                      style: const TextStyle(
                        fontSize   : 18,
                        fontWeight : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.site['region'] is Map
                        ? widget.site['region']['nom']
                        : widget.site['region'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.site['prix_entree']} FCFA / personne',
                      style: const TextStyle(
                        color      : Color(0xFF009A44),
                        fontWeight : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date de visite
            const Text(
              'Date de visite',
              style: TextStyle(
                fontSize   : 16,
                fontWeight : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed : _selectionnerDate,
              icon      : const Icon(Icons.calendar_today),
              label     : Text(
                _dateVisite == null
                  ? 'Choisir une date'
                  : '${_dateVisite!.day}/${_dateVisite!.month}/${_dateVisite!.year}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Nombre de personnes
            const Text(
              'Nombre de personnes',
              style: TextStyle(
                fontSize   : 16,
                fontWeight : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (_nombrePersonnes > 1) {
                      setState(() => _nombrePersonnes--);
                    }
                  },
                  icon : const Icon(Icons.remove_circle),
                  color: const Color(0xFFF77F00),
                  iconSize: 36,
                ),
                const SizedBox(width: 16),
                Text(
                  '$_nombrePersonnes',
                  style: const TextStyle(
                    fontSize   : 24,
                    fontWeight : FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() => _nombrePersonnes++),
                  icon     : const Icon(Icons.add_circle),
                  color    : const Color(0xFFF77F00),
                  iconSize : 36,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Montant total
            Container(
              padding    : const EdgeInsets.all(16),
              decoration : BoxDecoration(
                color        : const Color(0xFFF77F00).withOpacity(0.1),
                borderRadius : BorderRadius.circular(8),
                border       : Border.all(
                  color: const Color(0xFFF77F00),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant total',
                    style: TextStyle(
                      fontSize   : 16,
                      fontWeight : FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_montantTotal.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize   : 20,
                      fontWeight : FontWeight.bold,
                      color      : Color(0xFFF77F00),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Message d'erreur
            if (_erreur != null)
              Container(
                padding    : const EdgeInsets.all(12),
                decoration : BoxDecoration(
                  color        : Colors.red.shade50,
                  borderRadius : BorderRadius.circular(8),
                ),
                child: Text(
                  _erreur!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const SizedBox(height: 24),

            // Bouton réserver
            ElevatedButton(
              onPressed: _chargement ? null : _effectuerReservation,
              child    : _chargement
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Confirmer et payer',
                    style: TextStyle(fontSize: 16),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}