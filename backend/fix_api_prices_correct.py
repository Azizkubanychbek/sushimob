#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для правильного исправления цен в API
"""

def fix_api_prices_correct():
    print("🔧 ПРАВИЛЬНОЕ ИСПРАВЛЕНИЕ ЦЕН В API")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем API роллов - добавляем поле price
    old_rolls_code = '''            roll_data = {
                'id': roll.id,
                'name': roll.name,
                'description': roll.description,
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'category': 'roll',
                'is_available': True
            }'''
    
    new_rolls_code = '''            roll_data = {
                'id': roll.id,
                'name': roll.name,
                'description': roll.description,
                'price': roll.sale_price,  # Добавляем поле price
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'category': 'roll',
                'is_available': True
            }'''
    
    if old_rolls_code in content:
        content = content.replace(old_rolls_code, new_rolls_code)
        print("✅ API роллов исправлен")
    else:
        print("❌ Не удалось найти код роллов")
    
    # Исправляем API сетов - добавляем поле price
    old_sets_code = '''            set_data = {
                'id': set_item.id,
                'name': set_item.name,
                'description': set_item.description,
                'set_price': set_item.set_price,
                'image_url': set_item.image_url,
                'is_available': True
            }'''
    
    new_sets_code = '''            set_data = {
                'id': set_item.id,
                'name': set_item.name,
                'description': set_item.description,
                'price': set_item.set_price,  # Добавляем поле price
                'set_price': set_item.set_price,
                'image_url': set_item.image_url,
                'is_available': True
            }'''
    
    if old_sets_code in content:
        content = content.replace(old_sets_code, new_sets_code)
        print("✅ API сетов исправлен")
    else:
        print("❌ Не удалось найти код сетов")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Исправление завершено!")
    print("📝 Теперь API будет возвращать поле 'price' для Flutter")

if __name__ == "__main__":
    fix_api_prices_correct()

