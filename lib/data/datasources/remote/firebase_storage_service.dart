import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadTaskPhoto(String taskId, File photo) async {
    try {
      final ref = _storage.ref().child('task_photos').child('$taskId.jpg');
      final snapshot = await ref.putFile(photo);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('object-not-found')) {
        throw Exception(
          'Failed to upload photo: $e. This often happens when Firebase Storage rules block read access for getDownloadURL() or the upload path is incorrect.',
        );
      }
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<String> uploadTaskRejectionMarkedImage(
      String taskId, Uint8List pngBytes) async {
    try {
      final ref = _storage
          .ref()
          .child('task_rejection_marked_images')
          .child('$taskId.png');
      final snapshot = await ref.putData(
        pngBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload marked rejection image: $e');
    }
  }

  Future<String> uploadTaskRejectionVoiceNote(
      String taskId, File audioFile) async {
    try {
      final ext = p.extension(audioFile.path).trim();
      final safeExt = ext.isNotEmpty ? ext : '.m4a';
      final ref = _storage
          .ref()
          .child('task_rejection_voice_notes')
          .child('$taskId$safeExt');
      final snapshot = await ref.putFile(audioFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload voice note: $e');
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

  Future<String> uploadAttendanceSelfie(
      String userId, String date, File photo) async {
    try {
      final ref =
          _storage.ref().child('attendance').child(userId).child('$date.jpg');
      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload attendance photo: $e');
    }
  }

  Future<String> uploadAttendanceRejectionVoiceNote(
      String attendanceId, File audioFile) async {
    try {
      final ext = p.extension(audioFile.path).trim();
      final safeExt = ext.isNotEmpty ? ext : '.m4a';
      final ref = _storage
          .ref()
          .child('attendance_rejection_voice_notes')
          .child('$attendanceId$safeExt');
      final snapshot = await ref.putFile(audioFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload attendance voice note: $e');
    }
  }
}
