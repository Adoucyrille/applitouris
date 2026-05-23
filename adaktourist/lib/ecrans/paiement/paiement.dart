// lib/screens/paiement/ecran_paiement.dart
// Écran de paiement — choix du moyen de paiement

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../reservation/mes_reservations.dart';

class EcranPaiement extends StatefulWidget {
  final int    reservationId;
  final double montant;
  final String nomSite;

  const EcranPaiement({
    super.key,
    required this.reservationId,
    required this.montant,
    required this.nomSite,
  });

  @override
  State<EcranPaiement> createState() => _EcranPaiementState();
}

class _EcranPaiementState extends State<EcranPaiement> {
  String  _moyenSelectionne = 'orange_money';
  bool    _chargement       = false;
  String? _erreur;

  // Moyens de paiement disponibles
  final List<Map<String, dynamic>> _moyens = [
    {
      'id'    : 'orange_money',
      'nom'   : 'Orange Money',
      'icone' : Icons.phone_android,
      'couleur': Colors.orange,
    },
    {
      'id'    : 'mtn_momo',
      'nom'   : 'MTN MoMo',
      'icone' : Icons.phone_android,
      'couleur': Colors.yellow.shade700,
    },
    {
      'id'    : 'wave',
      'nom'   : 'Wave',
      'icone' : Icons.waves,
      'couleur': Colors.blue,
    },
    {
      'id'    : 'carte',
      'nom'   : 'Carte bancaire',
      'icone' : Icons.credit_card,
      'couleur': Colors.indigo,
    },
  ];

  Future<void> _payer() async {
    setState(() {
      _chargement = true;
      _erreur     = null;
    });

    try {
      // Initier le paiement
      final resultat = await ApiService.initierPaiement(
        reservationId : widget.reservationId,
        moyenPaiement : _moyenSelectionne,
      );

      if (resultat.containsKey('paiement_id')) {
        final paiementId = resultat['paiement_id'];

        // Confirmer le paiement simulé
        final confirmation = await ApiService.confirmerPaiement(paiementId);

        if (confirmation['statut'] == 'succes') {
          if (mounted) {
            // Afficher le succès
            showDialog(
              context   : context,
              barrierDismissible: false,
              builder   : (_) => AlertDialog(
                title  : const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 8),
                    Text('Paiement réussi !'),
                  ],
                ),
                content: Text(
                  'Votre réservation pour ${widget.nomSite} '
                  'est confirmée.\n\n'
                  'Montant payé : '
                  '${widget.montant.toStringAsFixed(0)} FCFA',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EcranMesReservations(),
                        ),
                      );
                    },
                    child: const Text('Voir mes réservations'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        setState(() => _erreur = resultat['erreur'] ?? 'Erreur de paiement.');
      }
    } catch (e) {
      setState(() => _erreur = 'Impossible de traiter le paiement.');
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body  : Padding(
        padding: const EdgeInsets.all(24),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Résumé du paiement
            Card(
              color : const Color(0xFFF77F00).withOpacity(0.1),
              child : Padding(
                padding: const EdgeInsets.all(16),
                child  : Column(
                  children: [
                    const Icon(
                      Icons.receipt,
                      size : 48,
                      color: Color(0xFFF77F00),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.nomSite,
                      style: const TextStyle(
                        fontSize   : 18,
                        fontWeight : FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize   : 32,
                        fontWeight : FontWeight.bold,
                        color      : Color(0xFFF77F00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Titre moyen de paiement
            const Text(
              'Choisir un moyen de paiement',
              style: TextStyle(
                fontSize   : 16,
                fontWeight : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des moyens de paiement
            ..._moyens.map((moyen) => RadioListTile<String>(
              value    : moyen['id'],
              groupValue: _moyenSelectionne,
              onChanged: (val) =>
                setState(() => _moyenSelectionne = val!),
              activeColor: const Color(0xFFF77F00),
              title    : Row(
                children: [
                  Icon(
                    moyen['icone'],
                    color: moyen['couleur'],
                  ),
                  const SizedBox(width: 12),
                  Text(moyen['nom']),
                ],
              ),
            )),

            const Spacer(),

            // Message d'erreur
            if (_erreur != null)
              Container(
                padding    : const EdgeInsets.all(12),
                margin     : const EdgeInsets.only(bottom: 16),
                decoration : BoxDecoration(
                  color        : Colors.red.shade50,
                  borderRadius : BorderRadius.circular(8),
                ),
                child: Text(
                  _erreur!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            // Bouton payer
            ElevatedButton(
              onPressed: _chargement ? null : _payer,
              child    : _chargement
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Payer ${widget.montant.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 16),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}