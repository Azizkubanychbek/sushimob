from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

# Создаем экземпляр db для моделей
db = SQLAlchemy()

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
    favorites = db.Column(db.Text, nullable=True)  # JSON строка с избранными
    cart = db.Column(db.Text, nullable=True)  # JSON строка с корзиной
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login_at = db.Column(db.DateTime)
    is_active = db.Column(db.Boolean, default=True)
    is_admin = db.Column(db.Boolean, default=False)  # Права администратора

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'location': self.location,
            'loyalty_points': self.loyalty_points,
            'favorites': self.favorites,
            'cart': self.cart,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login_at': self.last_login_at.isoformat() if self.last_login_at else None,
            'is_active': self.is_active,
            'is_admin': self.is_admin
        }

# Модель ингредиентов
class Ingredient(db.Model):
    __tablename__ = 'ingredients'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    cost_per_unit = db.Column(db.Float, nullable=False)  # Стоимость за 1 шт
    price_per_unit = db.Column(db.Float, nullable=False)  # Цена за 1 шт
    stock_quantity = db.Column(db.Float, default=0)  # Остаток на складе
    unit = db.Column(db.String(20), nullable=False)  # Единица измерения (кг, шт, лист)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'cost_per_unit': self.cost_per_unit,
            'price_per_unit': self.price_per_unit,
            'stock_quantity': self.stock_quantity,
            'unit': self.unit,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Модель роллов
class Roll(db.Model):
    __tablename__ = 'rolls'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    cost_price = db.Column(db.Float, nullable=False)  # Себестоимость
    sale_price = db.Column(db.Float, nullable=False)  # Цена на продажу
    image_url = db.Column(db.String(255), nullable=True)
    is_popular = db.Column(db.Boolean, default=False)
    is_new = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Связи
    ingredients = db.relationship('RollIngredient', back_populates='roll', cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'cost_price': self.cost_price,
            'sale_price': self.sale_price,
            'image_url': self.image_url,
            'is_popular': self.is_popular,
            'is_new': self.is_new,
            'ingredients': [ing.to_dict() for ing in self.ingredients],
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Модель состава роллов (связь многие-ко-многим)
class RollIngredient(db.Model):
    __tablename__ = 'roll_ingredients'
    
    id = db.Column(db.Integer, primary_key=True)
    roll_id = db.Column(db.Integer, db.ForeignKey('rolls.id'), nullable=False)
    ingredient_id = db.Column(db.Integer, db.ForeignKey('ingredients.id'), nullable=False)
    amount_per_roll = db.Column(db.Float, nullable=False)  # Количество ингредиента на ролл
    
    # Связи
    roll = db.relationship('Roll', back_populates='ingredients')
    ingredient = db.relationship('Ingredient')

    def to_dict(self):
        return {
            'id': self.id,
            'roll_id': self.roll_id,
            'ingredient_id': self.ingredient_id,
            'amount_per_roll': self.amount_per_roll,
            'ingredient': self.ingredient.to_dict() if self.ingredient else None
        }

# Модель сетов
class Set(db.Model):
    __tablename__ = 'sets'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    cost_price = db.Column(db.Float, nullable=False)  # Себестоимость сета
    set_price = db.Column(db.Float, nullable=False)  # Цена сета
    discount_percent = db.Column(db.Float, default=0)  # Процент скидки
    image_url = db.Column(db.String(255), nullable=True)
    is_popular = db.Column(db.Boolean, default=False)
    is_new = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Связи
    rolls = db.relationship('SetRoll', back_populates='set', cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'cost_price': self.cost_price,
            'set_price': self.set_price,
            'discount_percent': self.discount_percent,
            'image_url': self.image_url,
            'is_popular': self.is_popular,
            'is_new': self.is_new,
            'rolls': [sr.to_dict() for sr in self.rolls],
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Модель состава сетов (связь многие-ко-многим)
class SetRoll(db.Model):
    __tablename__ = 'set_rolls'
    
    id = db.Column(db.Integer, primary_key=True)
    set_id = db.Column(db.Integer, db.ForeignKey('sets.id'), nullable=False)
    roll_id = db.Column(db.Integer, db.ForeignKey('rolls.id'), nullable=False)
    quantity = db.Column(db.Integer, default=1)  # Количество роллов в сете
    
    # Связи
    set = db.relationship('Set', back_populates='rolls')
    roll = db.relationship('Roll')

    def to_dict(self):
        return {
            'id': self.id,
            'set_id': self.set_id,
            'roll_id': self.roll_id,
            'quantity': self.quantity,
            'roll': self.roll.to_dict() if self.roll else None
        }

# Модель заказов
class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    phone = db.Column(db.String(20), nullable=False)  # Номер для связи
    delivery_address = db.Column(db.Text, nullable=False)  # Адрес доставки
    payment_method = db.Column(db.String(50), nullable=False)  # Способ оплаты
    status = db.Column(db.String(50), default='Принят')  # Статус заказа
    total_price = db.Column(db.Float, nullable=False)  # Общая стоимость
    comment = db.Column(db.Text, nullable=True)  # Комментарий к заказу
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Связи
    user = db.relationship('User')
    items = db.relationship('OrderItem', back_populates='order', cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'phone': self.phone,
            'delivery_address': self.delivery_address,
            'payment_method': self.payment_method,
            'status': self.status,
            'total_price': self.total_price,
            'comment': self.comment,
            'items': [item.to_dict() for item in self.items],
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Модель элементов заказа
class OrderItem(db.Model):
    __tablename__ = 'order_items'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    item_type = db.Column(db.String(20), nullable=False)  # 'roll' или 'set'
    item_id = db.Column(db.Integer, nullable=False)  # ID ролла или сета
    quantity = db.Column(db.Integer, nullable=False)  # Количество
    unit_price = db.Column(db.Float, nullable=False)  # Цена за единицу
    total_price = db.Column(db.Float, nullable=False)  # Общая цена
    
    # Связи
    order = db.relationship('Order', back_populates='items')

    def to_dict(self):
        return {
            'id': self.id,
            'order_id': self.order_id,
            'item_type': self.item_type,
            'item_id': self.item_id,
            'quantity': self.quantity,
            'unit_price': self.unit_price,
            'total_price': self.total_price
        }

# Модель дополнительных товаров (соусы, напитки, другое)
class OtherItem(db.Model):
    __tablename__ = 'other_items'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    cost_price = db.Column(db.Float, nullable=False)  # Себестоимость
    sale_price = db.Column(db.Float, nullable=False)  # Цена продажи
    category = db.Column(db.String(50), nullable=False)  # 'соусы', 'напитки', 'другое'
    image_url = db.Column(db.String(255), nullable=True)
    stock_quantity = db.Column(db.Float, default=0)  # Остаток на складе
    unit = db.Column(db.String(20), default='шт')  # Единица измерения
    is_popular = db.Column(db.Boolean, default=False)
    is_new = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'cost_price': self.cost_price,
            'sale_price': self.sale_price,
            'category': self.category,
            'image_url': self.image_url,
            'stock_quantity': self.stock_quantity,
            'unit': self.unit,
            'is_popular': self.is_popular,
            'is_new': self.is_new,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
