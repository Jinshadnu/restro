import 'package:flutter/material.dart';
import 'package:restro/utils/theme/theme.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subTitle;
  final List<Widget>? actions;

  const CustomAppbar({
    super.key,
    required this.title,
    this.subTitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0.4,
      backgroundColor: AppTheme.primaryColor,
      centerTitle: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white, // AppBar bg is primaryColor
            ),
          ),
          if (subTitle != null)
            Text(
              subTitle!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
