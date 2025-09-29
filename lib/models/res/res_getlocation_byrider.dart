// To parse this JSON data, do
//
//     final resgetShipmentRidergetLocation = resgetShipmentRidergetLocationFromJson(jsonString);

import 'dart:convert';

ResgetShipmentRidergetLocation resgetShipmentRidergetLocationFromJson(String str) => ResgetShipmentRidergetLocation.fromJson(json.decode(str));

String resgetShipmentRidergetLocationToJson(ResgetShipmentRidergetLocation data) => json.encode(data.toJson());

class ResgetShipmentRidergetLocation {
    bool success;
    int shipmentId;
    Receiver sender;
    Receiver receiver;

    ResgetShipmentRidergetLocation({
        required this.success,
        required this.shipmentId,
        required this.sender,
        required this.receiver,
    });

    factory ResgetShipmentRidergetLocation.fromJson(Map<String, dynamic> json) => ResgetShipmentRidergetLocation(
        success: json["success"],
        shipmentId: json["shipment_id"],
        sender: Receiver.fromJson(json["sender"]),
        receiver: Receiver.fromJson(json["receiver"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "shipment_id": shipmentId,
        "sender": sender.toJson(),
        "receiver": receiver.toJson(),
    };
}

class Receiver {
    String name;
    String phone;
    String profileImage;
    String lat;
    String lng;
    String addressName;
    String addressText;

    Receiver({
        required this.name,
        required this.phone,
        required this.profileImage,
        required this.lat,
        required this.lng,
        required this.addressName,
        required this.addressText,
    });

    factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        name: json["name"],
        phone: json["phone"],
        profileImage: json["profile_image"],
        lat: json["lat"],
        lng: json["lng"],
        addressName: json["address_name"],
        addressText: json["address_text"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "phone": phone,
        "profile_image": profileImage,
        "lat": lat,
        "lng": lng,
        "address_name": addressName,
        "address_text": addressText,
    };
}
