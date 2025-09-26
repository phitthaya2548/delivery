import 'dart:developer';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/req/req_add_user_address.dart';
import 'package:deliveryrpoject/models/res/res_get_user_address.dart' as resModel;
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart'; // NEW: สำหรับแปลงที่อยู่ -> พิกัด

class AddressUser extends StatefulWidget {
  const AddressUser({Key? key}) : super(key: key);

  @override
  State<AddressUser> createState() => _AddressUserState();
}

class _AddressUserState extends State<AddressUser> {
  // THEME
  static const _orange = Color(0xFFFD8700);
  static const _lightOrange = Color(0xFFFFDE98);
  static const _bg = Color(0xFFF2F2F2);

  // RUNTIME
  String baseUrl = '';
  int userId = 0;

  bool _loading = false;
  List<resModel.Address> _addresses = [];

  // (optional) state เผื่ออยากโชว์ผล geocode ตอนผู้ใช้พิมพ์
  double? _tmpLat;
  double? _tmpLng;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cfg = await Configuration.getConfig();
    baseUrl = cfg['apiEndpoint'];

    final auth = SessionStore.getAuth();
    userId = (auth?['userId'] as int?) ?? 0;

    await _loadAddresses();
  }

  // --- GEOCODING: ที่อยู่ -> พิกัด ---
  Future<({double? lat, double? lng, String? error})> _geocode(String address) async {
    try {
      final raw = address.trim();
      if (raw.isEmpty) {
        return (lat: null, lng: null, error: 'กรุณากรอกที่อยู่');
      }
      final list = await locationFromAddress(raw);
      if (list.isEmpty) {
        return (lat: null, lng: null, error: 'หาไม่พบพิกัดจากที่อยู่นี้');
      }
      return (lat: list.first.latitude, lng: list.first.longitude, error: null);
    } catch (e) {
      return (lat: null, lng: null, error: 'แปลงที่อยู่เป็นพิกัดไม่สำเร็จ: $e');
    }
  }

  // --- LOAD ---
  Future<void> _loadAddresses() async {
    if (userId <= 0) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/users/$userId/addresses'));
      if (res.statusCode == 200) {
        final obj = resModel.resUserAddressFromJson(res.body);
        setState(() => _addresses = obj.addresses);
      } else {
        _toast('โหลดที่อยู่ล้มเหลว (${res.statusCode})');
        log('loadAddresses failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      log('loadAddresses error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // --- CREATE ---
  Future<void> _createAddress({
    required String label,
    required String detail,
    required bool isDefault,
  }) async {
    try {
      // แปลงที่อยู่นี้เป็นพิกัดก่อนส่งขึ้นเซิร์ฟเวอร์
      final g = await _geocode(detail);
      if (g.error != null || g.lat == null || g.lng == null) {
        _toast(g.error ?? 'ไม่พบพิกัดจากที่อยู่');
        return;
      }

      final req = ReqUserAddAddress(
        nameAddress: label,
        addressText: detail,
        gpsLat: g.lat!, // ใช้ค่าจริงที่ geocode มาได้
        gpsLng: g.lng!, // ใช้ค่าจริงที่ geocode มาได้
        isDefault: isDefault,
      );

      final res = await http.post(
        Uri.parse('$baseUrl/users/$userId/addresses'),
        headers: {'Content-Type': 'application/json'},
        body: reqUserAddAddressToJson(req),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _toast('เพิ่มที่อยู่สำเร็จ', success: true);
        await _loadAddresses();
      } else {
        _toast('เพิ่มที่อยู่ล้มเหลว (${res.statusCode})');
        log('createAddress failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      log('createAddress error: $e');
    }
  }

  // --- UPDATE ---
  Future<void> _updateAddress({
    required int addressId,
    required String label,
    required String detail,
    required bool isDefault,
  }) async {
    try {
      // แปลงที่อยู่นี้เป็นพิกัดก่อนส่งขึ้นเซิร์ฟเวอร์
      final g = await _geocode(detail);
      if (g.error != null || g.lat == null || g.lng == null) {
        _toast(g.error ?? 'ไม่พบพิกัดจากที่อยู่');
        return;
      }

      final req = ReqUserAddAddress(
        nameAddress: label,
        addressText: detail,
        gpsLat: g.lat!, // ใช้ค่าจริง
        gpsLng: g.lng!, // ใช้ค่าจริง
        isDefault: isDefault,
      );

      final res = await http.put(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId'),
        headers: {'Content-Type': 'application/json'},
        body: reqUserAddAddressToJson(req),
      );

      if (res.statusCode == 200) {
        _toast('บันทึกที่อยู่อัปเดตแล้ว', success: true);
        await _loadAddresses();
      } else {
        _toast('แก้ไขที่อยู่ล้มเหลว (${res.statusCode})');
        log('updateAddress failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      log('updateAddress error: $e');
    }
  }

  // --- DELETE ---
  Future<void> _deleteAddress(int addressId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId'),
      );
      if (res.statusCode == 200) {
        _toast('ลบที่อยู่แล้ว', success: true);
        await _loadAddresses();
      } else {
        _toast('ลบที่อยู่ล้มเหลว (${res.statusCode})');
        log('deleteAddress failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      log('deleteAddress error: $e');
    }
  }

  // --- SET DEFAULT ---
  Future<void> _setDefault(int index) async {
    if (index < 0 || index >= _addresses.length) return;
    final a = _addresses[index];

    await _updateAddress(
      addressId: a.addressId,
      label: a.nameAddress,
      detail: a.addressText,
      isDefault: true,
    );
  }

  // --- UI HELPERS ---
  void _toast(String msg, {bool success = false}) {
    final color = success ? const Color(0xFF22c55e) : const Color(0xFFef4444);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  Future<void> _addOrEditAddress({resModel.Address? init}) async {
    final isEdit = init != null;
    final labelCtrl = TextEditingController(text: isEdit ? init!.nameAddress : '');
    final detailCtrl = TextEditingController(text: isEdit ? init!.addressText : '');
    bool isDefault = isEdit
        ? (init!.isDefault == true || init.isDefault == 1 || init.isDefault == '1')
        : _addresses.isEmpty;

    _tmpLat = null;
    _tmpLng = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> _previewGeocode() async {
                final g = await _geocode(detailCtrl.text);
                if (g.error != null) {
                  _toast(g.error!);
                }
                setSheetState(() {
                  _tmpLat = g.lat;
                  _tmpLng = g.lng;
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(isEdit ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _input(
                    label: 'ป้ายกำกับ (เช่น บ้าน, หอ, ที่ทำงาน)',
                    controller: labelCtrl,
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 10),
                  _input(
                    label: 'ที่อยู่',
                    controller: detailCtrl,
                    icon: Icons.place_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _previewGeocode,
                        icon: const Icon(Icons.my_location),
                        label: const Text('ตรวจพิกัดจากที่อยู่'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lightOrange,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_tmpLat != null && _tmpLng != null)
                        Flexible(
                          child: Text(
                            'Lat: ${_tmpLat!.toStringAsFixed(6)}, Lng: ${_tmpLng!.toStringAsFixed(6)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ตั้งเป็นที่อยู่หลัก'),
                    activeColor: _orange,
                    value: isDefault,
                    onChanged: (v) => setSheetState(() => isDefault = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final label = labelCtrl.text.trim();
                        final detail = detailCtrl.text.trim();
                        if (label.isEmpty || detail.isEmpty) return;

                        Navigator.pop(ctx); // ปิด bottom sheet ก่อน

                        if (isEdit) {
                          await _updateAddress(
                            addressId: init!.addressId,
                            label: label,
                            detail: detail,
                            isDefault: isDefault,
                          );
                        } else {
                          await _createAddress(
                            label: label,
                            detail: detail,
                            isDefault: isDefault || _addresses.isEmpty,
                          );
                        }
                      },
                      child: Text(isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มที่อยู่'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('ที่อยู่ของฉัน',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange, _lightOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? const Center(child: Text('ยังไม่มีที่อยู่'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemBuilder: (_, i) => _addressTile(i),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: _addresses.length,
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditAddress(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มที่อยู่'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _addressTile(int i) {
    final a = _addresses[i];
    final isDefault = a.isDefault == true || a.isDefault == 1 || a.isDefault == '1';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        title: Row(
          children: [
            Text(a.nameAddress, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E0),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _orange.withOpacity(.4)),
                ),
                child: const Text('หลัก',
                    style: TextStyle(fontSize: 12, color: _orange, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(a.addressText, style: const TextStyle(height: 1.3)),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            switch (val) {
              case 'edit':
                _addOrEditAddress(init: a);
                break;
              case 'default':
                _setDefault(i);
                break;
              case 'delete':
                _confirmDelete(i);
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
            if (!isDefault) const PopupMenuItem(value: 'default', child: Text('ตั้งเป็นหลัก')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () {
          // ถ้าต้องการส่งค่ากลับหน้าเดิม:
          // Navigator.pop(context, a);
        },
      ),
    );
  }

  void _confirmDelete(int i) {
    final a = _addresses[i];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบที่อยู่ "${a.nameAddress}" หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(a.addressId);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET HELPERS ---
Widget _input({
  required String label,
  required TextEditingController controller,
  IconData? icon,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.orange[700]),
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: maxLines > 1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
