// lib/screens/auth/ecran_inscription.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../sites/accueil.dart';

class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  final _formKey              = GlobalKey<FormState>();
  final _usernameController   = TextEditingController();
  final _prenomController     = TextEditingController();
  final _nomController        = TextEditingController();
  final _emailController      = TextEditingController();
  final _telephoneController  = TextEditingController();
  final _passwordController   = TextEditingController();

  String  _roleSelectionne      = 'touriste';
  bool    _chargement           = false;
  bool    _afficherMotDePasse   = false;
  String? _erreur;

  @override
  void dispose() {
    _usernameController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _chargement = true;
      _erreur     = null;
    });

    try {
      final resultat = await ApiService.inscrire(
        username  : _usernameController.text.trim(),
        nom       : _nomController.text.trim(),
        prenom    : _prenomController.text.trim(),
        email     : _emailController.text.trim(),
        telephone : _telephoneController.text.trim(),
        role      : _roleSelectionne,
        motDePasse: _passwordController.text,
      );

      if (resultat.containsKey('access_token')) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EcranAccueil()),
          );
        }
      } else {
        setState(() => _erreur = resultat.toString());
      }
    } catch (e) {
      setState(() => _erreur = 'Impossible de contacter le serveur.');
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Nom d'utilisateur ─────────────────────────
              TextFormField(
                controller    : _usernameController,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9._@\-]'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText  : 'Nom d\'utilisateur',
                  prefixIcon : Icon(Icons.alternate_email),
                  border     : OutlineInputBorder(),
                  hintText   : 'ex: jean_dupont',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ obligatoire';
                  if (val.length < 3) return 'Minimum 3 caractères';
                  if (!RegExp(r'^[a-zA-Z0-9._@\-]+$').hasMatch(val)) {
                    return 'Caractères autorisés : lettres, chiffres, . _ @ -';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Prénom & Nom sur la même ligne ────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller        : _prenomController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters   : [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-ZÀ-ÿ \-']"),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText  : 'Prénom',
                        prefixIcon : Icon(Icons.person_outline),
                        border     : OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Obligatoire';
                        if (val.length < 2) return 'Trop court';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller        : _nomController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters   : [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-ZÀ-ÿ \-']"),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText  : 'Nom',
                        prefixIcon : Icon(Icons.person),
                        border     : OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Obligatoire';
                        if (val.length < 2) return 'Trop court';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────────
              TextFormField(
                controller   : _emailController,
                keyboardType : TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: const InputDecoration(
                  labelText  : 'Email',
                  prefixIcon : Icon(Icons.email),
                  border     : OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ obligatoire';
                  if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(val)) {
                    return 'Adresse email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Téléphone (chiffres uniquement) ───────────
              TextFormField(
                controller   : _telephoneController,
                keyboardType : TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: const InputDecoration(
                  labelText  : 'Téléphone',
                  prefixIcon : Icon(Icons.phone),
                  border     : OutlineInputBorder(),
                  hintText   : '+225XXXXXXXXXX',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ obligatoire';
                  final chiffres = val.replaceAll('+', '');
                  if (!RegExp(r'^\d+$').hasMatch(chiffres)) {
                    return 'Le téléphone ne doit contenir que des chiffres';
                  }
                  if (chiffres.length < 8) return 'Numéro trop court';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Rôle ──────────────────────────────────────
              DropdownButtonFormField<String>(
                value     : _roleSelectionne,
                decoration: const InputDecoration(
                  labelText  : 'Je suis',
                  prefixIcon : Icon(Icons.badge),
                  border     : OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'touriste',
                    child: Text('Touriste'),
                  ),
                  DropdownMenuItem(
                    value: 'proprietaire',
                    child: Text('Propriétaire de site'),
                  ),
                ],
                onChanged: (val) => setState(() => _roleSelectionne = val!),
              ),
              const SizedBox(height: 16),

              // ── Mot de passe ──────────────────────────────
              TextFormField(
                controller  : _passwordController,
                obscureText : !_afficherMotDePasse,
                decoration  : InputDecoration(
                  labelText  : 'Mot de passe',
                  prefixIcon : const Icon(Icons.lock),
                  border     : const OutlineInputBorder(),
                  suffixIcon : IconButton(
                    icon: Icon(
                      _afficherMotDePasse
                        ? Icons.visibility_off
                        : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _afficherMotDePasse = !_afficherMotDePasse,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ obligatoire';
                  if (val.length < 8) return 'Minimum 8 caractères';
                  if (!RegExp(r'[A-Z]').hasMatch(val)) {
                    return 'Au moins une lettre majuscule requise';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(val)) {
                    return 'Au moins un chiffre requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Message d'erreur ──────────────────────────
              if (_erreur != null)
                Container(
                  padding   : const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color       : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border      : Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _erreur!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 24),

              // ── Bouton inscription ────────────────────────
              ElevatedButton(
                onPressed: _chargement ? null : _inscrire,
                child: _chargement
                  ? const SizedBox(
                      height: 20,
                      width : 20,
                      child : CircularProgressIndicator(
                        color      : Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Créer mon compte',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
