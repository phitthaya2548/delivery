import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryrpoject/config/config.dart';
import 'package:deliveryrpoject/models/res/res_getlocation_byrider.dart';
import 'package:deliveryrpoject/pages/service/firestore_location_service.dart';
import 'package:deliveryrpoject/pages/service/rider_location_service.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapRider extends StatefulWidget {
  const MapRider({Key? key}) : super(key: key);

  @override
  State<MapRider> createState() => _MapRiderState();
}

class _MapRiderState extends State<MapRider> {
  GoogleMapController? _mapController;
  int? riderId = 0;

  late final FirestoreLocationService _fs;
  late final RiderLocationService _rls;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _fireSub;
  StreamSubscription<Position>? _gpsSub;

  LatLng? riderPos;
  LatLng? senderPos;
  LatLng? receiverPos;

  List<LatLng> routeToSender = [];
  List<LatLng> routeToReceiver = [];
  List<LatLng> currentActiveRoute = [];

  bool isPickedUp = false;
  bool showingRouteToSender = true;

  String? _addressLine;
  bool _firstCentered = false;
  bool _followGps = true;
  Timer? _pushThrottle;

  String url = '';
  late BitmapDescriptor riderIcon;
  // Route information
  String? estimatedTime;
  String? estimatedDistance;
  String? routeInstructions;

  // The shipment response model
  ResgetShipmentRidergetLocation? shipmentData;

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((config) {
      setState(() {
        url = config['apiEndpoint'];
      });
      log("API endpoint configured: $url");
      _fetchShipmentLocationData();
    });

    final auth = SessionStore.getAuth();
    if (auth != null) {
      riderId = auth['userId'];
    }

