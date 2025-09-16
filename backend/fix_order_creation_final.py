#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для финального исправления создания заказа
"""

def fix_order_creation_final():
    print("🔧 ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ СОЗДАНИЯ ЗАКАЗА")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем создание Order - убираем все несуществующие поля
    old_order_creation = '''        order = Order(
            user_id=user_id,
            user_name=user.name,
            user_phone=phone,
            user_email=user.email,
            delivery_address=delivery_address,
            delivery_latitude=data.get('delivery_latitude', 42.8746),
            delivery_longitude=data.get('delivery_longitude', 74.5698),
            total_price=total_price,
            status='Принят',
            created_at=datetime.utcnow(),
            payment_method=payment_method,
            comment=comment,
            phone=phone
        )'''
    
    new_order_creation = '''        order = Order(
            user_id=user_id,
            phone=phone,
            delivery_address=delivery_address,
            payment_method=payment_method,
            status='Принят',
            total_price=total_price,
            comment=comment,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )'''
    
    if old_order_creation in content:
        content = content.replace(old_order_creation, new_order_creation)
        print("✅ Создание Order исправлено")
    else:
        print("❌ Не удалось найти создание Order для замены")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Финальное исправление создания заказа завершено!")
    print("📝 Изменения:")
    print("  - Убраны все несуществующие поля из Order")
    print("  - Оставлены только поля из таблицы orders")

if __name__ == "__main__":
    fix_order_creation_final()

