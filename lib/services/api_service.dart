import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/roll.dart';
import '../models/set.dart';
import '../models/user.dart';
import '../models/cart_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Аутентификация
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка регистрации');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка входа');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Получение данных
  static Future<List<Roll>> getRolls() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rolls'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['rolls'] as List)
            .map((json) => Roll.fromJson(json))
            .toList();
      } else {
        throw Exception('Ошибка получения роллов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<List<Set>> getSets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sets'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['sets'] as List)
            .map((json) => Set.fromJson(json))
            .toList();
      } else {
        throw Exception('Ошибка получения сетов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Roll> getRollDetails(int rollId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rolls/$rollId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Roll.fromJson(data['roll']);
      } else {
        throw Exception('Ошибка получения деталей ролла');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Корзина
  static Future<List<CartItem>> getCart() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['cart'] as List)
            .map((json) => CartItem.fromJson(json))
            .toList();
      } else {
        throw Exception('Ошибка получения корзины');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<void> addToCart({
    required String itemType,
    required int itemId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: _headers,
        body: jsonEncode({
          'item_type': itemType,
          'item_id': itemId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка добавления в корзину');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<void> removeFromCart(int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove/$itemId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка удаления из корзины');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Заказы
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
    String? deliveryTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode({
          'items': items,
          'total_amount': totalAmount,
          'delivery_address': deliveryAddress,
          'delivery_time': deliveryTime,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка создания заказа');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['orders']);
      } else {
        throw Exception('Ошибка получения заказов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Профиль
  static Future<User> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Ошибка получения профиля');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления профиля');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Выход
  static void logout() {
    _authToken = null;
  }
}
