// lib/models/shipment_item.dart
import 'package:flutter/material.dart';

class ShipmentItem {
  final int shipmentId;
  final String itemName;

  /// URL รูปพัสดุ (อาจเป็น null)
  final String? photoUrl;

  /// URL รูปโปรไฟล์ผู้รับ (อาจเป็น null) — ใช้เป็น fallback ถ้าไม่มีรูปพัสดุ
  final String? recvAvatar;

  /// สถานะเป็นเลข 1..4
  final int status;

  /// ข้อความรายละเอียดที่จะโชว์ในการ์ด
  final String detailText;

  ShipmentItem({
    required this.shipmentId,
    required this.itemName,
    required this.photoUrl,
    required this.recvAvatar,
    required this.status,
    required this.detailText,
  });

  /// รูปสำหรับแสดงผล: ถ้ามีรูปพัสดุใช้ก่อน, ไม่มีก็ค่อยใช้ avatar ผู้รับ
  String? get thumbUrl =>
      (photoUrl != null && photoUrl!.isNotEmpty)
          ? photoUrl
          : (recvAvatar != null && recvAvatar!.isNotEmpty ? recvAvatar : null);

  /// ข้อความสถานะ (คำนวณจาก status)
  String get statusText {
    switch (status) {
      case 1:
        return 'รอไรเดอร์มารับสินค้า';
      case 2:
        return 'ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)';
      case 3:
        return 'ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง';
      case 4:
        return 'ไรเดอร์นำส่งสินค้าแล้ว';
      default:
        return 'ไม่ทราบสถานะ ($status)';
    }
  }

  /// สีสถานะ (คำนวณจาก status)
  Color get statusColor {
    switch (status) {
      case 1:
        return const Color(0xFF1976D2); // ฟ้าเข้ม
      case 2:
        return const Color(0xFF0288D1);
      case 3:
        return const Color(0xFF7B1FA2); // ม่วง
      case 4:
        return const Color(0xFF2E7D32); // เขียว
      default:
        return const Color(0xFF757575);
    }
  }

  /// ใช้ map → ShipmentItem
  /// รองรับทั้งคีย์แบบ MySQL API เดิม และคีย์สำรองบางตัว
  factory ShipmentItem.fromJson(
    Map<String, dynamic> j, {
    required bool isSenderView,
  }) {
    // status อาจมาเป็น string '1'..'4' หรือ number
    final statusStr = (j['status'] ?? '1').toString();
    final statusInt = int.tryParse(statusStr) ?? 1;

    // รองรับคีย์รูปได้ทั้ง item_photo_url และ photo_url
    final photo = (j['item_photo_url'] ?? j['photo_url'])?.toString().trim();

    // avatar ผู้รับ: รองรับ receiver_avatar และ recv_avatar
    final recvAva = (j['receiver_avatar'] ?? j['recv_avatar'])?.toString().trim();

    // ชื่อไอเท็ม
    final name = (j['item_name'] ?? '—').toString();

    // สร้างข้อความ detail ตามมุมมอง
    String who;
    String addr;
    double? lat;
    double? lng;

    if (isSenderView) {
      // ฝั่งผู้ส่ง: โชว์ข้อมูลผู้รับ
      who = (j['receiver_name'] ?? j['recv_name'] ?? '—').toString();
      addr = (j['recv_address_text'] ?? j['receiver_address_text'] ?? '—').toString();
      lat = _toDouble(j['recv_gps_lat'] ?? j['receiver_lat']);
      lng = _toDouble(j['recv_gps_lng'] ?? j['receiver_lng']);
    } else {
      // ฝั่งผู้รับ: โชว์ข้อมูลผู้ส่ง/ที่รับของ หรือชื่อไรเดอร์ถ้ามี
      final riderName = (j['rider_name'] ?? '').toString();
      if (riderName.isNotEmpty) {
        who = 'ไรเดอร์: $riderName';
      } else {
        who = (j['sender_name'] ?? j['send_addr_label'] ?? 'ผู้ส่ง').toString();
      }
      addr = (j['send_address_text'] ?? j['sender_address_text'] ?? '—').toString();
      lat = _toDouble(j['send_gps_lat'] ?? j['sender_lat']);
      lng = _toDouble(j['send_gps_lng'] ?? j['sender_lng']);
    }

    final coord = (lat != null && lng != null)
        ? '\nพิกัด: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
        : '';
    final detail = (isSenderView ? 'ผู้รับ: ' : 'ที่อยู่: ') + who + '\n' + addr + coord;

    return ShipmentItem(
      shipmentId: (j['shipment_id'] as num).toInt(),
      itemName: name,
      photoUrl: (photo?.isNotEmpty == true) ? photo : null,
      recvAvatar: (recvAva?.isNotEmpty == true) ? recvAva : null,
      status: statusInt,
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
