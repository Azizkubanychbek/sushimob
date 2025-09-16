#!/usr/bin/env python3
"""
Скрипт для создания пользователя шеф-повара
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

def create_chef_user():
    """Создает пользователя шеф-повара"""
    
    # Подключение к базе данных
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    try:
        # Проверяем, есть ли уже пользователь с email шеф-повара
        cursor.execute("SELECT id FROM users WHERE email = ?", ("chef@sushiroll.com",))
        existing_user = cursor.fetchone()
        
        if existing_user:
            print("❌ Пользователь шеф-повара уже существует!")
            return
        
        # Создаем пользователя шеф-повара
        chef_password = "chef123"  # Простой пароль для демо
        hashed_password = hash_password(chef_password)
        referral_code = generate_referral_code()
        
        cursor.execute("""
            INSERT INTO users (
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
        print(f"👑 Статус: Администратор")
        
        # Сохраняем изменения
        conn.commit()
        
        # Проверяем создание
        cursor.execute("SELECT * FROM users WHERE email = ?", ("chef@sushiroll.com",))
        user = cursor.fetchone()
        
        if user:
            print("\n📋 Информация о пользователе:")
            print(f"   ID: {user[0]}")
            print(f"   Имя: {user[1]}")
            print(f"   Email: {user[2]}")
            print(f"   Телефон: {user[3]}")
            print(f"   Админ: {'Да' if user[6] else 'Нет'}")
            print(f"   Активен: {'Да' if user[7] else 'Нет'}")
            print(f"   Реферальный код: {user[8]}")
            print(f"   Создан: {user[9]}")
        
    except sqlite3.Error as e:
        print(f"❌ Ошибка базы данных: {e}")
        conn.rollback()
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    print("🍣 Создание пользователя шеф-повара...")
    create_chef_user()
    print("\n🎉 Готово!")

