// lib/ecrans/proprietaire/ajout_site.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/sites.dart';

class EcranAjouterSite extends StatefulWidget {
  final Site? siteAModifier;
  const EcranAjouterSite({super.key, this.siteAModifier});

  @override
  State<EcranAjouterSite> createState() => _EcranAjouterSiteState();
}

class _EcranAjouterSiteState extends State<EcranAjouterSite> {
  final _formKey          = GlobalKey<FormState>();
  final _nomController    = TextEditingController();
  final _descController   = TextEditingController();
  final _adresseController= TextEditingController();
  final _latController    = TextEditingController();
  final _lngController    = TextEditingController();
  final _prixController   = TextEditingController();

  List<dynamic> _regions    = [];
  List<dynamic> _categories = [];
  int?          _regionId;
  int?          _categorieId;
  XFile?        _image;
  Uint8List?    _imageBytes;
  // Photos supplémentaires (galerie)
  final List<XFile>     _photosSupp      = [];
  final List<Uint8List> _photosSuppBytes = [];
  bool          _chargement = false;
  String?       _erreur;

  final _picker = ImagePicker();

  bool get _estModification => widget.siteAModifier != null;

  @override
  void initState() {
    super.initState();
    _initialiserDonnees();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descController.dispose();
    _adresseController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _initialiserDonnees() async {
    await _chargerFiltres();
    if (_estModification && mounted) {
      _remplirFormulaire();
    }
  }

  void _remplirFormulaire() {
    final site = widget.siteAModifier!;
    _nomController.text    = site.nom;
    _descController.text   = site.description;
    _adresseController.text= site.adresse;
    _latController.text    = site.latitude.toString();
    _lngController.text    = site.longitude.toString();
    _prixController.text   = site.prixEntree.toString();
    
    setState(() {
      _regionId    = site.regionId; 
      _categorieId = site.categorieId;
    });
  }

  Future<void> _chargerFiltres() async {
    try {
      final regions    = await ApiService.getRegions();
      final categories = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        _regions    = regions;
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = 'Erreur lors du chargement des filtres.');
    }
  }

