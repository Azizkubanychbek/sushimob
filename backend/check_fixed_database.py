#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки исправленной базы данных
"""

import sqlite3
import os

def check_fixed_database():
    print("🔍 ПРОВЕРКА ИСПРАВЛЕННОЙ БАЗЫ ДАННЫХ")
    print("=" * 50)
    
    db_path = 'sushi_express.db'
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Проверяем роллы
        print("🍣 Роллы в базе данных:")
        cursor.execute("SELECT id, name, sale_price FROM rolls LIMIT 10")
        rolls = cursor.fetchall()
        for roll in rolls:
            print(f"   ID {roll[0]}: {roll[1]} - {roll[2]} сом")
        
        print(f"\n📊 Всего роллов: {len(rolls)}")
        
        # Проверяем сеты
        print("\n🍱 Сеты в базе данных:")
        cursor.execute("SELECT id, name, sale_price FROM sets LIMIT 10")
        sets = cursor.fetchall()
        for set_item in sets:
            print(f"   ID {set_item[0]}: {set_item[1]} - {set_item[2]} сом")
        
        print(f"\n📊 Всего сетов: {len(sets)}")
        
        # Проверяем ингредиенты
        print("\n🥢 Ингредиенты в базе данных:")
        cursor.execute("SELECT id, name, stock_quantity FROM ingredients LIMIT 10")
        ingredients = cursor.fetchall()
        for ing in ingredients:
            print(f"   ID {ing[0]}: {ing[1]} - {ing[2]} шт")
        
        print(f"\n📊 Всего ингредиентов: {len(ingredients)}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_fixed_database()

