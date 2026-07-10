import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/services.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:project/screen/auth/Auth_page.dart';
import 'package:project/screen/main_navigation.dart';
import 'package:provider/provider.dart';

import 'package:project/firebase_options.dart'; 
import 'package:project/core/app_theme.dart';
import 'package:project/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
      child: const BMISmartScaleApp(),
    ),
  );
}

class BMISmartScaleApp extends StatelessWidget {
  const BMISmartScaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Health Monitoring',
      theme: AppTheme.lightTheme,
      
      // 🟢 2. เปลี่ยน home มาใช้ StreamBuilder เพื่อดักฟังสถานะ Real-time
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          // สถานะที่ 1: รอ Firebase เช็กข้อมูลตอนเปิดแอปแวบแรก
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // สถานะที่ 2: ถ้าเช็กแล้วพบว่า "มีข้อมูล User" (ล็อกอินสำเร็จ หรือล็อกอินค้างไว้)
          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigation(); // 👉 ให้ดีดไปหน้าหลักทันที
          }

          // สถานะที่ 3: ถ้า "ไม่มี User" (ยังไม่ล็อกอิน หรือเพิ่งกดล็อกเอาท์ตะกี้เลย)
          return const AuthPage(); // 👉 ให้ดีดกลับหน้าล็อกอิน/สมัครสมาชิกทันที
        },
      ),
    );
  }
}