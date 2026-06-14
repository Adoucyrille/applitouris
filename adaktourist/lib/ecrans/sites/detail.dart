// lib/screens/sites/ecran_detail_site.dart
// Écran de détail d'un site touristique

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../auth/connexion.dart';
import '../reservation/reservation.dart';
import '../hebergement/hotels.dart';
import '../gastronomie/restaurants.dart';

class EcranDetailSite extends StatefulWidget {
  final int siteId;
  const EcranDetailSite({super.key, required this.siteId});

  @override
  State<EcranDetailSite> createState() => _EcranDetailSiteState();
}

class _EcranDetailSiteState extends State<EcranDetailSite> {
  Map<String, dynamic>? _site;
  bool   _chargement        = true;
  String? _erreur;

  List<dynamic> _hotelsProches      = [];
  List<dynamic> _restaurantsProches = [];

  // Avis
  int     _noteAvis              = 0;
  bool    _estConnecte           = false;
  bool    _envoiAvis             = false;
  String? _messageAvis;
  final TextEditingController _commentaireController = TextEditingController();

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _chargerSite();
  }

  void _ouvrirPhotoPleinEcran(BuildContext context, String imageUrl, String legende) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding   : EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit     : BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top  : 16,
              right: 16,
              child: IconButton(
                icon : const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (legende.isNotEmpty)
              Positioned(
                bottom: 24,
                left  : 16,
                right : 16,
                child : Text(
                  legende,
                  textAlign: TextAlign.center,
                  style    : const TextStyle(
                    color    : Colors.white,
                    fontSize : 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _chargerSite() async {
    final connecte = await ApiService.estConnecte();
    try {
      final results = await Future.wait([
        ApiService.getDetailSite(widget.siteId),
        ApiService.getHotelsProximite(widget.siteId),
        ApiService.getRestaurantsProximite(widget.siteId),
      ]);
      setState(() {
        _site               = results[0] as Map<String, dynamic>;
        _hotelsProches      = results[1] as List<dynamic>;
        _restaurantsProches = results[2] as List<dynamic>;
        _chargement         = false;
        _estConnecte        = connecte;
      });
    } catch (e) {
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  Future<void> _soumettreAvis() async {
    if (_noteAvis == 0) {
      setState(() => _messageAvis = 'Veuillez sélectionner une note.');
      return;
    }
    if (_commentaireController.text.trim().isEmpty) {
      setState(() => _messageAvis = 'Veuillez écrire un commentaire.');
      return;
    }
    setState(() { _envoiAvis = true; _messageAvis = null; });
    try {
      final resultat = await ApiService.soumettreAvis(
        siteId     : widget.siteId,
        note       : _noteAvis,
        commentaire: _commentaireController.text.trim(),
      );
      if (resultat.containsKey('avis') || resultat.containsKey('message')) {
        _commentaireController.clear();
        setState(() {
          _noteAvis    = 0;
          _messageAvis = 'Votre avis a été publié !';
        });
        await _chargerSite();
      } else {
        setState(() => _messageAvis =
          resultat['erreur']?.toString() ?? 'Une erreur est survenue.');
      }
    } catch (_) {
      setState(() => _messageAvis = 'Impossible de soumettre votre avis.');
    } finally {
      setState(() => _envoiAvis = false);
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

    if (_erreur != null || _site == null) {
      return Scaffold(
        appBar: AppBar(),
        body  : Center(child: Text(_erreur ?? 'Données indisponibles')),
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
              title    : Text(site['nom']?.toString() ?? 'Détails du site'),
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
                          ? (site['region']['nom']?.toString() ?? '')
                          : (site['region']?.toString() ?? 'Région inconnue'),
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
                          ? (site['categorie']['nom']?.toString() ?? '')
                          : (site['categorie']?.toString() ?? 'Général'),
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
                          color : i < (double.tryParse(site['note_moyenne']?.toString() ?? '0') ?? 0).round()
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
                          (double.tryParse(site['prix_entree']?.toString() ?? '0') ?? 0) == 0
                            ? 'Gratuit'
                            : '${(double.tryParse(site['prix_entree']?.toString() ?? '0') ?? 0).toStringAsFixed(0)} FCFA / personne',
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
                    site['description']?.toString() ?? 'Aucune description disponible.',
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
                        child: Text(site['adresse']?.toString() ?? 'Adresse non spécifiée'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Galerie de photos
                  if ((site['photos'] as List?)?.isNotEmpty ?? false) ...[
                    const Text(
                      'Photos du site',
                      style: TextStyle(
                        fontSize  : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount      : (site['photos'] as List).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final photo = (site['photos'] as List)[index];
                          final imageUrl = photo['image']?.toString() ?? '';
                          final legende  = photo['legende']?.toString() ?? '';
                          return GestureDetector(
                            onTap: () => _ouvrirPhotoPleinEcran(context, imageUrl, legende),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl  : imageUrl,
                                    width     : 240,
                                    height    : 180,
                                    fit       : BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width : 240,
                                      height: 180,
                                      color : Colors.grey.shade200,
                                      child : const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF77F00),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width : 240,
                                      height: 180,
                                      color : Colors.grey.shade200,
                                      child : const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (legende.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      left  : 0,
                                      right : 0,
                                      child : Container(
                                        padding   : const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin  : Alignment.bottomCenter,
                                            end    : Alignment.topCenter,
                                            colors : [
                                              Colors.black.withValues(alpha: 0.7),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          legende,
                                          style: const TextStyle(
                                            color    : Colors.white,
                                            fontSize : 12,
                                          ),
                                          maxLines : 1,
                                          overflow : TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

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
                                    avis['auteur']?.toString() ?? 'Anonyme',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      int.tryParse(avis['note']?.toString() ?? '0') ?? 0,
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
                              Text(avis['commentaire']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Formulaire d'avis
                  if (_estConnecte) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Laisser un avis',
                      style: TextStyle(
                        fontSize  : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sélecteur d'étoiles
                    Row(
                      children: List.generate(5, (i) => GestureDetector(
                        onTap: () => setState(() => _noteAvis = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            i < _noteAvis ? Icons.star : Icons.star_border,
                            size : 40,
                            color: i < _noteAvis ? Colors.amber : Colors.grey.shade400,
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 12),

                    // Champ commentaire
                    TextField(
                      controller: _commentaireController,
                      maxLines  : 3,
                      decoration: InputDecoration(
                        hintText     : 'Partagez votre expérience...',
                        border       : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide  : const BorderSide(
                            color: Color(0xFFF77F00), width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Message retour (erreur ou succès)
                    if (_messageAvis != null)
                      Container(
                        padding   : const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color       : _messageAvis!.contains('publié')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _messageAvis!,
                          style: TextStyle(
                            color: _messageAvis!.contains('publié')
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width     : double.infinity,
                      child     : ElevatedButton.icon(
                        onPressed: _envoiAvis ? null : _soumettreAvis,
                        icon     : _envoiAvis
                          ? const SizedBox(
                              width : 18, height: 18,
                              child : CircularProgressIndicator(
                                color      : Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                        label: Text(
                          _envoiAvis ? 'Envoi...' : 'Publier mon avis',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF77F00),
                          padding        : const EdgeInsets.symmetric(vertical: 14),
                          shape          : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EcranConnexion(),
                          ),
                        ),
                        icon : const Icon(Icons.login, color: Color(0xFFF77F00)),
                        label: const Text(
                          'Connectez-vous pour laisser un avis',
                          style: TextStyle(color: Color(0xFFF77F00)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Hôtels à proximité ──────────────────────
                  _SectionProximite(
                    titre    : 'Hôtels à proximité',
                    icone    : Icons.hotel,
                    couleur  : const Color(0xFFF77F00),
                    elements : _hotelsProches,
                    voirTout : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EcranHotels(
                          siteId: widget.siteId,
                          titre : 'Hôtels à proximité',
                        ),
                      ),
                    ),
                    construireItem: (item) => _CarteHotelMini(hotel: item),
                  ),

                  const SizedBox(height: 24),

                  // ── Restaurants à proximité ─────────────────
                  _SectionProximite(
                    titre    : 'Restaurants à proximité',
                    icone    : Icons.restaurant,
                    couleur  : const Color(0xFF009A44),
                    elements : _restaurantsProches,
                    voirTout : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EcranRestaurants(
                          siteId: widget.siteId,
                          titre : 'Restaurants à proximité',
                        ),
                      ),
                    ),
                    construireItem: (item) => _CarteRestaurantMini(restaurant: item),
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
        onPressed      : () async {
          final connecte = await ApiService.estConnecte();
          if (!mounted) return;
          if (!connecte) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title  : const Text('Connexion requise'),
                content: const Text(
                  'Vous devez être connecté pour effectuer une réservation.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child    : const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EcranConnexion(),
                        ),
                      );
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcranReservation(site: _site!),
            ),
          );
        },
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


// ─── Widget réutilisable : section "à proximité" ─────────────────────────────
class _SectionProximite extends StatelessWidget {
  final String        titre;
  final IconData      icone;
  final Color         couleur;
  final List<dynamic> elements;
  final VoidCallback  voirTout;
  final Widget Function(Map<String, dynamic>) construireItem;

  const _SectionProximite({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.elements,
    required this.voirTout,
    required this.construireItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icone, color: couleur, size: 22),
                const SizedBox(width: 8),
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: voirTout,
              child: Text(
                'Voir tout',
                style: TextStyle(color: couleur),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (elements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucun résultat à proximité.',
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection : Axis.horizontal,
              itemCount       : elements.length > 5 ? 5 : elements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  construireItem(elements[i] as Map<String, dynamic>),
            ),
          ),
      ],
    );
  }
}


// ─── Carte miniature : Hôtel ──────────────────────────────────────────────────
class _CarteHotelMini extends StatelessWidget {
  final Map<String, dynamic> hotel;
  const _CarteHotelMini({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final distance = hotel['distance_km'];
    final prixMin  = double.tryParse(hotel['prix_min']?.toString() ?? '0') ?? 0;

    return Container(
      width      : 150,
      decoration : BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow   : [
          BoxShadow(
            color        : Colors.black.withValues(alpha: 0.08),
            blurRadius   : 6,
            offset       : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: hotel['image'] != null
                ? CachedNetworkImage(
                    imageUrl  : hotel['image'],
                    height    : 90,
                    width     : 150,
                    fit       : BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderHotel(),
                  )
                : _placeholderHotel(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel['nom']?.toString() ?? '',
                  style   : const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  prixMin == 0
                      ? 'Prix sur demande'
                      : '${prixMin.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color    : Color(0xFF009A44),
                    fontSize : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (distance != null)
                  Text(
                    '$distance km',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderHotel() => Container(
    height: 90, width: 150,
    color : Colors.grey.shade200,
    child : const Icon(Icons.hotel, color: Colors.grey),
  );
}


// ─── Carte miniature : Restaurant ────────────────────────────────────────────
class _CarteRestaurantMini extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  const _CarteRestaurantMini({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final distance    = restaurant['distance_km'];
    final typeCuisine = restaurant['type_cuisine']?.toString() ?? '';

    return Container(
      width      : 150,
      decoration : BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow   : [
          BoxShadow(
            color     : Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset    : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: restaurant['image'] != null
                ? CachedNetworkImage(
                    imageUrl  : restaurant['image'],
                    height    : 90,
                    width     : 150,
                    fit       : BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderResto(),
                  )
                : _placeholderResto(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant['nom']?.toString() ?? '',
                  style   : const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color       : const Color(0xFFF77F00).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeCuisine == 'maquis' ? 'Maquis' : typeCuisine,
                    style: const TextStyle(
                      color    : Color(0xFFF77F00),
                      fontSize : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '$distance km',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderResto() => Container(
    height: 90, width: 150,
    color : Colors.grey.shade200,
    child : const Icon(Icons.restaurant, color: Colors.grey),
  );
}