// lib/screens/auth/ecran_connexion.dart
// Écran de connexion — permet à l'utilisateur de se connecter

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../sites/accueil.dart';
import 'inscription.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  // Contrôleurs pour récupérer les valeurs des champs
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  bool _chargement      = false;
  bool _afficherMotDePasse = false;
  String? _erreur;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction de connexion appelée au clic du bouton
  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _chargement = true;
      _erreur     = null;
    });

    try {
      final resultat = await ApiService.connecter(
        username : _usernameController.text.trim(),
        password : _passwordController.text.trim(),
      );

      if (resultat.containsKey('access_token')) {
        // Connexion réussie → aller à l'accueil
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EcranAccueil()),
          );
        }
      } else {
        setState(() {
          _erreur = resultat['erreur'] ?? 'Erreur de connexion.';
        });
      }
    } catch (e) {
      setState(() {
        _erreur = 'Impossible de contacter le serveur.';
      });
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo et titre
                const Icon(
                  Icons.travel_explore,
                  size  : 80,
                  color : Color(0xFFF77F00),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ADAKTourist',
                  textAlign : TextAlign.center,
                  style     : TextStyle(
                    fontSize   : 28,
                    fontWeight : FontWeight.bold,
                    color      : Color(0xFFF77F00),
                  ),
                ),
                const Text(
                  'Découvrez la Côte d\'Ivoire',
                  textAlign : TextAlign.center,
                  style     : TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),

                // Champ nom d'utilisateur
                TextFormField(
                  controller  : _usernameController,
                  decoration  : const InputDecoration(
                    labelText  : 'Nom d\'utilisateur',
                    prefixIcon : Icon(Icons.person),
                    border     : OutlineInputBorder(),
                  ),
                  validator: (val) =>
                    val == null || val.isEmpty
                      ? 'Champ obligatoire'
                      : null,
                ),
                const SizedBox(height: 16),

                // Champ mot de passe
                TextFormField(
                  controller   : _passwordController,
                  obscureText  : !_afficherMotDePasse,
                  decoration   : InputDecoration(
                    labelText  : 'Mot de passe',
                    prefixIcon : const Icon(Icons.lock),
                    border     : const OutlineInputBorder(),
                    suffixIcon : IconButton(
                      icon    : Icon(
                        _afficherMotDePasse
                          ? Icons.visibility_off
                          : Icons.visibility,
                      ),
                      onPressed: () => setState(() =>
                        _afficherMotDePasse = !_afficherMotDePasse
                      ),
                    ),
                  ),
                  validator: (val) =>
                    val == null || val.isEmpty
                      ? 'Champ obligatoire'
                      : null,
                ),
                const SizedBox(height: 16),

                // Message d'erreur
                if (_erreur != null)
                  Container(
                    padding      : const EdgeInsets.all(12),
                    decoration   : BoxDecoration(
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

                // Bouton de connexion
                ElevatedButton(
                  onPressed: _chargement ? null : _connecter,
                  child: _chargement
                    ? const SizedBox(
                        height : 20,
                        width  : 20,
                        child  : CircularProgressIndicator(
                          color       : Colors.white,
                          strokeWidth : 2,
                        ),
                      )
                    : const Text(
                        'Se connecter',
                        style: TextStyle(fontSize: 16),
                      ),
                ),
                const SizedBox(height: 16),

                // Lien vers l'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte ?'),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EcranInscription(),
                        ),
                      ),
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(color: Color(0xFFF77F00)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}