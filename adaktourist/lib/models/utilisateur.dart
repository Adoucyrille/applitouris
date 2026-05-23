// Représente un utilisateur de l'application
class Utilisateur {
  final int    id;
  final String username;
  final String email;
  final String telephone;
  final String role;
  final String? photo;

  Utilisateur({
    required this.id,
    required this.username,
    required this.email,
    required this.telephone,
    required this.role,
    this.photo,
  });

  // Convertit le JSON reçu de l'API en objet Dart
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id        : json['id'],
      username  : json['username'],
      email     : json['email'],
      telephone : json['telephone'] ?? '',
      role      : json['role'],
      photo     : json['photo'],
    );
  }

  // Vérifie si l'utilisateur est propriétaire
  bool get estProprietaire => role == 'proprietaire';
  bool get estAdmin        => role == 'admin';
  bool get estTouriste     => role == 'touriste';
}