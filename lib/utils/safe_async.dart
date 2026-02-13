import 'package:flutter/material.dart';
import 'package:restro/utils/app_logger.dart';

Future<T?> safeAsync<T>(
  BuildContext context, {
  required String tag,
  required Future<T> Function() action,
  String? errorMessage,
  bool showSnackBar = true,
}) async {
  try {
    return await action();
  } catch (e, st) {
    AppLogger.e(tag, e, st);
    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}
