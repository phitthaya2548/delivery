import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/req/req_user_senditem.dart';
import 'package:deliveryrpoject/models/res/res_search_user.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Homeuser extends StatefulWidget {
  const Homeuser({super.key});

  @override
  State<Homeuser> createState() => _HomeuserState();
}

/// รายการที่จะส่งแบบ batch (แนบรูปด้วย base64 เพียว ๆ)
class _HomeuserState extends State<Homeuser> {
  // Theme
  static const _orange = Color(0xFFFD8700);
  static const _lightOrange = Color(0xFFFFDE98);
  static const _bg = Color(0xFFF4F4F4);

  // Controllers
  final _searchPhone = TextEditingController();
  final _productName = TextEditingController();
  final _productDetail = TextEditingController();

  // Session / State
  int userid = 0; // >0 = logged in
  String? phoneid; // sender phone
  int? receiverId; // from search
  int? _rcvAddressId; // from search
  int? idaddresssender; // sender default address (from sender.address)
  String? _rcvName;
  String? _rcvPhone;
  String? _rcvAddress;

  bool _creating = false;
  bool _searching = false;

  // ตะกร้า
  final List<ItemInput> _cart = [];

  // รูปปัจจุบันก่อนกด "เพิ่มเข้าตะกร้า"
  File? _photo;

  // API endpoint
  String url = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final config = await Configuration.getConfig();
      final auth = await SessionStore.getAuth();

      final ep = (config['apiEndpoint'] as String? ?? '').trim();
      final endpoint = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;

