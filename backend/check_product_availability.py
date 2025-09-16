#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3

def check_product_availability():
    print("🔍 ПРОВЕРКА НАЛИЧИЯ ТОВАРОВ")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("📋 ПРОВЕРКА НАЛИЧИЯ ИНГРЕДИЕНТОВ")
        print("-" * 40)
        
        # Проверяем ингредиенты с нулевым количеством
        cursor.execute("""
            SELECT name, stock_quantity, unit 
            FROM ingredients 
            WHERE stock_quantity <= 0 OR stock_quantity IS NULL
            ORDER BY name
        """)
        low_ingredients = cursor.fetchall()
        
        if low_ingredients:
            print("❌ Ингредиенты с нулевым или отсутствующим количеством:")
            for ingredient in low_ingredients:
                print(f"  - {ingredient[0]}: {ingredient[1]} {ingredient[2]}")
        else:
            print("✅ Все ингредиенты в наличии")
        
        print("\n🔍 ПРОВЕРКА ДОСТУПНОСТИ РОЛЛОВ")
        print("-" * 40)
        
        # Проверяем роллы с недостающими ингредиентами
        cursor.execute("""
            SELECT DISTINCT r.name as roll_name, r.id, r.sale_price
            FROM rolls r
            JOIN roll_ingredients ri ON r.id = ri.roll_id
            JOIN ingredients i ON ri.ingredient_id = i.id
            WHERE i.stock_quantity <= 0 OR i.stock_quantity IS NULL
            ORDER BY r.name
        """)
        unavailable_rolls = cursor.fetchall()
        
        if unavailable_rolls:
            print("❌ Роллы недоступные из-за недостающих ингредиентов:")
            for roll in unavailable_rolls:
                print(f"  - {roll[0]} (ID: {roll[1]}) - {roll[2]} сом")
        else:
            print("✅ Все роллы доступны")
        
        print("\n🔍 ПРОВЕРКА ДОСТУПНОСТИ СЕТОВ")
        print("-" * 40)
        
        # Проверяем сеты с недоступными роллами
        cursor.execute("""
            SELECT DISTINCT s.name as set_name, s.id, s.set_price
            FROM sets s
            JOIN set_rolls sr ON s.id = sr.set_id
            JOIN rolls r ON sr.roll_id = r.id
            JOIN roll_ingredients ri ON r.id = ri.roll_id
            JOIN ingredients i ON ri.ingredient_id = i.id
            WHERE i.stock_quantity <= 0 OR i.stock_quantity IS NULL
            ORDER BY s.name
        """)
        unavailable_sets = cursor.fetchall()
        
        if unavailable_sets:
            print("❌ Сеты недоступные из-за недостающих ингредиентов:")
            for set_item in unavailable_sets:
                print(f"  - {set_item[0]} (ID: {set_item[1]}) - {set_item[2]} сом")
        else:
            print("✅ Все сеты доступны")
        
        print("\n📊 СТАТИСТИКА ИНГРЕДИЕНТОВ")
        print("-" * 40)
        
        # Общее количество ингредиентов
        cursor.execute("SELECT COUNT(*) FROM ingredients")
        total_ingredients = cursor.fetchone()[0]
        print(f"🥬 Всего ингредиентов: {total_ingredients}")
        
        # Ингредиенты в наличии
        cursor.execute("SELECT COUNT(*) FROM ingredients WHERE stock_quantity > 0")
        available_ingredients = cursor.fetchone()[0]
        print(f"✅ Ингредиентов в наличии: {available_ingredients}")
        
        # Ингредиенты на исходе (меньше 100)
        cursor.execute("SELECT COUNT(*) FROM ingredients WHERE stock_quantity > 0 AND stock_quantity < 100")
        low_stock = cursor.fetchone()[0]
        print(f"⚠️ Ингредиентов на исходе (<100): {low_stock}")
        
        print("\n📋 ПРИМЕРЫ ИНГРЕДИЕНТОВ НА ИСХОДЕ")
        print("-" * 40)
        
        cursor.execute("""
            SELECT name, stock_quantity, unit 
            FROM ingredients 
            WHERE stock_quantity > 0 AND stock_quantity < 100
            ORDER BY stock_quantity ASC
            LIMIT 10
        """)
        low_stock_ingredients = cursor.fetchall()
        
        if low_stock_ingredients:
            for ingredient in low_stock_ingredients:
                print(f"  - {ingredient[0]}: {ingredient[1]} {ingredient[2]}")
        else:
            print("  Все ингредиенты в достаточном количестве")
        
        conn.close()
        print("\n✅ Проверка завершена!")
        
    except Exception as e:
        print(f"❌ Ошибка при проверке: {e}")

if __name__ == "__main__":
    check_product_availability()

