// lib/ecrans/hebergement/hotels.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'ajout_hotel.dart';

class EcranHotels extends StatefulWidget {
  final int?    siteId;     // si on veut les hôtels proches d'un site
  final int?    regionId;   // si on veut les hôtels d'une région
  final String  titre;

  const EcranHotels({
    super.key,
    this.siteId,
    this.regionId,
    this.titre = 'Hébergements',
  });

  @override
  State<EcranHotels> createState() => _EcranHotelsState();
}

class _EcranHotelsState extends State<EcranHotels> {
  List<dynamic> _hotels     = [];
  bool          _chargement = true;
  String?       _erreur;
  bool          _estAdmin   = false;

  @override
  void initState() {
    super.initState();
    _chargerHotels();
  }

  Future<void> _chargerHotels() async {
    try {
      final role = await ApiService.getRoleUtilisateur();
      List<dynamic> data;
      if (widget.siteId != null) {
        data = await ApiService.getHotelsProximite(widget.siteId!);
      } else if (widget.regionId != null) {
        data = await ApiService.getHotelsRegion(widget.regionId!);
      } else {
        data = [];
      }
      setState(() {
        _hotels     = data;
        _chargement = false;
        _estAdmin   = role == 'admin' || role == 'proprietaire';
      });
    } catch (_) {
      setState(() { _erreur = 'Impossible de charger les hôtels.'; _chargement = false; });
    }
  }

  // Convertit la gamme en étoiles
  Widget _etoilesGamme(String gamme) {
    final Map<String, int> etoiles = {
      'economique': 1,
      'standard'  : 2,
      'superieur' : 3,
      'luxe'      : 4,
    };
    final nb = etoiles[gamme] ?? 2;
    return Row(
      children: List.generate(
        nb,
        (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
      ),
    );
  }

  String _labelGamme(String gamme) {
    const labels = {
      'economique': 'Économique',
      'standard'  : 'Standard',
      'superieur' : 'Supérieur',
      'luxe'      : 'Luxe',
    };
    return labels[gamme] ?? gamme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _estAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFF77F00),
              onPressed: () async {
                final ajoute = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranAjouterHotel()),
                );
                if (ajoute == true) _chargerHotels();
              },
              icon : const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter un hôtel', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
          : _erreur != null
              ? Center(child: Text(_erreur!, style: const TextStyle(color: Colors.red)))
              : _hotels.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun hôtel disponible dans cette zone.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding    : const EdgeInsets.all(12),
                      itemCount  : _hotels.length,
                      itemBuilder: (context, index) {
                        final hotel = _hotels[index];
                        final gamme = hotel['gamme']?.toString() ?? 'standard';
                        final prixMin = double.tryParse(
                              hotel['prix_min']?.toString() ?? '0') ?? 0;
                        final distance = hotel['distance_km'];

                        return Card(
                          margin       : const EdgeInsets.only(bottom: 12),
                          shape        : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: hotel['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: hotel['image'],
                                        height  : 160,
                                        width   : double.infinity,
                                        fit     : BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          height: 160,
                                          color : Colors.grey.shade200,
                                          child : const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFF77F00),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          height: 160,
                                          color : Colors.grey.shade200,
                                          child : const Icon(
                                            Icons.hotel,
                                            size : 60,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 160,
                                        color : Colors.grey.shade200,
                                        child : const Icon(
                                          Icons.hotel,
                                          size : 60,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom + gamme
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            hotel['nom']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize  : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color       : const Color(0xFFF77F00).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _labelGamme(gamme),
                                            style: const TextStyle(
                                              color    : Color(0xFFF77F00),
                                              fontSize : 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    _etoilesGamme(gamme),
                                    const SizedBox(height: 8),

                                    // Adresse
                                    Row(
                                      children: [
                                        const Icon(Icons.place, size: 15, color: Color(0xFFF77F00)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            hotel['adresse']?.toString() ?? '',
                                            style: const TextStyle(
                                              color   : Colors.grey,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Prix et distance
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Prix
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color       : const Color(0xFF009A44),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            prixMin == 0
                                                ? 'Prix sur demande'
                                                : 'À partir de ${prixMin.toStringAsFixed(0)} FCFA',
                                            style: const TextStyle(
                                              color    : Colors.white,
                                              fontSize : 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        // Distance (si proximité)
                                        if (distance != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.near_me,
                                                size : 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$distance km',
                                                style: const TextStyle(
                                                  color  : Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),

                                    // Téléphone
                                    if ((hotel['telephone']?.toString() ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 15, color: Color(0xFF009A44)),
                                          const SizedBox(width: 4),
                                          Text(
                                            hotel['telephone'],
                                            style: const TextStyle(
                                              color  : Color(0xFF009A44),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
