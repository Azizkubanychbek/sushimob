import sqlite3
import os

def create_recipe_tables():
    """Создает таблицы для рецептов роллов и сетов"""
    
    # Подключаемся к базе данных
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🔧 Создаю таблицы для рецептов...")
        
        # Таблица рецептов роллов (ингредиенты + количество)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS roll_recipes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                roll_id INTEGER NOT NULL,
                ingredient_id INTEGER NOT NULL,
                quantity REAL NOT NULL,
                unit TEXT NOT NULL,
                FOREIGN KEY (roll_id) REFERENCES rolls (id) ON DELETE CASCADE,
                FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON DELETE CASCADE,
                UNIQUE(roll_id, ingredient_id)
            )
        ''')
        
        # Таблица составов сетов (роллы + количество)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS set_compositions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                set_id INTEGER NOT NULL,
                item_type TEXT NOT NULL, -- 'roll' или 'other_item'
                item_id INTEGER NOT NULL,
                quantity INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY (set_id) REFERENCES sets (id) ON DELETE CASCADE
            )
        ''')
        
        # Добавляем поле description в таблицу rolls если его нет
        cursor.execute("PRAGMA table_info(rolls)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'description' not in columns:
            cursor.execute('ALTER TABLE rolls ADD COLUMN description TEXT')
            print("✅ Добавлено поле description в таблицу rolls")
        
        # Добавляем поле description в таблицу sets если его нет
        cursor.execute("PRAGMA table_info(sets)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'description' not in columns:
            cursor.execute('ALTER TABLE sets ADD COLUMN description TEXT')
            print("✅ Добавлено поле description в таблицу sets")
        
        # Добавляем поле image_url в таблицу sets если его нет
        if 'image_url' not in columns:
            cursor.execute('ALTER TABLE sets ADD COLUMN image_url TEXT')
            print("✅ Добавлено поле image_url в таблицу sets")
        
        conn.commit()
        print("✅ Таблицы рецептов созданы успешно!")
        
        # Показываем структуру таблиц
        print("\n📊 Структура таблиц:")
        
        cursor.execute("PRAGMA table_info(roll_recipes)")
        print("roll_recipes:", [col[1] for col in cursor.fetchall()])
        
        cursor.execute("PRAGMA table_info(set_compositions)")
        print("set_compositions:", [col[1] for col in cursor.fetchall()])
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    create_recipe_tables()
