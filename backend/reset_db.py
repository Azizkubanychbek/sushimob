import os
from app_sqlite import app, db

# Удаляем старую базу данных
if os.path.exists('sushi_express.db'):
    os.remove('sushi_express.db')
    print("🗑️ Старая база данных удалена")

# Создаем новую базу данных
with app.app_context():
    db.create_all()
    print("✅ Новая база данных создана с полем location!")
    print("📁 Файл: sushi_express.db")

print("🚀 Теперь запустите: python app_sqlite.py")
