class UserEntity{
  final String id;
  final String email;
  final String phone;
  final String role;
  final String name;
  final int lastSynced;


  UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.lastSynced
  });
}