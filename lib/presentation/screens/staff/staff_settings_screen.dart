import 'package:flutter/material.dart';
import 'package:restro/presentation/widgets/custom_appbar.dart';

class StaffSettingsScreen extends StatelessWidget {
  const StaffSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        appBar: CustomAppbar(
      title: 'Completed Tasks',
    ));
  }
}
