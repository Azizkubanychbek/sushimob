import sqlite3

conn = sqlite3.connect('sushi_express.db')
cursor = conn.cursor()

print("📊 Проверка структуры БД:")
print("=" * 50)

# Проверяем таблицы
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = cursor.fetchall()
print(f"📋 Найдено таблиц: {len(tables)}")

for table in tables:
    table_name = table[0]
    print(f"\n🔍 Таблица: {table_name}")
    
    # Проверяем структуру таблицы
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = cursor.fetchall()
    
    for col in columns:
        col_id, col_name, col_type, not_null, default_val, pk = col
        print(f"  - {col_name}: {col_type} {'NOT NULL' if not_null else 'NULL'} {'PK' if pk else ''}")

conn.close()
