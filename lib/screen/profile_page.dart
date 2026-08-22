import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/core/app_theme.dart';
import 'package:project/providers/weight_provider_bluetooth.dart';
import 'package:provider/provider.dart';

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
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (!mounted) return;

      setState(() {
        _userData = data;
        _ageController.text = data?['age']?.toString() ?? '';

        final genderValue = data?['gender'];
        _gender = genderValue is int
            ? genderValue
            : int.tryParse(genderValue?.toString() ?? '') ?? 0;
      });
    } catch (e) {
      debugPrint('❌ โหลดข้อมูลโปรไฟล์ไม่สำเร็จ: $e');
    } finally {
      // ไม่ว่าไม่มี document, ไม่มีผู้ใช้ หรือ Firestore error ก็ต้องหยุด Loading
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'age': int.tryParse(_ageController.text) ?? 0,
          'gender': _gender,
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("อัปเดตข้อมูลสำเร็จ!")));
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final weightProvider = context.watch<WeightProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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

            const SizedBox(height: 28),
            _buildLatestMeasurementCard(weightProvider),

            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: _updateProfile,
              child: const Text(
                "บันทึกข้อมูล",
                style: TextStyle(color: AppTheme.background),
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
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestMeasurementCard(WeightProvider provider) {
    if (provider.historyRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.primary, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              color: AppTheme.primary,
              size: 36,
            ),
            SizedBox(height: 10),
            Text(
              'การวัดล่าสุด',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'ยังไม่มีข้อมูลการวัดที่บันทึกไว้',
              style: TextStyle(color: AppTheme.maintext),
            ),
          ],
        ),
      );
    }

    final latest = provider.historyRecords.first;
    final statusColor = _statusColor(latest.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                color: AppTheme.primary,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'การวัดล่าสุด',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  latest.status,
                  style: const TextStyle(
                    color: AppTheme.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatMeasurementDate(latest.timestamp),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementItem(
                  icon: Icons.monitor_weight_outlined,
                  label: 'น้ำหนัก',
                  value: '${latest.weight.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementItem(
                  icon: Icons.height_rounded,
                  label: 'ส่วนสูง',
                  value: '${latest.height.toStringAsFixed(1)} cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementItem(
                  icon: Icons.accessibility_new_rounded,
                  label: 'BMI',
                  value: latest.bmi.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementItem(
                  icon: Icons.favorite_rounded,
                  label: 'ชีพจร',
                  value: '${latest.heartRate} BPM',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.maintext,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'underweight':
        return AppTheme.statusUnderweight;
      case 'healthy':
        return AppTheme.statusHealthy;
      case 'overweight':
        return AppTheme.statusOverweight;
      case 'obese':
        return AppTheme.statusObese;
      default:
        return AppTheme.primary;
    }
  }

  String _formatMeasurementDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)} น.';
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
                color: isSelected ? AppTheme.primary : AppTheme.background,
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