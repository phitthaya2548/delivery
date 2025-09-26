// To parse this JSON data, do
//
//     final resRiderProfile = resRiderProfileFromJson(jsonString);

import 'dart:convert';

ResRiderProfile resRiderProfileFromJson(String str) => ResRiderProfile.fromJson(json.decode(str));

String resRiderProfileToJson(ResRiderProfile data) => json.encode(data.toJson());

class ResRiderProfile {
    bool success;
    Rider rider;

    ResRiderProfile({
        required this.success,
        required this.rider,
    });

    factory ResRiderProfile.fromJson(Map<String, dynamic> json) => ResRiderProfile(
        success: json["success"],
        rider: Rider.fromJson(json["rider"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "rider": rider.toJson(),
    };
}

class Rider {
    int riderId;
    String phoneNumber;
    String name;
    String licensePlate;
    String profileImage;
    String vehicleImage;

    Rider({
        required this.riderId,
        required this.phoneNumber,
        required this.name,
        required this.licensePlate,
        required this.profileImage,
        required this.vehicleImage,
    });

    factory Rider.fromJson(Map<String, dynamic> json) => Rider(
        riderId: json["rider_id"],
        phoneNumber: json["phone_number"],
        name: json["name"],
        licensePlate: json["license_plate"],
        profileImage: json["profile_image"],
        vehicleImage: json["vehicle_image"],
    );

    Map<String, dynamic> toJson() => {
        "rider_id": riderId,
        "phone_number": phoneNumber,
        "name": name,
        "license_plate": licensePlate,
        "profile_image": profileImage,
        "vehicle_image": vehicleImage,
    };
}
