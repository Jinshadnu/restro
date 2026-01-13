class UserEntity {
  // User roles
  static const String roleAdmin = 'ADMIN';
  static const String roleOwner = 'OWNER';

  final String id;
  final String email;
  final String phone;
  final String role;
  final String name;
  final int lastSynced;
  final bool isSelfieVerified;
  final int? selfieVerifiedAt;

  UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.lastSynced,
    this.isSelfieVerified = false,
    this.selfieVerifiedAt,
  });

  // bool get requiresSelfieVerification {
  //   return role == roleStaff && !isSelfieVerified;
  // }
}
