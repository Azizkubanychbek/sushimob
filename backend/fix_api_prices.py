#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления цен в API
"""

def fix_api_prices():
    print("🔧 ИСПРАВЛЕНИЕ ЦЕН В API")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем API роллов - добавляем поле price
    old_rolls_api = '''        rolls = []
        for roll in Roll.query.all():
            rolls.append({
                'id': roll.id,
                'name': roll.name,
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'is_available': True,
                'category': roll.category if hasattr(roll, 'category') else 'roll',
                'description': roll.description
            })'''
    
    new_rolls_api = '''        rolls = []
        for roll in Roll.query.all():
            rolls.append({
                'id': roll.id,
                'name': roll.name,
                'price': roll.sale_price,  # Добавляем поле price
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'is_available': True,
                'category': roll.category if hasattr(roll, 'category') else 'roll',
                'description': roll.description
            })'''
    
    if old_rolls_api in content:
        content = content.replace(old_rolls_api, new_rolls_api)
        print("✅ API роллов исправлен")
    else:
        print("❌ Не удалось найти API роллов для замены")
    
    # Исправляем API сетов - добавляем поле price
    old_sets_api = '''        sets = []
        for set_item in Set.query.all():
            sets.append({
                'id': set_item.id,
                'name': set_item.name,
                'set_price': set_item.set_price,
                'image_url': set_item.image_url,
                'is_available': True,
                'description': set_item.description
            })'''
    
    new_sets_api = '''        sets = []
        for set_item in Set.query.all():
            sets.append({
                'id': set_item.id,
                'name': set_item.name,
                'price': set_item.set_price,  # Добавляем поле price
                'set_price': set_item.set_price,
                'image_url': set_item.image_url,
                'is_available': True,
                'description': set_item.description
            })'''
    
    if old_sets_api in content:
        content = content.replace(old_sets_api, new_sets_api)
        print("✅ API сетов исправлен")
    else:
        print("❌ Не удалось найти API сетов для замены")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Исправление цен в API завершено!")
    print("📝 Изменения:")
    print("  - Добавлено поле 'price' для роллов и сетов")
    print("  - Теперь Flutter получит правильные цены")

if __name__ == "__main__":
    fix_api_prices()

