#!/usr/bin/env python3
"""
Скрипт для инициализации базы данных с таблицами
"""

import sqlite3
import hashlib
import secrets
import string

def generate_referral_code():
    """Генерирует случайный реферальный код"""
    return ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(8))

def hash_password(password):
    """Хеширует пароль"""
    return hashlib.sha256(password.encode()).hexdigest()

def init_database():
    """Инициализирует базу данных"""
    
    # Подключение к базе данных
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    try:
        print("🏗️ Создание таблиц...")
        
        # Таблица пользователей
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                phone TEXT,
                password_hash TEXT NOT NULL,
                location TEXT,
                loyalty_points INTEGER DEFAULT 0,
                bonus_points INTEGER DEFAULT 0,
                referral_code TEXT UNIQUE,
                referred_by TEXT,
                is_active BOOLEAN DEFAULT 1,
                is_admin BOOLEAN DEFAULT 0,
                cart TEXT DEFAULT '[]',
                favorites TEXT DEFAULT '{}',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login_at TIMESTAMP
            )
        """)
        
        # Таблица роллов
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS rolls (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                price REAL NOT NULL,
                image_url TEXT,
                ingredients TEXT,
                category TEXT,
                is_popular BOOLEAN DEFAULT 0,
                is_available BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Таблица сетов
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                price REAL NOT NULL,
                image_url TEXT,
                rolls_included TEXT,
                is_popular BOOLEAN DEFAULT 0,
                is_available BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Таблица заказов
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                user_name TEXT NOT NULL,
                user_phone TEXT NOT NULL,
                user_email TEXT NOT NULL,
                delivery_address TEXT NOT NULL,
                delivery_latitude REAL NOT NULL,
                delivery_longitude REAL NOT NULL,
                total_amount REAL NOT NULL,
                status TEXT DEFAULT 'pending',
                notes TEXT,
                delivery_instructions TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
        """)
        
        # Таблица элементов заказа
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS order_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                order_id INTEGER NOT NULL,
                item_type TEXT NOT NULL,
                item_id INTEGER NOT NULL,
                item_name TEXT NOT NULL,
                item_image TEXT,
                quantity INTEGER NOT NULL,
                price REAL NOT NULL,
                total_price REAL NOT NULL,
                FOREIGN KEY (order_id) REFERENCES orders (id)
            )
        """)
        
        # Таблица ингредиентов
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS ingredients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                current_stock REAL NOT NULL,
                unit TEXT NOT NULL,
                min_stock REAL DEFAULT 0,
                cost_per_unit REAL DEFAULT 0,
                supplier TEXT,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        print("✅ Таблицы созданы!")
        
        # Создаем пользователя шеф-повара
        print("👨‍🍳 Создание пользователя шеф-повара...")
        
        chef_password = "chef123"
        hashed_password = hash_password(chef_password)
        referral_code = generate_referral_code()
        
        cursor.execute("""
            INSERT OR IGNORE INTO users (
                name, email, phone, password_hash, 
                is_admin, is_active, referral_code,
                created_at, last_login_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        """, (
            "Шеф-повар",
            "chef@sushiroll.com", 
            "996700123456",
            hashed_password,
            True,  # is_admin = True
            True,  # is_active = True
            referral_code
        ))
        
        chef_id = cursor.lastrowid
        print(f"✅ Пользователь шеф-повара создан с ID: {chef_id}")
        print(f"📧 Email: chef@sushiroll.com")
        print(f"🔑 Пароль: chef123")
        print(f"🎫 Реферальный код: {referral_code}")
        
        # Создаем тестового пользователя
        print("👤 Создание тестового пользователя...")
        
        test_password = "test123"
        test_hashed_password = hash_password(test_password)
        test_referral_code = generate_referral_code()
        
        cursor.execute("""
            INSERT OR IGNORE INTO users (
                name, email, phone, password_hash, 
                is_admin, is_active, referral_code,
                created_at, last_login_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        """, (
            "Тестовый пользователь",
            "test@sushiroll.com", 
            "996700654321",
            test_hashed_password,
            False,  # is_admin = False
            True,   # is_active = True
            test_referral_code
        ))
        
        print(f"✅ Тестовый пользователь создан")
        print(f"📧 Email: test@sushiroll.com")
        print(f"🔑 Пароль: test123")
        
        # Добавляем базовые ингредиенты
        print("🥘 Добавление базовых ингредиентов...")
        
        ingredients = [
            ("Рис для суши", 15.0, "кг", 5.0, 150.0, "Поставщик риса"),
            ("Лосось", 8.0, "кг", 2.0, 800.0, "Рыбный поставщик"),
            ("Авокадо", 12.0, "шт", 5.0, 50.0, "Фруктовый поставщик"),
            ("Сыр Филадельфия", 6.0, "упаковок", 2.0, 300.0, "Молочный поставщик"),
            ("Нори", 50.0, "листов", 10.0, 20.0, "Морской поставщик"),
            ("Васаби", 3.0, "тюбиков", 1.0, 150.0, "Специи поставщик"),
            ("Имбирь", 2.0, "банок", 1.0, 100.0, "Консервы поставщик"),
        ]
        
        for name, stock, unit, min_stock, cost, supplier in ingredients:
            cursor.execute("""
                INSERT OR IGNORE INTO ingredients (
                    name, current_stock, unit, min_stock, cost_per_unit, supplier
                ) VALUES (?, ?, ?, ?, ?, ?)
            """, (name, stock, unit, min_stock, cost, supplier))
        
        print("✅ Ингредиенты добавлены!")
        
        # Сохраняем изменения
        conn.commit()
        
        print("\n🎉 База данных успешно инициализирована!")
        print("\n📋 Созданные таблицы:")
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        for table in tables:
            print(f"   - {table[0]}")
        
        print("\n👥 Пользователи:")
        cursor.execute("SELECT id, name, email, is_admin FROM users;")
        users = cursor.fetchall()
        for user in users:
            print(f"   - {user[1]} ({user[2]}) {'[АДМИН]' if user[3] else ''}")
        
        print("\n🥘 Ингредиенты:")
        cursor.execute("SELECT name, current_stock, unit FROM ingredients;")
        ingredients = cursor.fetchall()
        for ingredient in ingredients:
            print(f"   - {ingredient[0]}: {ingredient[1]} {ingredient[2]}")
        
    except sqlite3.Error as e:
        print(f"❌ Ошибка базы данных: {e}")
        conn.rollback()
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    print("🍣 Инициализация базы данных...")
    init_database()

