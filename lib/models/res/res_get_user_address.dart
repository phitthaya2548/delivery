// res_user_address.dart
import 'dart:convert';

ResUserAddress resUserAddressFromJson(String str) =>
    ResUserAddress.fromJson(json.decode(str));

String resUserAddressToJson(ResUserAddress data) => json.encode(data.toJson());

class ResUserAddress {
  final bool success;
  final List<Address> addresses;

  ResUserAddress({
    required this.success,
    required this.addresses,
  });

  factory ResUserAddress.fromJson(Map<String, dynamic> json) => ResUserAddress(
        success: json["success"] == true,
        addresses: (json["addresses"] as List)
            .map((x) => Address.fromJson(x))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "addresses": addresses.map((x) => x.toJson()).toList(),
      };
}

class Address {
  final int addressId;
  final int userId;
  final String nameAddress;
  final String addressText;
  final double? gpsLat;
  final double? gpsLng;
  final bool isDefault;

  Address({
    required this.addressId,
    required this.userId,
    required this.nameAddress,
    required this.addressText,
    this.gpsLat,
    this.gpsLng,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["address_id"] as int,
        userId: json["user_id"] as int,
        nameAddress: (json["name_address"] ?? "บ้าน").toString(),
        addressText: json["address_text"].toString(),
        gpsLat: _toDoubleOrNull(json["gps_lat"]),
        gpsLng: _toDoubleOrNull(json["gps_lng"]),
        // MySQL tinyint(1) -> 0/1 หรืออาจเป็น bool อยู่แล้ว
        isDefault: json["is_default"] == true ||
            json["is_default"] == 1 ||
            json["is_default"] == "1",
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

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) return double.tryParse(v);
    return null;
  }
}
