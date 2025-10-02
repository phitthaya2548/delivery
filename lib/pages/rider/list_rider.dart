// lib/pages/rider/list_rider.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ListRider extends StatefulWidget {
  const ListRider({Key? key}) : super(key: key);

  @override
  State<ListRider> createState() => _ListRiderState();
}

class _ListRiderState extends State<ListRider> {
  // ===== Theme =====
  static const _orange = Color(0xFFFD8700);
  static const _orangeLight = Color(0xFFFFDE98);
  static const _bg = Color.fromARGB(255, 235, 232, 230);
  static const _cardBg = Color(0xFFFFF4E5);
  static const _green = Color(0xFF16A34A);

  String _baseUrl = '';
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  Map<String, dynamic>? _shipment;
  int riderId = 0;

  // รูปที่ "คิวไว้" (ยังไม่ส่ง)
  XFile? _pendingPhotoFile;
  String? _pendingPhotoB64;

  // ===== Realtime from Firestore (รูปสถานะ) =====
  final _fs = FirebaseFirestore.instance;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _shipSub;
  String? _statusPhotoUrl; // รูปล่าสุดของ "สถานะปัจจุบัน"
  List<Map<String, dynamic>> _statusPhotos = []; // อัลบั้มรูปทั้งหมดใน photos[]

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initAndFetch() async {
    try {
      final cfg = await Configuration.getConfig();
      final ep = (cfg['apiEndpoint'] as String? ?? '').trim();
      _baseUrl = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;

      final auth = SessionStore.getAuth();
      if (auth != null && auth['userId'] != null) {
        riderId = auth['userId'];
        await _fetchDetail();
      } else {
        setState(() {
          _error = 'ไม่พบข้อมูลผู้ใช้งาน (riderId)';
          _loading = false;
        });
      }
    } catch (e) {
      log('init error: $e');
      setState(() {
        _error = 'ตั้งค่า API ไม่ถูกต้อง';
        _loading = false;
      });
    }
  }

