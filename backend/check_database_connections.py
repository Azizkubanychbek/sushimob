#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки связей в базе данных между пользователями, заказами и шеф-поваром
"""

import sqlite3

def check_database_connections():
    print("🔍 ПРОВЕРКА СВЯЗЕЙ В БАЗЕ ДАННЫХ")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("👥 ПРОВЕРКА ПОЛЬЗОВАТЕЛЕЙ")
        print("-" * 30)
        
        # Проверяем всех пользователей
        cursor.execute("SELECT id, email, name, is_admin FROM users")
        users = cursor.fetchall()
        print(f"📊 Всего пользователей: {len(users)}")
        
        for user in users:
            admin_status = "👨‍💼 АДМИН" if user[3] else "👤 Обычный"
            print(f"  {admin_status} ID:{user[0]} - {user[1]} ({user[2]})")
        
        print("\n📦 ПРОВЕРКА ЗАКАЗОВ")
        print("-" * 30)
        
        # Проверяем заказы
        cursor.execute("SELECT COUNT(*) FROM orders")
        total_orders = cursor.fetchone()[0]
        print(f"📊 Всего заказов: {total_orders}")
        
        # Проверяем последние 5 заказов
        cursor.execute("""
            SELECT o.id, o.user_id, u.email, u.name, o.total_price, o.status, o.created_at
            FROM orders o
            JOIN users u ON o.user_id = u.id
            ORDER BY o.created_at DESC
            LIMIT 5
        """)
        recent_orders = cursor.fetchall()
        
        print("📋 Последние 5 заказов:")
        for order in recent_orders:
            print(f"  Заказ #{order[0]} от {order[2]} ({order[3]}) - {order[4]} сом, статус: {order[5]}")
        
        print("\n🔗 ПРОВЕРКА СВЯЗЕЙ ЗАКАЗОВ С ПОЛЬЗОВАТЕЛЯМИ")
        print("-" * 50)
        
        # Проверяем, есть ли заказы без пользователей
        cursor.execute("""
            SELECT o.id, o.user_id 
            FROM orders o
            LEFT JOIN users u ON o.user_id = u.id
            WHERE u.id IS NULL
        """)
        orphan_orders = cursor.fetchall()
        
        if orphan_orders:
            print(f"❌ Найдены заказы без пользователей: {len(orphan_orders)}")
            for order in orphan_orders:
                print(f"  Заказ #{order[0]} ссылается на несуществующего пользователя ID:{order[1]}")
        else:
            print("✅ Все заказы связаны с существующими пользователями")
        
        print("\n👨‍🍳 ПРОВЕРКА ШЕФ-ПОВАРА")
        print("-" * 30)
        
        # Ищем шеф-повара
        cursor.execute("SELECT id, email, name, is_admin FROM users WHERE email = 'chef@sushiroll.com'")
        chef = cursor.fetchone()
        
        if chef:
            print(f"✅ Шеф-повар найден: {chef[2]} ({chef[1]})")
            print(f"   ID: {chef[0]}, Админ: {'Да' if chef[3] else 'Нет'}")
        else:
            print("❌ Шеф-повар не найден!")
            print("🔧 Создаем шеф-повара...")
            
            # Создаем шеф-повара
            cursor.execute("""
                INSERT INTO users (email, name, phone, password_hash, is_admin, created_at)
                VALUES ('chef@sushiroll.com', 'Шеф-повар', '+996555123456', 
                        'pbkdf2:sha256:600000$abc123$hash', 1, datetime('now'))
            """)
            conn.commit()
            print("✅ Шеф-повар создан!")
        
        print("\n📊 СТАТИСТИКА ЗАКАЗОВ ПО ПОЛЬЗОВАТЕЛЯМ")
        print("-" * 40)
        
        cursor.execute("""
            SELECT u.email, u.name, COUNT(o.id) as order_count, 
                   SUM(o.total_price) as total_spent
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
            GROUP BY u.id, u.email, u.name
            ORDER BY order_count DESC
        """)
        user_stats = cursor.fetchall()
        
        for stat in user_stats:
            print(f"  {stat[0]} ({stat[1]}): {stat[2]} заказов, {stat[3] or 0} сом")
        
        print("\n🔍 ПРОВЕРКА ТАБЛИЦЫ ORDER_ITEMS")
        print("-" * 40)
        
        cursor.execute("SELECT COUNT(*) FROM order_items")
        order_items_count = cursor.fetchone()[0]
        print(f"📦 Всего элементов заказов: {order_items_count}")
        
        # Проверяем последние элементы заказов
        cursor.execute("""
            SELECT oi.id, oi.order_id, oi.item_type, oi.item_id, oi.quantity, oi.unit_price
            FROM order_items oi
            ORDER BY oi.id DESC
            LIMIT 5
        """)
        recent_items = cursor.fetchall()
        
        print("📋 Последние 5 элементов заказов:")
        for item in recent_items:
            print(f"  Элемент #{item[0]} в заказе #{item[1]}: {item[2]} ID:{item[3]} x{item[4]} = {item[5]} сом")
        
        conn.close()
        print("\n✅ Проверка связей завершена!")
        
    except Exception as e:
        print(f"❌ Ошибка при проверке: {e}")

if __name__ == "__main__":
    check_database_connections()

