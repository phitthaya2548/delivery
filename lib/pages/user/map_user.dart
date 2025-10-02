import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryrpoject/pages/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapUser extends StatefulWidget {
  const MapUser({super.key});

  @override
  State<MapUser> createState() => _MapUserState();
}

class _MapUserState extends State<MapUser> {
  final int riderId = 1; // ตัวอย่าง Rider ID
  late MapController _mapController; // ควบคุมแผนที่
  late LatLng riderPos; // ตำแหน่งของผู้ขับขี่

  @override
  void initState() {
    super.initState();
    _mapController = MapController(); // สร้าง MapController
    riderPos = LatLng(16.244012, 103.249038); // กำหนดตำแหน่งที่ต้องการแสดง
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreLocationService(riderId);

    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลตำแหน่งผู้ขับขี่'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestoreService.streamSelf(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('ไม่มีข้อมูลตำแหน่ง'));
          }

          final userData = snapshot.data!.data();
          final gps = userData?['gps'];
          final address = userData?['address'];

          if (gps == null) {
            return Center(child: Text('ข้อมูล GPS ไม่สมบูรณ์'));
          }

          riderPos =
              LatLng(gps.latitude, gps.longitude); // ใช้ตำแหน่งจาก Firestore

          // Log ที่อยู่เพื่อดูข้อมูลใน Console
          if (address != null) {
            print('Address: $address'); // แสดงที่อยู่ใน console
          } else {
            print('Address not available');
          }

          // เลื่อนแผนที่ไปที่ตำแหน่งผู้ขับขี่
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(riderPos, 15); // เลื่อนไปที่ตำแหน่งที่กำหนด
          });

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: riderPos, // ตำแหน่งของผู้ขับขี่
                          width: 80.0,
                          height: 80.0,
                          child: Icon(
                            Icons.directions_bike,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (address != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'ที่อยู่: $address', // แสดงที่อยู่ของผู้ขับขี่
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
