/// Model représentant un utilisateur de l'application
class UserModel {
  final String id;
  final String name;
  final String nameFr;
  final String? nameAr;
  final String phone;
  final String? email;
  final UserRole role;
  final bool isActive;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? avatar;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.nameFr,
    this.nameAr,
    required this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    this.address,
    this.latitude,
    this.longitude,
    this.avatar,
    required this.createdAt,
  });

  /// Crée un UserModel à partir d'un JSON (depuis API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? (json['nameFr'] as String? ?? ''),
      nameFr: (json['nameFr'] as String?) ?? (json['name'] as String? ?? ''),
      nameAr: json['nameAr'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: UserRole.fromString(json['role'] as String),
      isActive: json['isActive'] == null ? true : json['isActive'] as bool,
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convertit le UserModel en JSON (pour envoyer à l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameFr': nameFr,
      'nameAr': nameAr,
      'phone': phone,
      'email': email,
      'role': role.value,
      'isActive': isActive,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copie le modèle avec des modifications
  UserModel copyWith({
    String? id,
    String? name,
    String? nameFr,
    String? nameAr,
    String? phone,
    String? email,
    UserRole? role,
    bool? isActive,
    String? address,
    double? latitude,
    double? longitude,
    String? avatar,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Énumération des rôles utilisateur
enum UserRole {
  client('CLIENT'),
  hanout('HANOUT'),
  livreur('LIVREUR'),
  admin('ADMIN');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value.toUpperCase(),
      orElse: () => UserRole.client,
    );
  }
}
