import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restro/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  });

  Future<AppUserModel> loginUser({
    required String email,
    required String password,
  });

  Future<void> logout();


}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
  });

  @override
  Future<AppUserModel> loginUser({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final snap = await firestore
        .collection("users")
        .where("id", isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception("User record not found in Firestore");
    }

    final data = snap.docs.first.data();
    return AppUserModel.fromMap(data);
  }

  @override
  Future<void> logout() async {
    await auth.signOut();
  }

  @override
  Future<AppUserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final docID = "${role}_$uid";

    final user = AppUserModel(
      id: uid,
      email: email,
      role: role,
      name: name,
      phone: phone,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );

    await firestore.collection("users").doc(docID).set(user.toMap());
    return user;
  }


}