#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки полного кода создания заказа
"""

def check_full_order_creation():
    print("🔍 ПРОВЕРКА ПОЛНОГО КОДА СОЗДАНИЯ ЗАКАЗА")
    print("=" * 50)
    
    # Читаем файл app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Найдем полный код создания заказа
    lines = content.split('\n')
    in_create_order = False
    create_order_lines = []
    
    for i, line in enumerate(lines):
        if '@app.route(\'/api/orders\', methods=[\'POST\'])' in line:
            in_create_order = True
            create_order_lines.append(f"{i+1:3}: {line}")
            continue
            
        if in_create_order and line.strip().startswith('@') and 'route' in line:
            break
            
        if in_create_order:
            create_order_lines.append(f"{i+1:3}: {line}")
    
    print("\n📋 Полный код создания заказа:")
    for line in create_order_lines:
        print(line)
        
        # Ищем проблемные места
        if 'user_name=' in line:
            print("   ⚠️  ПРОБЛЕМА: user_name=")
        if 'Order(' in line:
            print("   🔍 Создание Order:")

if __name__ == "__main__":
    check_full_order_creation()

