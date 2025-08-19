import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'json_user_service.dart';

class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? sessionToken;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.sessionToken,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final JsonUserService _userService = JsonUserService();
  User? _currentUser;
  String? _currentSessionToken;

  // Геттеры
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _currentSessionToken != null;
  String? get sessionToken => _currentSessionToken;

  // Инициализация - проверка сохраненной сессии
  Future<void> initialize() async {
    print('🔐 Инициализация AuthService...');
    
    // Инициализируем JSON сервис
    await _userService.initialize();
    
    print('✅ AuthService инициализирован');
  }

  // Регистрация нового пользователя
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      print('📝 Попытка регистрации: $email');

      // Проверка на существование пользователя
      if (_userService.isEmailTaken(email)) {
        return AuthResult(
          success: false,
          message: 'Пользователь с таким email уже существует',
        );
      }

      // Валидация данных
      final validationResult = _validateRegistrationData(name, email, phone, password);
      if (!validationResult.success) {
        return validationResult;
      }

      // Создание пользователя
      final user = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        loyaltyPoints: 100, // Приветственные баллы
      );

      // Добавление в JSON базу
      final createdUser = await _userService.addUser(user);

      // Автоматический вход после регистрации
      await _createSession(createdUser);
      
      return AuthResult(
        success: true,
        message: 'Регистрация прошла успешно! Добро пожаловать!',
        user: createdUser,
        sessionToken: _currentSessionToken,
      );

    } catch (e) {
      print('❌ Ошибка регистрации: $e');
      return AuthResult(
        success: false,
        message: 'Произошла ошибка при регистрации. Попробуйте позже.',
      );
    }
  }

  // Вход в систему
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Попытка входа: $email');

      final user = _userService.findUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'Неверный email или пароль',
        );
      }

      if (!user.isActive) {
        return AuthResult(
          success: false,
          message: 'Аккаунт деактивирован. Обратитесь в поддержку.',
        );
      }

      // Проверка пароля
      if (!_verifyPassword(password, user.passwordHash)) {
        return AuthResult(
          success: false,
          message: 'Неверный email или пароль',
        );
      }

      // Обновление времени последнего входа
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _userService.updateUser(updatedUser);

      // Создание сессии
      await _createSession(updatedUser);
      
      return AuthResult(
        success: true,
        message: 'Добро пожаловать, ${updatedUser.name}!',
        user: updatedUser,
        sessionToken: _currentSessionToken,
      );

    } catch (e) {
      print('❌ Ошибка входа: $e');
      return AuthResult(
        success: false,
        message: 'Произошла ошибка при входе. Попробуйте позже.',
      );
    }
  }

  // Выход из системы
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

  // Приватные методы
  Future<void> _createSession(User user) async {
    try {
      // Генерация токена сессии
      final sessionToken = _generateSessionToken();

      _currentUser = user;
      _currentSessionToken = sessionToken;

      print('✅ Сессия создана для ${user.name}');
    } catch (e) {
      print('❌ Ошибка создания сессии: $e');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'sushiroll_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  AuthResult _validateRegistrationData(String name, String email, String phone, String password) {
    if (name.trim().length < 2) {
      return AuthResult(
        success: false,
        message: 'Имя должно содержать минимум 2 символа',
      );
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return AuthResult(
        success: false,
        message: 'Неверный формат email',
      );
    }

    if (phone.trim().length < 10) {
      return AuthResult(
        success: false,
        message: 'Телефон должен содержать минимум 10 цифр',
      );
    }

    if (password.length < 6) {
      return AuthResult(
        success: false,
        message: 'Пароль должен содержать минимум 6 символов',
      );
    }

    return AuthResult(success: true);
  }
}
