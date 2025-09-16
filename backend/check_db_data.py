#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3

def check_database():
    print("🔍 ПРОВЕРКА БАЗЫ ДАННЫХ")
    print("=" * 50)
    
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    # Проверяем количество записей
    cursor.execute('SELECT COUNT(*) FROM ingredients')
    ingredients_count = cursor.fetchone()[0]
    print(f"📦 Ингредиентов: {ingredients_count}")
    
    cursor.execute('SELECT COUNT(*) FROM rolls')
    rolls_count = cursor.fetchone()[0]
    print(f"🍣 Роллов: {rolls_count}")
    
    cursor.execute('SELECT COUNT(*) FROM sets')
    sets_count = cursor.fetchone()[0]
    print(f"🍱 Сетов: {sets_count}")
    
    # Проверяем первые несколько записей
    print("\n📋 ПЕРВЫЕ 3 РОЛЛА:")
    cursor.execute('SELECT id, name, description, sale_price, image_url FROM rolls LIMIT 3')
    rolls = cursor.fetchall()
    for roll in rolls:
        print(f"   ID: {roll[0]}, Название: {roll[1]}, Описание: {roll[2][:50] if roll[2] else 'Нет'}, Цена: {roll[3]}, Фото: {roll[4] or 'Нет'}")
    
    print("\n📋 ПЕРВЫЕ 3 СЕТА:")
    cursor.execute('SELECT id, name, description, set_price, image_url FROM sets LIMIT 3')
    sets = cursor.fetchall()
    for set_item in sets:
        print(f"   ID: {set_item[0]}, Название: {set_item[1]}, Описание: {set_item[2][:50] if set_item[2] else 'Нет'}, Цена: {set_item[3]}, Фото: {set_item[4] or 'Нет'}")
    
    print("\n📋 ПЕРВЫЕ 3 ИНГРЕДИЕНТА:")
    cursor.execute('SELECT id, name, cost_per_unit, price_per_unit, stock_quantity, unit FROM ingredients LIMIT 3')
    ingredients = cursor.fetchall()
    for ingredient in ingredients:
        print(f"   ID: {ingredient[0]}, Название: {ingredient[1]}, Стоимость: {ingredient[2]}, Цена: {ingredient[3]}, Остаток: {ingredient[4]} {ingredient[5]}")
    
    conn.close()

if __name__ == "__main__":
    check_database()
