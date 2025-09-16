#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки структуры таблицы sets
"""

import sqlite3

def check_sets_structure():
    print("🔍 ПРОВЕРКА СТРУКТУРЫ ТАБЛИЦЫ SETS")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        # Проверяем структуру таблицы sets
        print("📋 Структура таблицы sets:")
        cursor.execute("PRAGMA table_info(sets)")
        columns = cursor.fetchall()
        for col in columns:
            print(f"   {col[1]} ({col[2]})")
        
        print("\n🍱 Сеты в базе данных:")
        cursor.execute("SELECT * FROM sets LIMIT 5")
        sets = cursor.fetchall()
        
        if sets:
            # Получаем названия колонок
            column_names = [description[0] for description in cursor.description]
            print(f"   Колонки: {column_names}")
            
            for set_item in sets:
                print(f"   {dict(zip(column_names, set_item))}")
        else:
            print("   Сетов не найдено")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_sets_structure()

