import 'package:flutter/material.dart';
import 'package:restro/utils/theme/theme.dart';

class DashboardBanner extends StatelessWidget {
  final String staffName;

  const DashboardBanner({super.key, required this.staffName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          /// Left side illustration
          Expanded(
            flex: 2,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/banner_illustration.png",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// Right side content
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Let's schedule your tasks\nand manage daily workflow.",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
