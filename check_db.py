import sqlite3
import os

def check_database():
    db_paths = [
        'instance/sushi_express.db',
        'backend/instance/sushi_express.db',
        'sushi_express.db'
    ]
    
    for db_path in db_paths:
        if os.path.exists(db_path):
            print(f"✅ База данных найдена: {db_path}")
            try:
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                
                # Проверяем таблицы
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
                tables = cursor.fetchall()
                print(f"📋 Таблицы в базе: {[table[0] for table in tables]}")
                
                # Проверяем количество записей
                for table in ['users', 'ingredients', 'rolls', 'sets']:
                    try:
                        cursor.execute(f'SELECT COUNT(*) FROM {table}')
                        count = cursor.fetchone()[0]
                        print(f"📊 {table.capitalize()}: {count} записей")
                    except sqlite3.OperationalError:
                        print(f"❌ Таблица {table} не существует")
                
                conn.close()
                return db_path
                
            except Exception as e:
                print(f"❌ Ошибка при подключении к {db_path}: {e}")
        else:
            print(f"❌ База данных не найдена: {db_path}")
    
    return None

if __name__ == "__main__":
    print("🔍 Проверяю базу данных...")
    db_path = check_database()
    
    if db_path:
        print(f"\n✅ База данных работает: {db_path}")
    else:
        print("\n❌ База данных не найдена нигде!")
