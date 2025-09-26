// lib/models/req/item_input.dart
import 'dart:convert';

class ItemInput {
  final int receiverId;
  final int deliveryAddressId;
  final String itemName;
  final String itemDescription;
  /// ส่งเป็น data URL: "data:image/png;base64,...." (optional)
  final String? photoBase64;

  const ItemInput({
    required this.receiverId,
    required this.deliveryAddressId,
    required this.itemName,
    required this.itemDescription,
    this.photoBase64,
  });

  ItemInput copyWith({
    int? receiverId,
    int? deliveryAddressId,
    String? itemName,
    String? itemDescription,
    String? photoBase64, // ใส่ null ได้เพื่อเคลียร์ค่า
  }) {
    return ItemInput(
      receiverId: receiverId ?? this.receiverId,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  factory ItemInput.fromJson(Map<String, dynamic> json) => ItemInput(
        receiverId: json['receiver_id'] as int,
        deliveryAddressId: json['delivery_address_id'] as int,
        itemName: json['item_name'] as String,
        itemDescription: json['item_description'] as String,
        photoBase64: json['photo_base64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'receiver_id': receiverId,
        'delivery_address_id': deliveryAddressId,
        'item_name': itemName,
        'item_description': itemDescription,
        if (photoBase64 != null && photoBase64!.isNotEmpty)
          'photo_base64': photoBase64,
      };

  /// เผื่อกรณีต้องการ encode/decode string เอง
  static ItemInput fromJsonString(String str) =>
      ItemInput.fromJson(json.decode(str) as Map<String, dynamic>);
  String toJsonString() => json.encode(toJson());
}
