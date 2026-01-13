import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:restro/data/models/user_model.dart';

/// 🔐 Authentication related remote operations contract
/// This defines WHAT operations are available (not HOW)
abstract class AuthRemoteDataSource {

  /// Register a new user using email & password
  /// Creates Firebase Auth user + Firestore user document
  Future<AppUserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  });

  /// Login using email + password
  /// Returns user profile from Firestore
  Future<AppUserModel> loginUser({
    required String identifier, // email
    required String password,
  });

  /// Login using a numeric PIN
  /// Uses Cloud Function primarily, Firestore fallback
  Future<AppUserModel> loginWithPin(String pin);

  /// Logout currently authenticated user
  Future<void> logout();

  /// Mark user as selfie verified in Firestore
  Future<void> updateUserVerification(String uid);
}

/// 🔥 Firebase implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
  });

  // ============================
  // 🔑 EMAIL + PASSWORD LOGIN
  // ============================
  @override
  Future<AppUserModel> loginUser({
    required String identifier,
    required String password,
  }) async {
    try {
      // 1️⃣ Authenticate user with Firebase Auth
      final credential = await auth
          .signInWithEmailAndPassword(
        email: identifier,
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
        throw TimeoutException("Connection timed out during sign in"),
      );

      final uid = credential.user!.uid;

      // 2️⃣ Fetch logged-in user's Firestore document
      final doc = await firestore
          .collection("users")
          .doc(uid)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          "Unable to fetch user profile. Check internet connection.",
        ),
      );

      if (!doc.exists) {
        throw Exception("User profile not found");
      }

      // 3️⃣ Convert Firestore data to AppUserModel
      return AppUserModel.fromMap(doc.data()!);

    } on FirebaseAuthException catch (e) {
      // 🔴 Handle known Firebase auth errors
      if (e.code == 'invalid-email') {
        throw Exception("Invalid email format.");
      } else if (e.code == 'user-not-found') {
        throw Exception("User not found.");
      } else if (e.code == 'wrong-password') {
        throw Exception("Incorrect password.");
      } else {
        throw Exception(e.message ?? "Authentication failed");
      }
    }
  }

  // ============================
  // 🔐 PIN LOGIN (Cloud Function)
  // ============================
  @override
  Future<AppUserModel> loginWithPin(String pin) async {
    try {
      // 1️⃣ Call secure Cloud Function
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('loginWithPin');
      final result = await callable.call({'pin': pin});

      final data = result.data;
      if (data is! Map) {
        throw Exception('Invalid server response');
      }

      // 2️⃣ Receive custom auth token + UID
      final token = data['token'] as String?;
      final uid = data['uid'] as String?;

      if (token == null || uid == null || token.isEmpty || uid.isEmpty) {
        throw Exception('Invalid server response');
      }

      // 3️⃣ Sign in using custom token
      await auth.signInWithCustomToken(token);

      final authedUid = auth.currentUser?.uid;
      if (authedUid == null) {
        throw Exception('Authentication failed.');
      }

      // 4️⃣ Fetch user profile from Firestore
      final userDoc = await firestore
          .collection('users')
          .doc(authedUid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.exists && userDoc.data() != null) {
        return AppUserModel.fromMap(userDoc.data()!);
      }

      // 5️⃣ If not found in users, check staff collection
      final staffDoc =
      await firestore.collection('staff').doc(authedUid).get();

      if (!staffDoc.exists) {
        throw Exception('User profile not found');
      }

      final staffData = staffDoc.data()!;

      return AppUserModel(
        id: authedUid,
        email: '',
        role: 'staff',
        name: staffData['name'] ?? '',
        phone: '',
        lastSynced: DateTime.now().millisecondsSinceEpoch,
        isSelfieVerified: false,
        selfieVerifiedAt: null,
      );

    } on FirebaseFunctionsException {
      // ⛑️ If Cloud Function fails → Firestore fallback
      return _loginWithPinFirestoreFallback(pin);
    } on TimeoutException {
      return _loginWithPinFirestoreFallback(pin);
    }
  }

  // ==========================================
  // ⚠️ PIN LOGIN FALLBACK (Firestore – Dev only)
  // ==========================================
  Future<AppUserModel> _loginWithPinFirestoreFallback(String pin) async {

    // Hash the PIN for secure comparison
    final pinHash = sha256.convert(utf8.encode(pin)).toString();

    // Ensure anonymous auth for Firestore access
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }

    // Query staff collection using hashed PIN
    final snapshot = await firestore
        .collection('staff')
        .where('pinHash', isEqualTo: pinHash)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Invalid PIN');
    }

    final staffDoc = snapshot.docs.first;
    final staffData = staffDoc.data();
    final uid = staffDoc.id;

    // Try to load user profile
    final userDoc = await firestore.collection('users').doc(uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      return AppUserModel.fromMap(userDoc.data()!);
    }

    // Return staff-only profile
    return AppUserModel(
      id: uid,
      email: staffData['email'] ?? '',
      role: 'staff',
      name: staffData['name'] ?? '',
      phone: staffData['phone'] ?? '',
      lastSynced: DateTime.now().millisecondsSinceEpoch,
      isSelfieVerified: false,
      selfieVerifiedAt: null,
    );
  }

  // ============================
  // 🚪 LOGOUT
  // ============================
  @override
  Future<void> logout() async {
    // Sign out from Firebase Auth
    await auth.signOut();
  }

  // ============================
  // 📝 REGISTER USER
  // ============================
  @override
  Future<AppUserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {

    // 1️⃣ Create Firebase Auth user
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // 2️⃣ Create Firestore user profile
    final user = AppUserModel(
      id: uid,
      email: email,
      role: role,
      name: name,
      phone: phone,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );

    // 🔥 Use UID as document ID (best practice)
    await firestore.collection("users").doc(uid).set(user.toMap());

    return user;
  }

  // ============================
  // ✅ SELFIE VERIFICATION UPDATE
  // ============================
  @override
  Future<void> updateUserVerification(String uid) async {
    // Update verification flags in Firestore
    await firestore.collection("users").doc(uid).update({
      'is_selfie_verified': true,
      'selfie_verified_at': FieldValue.serverTimestamp(),
    });
  }
}