import 'dart:convert';

ReqRegisterRider reqRegisterRiderFromJson(String str) =>
    ReqRegisterRider.fromJson(json.decode(str));

String reqRegisterRiderToJson(ReqRegisterRider data) =>
    json.encode(data.toJson());

class ReqRegisterRider {
  String phoneNumber;
  String password;
  String name;
  String licensePlate;
  String? profileImage;
  String? vehicleImage;

  ReqRegisterRider({
    required this.phoneNumber,
    required this.password,
    required this.name,
    required this.licensePlate,
    this.profileImage,
    this.vehicleImage,
  });

  factory ReqRegisterRider.fromJson(Map<String, dynamic> json) =>
      ReqRegisterRider(
        phoneNumber: json["phone_number"],
        password: json["password"],
        name: json["name"],
        licensePlate: json["license_plate"],
        profileImage: json["profile_image"],
        vehicleImage: json["vehicle_image"],
      );

  Map<String, dynamic> toJson() => {
        "phone_number": phoneNumber,
        "password": password,
        "name": name,
        "license_plate": licensePlate,
        "profile_image": profileImage,
        "vehicle_image": vehicleImage,
      };
}
