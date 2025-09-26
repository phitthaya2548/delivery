// To parse this JSON data, do
//
//     final resgetShipmentRiderById = resgetShipmentRiderByIdFromJson(jsonString);

import 'dart:convert';

ResgetShipmentRiderById resgetShipmentRiderByIdFromJson(String str) => ResgetShipmentRiderById.fromJson(json.decode(str));

String resgetShipmentRiderByIdToJson(ResgetShipmentRiderById data) => json.encode(data.toJson());

class ResgetShipmentRiderById {
    bool success;
    Item item;

    ResgetShipmentRiderById({
        required this.success,
        required this.item,
    });

    factory ResgetShipmentRiderById.fromJson(Map<String, dynamic> json) => ResgetShipmentRiderById(
        success: json["success"],
        item: Item.fromJson(json["item"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "item": item.toJson(),
    };
}

class Item {
    int shipmentId;
    String status;
    String itemName;
    String itemDescription;
    DateTime createdAt;
    DateTime updatedAt;
    LastPhoto lastPhoto;
    Receiver sender;
    Receiver receiver;

    Item({
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

    factory Item.fromJson(Map<String, dynamic> json) => Item(
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
    String avatar;
    Address address;

    Receiver({
        required this.userId,
        required this.name,
        required this.phone,
        required this.avatar,
        required this.address,
    });

    factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        userId: json["user_id"],
        name: json["name"],
        phone: json["phone"],
        avatar: json["avatar"],
        address: Address.fromJson(json["address"]),
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "name": name,
        "phone": phone,
        "avatar": avatar,
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
