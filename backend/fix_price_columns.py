#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления названий колонок в API
"""

def fix_price_columns():
    print("🔧 ИСПРАВЛЕНИЕ НАЗВАНИЙ КОЛОНОК В API")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Заменяем price на sale_price в запросах
    replacements = [
        ('roll.price', 'roll.sale_price'),
        ('set.price', 'set.sale_price'),
        ("'price': roll.price", "'price': roll.sale_price"),
        ("'price': set.price", "'price': set.sale_price"),
        ('item.price', 'item.sale_price'),
        ("'price': item.price", "'price': item.sale_price"),
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Названия колонок исправлены!")
    print("📝 Изменения:")
    print("  - roll.price → roll.sale_price")
    print("  - set.price → set.sale_price")
    print("  - item.price → item.sale_price")

if __name__ == "__main__":
    fix_price_columns()

