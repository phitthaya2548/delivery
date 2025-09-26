import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/req/req_register_user.dart';
import 'package:deliveryrpoject/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RegisterUser extends StatefulWidget {
  const RegisterUser({Key? key}) : super(key: key);

  @override
  State<RegisterUser> createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
  final _fullname = TextEditingController();
  final _password = TextEditingController();
  final _tel = TextEditingController();
  bool _obscure = true;
  File? _avatarFile;
  String url = '';
  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then(
      (config) {
        url = config['apiEndpoint'];
      },
    );
  }

  Future<void> _pickAvatar() async {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          color: Colors.white,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจาก Gallery'),
                onTap: () async {
                  Get.back();
                  final x = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (x != null) setState(() => _avatarFile = File(x.path));
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายด้วย Camera'),
                onTap: () async {
                  Get.back();
                  final x = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (x != null) setState(() => _avatarFile = File(x.path));
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<void> registerUser() async {
    // validate เบื้องต้น
    if (_fullname.text.trim().isEmpty ||
        _password.text.trim().isEmpty ||
        _tel.text.trim().isEmpty) {
      Get.snackbar('ผิดพลาด', 'กรุณากรอกข้อมูลให้ครบ');
      return;
    }
    if (_password.text.trim().length < 8) {
      Get.snackbar('ผิดพลาด', 'รหัสผ่านอย่างน้อย 8 ตัวอักษร');
      return;
    }

    // รูปเป็น optional: ถ้าไม่เลือกก็ส่ง null ได้
    String? profileImage;
    if (_avatarFile != null) {
      final bytes = await _avatarFile!.readAsBytes();
      final b64 = base64Encode(bytes);

      // ✅ ส่ง "base64 เพียว ๆ" เท่านั้น (ไม่มี data:image/...;base64,)
      profileImage = b64;
    }

    final req = ReqRegister(
      phoneNumber: _tel.text.trim(),
      password: _password.text.trim(),
      name: _fullname.text.trim(),
      profileImage: profileImage, // ส่งเป็น base64 เพียว ๆ
    );

    try {
      final res = await http.post(
        Uri.parse("$url/register/user"), // หรือ "$url/user" ตามที่เมาท์ route
        headers: {"Content-Type": "application/json"},
        body: reqRegisterToJson(req),
      );

      if (res.statusCode == 201) {
        Get.snackbar('สำเร็จ', 'สมัครสมาชิกเรียบร้อย',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color.fromARGB(255, 27, 155, 1),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
            icon: const Icon(Icons.check, color: Colors.white),
            duration: const Duration(seconds: 1));
        Get.to(const Login());
      } else {
        log(res.body);
        Get.snackbar('สมัครไม่สำเร็จ', res.body);
      }
    } catch (e) {
      Get.snackbar(
        'ผิดพลาด', 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e',
        snackPosition: SnackPosition.BOTTOM, // หรือ BOTTOM
        backgroundColor: const Color.fromARGB(255, 245, 145, 145), // ทึบ ไม่ใส
        colorText: Colors.white, // ตัวอักษรขาว
        margin: const EdgeInsets.all(12), // ลอยจากขอบ
        borderRadius: 12, // มุมโค้ง
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 1),
      );
    }
  }

  @override
  void dispose() {
    _fullname.dispose();
    _password.dispose();
    _tel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFD8700), Color(0xFFFFDE98)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Image.asset(
                  'assets/icons/logologin.png',
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    children: [
                      const Text(
                        'Register\nUser',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : null,
                            child: _avatarFile == null
                                ? const Icon(Icons.person,
                                    size: 46, color: Colors.white)
                                : null,
                          ),
                          InkWell(
                            onTap: _pickAvatar,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.orange,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _fullname,
                        decoration: _inputDec(
                          hint: 'Fullname',
                          icon: Icons.person_2_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),

                    

                      TextField(
                        controller: _tel,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDec(
                          hint: 'Tel.',
                          icon: Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 24),
 TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: _inputDec(
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.orange[700],
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            registerUser();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFD8700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          'back',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.orange[700]),
      suffixIcon: suffix,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
      ),
    );
  }
}
