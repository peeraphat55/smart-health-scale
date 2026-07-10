import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:project/screen/History/history_page.dart';
import 'package:project/screen/home_page.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/screen/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; 

  final List<Widget> _pages = [
    const HistoryPage(), 
    const HomePage(),    
    const ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], 
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(iconTheme: const IconThemeData(color: Colors.white)), 
        child: CurvedNavigationBar(
          index: _selectedIndex, 
          height: 60,
          items: const <Widget>[
            Icon(Icons.history, size: 30),
            Icon(Icons.home, size: 30),
            Icon(Icons.person, size: 30),
          ],
          color: AppTheme.primary,
          buttonBackgroundColor: AppTheme.primary,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: (index) => setState(() => _selectedIndex = index),
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}