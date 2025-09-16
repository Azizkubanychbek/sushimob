#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки модели Order
"""

import sqlite3

def check_order_model():
    print("🔍 ПРОВЕРКА МОДЕЛИ ORDER")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        # Проверяем структуру таблицы orders
        print("📋 Структура таблицы orders:")
        cursor.execute("PRAGMA table_info(orders)")
        columns = cursor.fetchall()
        for col in columns:
            print(f"   {col[1]} ({col[2]})")
        
        # Проверяем пример заказа
        print("\n📋 Пример заказа:")
        cursor.execute("SELECT * FROM orders LIMIT 1")
        order = cursor.fetchone()
        
        if order:
            column_names = [description[0] for description in cursor.description]
            print(f"   Колонки: {column_names}")
            print(f"   Данные: {dict(zip(column_names, order))}")
        else:
            print("   Заказов не найдено")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_order_model()

