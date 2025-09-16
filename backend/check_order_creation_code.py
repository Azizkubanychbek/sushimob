#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки кода создания заказа
"""

def check_order_creation_code():
    print("🔍 ПРОВЕРКА КОДА СОЗДАНИЯ ЗАКАЗА")
    print("=" * 50)
    
    # Читаем файл app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ищем функцию создания заказа
    if '@app.route(\'/api/orders\', methods=[\'POST\'])' in content:
        print("✅ Endpoint создания заказа найден")
        
        # Найдем функцию создания заказа
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
                # Ограничиваем вывод
                if len(create_order_lines) > 50:
                    create_order_lines.append("... (остальной код)")
                    break
        
        print("\n📋 Код создания заказа:")
        for line in create_order_lines:
            print(line)
    else:
        print("❌ Endpoint создания заказа не найден")
        
        # Поищем любые упоминания Order
        lines = content.split('\n')
        print("\n🔍 Поиск упоминаний Order:")
        for i, line in enumerate(lines):
            if 'Order(' in line:
                print(f"   Строка {i+1}: {line.strip()}")

if __name__ == "__main__":
    check_order_creation_code()

