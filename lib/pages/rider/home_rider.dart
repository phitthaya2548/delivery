import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_shipment_rider.dart';
import 'package:deliveryrpoject/pages/rider/detail_item.dart';
import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeRider extends StatefulWidget {
  const HomeRider({Key? key}) : super(key: key);

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider> {
  String baseUrl = '';
  bool loading = true;
  String? error;
  List<Shipment> shipments = [];

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
      final res = await http.get(Uri.parse('$baseUrl/shipments'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final parsed = resgetShipmentRiderFromJson(res.body);
      if (parsed.success != true) throw Exception('response not success');

      setState(() {
        shipments = parsed.shipments;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refresh() => _fetch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? _ErrorView(message: error!, onRetry: _fetch)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: shipments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 12),
                          child: Text(
                            'งานที่ว่าง',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange,
                            ),
                          ),
                        );
                      }
                      final s = shipments[index - 1];
                      return _JobCard(
                        title: 'Delivery WarpSong',
                        photoUrl: s.lastPhoto.url, // จาก model
                        itemName: s.itemName,
                        pickupName: s.sender.name, // ชื่อผู้ส่ง
                        pickupAddress:
                            s.sender.address.addressText, // ที่อยู่รับของ
                        deliveryName: s.receiver.name, // ชื่อผู้รับ
                        deliveryAddress:
                            s.receiver.address.addressText, // ที่อยู่ปลายทาง
                        onAccept: () {
                          // TODO: เชื่อม API รับงานจริงภายหลัง (POST /shipments/:id/accept)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('ยังไม่เปิดรับงานในหน้านี้')),
                          );
                        },
                        onDetail: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailItem(shipmentId: s.shipmentId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

/* ======================= UI Components ======================= */

class _JobCard extends StatelessWidget {
  final String title;
  final String? photoUrl;
  final String itemName;

  // ข้อมูล “รับที่/ส่งที่”
  final String pickupName;
  final String pickupAddress;
  final String deliveryName;
  final String deliveryAddress;

  final VoidCallback onAccept;
  final VoidCallback onDetail;

  const _JobCard({
    Key? key,
    required this.title,
    required this.photoUrl,
    required this.itemName,
    required this.pickupName,
    required this.pickupAddress,
    required this.deliveryName,
    required this.deliveryAddress,
    required this.onAccept,
    required this.onDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // แถวบน: ไอคอน + ชื่อระบบ
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // เนื้อหา: รูป + รายละเอียด (รับที่/ส่งที่)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(url: photoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อพัสดุ
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // รับที่ (ผู้ส่ง)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_pin,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context)
                                    .style
                                    .copyWith(height: 1.35),
                                children: [
                                  const TextSpan(
                                    text: 'รับที่: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                      text: pickupName.isNotEmpty
                                          ? pickupName
                                          : '—'),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                      text: pickupAddress.isNotEmpty
                                          ? pickupAddress
                                          : '—'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_pin,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context)
                                    .style
                                    .copyWith(height: 1.35),
                                children: [
                                  const TextSpan(
                                    text: 'ส่งที่: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                      text: deliveryName.isNotEmpty
                                          ? deliveryName
                                          : '—'),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                      text: deliveryAddress.isNotEmpty
                                          ? deliveryAddress
                                          : '—'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ปุ่ม
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('รับงาน'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetail,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade300, width: 2),
                      foregroundColor: Colors.orange.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('รายละเอียด'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({Key? key, this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: (url != null && url!.isNotEmpty)
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey),
              )
            : const Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({Key? key, required this.message, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }
}
