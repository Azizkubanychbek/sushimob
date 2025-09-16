#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки содержимого базы данных
"""

import sqlite3
import os

def check_database_content():
    print("🔍 ПРОВЕРКА СОДЕРЖИМОГО БАЗЫ ДАННЫХ")
    print("=" * 50)
    
    db_path = 'sushi_express.db'
    
    if not os.path.exists(db_path):
        print(f"❌ База данных не найдена: {db_path}")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Проверяем количество записей в каждой таблице
        tables = ['users', 'ingredients', 'rolls', 'sets', 'orders', 'order_items']
        
        for table in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                print(f"📊 {table}: {count} записей")
                
                if table == 'rolls' and count > 0:
                    print("   🍣 Примеры роллов:")
                    cursor.execute("SELECT id, name, price FROM rolls LIMIT 5")
                    rolls = cursor.fetchall()
                    for roll in rolls:
                        print(f"      ID {roll[0]}: {roll[1]} - {roll[2]} сом")
                
                elif table == 'sets' and count > 0:
                    print("   🍱 Примеры сетов:")
                    cursor.execute("SELECT id, name, price FROM sets LIMIT 5")
                    sets = cursor.fetchall()
                    for set_item in sets:
                        print(f"      ID {set_item[0]}: {set_item[1]} - {set_item[2]} сом")
                
                elif table == 'ingredients' and count > 0:
                    print("   🥢 Примеры ингредиентов:")
                    cursor.execute("SELECT id, name, stock_quantity FROM ingredients LIMIT 5")
                    ingredients = cursor.fetchall()
                    for ing in ingredients:
                        print(f"      ID {ing[0]}: {ing[1]} - {ing[2]} шт")
                
            except sqlite3.Error as e:
                print(f"❌ Ошибка при проверке таблицы {table}: {e}")
        
        # Проверяем структуру таблицы rolls
        print("\n🔍 Структура таблицы rolls:")
        cursor.execute("PRAGMA table_info(rolls)")
        columns = cursor.fetchall()
        for col in columns:
            print(f"   {col[1]} ({col[2]})")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка подключения к базе данных: {e}")

if __name__ == "__main__":
    check_database_content()

