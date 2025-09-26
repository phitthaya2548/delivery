import 'dart:developer';

import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_detail_shipment_byid.dart';
import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetailItem extends StatefulWidget {
  final int shipmentId;
  const DetailItem({Key? key, required this.shipmentId}) : super(key: key);

  @override
  State<DetailItem> createState() => _DetailItemState();
}

class _DetailItemState extends State<DetailItem> {
  String baseUrl = '';
  bool loading = true;
  String? error;
  Item? item;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final cfg = await Configuration.getConfig();
    baseUrl = cfg['apiEndpoint'];
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res =
          await http.get(Uri.parse('$baseUrl/shipments/${widget.shipmentId}'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final parsed = resgetShipmentRiderByIdFromJson(res.body);
      if (parsed.success != true) throw Exception('response not success');

      log(res.body); // debug ดู payload จริงจาก backend
      setState(() => item = parsed.item); // ✅ ใช้ URL จาก backend ตรง ๆ
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onAccept() {
    // TODO: ยิง API รับงานจริง
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ยังไม่เปิดรับงานในหน้านี้')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 36),
                        const SizedBox(height: 8),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _fetch, child: const Text('ลองใหม่')),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final it = item!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F0),
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'รายละเอียดรายการสินค้า',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                // รูปจริงจาก API (absolute URL จาก backend)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade300,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (it.lastPhoto.url.isNotEmpty)
                        ? Image.network(
                            it.lastPhoto.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  size: 36, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined,
                                size: 36, color: Colors.grey),
                          ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  'Delivery WarpSong',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                // ผู้ส่ง
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      backgroundImage: (it.sender.avatar != null &&
                              it.sender.avatar!.isNotEmpty)
                          ? NetworkImage(it.sender.avatar!)
                          : null,
                      child: (it.sender.avatar == null ||
                              it.sender.avatar!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ผู้ส่ง',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              'คุณ: ${it.sender.name.isNotEmpty ? it.sender.name : "—"}'),
                          Text(
                              'เบอร์: ${it.sender.phone.isNotEmpty ? it.sender.phone : "—"}'),
                          const SizedBox(height: 4),
                          const Text('ที่อยู่'),
                          Text(
                            it.sender.address.addressText.isNotEmpty
                                ? it.sender.address.addressText
                                : '—',
                            style: const TextStyle(
                                height: 1.3, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24, thickness: 2, color: Colors.orange),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      backgroundImage: (it.receiver.avatar != null &&
                              it.receiver.avatar!.isNotEmpty)
                          ? NetworkImage(it.receiver.avatar!)
                          : null,
                      child: (it.receiver.avatar == null ||
                              it.receiver.avatar!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ผู้รับ',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              'คุณ: ${it.receiver.name.isNotEmpty ? it.receiver.name : "—"}'),
                          Text(
                              'เบอร์: ${it.receiver.phone.isNotEmpty ? it.receiver.phone : "—"}'),
                          const SizedBox(height: 4),
                          const Text('ที่อยู่'),
                          Text(
                            it.receiver.address.addressText.isNotEmpty
                                ? it.receiver.address.addressText
                                : '—',
                            style: const TextStyle(
                                height: 1.3, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('รับงาน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('กลับ'),
          ),
        ),
      ],
    );
  }
}
