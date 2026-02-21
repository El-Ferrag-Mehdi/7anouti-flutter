enum UserRole {
  client,
  hanout,
  livreur,
  admin,
}

extension UserRoleParser on UserRole {
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name.toUpperCase() == role.toUpperCase(),
      orElse: () => UserRole.client,
    );
  }
}