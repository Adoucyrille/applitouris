// lib/ecrans/sites/carte.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/sites.dart';
import 'detail.dart';

class EcranCarte extends StatefulWidget {
  final List<Site> sites;
  const EcranCarte({super.key, required this.sites});

  @override
  State<EcranCarte> createState() => _EcranCarteState();
}

class _EcranCarteState extends State<EcranCarte> {
  // ✅ _mapController supprimé car inutilisé
  Set<Marker> _marqueurs = {};

  // Position centrale de la Côte d'Ivoire
  static const LatLng _centreCI = LatLng(7.539989, -5.547080);

  @override
  void initState() {
    super.initState();
    _creerMarqueurs();
  }

  void _creerMarqueurs() {
    setState(() {
      _marqueurs = widget.sites.map((site) => Marker(
        markerId  : MarkerId(site.id.toString()),
        position  : LatLng(site.latitude, site.longitude),
        infoWindow: InfoWindow(
          title   : site.nom,
          snippet : '${site.prixEntree == 0 ? "Gratuit" : "${site.prixEntree.toStringAsFixed(0)} FCFA"} • ⭐ ${site.noteMoyenne.toStringAsFixed(1)}',
          onTap   : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcranDetailSite(siteId: site.id),
            ),
          ),
        ),
      )).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carte (${widget.sites.length} sites)'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target : _centreCI,
          zoom   : 7,
        ),
        markers              : _marqueurs,
        myLocationEnabled    : true,
        myLocationButtonEnabled: true,
        // ✅ onMapCreated supprimé car _mapController inutilisé
      ),
    );
  }
}