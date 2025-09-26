// To parse this JSON data, do
//
//     final reqUserAddAddress = reqUserAddAddressFromJson(jsonString);

import 'dart:convert';

ReqUserAddAddress reqUserAddAddressFromJson(String str) => ReqUserAddAddress.fromJson(json.decode(str));

String reqUserAddAddressToJson(ReqUserAddAddress data) => json.encode(data.toJson());

class ReqUserAddAddress {
    String nameAddress;
    String addressText;
    double gpsLat;
    double gpsLng;
    bool isDefault;

    ReqUserAddAddress({
        required this.nameAddress,
        required this.addressText,
        required this.gpsLat,
        required this.gpsLng,
        required this.isDefault,
    });

    factory ReqUserAddAddress.fromJson(Map<String, dynamic> json) => ReqUserAddAddress(
        nameAddress: json["name_address"],
        addressText: json["address_text"],
        gpsLat: json["gps_lat"]?.toDouble(),
        gpsLng: json["gps_lng"]?.toDouble(),
        isDefault: json["is_default"],
    );

    Map<String, dynamic> toJson() => {
        "name_address": nameAddress,
        "address_text": addressText,
        "gps_lat": gpsLat,
        "gps_lng": gpsLng,
        "is_default": isDefault,
    };
}
