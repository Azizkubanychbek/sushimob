from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

# Создаем Flask приложение
app = Flask(__name__)

# Конфигурация для SQLite
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///sushi_express.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Инициализация SQLAlchemy
db = SQLAlchemy()
db.init_app(app)

# Модель пользователя
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    location = db.Column(db.String(200), nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    loyalty_points = db.Column(db.Integer, default=0)
    favorites = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login_at = db.Column(db.DateTime)
    is_active = db.Column(db.Boolean, default=True)

# Модель ингредиентов
class Ingredient(db.Model):
    __tablename__ = 'ingredients'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    cost_per_unit = db.Column(db.Float, nullable=False)
    price_per_unit = db.Column(db.Float, nullable=False)
    stock_quantity = db.Column(db.Float, default=0)
    unit = db.Column(db.String(20), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Модель роллов
class Roll(db.Model):
    __tablename__ = 'rolls'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    cost_price = db.Column(db.Float, nullable=False)
    sale_price = db.Column(db.Float, nullable=False)
    image_url = db.Column(db.String(255), nullable=True)
    is_popular = db.Column(db.Boolean, default=False)
    is_new = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Модель состава роллов
class RollIngredient(db.Model):
    __tablename__ = 'roll_ingredients'
    
    id = db.Column(db.Integer, primary_key=True)
    roll_id = db.Column(db.Integer, db.ForeignKey('rolls.id'), nullable=False)
    ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.id'), nullable=False)
    amount_per_roll = db.Column(db.Float, nullable=False)

# Модель сетов
class Set(db.Model):
    __tablename__ = 'sets'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    cost_price = db.Column(db.Float, nullable=False)
    set_price = db.Column(db.Float, nullable=False)
    discount_percent = db.Column(db.Float, default=0)
    image_url = db.Column(db.String(255), nullable=True)
    is_popular = db.Column(db.Boolean, default=False)
    is_new = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Модель состава сетов
class SetRoll(db.Model):
    __tablename__ = 'set_rolls'
    
    id = db.Column(db.Integer, primary_key=True)
    set_id = db.Column(db.Integer, db.ForeignKey('sets.id'), nullable=False)
    roll_id = db.Column(db.Integer, db.ForeignKey('rolls.id'), nullable=False)
    quantity = db.Column(db.Integer, default=1)

# Модель заказов
class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    delivery_address = db.Column(db.Text, nullable=False)
    payment_method = db.Column(db.String(50), nullable=False)
    status = db.Column(db.String(50), default='Принят')
    total_price = db.Column(db.Float, nullable=False)
    comment = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Модель элементов заказа
class OrderItem(db.Model):
    __tablename__ = 'order_items'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    item_type = db.Column(db.String(20), nullable=False)
    item_id = db.Column(db.Integer, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Float, nullable=False)
    total_price = db.Column(db.Float, nullable=False)

if __name__ == '__main__':
    # Удаляем старую БД если существует
    import os
    if os.path.exists('sushi_express.db'):
        os.remove('sushi_express.db')
        print("🗑️ Старая база данных удалена")
    
    # Создаем новую БД
    with app.app_context():
        db.create_all()
        print("✅ База данных SQLite создана!")
        print("📁 Файл: sushi_express.db")
        print("📊 Созданные таблицы:")
        print("   - users")
        print("   - ingredients") 
        print("   - rolls")
        print("   - roll_ingredients")
        print("   - sets")
        print("   - set_rolls")
        print("   - orders")
        print("   - order_items")
