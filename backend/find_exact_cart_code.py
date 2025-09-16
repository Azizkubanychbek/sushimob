#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Поиск точного кода корзины
"""

def find_exact_cart_code():
    print("🔍 ПОИСК ТОЧНОГО КОДА КОРЗИНЫ")
    print("=" * 50)
    
    # Читаем файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ищем код корзины
    lines = content.split('\n')
    in_cart_function = False
    cart_lines = []
    
    for i, line in enumerate(lines):
        if '/api/cart' in line and 'GET' in line:
            in_cart_function = True
            cart_lines.append(f"{i+1:3}: {line}")
            continue
        
        if in_cart_function:
            cart_lines.append(f"{i+1:3}: {line}")
            
            # Останавливаемся на следующей функции
            if line.strip().startswith('@app.route') and '/api/cart' not in line:
                break
    
    print("📋 КОД КОРЗИНЫ:")
    for line in cart_lines:
        print(line)
    
    # Ищем конкретные строки для замены
    print("\n🔍 ПОИСК СТРОК ДЛЯ ЗАМЕНЫ:")
    for i, line in enumerate(lines):
        if 'cart = json.loads(user.cart)' in line:
            print(f"   Строка {i+1}: {line}")
            # Показываем контекст
            for j in range(max(0, i-2), min(len(lines), i+10)):
                marker = ">>> " if j == i else "    "
                print(f"{marker}{j+1:3}: {lines[j]}")

if __name__ == "__main__":
    find_exact_cart_code()

