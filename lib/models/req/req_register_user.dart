import 'dart:convert';

ReqRegister reqRegisterFromJson(String str) => ReqRegister.fromJson(json.decode(str));
String reqRegisterToJson(ReqRegister data) => json.encode(data.toJson());

class ReqRegister {
  String phoneNumber;
  String password;
  String name;
  String? profileImage;

  ReqRegister({
    required this.phoneNumber,
    required this.password,
    required this.name,
    this.profileImage,
  });

  factory ReqRegister.fromJson(Map<String, dynamic> json) => ReqRegister(
        phoneNumber: json["phone_number"],
        password: json["password"],
        name: json["name"],
        profileImage: json["profile_image"],
      );

  Map<String, dynamic> toJson() => {
        "phone_number": phoneNumber,
        "password": password,
        "name": name,
        "profile_image": profileImage,
      };
}
