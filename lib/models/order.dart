class Order {
  final int id;
  final int userId;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String? deliveryInstructions;
  final String? paymentMethod;
  final String? comment;
  final String? phone;

  Order({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.deliveryInstructions,
    this.paymentMethod,
    this.comment,
    this.phone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userPhone: json['user_phone'],
      userEmail: json['user_email'],
      deliveryAddress: json['delivery_address'],
      deliveryLatitude: json['delivery_latitude']?.toDouble(),
      deliveryLongitude: json['delivery_longitude']?.toDouble(),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['total_amount'] ?? json['total_price'])?.toDouble() ?? 0.0,
      status: OrderStatusExtension.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      notes: json['notes'],
      deliveryInstructions: json['delivery_instructions'],
      paymentMethod: json['payment_method'],
      comment: json['comment'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'user_email': userEmail,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status.toApiString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
      'delivery_instructions': deliveryInstructions,
      'payment_method': paymentMethod,
      'comment': comment,
      'phone': phone,
    };
  }

  // Геттер для совместимости
  double get totalPrice => totalAmount;

  Order copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? deliveryInstructions,
    String? paymentMethod,
    String? comment,
    String? phone,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      comment: comment ?? this.comment,
      phone: phone ?? this.phone,
    );
  }
}

class OrderItem {
  final int id;
  final String itemType; // 'roll' или 'set'
  final int itemId;
  final String itemName;
  final String itemImage;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.itemImage,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      itemType: json['item_type'],
      itemId: json['item_id'],
      itemName: json['item_name'] ?? 'Товар',
      itemImage: json['item_image'] ?? '',
      quantity: json['quantity'],
      price: json['unit_price']?.toDouble() ?? json['price']?.toDouble() ?? 0.0,
      totalPrice: json['total_price'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'item_id': itemId,
      'item_name': itemName,
      'item_image': itemImage,
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
    };
  }
}

enum OrderStatus {
  pending,      // Ожидает подтверждения
  confirmed,    // Принят шеф-поваром
  preparing,    // Готовится
  ready,        // Готов, передан курьеру
  delivering,   // Доставляется
  delivered,    // Доставлен
  cancelled,    // Отменен
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Ожидает подтверждения';
      case OrderStatus.confirmed:
        return 'Принят';
      case OrderStatus.preparing:
        return 'Готовится';
      case OrderStatus.ready:
        return 'Готов';
      case OrderStatus.delivering:
        return 'Доставляется';
      case OrderStatus.delivered:
        return 'Доставлен';
      case OrderStatus.cancelled:
        return 'Отменен';
    }
  }

  String get color {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA500'; // Оранжевый
      case OrderStatus.confirmed:
        return '#007BFF'; // Синий
      case OrderStatus.preparing:
        return '#6C757D'; // Серый
      case OrderStatus.ready:
        return '#28A745'; // Зеленый
      case OrderStatus.delivering:
        return '#17A2B8'; // Голубой
      case OrderStatus.delivered:
        return '#28A745'; // Зеленый
      case OrderStatus.cancelled:
        return '#DC3545'; // Красный
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'ожидает подтверждения':
        return OrderStatus.pending;
      case 'confirmed':
      case 'принят':
        return OrderStatus.confirmed;
      case 'preparing':
      case 'готовится':
        return OrderStatus.preparing;
      case 'ready':
      case 'готов':
        return OrderStatus.ready;
      case 'delivering':
      case 'доставляется':
        return OrderStatus.delivering;
      case 'delivered':
      case 'доставлен':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'отменен':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String toApiString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.delivering:
        return 'delivering';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}