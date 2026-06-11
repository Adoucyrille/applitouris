// lib/ecrans/admin/gestion_utilisateurs.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EcranGestionUtilisateurs extends StatefulWidget {
  const EcranGestionUtilisateurs({super.key});

  @override
  State<EcranGestionUtilisateurs> createState() => _EcranGestionUtilisateursState();
}

class _EcranGestionUtilisateursState extends State<EcranGestionUtilisateurs> {
  List<dynamic> _utilisateurs     = [];
  List<dynamic> _utilisateursFiltres = [];
  bool    _chargement = true;
  String? _erreur;
  final TextEditingController _rechercheController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerUtilisateurs();
    _rechercheController.addListener(_filtrer);
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerUtilisateurs() async {
    setState(() => _chargement = true);
    try {
      final data = await ApiService.getUtilisateurs();
      setState(() {
        _utilisateurs        = data;
        _utilisateursFiltres = data;
        _chargement          = false;
      });
    } catch (_) {
      setState(() {
        _erreur     = 'Erreur de chargement.';
        _chargement = false;
      });
    }
  }

  void _filtrer() {
    final q = _rechercheController.text.toLowerCase();
    setState(() {
      _utilisateursFiltres = _utilisateurs.where((u) {
        final username = u['username']?.toString().toLowerCase() ?? '';
        final email    = u['email']?.toString().toLowerCase()    ?? '';
        final role     = u['role']?.toString().toLowerCase()     ?? '';
        return username.contains(q) || email.contains(q) || role.contains(q);
      }).toList();
    });
  }

  Color _couleurRole(String role) {
    switch (role) {
      case 'admin'        : return const Color(0xFFF77F00);
      case 'proprietaire' : return const Color(0xFF009A44);
      default             : return const Color(0xFF1B64F1);
    }
  }

  String _libelleRole(String role) {
    switch (role) {
      case 'admin'        : return '👑 Admin';
      case 'proprietaire' : return '🏨 Propriétaire';
      default             : return '🧳 Touriste';
    }
  }

  void _afficherDetails(Map<String, dynamic> u) {
    showModalBottomSheet(
      context      : context,
      isScrollControlled: true,
      shape        : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child  : Column(
          mainAxisSize     : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width : 40, height: 4,
                decoration: BoxDecoration(
                  color       : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius         : 28,
                  backgroundColor: _couleurRole(u['role'] ?? ''),
                  child          : Text(
                    (u['username']?.toString() ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['username']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize  : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ligneDetail(Icons.badge,     'Rôle',      _libelleRole(u['role'] ?? '')),
            const SizedBox(height: 10),
            _ligneDetail(Icons.email,     'Email',     u['email']?.toString() ?? 'Non renseigné'),
            const SizedBox(height: 10),
            _ligneDetail(Icons.phone,     'Téléphone', u['telephone']?.toString().isEmpty == true
              ? 'Non renseigné' : u['telephone']?.toString() ?? 'Non renseigné'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _ligneDetail(IconData icone, String label, String valeur) {
    return Row(
      children: [
        Icon(icone, color: const Color(0xFFF77F00), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Utilisateurs (${_utilisateursFiltres.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerUtilisateurs),
        ],
      ),
      body: _chargement
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFF77F00)))
        : _erreur != null
          ? Center(child: Text(_erreur!))
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16),
                  child  : TextField(
                    controller: _rechercheController,
                    decoration: InputDecoration(
                      hintText     : 'Rechercher par nom, email, rôle...',
                      prefixIcon   : const Icon(Icons.search),
                      border       : OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : BorderSide(color: Colors.grey.shade300),
                      ),
                      filled     : true,
                      fillColor  : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // Liste
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _chargerUtilisateurs,
                    child    : _utilisateursFiltres.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun utilisateur trouvé.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding        : const EdgeInsets.symmetric(horizontal: 16),
                          itemCount      : _utilisateursFiltres.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder    : (context, index) {
                            final u    = _utilisateursFiltres[index];
                            final role = u['role']?.toString() ?? 'touriste';
                            return ListTile(
                              onTap       : () => _afficherDetails(
                                Map<String, dynamic>.from(u),
                              ),
                              leading     : CircleAvatar(
                                backgroundColor: _couleurRole(role).withValues(alpha: 0.15),
                                child: Text(
                                  (u['username']?.toString() ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    color     : _couleurRole(role),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title       : Text(
                                u['username']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle    : Text(
                                u['email']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing    : Container(
                                padding   : const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color       : _couleurRole(role).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border      : Border.all(
                                    color: _couleurRole(role).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  _libelleRole(role),
                                  style: TextStyle(
                                    color    : _couleurRole(role),
                                    fontSize : 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
