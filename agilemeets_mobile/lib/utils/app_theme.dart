import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // Define custom colors
  static const Color secondaryBlue = Color(0xFF2A3C99); // Slightly lighter navy
  static const Color primaryBlue = Color(0xFF082585); // Primary brand color
  static const Color backgroundGrey = Color(0xFFF5F6FA); // Lighter background
  static const Color cardGrey = Color(0xFFEBEDF7); // Lighter card background
  static const Color textDark = Color(0xFF1A1F36); // Darker text
  static const Color textGrey = Color(0xFF6B7280); // Subtitle grey
  static const Color borderGrey = Color(0xFFE0E0E0);
 // Update colors to match the design

    // Status colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningYellow = Color(0xFFF7DC6F); // Warning yellow

  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  // Add new colors
  static const Color progressBlue = Color(0xFF2E5CFF); // Progress bar blue
  static const Color cardBorderGrey = Color(0xFFE5E7EB);

   // Card styling
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: secondaryBlue,
      surface: backgroundGrey,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
    ),
    
    scaffoldBackgroundColor: backgroundGrey,
    
    // Card Theme
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 65,
      indicatorColor: primaryBlue.withOpacity(0.08),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textGrey,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            size: 24,
            color: primaryBlue,
          );
        }
        return const IconThemeData(
          size: 24,
          color: textGrey,
        );
      }),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
  backgroundColor: backgroundGrey, // Match scaffold background
  foregroundColor: textDark,
  elevation: 0,
  centerTitle: true,
  titleTextStyle: TextStyle(
    color: textDark,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
  ),
  iconTheme: const IconThemeData(
    color: textDark,
    size: 24,
  ),
),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textDark,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textDark,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: textDark,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textGrey,
        fontSize: 14,
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

   
  );


  static TextStyle get headingLarge => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static TextStyle get headingMedium => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static TextStyle get subtitle => TextStyle(
    fontSize: 14.sp,
    color: textGrey,
  );

  static TextStyle get bodyText => TextStyle(
    fontSize: 16.sp,
    color: textDark,
  );

  // Dark theme can be implemented similarly if needed
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    // Implement dark theme properties here
  );
}
