// lib/main.dart
// Point d'entrée de l'application Flutter

import 'package:flutter/material.dart';
import 'ecrans/auth/connexion.dart';
import 'ecrans/sites/accueil.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AppTourisme());
}

class AppTourisme extends StatelessWidget {
  const AppTourisme({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title       : 'ADAKTourist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Couleurs inspirées du drapeau ivoirien
        colorScheme: ColorScheme.fromSeed(
          seedColor   : const Color(0xFFF77F00), // Orange
          primary     : const Color(0xFFF77F00), // Orange
          secondary   : const Color(0xFF009A44), // Vert
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor : Color(0xFFF77F00),
          foregroundColor : Colors.white,
          elevation       : 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF77F00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 14
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)
            ),
          ),
        ),
        useMaterial3: true,
      ),
      // Vérifier si l'utilisateur est connecté au démarrage
      home: const EcranDemarrage(),
    );
  }
}

class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage> {
  @override
  void initState() {
    super.initState();
    _verifierConnexion();
  }

  Future<void> _verifierConnexion() async {
    await ApiService.estConnecte(); // préchargement du token
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EcranAccueil()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement pendant la vérification
    return const Scaffold(
      backgroundColor: Color(0xFFF77F00),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.travel_explore, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'ADAKTourist',
              style: TextStyle(
                color    : Colors.white,
                fontSize : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}