import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/favorite_item.dart';
import 'auth_service.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal() {
    // Автоматически загружаем избранное при инициализации
    _initialize();
  }

  static const String _baseUrl = 'http://127.0.0.1:5002/api';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  List<FavoriteItem> _favoriteItems = [];
  bool _isLoading = false;

  List<FavoriteItem> get favoriteItems => List.unmodifiable(_favoriteItems);
  bool get isEmpty => _favoriteItems.isEmpty;
  bool get isLoading => _isLoading;

  int get totalItems => _favoriteItems.length;

  // Инициализация сервиса
  Future<void> _initialize() async {
    await loadFavorites();
  }

  // Получение избранного с сервера
  Future<void> loadFavorites() async {
    try {
      _isLoading = true;
      
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для загрузки избранного');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/favorites'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['favorites'] != null) {
          _favoriteItems = (data['favorites'] as List)
              .map((json) => FavoriteItem.fromJson(json))
              .toList();
          print('✅ Избранное загружено: ${_favoriteItems.length} товаров');
        } else {
          print('❌ API вернул ошибку: ${data['error'] ?? 'Неизвестная ошибка'}');
          _favoriteItems = [];
        }
      } else {
        print('❌ Ошибка загрузки избранного: ${response.statusCode}');
        _favoriteItems = [];
      }
    } catch (e) {
      print('❌ Ошибка загрузки избранного: $e');
      _favoriteItems = [];
    } finally {
      _isLoading = false;
    }
  }

  // Добавление товара в избранное
  Future<bool> addToFavorites({
    required String itemType,
    required int itemId,
  }) async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для добавления в избранное');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/favorites/add'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
        body: jsonEncode({
          'item_type': itemType,
          'item_id': itemId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Товар добавлен в избранное');
        // Перезагружаем избранное
        await loadFavorites();
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка добавления в избранное: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка добавления в избранное: $e');
      return false;
    }
  }

  // Удаление товара из избранного
  Future<bool> removeFromFavorites(int itemId) async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для удаления из избранного');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/favorites/remove/$itemId'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Товар удален из избранного');
        // Перезагружаем избранное
        await loadFavorites();
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка удаления из избранного: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка удаления из избранного: $e');
      return false;
    }
  }

  // Очистка избранного
  Future<bool> clearFavorites() async {
    try {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('❌ Пользователь не авторизован для очистки избранного');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/favorites/clear'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer ${authService.sessionToken}',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Избранное очищено');
        _favoriteItems = [];
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Ошибка очистки избранного: ${error['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка очистки избранного: $e');
      return false;
    }
  }

  // Проверка, есть ли товар в избранном
  bool isInFavorites(String itemType, int itemId) {
    return _favoriteItems.any((item) => 
      item.itemType == itemType && item.item.id == itemId
    );
  }

  // Переключение состояния избранного (добавить/удалить)
  Future<bool> toggleFavorite({
    required String itemType,
    required int itemId,
  }) async {
    if (isInFavorites(itemType, itemId)) {
      // Если товар уже в избранном, удаляем его
      final item = _favoriteItems.firstWhere(
        (item) => item.itemType == itemType && item.item.id == itemId,
      );
      return await removeFromFavorites(item.id);
    } else {
      // Если товара нет в избранном, добавляем его
      return await addToFavorites(itemType: itemType, itemId: itemId);
    }
  }
}
