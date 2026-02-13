import 'package:flutter/material.dart';
import 'package:restro/utils/theme/theme.dart';

class CustomeTextField extends StatelessWidget {
  final String label;
  final IconData prefixICon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final int? maxLine;
  final bool? obscureText;
  final VoidCallback? onToggleVisibility;

  const CustomeTextField(
      {super.key,
      required this.label,
      required this.prefixICon,
      this.isPassword = false,
      this.keyboardType,
      this.validator,
      this.controller,
      this.suffixIcon,
      this.maxLine,
      this.obscureText,
      this.onToggleVisibility});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5))
          ]),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText ?? isPassword,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLine ?? 1,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: Icon(
              prefixICon,
              color: AppTheme.primaryColor,
            ),
            suffixIcon: suffixIcon ??
                (isPassword && onToggleVisibility != null
                    ? IconButton(
                        onPressed: onToggleVisibility,
                        icon: Icon(
                          obscureText ?? false
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.primaryColor.withOpacity(0.7),
                        ))
                    : null),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: AppTheme.textSecondary.withOpacity(0.1), width: 1),
            )),
      ),
    );
  }
}
