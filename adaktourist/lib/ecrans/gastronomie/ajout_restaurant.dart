// lib/ecrans/gastronomie/ajout_restaurant.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class EcranAjouterRestaurant extends StatefulWidget {
  const EcranAjouterRestaurant({super.key});

  @override
  State<EcranAjouterRestaurant> createState() => _EcranAjouterRestaurantState();
}

class _EcranAjouterRestaurantState extends State<EcranAjouterRestaurant> {
  final _formKey        = GlobalKey<FormState>();
  final _nomController  = TextEditingController();
  final _descController = TextEditingController();
  final _adresseCtrl    = TextEditingController();
  final _telController  = TextEditingController();
  final _latController  = TextEditingController();
  final _lngController  = TextEditingController();
  final _specCtrl       = TextEditingController();
  final _prixController = TextEditingController();

  List<dynamic> _regions      = [];
  int?          _regionId;
  String        _typeCuisine  = 'maquis';
  XFile?        _image;
  Uint8List?    _imageBytes;
  bool          _chargement   = false;
  String?       _erreur;

  final _picker = ImagePicker();

  static const List<Map<String, String>> _typesCuisine = [
    {'id': 'maquis',         'label': 'Maquis (resto ivoirien typique)'},
    {'id': 'ivoirienne',     'label': 'Cuisine Ivoirienne'},
    {'id': 'garba',          'label': 'Garba (attiéké + thon)'},
    {'id': 'africaine',      'label': 'Cuisine Africaine'},
    {'id': 'libanaise',      'label': 'Cuisine Libanaise'},
    {'id': 'internationale', 'label': 'Cuisine Internationale'},
    {'id': 'rapide',         'label': 'Restauration Rapide'},
    {'id': 'fruits_mer',     'label': 'Fruits de Mer'},
    {'id': 'vegetarienne',   'label': 'Végétarienne'},
  ];

  @override
  void initState() {
    super.initState();
    _chargerRegions();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descController.dispose();
    _adresseCtrl.dispose();
    _telController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _specCtrl.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _chargerRegions() async {
    try {
      final data = await ApiService.getRegions();
      if (mounted) setState(() => _regions = data);
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Erreur de chargement des régions.');
    }
  }

  Future<void> _choisirImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title  : const Text('Prendre une photo'),
              onTap  : () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera, imageQuality: 80, maxWidth: 1200,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() { _image = picked; _imageBytes = bytes; });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title  : const Text('Choisir depuis la galerie'),
              onTap  : () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() { _image = picked; _imageBytes = bytes; });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_regionId == null) {
      setState(() => _erreur = 'Veuillez choisir une région.');
      return;
    }
    setState(() { _chargement = true; _erreur = null; });
    try {
      final resultat = await ApiService.creerRestaurant(
        nom         : _nomController.text.trim(),
        description : _descController.text.trim(),
        adresse     : _adresseCtrl.text.trim(),
        telephone   : _telController.text.trim(),
        latitude    : _latController.text.trim(),
        longitude   : _lngController.text.trim(),
        typeCuisine : _typeCuisine,
        specialites : _specCtrl.text.trim(),
        prixMoyen   : _prixController.text.trim(),
        regionId    : _regionId!,
        image       : _image,
      );
      if (!mounted) return;
      if (resultat.containsKey('id')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content        : Text('Restaurant ajouté avec succès !'),
            backgroundColor: Color(0xFF009A44),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _erreur = resultat['erreur']?.toString() ?? resultat.toString());
      }
    } catch (_) {
      setState(() => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionValide = _regions.any((r) => r['id'] == _regionId) ? _regionId : null;

    return Scaffold(
      appBar: AppBar(
        title          : const Text('Ajouter un restaurant'),
        backgroundColor: const Color(0xFF009A44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child  : Form(
          key  : _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Nom
              TextFormField(
                controller        : _nomController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText : 'Nom du restaurant',
                  prefixIcon: Icon(Icons.restaurant),
                  border    : OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                  if (v.trim().length < 3) return 'Minimum 3 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller        : _descController,
                maxLines          : 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText : 'Description',
                  prefixIcon: Icon(Icons.description),
                  border    : OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                  if (v.trim().length < 10) return 'Description trop courte (min. 10 caractères)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Région
              DropdownButtonFormField<int>(
                value    : regionValide,
                decoration: const InputDecoration(
                  labelText : 'Région',
                  prefixIcon: Icon(Icons.map),
                  border    : OutlineInputBorder(),
                ),
                items: _regions.map<DropdownMenuItem<int>>((r) =>
                  DropdownMenuItem(value: r['id'] as int, child: Text(r['nom'] ?? '')),
                ).toList(),
                onChanged: (v) => setState(() => _regionId = v),
                validator: (v) => v == null ? 'Choisissez une région' : null,
              ),
              const SizedBox(height: 16),

              // Type de cuisine
              DropdownButtonFormField<String>(
                value     : _typeCuisine,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText : 'Type de cuisine',
                  prefixIcon: Icon(Icons.outdoor_grill),
                  border    : OutlineInputBorder(),
                ),
                items: _typesCuisine.map((t) =>
                  DropdownMenuItem(value: t['id'], child: Text(t['label']!)),
                ).toList(),
                onChanged: (v) => setState(() => _typeCuisine = v ?? 'maquis'),
              ),
              const SizedBox(height: 16),

              // Spécialités
              TextFormField(
                controller        : _specCtrl,
                maxLines          : 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText : 'Spécialités du restaurant',
                  prefixIcon: Icon(Icons.menu_book),
                  border    : OutlineInputBorder(),
                  hintText  : 'ex: Kedjenou, Foutou, Aloko, Attiéké poisson',
                ),
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller        : _adresseCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText : 'Adresse',
                  prefixIcon: Icon(Icons.location_on),
                  border    : OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller     : _telController,
                keyboardType   : TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength      : 10,
                decoration     : const InputDecoration(
                  labelText   : 'Téléphone',
                  prefixIcon  : Icon(Icons.phone),
                  border      : OutlineInputBorder(),
                  hintText    : '0700000000',
                  counterText : '',
                ),
              ),
              const SizedBox(height: 16),

              // GPS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller  : _latController,
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border   : OutlineInputBorder(),
                        hintText : 'ex: 5.3484',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatoire';
                        final val = double.tryParse(v);
                        if (val == null) return 'Invalide';
                        if (val < -90 || val > 90) return '-90 à 90';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller  : _lngController,
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border   : OutlineInputBorder(),
                        hintText : 'ex: -4.0167',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatoire';
                        final val = double.tryParse(v);
                        if (val == null) return 'Invalide';
                        if (val < -180 || val > 180) return '-180 à 180';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Prix moyen
              TextFormField(
                controller     : _prixController,
                keyboardType   : TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText : 'Prix moyen par personne (FCFA)',
                  prefixIcon: Icon(Icons.attach_money),
                  border    : OutlineInputBorder(),
                  hintText  : 'ex: 3000',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (int.tryParse(v) == null) return 'Chiffres uniquement';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Photo
              const Text('Photo du restaurant', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _choisirImage,
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
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_imageBytes!, fit: BoxFit.cover),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() { _image = null; _imageBytes = null; }),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.red, size: 22),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Appuyez pour ajouter une photo', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              if (_erreur != null)
                Container(
                  padding   : const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color       : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_erreur!, style: TextStyle(color: Colors.red.shade700)),
                ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _chargement ? null : _soumettre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009A44),
                  padding        : const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _chargement
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publier le restaurant', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
