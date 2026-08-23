import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF7B61FF);
  static const Color primaryLight = Color(0xFFF3EFFF);
  static const Color background = Colors.white;
  static const Color maintext = Colors.black;

  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color refreshButton = Color(0xFF2196F3);
  static const Color refreshButtonForeground = Colors.white;

  static const Color cardCyan = Color(0xFF80F0F0);
  static const Color cardOrangeLight = Color(0xFFFFF4E6);

  static const Color historyCardBg = Color(0xFF7B61FF);
  static const Color historyTextColor = Color(0xFFF3EFFF);
  static const Color historyLabelColor = Color(0xFFF3EFFF);
  static const Color historyDeleteBtn = Color(0xFFFF6B6B);

  static const Color statusHealthy = Color(0xFF4CAF50);
  static const Color statusUnderweight = Color(0xFF2196F3);
  static const Color statusOverweight = Color(0xFFFF9800);
  static const Color statusObese = Color(0xFFF44336);

  // สีกราฟทั้งหมดรวมไว้ใน Theme เพื่อให้เปลี่ยนธีมได้จากจุดเดียว
  static const Color bmiGraph = Color(0xFF2196F3);
  static const Color weightGraph = Color(0xFFF9A825);
  static const Color heightGraph = Color(0xFF43A047);
  static const Color heartRateGraph = Color(0xFFE53935);
  static const Color graphCardBackground = Color(0xFFFAFAFF);
  static const Color graphGrid = Color(0xFFE0E0E0);
  static const Color graphAxis = Color(0xFF9E9E9E);
  static const Color emptyData = Color(0xFF9E9E9E);

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
