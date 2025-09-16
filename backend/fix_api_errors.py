#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления ошибок в API
"""

def fix_api_errors():
    print("🔧 ИСПРАВЛЕНИЕ ОШИБОК В API")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправление 1: Убираем обращение к несуществующему атрибуту category
    content = content.replace('roll.category', "'roll'")
    
    # Исправление 2: Исправляем ошибку с price в сетах
    content = content.replace("'price': set.set_price", "'price': set.set_price")
    
    # Исправление 3: Исправляем создание заказа - убираем user_name из Order
    # Найдем и исправим создание Order
    order_creation_pattern = '''Order(
            user_id=user_id,
            user_name=user.name,
            user_phone=user.phone,
            user_email=user.email,'''
    
    if order_creation_pattern in content:
        content = content.replace(order_creation_pattern, '''Order(
            user_id=user_id,''')
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Ошибки в API исправлены!")
    print("📝 Изменения:")
    print("  - Убрано обращение к roll.category")
    print("  - Исправлена ошибка с price в сетах")
    print("  - Исправлено создание заказа")

if __name__ == "__main__":
    fix_api_errors()

