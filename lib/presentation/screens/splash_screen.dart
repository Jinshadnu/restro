import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro/presentation/providers/auth_provider.dart';
import 'package:restro/utils/navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // 🔥 NEW: Check session & navigate
    navigateUser();
  }

  Future<void> navigateUser() async {
    final auth = Provider.of<AuthenticationProvider>(context, listen: false);

    await Future.delayed(const Duration(seconds: 2));

    bool loggedIn = await auth.loadSession();

    if (!loggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // 🔥 Navigate based on Role
    switch (auth.currentUser!.role) {
      case "admin":
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        break;

      case "manager":
        Navigator.pushReplacementNamed(context, AppRoutes.managerDashboard);
        break;

      case "staff":
        Navigator.pushReplacementNamed(context, AppRoutes.staffDashboard);
        break;

      default:
        Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFD62128),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Restro Manager",
                style: TextStyle(
                  color: Color(0xFFFED51F),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              const SizedBox(
                width: 260,
                child: Text(
                  "Committed to Cleanliness\nand Excellence",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF7722F),
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 90),
              Column(
                children: [
                  Text(
                    "Powered by",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Restro Technologies",
                    style: TextStyle(
                      color: Color(0xFFFED51F),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
