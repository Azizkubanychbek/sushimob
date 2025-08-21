import sqlite3
from werkzeug.security import generate_password_hash

def reset_admin_password():
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("🔐 Сбрасываю пароль админа...")
        print("=" * 50)
        
        # Новый пароль
        new_password = "admin123"
        hashed_password = generate_password_hash(new_password)
        
        # Обновляем пароль для админа
        cursor.execute("""
            UPDATE users 
            SET password_hash = ? 
            WHERE email = 'ss@gmail.com' AND is_admin = 1
        """, (hashed_password,))
        
        if cursor.rowcount > 0:
            print(f"✅ Пароль обновлен для админа ss@gmail.com")
            print(f"🔑 Новый пароль: {new_password}")
            print(f"🔐 Хеш: {hashed_password[:50]}...")
            
            # Проверяем обновление
            cursor.execute("SELECT name, email, is_admin FROM users WHERE email = 'ss@gmail.com'")
            user = cursor.fetchone()
            if user:
                print(f"👤 Пользователь: {user[0]} ({user[1]}) - Админ: {user[2]}")
        else:
            print("❌ Админ не найден или не обновлен")
        
        conn.commit()
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    reset_admin_password()
