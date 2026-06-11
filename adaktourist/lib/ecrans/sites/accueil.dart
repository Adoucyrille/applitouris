// lib/ecrans/sites/accueil.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../models/sites.dart';
import 'detail.dart';
import 'carte.dart';
import '../auth/connexion.dart';
import '../reservation/mes_reservations.dart';
import '../profil/profil.dart';
import '../proprietaire/mes_sites.dart';
import '../proprietaire/reservations_sites.dart';
import '../reservation/reservation.dart';


class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  List<Site>                 _sites              = [];
  List<Map<String, dynamic>> _regions            = [];
  bool                       _chargement         = true;
  bool                       _estConnecte        = false;
  String?                    _erreur;
  String?                    _regionSelectionnee;
  String?                    _categorieSelectionnee;
  String                     _roleUtilisateur    = 'touriste';
  final _rechercheController = TextEditingController();
  int _indexNavigation = 0;

  @override
  void initState() {
    super.initState();
    _initialiserEtat();
  }

  Future<void> _initialiserEtat() async {
    final connecte = await ApiService.estConnecte();
    setState(() => _estConnecte = connecte);
    await _chargerDonnees();
    if (connecte) await _chargerRole();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  // ── Charger le rôle de l'utilisateur connecté ─────────────
  Future<void> _chargerRole() async {
    final role = await ApiService.getRoleUtilisateur();
    setState(() => _roleUtilisateur = role);
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final resultats = await Future.wait([
        ApiService.getSites(
          regionId    : _regionSelectionnee,
          categorieId : _categorieSelectionnee,
          recherche   : _rechercheController.text.isEmpty
                          ? null
                          : _rechercheController.text,
        ),
        ApiService.getRegions(),
        ApiService.getCategories(),
      ]);

      setState(() {
        _sites   = (resultats[0] as List<dynamic>)
                    .map((s) => Site.fromJson(s as Map<String, dynamic>))
                    .toList();
        _regions = List<Map<String, dynamic>>.from(resultats[1]);
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur     = 'Erreur de chargement. Vérifiez votre connexion.';
        _chargement = false;
      });
    }
  }

  Future<void> _deconnecter() async {
    await ApiService.supprimerTokens();
    if (mounted) {
      setState(() {
        _estConnecte     = false;
        _roleUtilisateur = 'touriste';
        _indexNavigation = 0;
      });
    }
  }

  // ── Rediriger vers la connexion et réinitialiser après retour
  Future<void> _allerALaConnexion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EcranConnexion()),
    );
    // Après retour depuis la connexion, on recharge l'état
    if (mounted) await _initialiserEtat();
  }

  // ── Bloquer l'action et proposer la connexion ──────────────
  void _demanderConnexion() {
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
              _allerALaConnexion();
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  // ── Construire les items de navigation selon l'état ───────
  List<BottomNavigationBarItem> get _itemsNavigation {
    if (!_estConnecte) {
      return const [
        BottomNavigationBarItem(
          icon : Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon : Icon(Icons.login),
          label: 'Se connecter',
        ),
      ];
    }

    final estProprietaire = _roleUtilisateur == 'proprietaire';
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon : Icon(Icons.home),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon : const Icon(Icons.book_online),
        label: estProprietaire ? 'Réserv. reçues' : 'Réservations',
      ),
    ];

    if (estProprietaire) {
      items.add(const BottomNavigationBarItem(
        icon : Icon(Icons.add_business),
        label: 'Mes sites',
      ));
    }

    items.add(const BottomNavigationBarItem(
      icon : Icon(Icons.person),
      label: 'Profil',
    ));

    return items;
  }

  // ── Gérer la navigation ────────────────────────────────────
  void _gererNavigation(int index) {
    setState(() => _indexNavigation = index);

    if (index == 0) return;

    // Utilisateur non connecté → onglet "Se connecter"
    if (!_estConnecte) {
      _allerALaConnexion().then((_) => setState(() => _indexNavigation = 0));
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _roleUtilisateur == 'proprietaire'
            ? const EcranReservationsSites()
            : const EcranMesReservations(),
        ),
      ).then((_) => setState(() => _indexNavigation = 0));
      return;
    }

    if (_roleUtilisateur == 'proprietaire') {
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EcranMesSites()),
        ).then((_) => setState(() => _indexNavigation = 0));
        return;
      }
      if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EcranProfil()),
        ).then((_) => setState(() => _indexNavigation = 0));
        return;
      }
    } else {
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EcranProfil()),
        ).then((_) => setState(() => _indexNavigation = 0));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADAKTourist'),
        actions: [
          IconButton(
            icon     : const Icon(Icons.map),
            tooltip  : 'Voir la carte',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EcranCarte(sites: _sites),
              ),
            ),
          ),
          if (_estConnecte)
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value : 'deconnecter',
                  child : Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'deconnecter') _deconnecter();
              },
            )
          else
            TextButton.icon(
              onPressed: _allerALaConnexion,
              icon : const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Connexion',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),

      // ── Barre de navigation dynamique ─────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex     : _indexNavigation,
        selectedItemColor: const Color(0xFFF77F00),
        unselectedItemColor: Colors.grey,
        onTap            : _gererNavigation,
        items            : _itemsNavigation,
      ),

      body: Column(
        children: [
          // Barre de recherche
          Container(
            color   : const Color(0xFFF77F00),
            padding : const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child   : TextField(
              controller : _rechercheController,
              decoration : InputDecoration(
                hintText  : 'Rechercher un site touristique par catégories',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon     : const Icon(Icons.clear),
                  onPressed: () {
                    _rechercheController.clear();
                    _chargerDonnees();
                  },
                ),
                filled   : true,
                fillColor: Colors.white,
                border   : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide  : BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _chargerDonnees(),
            ),
          ),

          // Filtres par région
          SizedBox(
            height: 50,
            child : ListView(
              scrollDirection: Axis.horizontal,
              padding        : const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8,
              ),
              children: [
                _chipFiltre(
                  label      : 'Tous',
                  selectionne: _regionSelectionnee == null,
                  onTap      : () {
                    setState(() => _regionSelectionnee = null);
                    _chargerDonnees();
                  },
                ),
                ..._regions.map((r) => _chipFiltre(
                  label      : r['nom'],
                  selectionne: _regionSelectionnee == r['id'].toString(),
                  onTap      : () {
                    setState(() => _regionSelectionnee = r['id'].toString());
                    _chargerDonnees();
                  },
                )),
              ],
            ),
          ),

          // Liste des sites
          Expanded(
            child: _chargement
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF77F00),
                  ),
                )
              : _erreur != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size : 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(_erreur!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _chargerDonnees,
                          child    : const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _sites.isEmpty
                  ? const Center(
                      child: Text('Aucun site trouvé.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _chargerDonnees,
                      child    : ListView.builder(
                        padding    : const EdgeInsets.all(12),
                        itemCount  : _sites.length,
                        itemBuilder: (context, index) =>
                          _carteSite(_sites[index]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
 
 Widget _carteSite(Site site) {
  return Card(
    margin   : const EdgeInsets.only(bottom: 12),
    elevation: 3,
    shape    : RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image cliquable ──────────────────────────
        InkWell(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcranDetailSite(siteId: site.id),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: site.image != null
              ? CachedNetworkImage(
                  imageUrl   : site.image!,
                  height     : 180,
                  width      : double.infinity,
                  fit        : BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color : Colors.grey.shade200,
                    child : const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color : Colors.grey.shade200,
                    child : const Icon(
                      Icons.image_not_supported,
                      size : 64,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  height: 180,
                  color : Colors.grey.shade200,
                  child : const Icon(
                    Icons.landscape,
                    size : 64,
                    color: Colors.grey,
                  ),
                ),
          ),
        ),

        // ── Informations ─────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child  : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Nom et note
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      site.nom,
                      style: const TextStyle(
                        fontSize  : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        site.noteMoyenne.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Région
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  Text(
                    site.region,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Prix et catégorie
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding   : const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color       : const Color(0xFFF77F00)
                                      .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      site.categorie,
                      style: const TextStyle(
                        color: Color(0xFFF77F00), fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    site.prixEntree == 0
                      ? 'Gratuit'
                      : '${site.prixEntree.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color     : Color(0xFF009A44),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Boutons d'action ──────────────────
              Row(
                children: [
                  // Bouton Détails
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EcranDetailSite(siteId: site.id),
                        ),
                      ),
                      icon : const Icon(Icons.info_outline, size: 16),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF77F00),
                        side   : const BorderSide(color: Color(0xFFF77F00)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!_estConnecte) {
                          _demanderConnexion();
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EcranReservation(site: {
                              'id'          : site.id,
                              'nom'         : site.nom,
                              'prix_entree' : site.prixEntree,
                              'image'       : site.image,
                              'region'      : site.region,
                              'categorie'   : site.categorie,
                              'note_moyenne': site.noteMoyenne,
                            }),
                          ),
                        );
                      },
                      icon : const Icon(Icons.book_online, size: 16),
                      label: const Text('Réserver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF77F00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _chipFiltre({
    required String       label,
    required bool         selectionne,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin    : const EdgeInsets.only(right: 8),
        padding   : const EdgeInsets.symmetric(
          horizontal: 12, vertical: 4,
        ),
        decoration: BoxDecoration(
          color       : selectionne
                          ? const Color(0xFFF77F00)
                          : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color     : selectionne ? Colors.white : Colors.black87,
            fontWeight: selectionne
                          ? FontWeight.bold
                          : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}