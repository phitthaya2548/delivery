import 'dart:async';

import 'package:deliveryrpoject/pages/user/widgets/appbarheader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapRider extends StatefulWidget {
  const MapRider({Key? key}) : super(key: key);

  @override
  State<MapRider> createState() => _MapRiderState();
}

class _MapRiderState extends State<MapRider> {
  final MapController _mapController = MapController();

  // ตัวอย่างพิกัดผู้ส่ง/ผู้รับ (เอาจาก backend จริงของคุณ)
  final LatLng pickup = LatLng(16.2366717, 103.2836641);
  final LatLng dropoff = LatLng(16.2352536, 103.2697637);

  LatLng? riderPos;
  StreamSubscription<Position>? _posSub;
  bool _firstCentered = false;

  @override
  void initState() {
    super.initState();
    _initLocate();
  }

  Future<void> _initLocate() async {
    // 1) เปิด location service ไหม
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('Location service ยังปิดอยู่');
        return;
      }
    }

    // 2) ขอสิทธิ์
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (perm == LocationPermission.denied) return;

    // 3) ตำแหน่งล่าสุด (ถ้ามี)
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      _updateRider(LatLng(last.latitude, last.longitude), centerCamera: true);
    }

    // 4) พิกัดปัจจุบัน (กันค้างด้วย timeLimit)
    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      _updateRider(LatLng(current.latitude, current.longitude),
          centerCamera: true);
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
    }

    // 5) subscribe realtime
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // ขยับ >5 เมตรค่อยเด้ง
      ),
    ).listen((pos) {
      _updateRider(LatLng(pos.latitude, pos.longitude));
    });
  }

  void _updateRider(LatLng latLng, {bool centerCamera = false}) {
    setState(() => riderPos = latLng);
    if (!_firstCentered || centerCamera) {
      _firstCentered = true;
      _mapController.move(latLng, 15); // zoom 15 ให้เห็นชัด
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // กลางแผนที่เริ่มต้น (ให้เห็น pickup+dropoff ถ้า riderPos ยังไม่มี)
    final center = riderPos ??
        LatLng(
          (pickup.latitude + dropoff.latitude) / 2,
          (pickup.longitude + dropoff.longitude) / 2,
        );

    return Scaffold(
      appBar: customAppBar(),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          // เลเยอร์แผนที่ (Thunderforest ฟรี ต้องมี key)
          TileLayer(
            urlTemplate:
                'https://tile.thunderforest.com/neighbourhood/{z}/{x}/{y}.png?apikey={key}',
            additionalOptions: const {
              'key': '25f1e6447a5446a39768d3eb42100002'
            },
            userAgentPackageName: 'com.example.deliveryrpoject',
          ),

          // เส้นทาง (เดโม่เป็นเส้นตรง)
          PolylineLayer(
            polylines: [
              Polyline(points: [pickup, dropoff], strokeWidth: 4),
            ],
          ),

          // หมุดต่าง ๆ — ขยายขนาดให้พอ และบีบ Column ภายใน (_pin)
          MarkerLayer(
            markers: [
              Marker(
                point: pickup,
                width: 64, // เดิม 40 → ขยายกัน overflow
                height: 72, // เดิม 40 → ขยายกัน overflow
                child: _pin(
                    color: Colors.green,
                    icon: Icons.storefront,
                    label: 'รับของ'),
              ),
              Marker(
                point: dropoff,
                width: 64,
                height: 72,
                child:
                    _pin(color: Colors.red, icon: Icons.flag, label: 'ส่งของ'),
              ),
              if (riderPos != null)
                Marker(
                  point: riderPos!,
                  width: 64,
                  height: 72,
                  child: _pin(
                      color: Colors.blue, icon: Icons.motorcycle, label: 'ฉัน'),
                ),
            ],
          ),

          // ปุ่มช่วยใช้งาน
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundBtn(
                    icon: Icons.my_location,
                    onTap: () async {
                      final p = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.bestForNavigation,
                      );
                      _updateRider(LatLng(p.latitude, p.longitude),
                          centerCamera: true);
                    },
                  ),
                  const SizedBox(height: 8),
                  _roundBtn(
                    icon: Icons.add,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _roundBtn(
                    icon: Icons.remove,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pin({required Color color, required IconData icon, String? label}) {
    return Column(
      mainAxisSize: MainAxisSize.min, // สำคัญ! ลดโอกาสล้นกรอบ Marker
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (label != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon)),
      ),
    );
  }
}