  Future<void> _fetchDetail({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final uri = Uri.parse('$_baseUrl/riders/accepted/accepted')
          .replace(queryParameters: {'rider_id': '$riderId'});

      log('[GET] $uri');
      final res = await http.get(uri);
      log('status=${res.statusCode}');
      final preview =
          res.body.length > 300 ? '${res.body.substring(0, 300)}...' : res.body;
      log('body: $preview');

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final shipments =
            (j['shipments'] as List?)?.cast<Map<String, dynamic>>();
        if (shipments != null && shipments.isNotEmpty) {
          final first = shipments.first;

          // เขียน snapshot ลง Firestore ให้ฝั่งผู้ใช้เห็นแบบ realtime
          await _saveToFirebaseSnapshot(first);

          if (!mounted) return;
          setState(() {
            _shipment = first;
            _loading = false;
          });

          // ✅ ผูก realtime photos ของ shipment นี้
          final sid = (first['shipment_id'] as num).toString();
          _bindShipmentPhotos(sid);
        } else {
          setState(() {
            _shipment = null;
            _error = 'ไม่พบงานที่รับไว้';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  /// บันทึก snapshot ไป Firestore:
  /// - shipments/{shipment_id}
  /// - riders/{riderId}.current
  Future<void> _saveToFirebaseSnapshot(Map<String, dynamic> s) async {
    try {
      final sid = (s['shipment_id'] as num).toString();
      final shipRef = _fs.collection('shipments').doc(sid);

      final data = <String, dynamic>{
        'shipment_id': sid,
        'item_name': s['item_name'],
        'item_description': s['item_description'],
        'status': (s['status'] is num)
            ? s['status']
            : int.tryParse(s['status']?.toString() ?? '1') ?? 1,
        'item_photo_url': s['item_photo_url'], // รูปหลักของลูกค้า (อย่าแตะ)
        'updated_at': FieldValue.serverTimestamp(),
        'sender': s['sender'],
        'receiver': s['receiver'],
        'rider': s['rider'],
        'riderId': riderId.toString(),
      };

      await shipRef.set(data, SetOptions(merge: true));

      // current job ของไรเดอร์
      final riderRef = _fs.collection('riders').doc(riderId.toString());
      await riderRef.set({
        'current': {
          'shipment_id': sid,
          'status': data['status'],
        },
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('saveToFirebaseSnapshot error: $e');
    }
  }

  /// 🔴 ผูก realtime photos + status_photo_url ของ shipment
  void _bindShipmentPhotos(String shipmentId) {
    _shipSub?.drain();
    _shipSub = _fs.collection('shipments').doc(shipmentId).snapshots();
    _shipSub!.listen((snap) {
      if (!mounted || !snap.exists) return;
      final m = snap.data();
      if (m == null) return;

      final statusPhoto = (m['status_photo_url'] as String?)?.trim();
      final listRaw = (m['photos'] as List?) ?? const [];
      final photos = <Map<String, dynamic>>[];

      for (final e in listRaw) {
        if (e is Map) {
          final mm = e.cast<String, dynamic>();
          final url = (mm['url'] as String?)?.trim();
          if (url != null && url.isNotEmpty) {
            photos.add(mm);
          }
        }
      }

      // เรียงใหม่ (ใหม่สุดก่อน) โดยใช้ uploaded_at ถ้ามี หรือใช้ id ตามเวลา
      photos.sort((a, b) {
        final at = a['uploaded_at'];
        final bt = b['uploaded_at'];
        if (at is Timestamp && bt is Timestamp) {
          return bt.compareTo(at);
        }
        final aid = (a['id'] ?? '').toString();
        final bid = (b['id'] ?? '').toString();
        return bid.compareTo(aid);
      });

      setState(() {
        _statusPhotoUrl = statusPhoto;
        _statusPhotos = photos;
      });
    });
  }

  /// เลือกรูป (camera/gallery) แล้ว "คิว" ไว้เฉย ๆ — ยังไม่ส่ง
  Future<void> _pickPhotoAndQueue() async {
    if (_uploading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (!mounted || source == null) return;

    final xf = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (xf == null) return;

    final bytes = await xf.readAsBytes();
    setState(() {
      _pendingPhotoFile = xf;
      _pendingPhotoB64 = base64Encode(bytes); // ❗ ไม่มี data:image/... prefix
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เลือกรูปแล้ว • กด "อัปเดตสถานะ" เพื่อส่ง')),
    );
  }

  /// โยนไป backend: advance (+ แนบรูปถ้ามีคิวไว้)
  /// body: { rider_id: <int>, photo_base64?: <string> }
  Future<void> _advanceStatus() async {
    final sid = (_shipment?['shipment_id'] as num?)?.toInt();
    if (sid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ shipment_id')),
      );
      return;
    }

    try {
      setState(() => _uploading = true);

      final uri = Uri.parse('$_baseUrl/riders/accepted/$sid/advance');

      final body = <String, dynamic>{
        'rider_id': riderId,
        if (_pendingPhotoB64 != null && _pendingPhotoB64!.isNotEmpty)
          'photo_base64': _pendingPhotoB64, // ส่งรูป (ถ้ามี)
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      log('advance -> ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200) {
        Map<String, dynamic>? j;
        try {
          j = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}

        await _fetchDetail(silent: true);

        final newStatus = (j?['new_status'] as num?)?.toInt();

        String? returnedPhotoUrl;
        if (j?['photo'] is String && (j!['photo'] as String).isNotEmpty) {
          returnedPhotoUrl = j!['photo'] as String;
        } else if (j?['photos'] is List && (j!['photos'] as List).isNotEmpty) {
          returnedPhotoUrl = (j!['photos'] as List).cast<String>().last;
        }

        final sidStr = '$sid';
        final batch = _fs.batch();
        final shipDoc = _fs.collection('shipments').doc(sidStr);
        final riderDoc = _fs.collection('riders').doc(riderId.toString());

        // 1) อัปเดตสถานะ + เก็บ "รูปสถานะล่าสุด" แยกที่ status_photo_url (อย่าแตะ item_photo_url)
        batch.set(
          shipDoc,
          {
            if (newStatus != null) 'status': newStatus,
            if (returnedPhotoUrl != null && returnedPhotoUrl.isNotEmpty)
              'status_photo_url': returnedPhotoUrl,
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 2) เพิ่มรูปเข้า photos[] ด้วย "id" ไม่ซ้ำ เพื่อไม่ให้ arrayUnion มองว่าซ้ำ
        if (returnedPhotoUrl != null &&
            returnedPhotoUrl.isNotEmpty &&
            newStatus != null) {
          final uniqueId =
              '${DateTime.now().microsecondsSinceEpoch}_${riderId}';
          final photoEntry = {
            'id': uniqueId, // 👈 ทำให้ไม่ซ้ำทุกครั้ง
            'url': returnedPhotoUrl,
            'status': newStatus,
            'uploaded_at': Timestamp.now(),
            'riderId': riderId.toString(),
          };
          batch.set(
            shipDoc,
            {
              'photos': FieldValue.arrayUnion([photoEntry]),
            },
            SetOptions(merge: true),
          );
        }

        // 3) sync current ของไรเดอร์
        if (newStatus != null) {
          batch.set(
            riderDoc,
            {
              'current': {'shipment_id': sidStr, 'status': newStatus},
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        if (mounted) {
          setState(() {
            _pendingPhotoFile = null;
            _pendingPhotoB64 = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตสถานะสำเร็จ')),
          );
        }
      } else {
        if (!mounted) return;
        final short =
            res.body.length > 150 ? '${res.body.substring(0, 150)}...' : res.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตไม่สำเร็จ (${res.statusCode}) $short')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _statusText(dynamic s) {
    final code = s?.toString() ?? '';
    switch (code) {
      case '1':
        return 'รอไรเดอร์มารับสินค้า';
      case '2':
        return 'ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)';
      case '3':
        return 'ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง';
      case '4':
        return 'ไรเดอร์นำส่งสินค้าแล้ว';
      default:
        return 'ไม่ทราบสถานะ ($code)';
    }
  }

  int _statusStep(dynamic s) {
    final code = int.tryParse(s?.toString() ?? '') ?? 1;
    return code.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Delivery WarpSong'),
        centerTitle: false,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange, _orangeLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDetail,
            tooltip: 'รีเฟรช',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _shipment == null
                  ? const Center(child: Text('ยังไม่มีงานที่รับไว้'))
                  : _buildPrettyContent(),
    );
  }

  Widget _buildPrettyContent() {
    final s = _shipment!;
    // รูปหลักของลูกค้า: แสดงจาก item_photo_url เท่านั้น (จะไม่ถูกทับ)
    final photo = (s['item_photo_url'] as String?) ?? '';
    final itemName = s['item_name'] ?? 'เอกสารสำคัญ';
    final itemDesc = s['item_description'] ?? 'ส่งให้เจ้าของบ้านโดยตรง';
    final status = s['status'];
    final step = _statusStep(status);

    final sender = (s['sender'] as Map?)?.cast<String, dynamic>() ?? {};
    final senderAddr =
        (sender['sender_address'] as Map?)?.cast<String, dynamic>() ?? {};
    final receiver = (s['receiver'] as Map?)?.cast<String, dynamic>() ?? {};
    final recvAddr =
        (receiver['receiver_address'] as Map?)?.cast<String, dynamic>() ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 6),
              color: Color(0x1A000000),
            )
          ],
          border: Border.all(color: _orange.withOpacity(.25), width: 1),
        ),
        child: Column(
          children: [
            // Header bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE6C7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Text(
                'รายละเอียดรายการสินค้า',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปสินค้า (รูปหลักของลูกค้า)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: const Color(0xFFECECEC),
                        child: photo.isEmpty
                            ? const Icon(Icons.image,
                                size: 48, color: Colors.grey)
                            : Image.network(photo, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ชื่อสินค้า/หมายเหตุ
                  _labelValue('สินค้า:', itemName,
                      valueStyle: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 6),
                  _labelValue('หมายเหตุ:', itemDesc),
                  const SizedBox(height: 10),
                  const Text(
                    'Delivery WarpSong',
                    style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 14),

                  // ผู้ส่ง
                  const Divider(thickness: .8),
                  _partyTile(
                    title: 'ผู้ส่ง',
                    name: sender['sender_name'] ?? '-',
                    phone: sender['sender_phone'] ?? '-',
                    address: senderAddr['send_address_text'] ?? '-',
                    avatarUrl: sender['sender_avatar'] as String?,
                  ),
                  const SizedBox(height: 8),

                  // เส้นคั่น
                  const _SoftDivider(),
                  const SizedBox(height: 8),

                  // ผู้รับ
                  _partyTile(
                    title: 'ผู้รับ',
                    name: receiver['receiver_name'] ?? '-',
                    phone: receiver['receiver_phone'] ?? '-',
                    address: recvAddr['recv_address_text'] ?? '-',
                    avatarUrl: receiver['receiver_avatar'] as String?,
                  ),
                  const SizedBox(height: 16),

                  // สถานะ + ขั้นตอน
                  _statusSection(
                    statusText: _statusText(status),
                    step: step,
                    total: 4,
                  ),

                  const SizedBox(height: 16),

                  // ✅ อัลบั้ม "รูปสถานะทั้งหมด" (อ่านจาก Firestore photos[] แบบเรียลไทม์)
                  _statusPhotosSection(),

                  const SizedBox(height: 16),

                  // ปุ่มอัปเดตสถานะ และ ปุ่มเลือกรูป (คิว)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _advanceStatus,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'อัปเดตสถานะ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _pickPhotoAndQueue,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            _pendingPhotoFile != null
                                ? 'เปลี่ยนรูป'
                                : 'เลือกรูป',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // พรีวิวรูปที่คิวไว้ (ถ้ามี) + ปุ่มลบคิว
                  if (_pendingPhotoFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.file(
                              File(_pendingPhotoFile!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _pendingPhotoFile = null;
                                    _pendingPhotoB64 = null;
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.close, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Widgets =====

  Widget _statusPhotosSection() {
    // แสดง status_photo_url (ล่าสุด) เป็นรูปปก + แสดงทั้งหมดจาก _statusPhotos ด้านล่าง
    final latest = _statusPhotoUrl;
    final all = _statusPhotos;

    if ((latest == null || latest.isEmpty) && all.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('รูปสถานะทั้งหมด',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),

        // รูปล่าสุด (optional)
        if (latest != null && latest.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                latest,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 32, color: Colors.grey),
              ),
            ),
          ),

        if (latest != null && latest.isNotEmpty) const SizedBox(height: 12),

        // กริดแสดงรูปทั้งหมดใน photos[] (ย้อนหลัง)
        GridView.builder(
          itemCount: all.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final m = all[index];
            final url = (m['url'] as String?) ?? '';
            final st = (m['status'] as num?)?.toInt();
            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                if (st != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'S$st',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _labelValue(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(color: Colors.black87, height: 1.25),
          ),
        ),
      ],
    );
  }

  Widget _partyTile({
    required String title,
    required String name,
    required String phone,
    required String address,
    String? avatarUrl,
  }) {
    final avatar = avatarUrl?.isNotEmpty == true
        ? NetworkImage(avatarUrl!)
        : const AssetImage('assets/images/avatar_placeholder.png')
            as ImageProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(backgroundImage: avatar, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelValue('คุณ', name),
                  _labelValue('เบอร์:', phone),
                  const SizedBox(height: 4),
                  _labelValue('ที่อยู่', address),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusSection({
    required String statusText,
    required int step,
    required int total,
  }) {
    final double progress = step / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withOpacity(.35), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: _orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.black87),
                ),
              ),
              Text('ขั้นตอน $step/$total',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEFEFEF),
              color: _orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.black.withOpacity(.08),
      thickness: 1,
      height: 1,
    );
  }
}
