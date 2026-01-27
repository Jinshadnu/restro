import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restro/data/datasources/remote/auth_remote_data_source.dart';
import 'package:restro/domain/repositories/auth_repository_impl.dart';
import 'package:restro/presentation/providers/admin_dashboard_provider.dart';
import 'package:restro/presentation/providers/admin_profile_provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/presentation/providers/change_password_provider.dart';
import 'package:restro/presentation/providers/completed_task_provider.dart';
import 'package:restro/presentation/providers/daily_score_provider.dart';
import 'package:restro/presentation/providers/sop_provider.dart';
import 'package:restro/presentation/providers/task_details_provider.dart';
import 'package:restro/presentation/providers/task_provider.dart';
import 'package:restro/utils/navigation/app_routes.dart';
import 'package:restro/utils/services/notification_service.dart';
import 'package:restro/data/datasources/local/database_helper.dart';
import 'package:restro/utils/location_service.dart';
import 'package:restro/utils/theme/theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryColor,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // Initialize notification service (local notifications only)
  await NotificationService().initialize(navigatorKey: rootNavigatorKey);

  // Initialize local database
  await DatabaseHelper.instance.database;

  if (kDebugMode) {
    await LocationService.setShopLocationToCurrentLocation();
  }

  final remoteDataSource = AuthRemoteDataSourceImpl(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );

  final authRepository = AuthRepositoryImpl(remoteDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthenticationProvider(authRepository),
        ),

        ChangeNotifierProvider(
          create: (_) => AdminDashboardProvider(),
        ),

        // other providers...
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => SopProvider()),
        ChangeNotifierProvider(create: (_) => AdminProfileProvider()),
        ChangeNotifierProvider(create: (_) => CompletedTaskProvider()),
        ChangeNotifierProvider(create: (_) => ChangePasswordProvider()),
        ChangeNotifierProvider(create: (_) => DailyScoreProvider()),
        ChangeNotifierProvider(
          create: (_) => TaskDetailsProvider(
            title: "Kitchen Cleaning",
            description:
                "Deep clean the entire kitchen area including shelves.",
            assignedTo: "John Doe",
            status: "Pending",
            deadline: "12 Jan 2025",
            activity: [
              "Task created",
              "Assigned to John",
            ],
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restro App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: rootNavigatorKey,
      initialRoute: '/',
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
