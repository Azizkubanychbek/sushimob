import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'api_user_service.dart';

class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final String? sessionToken;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.sessionToken,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiUserService _userService = ApiUserService();
  User? _currentUser;
  String? _currentSessionToken;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get sessionToken => _currentSessionToken;

  Future<void> initialize() async {
    print('🔐 Инициализация AuthService...');
    
    // Проверяем состояние API
    final apiHealth = await _userService.checkApiHealth();
    if (apiHealth) {
      print('✅ API сервер доступен');
    } else {
      print('❌ API сервер недоступен');
    }
    
    print('✅ AuthService инициализирован');
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      print('📝 Попытка регистрации через API: $email');

      final validationResult = _validateRegistrationData(name, email, phone, password);
      if (!validationResult.success) {
        return validationResult;
      }

      // Регистрация через API
      final result = await _userService.registerUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (result['success']) {
        final user = result['user'] as User;
        final accessToken = result['access_token'] as String;
        
        await _createSession(user, accessToken);
        
        return AuthResult(
          success: true,
          message: result['message'] as String,
          user: user,
          sessionToken: accessToken,
        );
      } else {
        return AuthResult(
          success: false,
          message: result['error'] as String,
        );
      }

    } catch (e) {
      print('❌ Ошибка регистрации: $e');
      return AuthResult(
        success: false,
        message: 'Произошла ошибка при регистрации. Попробуйте позже.',
      );
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Попытка входа через API: $email');

      // Вход через API
      final result = await _userService.loginUser(
        email: email,
        password: password,
      );

      if (result['success']) {
        final user = result['user'] as User;
        final accessToken = result['access_token'] as String;
        
        await _createSession(user, accessToken);
        
        return AuthResult(
          success: true,
          message: result['message'] as String,
          user: user,
          sessionToken: accessToken,
        );
      } else {
        return AuthResult(
          success: false,
          message: result['error'] as String,
        );
      }

    } catch (e) {
      print('❌ Ошибка входа: $e');
      return AuthResult(
        success: false,
        message: 'Произошла ошибка при входе. Попробуйте позже.',
      );
    }
  }

  Future<void> logout() async {
    try {
      print('🚪 Выход из системы...');
      _currentUser = null;
      _currentSessionToken = null;
      print('✅ Выход выполнен');
    } catch (e) {
      print('❌ Ошибка при выходе: $e');
    }
  }

  Future<void> _createSession(User user, String accessToken) async {
    try {
      _currentUser = user;
      _currentSessionToken = accessToken;

      print('✅ Сессия создана для ${user.name} через API');
    } catch (e) {
      print('❌ Ошибка создания сессии: $e');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }

  String _generateSessionToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  AuthResult _validateRegistrationData(String name, String email, String phone, String password) {
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: 'Все поля должны быть заполнены');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return AuthResult(success: false, message: 'Введите корректный email');
    }
    if (password.length < 6) {
      return AuthResult(success: false, message: 'Пароль должен содержать минимум 6 символов');
    }
    return AuthResult(success: true, message: 'Данные валидны');
  }

  // Метод для отладки - показать всех пользователей через API
  Future<void> debugPrintUsers() async {
    try {
      final users = await _userService.getAllUsers();
      print('🔍 ПОЛЬЗОВАТЕЛИ В API БАЗЕ ДАННЫХ:');
      for (final user in users) {
        print('  - ID: ${user.id}, Имя: ${user.name}, Email: ${user.email}');
      }
    } catch (e) {
      print('❌ Ошибка получения пользователей: $e');
    }
  }
}
