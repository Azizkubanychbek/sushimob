import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class JsonUserService {
  static final JsonUserService _instance = JsonUserService._internal();
  factory JsonUserService() => _instance;
  JsonUserService._internal();

  static const String _usersFilePath = 'assets/data/users.json';
  static const String _usersStorageKey = 'users_data';
  List<User> _users = [];
  bool _isInitialized = false;

  List<User> get users => List.unmodifiable(_users);
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('📁 Инициализация JsonUserService...');
      
      if (kIsWeb) {
        // На вебе сначала пробуем загрузить из localStorage
        await _loadFromLocalStorage();
        
        // Если в localStorage пусто, загружаем из JSON файла
        if (_users.isEmpty) {
          await _loadFromJsonFile();
        }
      } else {
        // На мобильных загружаем из файла
        await _loadFromJsonFile();
      }
      
      print('✅ JsonUserService инициализирован. Пользователей: ${_users.length}');
      _isInitialized = true;
    } catch (e) {
      print('❌ Ошибка инициализации JsonUserService: $e');
      _users = [];
      _isInitialized = true;
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersStorageKey);
      
      if (usersJson != null) {
        final jsonData = jsonDecode(usersJson);
        _users = _parseUsersFromJson(jsonData);
        print('✅ Загружено ${_users.length} пользователей из localStorage');
      } else {
        print('ℹ️ localStorage пуст, загружаем из JSON файла...');
      }
    } catch (e) {
      print('❌ Ошибка загрузки из localStorage: $e');
    }
  }

  Future<void> _loadFromJsonFile() async {
    try {
      final jsonString = await rootBundle.loadString(_usersFilePath);
      final jsonData = jsonDecode(jsonString);
      _users = _parseUsersFromJson(jsonData);
      print('✅ Загружено ${_users.length} пользователей из JSON файла');
    } catch (e) {
      print('❌ Ошибка загрузки из JSON файла: $e');
      _users = [];
    }
  }

  List<User> _parseUsersFromJson(Map<String, dynamic> jsonData) {
    final usersList = jsonData['users'] as List<dynamic>? ?? [];
    return usersList.map((userData) => User.fromJson(userData)).toList();
  }

  Future<void> _saveUsers() async {
    try {
      final jsonData = {
        'users': _users.map((user) => user.toLocalStorageJson()).toList(),
      };
      
      print('💾 Сохраняем ${_users.length} пользователей...');
      
      if (kIsWeb) {
        // На вебе сохраняем в localStorage
        await _saveToLocalStorage(jsonData);
      } else {
        // На мобильных сохраняем в файл
        await _saveToFile(jsonData);
      }
      
      print('✅ Пользователи успешно сохранены!');
    } catch (e) {
      print('❌ Ошибка сохранения пользователей: $e');
    }
  }

  Future<void> _saveToLocalStorage(Map<String, dynamic> jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usersStorageKey, jsonEncode(jsonData));
      print('✅ Пользователи сохранены в localStorage');
    } catch (e) {
      print('❌ Ошибка сохранения в localStorage: $e');
    }
  }

  Future<void> _saveToFile(Map<String, dynamic> jsonData) async {
    try {
      final file = File(_usersFilePath);
      await file.writeAsString(jsonEncode(jsonData));
      print('✅ Пользователи сохранены в файл: ${file.path}');
    } catch (e) {
      print('❌ Ошибка сохранения в файл: $e');
    }
  }

  Future<User> addUser(User user) async {
    await initialize();
    
    final newUser = user.id == null 
        ? user.copyWith(id: _generateUserId())
        : user;
    
    _users.add(newUser);
    await _saveUsers();
    
    print('✅ Пользователь ${newUser.name} добавлен в базу данных');
    return newUser;
  }

  User? findUserByEmail(String email) {
    return _users.cast<User?>().firstWhere(
      (user) => user?.email == email.toLowerCase(),
      orElse: () => null,
    );
  }

  User? findUserById(int id) {
    return _users.cast<User?>().firstWhere(
      (user) => user?.id == id,
      orElse: () => null,
    );
  }

  Future<void> updateUser(User updatedUser) async {
    final index = _users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      await _saveUsers();
      print('✅ Пользователь ${updatedUser.name} обновлен');
    }
  }

  bool isEmailTaken(String email) {
    return _users.any((user) => user.email == email.toLowerCase());
  }

  int _generateUserId() {
    if (_users.isEmpty) return 1;
    return _users.map((u) => u.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  List<User> getAllUsers() {
    return List.unmodifiable(_users);
  }

  Future<void> clearAllUsers() async {
    _users.clear();
    await _saveUsers();
    print('🗑️ Все пользователи удалены');
  }

  // Метод для отладки - показать всех пользователей
  void debugPrintUsers() {
    print('🔍 ТЕКУЩИЕ ПОЛЬЗОВАТЕЛИ В БАЗЕ:');
    for (final user in _users) {
      print('  - ID: ${user.id}, Имя: ${user.name}, Email: ${user.email}');
    }
  }
}
