// To parse this JSON data, do
//
//     final resgetShipmentRider = resgetShipmentRiderFromJson(jsonString);

import 'dart:convert';

ResgetShipmentRider resgetShipmentRiderFromJson(String str) => ResgetShipmentRider.fromJson(json.decode(str));

String resgetShipmentRiderToJson(ResgetShipmentRider data) => json.encode(data.toJson());

class ResgetShipmentRider {
    bool success;
    List<Shipment> shipments;

    ResgetShipmentRider({
        required this.success,
        required this.shipments,
    });

    factory ResgetShipmentRider.fromJson(Map<String, dynamic> json) => ResgetShipmentRider(
        success: json["success"],
        shipments: List<Shipment>.from(json["shipments"].map((x) => Shipment.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "shipments": List<dynamic>.from(shipments.map((x) => x.toJson())),
    };
}

class Shipment {
    int shipmentId;
    String status;
    String itemName;
    String itemDescription;
    DateTime createdAt;
    DateTime updatedAt;
    LastPhoto lastPhoto;
    Receiver sender;
    Receiver receiver;

    Shipment({
        required this.shipmentId,
        required this.status,
        required this.itemName,
        required this.itemDescription,
        required this.createdAt,
        required this.updatedAt,
        required this.lastPhoto,
        required this.sender,
        required this.receiver,
    });

    factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        shipmentId: json["shipment_id"],
        status: json["status"],
        itemName: json["item_name"],
        itemDescription: json["item_description"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        lastPhoto: LastPhoto.fromJson(json["last_photo"]),
        sender: Receiver.fromJson(json["sender"]),
        receiver: Receiver.fromJson(json["receiver"]),
    );

    Map<String, dynamic> toJson() => {
        "shipment_id": shipmentId,
        "status": status,
        "item_name": itemName,
        "item_description": itemDescription,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "last_photo": lastPhoto.toJson(),
        "sender": sender.toJson(),
        "receiver": receiver.toJson(),
    };
}

class LastPhoto {
    String url;
    String status;
    DateTime uploadedAt;

    LastPhoto({
        required this.url,
        required this.status,
        required this.uploadedAt,
    });

    factory LastPhoto.fromJson(Map<String, dynamic> json) => LastPhoto(
        url: json["url"],
        status: json["status"],
        uploadedAt: DateTime.parse(json["uploaded_at"]),
    );

    Map<String, dynamic> toJson() => {
        "url": url,
        "status": status,
        "uploaded_at": uploadedAt.toIso8601String(),
    };
}

class Receiver {
    int userId;
    String name;
    String phone;
    Address address;

    Receiver({
        required this.userId,
        required this.name,
        required this.phone,
        required this.address,
    });

    factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        userId: json["user_id"],
        name: json["name"],
        phone: json["phone"],
        address: Address.fromJson(json["address"]),
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "name": name,
        "phone": phone,
        "address": address.toJson(),
    };
}

class Address {
    int addressId;
    String label;
    String addressText;
    String lat;
    String lng;

    Address({
        required this.addressId,
        required this.label,
        required this.addressText,
        required this.lat,
        required this.lng,
    });

    factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["address_id"],
        label: json["label"],
        addressText: json["address_text"],
        lat: json["lat"],
        lng: json["lng"],
    );

    Map<String, dynamic> toJson() => {
        "address_id": addressId,
        "label": label,
        "address_text": addressText,
        "lat": lat,
        "lng": lng,
    };
}
