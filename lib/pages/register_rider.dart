import 'dart:convert';
import 'dart:io';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/req/req_register_rider.dart';
import 'package:deliveryrpoject/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RegisterRider extends StatefulWidget {
  const RegisterRider({Key? key}) : super(key: key);

  @override
  State<RegisterRider> createState() => _RegisterRiderState();
}

class _RegisterRiderState extends State<RegisterRider> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _tel = TextEditingController();
  final _plate = TextEditingController();

  bool _obscure = true;
  File? _avatarFile;
  File? _vehicleFile;

  static const _orange = Color(0xFFFD8700);
  static const _lightOrange = Color(0xFFFFDE98);
  static const _cardFill = Colors.white;
  static const _fieldFill = Color(0xFFF8F8F8);

  String url = '';

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((config) {
      url = config['apiEndpoint'];
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _tel.dispose();
    _plate.dispose();
    super.dispose();
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

  Future<void> _pickVehicle() async {
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
                  if (x != null) setState(() => _vehicleFile = File(x.path));
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
                  if (x != null) setState(() => _vehicleFile = File(x.path));
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<void> registerRider() async {
    // validate
    if (_name.text.trim().isEmpty ||
        _password.text.trim().isEmpty ||
        _tel.text.trim().isEmpty ||
        _plate.text.trim().isEmpty) {
      _toast('กรุณากรอกข้อมูลให้ครบ');
      return;
    }
    if (_password.text.trim().length < 8) {
      _toast('รหัสผ่านอย่างน้อย 8 ตัวอักษร');
      return;
    }

    // รูปเป็น optional -> base64 เพียว ๆ
    String? profileB64;
    if (_avatarFile != null) {
      final bytes = await _avatarFile!.readAsBytes();
      profileB64 = base64Encode(bytes);
    }
    String? vehicleB64;
    if (_vehicleFile != null) {
      final bytes = await _vehicleFile!.readAsBytes();
      vehicleB64 = base64Encode(bytes);
    }

    final req = ReqRegisterRider(
      phoneNumber: _tel.text.trim(),
      password: _password.text.trim(),
      name: _name.text.trim(),
      licensePlate: _plate.text.trim(),
      profileImage: profileB64,
      vehicleImage: vehicleB64,
    );

    try {
      final res = await http.post(
        Uri.parse("$url/register/rider"),
        headers: {"Content-Type": "application/json"},
        body: reqRegisterRiderToJson(req),
      );

      if (res.statusCode == 201) {
        _toast('สมัคร Rider สำเร็จ', success: true);
        Get.to(Login());
        // TODO: Get.offAllNamed('/home');
      } else {
        _toast('สมัครไม่สำเร็จ: ${res.body}');
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e');
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_orange, _lightOrange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Image.asset('assets/icons/logologin.png'),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _cardFill,
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
                          'Register\nRider',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _avatarFile == null
                                  ? Icon(Icons.person,
                                      size: 46, color: Colors.grey.shade400)
                                  : Image.file(_avatarFile!, fit: BoxFit.cover),
                            ),
                            InkWell(
                              onTap: _pickAvatar,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: _orange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Fullname
                        TextField(
                          controller: _name,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_2_outlined,
                                color: _orange),
                            hintText: 'Fullname',
                            filled: true,
                            fillColor: _fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _orange, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        TextField(
                          controller: _tel,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone_outlined,
                                color: _orange),
                            hintText: 'Tel.',
                            filled: true,
                            fillColor: _fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.2),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: _orange, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Password
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.lock_outline, color: _orange),
                            hintText: 'Password',
                            filled: true,
                            fillColor: _fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.2),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: _orange, width: 2),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Vehicle photo + plate
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1.2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _vehicleFile == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_outlined,
                                            size: 36,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 6),
                                        Text('ไม่มีรูป',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12)),
                                      ],
                                    )
                                  : Image.file(_vehicleFile!,
                                      fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ทะเบียนรถ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _orange)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _plate,
                                      decoration: InputDecoration(
                                        hintText: 'ใส่ทะเบียนรถ',
                                        filled: true,
                                        fillColor: _fieldFill,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1.2),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1.2),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                          borderSide: BorderSide(
                                              color: _orange, width: 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: _pickVehicle,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _orange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text('เลือกรูปพาหนะ'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: registerRider,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 8,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'back',
                            style: TextStyle(
                                color: _orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
