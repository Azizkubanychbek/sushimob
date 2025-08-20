import sqlite3
import os

def debug_database():
    """Отладка базы данных"""
    
    if not os.path.exists('sushi_express.db'):
        print("❌ База данных не существует!")
        return
    
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    try:
        print("🔍 Отладка базы данных:")
        print("=" * 50)
        
        # Проверяем таблицы
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        print(f"📋 Таблиц: {len(tables)}")
        
        for table in tables:
            table_name = table[0]
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]
            print(f"   {table_name}: {count} записей")
        
        print("\n🔍 Детальная информация:")
        
        # Проверяем users
        cursor.execute("SELECT id, name, email FROM users LIMIT 3")
        users = cursor.fetchall()
        print(f"\n👥 Пользователи (первые 3):")
        for user in users:
            print(f"   ID {user[0]}: {user[1]} ({user[2]})")
        
        # Проверяем ingredients
        cursor.execute("SELECT id, name FROM ingredients LIMIT 3")
        ingredients = cursor.fetchall()
        print(f"\n🥬 Ингредиенты (первые 3):")
        for ing in ingredients:
            print(f"   ID {ing[0]}: {ing[1]}")
        
        # Проверяем rolls
        cursor.execute("SELECT id, name FROM rolls LIMIT 3")
        rolls = cursor.fetchall()
        print(f"\n🍣 Роллы (первые 3):")
        for roll in rolls:
            print(f"   ID {roll[0]}: {roll[1]}")
        
        # Проверяем sets
        cursor.execute("SELECT id, name FROM sets LIMIT 3")
        sets = cursor.fetchall()
        print(f"\n📦 Сеты (первые 3):")
        for set_item in sets:
            print(f"   ID {set_item[0]}: {set_item[1]}")
        
        # Проверяем autoincrement
        cursor.execute("SELECT name, seq FROM sqlite_sequence")
        sequences = cursor.fetchall()
        print(f"\n🔢 Последовательности:")
        for seq in sequences:
            print(f"   {seq[0]}: {seq[1]}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    debug_database()
