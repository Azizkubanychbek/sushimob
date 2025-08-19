import 'roll.dart';
import 'set.dart';

class CartItem {
  final int id;
  final String itemType; // 'roll' или 'set'
  final dynamic item; // Roll или Set
  final int quantity;
  final String addedAt;

  CartItem({
    required this.id,
    required this.itemType,
    required this.item,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    dynamic item;
    if (json['item_type'] == 'roll') {
      item = Roll.fromJson(json['item']);
    } else if (json['item_type'] == 'set') {
      item = Set.fromJson(json['item']);
    }

    return CartItem(
      id: json['id']?.toInt() ?? 0,
      itemType: json['item_type'] ?? '',
      item: item,
      quantity: json['quantity']?.toInt() ?? 0,
      addedAt: json['added_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'item': item.toJson(),
      'quantity': quantity,
      'added_at': addedAt,
    };
  }

  double get price {
    if (item is Roll) {
      return (item as Roll).salePrice * quantity;
    } else if (item is Set) {
      return (item as Set).setPrice * quantity;
    }
    return 0.0;
  }

  String get itemName {
    if (item is Roll) {
      return (item as Roll).name;
    } else if (item is Set) {
      return (item as Set).name;
    }
    return '';
  }

  @override
  String toString() {
    return 'CartItem(id: $id, itemType: $itemType, itemName: $itemName, quantity: $quantity)';
  }
}
