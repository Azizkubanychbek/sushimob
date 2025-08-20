import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'auth_service.dart';

class WebAuthService {
  static final WebAuthService _instance = WebAuthService._internal();
  factory WebAuthService() => _instance;
  WebAuthService._internal();

  final String _usersKey = 'sushi_users';
  final String _currentUserKey = 'current_user';
  final String _sessionKey = 'session_token';

  User? _currentUser;
  String? _currentSessionToken;

  // Геттеры
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _currentSessionToken != null;
  String? get sessionToken => _currentSessionToken;

  // Инициализация
  Future<void> initialize() async {
    print('🔐 Инициализация WebAuthService...');
    
    final savedToken = html.window.localStorage[_sessionKey];
    
    if (savedToken != null) {
      final currentUserData = html.window.localStorage[_currentUserKey];
      if (currentUserData != null) {
        try {
          final userData = jsonDecode(currentUserData);
          _currentUser = User.fromJson(userData);
          _currentSessionToken = savedToken;
          print('✅ Автоматический вход: ${_currentUser!.name}');
          return;
        } catch (e) {
          print('❌ Ошибка восстановления сессии: $e');
          await _clearStoredSession();
        }
      }
    }
    
    print('❌ Пользователь не авторизован');
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

      // Получение существующих пользователей
      final users = _getStoredUsers();

      // Проверка на существование пользователя
      if (users.any((user) => user.email == email.toLowerCase())) {
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
        id: _generateUserId(users),
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        loyaltyPoints: 100, // Приветственные баллы
      );

      // Сохранение пользователя
      users.add(user);
      _saveUsers(users);

      // Автоматический вход после регистрации
      await _createSession(user);
      
      return AuthResult(
        success: true,
        message: 'Регистрация прошла успешно! Добро пожаловать!',
        user: user,
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

      final users = _getStoredUsers();
      final user = users.cast<User?>().firstWhere(
        (user) => user?.email == email.trim().toLowerCase(),
        orElse: () => null,
      );

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
      _updateUser(updatedUser);

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

      await _clearStoredSession();
      _currentUser = null;
      _currentSessionToken = null;

      print('✅ Выход выполнен');
    } catch (e) {
      print('❌ Ошибка при выходе: $e');
    }
  }

  // Смена пароля
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        message: 'Пользователь не авторизован',
      );
    }

    try {
      // Проверка текущего пароля
      if (!_verifyPassword(currentPassword, _currentUser!.passwordHash)) {
        return AuthResult(
          success: false,
          message: 'Неверный текущий пароль',
        );
      }

      // Валидация нового пароля
      if (newPassword.length < 6) {
        return AuthResult(
          success: false,
          message: 'Новый пароль должен содержать минимум 6 символов',
        );
      }

      // Обновление пароля
      final newPasswordHash = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(passwordHash: newPasswordHash);
      
      _updateUser(updatedUser);
      _currentUser = updatedUser;

      // Создание новой сессии
      await _createSession(_currentUser!);

      return AuthResult(
        success: true,
        message: 'Пароль успешно изменен',
        user: _currentUser,
      );

    } catch (e) {
      print('❌ Ошибка смены пароля: $e');
      return AuthResult(
        success: false,
        message: 'Произошла ошибка при смене пароля',
      );
    }
  }

  // Обновление профиля
  Future<AuthResult> updateProfile({
    String? name,
    String? phone,
  }) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        message: 'Пользователь не авторизован',
      );
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name?.trim() ?? _currentUser!.name,
        phone: phone?.trim() ?? _currentUser!.phone,
      );

      _updateUser(updatedUser);
      _currentUser = updatedUser;

      return AuthResult(
        success: true,
        message: 'Профиль обновлен',
        user: _currentUser,
      );

    } catch (e) {
      print('❌ Ошибка обновления профиля: $e');
      return AuthResult(
        success: false,
        message: 'Произошла ошибка при обновлении профиля',
      );
    }
  }

  // Получение статистики пользователя
  Future<Map<String, dynamic>> getUserStats() async {
    if (_currentUser == null) return {};

    try {
      final users = _getStoredUsers();
      
      return {
        'user_id': _currentUser!.id,
        'loyalty_points': _currentUser!.loyaltyPoints,
        'member_since': _currentUser!.createdAt,
        'last_login': _currentUser!.lastLoginAt,
        'total_users': users.length,
      };
    } catch (e) {
      print('❌ Ошибка получения статистики: $e');
      return {};
    }
  }

  // Приватные методы
  List<User> _getStoredUsers() {
    try {
      final usersData = html.window.localStorage[_usersKey];
      
      if (usersData != null) {
        final List<dynamic> usersList = jsonDecode(usersData);
        return usersList.map((userData) => User.fromJson(userData)).toList();
      }
    } catch (e) {
      print('❌ Ошибка чтения пользователей: $e');
    }
    return [];
  }

  void _saveUsers(List<User> users) {
    try {
      final usersData = jsonEncode(users.map((user) => user.toLocalStorageJson()).toList());
      html.window.localStorage[_usersKey] = usersData;
    } catch (e) {
      print('❌ Ошибка сохранения пользователей: $e');
    }
  }

  void _updateUser(User updatedUser) {
    final users = _getStoredUsers();
    final index = users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      _saveUsers(users);
    }
  }

  Future<void> _createSession(User user) async {
    try {
      // Генерация токена сессии
      final sessionToken = _generateSessionToken();

      // Сохранение в LocalStorage
      html.window.localStorage[_sessionKey] = sessionToken;
      html.window.localStorage[_currentUserKey] = jsonEncode(user.toJson());

      _currentUser = user;
      _currentSessionToken = sessionToken;

      print('✅ Сессия создана для ${user.name}');
    } catch (e) {
      print('❌ Ошибка создания сессии: $e');
    }
  }

  Future<void> _clearStoredSession() async {
    html.window.localStorage.remove(_sessionKey);
    html.window.localStorage.remove(_currentUserKey);
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
    return base64Encode(bytes);
  }

  int _generateUserId(List<User> existingUsers) {
    if (existingUsers.isEmpty) return 1;
    return existingUsers.map((u) => u.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
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

    return AuthResult(success: true, message: 'Данные корректны'); // Added missing message parameter
  }
}
