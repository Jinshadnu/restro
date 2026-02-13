import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  static void e(
    String tag,
    Object error,
    StackTrace stackTrace, {
    String? message,
  }) {
    final m = message == null ? '' : ' $message';
    debugPrint('[$tag] ERROR$m: $error');
    debugPrint('[$tag] STACKTRACE: $stackTrace');
  }
}
