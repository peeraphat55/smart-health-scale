import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/providers/auth_provider.dart'; // import provider ตัวใหม่
import 'package:project/main.dart'; // เพื่อลิงก์ไปหน้า MainNavigation

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  int _selectedGender = 0; 

  void _handleSubmit() async {
    // 1. ดึงค่าจากช่องกรอก
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final ageText = _ageController.text.trim();

    // 2. ตรวจสอบข้อมูลเบื้องต้น
    if (email.isEmpty || password.isEmpty) return _showError("กรุณากรอกอีเมลและรหัสผ่าน");
    if (!isLogin && ageText.isEmpty) return _showError("กรุณากรอกอายุของคุณ");

    // 3. เรียกใช้ Logic จาก AuthProvider
    final authProvider = context.read<AuthProvider>();
    String? errorMessage;

    if (isLogin) {
      errorMessage = await authProvider.signIn(email: email, password: password);
    } else {
      errorMessage = await authProvider.signUp(
        email: email, 
        password: password, 
        age: int.tryParse(ageText) ?? 21, 
        gender: _selectedGender,
      );
    }

    // 4. จัดการผลลัพธ์
    // 4. จัดการผลลัพธ์
    if (errorMessage != null) {
      _showError(errorMessage); // ถ้ามี Error ให้แสดงแจ้งเตือน
    } else if (mounted) {
      // 🟢 แยกการทำงานระหว่าง โหมดล็อกอิน กับ โหมดสมัครสมาชิก
      if (isLogin) {
        // ถ้าเป็นการ "เข้าสู่ระบบ" สำเร็จ -> พาเข้าแอปทันที
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        // ถ้าเป็นการ "สมัครสมาชิก" สำเร็จ -> แจ้งเตือนสีเขียว + สลับหน้าเป็นล็อกอิน
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ"),
            backgroundColor: Colors.green, // แจ้งเตือนสีเขียวเพื่อบอกว่าสำเร็จ
          ),
        );
        
        setState(() {
          isLogin = true; // เปลี่ยน UI กลับเป็นโหมดล็อกอิน
          _passwordController.clear(); // ล้างช่องรหัสผ่านให้กรอกใหม่เพื่อความปลอดภัย
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // เฝ้าดูสถานะ isLoading เพื่อหมุนวงกลม
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monitor_weight_rounded, size: 100, color: Color(0xFF7B61FF)),
              const SizedBox(height: 20),
              Text(isLogin ? "เข้าสู่ระบบ" : "สร้างบัญชีใหม่", 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7B61FF))),
              const SizedBox(height: 30),

              _buildTextField(_emailController, "Email", Icons.email_outlined, TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Password", Icons.lock_outline, TextInputType.text, obscure: true),
              const SizedBox(height: 15),

              if (!isLogin) ...[
                _buildTextField(_ageController, "อายุ (ปี)", Icons.calendar_today_outlined, TextInputType.number),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: _selectedGender,
                  decoration: _inputStyle(Icons.transgender),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("ชาย")),
                    DropdownMenuItem(value: 1, child: Text("หญิง")),
                  ],
                  onChanged: (val) => setState(() => _selectedGender = val!),
                ),
                const SizedBox(height: 15),
              ],

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isLoading ? null : _handleSubmit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? "เข้าสู่ระบบ" : "สมัครสมาชิก", style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 15),
              
              TextButton(
                onPressed: () => setState(() { isLogin = !isLogin; }),
                child: Text(isLogin ? "สมัครสมาชิกที่นี่" : "มีบัญชีแล้ว? เข้าสู่ระบบ", style: const TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, TextInputType type, {bool obscure = false}) {
    return TextField(
      controller: controller, obscureText: obscure, keyboardType: type,
      decoration: _inputStyle(icon).copyWith(hintText: hint),
    );
  }

  InputDecoration _inputStyle(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
      filled: true, fillColor: const Color(0xFFF3EFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}