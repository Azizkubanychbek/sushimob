#!/usr/bin/env python3
"""Скрипт для исправления проблем с базой данных"""

import sqlite3
import os

def fix_database():
    db_path = 'sushi_express.db'
    
    if not os.path.exists(db_path):
        print(f"❌ База данных не найдена: {db_path}")
        return
    
    print(f"✅ Работаем с базой: {db_path}")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("\n🔍 ПРОВЕРЯЕМ ТЕКУЩЕЕ СОСТОЯНИЕ")
        print("="*50)
        
        # Проверяем количества
        cursor.execute('SELECT COUNT(*) FROM rolls')
        rolls_count = cursor.fetchone()[0]
        print(f"🍣 Роллов: {rolls_count}")
        
        cursor.execute('SELECT COUNT(*) FROM sets')
        sets_count = cursor.fetchone()[0]
        print(f"🍱 Сетов: {sets_count}")
        
        cursor.execute('SELECT COUNT(*) FROM ingredients')
        ingredients_count = cursor.fetchone()[0]
        print(f"🧄 Ингредиентов: {ingredients_count}")
        
        cursor.execute('SELECT COUNT(*) FROM roll_ingredients')
        roll_recipes_count = cursor.fetchone()[0]
        print(f"🧄 Рецептур роллов: {roll_recipes_count}")
        
        cursor.execute('SELECT COUNT(*) FROM set_rolls')
        set_compositions_count = cursor.fetchone()[0]
        print(f"🥢 Составов сетов: {set_compositions_count}")
        
        # 1. СОЗДАЕМ ТЕСТОВЫЕ ИНГРЕДИЕНТЫ ЕСЛИ ИХ НЕТ
        if ingredients_count == 0:
            print("\n🧄 СОЗДАЕМ БАЗОВЫЕ ИНГРЕДИЕНТЫ")
            print("="*50)
            
            test_ingredients = [
                ('Рис', 50.0, 'гр', 1000, 'основа'),
                ('Нори', 5.0, 'лист', 100, 'водоросли'),
                ('Лосось', 800.0, 'гр', 500, 'рыба'),
                ('Огурец', 150.0, 'гр', 200, 'овощи'),
                ('Авокадо', 300.0, 'шт', 50, 'овощи'),
                ('Сыр филадельфия', 600.0, 'гр', 300, 'молочные'),
                ('Икра тобико', 1500.0, 'гр', 100, 'икра'),
                ('Курица', 400.0, 'гр', 1000, 'мясо'),
                ('Угорь', 1200.0, 'гр', 200, 'рыба'),
                ('Кунжут', 800.0, 'гр', 100, 'семена')
            ]
            
            for name, cost, unit, stock, category in test_ingredients:
                cursor.execute('''
                    INSERT INTO ingredients (name, cost_per_unit, unit, stock_quantity, category)
                    VALUES (?, ?, ?, ?, ?)
                ''', (name, cost, unit, stock, category))
                print(f"  ✅ Добавлен ингредиент: {name}")
            
            conn.commit()
            
        # 2. СОЗДАЕМ РЕЦЕПТУРЫ ДЛЯ РОЛЛОВ БЕЗ НИХ
        print("\n🧄 СОЗДАЕМ РЕЦЕПТУРЫ ДЛЯ РОЛЛОВ")
        print("="*50)
        
        # Находим роллы без рецептур
        cursor.execute('''
            SELECT r.id, r.name 
            FROM rolls r 
            LEFT JOIN roll_ingredients ri ON r.id = ri.roll_id 
            WHERE ri.roll_id IS NULL
            LIMIT 10
        ''')
        rolls_without_recipes = cursor.fetchall()
        
        # Получаем ID базовых ингредиентов
        cursor.execute('SELECT id, name FROM ingredients LIMIT 5')
        available_ingredients = cursor.fetchall()
        
        if rolls_without_recipes and available_ingredients:
            for roll_id, roll_name in rolls_without_recipes:
                print(f"  🍣 Создаем рецептуру для: {roll_name}")
                
                # Добавляем базовые ингредиенты
                for i, (ing_id, ing_name) in enumerate(available_ingredients[:3]):  # Берем первые 3 ингредиента
                    amount = 100 + i * 50  # Разные количества
                    cursor.execute('''
                        INSERT INTO roll_ingredients (roll_id, ingredient_id, amount_per_roll)
                        VALUES (?, ?, ?)
                    ''', (roll_id, ing_id, amount))
                    print(f"    ✅ Добавлен {ing_name}: {amount}гр")
            
            conn.commit()
        
        # 3. СОЗДАЕМ СОСТАВЫ ДЛЯ СЕТОВ БЕЗ НИХ
        print("\n🥢 СОЗДАЕМ СОСТАВЫ ДЛЯ СЕТОВ")
        print("="*50)
        
        # Находим сеты без состава
        cursor.execute('''
            SELECT s.id, s.name 
            FROM sets s 
            LEFT JOIN set_rolls sr ON s.id = sr.set_id 
            WHERE sr.set_id IS NULL
            LIMIT 10
        ''')
        sets_without_composition = cursor.fetchall()
        
        # Получаем ID роллов
        cursor.execute('SELECT id, name FROM rolls LIMIT 3')
        available_rolls = cursor.fetchall()
        
        if sets_without_composition and available_rolls:
            for set_id, set_name in sets_without_composition:
                print(f"  🍱 Создаем состав для: {set_name}")
                
                # Добавляем 2-3 ролла в каждый сет
                for i, (roll_id, roll_name) in enumerate(available_rolls[:2]):
                    quantity = 2 + i  # 2 или 3 штуки
                    cursor.execute('''
                        INSERT INTO set_rolls (set_id, roll_id, quantity)
                        VALUES (?, ?, ?)
                    ''', (set_id, roll_id, quantity))
                    print(f"    ✅ Добавлен {roll_name}: {quantity} шт")
            
            conn.commit()
        
        # 4. ОБНОВЛЯЕМ ЦЕНЫ РОЛЛОВ НА ОСНОВЕ РЕЦЕПТУР
        print("\n💰 ОБНОВЛЯЕМ ЦЕНЫ РОЛЛОВ")
        print("="*50)
        
        cursor.execute('''
            SELECT r.id, r.name,
                   SUM(ri.amount_per_roll * i.cost_per_unit / 1000) as calculated_cost
            FROM rolls r
            JOIN roll_ingredients ri ON r.id = ri.roll_id
            JOIN ingredients i ON ri.ingredient_id = i.id
            GROUP BY r.id, r.name
        ''')
        
        roll_costs = cursor.fetchall()
        for roll_id, roll_name, calculated_cost in roll_costs:
            # Обновляем себестоимость
            cursor.execute('''
                UPDATE rolls 
                SET cost_price = ? 
                WHERE id = ?
            ''', (round(calculated_cost, 2), roll_id))
            print(f"  💰 {roll_name}: себестоимость {calculated_cost:.2f}₽")
        
        conn.commit()
        
        # 5. ОБНОВЛЯЕМ ЦЕНЫ СЕТОВ НА ОСНОВЕ СОСТАВА
        print("\n💰 ОБНОВЛЯЕМ ЦЕНЫ СЕТОВ")
        print("="*50)
        
        cursor.execute('''
            SELECT s.id, s.name,
                   SUM(sr.quantity * r.cost_price) as calculated_cost,
                   SUM(sr.quantity * r.sale_price) as total_sale_price
            FROM sets s
            JOIN set_rolls sr ON s.id = sr.set_id
            JOIN rolls r ON sr.roll_id = r.id
            GROUP BY s.id, s.name
        ''')
        
        set_costs = cursor.fetchall()
        for set_id, set_name, calculated_cost, total_sale_price in set_costs:
            # Себестоимость = сумма себестоимостей роллов
            # Цена продажи = общая цена роллов - скидка 10%
            sale_price = total_sale_price * 0.9  # 10% скидка
            discount = ((total_sale_price - sale_price) / total_sale_price) * 100
            
            cursor.execute('''
                UPDATE sets 
                SET cost_price = ?, set_price = ?, discount_percent = ?
                WHERE id = ?
            ''', (round(calculated_cost, 2), round(sale_price, 2), round(discount, 1), set_id))
            print(f"  💰 {set_name}: себестоимость {calculated_cost:.2f}₽, продажа {sale_price:.2f}₽ (скидка {discount:.1f}%)")
        
        conn.commit()
        
        print("\n✅ ИСПРАВЛЕНИЯ ЗАВЕРШЕНЫ!")
        print("="*50)
        
        # Финальная статистика
        cursor.execute('SELECT COUNT(*) FROM roll_ingredients')
        print(f"🧄 Рецептур роллов: {cursor.fetchone()[0]}")
        
        cursor.execute('SELECT COUNT(*) FROM set_rolls')
        print(f"🥢 Составов сетов: {cursor.fetchone()[0]}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    fix_database()
