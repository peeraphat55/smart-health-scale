import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 กำหนดสีหลักของแอป
  static const Color primary = Color(0xFF7B61FF);
  static const Color primaryLight = Color(0xFFF3EFFF);
  static const Color background = Colors.white;
  static const Color maintext = Colors.black;
  
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  
  static const Color cardCyan = Color(0xFF80F0F0);
  static const Color cardOrangeLight = Color(0xFFFFF4E6);

  static const Color historyCardBg = Color(0xFF7B61FF); // สีพื้นหลังการ์ดประวัติ
  static const Color historyTextColor = Color(0xFFF3EFFF); // สีตัวอักษรหลัก
  static const Color historyLabelColor = Color(0xFFF3EFFF); // สีตัวอักษรกำกับ
  static const Color historyDeleteBtn = Color(0xFFFF6B6B); // สีปุ่มลบ

  static const Color statusHealthy = Color(0xFF4CAF50); // เขียว (สมส่วน)
  static const Color statusUnderweight = Color(0xFF2196F3); // ฟ้า (ผอม)
  static const Color statusOverweight = Color(0xFFFF9800); // ส้ม (น้ำหนักเกิน)
  static const Color statusObese = Color(0xFFF44336); // แดง (อ้วน)

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