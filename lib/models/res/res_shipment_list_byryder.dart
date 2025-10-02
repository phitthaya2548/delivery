// To parse this JSON data, do
//
//   final res = resgetShipmentRiderListByRyderFromJson(jsonString);

import 'dart:convert';

ResgetShipmentRiderListByRyder resgetShipmentRiderListByRyderFromJson(
        String str) =>
    ResgetShipmentRiderListByRyder.fromJson(
        json.decode(str) as Map<String, dynamic>);

String resgetShipmentRiderListByRyderToJson(
        ResgetShipmentRiderListByRyder data) =>
    json.encode(data.toJson());

/// ---------- helpers ปลอดภัย ----------
int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

String _asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime _asDate(dynamic v, [DateTime? fallback]) {
  if (v == null || v.toString().trim().isEmpty)
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

Map<String, dynamic> _asMap(dynamic v) =>
    (v is Map<String, dynamic>) ? v : <String, dynamic>{};

List<T> _asList<T>(dynamic v, T Function(dynamic) mapFn) {
  if (v is List) {
    final out = <T>[];
    for (final e in v) {
      try {
        out.add(mapFn(e));
      } catch (_) {
        // ข้าม element ที่เพี้ยน
      }
    }
    return out;
  }
  return <T>[];
}

/// ---------- root ----------
class ResgetShipmentRiderListByRyder {
  final bool success;
  final List<Shipment> shipments;
  final String? message; // เผื่อแบ็กเอนด์ส่งข้อความ

  ResgetShipmentRiderListByRyder({
    required this.success,
    required this.shipments,
    this.message,
  });

  factory ResgetShipmentRiderListByRyder.fromJson(Map<String, dynamic> json) {
    // บาง API อาจส่ง data แทน shipments → ลองแม็พให้
    dynamic rawShipments = json['shipments'];
    if (rawShipments == null && json['data'] != null) {
      rawShipments = json['data'];
    }

    final shipments = _asList<Shipment>(rawShipments, (e) {
      return Shipment.fromJson(_asMap(e));
    });

    return ResgetShipmentRiderListByRyder(
      success: json['success'] == true ||
          _asString(json['success']).toLowerCase() == 'true',
      shipments: shipments,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'shipments': shipments.map((x) => x.toJson()).toList(),
        if (message != null) 'message': message,
      };
}

/// ---------- shipment ----------
class Shipment {
  final int shipmentId;
  final String itemPhotoUrl;
  final String itemName;
  final String itemDescription;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Rider rider;
  final Sender sender;
  final Receiver receiver;

  Shipment({
    required this.shipmentId,
    required this.itemPhotoUrl,
    required this.itemName,
    required this.itemDescription,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.rider,
    required this.sender,
    required this.receiver,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      shipmentId: _asInt(json['shipment_id']),
      itemPhotoUrl: _asString(json['item_photo_url']),
      itemName: _asString(json['item_name']),
      itemDescription: _asString(json['item_description']),
      status: _asString(json['status']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      rider: Rider.fromJson(_asMap(json['rider'])),
      sender: Sender.fromJson(_asMap(json['sender'])),
      receiver: Receiver.fromJson(_asMap(json['receiver'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'shipment_id': shipmentId,
        'item_photo_url': itemPhotoUrl,
        'item_name': itemName,
        'item_description': itemDescription,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'rider': rider.toJson(),
        'sender': sender.toJson(),
        'receiver': receiver.toJson(),
      };
}

/// ---------- receiver ----------
class Receiver {
  final String receiverName;
  final String receiverPhone;
  final String receiverAvatar;
  final ReceiverAddress receiverAddress;

  Receiver({
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAvatar,
    required this.receiverAddress,
  });

  factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        receiverName: _asString(json['receiver_name']),
        receiverPhone: _asString(json['receiver_phone']),
        receiverAvatar: _asString(json['receiver_avatar']),
        receiverAddress:
            ReceiverAddress.fromJson(_asMap(json['receiver_address'])),
      );

  Map<String, dynamic> toJson() => {
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'receiver_avatar': receiverAvatar,
        'receiver_address': receiverAddress.toJson(),
      };
}

class ReceiverAddress {
  final int recvAddressId;
  final String recvAddressText;

  ReceiverAddress({
    required this.recvAddressId,
    required this.recvAddressText,
  });

  factory ReceiverAddress.fromJson(Map<String, dynamic> json) =>
      ReceiverAddress(
        recvAddressId: _asInt(json['recv_address_id']),
        recvAddressText: _asString(json['recv_address_text']),
      );

  Map<String, dynamic> toJson() => {
        'recv_address_id': recvAddressId,
        'recv_address_text': recvAddressText,
      };
}

/// ---------- rider ----------
class Rider {
  final String riderName;
  final String riderPhone;
  final String riderLicensePlate;
  final String riderAvatar;

  Rider({
    required this.riderName,
    required this.riderPhone,
    required this.riderLicensePlate,
    required this.riderAvatar,
  });

  factory Rider.fromJson(Map<String, dynamic> json) => Rider(
        riderName: _asString(json['rider_name']),
        riderPhone: _asString(json['rider_phone']),
        riderLicensePlate: _asString(json['rider_license_plate']),
        riderAvatar: _asString(json['rider_avatar']),
      );

  Map<String, dynamic> toJson() => {
        'rider_name': riderName,
        'rider_phone': riderPhone,
        'rider_license_plate': riderLicensePlate,
        'rider_avatar': riderAvatar,
      };
}

/// ---------- sender ----------
class Sender {
  final String senderName;
  final String senderPhone;
  final String senderAvatar;
  final SenderAddress senderAddress;

  Sender({
    required this.senderName,
    required this.senderPhone,
    required this.senderAvatar,
    required this.senderAddress,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        senderName: _asString(json['sender_name']),
        senderPhone: _asString(json['sender_phone']),
        senderAvatar: _asString(json['sender_avatar']),
        senderAddress: SenderAddress.fromJson(_asMap(json['sender_address'])),
      );

  Map<String, dynamic> toJson() => {
        'sender_name': senderName,
        'sender_phone': senderPhone,
        'sender_avatar': senderAvatar,
        'sender_address': senderAddress.toJson(),
      };
}

class SenderAddress {
  final int sendAddressId;
  final String sendAddressText;

  SenderAddress({
    required this.sendAddressId,
    required this.sendAddressText,
  });

  factory SenderAddress.fromJson(Map<String, dynamic> json) => SenderAddress(
        sendAddressId: _asInt(json['send_address_id']),
        sendAddressText: _asString(json['send_address_text']),
      );

  Map<String, dynamic> toJson() => {
        'send_address_id': sendAddressId,
        'send_address_text': sendAddressText,
      };
}
