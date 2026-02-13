import 'package:flutter/material.dart';
import 'package:restro/presentation/widgets/critical_compliance_blocker.dart';
import 'package:restro/services/critical_compliance_service.dart';
import 'package:restro/utils/app_logger.dart';

class NavigationGuard {
  static final NavigationGuard _instance = NavigationGuard._internal();
  factory NavigationGuard() => _instance;
  NavigationGuard._internal();

  CriticalComplianceService? _complianceService;

  /// Check navigation and show blocker if needed
  /// Returns true if navigation is allowed, false if blocked
  Future<bool> checkNavigation(BuildContext context, String userId) async {
    try {
      _complianceService ??= CriticalComplianceService();
      // Check if user has incomplete critical tasks
      final hasIncompleteCritical =
          await _complianceService!.hasIncompleteCriticalTasks(userId);

      if (hasIncompleteCritical) {
        // Get the incomplete tasks for display
        final incompleteTasks =
            await _complianceService!.getIncompleteCriticalTasks(userId);

        if (!context.mounted) return false;

        // Show the blocker screen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CriticalComplianceBlocker(
              incompleteTasks: incompleteTasks,
            ),
          ),
        );

        return false; // Navigation was blocked
      }

      return true; // Navigation allowed
    } catch (e, st) {
      AppLogger.e('NavigationGuard', e, st, message: 'checkNavigation failed');
      return true; // Allow navigation on error (fail-safe)
    }
  }

  /// Quick check without showing blocker (for UI state)
  Future<bool> hasBlockingTasks(String userId) async {
    try {
      _complianceService ??= CriticalComplianceService();
      return await _complianceService!.hasIncompleteCriticalTasks(userId);
    } catch (e, st) {
      AppLogger.e('NavigationGuard', e, st, message: 'hasBlockingTasks failed');
      return false;
    }
  }
}
