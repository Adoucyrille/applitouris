
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

  final TextEditingController _numeroController = TextEditingController();

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _moyens = [
    {'id': 'orange_money', 'nom': 'Orange Money CI'},
    {'id': 'mtn_momo',     'nom': 'MTN MoMo'},
    {'id': 'wave',         'nom': 'Wave'},
    {'id': 'moov_africa',  'nom': 'Moov Africa'},
  ];

  String _hintNumero() {
    switch (_moyenSelectionne) {
      case 'orange_money': return 'Ex : 0700000000';
      case 'mtn_momo'    : return 'Ex : 0500000000';
      case 'moov_africa' : return 'Ex : 0100000000';
      case 'wave'        : return 'Ex : 0700000000';
      default            : return 'Numéro de téléphone (10 chiffres)';
    }
  }

  static const Map<String, List<String>> _prefixesOperateur = {
    'orange_money': ['07', '08', '09'],
    'mtn_momo'    : ['04', '05', '06'],
    'moov_africa' : ['01', '02', '03'],
    'wave'        : ['01', '02', '03', '04', '05', '06', '07', '08', '09'],
  };

  String? _validerNumero(String numero) {
    final chiffres = numero.replaceAll(RegExp(r'\s'), '');
    if (chiffres.isEmpty) return 'Veuillez entrer votre numéro de paiement.';
    if (!RegExp(r'^\d+$').hasMatch(chiffres)) return 'Le numéro ne doit contenir que des chiffres.';
    if (chiffres.length != 10) return 'Le numéro doit contenir 10 chiffres.';

    final prefixes = _prefixesOperateur[_moyenSelectionne] ?? [];
    final prefixe  = chiffres.substring(0, 2);
    if (!prefixes.contains(prefixe)) {
      final noms = {
        'orange_money': 'Orange (07, 08, 09)',
        'mtn_momo'    : 'MTN (05, 06)',
        'moov_africa' : 'Moov Africa (01, 02, 03)',
        'wave'        : 'tous opérateurs',
      };
      final nomOperateur = noms[_moyenSelectionne] ?? '';
      final prefixesStr  = prefixes.join(', ');
      return 'Numéro invalide pour $nomOperateur.\nPréfixes acceptés : $prefixesStr.';
    }
    return null;
  }

  Future<void> _payer() async {
    final numero = _numeroController.text.trim();
    final erreurNumero = _validerNumero(numero);
    if (erreurNumero != null) {
      setState(() => _erreur = erreurNumero);
      return;
    }

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

  Widget _logoOperateur(String id) {
    switch (id) {
      case 'orange_money':
        return Container(
          width : 64, height: 42,
          decoration: BoxDecoration(
            color       : const Color(0xFFFF6600),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width : 18, height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Orange',
                style: TextStyle(
                  color     : Colors.white,
                  fontSize  : 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );

      case 'mtn_momo':
        return Container(
          width : 64, height: 42,
          decoration: BoxDecoration(
            color       : const Color(0xFFFFCD00),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MTN',
                style: TextStyle(
                  color     : Colors.black,
                  fontSize  : 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'MoMo',
                style: TextStyle(
                  color    : Colors.black87,
                  fontSize : 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'wave':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width : 64, height: 42,
            color : const Color(0xFF1B64F1),
            child : Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  left  : 0,
                  right : 0,
                  child : CustomPaint(
                    size   : const Size(double.infinity, 14),
                    painter: _WavePainter(),
                  ),
                ),
                const Text(
                  'wave',
                  style: TextStyle(
                    color        : Colors.white,
                    fontSize     : 16,
                    fontWeight   : FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );

      case 'moov_africa':
        return Container(
          width : 64, height: 42,
          decoration: BoxDecoration(
            gradient    : const LinearGradient(
              colors: [Color(0xFF00AEEF), Color(0xFF0072BC)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MOOV',
                style: TextStyle(
                  color     : Colors.white,
                  fontSize  : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Africa',
                style: TextStyle(
                  color    : Colors.white70,
                  fontSize : 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox(width: 64, height: 42);
    }
  }

  Widget _cartePaiement(String id, String nom) {
    final selectionne = _moyenSelectionne == id;
    return GestureDetector(
      onTap: () => setState(() => _moyenSelectionne = id),
      child: AnimatedContainer(
        duration  : const Duration(milliseconds: 180),
        margin    : const EdgeInsets.only(bottom: 12),
        padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color       : selectionne
            ? const Color(0xFFF77F00).withValues(alpha: 0.06)
            : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border      : Border.all(
            color: selectionne ? const Color(0xFFF77F00) : Colors.grey.shade200,
            width: selectionne ? 2 : 1,
          ),
          boxShadow   : [
            BoxShadow(
              color  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset : const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _logoOperateur(id),
            const SizedBox(width: 16),
            Text(
              nom,
              style: const TextStyle(
                fontSize  : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (selectionne)
              const Icon(Icons.check_circle, color: Color(0xFFF77F00), size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body  : Column(
        children: [

          // Contenu défilable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Résumé du paiement
                  Card(
                    color : const Color(0xFFF77F00).withValues(alpha: 0.1),
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
                              fontSize  : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.montant.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize  : 32,
                              fontWeight: FontWeight.bold,
                              color     : Color(0xFFF77F00),
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
                      fontSize  : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Liste des moyens de paiement
                  ..._moyens.map((moyen) =>
                    _cartePaiement(moyen['id']!, moyen['nom']!)),

                  const SizedBox(height: 8),

                  // Champ numéro de paiement
                  const Text(
                    'Numéro de paiement',
                    style: TextStyle(
                      fontSize  : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller  : _numeroController,
                    keyboardType: TextInputType.phone,
                    maxLength   : 15,
                    decoration  : InputDecoration(
                      hintText: _hintNumero(),
                      prefixIcon   : const Icon(
                        Icons.phone,
                        color: Color(0xFFF77F00),
                      ),
                      border       : OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : const BorderSide(
                          color: Color(0xFFF77F00),
                          width: 2,
                        ),
                      ),
                      counterText: '',
                    ),
                    onChanged: (_) {
                      if (_erreur != null) setState(() => _erreur = null);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bouton toujours visible en bas
          Container(
            padding  : const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color    : Colors.white,
              boxShadow: [
                BoxShadow(
                  color    : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset   : const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_erreur != null)
                  Container(
                    padding   : const EdgeInsets.all(12),
                    margin    : const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color       : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _erreur!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                SizedBox(
                  width : double.infinity,
                  child : ElevatedButton(
                    onPressed: _chargement ? null : _payer,
                    style    : ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _chargement
                      ? const SizedBox(
                          width : 22, height: 22,
                          child : CircularProgressIndicator(
                            color      : Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Payer ${widget.montant.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontSize: 16),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.white.withValues(alpha: 0.35)
      ..style       = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.cubicTo(
      size.width * 0.25, 0,
      size.width * 0.5,  size.height,
      size.width * 0.75, size.height * 0.3,
    );
    path.cubicTo(
      size.width * 0.88, 0,
      size.width,        size.height * 0.5,
      size.width,        size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}