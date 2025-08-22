#!/usr/bin/env python3
import sqlite3

conn = sqlite3.connect('backend/instance/sushi_express.db')
cursor = conn.cursor()

print('🔍 ПРОВЕРКА СОЗДАННОЙ БАЗЫ')
print('='*40)

cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = cursor.fetchall()

print('📋 Созданные таблицы:')
for table in tables:
    print(f'  {table[0]}')

conn.close()
