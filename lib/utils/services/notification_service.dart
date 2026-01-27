import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:restro/data/datasources/remote/firestore_service.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  GlobalKey<NavigatorState>? _navigatorKey;

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;

    _navigatorKey = navigatorKey;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    await _initializeFcm();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ requires notification permission
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _initializeFcm() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;
      await showNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: _payloadFromMessage(message),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleFcmTap(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleFcmTap(initialMessage);
    }
  }

  String _payloadFromMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString();
    final attendanceId = (message.data['attendanceId'] ?? '').toString();
    if (type.isNotEmpty && attendanceId.isNotEmpty) {
      return '$type:$attendanceId';
    }
    if (type.isNotEmpty) return type;
    return '';
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = (response.payload ?? '').toString();
    _handleLocalPayload(payload);
  }

  void _handleLocalPayload(String payload) {
    if (payload.isEmpty) return;

    final parts = payload.split(':');
    final type = parts.isNotEmpty ? parts.first : payload;
    final attendanceId = parts.length > 1 ? parts[1] : '';

    if (type == 'attendance_pending') {
      _navigatorKey?.currentState?.pushNamed(
        AppRoutes.attendanceVerification,
        arguments: {
          'attendanceId': attendanceId,
        },
      );
    }
  }

  void _handleFcmTap(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString();
    final attendanceId = (message.data['attendanceId'] ?? '').toString();
    if (type == 'attendance_pending') {
      _navigatorKey?.currentState?.pushNamed(
        AppRoutes.attendanceVerification,
        arguments: {
          'attendanceId': attendanceId,
        },
      );
    }
  }

  Future<void> registerFcmTokenForUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _firestoreService.upsertUserFcmToken(
            userId: userId, token: token);
      }
      _messaging.onTokenRefresh.listen((t) async {
        if (t.isNotEmpty) {
          await _firestoreService.upsertUserFcmToken(userId: userId, token: t);
        }
      });
    } catch (_) {
      // Ignore token registration failures (notifications will just not work)
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'restro_channel',
      'Restro Notifications',
      channelDescription: 'Notifications for tasks, verifications, and alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int? id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'restro_channel',
      'Restro Notifications',
      channelDescription: 'Notifications for tasks, verifications, and alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Send notification to staff for delayed tasks
  Future<void> notifyDelayedTask({
    required String taskTitle,
    required DateTime dueDate,
    required String staffId,
  }) async {
    await showNotification(
      title: 'Task Overdue',
      body: 'Task "$taskTitle" is overdue. Please complete it soon.',
      payload: 'task:$staffId',
    );
  }

  /// Send notification to manager for verification pending
  Future<void> notifyVerificationPending({
    required String taskTitle,
    required String staffName,
    required String managerId,
  }) async {
    await showNotification(
      title: 'Task Verification Required',
      body: '$staffName completed "$taskTitle". Please verify.',
      payload: 'verification:$managerId',
    );
  }

  /// Send alert to owner for critical SOP failure
  Future<void> notifyCriticalFailure({
    required String sopTitle,
    required String reason,
    required String ownerId,
  }) async {
    await showNotification(
      title: 'Critical SOP Failure',
      body: 'SOP "$sopTitle" failed: $reason',
      payload: 'critical:$ownerId',
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // TODO: FCM implementation will be added later
  // Future<String?> getFCMToken() async {
  //   return await _firebaseMessaging.getToken();
  // }
}
