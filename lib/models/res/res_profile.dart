// To parse this JSON data, do
//
//     final resProfile = resProfileFromJson(jsonString);

import 'dart:convert';

ResProfile resProfileFromJson(String str) => ResProfile.fromJson(json.decode(str));

String resProfileToJson(ResProfile data) => json.encode(data.toJson());

class ResProfile {
    bool success;
    User user;
    List<dynamic> addresses;
    dynamic defaultAddress;

    ResProfile({
        required this.success,
        required this.user,
        required this.addresses,
        required this.defaultAddress,
    });

    factory ResProfile.fromJson(Map<String, dynamic> json) => ResProfile(
        success: json["success"],
        user: User.fromJson(json["user"]),
        addresses: List<dynamic>.from(json["addresses"].map((x) => x)),
        defaultAddress: json["defaultAddress"],
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "user": user.toJson(),
        "addresses": List<dynamic>.from(addresses.map((x) => x)),
        "defaultAddress": defaultAddress,
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
