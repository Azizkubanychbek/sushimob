import sqlite3
import os

def add_new_fields_safely():
    """Безопасно добавляет новые поля в существующие таблицы без изменения данных"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🔧 Безопасно добавляю новые поля...")
        
        # Проверяем и добавляем поле description в rolls
        cursor.execute("PRAGMA table_info(rolls)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'description' not in columns:
            cursor.execute('ALTER TABLE rolls ADD COLUMN description TEXT DEFAULT ""')
            print("✅ Добавлено поле description в rolls (пустое по умолчанию)")
        
        # Проверяем и добавляем поле description в sets
        cursor.execute("PRAGMA table_info(sets)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'description' not in columns:
            cursor.execute('ALTER TABLE sets ADD COLUMN description TEXT DEFAULT ""')
            print("✅ Добавлено поле description в sets (пустое по умолчанию)")
        
        # Проверяем и добавляем поле image_url в sets
        if 'image_url' not in columns:
            cursor.execute('ALTER TABLE sets ADD COLUMN image_url TEXT DEFAULT ""')
            print("✅ Добавлено поле image_url в sets (пустое по умолчанию)")
        
        conn.commit()
        print("\n✅ Новые поля добавлены безопасно!")
        
        # Показываем текущую структуру
        print("\n📊 Структура таблицы rolls:")
        cursor.execute("PRAGMA table_info(rolls)")
        for col in cursor.fetchall():
            print(f"  - {col[1]} ({col[2]}) - Default: {col[4]}")
        
        print("\n📊 Структура таблицы sets:")
        cursor.execute("PRAGMA table_info(sets)")
        for col in cursor.fetchall():
            print(f"  - {col[1]} ({col[2]}) - Default: {col[4]}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    add_new_fields_safely()
