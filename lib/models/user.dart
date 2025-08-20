class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String? location; // Добавляю локацию
  final int loyaltyPoints; // Возвращаю лоялити
  final String? favorites; // JSON строка с избранными
  final String passwordHash;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.location, // Добавляю локацию
    this.loyaltyPoints = 0, // Возвращаю лоялити
    this.favorites, // Добавляю избранное
    required this.passwordHash,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  // Копирование с изменениями для редактирования
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? location, // Добавляю локацию
    int? loyaltyPoints, // Возвращаю лоялити
    String? favorites, // Добавляю избранное
    String? passwordHash,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location, // Добавляю локацию
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints, // Возвращаю лоялити
      favorites: favorites ?? this.favorites, // Добавляю избранное
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location, // Добавляю локацию
      'loyalty_points': loyaltyPoints, // Возвращаю лоялити
      'favorites': favorites, // Добавляю избранное
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'], // Добавляю локацию
      loyaltyPoints: map['loyalty_points']?.toInt() ?? 0, // Возвращаю лоялити
      favorites: map['favorites'], // Добавляю избранное
      passwordHash: map['password_hash'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at']) 
          : null,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  // Для совместимости с ApiService
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toInt(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'], // Добавляю локацию
      loyaltyPoints: json['loyalty_points']?.toInt() ?? 0, // Возвращаю лоялити
      favorites: json['favorites'], // Добавляю избранное
      passwordHash: json['password_hash'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location, // Добавляю локацию
      'loyalty_points': loyaltyPoints, // Возвращаю лоялити
      'favorites': favorites, // Добавляю избранное
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Для сохранения в localStorage (включает хеш пароля)
  Map<String, dynamic> toLocalStorageJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location, // Добавляю локацию
      'loyalty_points': loyaltyPoints, // Возвращаю лоялити
      'favorites': favorites, // Добавляю избранное
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Для API (без хеша пароля)
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location, // Добавляю локацию
      'loyalty_points': loyaltyPoints, // Возвращаю лоялити
      'favorites': favorites, // Добавляю избранное
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone, location: $location, loyaltyPoints: $loyaltyPoints, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}