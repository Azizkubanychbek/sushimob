import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/user.dart';

class OrderService {
  static const String baseUrl = 'http://localhost:5002/api';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Создать заказ
  Future<Map<String, dynamic>> createOrder({
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required List<Map<String, dynamic>> cartItems,
    String? notes,
    String? deliveryInstructions,
  }) async {
    try {
      print('📦 Создание заказа...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: json.encode({
          'delivery_address': deliveryAddress,
          'delivery_latitude': deliveryLatitude,
          'delivery_longitude': deliveryLongitude,
          'items': cartItems,
          'notes': notes,
          'delivery_instructions': deliveryInstructions,
        }),
      );

      print('📦 Ответ API заказа: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Заказ создан успешно');
        return {
          'success': true,
          'order': data['order'],
          'message': data['message'] ?? 'Заказ создан успешно',
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ Ошибка создания заказа: ${errorData['detail']}');
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Ошибка создания заказа',
        };
      }
    } catch (e) {
      print('❌ Ошибка создания заказа: $e');
      return {
        'success': false,
        'message': 'Ошибка сети: $e',
      };
    }
  }

  // Получить заказы пользователя
  Future<List<Order>> getUserOrders() async {
    try {
      print('📋 Получение заказов пользователя...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
      );

      print('📋 Ответ API заказов: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        
        print('✅ Получено заказов: ${orders.length}');
        return orders;
      } else {
        print('❌ Ошибка получения заказов');
        return [];
      }
    } catch (e) {
      print('❌ Ошибка получения заказов: $e');
      return [];
    }
  }

  // Получить все заказы (для шеф-повара)
  Future<List<Order>> getAllOrders() async {
    try {
      print('👨‍🍳 Получение всех заказов...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/all'),
        headers: _headers,
      );

      print('👨‍🍳 Ответ API всех заказов: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        
        print('✅ Получено заказов: ${orders.length}');
        return orders;
      } else {
        print('❌ Ошибка получения всех заказов');
        return [];
      }
    } catch (e) {
      print('❌ Ошибка получения всех заказов: $e');
      return [];
    }
  }

  // Обновить статус заказа
  Future<bool> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    try {
      print('🔄 Обновление статуса заказа $orderId на ${newStatus.displayName}...');
      
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: _headers,
        body: json.encode({
          'status': newStatus.toApiString(),
        }),
      );

      print('🔄 Ответ API обновления статуса: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Статус заказа обновлен');
        return true;
      } else {
        print('❌ Ошибка обновления статуса заказа');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка обновления статуса заказа: $e');
      return false;
    }
  }

  // Получить заказ по ID
  Future<Order?> getOrderById(int orderId) async {
    try {
      print('🔍 Получение заказа $orderId...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _headers,
      );

      print('🔍 Ответ API заказа: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final order = Order.fromJson(data['order']);
        
        print('✅ Заказ получен');
        return order;
      } else {
        print('❌ Ошибка получения заказа');
        return null;
      }
    } catch (e) {
      print('❌ Ошибка получения заказа: $e');
      return null;
    }
  }

  // Отменить заказ
  Future<bool> cancelOrder(int orderId) async {
    try {
      print('❌ Отмена заказа $orderId...');
      
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: _headers,
      );

      print('❌ Ответ API отмены заказа: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Заказ отменен');
        return true;
      } else {
        print('❌ Ошибка отмены заказа');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка отмены заказа: $e');
      return false;
    }
  }
}
