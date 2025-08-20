import sqlite3

def check_schema():
    """Проверяем схему базы данных"""
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    print("🔍 Проверяем схему таблицы users:")
    cursor.execute("PRAGMA table_info(users)")
    columns = cursor.fetchall()
    
    for column in columns:
        print(f"  - {column[1]} ({column[2]}) {'NOT NULL' if column[3] else 'NULL'}")
    
    print("\n📊 Проверяем данные пользователей:")
    cursor.execute("SELECT id, name, email, favorites, cart FROM users LIMIT 3")
    users = cursor.fetchall()
    
    for user in users:
        print(f"  User {user[0]}: {user[1]} ({user[2]})")
        print(f"    Favorites: {user[3]}")
        print(f"    Cart: {user[4]}")
        print()
    
    conn.close()

if __name__ == "__main__":
    check_schema()
