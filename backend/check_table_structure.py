import sqlite3

conn = sqlite3.connect('sushi_express.db')
cursor = conn.cursor()

print("🔍 СТРУКТУРА ТАБЛИЦ")
print("="*50)

# Проверяем структуру таблицы rolls
print("\n🍣 ТАБЛИЦА ROLLS:")
cursor.execute("PRAGMA table_info(rolls)")
rolls_columns = cursor.fetchall()
for col in rolls_columns:
    print(f"  {col[1]} ({col[2]})")

# Проверяем структуру таблицы sets
print("\n🍱 ТАБЛИЦА SETS:")
cursor.execute("PRAGMA table_info(sets)")
sets_columns = cursor.fetchall()
for col in sets_columns:
    print(f"  {col[1]} ({col[2]})")

# Проверяем структуру таблицы ingredients
print("\n🧄 ТАБЛИЦА INGREDIENTS:")
cursor.execute("PRAGMA table_info(ingredients)")
ingredients_columns = cursor.fetchall()
for col in ingredients_columns:
    print(f"  {col[1]} ({col[2]})")

conn.close()
