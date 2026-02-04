import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:restro/data/datasources/remote/auth_remote_data_source.dart';
import 'package:restro/data/repositories/auth_repository.dart';
import 'package:restro/domain/repositories/auth_repository_impl.dart';
import '../controllers/selfie_verification_controller.dart';

class SelfieVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Get.find()),
    );
    Get.lazyPut<SelfieVerificationController>(
      () => SelfieVerificationController(),
    );
  }
}
