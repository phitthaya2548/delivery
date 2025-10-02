import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreLocationService {
  FirestoreLocationService(this.riderId);
  final int riderId;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('riders').doc(riderId.toString());

  Future<void> save({
    required double lat,
    required double lng,
  }) async {
    await _doc.set({
      'gps': GeoPoint(lat, lng),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamSelf() =>
      _doc.snapshots();

  Future<Map<String, dynamic>?> get() async {
    try {
      final snapshot = await _doc.get();
      if (snapshot.exists) {
        return snapshot.data();
      } else {
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error reading data: $e');
      return null;
    }
  }
}

class FirestoreDeliveryService {
  FirestoreDeliveryService(this.riderId);
  final String riderId;

  final _fs = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _riderDoc =>
      _fs.collection('riders').doc(riderId);

  DocumentReference<Map<String, dynamic>> _shipDoc(String shipmentId) =>
      _fs.collection('shipments').doc(shipmentId);

  /// 1) เปลี่ยนสถานะอย่างเดียว (1..4) + sync current ของไรเดอร์
  Future<void> advanceStatus({
    required String shipmentId,
    required int nextStatus, // 1..4
  }) async {
    assert(nextStatus >= 1 && nextStatus <= 4);

    final now = FieldValue.serverTimestamp();
    final batch = _fs.batch();

    // shipments/{sid}
    batch.set(
      _shipDoc(shipmentId),
      {
        'status': nextStatus,
        'riderId': riderId,
        'updated_at': now,
      },
      SetOptions(merge: true),
    );

    // riders/{rid}.current
    batch.set(
      _riderDoc,
      {
        'current': {
          'shipment_id': shipmentId,
          'status': nextStatus,
        },
        'updated_at': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> advanceStatusWithPhoto({
    required String shipmentId,
    required int nextStatus,
    required String photoUrl,
  }) async {
    assert(nextStatus >= 1 && nextStatus <= 4);
    assert(photoUrl.isNotEmpty);

    final now = FieldValue.serverTimestamp();
    final shipRef = _shipDoc(shipmentId);
    final batch = _fs.batch();
    batch.set(
      shipRef,
      {
        'status': nextStatus,
        'riderId': riderId,
        'item_photo_url': photoUrl,
        'updated_at': now,
      },
      SetOptions(merge: true),
    );
    batch.set(
      shipRef,
      {
        'photos': FieldValue.arrayUnion([
          {
            'url': photoUrl,
            'status': nextStatus,
            'uploaded_at': now,
            'riderId': riderId,
          }
        ]),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _riderDoc,
      {
        'current': {
          'shipment_id': shipmentId,
          'status': nextStatus,
        },
        'updated_at': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// 3) แนบรูปอย่างเดียว (ไม่เปลี่ยนสถานะ)
  Future<void> appendStatusPhotoOnly({
    required String shipmentId,
    required int status,      // สถานะที่รูปนี้อ้างถึง
    required String photoUrl, // absolute URL
  }) async {
    assert(status >= 1 && status <= 4);
    assert(photoUrl.isNotEmpty);

    final now = FieldValue.serverTimestamp();
    await _shipDoc(shipmentId).set({
      'item_photo_url': photoUrl, // อัปเดตรูปล่าสุด
      'photos': FieldValue.arrayUnion([
        {
          'url': photoUrl,
          'status': status,
          'uploaded_at': now,
          'riderId': riderId,
        }
      ]),
      'updated_at': now,
    }, SetOptions(merge: true));
  }

  /// 4) สตรีมสถานะจาก shipments/{sid}
  Stream<int?> streamShipmentStatus(String shipmentId) {
    return _shipDoc(shipmentId).snapshots().map((snap) {
      final m = snap.data();
      return (m?['status'] as num?)?.toInt();
    });
  }

  /// 5) สตรีมรวมสถานะ + รูปล่าสุด + ประวัติรูป
  Stream<({
    int? status,
    String? lastPhotoUrl,
    List<Map<String, dynamic>> photos
  })> streamShipment(String shipmentId) {
    return _shipDoc(shipmentId).snapshots().map((snap) {
      final m = snap.data() ?? {};
      final s = (m['status'] as num?)?.toInt();
      final last = (m['item_photo_url'] as String?)?.trim();
      final phs = ((m['photos'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      return (status: s, lastPhotoUrl: last, photos: phs);
    });
  }

  Stream<({String? shipmentId, int? status})> streamCurrentJob() {
    return _riderDoc.snapshots().map((snap) {
      final m = snap.data();
      final cur = (m?['current'] as Map?)?.cast<String, dynamic>();
      return (
        shipmentId: cur?['shipment_id'] as String?,
        status: (cur?['status'] as num?)?.toInt()
      );
    });
  }
}