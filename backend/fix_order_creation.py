#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления создания заказа
"""

def fix_order_creation():
    print("🔧 ИСПРАВЛЕНИЕ СОЗДАНИЯ ЗАКАЗА")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем создание Order - убираем поля которых нет в таблице
    old_order_creation = '''Order(
            user_id=user_id,
            user_phone=user.phone,
            user_email=user.email,
            delivery_address=delivery_address,
            delivery_latitude=0.0,
            delivery_longitude=0.0,
            items=order_items,
            total_price=total_price,
            status='pending',
            notes=notes,
            delivery_instructions=delivery_instructions,
            payment_method=payment_method,
            comment=comment,
            phone=phone,
        )'''
    
    new_order_creation = '''Order(
            user_id=user_id,
            phone=phone,
            delivery_address=delivery_address,
            payment_method=payment_method,
            status='pending',
            total_price=total_price,
            comment=comment,
        )'''
    
    if old_order_creation in content:
        content = content.replace(old_order_creation, new_order_creation)
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Создание заказа исправлено!")
    print("📝 Изменения:")
    print("  - Убраны несуществующие поля из Order")
    print("  - Оставлены только поля из таблицы orders")

if __name__ == "__main__":
    fix_order_creation()

