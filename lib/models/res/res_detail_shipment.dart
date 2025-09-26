// lib/models/res/res_detail_shipment.dart
class ShipmentDetail {
  final int id;
  final String status; // '1'..'4'
  final String statusText;

  // rider
  final String? riderName;
  final String? riderPhone;
  final String? licensePlate;
  final String? riderAvatar;

  // sender / receiver
  final String? senderName;
  final String? senderPhone;
  final String sendAddress;
  final String? senderAvatar;

  final String? receiverName;
  final String? receiverPhone;
  final String recvAddress;
  final String? receiverAvatar;

  // media
  final String? photoUrl; // รูปพัสดุ (ถ้ามี)
  final String? mapImageUrl;

  ShipmentDetail({
    required this.id,
    required this.status,
    required this.statusText,
    this.riderName,
    this.riderPhone,
    this.licensePlate,
    this.riderAvatar,
    this.senderName,
    this.senderPhone,
    required this.sendAddress,
    this.senderAvatar,
    this.receiverName,
    this.receiverPhone,
    required this.recvAddress,
    this.receiverAvatar,
    this.photoUrl,
    this.mapImageUrl,
  });

  /// j อาจเป็นโครงสร้าง item (nested) หรือ flat field ก็ได้
  factory ShipmentDetail.fromItemJson(
    Map<String, dynamic> j, {
    required String baseUrl,
  }) {
    // อ่าน path ซ้อน ๆ แบบปลอดภัย
    String? pick(List<String> path) {
      dynamic cur = j;
      for (final k in path) {
        if (cur is Map && cur[k] != null) {
          cur = cur[k];
        } else {
          return null;
        }
      }
      return cur?.toString();
    }

    // ทำ path -> absolute URL (ถ้า backend เผลอส่งเป็น path)
    String? abs(String? u) {
      if (u == null || u.isEmpty) return null;
      final s = u.trim();
      if (s.startsWith('http://') || s.startsWith('https://')) return s;
      final b = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      return '$b${s.startsWith('/') ? '' : '/'}$s';
    }

    int parseId() {
      final v = j['shipment_id'] ?? j['id'];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final status = (j['status'] ?? '').toString();

    String statusText = (j['status_text'] ?? '').toString();
    if (statusText.isEmpty) {
      statusText = switch (status) {
        '1' => 'รอไรเดอร์',
        '2' => 'ไรเดอร์รับงาน',
        '3' => 'กำลังส่ง',
        '4' => 'ส่งแล้ว',
        _ => 'ไม่ทราบสถานะ',
      };
    }

    // รูปพัสดุ: รองรับทั้ง last_photo.url และ photo_url
    final photoUrl = abs(
      (pick(['last_photo', 'url'])) ?? (j['photo_url']?.toString()),
    );

    // sender (รองรับทั้ง nested/flat)
    final senderName = pick(['sender', 'name']) ?? j['send_name']?.toString();
    final senderPhone =
        pick(['sender', 'phone']) ?? j['send_phone']?.toString();
    final sendAddr = pick(['sender', 'address', 'address_text']) ??
        j['send_address_text']?.toString() ??
        '-';
    final senderAvatar =
        abs(pick(['sender', 'avatar']) ?? j['send_avatar']?.toString());

    // receiver
    final receiverName =
        pick(['receiver', 'name']) ?? j['recv_name']?.toString();
    final receiverPhone =
        pick(['receiver', 'phone']) ?? j['recv_phone']?.toString();
    final recvAddr = pick(['receiver', 'address', 'address_text']) ??
        j['recv_address_text']?.toString() ??
        '-';
    final receiverAvatar =
        abs(pick(['receiver', 'avatar']) ?? j['recv_avatar']?.toString());

    // rider (ถ้าสถานะยัง 1 ก็อาจว่าง)
    final riderName = j['rider_name']?.toString();
    final riderPhone = j['rider_phone']?.toString();
    final licensePlate = j['license_plate']?.toString();
    final riderAvatar = abs(j['rider_avatar']?.toString());

    return ShipmentDetail(
      id: parseId(),
      status: status,
      statusText: statusText,
      riderName: riderName,
      riderPhone: riderPhone,
      licensePlate: licensePlate,
      riderAvatar: riderAvatar,
      senderName: senderName,
      senderPhone: senderPhone,
      sendAddress: sendAddr,
      senderAvatar: senderAvatar,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      recvAddress: recvAddr,
      receiverAvatar: receiverAvatar,
      photoUrl: photoUrl,
      mapImageUrl: null,
    );
  }
}
