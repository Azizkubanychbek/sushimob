#!/usr/bin/env python3
"""Скрипт для проверки структуры базы данных"""

import sqlite3
import os

def check_database():
    db_path = 'backend/instance/sushi_express.db'
    
    if not os.path.exists(db_path):
        print(f"❌ База данных не найдена: {db_path}")
        return
        
    print(f"✅ База данных найдена: {db_path}")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("\n" + "="*50)
        print("📋 ТАБЛИЦЫ В БАЗЕ ДАННЫХ")
        print("="*50)
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        for table in tables:
            print(f"📁 {table[0]}")
        
        print("\n" + "="*50)
        print("🍣 РОЛЛЫ (первые 5)")
        print("="*50)
        cursor.execute('SELECT id, name, description, cost_price, sale_price FROM rolls LIMIT 5')
        rolls = cursor.fetchall()
        for roll in rolls:
            print(f"🍣 ID: {roll[0]}, Name: {roll[1]}, Desc: {roll[2]}, Cost: {roll[3]}₽, Sale: {roll[4]}₽")
        
        print("\n" + "="*50)
        print("🍱 СЕТЫ (первые 5)")
        print("="*50)
        cursor.execute('SELECT id, name, description, cost_price, sale_price, discount_percent FROM sets LIMIT 5')
        sets = cursor.fetchall()
        for set_item in sets:
            print(f"🍱 ID: {set_item[0]}, Name: {set_item[1]}, Desc: {set_item[2]}, Cost: {set_item[3]}₽, Sale: {set_item[4]}₽, Discount: {set_item[5]}%")
        
        print("\n" + "="*50)
        print("🥢 СОСТАВ СЕТОВ (первые 10)")
        print("="*50)
        cursor.execute('SELECT sr.set_id, s.name as set_name, sr.roll_id, r.name as roll_name, sr.quantity FROM set_rolls sr LEFT JOIN sets s ON sr.set_id = s.id LEFT JOIN rolls r ON sr.roll_id = r.id LIMIT 10')
        set_compositions = cursor.fetchall()
        for comp in set_compositions:
            print(f"🥢 Set: {comp[1]} (ID: {comp[0]}) -> Roll: {comp[3]} (ID: {comp[2]}) x{comp[4]}")
        
        print("\n" + "="*50)
        print("🧄 РЕЦЕПТУРЫ РОЛЛОВ (первые 10)")
        print("="*50)
        cursor.execute('SELECT ri.roll_id, r.name as roll_name, ri.ingredient_id, i.name as ingredient_name, ri.amount_per_roll FROM roll_ingredients ri LEFT JOIN rolls r ON ri.roll_id = r.id LEFT JOIN ingredients i ON ri.ingredient_id = i.id LIMIT 10')
        roll_recipes = cursor.fetchall()
        for recipe in roll_recipes:
            print(f"🧄 Roll: {recipe[1]} (ID: {recipe[0]}) -> Ingredient: {recipe[3]} (ID: {recipe[2]}) x{recipe[4]}")
        
        print("\n" + "="*50)
        print("📊 СТАТИСТИКА")
        print("="*50)
        cursor.execute('SELECT COUNT(*) FROM rolls')
        rolls_count = cursor.fetchone()[0]
        print(f"🍣 Всего роллов: {rolls_count}")
        
        cursor.execute('SELECT COUNT(*) FROM sets')
        sets_count = cursor.fetchone()[0]
        print(f"🍱 Всего сетов: {sets_count}")
        
        cursor.execute('SELECT COUNT(*) FROM ingredients')
        ingredients_count = cursor.fetchone()[0]
        print(f"🧄 Всего ингредиентов: {ingredients_count}")
        
        cursor.execute('SELECT COUNT(*) FROM set_rolls')
        set_compositions_count = cursor.fetchone()[0]
        print(f"🥢 Записей состава сетов: {set_compositions_count}")
        
        cursor.execute('SELECT COUNT(*) FROM roll_ingredients')
        roll_recipes_count = cursor.fetchone()[0]
        print(f"🧄 Записей рецептур роллов: {roll_recipes_count}")
        
        # Проверяем, есть ли у роллов рецептуры
        print("\n" + "="*50)
        print("🔍 РОЛЛЫ БЕЗ РЕЦЕПТУР")
        print("="*50)
        cursor.execute('SELECT r.id, r.name FROM rolls r LEFT JOIN roll_ingredients ri ON r.id = ri.roll_id WHERE ri.roll_id IS NULL')
        rolls_without_recipes = cursor.fetchall()
        if rolls_without_recipes:
            print("❌ Роллы без рецептур:")
            for roll in rolls_without_recipes:
                print(f"   🍣 ID: {roll[0]}, Name: {roll[1]}")
        else:
            print("✅ У всех роллов есть рецептуры")
        
        # Проверяем, есть ли у сетов состав
        print("\n" + "="*50)
        print("🔍 СЕТЫ БЕЗ СОСТАВА")
        print("="*50)
        cursor.execute('SELECT s.id, s.name FROM sets s LEFT JOIN set_rolls sr ON s.id = sr.set_id WHERE sr.set_id IS NULL')
        sets_without_composition = cursor.fetchall()
        if sets_without_composition:
            print("❌ Сеты без состава:")
            for set_item in sets_without_composition:
                print(f"   🍱 ID: {set_item[0]}, Name: {set_item[1]}")
        else:
            print("✅ У всех сетов есть состав")
        
    except Exception as e:
        print(f"❌ Ошибка при проверке базы данных: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    check_database()
