// To parse this JSON data, do
//
//     final resgetShipmentRiderListByRyder = resgetShipmentRiderListByRyderFromJson(jsonString);

import 'dart:convert';

ResgetShipmentRiderListByRyder resgetShipmentRiderListByRyderFromJson(
        String str) =>
    ResgetShipmentRiderListByRyder.fromJson(json.decode(str));

String resgetShipmentRiderListByRyderToJson(
        ResgetShipmentRiderListByRyder data) =>
    json.encode(data.toJson());

class ResgetShipmentRiderListByRyder {
  bool success;
  List<Shipment> shipments;

  ResgetShipmentRiderListByRyder({
    required this.success,
    required this.shipments,
  });

  factory ResgetShipmentRiderListByRyder.fromJson(Map<String, dynamic> json) =>
      ResgetShipmentRiderListByRyder(
        success: json["success"],
        shipments: List<Shipment>.from(
            json["shipments"].map((x) => Shipment.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "shipments": List<dynamic>.from(shipments.map((x) => x.toJson())),
      };
}

class Shipment {
  int shipmentId;
  String itemName;
  String itemDescription;
  String status;
  DateTime createdAt;
  DateTime updatedAt;
  Rider rider;
  Sender sender;
  Receiver receiver;

  Shipment({
    required this.shipmentId,
    required this.itemName,
    required this.itemDescription,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.rider,
    required this.sender,
    required this.receiver,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        shipmentId: json["shipment_id"],
        itemName: json["item_name"],
        itemDescription: json["item_description"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        rider: Rider.fromJson(json["rider"]),
        sender: Sender.fromJson(json["sender"]),
        receiver: Receiver.fromJson(json["receiver"]),
      );

  Map<String, dynamic> toJson() => {
        "shipment_id": shipmentId,
        "item_name": itemName,
        "item_description": itemDescription,
        "status": status,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "rider": rider.toJson(),
        "sender": sender.toJson(),
        "receiver": receiver.toJson(),
      };
}

class Receiver {
  String receiverName;
  String receiverPhone;
  String receiverAvatar;
  ReceiverAddress receiverAddress;

  Receiver({
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAvatar,
    required this.receiverAddress,
  });

  factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        receiverName: json["receiver_name"],
        receiverPhone: json["receiver_phone"],
        receiverAvatar: json["receiver_avatar"],
        receiverAddress: ReceiverAddress.fromJson(json["receiver_address"]),
      );

  Map<String, dynamic> toJson() => {
        "receiver_name": receiverName,
        "receiver_phone": receiverPhone,
        "receiver_avatar": receiverAvatar,
        "receiver_address": receiverAddress.toJson(),
      };
}

class ReceiverAddress {
  int recvAddressId;
  String recvAddressText;

  ReceiverAddress({
    required this.recvAddressId,
    required this.recvAddressText,
  });

  factory ReceiverAddress.fromJson(Map<String, dynamic> json) =>
      ReceiverAddress(
        recvAddressId: json["recv_address_id"],
        recvAddressText: json["recv_address_text"],
      );

  Map<String, dynamic> toJson() => {
        "recv_address_id": recvAddressId,
        "recv_address_text": recvAddressText,
      };
}

class Rider {
  String riderName;
  String riderPhone;
  String riderLicensePlate;

  Rider({
    required this.riderName,
    required this.riderPhone,
    required this.riderLicensePlate,
  });

  factory Rider.fromJson(Map<String, dynamic> json) => Rider(
        riderName: json["rider_name"],
        riderPhone: json["rider_phone"],
        riderLicensePlate: json["rider_license_plate"],
      );

  Map<String, dynamic> toJson() => {
        "rider_name": riderName,
        "rider_phone": riderPhone,
        "rider_license_plate": riderLicensePlate,
      };
}

class Sender {
  String senderName;
  String senderPhone;
  String senderAvatar;
  SenderAddress senderAddress;

  Sender({
    required this.senderName,
    required this.senderPhone,
    required this.senderAvatar,
    required this.senderAddress,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        senderName: json["sender_name"],
        senderPhone: json["sender_phone"],
        senderAvatar: json["sender_avatar"],
        senderAddress: SenderAddress.fromJson(json["sender_address"]),
      );

  Map<String, dynamic> toJson() => {
        "sender_name": senderName,
        "sender_phone": senderPhone,
        "sender_avatar": senderAvatar,
        "sender_address": senderAddress.toJson(),
      };
}

class SenderAddress {
  int sendAddressId;
  String sendAddressText;

  SenderAddress({
    required this.sendAddressId,
    required this.sendAddressText,
  });

  factory SenderAddress.fromJson(Map<String, dynamic> json) => SenderAddress(
        sendAddressId: json["send_address_id"],
        sendAddressText: json["send_address_text"],
      );

  /// Converts [SenderAddress] to a JSON encodable map.
  ///
  /// Returns a [Map] containing the following keys:
  ///
  /// - `send_address_id`: The [int] id of the sender's address.
  /// - `send_address_text`: The [String] text of the sender's address.

  Map<String, dynamic> toJson() => {
        "send_address_id": sendAddressId,
        "send_address_text": sendAddressText,
      };
}
