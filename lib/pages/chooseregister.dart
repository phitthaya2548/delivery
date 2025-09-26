import 'package:deliveryrpoject/pages/register_rider.dart';
import 'package:deliveryrpoject/pages/register_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class ChooseRegister extends StatefulWidget {
  const ChooseRegister({Key? key}) : super(key: key);

  @override
  State<ChooseRegister> createState() => _ChooseRegisterState();
}

class _ChooseRegisterState extends State<ChooseRegister> {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
              padding: EdgeInsets.symmetric(horizontal: w * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // โลโก้สีขาวด้านบน
                  Image.asset(
                    'assets/icons/logologin.png', // ถ้ามีไฟล์โลโก้สีขาว
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: h * 0.06),

                  // การ์ดโค้งมนตรงกลาง
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: Column(
                      children: [
                        Text(
                          'เลือกประเภทสมาชิก',
                          style: TextStyle(
                            fontSize: w * 0.055,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: h * 0.02),

                        // ปุ่ม สมัครผู้ใช้
                        _OrangeButton(
                          text: 'สมัครผู้ใช้',
                          onPressed: () {
                            Get.to(() => const RegisterUser());
                          },
                        ),
                        SizedBox(height: h * 0.018),

                        // ปุ่ม สมัครไรเดอร์
                        _OrangeButton(
                          text: 'สมัครไรเดอร์',
                          onPressed: () {
                            Get.to(() => const RegisterRider());
                          },
                        ),
                        SizedBox(height: h * 0.02),

                        // ปุ่ม ย้อนกลับ
                        TextButton(
                          child: const Text('ย้อนกลับ',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Get.back();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrangeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _OrangeButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFD8700),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: w * 0.06,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
