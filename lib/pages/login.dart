import 'dart:developer';

import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../models/req/req_login.dart';
import '../models/res/res_login.dart';
import 'chooseregister.dart';
import 'rider/widgets/bottom_rider.dart';
import 'user/widgets/bottom_user.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String url = '';

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((config) {
      url = config['apiEndpoint'];
    });
  }

  Future<void> _login() async {
    final phone = _telController.text.trim();
    final pass = _passwordController.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      _toast('กรุณากรอกเบอร์และรหัสผ่าน');
      return;
    }

    final req = Reqlogin(phoneNumber: phone, password: pass);

    try {
      final res = await http.post(
        Uri.parse('$url/login'),
        headers: {'Content-Type': 'application/json'},
        body: reqloginToJson(req),
      );

      if (res.statusCode == 200) {
        final data = resloginFromJson(res.body);

        final role = data.role;
        final userId = data.profile.id;
        final fullname = data.profile.name;
        if (role == null || userId == null) {
          _toast('ข้อมูลไม่ครบจากเซิร์ฟเวอร์');
          return;
        }

        await SessionStore.saveAuth(
          role: role,
          userId: userId,
          fullname: fullname,
          phoneId: phone,
        );
        _toast('เข้าสู่ระบบสำเร็จ ($role)', success: true);
        if (role == 'USER') {
          Get.offAll(() => BottomUser());
        } else if (role == 'RIDER') {
          Get.offAll(() => BottomRider());
        } else {
          Get.offAll(() => BottomUser());
        }
      } else {
        _toast('เข้าสู่ระบบไม่สำเร็จ: ${res.body}');
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e');
      log(e.toString());
    }
  }

  void _toast(String msg, {bool success = false}) {
    Get.showSnackbar(
      GetSnackBar(
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        snackPosition: SnackPosition.TOP,
        backgroundColor:
            success ? const Color(0xFF22c55e) : const Color(0xFFef4444),
        icon: Icon(success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white),
        titleText: Text(success ? 'สำเร็จ' : 'ผิดพลาด',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        messageText: Text(msg, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/icons/logologin.png',
                    fit: BoxFit.contain,
                  ),

                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Login Delivery\nWarpSong',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // Phone
                          TextField(
                            controller: _telController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_android_outlined,
                                  color: Colors.orange[800]),
                              hintText: 'Phone',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey.shade400, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.orange.shade800, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: Colors.orange[800]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.orange[800],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintText: 'Password',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey.shade400, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.orange.shade800, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Get.to(() => const ChooseRegister());
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
