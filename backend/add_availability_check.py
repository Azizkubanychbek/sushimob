#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для добавления проверки наличия товаров в API
"""

import sqlite3
import os

def add_availability_check():
    print("🔧 ДОБАВЛЕНИЕ ПРОВЕРКИ НАЛИЧИЯ ТОВАРОВ")
    print("=" * 50)
    
    # Читаем текущий файл app_sqlite.py
    app_file = 'app_sqlite.py'
    
    if not os.path.exists(app_file):
        print(f"❌ Файл {app_file} не найден!")
        return
    
    with open(app_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("📝 Файл app_sqlite.py найден")
    
    # Проверяем, есть ли уже функция проверки наличия
    if 'def check_ingredient_availability' in content:
        print("✅ Функция проверки наличия уже существует")
        return
    
    print("🔧 Добавляем функцию проверки наличия ингредиентов...")
    
    # Добавляем функцию проверки наличия перед определением моделей
    availability_function = '''
# ===== ФУНКЦИИ ПРОВЕРКИ НАЛИЧИЯ =====

def check_ingredient_availability(ingredient_id, required_quantity=1):
    """Проверяет наличие ингредиента в достаточном количестве"""
    try:
        ingredient = Ingredient.query.get(ingredient_id)
        if not ingredient:
            return False, "Ингредиент не найден"
        
        if ingredient.stock_quantity is None or ingredient.stock_quantity <= 0:
            return False, f"Ингредиент '{ingredient.name}' закончился"
        
        if ingredient.stock_quantity < required_quantity:
            return False, f"Недостаточно ингредиента '{ingredient.name}'. Доступно: {ingredient.stock_quantity}, требуется: {required_quantity}"
        
        return True, "В наличии"
    except Exception as e:
        return False, f"Ошибка проверки наличия: {str(e)}"

def check_roll_availability(roll_id):
    """Проверяет доступность ролла на основе наличия всех ингредиентов"""
    try:
        roll = Roll.query.get(roll_id)
        if not roll:
            return False, "Ролл не найден"
        
        # Получаем все ингредиенты ролла
        roll_ingredients = RollIngredient.query.filter_by(roll_id=roll_id).all()
        
        unavailable_ingredients = []
        for roll_ingredient in roll_ingredients:
            available, message = check_ingredient_availability(
                roll_ingredient.ingredient_id, 
                roll_ingredient.quantity
            )
            if not available:
                ingredient = Ingredient.query.get(roll_ingredient.ingredient_id)
                unavailable_ingredients.append(f"{ingredient.name}: {message}")
        
        if unavailable_ingredients:
            return False, f"Недоступен: {', '.join(unavailable_ingredients)}"
        
        return True, "В наличии"
    except Exception as e:
        return False, f"Ошибка проверки ролла: {str(e)}"

def check_set_availability(set_id):
    """Проверяет доступность сета на основе наличия всех роллов"""
    try:
        set_item = Set.query.get(set_id)
        if not set_item:
            return False, "Сет не найден"
        
        # Получаем все роллы в сете
        set_rolls = SetRoll.query.filter_by(set_id=set_id).all()
        
        unavailable_rolls = []
        for set_roll in set_rolls:
            available, message = check_roll_availability(set_roll.roll_id)
            if not available:
                roll = Roll.query.get(set_roll.roll_id)
                unavailable_rolls.append(f"{roll.name}: {message}")
        
        if unavailable_rolls:
            return False, f"Недоступен: {', '.join(unavailable_rolls)}"
        
        return True, "В наличии"
    except Exception as e:
        return False, f"Ошибка проверки сета: {str(e)}"

'''
    
    # Находим место для вставки (перед определением моделей)
    insert_point = content.find('class User(db.Model):')
    if insert_point == -1:
        print("❌ Не удалось найти место для вставки функции")
        return
    
    # Вставляем функцию
    new_content = content[:insert_point] + availability_function + content[insert_point:]
    
    # Записываем обновленный файл
    with open(app_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("✅ Функции проверки наличия добавлены в app_sqlite.py")
    print("📝 Добавлены функции:")
    print("  - check_ingredient_availability()")
    print("  - check_roll_availability()")
    print("  - check_set_availability()")

if __name__ == "__main__":
    add_availability_check()

