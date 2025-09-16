#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для поиска оригинальной базы данных
"""

import os
import sqlite3
import shutil
from pathlib import Path

def find_original_database():
    print("🔍 ПОИСК ОРИГИНАЛЬНОЙ БАЗЫ ДАННЫХ")
    print("=" * 50)
    
    # Ищем все файлы .db в проекте
    project_root = Path("..")
    db_files = list(project_root.rglob("*.db"))
    
    print(f"📁 Найдено файлов базы данных: {len(db_files)}")
    for db_file in db_files:
        print(f"   {db_file}")
    
    # Проверяем каждый файл на наличие правильных данных
    for db_file in db_files:
        print(f"\n🔍 Проверка файла: {db_file}")
        try:
            conn = sqlite3.connect(db_file)
            cursor = conn.cursor()
            
            # Проверяем таблицы
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = [row[0] for row in cursor.fetchall()]
            print(f"   📊 Таблицы: {tables}")
            
            # Проверяем роллы
            if 'rolls' in tables:
                cursor.execute("SELECT COUNT(*) FROM rolls")
                rolls_count = cursor.fetchone()[0]
                print(f"   🍣 Роллы: {rolls_count}")
                
                if rolls_count > 0:
                    cursor.execute("SELECT name, sale_price, image_url FROM rolls LIMIT 3")
                    sample_rolls = cursor.fetchall()
                    print(f"   📝 Примеры роллов:")
                    for roll in sample_rolls:
                        print(f"      {roll[0]} - {roll[1]} сом - {roll[2]}")
            
            # Проверяем сеты
            if 'sets' in tables:
                cursor.execute("SELECT COUNT(*) FROM sets")
                sets_count = cursor.fetchone()[0]
                print(f"   🍱 Сеты: {sets_count}")
                
                if sets_count > 0:
                    cursor.execute("SELECT name, set_price, image_url FROM sets LIMIT 3")
                    sample_sets = cursor.fetchall()
                    print(f"   📝 Примеры сетов:")
                    for set_item in sample_sets:
                        print(f"      {set_item[0]} - {set_item[1]} сом - {set_item[2]}")
            
            # Проверяем заказы
            if 'orders' in tables:
                cursor.execute("SELECT COUNT(*) FROM orders")
                orders_count = cursor.fetchone()[0]
                print(f"   📦 Заказы: {orders_count}")
            
            conn.close()
            
            # Если найдена база с данными, копируем её
            if rolls_count > 0 and sets_count > 0:
                print(f"   ✅ Найдена база с данными!")
                backup_path = "sushi_express_backup.db"
                shutil.copy2(db_file, backup_path)
                print(f"   💾 Создана резервная копия: {backup_path}")
                
        except Exception as e:
            print(f"   ❌ Ошибка проверки: {e}")
    
    print("\n📋 Рекомендации:")
    print("   1. Найти базу с полными данными роллов и сетов")
    print("   2. Скопировать её в backend/sushi_express.db")
    print("   3. Проверить, что все данные на месте")

if __name__ == "__main__":
    find_original_database()

