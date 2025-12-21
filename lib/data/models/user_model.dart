import 'package:restro/domain/entities/user_entity.dart';

class AppUserModel extends UserEntity {
  AppUserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.name,
    required super.phone,
    required super.lastSynced,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'last_synced': lastSynced,
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'],
      email: map['email'],
      role: map['role'],
      name: map['name'],
      phone: map['phone'],
      lastSynced: map['last_synced'],
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      role: role,
      name: name,
      phone: phone,
      lastSynced: lastSynced,
    );
  }
}