    log("Rider ID: $riderId");
    _fs = FirestoreLocationService(riderId!);
    _rls = RiderLocationService();
    _rls.initialize();
    _listenFirestore();
    _initLocate();
    _loadCustomIcon();
  }

  void _loadCustomIcon() async {
    try {
      riderIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(
          size: Size(50, 60), // You can define the size here
          devicePixelRatio: 2, // You can set the device pixel ratio for scaling
        ),
        'assets/images/car.png', // Correct path to the rider icon
      );
      setState(() {}); // Trigger UI update after loading the custom icon
    } catch (e) {
      print('Error loading custom icon: $e'); // Handle errors if any
    }
  }

  Future<void> _fetchShipmentLocationData() async {
    final apiUrl = url.isNotEmpty
        ? '$url/riders/accepted/location?rider_id=$riderId'
        : 'http://10.0.2.2:3000/riders/accepted/location?rider_id=$riderId';

    log("Fetching from: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        shipmentData = ResgetShipmentRidergetLocation.fromJson(data);

        if (shipmentData != null) {
          setState(() {
            senderPos = LatLng(double.parse(shipmentData!.sender.lat),
                double.parse(shipmentData!.sender.lng));
            receiverPos = LatLng(double.parse(shipmentData!.receiver.lat),
                double.parse(shipmentData!.receiver.lng));
          });

          _updateRoutes();
        }
      } else {
        log('Failed to load shipment data: ${response.statusCode}');
        throw Exception('Failed to load shipment data: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching shipment location data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> getDetailedOSRMRoute(
      LatLng start, LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=true&annotations=true';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'];
          final routePoints = coordinates
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();

          final duration = route['duration']; // in seconds
          final distance = route['distance']; // in meters
          final legs = route['legs'];

          String instructions = '';
          if (legs != null && legs.isNotEmpty && legs[0]['steps'] != null) {
            final steps = legs[0]['steps'];
            for (var step in steps.take(3)) {
              // Take first 3 instructions
              final maneuver = step['maneuver'];
              final instruction = maneuver['instruction'] ?? '';
              if (instruction.isNotEmpty) {
                instructions += instruction + '\n';
              }
            }
          }

          return {
            'points': routePoints,
            'duration': duration,
            'distance': distance,
            'instructions': instructions.trim(),
          };
        }
      }
      throw Exception('Failed to get route: ${response.statusCode}');
    } catch (e) {
      log('Error getting route: $e');
      throw Exception('Failed to get route');
    }
  }

  Future<void> _updateRoutes() async {
    if (riderPos == null) return;

    try {
      // Determine which route to show based on pickup status
      LatLng destination = isPickedUp ? receiverPos! : senderPos!;

      if (destination != null) {
        final routeData = await getDetailedOSRMRoute(riderPos!, destination);

        setState(() {
          currentActiveRoute = routeData['points'];

          // Update route information
          final duration = routeData['duration'];
          final distance = routeData['distance'];

          estimatedTime = _formatDuration(duration);
          estimatedDistance = _formatDistance(distance);
          routeInstructions = routeData['instructions'];

          // Update individual routes for reference
          if (isPickedUp) {
            routeToReceiver = routeData['points'];
          } else {
            routeToSender = routeData['points'];
          }
        });

        log("Active route updated: ${currentActiveRoute.length} points");
        log("Estimated time: $estimatedTime, distance: $estimatedDistance");
      }
    } catch (e) {
      log("Error updating routes: $e");
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes นาที';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours ชม. $remainingMinutes นาที';
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} ม.';
    } else {
      final km = (meters / 1000);
      return '${km.toStringAsFixed(1)} กม.';
    }
  }

  void _listenFirestore() {
    _fireSub?.cancel();
    _fireSub = _fs.streamSelf().listen((doc) {
      final data = doc.data();
      if (data == null) return;

      final gp = data['gps'];
      if (gp is GeoPoint) {
        final p = LatLng(gp.latitude, gp.longitude);
        _updateRider(p, centerCamera: !_firstCentered);
      }
      final addr = (data['address'] ?? '') as String? ?? '';
      if (addr.isNotEmpty) _addressLine = addr;
    });
  }

  Future<void> _initLocate() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (perm == LocationPermission.denied) return;

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      final p = LatLng(last.latitude, last.longitude);
      _onPositionChange(p, centerCamera: true);
    }

    try {
      final cur = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      final p = LatLng(cur.latitude, cur.longitude);
      _onPositionChange(p, centerCamera: true);
    } catch (_) {}

    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      if (!_followGps) return;
      _onPositionChange(LatLng(pos.latitude, pos.longitude));
    });
  }

  void _onPositionChange(LatLng p, {bool centerCamera = false}) {
    _updateRider(p, centerCamera: centerCamera);
    _throttleSaveToFirestore(p);
    _updateRoutes();
  }

  void _updateRider(LatLng latLng, {bool centerCamera = false}) {
    setState(() => riderPos = latLng);
    if (!_firstCentered || centerCamera) {
      _firstCentered = true;
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    }
  }

  void _throttleSaveToFirestore(LatLng p) {
    if (_pushThrottle?.isActive ?? false) return;

    _pushThrottle = Timer(const Duration(seconds: 2), () {});
    _fs.save(lat: p.latitude, lng: p.longitude);
    _rls.saveLocation(
        riderId: riderId!, latitude: p.latitude, longitude: p.longitude);
  }

  void _togglePickupStatus() {
    setState(() {
      isPickedUp = !isPickedUp;
      showingRouteToSender = !isPickedUp;
    });
    _updateRoutes();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _fireSub?.cancel();
    _pushThrottle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = riderPos ?? const LatLng(13.736717, 100.523186);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(
          isPickedUp ? 'กำลังส่งสินค้า' : 'กำลังรับสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: {
              if (riderPos != null)
                Marker(
                    markerId: MarkerId('rider'),
                    position: riderPos!,
                    infoWindow: InfoWindow(
                      title: '🏍️ ไรเดอร์',
                      snippet: 'ตำแหน่งปัจจุบัน',
                    ),
                    icon: riderIcon),
              if (senderPos != null)
                Marker(
                  markerId: MarkerId('sender'),
                  position: senderPos!,
                  infoWindow: InfoWindow(
                    title: isPickedUp ? '✅ รับสินค้าแล้ว' : '📦 จุดรับสินค้า',
                    snippet: shipmentData?.sender.name ?? 'ผู้ส่ง',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    isPickedUp
                        ? BitmapDescriptor.hueOrange
                        : BitmapDescriptor.hueGreen,
                  ),
                  alpha: isPickedUp ? 0.6 : 1.0,
                ),
              if (receiverPos != null)
                Marker(
                  markerId: MarkerId('receiver'),
                  position: receiverPos!,
                  infoWindow: InfoWindow(
                    title: isPickedUp ? '🎯 จุดส่งสินค้า' : '📍 จุดหมายปลายทาง',
                    snippet: shipmentData?.receiver.name ?? 'ผู้รับ',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    isPickedUp
                        ? BitmapDescriptor.hueRed
                        : BitmapDescriptor.hueViolet,
                  ),
                  alpha: isPickedUp ? 1.0 : 0.6,
                ),
            },
            polylines: {
              // Active route (highlighted)
              if (currentActiveRoute.isNotEmpty)
                Polyline(
                  polylineId: PolylineId('activeRoute'),
                  points: currentActiveRoute,
                  color: isPickedUp ? Colors.red : Colors.green,
                  width: 6,
                  patterns: [],
                ),
              // Inactive routes (dimmed)
              if (!isPickedUp && routeToReceiver.isNotEmpty)
                Polyline(
                  polylineId: PolylineId('routeToReceiver'),
                  points: routeToReceiver,
                  color: Colors.grey.withOpacity(0.4),
                  width: 3,
                  patterns: [PatternItem.dash(10), PatternItem.gap(5)],
                ),
              if (isPickedUp && routeToSender.isNotEmpty)
                Polyline(
                  polylineId: PolylineId('routeToSender'),
                  points: routeToSender,
                  color: Colors.grey.withOpacity(0.4),
                  width: 3,
                  patterns: [PatternItem.dash(10), PatternItem.gap(5)],
                ),
            },
          ),

          // Route Information Panel
          if (estimatedTime != null && estimatedDistance != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPickedUp
                              ? Icons.local_shipping
                              : Icons.directions_bike,
                          color: isPickedUp ? Colors.red : Colors.green,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isPickedUp
                              ? 'เส้นทางไปส่งสินค้า'
                              : 'เส้นทางไปรับสินค้า',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(estimatedTime!,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.straighten,
                                  size: 16, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(estimatedDistance!,
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (routeInstructions != null &&
                        routeInstructions!.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(
                        'คำแนะนำการเดินทาง:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        routeInstructions!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Control buttons
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle pickup status button
                  _roundBtn(
                    icon:
                        isPickedUp ? Icons.local_shipping : Icons.shopping_bag,
                    color: isPickedUp ? Colors.red : Colors.green,
                    onTap: _togglePickupStatus,
                  ),
                  SizedBox(height: 12),
                  // My location button
                  _roundBtn(
                    icon: Icons.my_location,
                    color: Colors.blue,
                    onTap: () async {
                      try {
                        final p = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.bestForNavigation,
                        );
                        final here = LatLng(p.latitude, p.longitude);
                        _followGps = true;
                        _onPositionChange(here, centerCamera: true);
                      } catch (e) {
                        debugPrint('my_location error: $e');
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  // Fit all markers button
                  _roundBtn(
                    icon: Icons.zoom_out_map,
                    color: const Color.fromARGB(255, 136, 136, 136),
                    onTap: () {
                      if (_mapController != null &&
                          riderPos != null &&
                          senderPos != null &&
                          receiverPos != null) {
                        _fitAllMarkers();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitAllMarkers() {
    if (_mapController == null) return;

    List<LatLng> positions = [];
    if (riderPos != null) positions.add(riderPos!);
    if (senderPos != null) positions.add(senderPos!);
    if (receiverPos != null) positions.add(receiverPos!);

    if (positions.isEmpty) return;

    double minLat =
        positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 8,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
