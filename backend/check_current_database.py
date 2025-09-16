#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки текущей базы данных
"""

import sqlite3

def check_current_database():
    print("🔍 ПРОВЕРКА ТЕКУЩЕЙ БАЗЫ ДАННЫХ")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("📊 СТАТИСТИКА БАЗЫ ДАННЫХ:")
        
        # Проверяем роллы
        cursor.execute("SELECT COUNT(*) FROM rolls")
        rolls_count = cursor.fetchone()[0]
        print(f"🍣 Роллы: {rolls_count}")
        
        if rolls_count > 0:
            cursor.execute("SELECT id, name, sale_price, image_url FROM rolls LIMIT 5")
            sample_rolls = cursor.fetchall()
            print("   📝 Примеры роллов:")
            for roll in sample_rolls:
                print(f"      ID {roll[0]}: {roll[1]} - {roll[2]} сом - {roll[3][:50]}...")
        
        # Проверяем сеты
        cursor.execute("SELECT COUNT(*) FROM sets")
        sets_count = cursor.fetchone()[0]
        print(f"\n🍱 Сеты: {sets_count}")
        
        if sets_count > 0:
            cursor.execute("SELECT id, name, set_price, image_url FROM sets LIMIT 5")
            sample_sets = cursor.fetchall()
            print("   📝 Примеры сетов:")
            for set_item in sample_sets:
                print(f"      ID {set_item[0]}: {set_item[1]} - {set_item[2]} сом - {set_item[3][:50]}...")
        
        # Проверяем заказы
        cursor.execute("SELECT COUNT(*) FROM orders")
        orders_count = cursor.fetchone()[0]
        print(f"\n📦 Заказы: {orders_count}")
        
        if orders_count > 0:
            cursor.execute("SELECT id, user_id, total_price, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5")
            sample_orders = cursor.fetchall()
            print("   📝 Последние заказы:")
            for order in sample_orders:
                print(f"      ID {order[0]}: Пользователь {order[1]} - {order[2]} сом - {order[3]} - {order[4]}")
        
        # Проверяем пользователей
        cursor.execute("SELECT COUNT(*) FROM users")
        users_count = cursor.fetchone()[0]
        print(f"\n👥 Пользователи: {users_count}")
        
        # Проверяем шеф-повара
        cursor.execute("SELECT id, name, email, is_admin FROM users WHERE is_admin = 1")
        chefs = cursor.fetchall()
        print(f"👨‍🍳 Шеф-повары: {len(chefs)}")
        for chef in chefs:
            print(f"   ID {chef[0]}: {chef[1]} ({chef[2]}) - Админ: {chef[3]}")
        
        # Проверяем ингредиенты
        cursor.execute("SELECT COUNT(*) FROM ingredients")
        ingredients_count = cursor.fetchone()[0]
        print(f"\n🥢 Ингредиенты: {ingredients_count}")
        
        conn.close()
        
        print("\n✅ ПРОБЛЕМЫ ДЛЯ ИСПРАВЛЕНИЯ:")
        if rolls_count == 0:
            print("❌ Нет роллов в базе")
        if sets_count == 0:
            print("❌ Нет сетов в базе")
        if orders_count == 0:
            print("❌ Нет заказов в базе")
        if len(chefs) == 0:
            print("❌ Нет шеф-повара в базе")
        
        print("\n📋 ПЛАН ДЕЙСТВИЙ:")
        print("1. Проверить, почему роллы и сеты не отображаются во фронтенде")
        print("2. Убедиться, что шеф-повар может видеть заказы")
        print("3. Исправить связь фронтенда с бэкендом")
        
    except Exception as e:
        print(f"❌ Ошибка проверки базы данных: {e}")

if __name__ == "__main__":
    check_current_database()

