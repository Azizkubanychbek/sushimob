import sqlite3
import os

def restore_original_db():
    """Восстанавливает оригинальную базу данных, удаляя новые таблицы"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🔄 Восстанавливаю оригинальную базу данных...")
        
        # Удаляем созданные таблицы
        cursor.execute("DROP TABLE IF EXISTS roll_recipes")
        print("✅ Удалена таблица roll_recipes")
        
        cursor.execute("DROP TABLE IF EXISTS set_compositions")
        print("✅ Удалена таблица set_compositions")
        
        # Удаляем добавленные поля (если они есть)
        try:
            cursor.execute("ALTER TABLE rolls DROP COLUMN description")
            print("✅ Удалено поле description из rolls")
        except:
            print("ℹ️ Поле description не существовало в rolls")
        
        try:
            cursor.execute("ALTER TABLE sets DROP COLUMN description")
            print("✅ Удалено поле description из sets")
        except:
            print("ℹ️ Поле description не существовало в sets")
        
        try:
            cursor.execute("ALTER TABLE sets DROP COLUMN image_url")
            print("✅ Удалено поле image_url из sets")
        except:
            print("ℹ️ Поле image_url не существовало в sets")
        
        conn.commit()
        print("\n✅ Оригинальная база данных восстановлена!")
        
        # Показываем текущую структуру
        print("\n📊 Текущая структура базы:")
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        for table in tables:
            print(f"  - {table[0]}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    restore_original_db()
