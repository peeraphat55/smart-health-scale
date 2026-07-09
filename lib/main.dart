import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      theme: AppTheme.lightTheme, // 🟢 เรียกใช้ธีมรวมจาก AppTheme ที่เราสร้างไว้
      home: MainNavigation(),
    );
  }
}