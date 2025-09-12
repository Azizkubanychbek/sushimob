import 'roll.dart';
import 'set.dart';

class CartItem {
  final int id;
  final String itemType; // 'roll' или 'set'
  final dynamic item; // Roll или Set
  final int quantity;
  final String addedAt;
  final double price; // Added price field

  CartItem({
    required this.id,
    required this.itemType,
    required this.item,
    required this.quantity,
    required this.addedAt,
    required this.price, // Added price parameter
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    dynamic item;
    
    // Проверяем, что item существует и не null
    if (json['item'] != null) {
      if (json['item_type'] == 'roll') {
        item = Roll.fromJson(json['item']);
      } else if (json['item_type'] == 'set') {
        item = Set.fromJson(json['item']);
      } else if (json['item_type'] == 'loyalty_roll') {
        // Для бесплатных роллов тоже используем Roll
        item = Roll.fromJson(json['item']);
      } else if (json['item_type'] == 'bonus_points') {
        // Для бонусных баллов создаем фиктивный объект
        item = {
          'id': 'bonus',
          'name': json['name'] ?? 'Бонусные баллы',
          'description': 'Скидка за бонусные баллы',
          'sale_price': json['price'] ?? 0.0,
          'image_url': null,
        };
      }
    }

    // Для бонусных баллов генерируем уникальный ID
    int itemId = json['id']?.toInt() ?? 0;
    if (json['item_type'] == 'bonus_points' && itemId == 0) {
      itemId = -1; // Используем отрицательный ID для бонусных баллов
    }

    return CartItem(
      id: itemId,
      itemType: json['item_type'] ?? '',
      item: item,
      quantity: json['quantity']?.toInt() ?? 0,
      addedAt: json['added_at'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(), // Parse price from API
    );
  }

  Map<String, dynamic> toJson() {
    dynamic itemJson;
    if (item is Roll || item is Set) {
      itemJson = item.toJson();
    } else if (item is Map<String, dynamic>) {
      // Для бонусных баллов
      itemJson = item;
    } else {
      itemJson = {};
    }

    return {
      'id': id,
      'item_type': itemType,
      'item': itemJson,
      'quantity': quantity,
      'added_at': addedAt,
      'price': price, // Include price in JSON
    };
  }

  String get itemName {
    if (item is Roll) {
      return (item as Roll).name;
    } else if (item is Set) {
      return (item as Set).name;
    } else if (item is Map<String, dynamic>) {
      // Для бонусных баллов
      return item['name'] ?? 'Бонусные баллы';
    }
    return '';
  }

  @override
  String toString() {
    return 'CartItem(id: $id, itemType: $itemType, itemName: $itemName, quantity: $quantity, price: $price)';
  }
}