      setState(() {
        url = endpoint;
        userid = (auth?['userId'] as num?)?.toInt() ?? 0;
        phoneid = auth?['phoneId']?.toString();
      });
    } catch (e) {
      log('init error: $e');
    }
  }

  @override
  void dispose() {
    _searchPhone.dispose();
    _productName.dispose();
    _productDetail.dispose();
    super.dispose();
  }

  // ---------- รูปภาพ ----------
  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () async {
                Navigator.pop(context);
                final x = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85, // ลดขนาดไฟล์หน่อย
                );
                if (x != null) setState(() => _photo = File(x.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายด้วยกล้อง'),
              onTap: () async {
                Navigator.pop(context);
                final x = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (x != null) setState(() => _photo = File(x.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ แปลง File -> base64 "เพียว ๆ" (ไม่มี data:image/...;base64,)
  Future<String?> _toBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      log('toBase64 error: $e');
      return null;
    }
  }

  /// ✅ สำหรับพรีวิวในตะกร้า: decode base64 เพียว ๆ
  Uint8List? _bytesFromBase64(String base64str) {
    try {
      return base64Decode(base64str);
    } catch (_) {
      return null;
    }
  }

  // ---------- ค้นหาผู้รับ ----------
  Future<void> _searchReceiver() async {
    final raw = _searchPhone.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์ผู้รับ')),
      );
      return;
    }
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้ตั้งค่า API endpoint')),
      );
      return;
    }
    if (phoneid == null || phoneid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้ล็อกอิน/ไม่มีหมายเลขผู้ส่ง')),
      );
      return;
    }

    setState(() => _searching = true);
    try {
      final uri = Uri.parse('$url/senditem/search').replace(queryParameters: {
        'sender_phone': phoneid!,
        'receiver_phone': raw,
      });

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final model = resuserSearchFromJson(res.body);

        final rec = model.receiver;
        final recAddr = rec.address;
        final senAddr = model.sender.address;

        setState(() {
          _rcvName = rec.name;
          _rcvPhone = rec.phoneNumber.isNotEmpty ? rec.phoneNumber : raw;
          _rcvAddress = recAddr.addressText;
          receiverId = rec.userId;
          _rcvAddressId = recAddr.addressId;
          idaddresssender = senAddr.addressId;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _rcvName = null;
          _rcvPhone = raw;
          _rcvAddress = null;
          receiverId = null;
          _rcvAddressId = null;
          idaddresssender = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบผู้ใช้ตามเบอร์ที่ค้นหา')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ค้นหาไม่สำเร็จ (${res.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ---------- ตะกร้า ----------
  Future<void> _addItem() async {
    if (receiverId == null || _rcvAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาค้นหาและเลือกผู้รับก่อน')),
      );
      return;
    }
    final name = _productName.text.trim();
    final desc = _productDetail.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อสินค้า')),
      );
      return;
    }

    String? b64;
    if (_photo != null) {
      b64 = await _toBase64(_photo!); // ✅ ได้ base64 เพียว ๆ
      if (b64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แปลงรูปไม่สำเร็จ')),
        );
        return;
      }
    }

    setState(() {
      _cart.add(ItemInput(
        receiverId: receiverId!,
        deliveryAddressId: _rcvAddressId!,
        itemName: name,
        itemDescription: desc.isEmpty ? "—" : desc,
        photoBase64: b64, // ✅ ส่ง base64 เพียว ๆ
      ));
      _productName.clear();
      _productDetail.clear();
      _photo = null; // เคลียร์รูปหลังเพิ่มรายการ
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เพิ่มรายการแล้ว')),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  Future<void> _submitAll() async {
    if (_creating) return;

    if (userid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้ล็อกอิน')),
      );
      return;
    }
    if (idaddresssender == null || idaddresssender! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบที่อยู่ผู้ส่ง')),
      );
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีรายการสินค้าในตะกร้า')),
      );
      return;
    }
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้ตั้งค่า API endpoint')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final payload = {
        "sender_id": userid,
        "pickup_address_id": idaddresssender,
        "items": _cart.map((e) => e.toJson()).toList(),
      };

      final uri = Uri.parse('$url/senditem/create-batch');
      final res = await http.post(
        uri,
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final ids = (data['shipment_ids'] as List).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('สร้างคำสั่งสำเร็จ: $ids')),
          );
          setState(() {
            _cart.clear();
            _photo = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('สร้างไม่สำเร็จ: ${data['message'] ?? 'unknown'}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error (${res.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งคำสั่งไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: customAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/images/car.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ส่งสินค้า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ค้นหาเบอร์ผู้รับ
                Row(
                  children: const [
                    Icon(Icons.phone_in_talk_outlined, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('ค้นหาผู้รับสินค้า',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'กรอกเบอร์ผู้รับ แล้วกดค้นหา',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: _searchReceiver,
                            icon: const Icon(Icons.search),
                          ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orange, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ชื่อสินค้า *
                Row(
                  children: const [
                    Icon(Icons.inventory_2_outlined, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('ชื่อสินค้า *',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _productName,
                  decoration: InputDecoration(
                    hintText: 'ชื่อสินค้า',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orange, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // รายละเอียดเพิ่มเติม
                const Text('รายละเอียดเพิ่มเติม',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _productDetail,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'รายละเอียดสินค้า (ถ้ามี)',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orange, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.photo_camera_outlined, color: Colors.orange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: [
                          Text('แนบรูปสินค้า *',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 6),
                          Text('(สำหรับสถานะ "รอไรเดอร์มารับ")',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_photo == null)
                  InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo_outlined,
                            size: 32, color: Colors.black38),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(_photo!, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _photo = null),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // แสดงรายการในตะกร้า
                if (_cart.isNotEmpty) ...[
                  const Text('รายการที่จะส่ง',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final it = _cart[index];
                      final thumb = (it.photoBase64 != null)
                          ? _bytesFromBase64(
                              it.photoBase64!) // ✅ พรีวิวจาก base64
                          : null;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7E7E7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (thumb != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    thumb,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.local_shipping_outlined),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.itemName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(it.itemDescription,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    'receiver_id: ${it.receiverId}, addr_id: ${it.deliveryAddressId}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeItem(index),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'ลบ',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ข้อมูลผู้รับล่าสุดที่ค้นหา
                Row(
                  children: const [
                    Icon(Icons.person_outline, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('ข้อมูลผู้รับล่าสุด',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.person,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_rcvName ?? '—')),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.phone,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_rcvPhone ?? '—')),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_rcvAddress ?? '—')),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ปุ่มส่งทั้งหมด
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _creating ? null : _submitAll,
                    icon: _creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _creating
                          ? 'กำลังส่ง...'
                          : 'สร้างคำสั่งส่งสินค้า (${_cart.length} รายการ)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, color: _orange),
                        label: const Text('เพิ่มรายการเข้าตะกร้า'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _orange),
                          foregroundColor: _orange,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
