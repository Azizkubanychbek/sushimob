import sqlite3

def check_user():
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    # Проверяем пользователя test2@test.com
    cursor.execute('SELECT id, name, email, favorites, cart FROM users WHERE email = ?', ('test2@test.com',))
    user = cursor.fetchone()
    
    if user:
        user_id, name, email, favorites, cart = user
        print(f"User {user_id}: {name} ({email})")
        print(f"  Favorites: {favorites}")
        print(f"  Cart: {cart}")
    else:
        print("Пользователь test2@test.com не найден")
    
    conn.close()

if __name__ == "__main__":
    check_user()
