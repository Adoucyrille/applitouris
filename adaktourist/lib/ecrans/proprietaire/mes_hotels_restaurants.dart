// lib/ecrans/proprietaire/mes_hotels_restaurants.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../hebergement/ajout_hotel.dart';
import '../gastronomie/ajout_restaurant.dart';

class EcranMesHotelsRestaurants extends StatefulWidget {
  const EcranMesHotelsRestaurants({super.key});

  @override
  State<EcranMesHotelsRestaurants> createState() => _EcranMesHotelsRestaurantsState();
}

class _EcranMesHotelsRestaurantsState extends State<EcranMesHotelsRestaurants>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _hotels      = [];
  List<dynamic> _restaurants = [];
  bool          _chargement  = true;
  String?       _erreur;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final results = await Future.wait([
        ApiService.getMesHotels(),
        ApiService.getMesRestaurants(),
      ]);
      setState(() {
        _hotels      = results[0];
        _restaurants = results[1];
        _chargement  = false;
      });
    } catch (_) {
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title          : const Text('Mes établissements'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller        : _tabController,
          indicatorColor    : Colors.white,
          labelColor        : Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.hotel),
              text: 'Hôtels (${_hotels.length})',
            ),
            Tab(
              icon: const Icon(Icons.restaurant),
              text: 'Restaurants (${_restaurants.length})',
            ),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
          : _erreur != null
              ? Center(child: Text(_erreur!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ListeEtablissements(
                      elements   : _hotels,
                      type       : 'hotel',
                      onAjouter  : () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const EcranAjouterHotel()),
                        );
                        if (ok == true) _chargerDonnees();
                      },
                    ),
                    _ListeEtablissements(
                      elements   : _restaurants,
                      type       : 'restaurant',
                      onAjouter  : () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const EcranAjouterRestaurant()),
                        );
                        if (ok == true) _chargerDonnees();
                      },
                    ),
                  ],
                ),
    );
  }
}


class _ListeEtablissements extends StatelessWidget {
  final List<dynamic> elements;
  final String        type;
  final VoidCallback  onAjouter;

  const _ListeEtablissements({
    required this.elements,
    required this.type,
    required this.onAjouter,
  });

  bool get _estHotel => type == 'hotel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _estHotel ? const Color(0xFFF77F00) : const Color(0xFF009A44),
        onPressed      : onAjouter,
        icon           : const Icon(Icons.add, color: Colors.white),
        label          : Text(
          _estHotel ? 'Ajouter un hôtel' : 'Ajouter un restaurant',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: elements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _estHotel ? Icons.hotel : Icons.restaurant,
                    size : 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _estHotel
                        ? 'Vous n\'avez pas encore ajouté d\'hôtel.'
                        : 'Vous n\'avez pas encore ajouté de restaurant.',
                    style    : const TextStyle(color: Colors.grey, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onAjouter,
                    icon : const Icon(Icons.add),
                    label: Text(_estHotel ? 'Ajouter un hôtel' : 'Ajouter un restaurant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _estHotel
                          ? const Color(0xFFF77F00)
                          : const Color(0xFF009A44),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding    : const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount  : elements.length,
              itemBuilder: (context, index) {
                final item   = elements[index];
                final actif  = item['est_actif'] as bool? ?? true;

                return Card(
                  margin : const EdgeInsets.only(bottom: 12),
                  shape  : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: (_estHotel
                              ? const Color(0xFFF77F00)
                              : const Color(0xFF009A44))
                          .withValues(alpha: 0.15),
                      child: Icon(
                        _estHotel ? Icons.hotel : Icons.restaurant,
                        color: _estHotel
                            ? const Color(0xFFF77F00)
                            : const Color(0xFF009A44),
                      ),
                    ),
                    title: Text(
                      item['nom']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          item['adresse']?.toString() ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _estHotel
                                    ? const Color(0xFFF77F00).withValues(alpha: 0.1)
                                    : const Color(0xFF009A44).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _estHotel
                                    ? (item['gamme']?.toString() ?? '')
                                    : (item['type_cuisine']?.toString() ?? ''),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _estHotel
                                      ? const Color(0xFFF77F00)
                                      : const Color(0xFF009A44),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: actif
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                actif ? 'Actif' : 'Inactif',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: actif ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      _estHotel
                          ? '${(double.tryParse(item['prix_min']?.toString() ?? '0') ?? 0).toStringAsFixed(0)} FCFA'
                          : '${(double.tryParse(item['prix_moyen']?.toString() ?? '0') ?? 0).toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _estHotel
                            ? const Color(0xFFF77F00)
                            : const Color(0xFF009A44),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
