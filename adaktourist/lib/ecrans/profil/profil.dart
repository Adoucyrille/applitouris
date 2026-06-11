// lib/screens/profil/ecran_profil.dart
// Écran profil — affiche les informations de l'utilisateur connecté

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../models/utilisateur.dart';
import '../auth/connexion.dart';

class EcranProfil extends StatefulWidget {
  const EcranProfil({super.key});

  @override
  State<EcranProfil> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfil> {
  Utilisateur? _utilisateur;
  bool    _chargement      = true;
  bool    _envoiPhoto      = false;
  String? _erreur;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
  try {
    // On appelle directement getProfil() sans stocker les headers séparément
    final reponse = await ApiService.getProfil();
    setState(() {
      _utilisateur = Utilisateur.fromJson(reponse);
      _chargement  = false;
    });
  } catch (e) {
    setState(() {
      _erreur     = 'Erreur de chargement du profil.';
      _chargement = false;
    });
  }
}

  Future<void> _choisirPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source      : source,
      imageQuality: 80,
      maxWidth    : 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _envoiPhoto = true);
    try {
      final result = await ApiService.mettreAJourPhotoProfil(picked);
      if (mounted) {
        setState(() => _utilisateur = Utilisateur.fromJson(result));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')),
        );
      }
    } finally {
      if (mounted) setState(() => _envoiPhoto = false);
    }
  }

  void _afficherChoixPhoto() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading : const Icon(Icons.camera_alt),
              title   : const Text('Prendre une photo'),
              onTap   : () {
                Navigator.pop(context);
                _choisirPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading : const Icon(Icons.photo_library),
              title   : const Text('Choisir depuis la galerie'),
              onTap   : () {
                Navigator.pop(context);
                _choisirPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deconnecter() async {
    await ApiService.supprimerTokens();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EcranConnexion()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title  : const Text('Mon profil'),
        actions: [
          IconButton(
            icon     : const Icon(Icons.logout),
            tooltip  : 'Déconnexion',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title  : const Text('Déconnexion'),
                content: const Text('Voulez-vous vous déconnecter ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child    : const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: _deconnecter,
                    style    : ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Déconnexion'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _chargement
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF77F00)),
          )
        : _erreur != null
          ? Center(child: Text(_erreur!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child  : Column(
                children: [

                  // Avatar cliquable
                  GestureDetector(
                    onTap: _envoiPhoto ? null : _afficherChoixPhoto,
                    child: SizedBox(
                      width : 110,
                      height: 110,
                      child : Stack(
                        children: [
                          Center(
                            child: _envoiPhoto
                              ? const SizedBox(
                                  width : 100,
                                  height: 100,
                                  child : CircularProgressIndicator(
                                    color: Color(0xFFF77F00),
                                  ),
                                )
                              : CircleAvatar(
                                  radius         : 50,
                                  backgroundColor: const Color(0xFFF77F00),
                                  child          : _utilisateur!.photo != null
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl   : _utilisateur!.photo!,
                                          width      : 100,
                                          height     : 100,
                                          fit        : BoxFit.cover,
                                          errorWidget: (_, __, ___) => Text(
                                            _utilisateur!.username[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize  : 40,
                                              color     : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _utilisateur!.username[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize  : 40,
                                          color     : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                          ),
                          Positioned(
                            bottom: 0,
                            right : 0,
                            child : Container(
                              padding   : const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF77F00),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size : 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nom d'utilisateur
                  Text(
                    _utilisateur!.username,
                    style: const TextStyle(
                      fontSize   : 24,
                      fontWeight : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Badge rôle
                  Container(
                    padding    : const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4,
                    ),
                    decoration : BoxDecoration(
                      color        : const Color(0xFFF77F00).withValues(alpha: 0.1),
                      borderRadius : BorderRadius.circular(20),
                      border       : Border.all(
                        color: const Color(0xFFF77F00),
                      ),
                    ),
                    child: Text(
                      _utilisateur!.estAdmin
                        ? '👑 Administrateur'
                        : _utilisateur!.estProprietaire
                          ? '🏨 Propriétaire de site'
                          : '🧳 Touriste',
                      style: const TextStyle(
                        color     : Color(0xFFF77F00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informations
                  _carteInfo(
                    icone  : Icons.email,
                    label  : 'Email',
                    valeur : _utilisateur!.email,
                  ),
                  const SizedBox(height: 12),
                  _carteInfo(
                    icone  : Icons.phone,
                    label  : 'Téléphone',
                    valeur : _utilisateur!.telephone.isEmpty
                               ? 'Non renseigné'
                               : _utilisateur!.telephone,
                  ),
                  const SizedBox(height: 32),

                  // Bouton déconnexion
                  OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title  : const Text('Déconnexion'),
                        content: const Text(
                          'Voulez-vous vous déconnecter ?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child    : const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: _deconnecter,
                            style    : ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Déconnexion'),
                          ),
                        ],
                      ),
                    ),
                    icon : const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side   : const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _carteInfo({
    required IconData icone,
    required String   label,
    required String   valeur,
  }) {
    return Container(
      padding    : const EdgeInsets.all(16),
      decoration : BoxDecoration(
        color        : Colors.grey.shade50,
        borderRadius : BorderRadius.circular(12),
        border       : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icone, color: const Color(0xFFF77F00)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color    : Colors.grey,
                  fontSize : 12,
                ),
              ),
              Text(
                valeur,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}