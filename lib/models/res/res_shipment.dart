// lib/models/shipment_item.dart
import 'package:flutter/material.dart';

class ShipmentItem {
  final int shipmentId;
  final String itemName;

  /// รูปพัสดุ (อาจเป็น null)
  final String? photoUrl;

  /// รูปโปรไฟล์ผู้รับ (อาจเป็น null) — ใช้เป็น fallback ถ้าไม่มีรูปพัสดุ
  final String? recvAvatar;

  final String status; // '1'..'4'
  final String statusText; // ข้อความสถานะ (ไทย)
  final Color statusColor; // สีแสดงสถานะ
  final String detailText; // ข้อความรายละเอียดที่ใช้แสดงในการ์ด

  ShipmentItem({
    required this.shipmentId,
    required this.itemName,
    required this.photoUrl,
    required this.recvAvatar,
    required this.status,
    required this.statusText,
    required this.statusColor,
    required this.detailText,
  });

  /// ใช้เป็น URL รูปสำหรับแสดงผล:
  /// - มีรูปพัสดุ (photo_url) ใช้อันนั้น
  /// - ถ้าไม่มี ใช้รูปโปรไฟล์ผู้รับ (recv_avatar)
  String? get thumbUrl => (photoUrl != null && photoUrl!.isNotEmpty)
      ? photoUrl
      : (recvAvatar != null && recvAvatar!.isNotEmpty ? recvAvatar : null);

  factory ShipmentItem.fromJson(
    Map<String, dynamic> j, {
    required bool isSenderView,
  }) {
    // map สถานะ → ข้อความเริ่มต้น + สี
    final s = (j['status'] ?? '').toString();
    final (fallbackText, color) = switch (s) {
      '1' => ('รอไรเดอร์', const Color(0xFF1976D2)), // ฟ้าเข้ม
      '2' => ('ไรเดอร์รับงาน', const Color(0xFF0288D1)),
      '3' => ('กำลังจัดส่ง', const Color(0xFF7B1FA2)), // ม่วง
      '4' => ('ส่งแล้ว', const Color(0xFF2E7D32)), // เขียว
      _ => ('ไม่ทราบสถานะ', const Color(0xFF757575)),
    };

    final statusText = (j['status_text'] ?? fallbackText).toString();

    // detail:
    // - มุมมองผู้ส่ง: แสดงข้อมูลผู้รับ
    // - มุมมองผู้รับ: แสดงข้อมูลผู้ส่ง/ที่รับของ (หรือชื่อไรเดอร์ถ้ามี)
    String who;
    String addr;
    double? lat;
    double? lng;

    if (isSenderView) {
      who = (j['recv_name'] ?? '—').toString();
      addr = (j['recv_address_text'] ?? '—').toString();
      lat = _toDouble(j['recv_gps_lat']);
      lng = _toDouble(j['recv_gps_lng']);
    } else {
      who = (j['rider_name'] != null && j['rider_name'].toString().isNotEmpty)
          ? 'ไรเดอร์: ${j['rider_name']}'
          : (j['send_addr_label'] ?? 'ผู้ส่ง').toString();
      addr = (j['send_address_text'] ?? '—').toString();
      lat = _toDouble(j['send_gps_lat']);
      lng = _toDouble(j['send_gps_lng']);
    }

    final coord = (lat != null && lng != null)
        ? '\nพิกัด: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
        : '';
    final detail =
        (isSenderView ? 'ผู้รับ: ' : 'ที่อยู่: ') + who + '\n' + addr + coord;

    return ShipmentItem(
      shipmentId: (j['shipment_id'] as num).toInt(),
      itemName: (j['item_name'] ?? '—').toString(),
      photoUrl: (j['photo_url'] as String?)?.trim(),
      recvAvatar: (j['recv_avatar'] as String?)?.trim(),
      status: s,
      statusText: statusText,
      statusColor: color,
      detailText: detail,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) return double.tryParse(v);
    return null;
  }
}
