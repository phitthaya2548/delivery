// To parse this JSON data, do
//
//     final resuserSearch = resuserSearchFromJson(jsonString);

import 'dart:convert';

ResuserSearch resuserSearchFromJson(String str) =>
    ResuserSearch.fromJson(json.decode(str));

String resuserSearchToJson(ResuserSearch data) =>
    json.encode(data.toJson());

class ResuserSearch {
  bool success;
  Receiver sender;
  Receiver receiver;

  ResuserSearch({
    required this.success,
    required this.sender,
    required this.receiver,
  });

  factory ResuserSearch.fromJson(Map<String, dynamic> json) => ResuserSearch(
        success: json["success"] ?? false,
        sender: Receiver.fromJson(json["sender"] ?? {}),
        receiver: Receiver.fromJson(json["receiver"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "sender": sender.toJson(),
        "receiver": receiver.toJson(),
      };
}

class Receiver {
  int userId;
  String phoneNumber;
  String name;
  String profileImage;
  Address address;

  Receiver({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    required this.profileImage,
    required this.address,
  });

  factory Receiver.fromJson(Map<String, dynamic> json) => Receiver(
        userId: json["user_id"] ?? 0,
        phoneNumber: json["phone_number"] ?? "",
        name: json["name"] ?? "",
        profileImage: json["profile_image"] ?? "",
        address: Address.fromJson(json["address"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "phone_number": phoneNumber,
        "name": name,
        "profile_image": profileImage,
        "address": address.toJson(),
      };
}

class Address {
  int addressId;
  String nameAddress;
  String addressText;
  String gpsLat;
  String gpsLng;
  int isDefault;

  Address({
    required this.addressId,
    required this.nameAddress,
    required this.addressText,
    required this.gpsLat,
    required this.gpsLng,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["address_id"] ?? 0,
        nameAddress: json["name_address"] ?? "",
        addressText: json["address_text"] ?? "",
        gpsLat: json["gps_lat"]?.toString() ?? "",
        gpsLng: json["gps_lng"]?.toString() ?? "",
        isDefault: json["is_default"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "address_id": addressId,
        "name_address": nameAddress,
        "address_text": addressText,
        "gps_lat": gpsLat,
        "gps_lng": gpsLng,
        "is_default": isDefault,
      };
}
