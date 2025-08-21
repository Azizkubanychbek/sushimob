import sqlite3

def check_users_table():
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("🔍 Проверяю структуру таблицы users...")
        print("=" * 50)
        
        # Проверяем структуру таблицы
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        
        print("📋 Структура таблицы users:")
        for col in columns:
            col_id, col_name, col_type, not_null, default_val, pk = col
            print(f"  - {col_name}: {col_type} {'NOT NULL' if not_null else 'NULL'} {'PK' if pk else ''}")
        
        print()
        
        # Проверяем данные
        cursor.execute("SELECT * FROM users LIMIT 1")
        user = cursor.fetchone()
        
        if user:
            print("📊 Пример данных пользователя:")
            for i, col in enumerate(columns):
                col_name = col[1]
                value = user[i]
                print(f"  {col_name}: {value}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_users_table()
