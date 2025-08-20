import 'roll.dart';
import 'set.dart';

class FavoriteItem {
  final int id;
  final String itemType; // 'roll' или 'set'
  final dynamic item; // Roll или Set
  final String addedAt;

  FavoriteItem({
    required this.id,
    required this.itemType,
    required this.item,
    required this.addedAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    dynamic item;
    if (json['item_type'] == 'roll') {
      item = Roll.fromJson(json['item']);
    } else if (json['item_type'] == 'set') {
      item = Set.fromJson(json['item']);
    }

    return FavoriteItem(
      id: json['id']?.toInt() ?? 0,
      itemType: json['item_type'] ?? '',
      item: item,
      addedAt: json['added_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'item': item.toJson(),
      'added_at': addedAt,
    };
  }

  String get itemName {
    if (item is Roll) {
      return (item as Roll).name;
    } else if (item is Set) {
      return (item as Set).name;
    }
    return '';
  }

  double get price {
    if (item is Roll) {
      return (item as Roll).salePrice;
    } else if (item is Set) {
      return (item as Set).setPrice;
    }
    return 0.0;
  }

  String get imageUrl {
    // Используем заглушки для изображений, так как в моделях Roll и Set нет imageUrl
    if (item is Roll) {
      return 'https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
    } else if (item is Set) {
      return 'https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
    }
    return '';
  }

  @override
  String toString() {
    return 'FavoriteItem(id: $id, itemType: $itemType, itemName: $itemName)';
  }
}
