#!/usr/bin/env python3
"""
Скрипт для проверки структуры базы данных
"""

import sqlite3

def check_database():
    """Проверяет структуру базы данных"""
    
    try:
        # Подключение к базе данных
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        # Получаем список таблиц
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        print("📋 Таблицы в базе данных:")
        for table in tables:
            print(f"   - {table[0]}")
        
        if not tables:
            print("❌ База данных пуста!")
            return
        
        # Проверяем структуру каждой таблицы
        for table in tables:
            table_name = table[0]
            print(f"\n🔍 Структура таблицы '{table_name}':")
            
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = cursor.fetchall()
            
            for column in columns:
                print(f"   - {column[1]} ({column[2]})")
            
            # Показываем количество записей
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            count = cursor.fetchone()[0]
            print(f"   📊 Записей: {count}")
        
        conn.close()
        
    except sqlite3.Error as e:
        print(f"❌ Ошибка базы данных: {e}")
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_database()