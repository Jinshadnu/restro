import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadTaskPhoto(String taskId, File photo) async {
    try {
      final ref = _storage.ref().child('task_photos').child('$taskId.jpg');
      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<void> deleteTaskPhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }
}

