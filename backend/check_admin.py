import sqlite3

def check_admin_users():
    try:
        conn = sqlite3.connect('sushi_express.db')
        cursor = conn.cursor()
        
        print("🔍 Проверяю пользователей-админов...")
        print("=" * 50)
        
        # Проверяем всех пользователей
        cursor.execute("""
            SELECT id, name, email, is_admin, is_active 
            FROM users 
            ORDER BY is_admin DESC, name
        """)
        
        users = cursor.fetchall()
        
        if not users:
            print("❌ Пользователи не найдены!")
            return
        
        print(f"📊 Найдено пользователей: {len(users)}")
        print()
        
        for user in users:
            user_id, name, email, is_admin, is_active = user
            admin_status = "👑 АДМИН" if is_admin else "👤 Пользователь"
            active_status = "✅ Активен" if is_active else "❌ Заблокирован"
            
            print(f"🆔 ID: {user_id}")
            print(f"👤 Имя: {name}")
            print(f"📧 Email: {email}")
            print(f"🔑 Роль: {admin_status}")
            print(f"📊 Статус: {active_status}")
            print("-" * 30)
        
        # Проверяем, есть ли хотя бы один админ
        admins = [u for u in users if u[3]]  # u[3] = is_admin
        if not admins:
            print("⚠️  ВНИМАНИЕ: Нет ни одного администратора!")
            print("💡 Создайте админа или назначьте существующего пользователя")
        else:
            print(f"✅ Найдено администраторов: {len(admins)}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    check_admin_users()
