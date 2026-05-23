// lib/screens/sites/ecran_detail_site.dart
// Écran de détail d'un site touristique

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../models/sites.dart';
import '../reservation/reservation.dart';

class EcranDetailSite extends StatefulWidget {
  final int siteId;
  const EcranDetailSite({super.key, required this.siteId});

  @override
  State<EcranDetailSite> createState() => _EcranDetailSiteState();
}

class _EcranDetailSiteState extends State<EcranDetailSite> {
  Map<String, dynamic>? _site;
  bool   _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerSite();
  }

  Future<void> _chargerSite() async {
    try {
      final data = await ApiService.getDetailSite(widget.siteId);
      setState(() {
        _site       = data;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF77F00)),
        ),
      );
    }

    if (_erreur != null) {
      return Scaffold(
        appBar: AppBar(),
        body  : Center(child: Text(_erreur!)),
      );
    }

    final site = _site!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image en en-tête
          SliverAppBar(
            expandedHeight : 250,
            pinned         : true,
            flexibleSpace  : FlexibleSpaceBar(
              title    : Text(site['nom']),
              background: site['image'] != null
                ? CachedNetworkImage(
                    imageUrl : site['image'],
                    fit      : BoxFit.cover,
                  )
                : Container(
                    color : Colors.grey.shade300,
                    child : const Icon(
                      Icons.landscape,
                      size : 80,
                      color: Colors.grey,
                    ),
                  ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Région et catégorie
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFF77F00),
                        size : 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        site['region'] is Map
                          ? site['region']['nom']
                          : site['region'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.category,
                        color: Color(0xFFF77F00),
                        size : 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        site['categorie'] is Map
                          ? site['categorie']['nom']
                          : site['categorie'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Note et prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Note
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star,
                          size  : 20,
                          color : i < (site['note_moyenne'] ?? 0).round()
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                        )),
                      ),
                      // Prix
                      Container(
                        padding    : const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,
                        ),
                        decoration : BoxDecoration(
                          color        : const Color(0xFF009A44),
                          borderRadius : BorderRadius.circular(20),
                        ),
                        child: Text(
                          double.parse(
                            site['prix_entree'].toString()
                          ) == 0
                            ? 'Gratuit'
                            : '${site['prix_entree']} FCFA / personne',
                          style: const TextStyle(
                            color      : Colors.white,
                            fontWeight : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize   : 18,
                      fontWeight : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    site['description'] ?? '',
                    style: const TextStyle(
                      height : 1.5,
                      color  : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Adresse
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: Color(0xFFF77F00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(site['adresse'] ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avis
                  const Text(
                    'Avis des visiteurs',
                    style: TextStyle(
                      fontSize   : 18,
                      fontWeight : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if ((site['avis'] as List?)?.isEmpty ?? true)
                    const Text(
                      'Aucun avis pour le moment.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...(site['avis'] as List).map((avis) =>
                      Card(
                        margin : const EdgeInsets.only(bottom: 8),
                        child  : Padding(
                          padding: const EdgeInsets.all(12),
                          child  : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    avis['auteur'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      avis['note'] ?? 0,
                                      (_) => const Icon(
                                        Icons.star,
                                        size : 14,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(avis['commentaire'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bouton réserver
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF77F00),
        onPressed      : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EcranReservation(site: _site!),
          ),
        ),
        icon  : const Icon(Icons.book_online, color: Colors.white),
        label : const Text(
          'Réserver',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation:
        FloatingActionButtonLocation.centerFloat,
    );
  }
}