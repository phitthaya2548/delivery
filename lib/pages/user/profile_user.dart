import 'dart:developer';
import 'dart:io';

import 'package:deliveryrpoject/config/config.dart';
// ใช้โมเดล Address/ResUserAddress ด้วย prefix ให้ชัดเจน
import 'package:deliveryrpoject/models/res/res_get_user_address.dart'
    as resModel;
import 'package:deliveryrpoject/models/res/res_profile.dart';
import 'package:deliveryrpoject/pages/login.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
// ถ้าในไฟล์นี้ (address_user.dart) เคยมี class ชื่อ Address อยู่ ให้ซ่อนไป:
// import 'package:deliveryrpoject/pages/user/address_user.dart' hide Address;
import 'package:deliveryrpoject/pages/user/address_user.dart';
import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  // สีหลักตามธีม
  static const _orange = Color(0xFFFD8700);
  static const _bg = Color(0xFFF2F2F2);

  final _name = TextEditingController();
  final _phone = TextEditingController();

  int user = 0;

  String baseUrl = '';
  String? _profileImageUrl;

  // เก็บที่อยู่จาก API
  List<resModel.Address> _addresses = [];
  resModel.ResUserAddress? resUserAddress;

  // รูปโปรไฟล์ที่ผู้ใช้เพิ่งเลือก (ยังไม่อัปขึ้นเซิร์ฟเวอร์)
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((config) async {
      baseUrl = config['apiEndpoint'];
      await _loadProfile();
      await _loadAddresses();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = SessionStore.getAuth();
    if (auth != null) {
      user = auth['userId'];
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/users/$user/profile'));
      if (res.statusCode == 200) {
        final data = resProfileFromJson(res.body);
        log("Profile loaded: ${data.user.name}");
        setState(() {
          _name.text = data.user.name;
          _phone.text = data.user.phoneNumber;
          _profileImageUrl = data.user.profileImage;
        });
      } else {
        log('loadProfile failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      log('loadProfile error: $e');
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/users/$user/addresses'));
      if (res.statusCode == 200) {
        final obj = resModel.resUserAddressFromJson(res.body);
        setState(() {
          _addresses = obj.addresses;
          resUserAddress = obj;
        });
      } else {
        log('loadAddresses failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      log('loadAddresses error: $e');
    }
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจาก Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final x = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (x != null) {
                    setState(() => _avatarFile = File(x.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายด้วย Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final x = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (x != null) {
                    setState(() => _avatarFile = File(x.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: customAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + ปุ่มแก้ไข
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFE9EEF3),
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty)
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                      child: (_avatarFile == null &&
                              (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty))
                          ? const Icon(Icons.person,
                              size: 56, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.white,
                      elevation: 1.5,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickAvatar,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child:
                              Icon(Icons.edit, size: 18, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionHeader('ข้อมูลส่วนตัว'),
            const SizedBox(height: 8),

            _roundedField(
              controller: _name,
              hint: 'name',
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 12),

            _roundedField(
              controller: _phone,
              hint: 'phone number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // ปุ่ม Logout
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                onTap: () async {
                  await SessionStore.clearAuth();
                  Get.offAll(() => const Login());
                },
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('ที่อยู่'),
                TextButton(
                  onPressed: () {
                    Get.to(() => const AddressUser());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('เพิ่มที่อยู่',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // แสดงที่อยู่จาก API
            if (_addresses.isNotEmpty)
              ..._addresses.map(
                (a) => _addressCard(
                  title:
                      (a.isDefault == true) ? '${a.nameAddress} (หลัก)' : a.nameAddress,
                  address: a.addressText,
                  onTap: () {
                    // TODO: ไปหน้าแก้ไข / เลือกที่อยู่นี้
                  },
                ),
              )
            else
              _addressCard(
                title: 'ยังไม่มีที่อยู่',
                address: 'กด “เพิ่มที่อยู่” เพื่อเพิ่มข้อมูล',
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _orange,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }

  Widget _roundedField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _addressCard({
    required String title,
    required String address,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(address,
            style: const TextStyle(color: Colors.black87, height: 1.3)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
