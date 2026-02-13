import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:restro/firebase_options.dart';
import 'dart:convert';

class StaffRegistrationService {
  StaffRegistrationService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String> registerStaff({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String staffRole,
    required String pin,
    required String createdBy,
  }) async {
    final secondaryApp = await _getOrCreateSecondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final pinHash = sha256.convert(utf8.encode(pin)).toString();

    // Staff collection (as per screenshot)
    await _firestore.collection('staff').doc(uid).set({
      'id': uid,
      'name': name,
      'staffRole': staffRole,
      'pinHash': pinHash,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(uid).set({
      'id': uid,
      'email': email,
      'role': 'staff',
      'staff_role': staffRole,
      'name': name,
      'phone': phone,
      'last_synced': DateTime.now().millisecondsSinceEpoch,
      'is_selfie_verified': false,
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
    });

    await secondaryAuth.signOut();

    return uid;
  }

  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    try {
      return Firebase.app('Secondary');
    } catch (_) {
      return Firebase.initializeApp(
        name: 'Secondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}
