// lib/screens/auth/ecran_inscription.dart
// Écran d'inscription — permet de créer un nouveau compte

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../sites/accueil.dart';

class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  final _formKey            = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _telephoneController= TextEditingController();
  final _passwordController = TextEditingController();

  String  _roleSelectionne  = 'touriste';
  bool    _chargement       = false;
  String? _erreur;

  @override
  void dispose() {
    _usernameController.dispose();
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
        email     : _emailController.text.trim(),
        telephone : _telephoneController.text.trim(),
        role      : _roleSelectionne,
        motDePasse: _passwordController.text.trim(),
      );

      if (resultat.containsKey('access_token')) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EcranAccueil()),
          );
        }
      } else {
        setState(() {
          _erreur = resultat.toString();
        });
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
              // Champ username
              TextFormField(
                controller : _usernameController,
                decoration : const InputDecoration(
                  labelText  : 'Nom d\'utilisateur',
                  prefixIcon : Icon(Icons.person),
                  border     : OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                  ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Champ email
              TextFormField(
                controller   : _emailController,
                keyboardType : TextInputType.emailAddress,
                decoration   : const InputDecoration(
                  labelText  : 'Email',
                  prefixIcon : Icon(Icons.email),
                  border     : OutlineInputBorder(),
                ),
                validator: (val) => val == null || !val.contains('@')
                  ? 'Email invalide' : null,
              ),
              const SizedBox(height: 16),

              // Champ téléphone
              TextFormField(
                controller   : _telephoneController,
                keyboardType : TextInputType.phone,
                decoration   : const InputDecoration(
                  labelText  : 'Téléphone (+225...)',
                  prefixIcon : Icon(Icons.phone),
                  border     : OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                  ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Sélection du rôle
              DropdownButtonFormField<String>(
                value     : _roleSelectionne,
                decoration: const InputDecoration(
                  labelText  : 'Je suis',
                  prefixIcon : Icon(Icons.badge),
                  border     : OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value : 'touriste',
                    child : Text('Touriste'),
                  ),
                  DropdownMenuItem(
                    value : 'proprietaire',
                    child : Text('Propriétaire de site'),
                  ),
                ],
                onChanged: (val) =>
                  setState(() => _roleSelectionne = val!),
              ),
              const SizedBox(height: 16),

              // Champ mot de passe
              TextFormField(
                controller  : _passwordController,
                obscureText : true,
                decoration  : const InputDecoration(
                  labelText  : 'Mot de passe',
                  prefixIcon : Icon(Icons.lock),
                  border     : OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.length < 8
                  ? 'Minimum 8 caractères' : null,
              ),
              const SizedBox(height: 16),

              // Message d'erreur
              if (_erreur != null)
                Container(
                  padding    : const EdgeInsets.all(12),
                  decoration : BoxDecoration(
                    color        : Colors.red.shade50,
                    borderRadius : BorderRadius.circular(8),
                    border       : Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _erreur!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 24),

              // Bouton inscription
              ElevatedButton(
                onPressed: _chargement ? null : _inscrire,
                child: _chargement
                  ? const CircularProgressIndicator(color: Colors.white)
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