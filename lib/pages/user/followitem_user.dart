import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_detail_shipment.dart';
import 'package:deliveryrpoject/pages/service/firestore_location_service.dart';
import 'package:deliveryrpoject/pages/user/map_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class FollowitemUser extends StatefulWidget {
  const FollowitemUser({Key? key, required this.shipmentId}) : super(key: key);

  final int shipmentId;

  @override
  State<FollowitemUser> createState() => _FollowitemUserState();
}

class _FollowitemUserState extends State<FollowitemUser> {
  static const _orange = Color(0xFFFD8700);
  static const _bg = Color(0xFFF4F4F4);

  GoogleMapController? _mapController;
  FirestoreLocationService firestoreService = FirestoreLocationService(1);
  String _baseUrl = '';
  bool _loading = true;
  String? _error;
  ShipmentDetail? _data;
  double? _riderLat;
  double? _riderLng;
  @override

  /// Called when the widget is inserted into the tree.
  /// It initializes the map controller and fetches the detail shipment data.
  void initState() {
    super.initState();
    _initAndFetch();
    _fetchRiderLocation();
  }

  void _fetchRiderLocation() {
    firestoreService.streamSelf().listen((snapshot) {
      if (snapshot.exists) {
        final riderLocation = snapshot.data();
        final gps = riderLocation?['gps'] as GeoPoint?;
        if (gps != null) {
          setState(() {
            _riderLat = gps.latitude;
            _riderLng = gps.longitude;
          });
          log('Rider location updated: ${_riderLat}, ${_riderLng}');
        }
      }
    });
  }

  Future<void> _initAndFetch() async {
    try {
      final cfg = await Configuration.getConfig();
      final ep = (cfg['apiEndpoint'] as String? ?? '').trim();
      _baseUrl = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;
      await _fetchDetail();
    } catch (e) {
      log('init error: $e');
      if (mounted) {
        setState(() {
          _error = 'ตั้งค่า API ไม่ถูกต้อง';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/shipments/${widget.shipmentId}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final item = ShipmentDetail.fromItemJson(
          j['item'] as Map<String, dynamic>,
          baseUrl: _baseUrl,
        );

        setState(() {
          _data = item;
          _loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _error = 'ไม่พบรายการ';
          _loading = false;
        });
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
              colors: [_orange, Color(0xFFFFDE98)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchDetail,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('ย้อนกลับ',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final d = _data!;
    return RefreshIndicator(
      onRefresh: () async => _fetchDetail(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // การ์ดไรเดอร์
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(d.riderAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.riderName ?? 'รอจัดสรรไรเดอร์',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.motorcycle,
                              size: 18, color: _orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              d.licensePlate ?? 'เลขทะเบียน: -',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: _orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              d.riderPhone ?? '-',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _card(
            child: SizedBox(
                height: 250,
                child: // GoogleMap widget
                    GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(d.senderLat ?? 0.0, d.senderLng ?? 0.0),
                    zoom: 14.0,
                  ),
                  markers: {
                    // Sender Marker
                    Marker(
                      markerId: MarkerId('sender'),
                      position: LatLng(d.senderLat ?? 0.0, d.senderLng ?? 0.0),
                      infoWindow: InfoWindow(
                        title: 'Sender',
                        snippet: 'This is the sender location',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue), // Custom icon color (blue)
                    ),

                    // Receiver Marker
                    Marker(
                      markerId: MarkerId('receiver'),
                      position:
                          LatLng(d.receiverLat ?? 0.0, d.receiverLng ?? 0.0),
                      infoWindow: InfoWindow(
                        title: 'Receiver',
                        snippet: 'This is the receiver location',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor
                              .hueGreen), // Custom icon color (green)
                    ),

                    // Rider Marker (if available)
                    if (_riderLat != null && _riderLng != null)
                      Marker(
                        markerId: MarkerId('rider'),
                        position: LatLng(_riderLat!, _riderLng!),
                        infoWindow: InfoWindow(
                          title: 'Rider',
                          snippet: 'This is the rider\'s current location',
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed), // Custom icon color (red)
                      ),
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                )),
          ),
          const SizedBox(height: 12),

          // ผู้ส่ง
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(d.senderAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ผู้ส่ง',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      _rowIconText(
                          Icons.person_2_outlined, d.senderName ?? '-'),
                      const SizedBox(height: 4),
                      _rowIconText(Icons.phone_outlined, d.senderPhone ?? '-'),
                      const SizedBox(height: 4),
                      _dividerThin(),
                      const SizedBox(height: 8),
                      _rowIconText(Icons.location_on_outlined, d.sendAddress),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ผู้รับ
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(d.receiverAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ผู้รับ',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      _rowIconText(
                          Icons.person_2_outlined, d.receiverName ?? '-'),
                      const SizedBox(height: 4),
                      _rowIconText(Icons.phone, d.receiverPhone ?? '-'),
                      const SizedBox(height: 6),
                      _dividerThin(),
                      const SizedBox(height: 8),
                      _rowIconText(Icons.location_on_outlined, d.recvAddress),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // สถานะการส่ง
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.location_pin, color: _orange),
                  SizedBox(width: 6),
                  Text('สถานะการส่ง',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                const SizedBox(height: 12),
                _statusTimeline(d.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI Helpers ----------

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _avatar(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl == null
            ? Container(
                color: Colors.black12,
                child: const Icon(Icons.person, color: Colors.black38),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.person, color: Colors.black38),
                ),
                loadingBuilder: (c, w, p) =>
                    p == null ? w : Container(color: Colors.black12),
              ),
      ),
    );
  }

  Widget _rowIconText(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _dividerThin() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(right: 6),
      color: const Color(0xFFFFE1B8),
    );
  }

  Widget _mapPlaceholder({bool loading = false}) {
    return Container(
      color: const Color(0xFFEFF5EA),
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator()
          : TextButton(
              child: const Text('แผนที่ / รูปเส้นทาง'),
              onPressed: () {
                Get.to(() => const MapUser());
              },
            ),
    );
  }

  /// ไทม์ไลน์สถานะ (1..4)
  Widget _statusTimeline(String status) {
    final step = switch (status) {
      '1' => 1,
      '2' => 2,
      '3' => 3,
      '4' => 4,
      _ => 0,
    };
    final items = const [
      ('รอไรเดอร์รับงาน', 'status1'),
      ('ไรเดอร์รับงาน (กำลังมารับสินค้า)', 'status2'),
      ('ไรเดอร์รับสินค้าแล้วกำลังจัดส่งต่อไป', 'status3'),
      ('ไรเดอร์จัดส่งสำเร็จแล้ว', 'status4'),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _statusRow(
            index: i + 1,
            text: items[i].$1,
            done: (i + 1) <= step,
          ),
      ],
    );
  }

  Widget _statusRow(
      {required int index, required String text, required bool done}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? Colors.green : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          const SizedBox(width: 10),
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
