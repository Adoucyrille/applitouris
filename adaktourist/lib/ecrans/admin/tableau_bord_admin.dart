// lib/ecrans/admin/tableau_bord_admin.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'gestion_utilisateurs.dart';
import 'gestion_sites_admin.dart';

class EcranTableauBordAdmin extends StatefulWidget {
  const EcranTableauBordAdmin({super.key});

  @override
  State<EcranTableauBordAdmin> createState() => _EcranTableauBordAdminState();
}

class _EcranTableauBordAdminState extends State<EcranTableauBordAdmin> {
  Map<String, dynamic>? _stats;
  bool    _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _chargement = true);
    try {
      final data = await ApiService.getTableauBordAdmin();
      setState(() {
        _stats      = data;
        _chargement = false;
      });
    } catch (_) {
      setState(() {
        _erreur     = 'Erreur de chargement des statistiques.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon     : const Icon(Icons.refresh),
            onPressed: _chargerStats,
          ),
        ],
      ),
      body: _chargement
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
        : _erreur != null
          ? Center(child: Text(_erreur!))
          : RefreshIndicator(
              onRefresh: _chargerStats,
              child    : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // En-tête avec compteurs rapides
                    Container(
                      width     : double.infinity,
                      padding   : const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient    : const LinearGradient(
                          colors: [Color(0xFFF77F00), Color(0xFFFF9A3C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Administration',
                            style: TextStyle(
                              color     : Colors.white,
                              fontSize  : 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Vue d\'ensemble de la plateforme',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          // Compteurs rapides dans la bannière
                          Row(
                            children: [
                              _compteurBanniere(
                                icone : Icons.people,
                                valeur: '${_stats?['nombre_utilisateurs'] ?? 0}',
                                label : 'Utilisateurs',
                              ),
                              const SizedBox(width: 12),
                              _compteurBanniere(
                                icone : Icons.landscape,
                                valeur: '${_stats?['nombre_sites'] ?? 0}',
                                label : 'Sites',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistiques
                    const Text(
                      'Statistiques',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount  : 2,
                      shrinkWrap      : true,
                      physics         : const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing : 12,
                      childAspectRatio: 1.4,
                      children: [
                        _carteStatistique(
                          icone  : Icons.place,
                          label  : 'Sites',
                          valeur : '${_stats?['nombre_sites'] ?? 0}',
                          couleur: const Color(0xFF009A44),
                        ),
                        _carteStatistique(
                          icone  : Icons.people,
                          label  : 'Utilisateurs',
                          valeur : '${_stats?['nombre_utilisateurs'] ?? 0}',
                          couleur: const Color(0xFF1B64F1),
                        ),
                        _carteStatistique(
                          icone  : Icons.book_online,
                          label  : 'Réservations',
                          valeur : '${_stats?['nombre_reservations'] ?? 0}',
                          couleur: Colors.purple,
                        ),
                        _carteStatistique(
                          icone  : Icons.check_circle,
                          label  : 'Confirmées',
                          valeur : '${_stats?['reservations_confirmees'] ?? 0}',
                          couleur: Colors.teal,
                        ),
                        _carteStatistique(
                          icone  : Icons.payments,
                          label  : 'Paiements réussis',
                          valeur : '${_stats?['paiements_reussis'] ?? 0}',
                          couleur: Colors.indigo,
                        ),
                        _carteRevenus(
                          valeur: _formaterMontant(
                            double.tryParse(
                              _stats?['revenus_total']?.toString() ?? '0'
                            ) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    const Text(
                      'Gestion',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _boutonAction(
                      icone    : Icons.people_alt,
                      titre    : 'Gérer les utilisateurs',
                      sousTitre: 'Voir et gérer tous les comptes',
                      couleur  : const Color(0xFF1B64F1),
                      onTap    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EcranGestionUtilisateurs(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _boutonAction(
                      icone    : Icons.landscape,
                      titre    : 'Gérer les sites',
                      sousTitre: 'Voir et supprimer des sites touristiques',
                      couleur  : const Color(0xFF009A44),
                      onTap    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EcranGestionSitesAdmin(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _carteStatistique({
    required IconData icone,
    required String   label,
    required String   valeur,
    required Color    couleur,
  }) {
    return Container(
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: couleur.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment : MainAxisAlignment.spaceBetween,
        children: [
          Icon(icone, color: couleur, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valeur,
                style: TextStyle(
                  fontSize  : 22,
                  fontWeight: FontWeight.bold,
                  color     : couleur,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compteurBanniere({
    required IconData icone,
    required String   valeur,
    required String   label,
  }) {
    return Expanded(
      child: Container(
        padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color       : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icone, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valeur,
                  style: const TextStyle(
                    color     : Colors.white,
                    fontSize  : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color   : Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteRevenus({required String valeur}) {
    const couleur = Color(0xFFF77F00);
    return Container(
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: couleur.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment : MainAxisAlignment.spaceBetween,
        children: [
          // Badge FCFA
          Container(
            padding   : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color       : couleur,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FCFA',
              style: TextStyle(
                color     : Colors.white,
                fontSize  : 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valeur,
                style: const TextStyle(
                  fontSize  : 22,
                  fontWeight: FontWeight.bold,
                  color     : couleur,
                ),
              ),
              const Text(
                'Revenus',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boutonAction({
    required IconData icone,
    required String   titre,
    required String   sousTitre,
    required Color    couleur,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap        : onTap,
      borderRadius : BorderRadius.circular(14),
      child: Container(
        padding   : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color       : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border      : Border.all(color: Colors.grey.shade200),
          boxShadow   : [
            BoxShadow(
              color    : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset   : const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding   : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color       : couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: couleur, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize  : 15,
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: const TextStyle(
                      color   : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formaterMontant(double montant) {
    if (montant >= 1000000) {
      return '${(montant / 1000000).toStringAsFixed(1)}M';
    } else if (montant >= 1000) {
      return '${(montant / 1000).toStringAsFixed(0)}K';
    }
    return montant.toStringAsFixed(0);
  }
}
