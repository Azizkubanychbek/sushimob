import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Для веб-платформы используем sqflite_ffi_web
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      // Для мобильных платформ используем sqflite_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sushiroll_express.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создание таблицы пользователей
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        loyalty_points INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Создание таблицы сессий
    await db.execute('''
      CREATE TABLE user_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_token TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы заказов
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        delivery_address TEXT,
        delivery_phone TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Создание таблицы элементов заказа
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_type TEXT NOT NULL, -- 'roll' или 'set'
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    print('🗄️ База данных создана успешно');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Логика обновления схемы БД при необходимости
    if (oldVersion < 2) {
      // Примеры миграций
      // await db.execute('ALTER TABLE users ADD COLUMN new_field TEXT');
    }
  }

  // CRUD операции для пользователей
  Future<int> insertUser(User user) async {
    final db = await database;
    try {
      final id = await db.insert('users', user.toMap());
      print('✅ Пользователь ${user.name} создан с ID: $id');
      return id;
    } catch (e) {
      print('❌ Ошибка создания пользователя: $e');
      rethrow;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isEmailTaken(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  Future<void> updateLastLogin(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> addLoyaltyPoints(int userId, int points) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE users SET loyalty_points = loyalty_points + ? WHERE id = ?',
      [points, userId],
    );
  }

  // Методы для сессий
  Future<int> createSession(int userId, String sessionToken, DateTime expiresAt) async {
    final db = await database;
    return await db.insert('user_sessions', {
      'user_id': userId,
      'session_token': sessionToken,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': 1,
    });
  }

  Future<Map<String, dynamic>?> getActiveSession(String sessionToken) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_sessions',
      where: 'session_token = ? AND is_active = 1 AND expires_at > ?',
      whereArgs: [sessionToken, DateTime.now().toIso8601String()],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> deactivateSession(String sessionToken) async {
    final db = await database;
    await db.update(
      'user_sessions',
      {'is_active': 0},
      where: 'session_token = ?',
      whereArgs: [sessionToken],
    );
  }

  Future<void> deactivateAllUserSessions(int userId) async {
    final db = await database;
    await db.update(
      'user_sessions',
      {'is_active': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Утилиты
  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('user_sessions');
    await db.delete('users');
    print('🗑️ Все таблицы очищены');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Метод для получения статистики
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    final activeSessionCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM user_sessions WHERE is_active = 1 AND expires_at > ?',
      [DateTime.now().toIso8601String()]
    )) ?? 0;
    final orderCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders')) ?? 0;

    return {
      'users': userCount,
      'active_sessions': activeSessionCount,
      'orders': orderCount,
    };
  }
}
