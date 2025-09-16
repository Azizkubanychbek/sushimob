#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления ответа API корзины
"""

def fix_cart_api_response():
    print("🔧 ИСПРАВЛЕНИЕ ОТВЕТА API КОРЗИНЫ")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем ответ API корзины - добавляем поле success
    old_cart_response = '''        return jsonify({
            'cart': cart,
            'total_items': len(cart)
        }), 200'''
    
    new_cart_response = '''        return jsonify({
            'success': True,
            'cart': cart,
            'total_items': len(cart)
        }), 200'''
    
    if old_cart_response in content:
        content = content.replace(old_cart_response, new_cart_response)
        print("✅ Ответ API корзины исправлен")
    else:
        print("❌ Не удалось найти ответ API корзины для замены")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Исправление ответа API корзины завершено!")
    print("📝 Изменения:")
    print("  - Добавлено поле 'success': True в ответ API корзины")

if __name__ == "__main__":
    fix_cart_api_response()

