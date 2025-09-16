#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def fix_favorites_bug():
    print("🔧 ИСПРАВЛЕНИЕ ОШИБКИ ИЗБРАННОГО")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем проблему с избранным
    old_favorites_code = '''        favorites = json.loads(user.favorites) if user.favorites else []'''
    new_favorites_code = '''        favorites = json.loads(user.favorites) if user.favorites and user.favorites != 'null' else []'''
    
    if old_favorites_code in content:
        content = content.replace(old_favorites_code, new_favorites_code)
        print("✅ Исправлена проблема с избранным")
    else:
        print("⚠️ Код избранного не найден")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Ошибка избранного исправлена")

if __name__ == "__main__":
    fix_favorites_bug()
