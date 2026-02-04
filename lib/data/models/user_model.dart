import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restro/domain/entities/user_entity.dart';

class AppUserModel extends UserEntity {
  AppUserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.name,
    required super.phone,
    required super.lastSynced,
    super.isSelfieVerified,
    super.selfieVerifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'last_synced': lastSynced,
      'is_selfie_verified': isSelfieVerified,
      if (selfieVerifiedAt != null) 'selfie_verified_at': selfieVerifiedAt,
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    final dynamic selfieVerifiedAtRaw = map['selfie_verified_at'];
    int? selfieVerifiedAt;
    if (selfieVerifiedAtRaw is int) {
      selfieVerifiedAt = selfieVerifiedAtRaw;
    } else if (selfieVerifiedAtRaw is Timestamp) {
      selfieVerifiedAt = selfieVerifiedAtRaw.toDate().millisecondsSinceEpoch;
    } else if (selfieVerifiedAtRaw is DateTime) {
      selfieVerifiedAt = selfieVerifiedAtRaw.millisecondsSinceEpoch;
    }

    return AppUserModel(
      id: map['id'],
      email: map['email'],
      role: map['role'],
      name: map['name'],
      phone: map['phone'],
      lastSynced: map['last_synced'],
      isSelfieVerified: map['is_selfie_verified'] ?? false,
      selfieVerifiedAt: selfieVerifiedAt,
    );
  }

  @override
  UserEntity toEntity() {
    return UserEntity(
        id: id,
        email: email,
        role: role,
        name: name,
        phone: phone,
        lastSynced: lastSynced,
        isSelfieVerified: isSelfieVerified,
        selfieVerifiedAt: selfieVerifiedAt);
  }
}
