import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/screen/auth/Auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  final _ageController = TextEditingController();
  int _gender = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _ageController.text = _userData?['age']?.toString() ?? '';
          _gender = _userData?['gender'] ?? 0;
          _isLoading = false; 
        });
      }
    } else {

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _gender,
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("อัปเดตข้อมูลสำเร็จ!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
            const SizedBox(height: 20),
            Text(
              _auth.currentUser?.email ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: 120,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12), //
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        "อายุ:",
                        style: TextStyle(
                          color:
                              AppTheme.primary, // ปรับสีตัวอักษรให้เข้ากับขอบ
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.maintext,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none, // ลบเส้นใต้เดิมออก
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width:
                      140, // ขยายความกว้างเล็กน้อยเพื่อให้พอดีกับคำว่า "เพศชาย / เพศหญิง"
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // ความโค้งเท่ากับช่องอายุ
                    border: Border.all(
                      color: AppTheme.primary,
                      width: 2,
                    ), // สีและขนาดกรอบเข้าธีม
                  ),
                  child: DropdownButton<int>(
                    value: _gender,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: AppTheme.primary,
                    selectedItemBuilder: (BuildContext context) {
                      return [0, 1].map<Widget>((int value) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),

                            child: Text(
                              value == 0 ? "เพศชาย" : "เพศหญิง",
                              key: ValueKey<int>(
                                value,
                              ), // Key สำคัญมาก เพื่อให้ AnimatedSwitcher รู้ว่าค่าเปลี่ยนแล้ว
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList();
                    },

                    // --- ส่วนที่ 2: รายการตัวเลือกพร้อมไฮไลท์ ---
                    items: [
                      _buildDropdownItem(value: 0, text: "เพศชาย"),
                      _buildDropdownItem(value: 1, text: "เพศหญิง"),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _gender = val);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 49),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: _updateProfile,
              child: const Text(
                "บันทึกข้อมูล",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                // ถ้าใช้ Navigator ให้ดีดกลับไปหน้าแรก/หน้าล็อกอินแบบล้าง Stack
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text(
                "ออกจากระบบ",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<int> _buildDropdownItem({
    required int value,
    required String text,
  }) {
    final bool isSelected = _gender == value;

    return DropdownMenuItem<int>(
      value: value,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
