import 'dart:convert';
import 'dart:developer';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_rider_profile.dart';
import 'package:deliveryrpoject/pages/login.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ProfileRider extends StatefulWidget {
  const ProfileRider({Key? key}) : super(key: key);

  @override
  State<ProfileRider> createState() => _ProfileRiderState();
}

class _ProfileRiderState extends State<ProfileRider> {
  String baseUrl = '';
  int riderId = 0;

  // state
  bool loading = true;
  String? profileImageUrl;
  String? vehicleImageUrl;

  // controllers (read-only)
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final plateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    try {
      final cfg = await Configuration.getConfig();
      baseUrl = cfg['apiEndpoint'];
      final auth = SessionStore.getAuth();
      if (auth != null) {
        riderId = auth['userId'];
      }
      await _fetchProfile();
    } catch (e) {
      log('init error: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/riders/$riderId'));
      if (res.statusCode == 200) {
        final data = resRiderProfileFromJson(res.body);
        log("Profile loaded: ${jsonEncode(data.toJson())}");
        final r = data.rider;

        nameCtrl.text = r.name;
        phoneCtrl.text = r.phoneNumber;
        plateCtrl.text = r.licensePlate ?? '';
        profileImageUrl = r.profileImage;
        vehicleImageUrl = r.vehicleImage;
      } else {
        log('fetch profile status: ${res.statusCode}');
      }
    } catch (e) {
      log('fetch profile error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // avatar
                    Center(
                      child: CircleAvatar(
                        radius: 52,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child: profileImageUrl == null
                            ? const Icon(Icons.person, size: 56)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle('ข้อมูลส่วนตัว'),
                    const SizedBox(height: 8),

                    _readField(
                      controller: nameCtrl,
                      label: 'name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),

                    _readField(
                      controller: phoneCtrl,
                      label: 'phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _logoutTile(),

                    const SizedBox(height: 24),
                    _sectionTitle('ข้อมูลรถ'),
                    const SizedBox(height: 8),

                    _readField(
                      controller: plateCtrl,
                      label: 'เลขทะเบียนรถ',
                      icon: Icons.directions_bike_outlined,
                    ),
                    const SizedBox(height: 16),

                    // vehicle image card
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        image: vehicleImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(vehicleImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: vehicleImageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.photo_camera_outlined, size: 36),
                                SizedBox(height: 8),
                                Text('แตะเพื่อถ่ายรูป'),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // widgets

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFFf59e0b), // ส้ม
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );

  Widget _readField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixIconColor: Colors.orange[700],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(color: Colors.orange)),
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _logout,
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    SessionStore.clearAuth();
    Get.offAll(() => const Login());
  }
}
