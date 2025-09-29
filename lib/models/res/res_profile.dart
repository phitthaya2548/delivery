// To parse this JSON data, do
//
//     final resProfile = resProfileFromJson(jsonString);

import 'dart:convert';

ResProfile resProfileFromJson(String str) => ResProfile.fromJson(json.decode(str));

String resProfileToJson(ResProfile data) => json.encode(data.toJson());

class ResProfile {
    bool success;
    User user;
    List<Address> addresses;
    Address defaultAddress;

    ResProfile({
        required this.success,
        required this.user,
        required this.addresses,
        required this.defaultAddress,
    });

    factory ResProfile.fromJson(Map<String, dynamic> json) => ResProfile(
        success: json["success"],
        user: User.fromJson(json["user"]),
        addresses: List<Address>.from(json["addresses"].map((x) => Address.fromJson(x))),
        defaultAddress: Address.fromJson(json["defaultAddress"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "user": user.toJson(),
        "addresses": List<dynamic>.from(addresses.map((x) => x.toJson())),
        "defaultAddress": defaultAddress.toJson(),
    };
}

class Address {
    int addressId;
    int userId;
    String nameAddress;
    String addressText;
    String gpsLat;
    String gpsLng;
    int isDefault;

    Address({
        required this.addressId,
        required this.userId,
        required this.nameAddress,
        required this.addressText,
        required this.gpsLat,
        required this.gpsLng,
        required this.isDefault,
    });

    factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["address_id"],
        userId: json["user_id"],
        nameAddress: json["name_address"],
        addressText: json["address_text"],
        gpsLat: json["gps_lat"],
        gpsLng: json["gps_lng"],
        isDefault: json["is_default"],
    );

    Map<String, dynamic> toJson() => {
        "address_id": addressId,
        "user_id": userId,
        "name_address": nameAddress,
        "address_text": addressText,
        "gps_lat": gpsLat,
        "gps_lng": gpsLng,
        "is_default": isDefault,
    };
}

class User {
    int userId;
    String phoneNumber;
    String name;
    String profileImage;

    User({
        required this.userId,
        required this.phoneNumber,
        required this.name,
        required this.profileImage,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json["user_id"],
        phoneNumber: json["phone_number"],
        name: json["name"],
        profileImage: json["profile_image"],
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "phone_number": phoneNumber,
        "name": name,
        "profile_image": profileImage,
    };
}
