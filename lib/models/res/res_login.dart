// To parse this JSON data, do
//
//     final reslogin = resloginFromJson(jsonString);

import 'dart:convert';

Reslogin resloginFromJson(String str) => Reslogin.fromJson(json.decode(str));

String resloginToJson(Reslogin data) => json.encode(data.toJson());

class Reslogin {
  bool success;
  String role;
  Profile profile;

  Reslogin({
    required this.success,
    required this.role,
    required this.profile,
  });

  factory Reslogin.fromJson(Map<String, dynamic> json) => Reslogin(
        success: json["success"],
        role: json["role"],
        profile: Profile.fromJson(json["profile"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "role": role,
        "profile": profile.toJson(),
      };
}

class Profile {
  int id;
  String phoneNumber;
  String name;
  String profileImage;

  Profile({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.profileImage,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json["id"],
        phoneNumber: json["phone_number"],
        name: json["name"],
        profileImage: json["profile_image"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "phone_number": phoneNumber,
        "name": name,
        "profile_image": profileImage,
      };
}
