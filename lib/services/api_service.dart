import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/roll.dart';
import '../models/set.dart';
import '../models/user.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5002/api';
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
          'location': address, // Используем location вместо address
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['access_token']; // Используем access_token
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
        _authToken = data['access_token']; // Используем access_token
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

  // Новый метод для получения дополнительных товаров
  static Future<List<Map<String, dynamic>>> getOtherItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/other-items'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['other_items']);
      } else {
        throw Exception('Ошибка получения дополнительных товаров');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Новый метод для получения товаров по категории
  static Future<List<Map<String, dynamic>>> getOtherItemsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/other-items/category/$category'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['other_items']);
      } else {
        throw Exception('Ошибка получения товаров категории $category');
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

  // Метод для получения всех ингредиентов (для редактора рецептуры)
  static Future<List<Map<String, dynamic>>> getIngredients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/ingredients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['ingredients']);
      } else {
        throw Exception('Ошибка получения ингредиентов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Заказы
  static Future<Map<String, dynamic>> createOrder({
    required double totalAmount,
    required String deliveryAddress,
    required String phone,
    String paymentMethod = 'cash',
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode({
          'total_amount': totalAmount,
          'delivery_address': deliveryAddress,
          'phone': phone,
          'payment_method': paymentMethod,
          'comment': comment ?? '',
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

  // Админ API методы
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        throw Exception('Ошибка получения пользователей');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> createAdminRoll(Map<String, dynamic> rollData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/rolls'),
        headers: _headers,
        body: jsonEncode(rollData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка создания ролла');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAdminRoll(int rollId, Map<String, dynamic> rollData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/rolls/$rollId'),
        headers: _headers,
        body: jsonEncode(rollData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления ролла');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteAdminRoll(int rollId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/rolls/$rollId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка удаления ролла');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> createAdminSet(Map<String, dynamic> setData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/sets'),
        headers: _headers,
        body: jsonEncode(setData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка создания сета');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAdminSet(int setId, Map<String, dynamic> setData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/sets/$setId'),
        headers: _headers,
        body: jsonEncode(setData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления сета');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteAdminSet(int setId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/sets/$setId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка удаления сета');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminIngredients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/ingredients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['ingredients']);
      } else {
        throw Exception('Ошибка получения ингредиентов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> createAdminIngredient(Map<String, dynamic> ingredientData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/ingredients'),
        headers: _headers,
        body: jsonEncode(ingredientData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка создания ингредиента');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAdminIngredient(int ingredientId, Map<String, dynamic> ingredientData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/ingredients/$ingredientId'),
        headers: _headers,
        body: jsonEncode(ingredientData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления ингредиента');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteAdminIngredient(int ingredientId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/ingredients/$ingredientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка удаления ингредиента');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // API методы для управления соусами/напитками
  static Future<Map<String, dynamic>> createAdminOtherItem(Map<String, dynamic> itemData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/other-items'),
        headers: _headers,
        body: jsonEncode(itemData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка создания товара');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAdminOtherItem(int itemId, Map<String, dynamic> itemData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/other-items/$itemId'),
        headers: _headers,
        body: jsonEncode(itemData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления товара');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteAdminOtherItem(int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/other-items/$itemId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка удаления товара');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения статистики');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Админ API для рецептуры роллов
  static Future<Map<String, dynamic>> getRollRecipe(int rollId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/rolls/$rollId/recipe'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения рецептуры');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> updateRollRecipe(int rollId, Map<String, dynamic> recipeData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/rolls/$rollId/recipe'),
        headers: _headers,
        body: jsonEncode(recipeData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления рецептуры');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // API для работы с составом сетов
  static Future<Map<String, dynamic>> getSetComposition(int setId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/sets/$setId/composition'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения состава сета');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<Map<String, dynamic>> updateSetComposition(int setId, Map<String, dynamic> compositionData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/sets/$setId/composition'),
        headers: _headers,
        body: jsonEncode(compositionData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка обновления состава сета');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // ===== API для накопительных карт =====
  
  // Получение накопительных карт пользователя
  static Future<Map<String, dynamic>> getLoyaltyCards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/loyalty/cards'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения накопительных карт');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Получение доступных роллов для накопительной системы
  static Future<Map<String, dynamic>> getAvailableLoyaltyRolls() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/loyalty/available-rolls'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения доступных роллов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Использование накопительной карты
  static Future<Map<String, dynamic>> useLoyaltyCard({
    required int cardId,
    required int rollId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loyalty/use-card'),
        headers: _headers,
        body: jsonEncode({
          'card_id': cardId,
          'roll_id': rollId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка использования накопительной карты');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Получение истории использования накопительных карт
  static Future<Map<String, dynamic>> getLoyaltyHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/loyalty/history'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения истории');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Получение списка заказов пользователя (обновленная версия)
  static Future<List<Order>> getOrdersList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = (data['orders'] as List<dynamic>?)
            ?.map((order) => Order.fromJson(order))
            .toList() ?? [];
        return orders;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения заказов');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Создание нового заказа (обновленная версия)
  static Future<Order> createNewOrder({
    required String deliveryAddress,
    required String deliveryPhone,
    required String paymentMethod,
    String? notes,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      // Получаем данные корзины если items не переданы
      List<Map<String, dynamic>> orderItems = items ?? [];
      
      if (orderItems.isEmpty) {
        // Получаем корзину пользователя
        final cart = await getCart();
        orderItems = cart.map((cartItem) {
          // Безопасно получаем ID товара
          dynamic itemId;
          if (cartItem.item is Map) {
            itemId = cartItem.item['id'];
          } else if (cartItem.item != null) {
            itemId = cartItem.item.id;
          } else {
            // Если item равен null, используем ID из cartItem
            itemId = cartItem.id;
          }
          
          return {
            'item_type': cartItem.itemType,
            'item_id': itemId,
            'quantity': cartItem.quantity,
            'price': cartItem.price / cartItem.quantity,
          };
        }).toList();
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode({
          'delivery_address': deliveryAddress,
          'phone': deliveryPhone,
          'payment_method': paymentMethod,
          'comment': notes,
          'items': orderItems,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка создания заказа');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // Получение деталей заказа по ID
  static Future<Order> getOrderById(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка получения заказа');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }
}
