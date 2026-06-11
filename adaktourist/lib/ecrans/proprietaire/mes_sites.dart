// lib/ecrans/proprietaire/mes_sites.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/sites.dart';
import 'ajout_site.dart';
import 'reservations_sites.dart';

class EcranMesSites extends StatefulWidget {
  const EcranMesSites({super.key});

  @override
  State<EcranMesSites> createState() => _EcranMesSitesState();
}

class _EcranMesSitesState extends State<EcranMesSites> {
  List<Site> _sites      = [];
  bool       _chargement = true;
  String?    _erreur;

  @override
  void initState() {
    super.initState();
    _chargerMesSites();
  }

  Future<void> _chargerMesSites() async {
    if (!mounted) return;
    setState(() => _chargement = true);
    try {
      final data = await ApiService.getMesSites();
      if (!mounted) return;
      setState(() {
        // Transtypage explicite pour éviter les conflits de types
        _sites      = (data as List).map((s) => Site.fromJson(s as Map<String, dynamic>)).toList();
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  Future<void> _supprimerSite(int siteId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Supprimer ce site ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        await ApiService.supprimerSite(siteId);
        if (!mounted) return; // Protection anti-crash
        _chargerMesSites();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title  : const Text('Mes sites touristiques'),
        actions: [
          IconButton(
            icon   : const Icon(Icons.book_online),
            tooltip: 'Réservations reçues',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EcranReservationsSites(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF77F00),
        onPressed      : () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EcranAjouterSite()),
          );
          _chargerMesSites();
        },
        icon : const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter un site', style: TextStyle(color: Colors.white)),
      ),
      body: _chargement
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
        : _erreur != null
          ? Center(child: Text(_erreur!))
          : _sites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt, size : 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Vous n\'avez pas encore de site.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EcranAjouterSite()),
                        );
                        _chargerMesSites();
                      },
                      icon : const Icon(Icons.add),
                      label: const Text('Ajouter mon premier site'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _chargerMesSites,
                child    : ListView.builder(
                  padding    : const EdgeInsets.all(16),
                  itemCount  : _sites.length,
                  itemBuilder: (context, index) {
                    final site = _sites[index];
                    return Card(
                      margin    : const EdgeInsets.only(bottom: 12),
                      elevation : 2,
                      shape     : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    site.nom,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFFF77F00)),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EcranAjouterSite(siteAModifier: site),
                                          ),
                                        );
                                        _chargerMesSites();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _supprimerSite(site.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size : 14, color: Colors.grey),
                                Text(site.region, style: const TextStyle(color: Colors.grey)),
                                const SizedBox(width: 16),
                                const Icon(Icons.star, size : 14, color: Colors.amber),
                                Text(site.noteMoyenne.toStringAsFixed(1)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(site.categorie, style: const TextStyle(color: Color(0xFFF77F00))),
                                Text(
                                  '${site.prixEntree.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009A44)),
                                ),
                              ],
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
}