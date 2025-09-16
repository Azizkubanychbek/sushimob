#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для добавления функций проверки наличия товаров в API
"""

import os

def add_availability_functions():
    print("🔧 ДОБАВЛЕНИЕ ФУНКЦИЙ ПРОВЕРКИ НАЛИЧИЯ")
    print("=" * 50)
    
    # Читаем текущий файл app_sqlite.py
    app_file = 'app_sqlite.py'
    
    with open(app_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Проверяем, есть ли уже функции
    if 'def check_ingredient_availability' in content:
        print("✅ Функции проверки наличия уже существуют")
        return
    
    print("🔧 Добавляем функции проверки наличия...")
    
    # Добавляем функции после импорта моделей
    availability_functions = '''

# ===== ФУНКЦИИ ПРОВЕРКИ НАЛИЧИЯ ТОВАРОВ =====

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
    
    # Находим место для вставки (после импорта моделей)
    insert_point = content.find('CORS(app)')
    if insert_point == -1:
        print("❌ Не удалось найти место для вставки функций")
        return
    
    # Ищем конец строки с CORS(app)
    end_of_line = content.find('\n', insert_point)
    if end_of_line == -1:
        end_of_line = len(content)
    
    # Вставляем функции после CORS(app)
    new_content = content[:end_of_line] + availability_functions + content[end_of_line:]
    
    # Записываем обновленный файл
    with open(app_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("✅ Функции проверки наличия добавлены в app_sqlite.py")
    print("📝 Добавлены функции:")
    print("  - check_ingredient_availability()")
    print("  - check_roll_availability()")
    print("  - check_set_availability()")

if __name__ == "__main__":
    add_availability_functions()

