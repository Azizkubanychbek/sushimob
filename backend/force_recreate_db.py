from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os

# Создаем Flask приложение
app = Flask(__name__)

# Конфигурация для SQLite
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///sushi_express.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Инициализация SQLAlchemy
db = SQLAlchemy()
db.init_app(app)

# Импортируем модели
from models import User, Ingredient, Roll, RollIngredient, Set, SetRoll, Order, OrderItem

def force_recreate_db():
    """Принудительно пересоздает БД через Flask-SQLAlchemy"""
    
    with app.app_context():
        print("🗑️ Удаляем старую БД...")
        
        # Удаляем все таблицы
        db.drop_all()
        print("✅ Старые таблицы удалены")
        
        # Создаем новые таблицы
        db.create_all()
        print("✅ Новые таблицы созданы")
        
        # Проверяем структуру
        print("\n📊 Проверяем структуру БД:")
        for table_name in db.metadata.tables.keys():
            print(f"   - {table_name}")
        
        print("\n🎉 БД успешно пересоздана!")

if __name__ == '__main__':
    force_recreate_db()
