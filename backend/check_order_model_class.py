#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки класса Order в API
"""

def check_order_model_class():
    print("🔍 ПРОВЕРКА КЛАССА ORDER В API")
    print("=" * 50)
    
    # Читаем файл app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ищем определение класса Order
    if 'class Order' in content:
        print("✅ Класс Order найден")
        
        # Ищем __init__ метод
        lines = content.split('\n')
        in_order_class = False
        in_init = False
        init_lines = []
        
        for line in lines:
            if 'class Order' in line:
                in_order_class = True
                continue
            
            if in_order_class and line.strip().startswith('class '):
                break
                
            if in_order_class and 'def __init__' in line:
                in_init = True
                init_lines.append(line)
                continue
                
            if in_init and line.strip() and not line.startswith(' '):
                break
                
            if in_init:
                init_lines.append(line)
        
        if init_lines:
            print("\n📋 Конструктор Order:")
            for line in init_lines:
                print(f"   {line}")
    else:
        print("❌ Класс Order не найден")
    
    # Ищем создание Order в коде
    print("\n🔍 Поиск создания Order в коде:")
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'Order(' in line and 'user_name=' in line:
            print(f"   Строка {i+1}: {line.strip()}")
            # Показываем контекст
            for j in range(max(0, i-2), min(len(lines), i+5)):
                marker = ">>> " if j == i else "    "
                print(f"{marker}{j+1:3}: {lines[j]}")

if __name__ == "__main__":
    check_order_model_class()

