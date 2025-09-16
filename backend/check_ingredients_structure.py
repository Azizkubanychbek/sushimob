#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3

def check_ingredients_structure():
    print("🔍 ПРОВЕРКА СТРУКТУРЫ ТАБЛИЦЫ INGREDIENTS")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        # Получаем структуру таблицы ingredients
        cursor.execute("PRAGMA table_info(ingredients)")
        columns = cursor.fetchall()
        
        print("📊 Столбцы в таблице ingredients:")
        for col in columns:
            print(f"  - {col[1]} ({col[2]}) - {'NOT NULL' if col[3] else 'NULL'}")
        
        print("\n🔍 ПЕРВЫЕ 5 ИНГРЕДИЕНТОВ:")
        print("-" * 30)
        cursor.execute("SELECT * FROM ingredients LIMIT 5")
        ingredients = cursor.fetchall()
        
        for ingredient in ingredients:
            print(f"ID: {ingredient[0]}, Name: {ingredient[1]}")
            if len(ingredient) > 2:
                print(f"  Дополнительные поля: {ingredient[2:]}")
        
        # Проверяем, есть ли таблица ingredient_inventory или подобная
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%inventory%'")
        inventory_tables = cursor.fetchall()
        
        if inventory_tables:
            print(f"\n📦 Найдены таблицы инвентаря: {inventory_tables}")
        else:
            print("\n❌ Таблицы инвентаря не найдены")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_ingredients_structure()

