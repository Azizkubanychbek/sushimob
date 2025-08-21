import sqlite3
import os

def check_roll_ingredients():
    """Проверяет структуру таблицы roll_ingredients"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🔍 Проверяю структуру таблицы roll_ingredients...")
        
        # Проверяем существование таблицы
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='roll_ingredients'")
        if not cursor.fetchone():
            print("❌ Таблица roll_ingredients не существует!")
            return
        
        # Показываем структуру таблицы
        cursor.execute("PRAGMA table_info(roll_ingredients)")
        columns = cursor.fetchall()
        
        print("\n📊 Структура таблицы roll_ingredients:")
        for col in columns:
            print(f"  - {col[1]} ({col[2]}) - Default: {col[4]}")
        
        # Проверяем данные в таблице
        cursor.execute("SELECT COUNT(*) FROM roll_ingredients")
        count = cursor.fetchone()[0]
        print(f"\n📊 Всего записей в roll_ingredients: {count}")
        
        if count > 0:
            cursor.execute("SELECT * FROM roll_ingredients LIMIT 3")
            rows = cursor.fetchall()
            print("\n📋 Примеры данных:")
            for row in rows:
                print(f"  {row}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    check_roll_ingredients()
