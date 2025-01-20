import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? animationIndex;
  final bool animate;
  final String? errorText;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final ValueChanged<String>? onFieldSubmitted;
  final TextStyle? textStyle;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.animationIndex,
    this.animate = true,
    this.errorText,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
    this.onEditingComplete,
    this.onChanged,
    this.decoration,
    this.onFieldSubmitted,
    this.textStyle,
    this.enabled = true,
  });

  factory CustomTextField.search({
    required TextEditingController controller,
    required String label,
    VoidCallback? onTap,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      prefixIcon: Icons.search,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.cardGrey,
        hintText: label,
        prefixIcon: Icon(Icons.search, size: 20.w, color: AppTheme.textGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: decoration ?? InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20.w) : null,
        suffixIcon: suffixIcon,
        errorText: errorText,
        filled: true,
        fillColor: enabled ? AppTheme.cardGrey : AppTheme.cardGrey.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.primaryBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: maxLines! > 1 ? 16.h : 0,
        ),
      ),
      style: textStyle ?? TextStyle(
        fontSize: 16.sp,
        color: enabled ? AppTheme.textDark : AppTheme.textGrey,
      ),
      validator: validator,
    );

    if (animate && animationIndex != null) {
      return textField
          .animate()
          .slideX(
            begin: 0.3,
            delay: (100 * animationIndex!).ms,
            duration: 400.ms,
            curve: Curves.easeOut,
          )
          .fade();
    }

    return textField;
  }
}