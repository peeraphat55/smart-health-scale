import 'package:flutter/material.dart';
import 'package:project/model/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// Import ไฟล์ของคุณ (เช็ค Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์คุณด้วยนะครับ)
import 'package:project/model/weight_provider.dart';
import 'package:project/screen/MainPage.dart'; // ไฟล์หน้า HomePage ด้านบน
import 'package:project/screen/History.dart'; // ไฟล์หน้าประวัติของคุณ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeightProvider()),
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
      title: 'Daily BMI',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurpleAccent,
        useMaterial3: true,
        fontFamily: 'Kanit',
      ),
      home: const MainNavigation(),
    );
  }
}

// หน้าหลักที่ควบคุมแถบเมนูด้านล่าง
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // เริ่มต้นที่หน้า Home (ตรงกลาง)

  // รายการหน้าจอที่จะแสดง
  final List<Widget> _pages = [
    const HistoryPage(), // หน้า History ของคุณ
    const HomePage(),    // หน้า Home ที่เราทำ UI ไว้
    const Center(
      child: Text(
        'กำลังพัฒนาหน้า Profile...',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], 
      
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: Colors.white),
        ), 
        child: CurvedNavigationBar(
          index: _selectedIndex, 
          height: 60,
          items: const <Widget>[
            Icon(Icons.history, size: 30),
            Icon(Icons.home, size: 30),
            Icon(Icons.person, size: 30),
          ],
          color: Colors.deepPurpleAccent,
          buttonBackgroundColor: Colors.deepPurpleAccent,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}