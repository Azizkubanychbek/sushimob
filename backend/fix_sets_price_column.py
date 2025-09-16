#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления колонки цены в API для сетов
"""

def fix_sets_price_column():
    print("🔧 ИСПРАВЛЕНИЕ КОЛОНКИ ЦЕНЫ ДЛЯ СЕТОВ")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Заменяем set.sale_price на set.set_price
    replacements = [
        ('set.sale_price', 'set.set_price'),
        ("'price': set.sale_price", "'price': set.set_price"),
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Колонка цены для сетов исправлена!")
    print("📝 Изменения:")
    print("  - set.sale_price → set.set_price")

if __name__ == "__main__":
    fix_sets_price_column()

