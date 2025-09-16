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
    bonus_points = db.Column(db.Integer, default=0)  # Бонусные баллы от рефералов
    referral_code = db.Column(db.String(20), unique=True, nullable=True)  # Уникальный реферальный код пользователя
    referred_by = db.Column(db.String(20), nullable=True)  # Код пользователя, который пригласил
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
            'bonus_points': self.bonus_points,
            'referral_code': self.referral_code,
            'referred_by': self.referred_by,
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
            'price': self.sale_price,  # Добавляем поле price для совместимости
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
        # Получаем название товара
        item_name = 'Товар'
        item_image = ''
        
        if self.item_type == 'roll':
            roll = Roll.query.get(self.item_id)
            if roll:
                item_name = roll.name
                item_image = roll.image_url or ''
        elif self.item_type == 'set':
            set_item = Set.query.get(self.item_id)
            if set_item:
                item_name = set_item.name
                item_image = set_item.image_url or ''
        elif self.item_type == 'other_item':
            other_item = OtherItem.query.get(self.item_id)
            if other_item:
                item_name = other_item.name
                item_image = other_item.image_url or ''
        
        return {
            'id': self.id,
            'order_id': self.order_id,
            'item_type': self.item_type,
            'item_id': self.item_id,
            'item_name': item_name,
            'item_image': item_image,
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

# Модель накопительных карт лояльности
class LoyaltyCard(db.Model):
    __tablename__ = 'loyalty_cards'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    card_number = db.Column(db.String(50), nullable=False)  # Номер карты (например, LC-001)
    filled_rolls = db.Column(db.Integer, default=0)  # Количество заполненных роллов (0-8)
    is_completed = db.Column(db.Boolean, default=False)  # Карта полностью заполнена
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime, nullable=True)  # Когда карта была заполнена
    
    # Связи
    user = db.relationship('User')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'card_number': self.card_number,
            'filled_rolls': self.filled_rolls,
            'is_completed': self.is_completed,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'progress_percent': (self.filled_rolls / 8) * 100  # Процент заполнения
        }

# Модель роллов доступных для накопительной системы
class LoyaltyRoll(db.Model):
    __tablename__ = 'loyalty_rolls'
    
    id = db.Column(db.Integer, primary_key=True)
    roll_id = db.Column(db.Integer, db.ForeignKey('rolls.id'), nullable=False)
    is_available = db.Column(db.Boolean, default=True)  # Доступен ли ролл для получения
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Связи
    roll = db.relationship('Roll')
    
    def to_dict(self):
        return {
            'id': self.id,
            'roll_id': self.roll_id,
            'is_available': self.is_available,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'roll': self.roll.to_dict() if self.roll else None
        }

# Модель истории использования накопительных карт
class LoyaltyCardUsage(db.Model):
    __tablename__ = 'loyalty_card_usage'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    loyalty_card_id = db.Column(db.Integer, db.ForeignKey('loyalty_cards.id'), nullable=False)
    roll_id = db.Column(db.Integer, db.ForeignKey('rolls.id'), nullable=False)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=True)  # Если получен через заказ
    used_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Связи
    user = db.relationship('User')
    loyalty_card = db.relationship('LoyaltyCard')
    roll = db.relationship('Roll')
    order = db.relationship('Order')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'loyalty_card_id': self.loyalty_card_id,
            'roll_id': self.roll_id,
            'order_id': self.order_id,
            'used_at': self.used_at.isoformat() if self.used_at else None,
            'roll': self.roll.to_dict() if self.roll else None,
            'card_number': self.loyalty_card.card_number if self.loyalty_card else None
        }

# Модель реферальных кодов
class ReferralCode(db.Model):
    __tablename__ = 'referral_codes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    code = db.Column(db.String(20), unique=True, nullable=False)  # Уникальный код
    is_active = db.Column(db.Boolean, default=True)  # Активен ли код
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Связи
    user = db.relationship('User', backref='referral_code_record')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'code': self.code,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

# Модель использования реферальных кодов
class ReferralUsage(db.Model):
    __tablename__ = 'referral_usage'
    
    id = db.Column(db.Integer, primary_key=True)
    referrer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # Кто пригласил
    referred_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)  # Кого пригласили
    referral_code = db.Column(db.String(20), nullable=False)  # Использованный код
    bonus_points_awarded = db.Column(db.Integer, default=200)  # Количество бонусных баллов
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Связи
    referrer = db.relationship('User', foreign_keys=[referrer_id], backref='referrals_made')
    referred = db.relationship('User', foreign_keys=[referred_id], backref='referrals_received')
    
    def to_dict(self):
        return {
            'id': self.id,
            'referrer_id': self.referrer_id,
            'referred_id': self.referred_id,
            'referral_code': self.referral_code,
            'bonus_points_awarded': self.bonus_points_awarded,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'referrer_name': self.referrer.name if self.referrer else None,
            'referred_name': self.referred.name if self.referred else None
        }
