#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

def fix_db_creation_message():
    print("🔧 ИСПРАВЛЕНИЕ СООБЩЕНИЯ О СОЗДАНИИ БД")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Проверяем, существует ли база данных
    db_exists = os.path.exists('sushi_express.db')
    
    if db_exists:
        print("✅ База данных уже существует")
        
        # Заменяем сообщение о создании
        old_message = '''        print('✅ База данных SQLite создана!')
        print(f'📁 Файл: sushi_express.db')
        print('📊 Созданные таблицы:')
        print('   - users')
        print('   - ingredients')
        print('   - rolls')
        print('   - roll_ingredients')
        print('   - sets')
        print('   - set_rolls')
        print('   - orders')
        print('   - order_items')
        print('   - loyalty_cards')
        print('   - loyalty_rolls')
        print('   - loyalty_card_usage')
        print('✅ Система накопительных карт уже инициализирована')'''
        
        new_message = '''        print('✅ База данных SQLite подключена!')
        print(f'📁 Файл: sushi_express.db')
        print('📊 Доступные таблицы:')
        print('   - users')
        print('   - ingredients')
        print('   - rolls')
        print('   - roll_ingredients')
        print('   - sets')
        print('   - set_rolls')
        print('   - orders')
        print('   - order_items')
        print('   - loyalty_cards')
        print('   - loyalty_rolls')
        print('   - loyalty_card_usage')
        print('✅ Система накопительных карт активна')'''
        
        if old_message in content:
            content = content.replace(old_message, new_message)
            print("✅ Сообщение о создании БД исправлено")
        else:
            print("⚠️ Сообщение о создании БД не найдено")
    else:
        print("⚠️ База данных не существует, оставляем сообщение о создании")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Исправление завершено")

if __name__ == "__main__":
    fix_db_creation_message()
