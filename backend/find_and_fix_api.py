#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для поиска и исправления API
"""

def find_and_fix_api():
    print("🔍 ПОИСК И ИСПРАВЛЕНИЕ API")
    print("=" * 50)
    
    # Читаем файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ищем код API роллов
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if '/api/rolls' in line and 'GET' in line:
            print(f"Найден API роллов на строке {i+1}")
            # Показываем код
            for j in range(max(0, i-5), min(len(lines), i+20)):
                marker = ">>> " if j == i else "    "
                print(f"{marker}{j+1:3}: {lines[j]}")
            break
    
    print("\n" + "="*50)
    
    # Ищем код API сетов
    for i, line in enumerate(lines):
        if '/api/sets' in line and 'GET' in line:
            print(f"Найден API сетов на строке {i+1}")
            # Показываем код
            for j in range(max(0, i-5), min(len(lines), i+20)):
                marker = ">>> " if j == i else "    "
                print(f"{marker}{j+1:3}: {lines[j]}")
            break

if __name__ == "__main__":
    find_and_fix_api()

