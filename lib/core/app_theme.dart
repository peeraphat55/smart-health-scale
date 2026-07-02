import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 กำหนดสีหลักของแอป
  static const Color primary = Color(0xFF7B61FF);
  static const Color primaryLight = Color(0xFFF3EFFF);
  static const Color background = Colors.white;
  
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  
  static const Color cardCyan = Color(0xFF80F0F0);
  static const Color cardOrangeLight = Color(0xFFFFF4E6);

  // 📝 ธีมหลักของแอป
  static ThemeData get lightTheme {
    return ThemeData(
      colorSchemeSeed: primary,
      useMaterial3: true,
      fontFamily: 'Kanit',
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          fontFamily: 'Kanit',
        ),
      ),
    );
  }
}