  Future<void> _choisirImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source      : source,
      imageQuality: 80,
      maxWidth    : 1200,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _image      = picked;
        _imageBytes = bytes;
      });
    }
  }

  void _afficherChoixImage() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading  : const Icon(Icons.camera_alt),
              title    : const Text('Prendre une photo'),
              onTap    : () {
                Navigator.pop(context);
                _choisirImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading  : const Icon(Icons.photo_library),
              title    : const Text('Choisir depuis la galerie'),
              onTap    : () {
                Navigator.pop(context);
                _choisirImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ajouterPhotoSupp() async {
    final picked = await _picker.pickImage(
      source      : ImageSource.gallery,
      imageQuality: 80,
      maxWidth    : 1200,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photosSupp.add(picked);
        _photosSuppBytes.add(bytes);
      });
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_regionId == null || _categorieId == null) {
      setState(() => _erreur = 'Veuillez choisir une région et une catégorie.');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur     = null;
    });

    try {
      Map<String, dynamic> resultat;

      if (_estModification) {
        resultat = await ApiService.modifierSite(
          siteId     : widget.siteAModifier!.id,
          nom        : _nomController.text,
          description: _descController.text,
          adresse    : _adresseController.text,
          latitude   : _latController.text,
          longitude  : _lngController.text,
          prixEntree : _prixController.text,
          regionId   : _regionId!,
          categorieId: _categorieId!,
          image      : _image,
        );
      } else {
        resultat = await ApiService.creerSite(
          nom        : _nomController.text,
          description: _descController.text,
          adresse    : _adresseController.text,
          latitude   : _latController.text,
          longitude  : _lngController.text,
          prixEntree : _prixController.text,
          regionId   : _regionId!,
          categorieId: _categorieId!,
          image      : _image,
        );
      }

      if (!mounted) return;

      // Récupérer l'ID du site créé/modifié pour uploader les photos supplémentaires
      final siteData = resultat['site'] ?? resultat;
      final siteId = siteData['id'] as int?
          ?? (widget.siteAModifier?.id);

      if (siteId != null && _photosSupp.isNotEmpty) {
        for (final photo in _photosSupp) {
          await ApiService.ajouterPhotoSite(siteId: siteId, image: photo);
        }
      }

      if (!mounted) return;
      if (resultat.containsKey('id') || resultat.containsKey('site') || resultat.containsKey('message')) {
        Navigator.pop(context);
      } else {
        setState(() => _erreur = resultat.toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionValide = _regions.any((r) => r['id'] == _regionId) ? _regionId : null;
    final catValide    = _categories.any((c) => c['id'] == _categorieId) ? _categorieId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_estModification ? 'Modifier le site' : 'Ajouter un site'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child  : Form(
          key  : _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller        : _nomController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText  : 'Nom du site',
                  prefixIcon : Icon(Icons.place),
                  border     : OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (v.length < 3) return 'Minimum 3 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller        : _descController,
                maxLines          : 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText  : 'Description',
                  prefixIcon : Icon(Icons.description),
                  border     : OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (v.length < 10) return 'Description trop courte (min. 10 caractères)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value     : regionValide,
                decoration: const InputDecoration(
                  labelText  : 'Région',
                  prefixIcon : Icon(Icons.map),
                  border     : OutlineInputBorder(),
                ),
                items: _regions.map<DropdownMenuItem<int>>((r) =>
                  DropdownMenuItem(value: r['id'] as int, child: Text(r['nom'] ?? ''))
                ).toList(),
                onChanged: (v) => setState(() => _regionId = v),
                validator: (v) => v == null ? 'Choisissez une région' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value     : catValide,
                decoration: const InputDecoration(
                  labelText  : 'Catégorie',
                  prefixIcon : Icon(Icons.category),
                  border     : OutlineInputBorder(),
                ),
                items: _categories.map<DropdownMenuItem<int>>((c) =>
                  DropdownMenuItem(value: c['id'] as int, child: Text(c['nom'] ?? ''))
                ).toList(),
                onChanged: (v) => setState(() => _categorieId = v),
                validator: (v) => v == null ? 'Choisissez une catégorie' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller        : _adresseController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText  : 'Adresse',
                  prefixIcon : Icon(Icons.location_on),
                  border     : OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (v.length < 5) return 'Adresse trop courte';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller  : _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border   : OutlineInputBorder(),
                        hintText : 'ex: 5.3484',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatoire';
                        final val = double.tryParse(v);
                        if (val == null) return 'Nombre invalide';
                        if (val < -90 || val > 90) return '-90 à 90';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller  : _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border   : OutlineInputBorder(),
                        hintText : 'ex: -4.0167',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatoire';
                        final val = double.tryParse(v);
                        if (val == null) return 'Nombre invalide';
                        if (val < -180 || val > 180) return '-180 à 180';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller  : _prixController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                decoration: const InputDecoration(
                  labelText  : 'Prix d\'entrée (FCFA)',
                  prefixIcon : Icon(Icons.attach_money),
                  border     : OutlineInputBorder(),
                  hintText   : '0 pour gratuit',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (int.tryParse(v) == null) return 'Chiffres uniquement';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Sélecteur d'image ─────────────────────────────
              const Text(
                'Photo du site',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _afficherChoixImage,
                child: Container(
                  height    : 180,
                  decoration: BoxDecoration(
                    color       : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border      : Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child       : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_imageBytes!, fit: BoxFit.cover),
                            Positioned(
                              top  : 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _image      = null;
                                  _imageBytes = null;
                                }),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color      : Colors.white,
                                    shape      : BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size : 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size : 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appuyez pour ajouter une photo',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Photos supplémentaires (galerie) ──────────────
              const Text(
                'Photos supplémentaires',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._photosSuppBytes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final bytes = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            bytes,
                            width : 90,
                            height: 90,
                            fit   : BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top  : 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _photosSupp.removeAt(index);
                              _photosSuppBytes.removeAt(index);
                            }),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.red, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _ajouterPhotoSupp,
                    child: Container(
                      width : 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color       : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border      : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size : 32,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_erreur != null)
                Container(
                  padding    : const EdgeInsets.all(12),
                  decoration : BoxDecoration(
                    color        : Colors.red.shade50,
                    borderRadius : BorderRadius.circular(8),
                  ),
                  child: Text(_erreur!, style: TextStyle(color: Colors.red.shade700)),
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _chargement ? null : _soumettre,
                child    : _chargement
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_estModification ? 'Modifier le site' : 'Publier le site', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}