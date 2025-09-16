#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Быстрая проверка таблицы заказов
"""

import sqlite3

def check_orders_table():
    print("📦 ТАБЛИЦА ЗАКАЗОВ В БД")
    print("=" * 50)
    
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("🔍 СТРУКТУРА ТАБЛИЦЫ orders:")
        cursor.execute("PRAGMA table_info(orders)")
        columns = cursor.fetchall()
        for col in columns:
            print(f"   {col[1]} ({col[2]})")
        
        print(f"\n📊 КОЛИЧЕСТВО ЗАКАЗОВ: {cursor.execute('SELECT COUNT(*) FROM orders').fetchone()[0]}")
        
        print("\n📋 ПОСЛЕДНИЕ 5 ЗАКАЗОВ:")
        cursor.execute("SELECT * FROM orders ORDER BY id DESC LIMIT 5")
        orders = cursor.fetchall()
        
        if orders:
            column_names = [description[0] for description in cursor.description]
            print(f"   Колонки: {column_names}")
            print()
            
            for order in orders:
                order_dict = dict(zip(column_names, order))
                print(f"   Заказ #{order_dict['id']}:")
                print(f"      user_id: {order_dict['user_id']}")
                print(f"      phone: {order_dict.get('phone', 'НЕТ')}")
                print(f"      delivery_address: {order_dict.get('delivery_address', 'НЕТ')}")
                print(f"      payment_method: {order_dict.get('payment_method', 'НЕТ')}")
                print(f"      status: {order_dict.get('status', 'НЕТ')}")
                print(f"      total_price: {order_dict.get('total_price', 'НЕТ')}")
                print(f"      comment: {order_dict.get('comment', 'НЕТ')}")
                print(f"      created_at: {order_dict.get('created_at', 'НЕТ')}")
                print()
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_orders_table()

