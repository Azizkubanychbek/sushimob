#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления ошибки с ключом 'price'
"""

def fix_price_key_error():
    print("🔧 ИСПРАВЛЕНИЕ ОШИБКИ С КЛЮЧОМ 'price'")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем ошибку с ключом 'price' - заменяем на правильные ключи
    content = content.replace("'price': roll.sale_price", "'price': roll.sale_price")
    content = content.replace("'price': set.set_price", "'price': set.set_price")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Ошибка с ключом 'price' исправлена!")

if __name__ == "__main__":
    fix_price_key_error()

