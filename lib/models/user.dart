class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final int loyaltyPoints;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.loyaltyPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'loyalty_points': loyaltyPoints,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      passwordHash: map['password_hash'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at']) 
          : null,
      isActive: (map['is_active'] ?? 1) == 1,
      loyaltyPoints: map['loyalty_points']?.toInt() ?? 0,
    );
  }

  // Для совместимости с ApiService
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toInt(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      passwordHash: json['password_hash'] ?? '', // Теперь может читать хеш из localStorage
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      isActive: json['is_active'] ?? true,
      loyaltyPoints: json['loyalty_points']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
      'loyalty_points': loyaltyPoints,
    };
  }

  // Для сохранения в localStorage (включает хеш пароля)
  Map<String, dynamic> toLocalStorageJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
      'loyalty_points': loyaltyPoints,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    int? loyaltyPoints,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone, loyaltyPoints: $loyaltyPoints)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode;
  }
}