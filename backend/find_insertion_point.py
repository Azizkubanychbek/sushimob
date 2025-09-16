#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def find_insertion_point():
    print("🔍 ПОИСК МЕСТА ДЛЯ ВСТАВКИ ФУНКЦИЙ")
    print("=" * 50)
    
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ищем различные паттерны
    patterns = [
        'class User(db.Model):',
        'db = SQLAlchemy()',
        'from flask_sqlalchemy import SQLAlchemy',
        'app = Flask(__name__)',
        'class Ingredient(db.Model):',
        'class Roll(db.Model):'
    ]
    
    for pattern in patterns:
        pos = content.find(pattern)
        if pos != -1:
            line_num = content[:pos].count('\n') + 1
            print(f"✅ Найден паттерн '{pattern}' на строке {line_num}")
            print(f"   Контекст: {content[pos-50:pos+100]}")
            print()
        else:
            print(f"❌ Паттерн '{pattern}' не найден")

if __name__ == "__main__":
    find_insertion_point()

