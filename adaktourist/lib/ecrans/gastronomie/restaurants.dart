// lib/ecrans/gastronomie/restaurants.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'ajout_restaurant.dart';

class EcranRestaurants extends StatefulWidget {
  final int?    siteId;
  final int?    regionId;
  final String  titre;

  const EcranRestaurants({
    super.key,
    this.siteId,
    this.regionId,
    this.titre = 'Gastronomie',
  });

  @override
  State<EcranRestaurants> createState() => _EcranRestaurantsState();
}

class _EcranRestaurantsState extends State<EcranRestaurants> {
  List<dynamic> _restaurants = [];
  bool          _chargement  = true;
  String?       _erreur;
  bool          _estAdmin    = false;

  @override
  void initState() {
    super.initState();
    _chargerRestaurants();
  }

  Future<void> _chargerRestaurants() async {
    try {
      final role = await ApiService.getRoleUtilisateur();
      List<dynamic> data;
      if (widget.siteId != null) {
        data = await ApiService.getRestaurantsProximite(widget.siteId!);
      } else if (widget.regionId != null) {
        data = await ApiService.getRestaurantsRegion(widget.regionId!);
      } else {
        data = [];
      }
      setState(() {
        _restaurants = data;
        _chargement  = false;
        _estAdmin    = role == 'admin' || role == 'proprietaire';
      });
    } catch (_) {
      setState(() {
        _erreur     = 'Impossible de charger les restaurants.';
        _chargement = false;
      });
    }
  }

  // Icône selon le type de cuisine
  IconData _iconeCuisine(String type) {
    const icones = {
      'maquis'        : Icons.outdoor_grill,
      'ivoirienne'    : Icons.rice_bowl,
      'garba'         : Icons.set_meal,
      'africaine'     : Icons.local_dining,
      'libanaise'     : Icons.kebab_dining,
      'internationale': Icons.public,
      'rapide'        : Icons.fastfood,
      'fruits_mer'    : Icons.set_meal,
      'vegetarienne'  : Icons.eco,
    };
    return icones[type] ?? Icons.restaurant;
  }

  String _labelCuisine(String type) {
    const labels = {
      'maquis'        : 'Maquis',
      'ivoirienne'    : 'Cuisine Ivoirienne',
      'garba'         : 'Garba',
      'africaine'     : 'Cuisine Africaine',
      'libanaise'     : 'Cuisine Libanaise',
      'internationale': 'Internationale',
      'rapide'        : 'Restauration Rapide',
      'fruits_mer'    : 'Fruits de Mer',
      'vegetarienne'  : 'Végétarienne',
    };
    return labels[type] ?? type;
  }

  Color _couleurCuisine(String type) {
    const couleurs = {
      'maquis'        : Color(0xFFF77F00),
      'ivoirienne'    : Color(0xFF009A44),
      'garba'         : Color(0xFFE65100),
      'africaine'     : Color(0xFF6D4C41),
      'libanaise'     : Color(0xFF1565C0),
      'internationale': Color(0xFF6A1B9A),
      'rapide'        : Color(0xFFD32F2F),
      'fruits_mer'    : Color(0xFF0277BD),
      'vegetarienne'  : Color(0xFF2E7D32),
    };
    return couleurs[type] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title          : Text(widget.titre),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _estAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF009A44),
              onPressed: () async {
                final ajoute = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranAjouterRestaurant()),
                );
                if (ajoute == true) _chargerRestaurants();
              },
              icon : const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter un restaurant', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
          : _erreur != null
              ? Center(child: Text(_erreur!, style: const TextStyle(color: Colors.red)))
              : _restaurants.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun restaurant disponible dans cette zone.',
                            style   : TextStyle(color: Colors.grey, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding    : const EdgeInsets.all(12),
                      itemCount  : _restaurants.length,
                      itemBuilder: (context, index) {
                        final resto       = _restaurants[index];
                        final typeCuisine = resto['type_cuisine']?.toString() ?? 'ivoirienne';
                        final prixMoyen   = double.tryParse(
                              resto['prix_moyen']?.toString() ?? '0') ?? 0;
                        final distance    = resto['distance_km'];
                        final specialites = resto['specialites']?.toString() ?? '';

                        return Card(
                          margin   : const EdgeInsets.only(bottom: 12),
                          shape    : RoundedRectangleBorder(
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
                                child: Stack(
                                  children: [
                                    resto['image'] != null
                                        ? CachedNetworkImage(
                                            imageUrl  : resto['image'],
                                            height    : 160,
                                            width     : double.infinity,
                                            fit       : BoxFit.cover,
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
                                              child : Icon(
                                                _iconeCuisine(typeCuisine),
                                                size : 60,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            height: 160,
                                            color : Colors.grey.shade200,
                                            child : Icon(
                                              _iconeCuisine(typeCuisine),
                                              size : 60,
                                              color: Colors.grey,
                                            ),
                                          ),

                                    // Badge type cuisine
                                    Positioned(
                                      top  : 10,
                                      left : 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color       : _couleurCuisine(typeCuisine),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _iconeCuisine(typeCuisine),
                                              size : 13,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _labelCuisine(typeCuisine),
                                              style: const TextStyle(
                                                color    : Colors.white,
                                                fontSize : 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom + distance
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            resto['nom']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize  : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (distance != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.near_me,
                                                  size: 14, color: Colors.grey),
                                              const SizedBox(width: 3),
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
                                    const SizedBox(height: 6),

                                    // Adresse
                                    Row(
                                      children: [
                                        const Icon(Icons.place,
                                            size: 15, color: Color(0xFFF77F00)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            resto['adresse']?.toString() ?? '',
                                            style: const TextStyle(
                                              color  : Colors.grey,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Spécialités
                                    if (specialites.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.menu_book,
                                              size: 15, color: Color(0xFF009A44)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              specialites,
                                              style: const TextStyle(
                                                color  : Colors.black87,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),

                                    // Prix moyen + téléphone
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color       : const Color(0xFF009A44),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            prixMoyen == 0
                                                ? 'Prix variable'
                                                : 'Moy. ${prixMoyen.toStringAsFixed(0)} FCFA',
                                            style: const TextStyle(
                                              color    : Colors.white,
                                              fontSize : 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if ((resto['telephone']?.toString() ?? '')
                                            .isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.phone,
                                                  size: 15,
                                                  color: Color(0xFF009A44)),
                                              const SizedBox(width: 4),
                                              Text(
                                                resto['telephone'],
                                                style: const TextStyle(
                                                  color  : Color(0xFF009A44),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
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
