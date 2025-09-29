import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreLocationService {
  FirestoreLocationService(this.riderId);
  final int riderId;

  // Get the Firestore document reference
  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('riders').doc(riderId.toString());

  // Save the rider's GPS location and update timestamp
  Future<void> save({
    required double lat,
    required double lng,
  }) async {
    await _doc.set({
      'gps': GeoPoint(lat, lng),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Stream real-time updates of the rider's location
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamSelf() => _doc.snapshots();

  // Method to read data once from Firestore (no stream)
  Future<Map<String, dynamic>?> get() async {
    try {
      final snapshot = await _doc.get();
      if (snapshot.exists) {
        return snapshot.data();  // Return the data if document exists
      } else {
        return null;  // Return null if document does not exist
      }
    } catch (e) {
      print('Error reading data: $e');
      return null;  // Return null in case of error
    }
  }
}
