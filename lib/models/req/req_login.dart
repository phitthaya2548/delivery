// To parse this JSON data, do
//
//     final reqlogin = reqloginFromJson(jsonString);

import 'dart:convert';

Reqlogin reqloginFromJson(String str) => Reqlogin.fromJson(json.decode(str));

String reqloginToJson(Reqlogin data) => json.encode(data.toJson());

class Reqlogin {
    String phoneNumber;
    String password;

    Reqlogin({
        required this.phoneNumber,
        required this.password,
    });

    factory Reqlogin.fromJson(Map<String, dynamic> json) => Reqlogin(
        phoneNumber: json["phone_number"],
        password: json["password"],
    );

    Map<String, dynamic> toJson() => {
        "phone_number": phoneNumber,
        "password": password,
    };
}
