import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import 'auth_service.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    // Автоматически загружаем корзину при инициализации
    _initialize();
  }

  static const String _baseUrl = 'http://127.0.0.1:5002/api';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  bool get isEmpty => _cartItems.isEmpty;
  bool get isLoading => _isLoading;

  double get totalPrice {
    return _cartItems.fold(0.0, (total, item) => total + item.price);
  }

  int get totalItems {
    return _cartItems.fold(0, (total, item) => total + item.quantity);
  }

  // Инициализация сервиса
  Future<void> _initialize() async {
    await loadCart();
  }

  // Получение корзины с сервера
  Future<void> loadCart() async {
    try {
      _isLoading = true;
      
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для загрузки корзины');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/cart'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['cart'] != null) {
          try {
            _cartItems = (data['cart'] as List)
                .map((json) {
                  // Проверяем, что json не null и содержит необходимые поля
                  if (json == null) return null;
                  return CartItem.fromJson(json);
                })
                .where((item) => item != null) // Убираем null элементы
                .cast<CartItem>()
                .toList();
            print('✅ Корзина загружена: ${_cartItems.length} товаров');
          } catch (e) {
            print('❌ Ошибка парсинга корзины: $e');
            _cartItems = [];
          }
        } else {
          print('❌ API вернул ошибку: ${data['error'] ?? 'Неизвестная ошибка'}');
          _cartItems = [];
        }
      } else {
        print('❌ Ошибка загрузки корзины: ${response.statusCode}');
        _cartItems = [];
      }
    } catch (e) {
      print('❌ Ошибка загрузки корзины: $e');
      _cartItems = [];
    } finally {
      _isLoading = false;
    }
  }

  // Добавление товара в корзину
  Future<bool> addToCart({
    required String itemType,
    required int itemId,
    required int quantity,
  }) async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для добавления в корзину');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/cart/add'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
        body: jsonEncode({
          'item_type': itemType,
          'item_id': itemId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Товар добавлен в корзину');
        // Перезагружаем корзину
        await loadCart();
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка добавления в корзину: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка добавления в корзину: $e');
      return false;
    }
  }

  // Удаление товара из корзины
  Future<bool> removeFromCart(int itemId) async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для удаления из корзины');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/cart/remove/$itemId'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Товар удален из корзины');
        // Перезагружаем корзину
        await loadCart();
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка удаления из корзины: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка удаления из корзины: $e');
      return false;
    }
  }

  // Обновление количества товара
  Future<bool> updateQuantity(int itemId, int newQuantity) async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для обновления корзины');
        return false;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/cart/update/$itemId'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
        body: jsonEncode({
          'quantity': newQuantity,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Количество товара обновлено');
        // Перезагружаем корзину
        await loadCart();
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка обновления количества: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка обновления количества: $e');
      return false;
    }
  }

  // Очистка корзины
  Future<bool> clearCart() async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для очистки корзины');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/cart/clear'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Корзина очищена');
        _cartItems = [];
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка очистки корзины: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка очистки корзины: $e');
      return false;
    }
  }

  // Проверка, есть ли товар в корзине
  bool isInCart(String itemType, int itemId) {
    return _cartItems.any((item) => 
      item.itemType == itemType && item.item.id == itemId
    );
  }

  // Получение количества товара в корзине
  int getItemQuantity(String itemType, int itemId) {
    final item = _cartItems.firstWhere(
      (item) => item.itemType == itemType && item.item.id == itemId,
      orElse: () => CartItem(
        id: 0,
        itemType: itemType,
        item: null,
        quantity: 0,
        addedAt: '',
        price: 0.0, // Added missing price parameter
      ),
    );
    return item.quantity;
  }

  // Использование бонусных баллов
  Future<Map<String, dynamic>> useBonusPoints(int bonusPoints) async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        return {
          'success': false,
          'error': 'Необходимо войти в систему',
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/cart/use-bonus'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
        body: jsonEncode({
          'bonus_points': bonusPoints,
        }),
      );

      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Бонусные баллы успешно использованы');
        // Перезагружаем корзину после использования бонусов
        await loadCart();
        return {
          'success': true,
          'message': jsonData['message'],
          'bonus_points_used': jsonData['bonus_points_used'],
          'remaining_bonus_points': jsonData['remaining_bonus_points'],
          'discount_applied': jsonData['discount_applied'],
        };
      } else {
        print('❌ Ошибка использования бонусных баллов: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ Ошибка сети при использовании бонусных баллов: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }
}
