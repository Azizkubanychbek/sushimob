#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для проверки endpoints корзины в API
"""

def check_cart_endpoints():
    print("🔍 ПРОВЕРКА ENDPOINTS КОРЗИНЫ В API")
    print("=" * 50)
    
    # Читаем файл app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ищем endpoints корзины
    cart_endpoints = [
        '@app.route(\'/api/cart\', methods=[\'GET\'])',
        '@app.route(\'/api/cart/add\', methods=[\'POST\'])',
        '@app.route(\'/api/cart/remove\', methods=[\'DELETE\'])',
        '@app.route(\'/api/cart/clear\', methods=[\'POST\'])'
    ]
    
    print("📋 Endpoints корзины:")
    for endpoint in cart_endpoints:
        if endpoint in content:
            print(f"   ✅ {endpoint}")
        else:
            print(f"   ❌ {endpoint}")
    
    # Проверяем, есть ли ошибки в коде корзины
    print("\n🔍 Поиск потенциальных проблем в коде корзины:")
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if '/api/cart' in line and '@app.route' in line:
            print(f"   Строка {i+1}: {line.strip()}")
            
            # Показываем код функции
            for j in range(i+1, min(len(lines), i+20)):
                if lines[j].strip().startswith('@') and 'route' in lines[j]:
                    break
                if lines[j].strip() and not lines[j].startswith(' '):
                    break
                print(f"      {j+1:3}: {lines[j]}")

if __name__ == "__main__":
    check_cart_endpoints()

