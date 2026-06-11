// lib/ecrans/admin/gestion_sites_admin.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

class EcranGestionSitesAdmin extends StatefulWidget {
  const EcranGestionSitesAdmin({super.key});

  @override
  State<EcranGestionSitesAdmin> createState() => _EcranGestionSitesAdminState();
}

class _EcranGestionSitesAdminState extends State<EcranGestionSitesAdmin> {
  List<dynamic> _sites       = [];
  List<dynamic> _sitesFiltres = [];
  bool    _chargement = true;
  String? _erreur;
  final TextEditingController _rechercheController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerSites();
    _rechercheController.addListener(_filtrer);
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerSites() async {
    setState(() => _chargement = true);
    try {
      final data = await ApiService.getSites();
      setState(() {
        _sites        = data;
        _sitesFiltres = data;
        _chargement   = false;
      });
    } catch (_) {
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  void _filtrer() {
    final q = _rechercheController.text.toLowerCase();
    setState(() {
      _sitesFiltres = _sites.where((s) {
        final nom    = s['nom']?.toString().toLowerCase()    ?? '';
        final region = s['region']?.toString().toLowerCase() ?? '';
        return nom.contains(q) || region.contains(q);
      }).toList();
    });
  }

  Future<void> _supprimerSite(Map<String, dynamic> site) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Supprimer le site'),
        content: Text(
          'Voulez-vous supprimer "${site['nom']}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Annuler'),
          ),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await ApiService.supprimerSite(site['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content        : Text('Site supprimé avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      _chargerSites();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content        : Text('Erreur lors de la suppression.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sites (${_sitesFiltres.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerSites),
        ],
      ),
      body: _chargement
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
        : _erreur != null
          ? Center(child: Text(_erreur!))
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16),
                  child  : TextField(
                    controller: _rechercheController,
                    decoration: InputDecoration(
                      hintText     : 'Rechercher par nom ou région...',
                      prefixIcon   : const Icon(Icons.search),
                      border       : OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : BorderSide(color: Colors.grey.shade300),
                      ),
                      filled       : true,
                      fillColor    : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // Liste
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _chargerSites,
                    child    : _sitesFiltres.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun site trouvé.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding        : const EdgeInsets.symmetric(horizontal: 16),
                          itemCount      : _sitesFiltres.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder    : (context, index) {
                            final s = _sitesFiltres[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: s['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl  : s['image'].toString(),
                                        width     : 56,
                                        height    : 56,
                                        fit       : BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width : 56, height: 56,
                                          color : Colors.grey.shade200,
                                          child : const Icon(Icons.landscape,
                                            color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        width : 56, height: 56,
                                        color : Colors.grey.shade200,
                                        child : const Icon(Icons.landscape,
                                          color: Colors.grey),
                                      ),
                                ),
                                title: Text(
                                  s['nom']?.toString() ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['region']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                          size: 12, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          (double.tryParse(
                                            s['note_moyenne']?.toString() ?? '0',
                                          ) ?? 0).toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          (double.tryParse(
                                            s['prix_entree']?.toString() ?? '0',
                                          ) ?? 0) == 0
                                            ? 'Gratuit'
                                            : '${s['prix_entree']} FCFA',
                                          style: const TextStyle(
                                            fontSize : 11,
                                            color    : Color(0xFF009A44),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon     : const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                  onPressed: () => _supprimerSite(
                                    Map<String, dynamic>.from(s),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
