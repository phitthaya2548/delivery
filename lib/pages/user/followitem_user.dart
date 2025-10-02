// lib/pages/user/followitem_user.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_detail_shipment.dart';
import 'package:deliveryrpoject/pages/service/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  String _baseUrl = '';
  bool _loading = true;
  String? _error;

  /// จาก REST (ข้อมูลคงที่: sender/receiver/rider/ที่อยู่/รูปล่าสุดจาก DB)
  ShipmentDetail? _detail;

  /// ค่าจาก Firestore (Realtime-ish)
  int _realtimeStatus = 1; // 1..4
  String? _realtimeRiderId; // shipments/{sid}.riderId
  LatLng? _realtimeRiderLatLng; // จาก Firestore (streamSelf)
  String? _realtimePhotoUrl; // shipments/{sid}.item_photo_url

  /// ✅ เก็บ "รูปย้อนหลัง" แยกตามสถานะ: 1..4 -> [url1, url2, ...] (เรียงใหม่สุดก่อน)
  Map<int, List<String>> _statusPhotos = {};

  /// 🔁 Stream ตำแหน่งไรเดอร์ + กล้องตาม
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _riderSub;
  bool _followRider = true; // ให้กล้องตามไรเดอร์แบบอัตโนมัติ
  DateTime? _lastCamMove; // throttle การขยับกล้อง

  /// 🚗 เส้นทาง (Polyline) + ETA/Distance
  List<LatLng> _routePoints = [];
  String? _etaText;
  String? _distText;
  Timer? _routeDebounce;

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  @override
  void dispose() {
    _riderSub?.cancel();
    _routeDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initAndFetch() async {
    try {
      final cfg = await Configuration.getConfig();
      final ep = (cfg['apiEndpoint'] as String? ?? '').trim();
      _baseUrl = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;

      await _fetchDetail(); // REST: รายละเอียด shipment
      _bindShipmentRealtime(); // Firestore: status + riderId + item_photo_url + photos
    } catch (e) {
      log('init error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'ตั้งค่า API ไม่ถูกต้อง';
        _loading = false;
      });
    }
  }

  /// ดึงรายละเอียดจาก REST (ข้อมูลคงที่)
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
          _detail = item;
          _loading = false;
        });
        // หลังได้ sender/receiver แล้ว ลองอัปเดตเส้นทางครั้งแรกถ้ามีพิกัดไรเดอร์อยู่แล้ว
        _scheduleRouteUpdate();
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

  /// สตรีม shipments/{sid} → อ่าน status + riderId + item_photo_url + photos (Realtime)
  void _bindShipmentRealtime() {
    final sid = widget.shipmentId.toString();
    FirebaseFirestore.instance
        .collection('shipments')
        .doc(sid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (!snap.exists) return;

      final data = snap.data();

      final st = (data?['status'] as num?)?.toInt();
      final rid = data?['riderId']?.toString();
      final ph = (data?['item_photo_url'] as String?)?.trim();

      // รองรับ status_photo_url (รูปของสถานะปัจจุบัน)
      final curStatusPhoto = (data?['status_photo_url'] as String?)?.trim();

      // เดิม: ถ้ามี photos[] ให้ map ตามสถานะ (เก็บหลายรูปย้อนหลัง)
      final photosList = (data?['photos'] as List?) ?? const [];
      final Map<int, List<String>> statusPhotos = {1: [], 2: [], 3: [], 4: []};

      for (final m in photosList.whereType<Map>()) {
        final mm = m.cast<String, dynamic>();
        final s = (mm['status'] as num?)?.toInt();
        final url = (mm['url'] as String?)?.trim();
        if (s != null && s >= 1 && s <= 4 && url != null && url.isNotEmpty) {
          final bucket = statusPhotos[s]!;
          if (!bucket.contains(url)) bucket.insert(0, url);
        }
      }

      if (st != null &&
          st >= 1 &&
          st <= 4 &&
          (curStatusPhoto ?? '').isNotEmpty) {
        final bucket = statusPhotos[st]!;
        if (!bucket.contains(curStatusPhoto)) {
          bucket.insert(0, curStatusPhoto!);
        }
      }

      final statusChanged = (st != null && st != _realtimeStatus);

      setState(() {
        if (st != null && st >= 1 && st <= 4) _realtimeStatus = st;
        if ((ph ?? '').isNotEmpty) _realtimePhotoUrl = ph;
        _statusPhotos = statusPhotos;

        if ((rid ?? '').isNotEmpty && rid != _realtimeRiderId) {
          _realtimeRiderId = rid;
          _bindRiderRealtimeStream(rid!); // ✅ ใช้ streamSelf() แทนการ poll
        }
      });

      if (statusChanged) _scheduleRouteUpdate();
    });
  }

  /// ✅ ใช้ FirestoreLocationService.streamSelf() (Realtime) + กล้องตามไรเดอร์แบบ throttle
  void _bindRiderRealtimeStream(String riderIdStr) {
    // FirestoreLocationService ปัจจุบันรับ int → แปลงก่อน
    final riderId = int.tryParse(riderIdStr);
    if (riderId == null || riderId <= 0) return;

    _riderSub?.cancel(); // ยกเลิกสตรีมเดิม (ถ้ามี)

    final svc = FirestoreLocationService(riderId);
    _riderSub = svc.streamSelf().listen((snap) {
      if (!mounted) return;

      final m = snap.data();
      final gp = m?['gps'];
      if (gp is GeoPoint) {
        final pos = LatLng(gp.latitude, gp.longitude);
        final posChanged = _realtimeRiderLatLng == null ||
            _realtimeRiderLatLng!.latitude != pos.latitude ||
            _realtimeRiderLatLng!.longitude != pos.longitude;

        setState(() {
          _realtimeRiderLatLng = pos;
        });

        // ให้กล้องค่อย ๆ ตามไรเดอร์ (กันกระตุกด้วย throttle ~800ms)
        if (_mapController != null && _followRider) {
          final now = DateTime.now();
          if (_lastCamMove == null ||
              now.difference(_lastCamMove!) >
                  const Duration(milliseconds: 800)) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
            _lastCamMove = now;
          }
        }

        if (posChanged)
          _scheduleRouteUpdate(); // ตำแหน่งเปลี่ยน → ลองอัปเดตเส้นทาง
      }
    });
  }

  /// ---- เส้นทาง OSRM ----

  void _scheduleRouteUpdate() {
    // debounce กันเรียกถี่จาก stream/pan
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(milliseconds: 500), () {
      _updateRoute();
    });
  }

  /// เลือกปลายทางตามสถานะ:
  /// 1,2 → ไปจุดรับ / 3 → ไปจุดส่ง / 4 → ไม่วาดเส้น (เสร็จสิ้น)
  Future<void> _updateRoute() async {
    if (_detail == null) return;
    final rider = _realtimeRiderLatLng;
    if (rider == null) return;

    // กำหนดปลายทางตามสถานะ
    LatLng? dest;
    if (_realtimeStatus == 1 || _realtimeStatus == 2) {
      if (_detail!.senderLat != null && _detail!.senderLng != null) {
        dest = LatLng(_detail!.senderLat!, _detail!.senderLng!);
      }
    } else if (_realtimeStatus == 3) {
      if (_detail!.receiverLat != null && _detail!.receiverLng != null) {
        dest = LatLng(_detail!.receiverLat!, _detail!.receiverLng!);
      }
    } else {
      // status 4 → clear route & show complete
      setState(() {
        _routePoints = [];
        _etaText = 'เสร็จสิ้น';
        _distText = null;
      });
      return;
    }

    if (dest == null) return;

    try {
      final data = await _getOsrmRoute(rider, dest);
      final pts = data['points'] as List<LatLng>;
      final sec = (data['duration'] as num).toDouble();
      final mtr = (data['distance'] as num).toDouble();

      setState(() {
        _routePoints = pts;
        _etaText = _fmtDuration(sec);
        _distText = _fmtDistance(mtr);
      });

      // ถ้าเพิ่งได้เส้นทางครั้งแรกหรือจุดสำคัญเปลี่ยน ลอง fit ให้เห็นภาพรวม
      if (_mapController != null && pts.length >= 2) {
        _fitBoundsFor(rider, dest, extra: pts);
      }
    } catch (e) {
      log('[route] error: $e');
      // ไม่ต้อง throw ต่อ ให้ UI ใช้ค่าล่าสุดที่มี
    }
  }

  Future<Map<String, dynamic>> _getOsrmRoute(LatLng a, LatLng b) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${a.longitude},${a.latitude};'
        '${b.longitude},${b.latitude}'
        '?overview=full&geometries=geojson&steps=false&annotations=true';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('OSRM failed ${res.statusCode}');
    }
    final j = jsonDecode(res.body);
    final routes = j['routes'] as List?;
    if (routes == null || routes.isEmpty) throw Exception('no route');
    final r = routes[0] as Map<String, dynamic>;
    final coords = (r['geometry']['coordinates'] as List)
        .map<LatLng>(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    return {
      'points': coords,
      'duration': (r['duration'] as num).toDouble(),
      'distance': (r['distance'] as num).toDouble(),
    };
  }

  String _fmtDuration(double sec) {
    final min = (sec / 60).round();
    if (min < 60) return '$min นาที';
    final h = min ~/ 60;
    final rm = min % 60;
    return '$h ชม. $rm นาที';
  }

  String _fmtDistance(double m) {
    if (m < 1000) return '${m.round()} ม.';
    return '${(m / 1000).toStringAsFixed(1)} กม.';
  }

  void _fitBoundsFor(LatLng a, LatLng b, {List<LatLng>? extra}) {
    final pts = <LatLng>[a, b, ...(extra ?? const [])];
    double minLat = pts.map((e) => e.latitude).reduce((x, y) => x < y ? x : y);
    double maxLat = pts.map((e) => e.latitude).reduce((x, y) => x > y ? x : y);
    double minLng = pts.map((e) => e.longitude).reduce((x, y) => x < y ? x : y);
    double maxLng = pts.map((e) => e.longitude).reduce((x, y) => x > y ? x : y);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  // ---------- UI ----------

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
      
    );
  }

  Widget _buildContent(BuildContext context) {
    final d = _detail!;
    final riderName = d.riderName ?? 'รอจัดสรรไรเดอร์';
    final riderPhone = d.riderPhone ?? '-';
    final plate = d.licensePlate ?? 'เลขทะเบียน: -';

    // รูปการ์ดบนสุด: ใช้ realtime ก่อน ถ้าไม่มีค่อย fallback ไปของ REST
    final photoUrl = _realtimePhotoUrl ?? (d.photoUrl ?? '');

    // markers: sender/receiver (REST) + rider (Realtime via stream)
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('sender'),
        position: LatLng(d.senderLat ?? 0.0, d.senderLng ?? 0.0),
        infoWindow: const InfoWindow(title: 'Sender'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('receiver'),
        position: LatLng(d.receiverLat ?? 0.0, d.receiverLng ?? 0.0),
        infoWindow: const InfoWindow(title: 'Receiver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      if (_realtimeRiderLatLng != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: _realtimeRiderLatLng!,
          infoWindow: const InfoWindow(title: 'Rider'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };

    final polylines = <Polyline>{
      if (_routePoints.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('activeRoute'),
          points: _routePoints,
          width: 6,
          geodesic: true,
          color: Colors.blue,
        ),
    };

    return RefreshIndicator(
      onRefresh: () async => _fetchDetail(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // การ์ด: รูปสินค้าล่าสุด (Realtime > REST) + แตะเพื่อดูเต็มจอ
          _card(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (photoUrl.isNotEmpty) {
                      _openFullImage(photoUrl);
                    }
                  },
                  child: Container(
                    color: const Color(0xFFECECEC),
                    child: (photoUrl.isEmpty)
                        ? const Icon(Icons.image, size: 48, color: Colors.grey)
                        : Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

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
                      Text(riderName,
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
                              plate,
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
                              riderPhone,
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

          // แผนที่ + rider realtime (streamSelf) + polyline + ETA/Distance
          _card(
            child: SizedBox(
              height: 250,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(d.senderLat ?? 0.0, d.senderLng ?? 0.0),
                      zoom: 14.0,
                    ),
                    markers: markers,
                    polylines: polylines,
                    onMapCreated: (c) {
                      _mapController = c;

                      _scheduleRouteUpdate();
                    },
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,

                    // ✅ ให้แผนที่รับ gesture ก่อน ListView (แก้ปัญหาลาก/ซูมไม่ได้)
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  if (_etaText != null || _distText != null)
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 8,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_etaText != null)
                            _chip(Icons.access_time, _etaText!),
                          if (_distText != null)
                            _chip(Icons.straighten, _distText!),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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

          // สถานะการส่ง (เรียลไทม์จาก _realtimeStatus) + รูปย้อนหลังของสถานะนั้น ๆ
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
                _statusTimeline(_realtimeStatus),
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
        child: imageUrl == null || imageUrl.isEmpty
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

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// ไทม์ไลน์สถานะ (1..4) — ใช้ค่าจาก Firestore แบบเรียลไทม์
  Widget _statusTimeline(int status) {
    final step = status.clamp(1, 4);
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

  /// แถวสถานะ + แสดงรูป "ย้อนหลัง" ของสถานะนั้น (ถ้ามี)
  Widget _statusRow({
    required int index,
    required String text,
    required bool done,
  }) {
    final list = _statusPhotos[index] ?? const <String>[];
    final hasImages = list.isNotEmpty;
    final first = hasImages ? list.first : null;
    final more = hasImages && list.length > 1 ? list.length - 1 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // วงกลมหมายเลข
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

          // ข้อความ + รูป (ถ้ามี)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text),
                if (hasImages) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _openPhotoGallery(index, list),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              first!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 64,
                                child: Center(
                                  child: Icon(Icons.broken_image,
                                      size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          if (more > 0)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+$more',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openPhotoGallery(index, list),
                      icon: const Icon(Icons.photo_library),
                      label: Text('ดูทั้งหมด (${list.length})'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ไอคอนติ๊ก
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  // ---------- Viewers ----------

  void _openPhotoGallery(int status, List<String> urls) {
    if (urls.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text('รูปย้อนหลังของสถานะ $status',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: urls.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (_, i) {
                      final u = urls[i];
                      return GestureDetector(
                        onTap: () => _openFullImage(u),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            u,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white70),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
