from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import os
import json
from datetime import datetime, timedelta

# Создаем Flask приложение
app = Flask(__name__)

# Конфигурация для SQLite
app.config['SECRET_KEY'] = 'your-super-secret-key-change-this-in-production'
# Используем абсолютный путь к базе данных
db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sushi_express.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'jwt-secret-string'
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=30)

# Инициализация расширений
from models import db, User, Ingredient, Roll, RollIngredient, Set, SetRoll, Order, OrderItem, OtherItem, LoyaltyCard, LoyaltyRoll, LoyaltyCardUsage, ReferralUsage
db.init_app(app)

jwt = JWTManager()
jwt.init_app(app)

CORS(app)

# Импортируем модели после инициализации db
# from models import User, Ingredient, Roll, RollIngredient, Set, SetRoll, Order, OrderItem


# Маршруты API
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'OK', 
        'message': 'Sushi Express API is running!',
        'database': 'SQLite',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        # Валидация данных
        required_fields = ['name', 'email', 'phone', 'password']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'Поле {field} обязательно'}), 400
        
        # Локация необязательна
        location = data.get('location', '').strip() if data.get('location') else None
        
        # Проверка длины пароля
        if len(data['password']) < 6:
            return jsonify({'error': 'Пароль должен содержать минимум 6 символов'}), 400
        
        # Проверка существования пользователя
        existing_user = User.query.filter_by(email=data['email'].lower()).first()
        if existing_user:
            return jsonify({'error': 'Пользователь с таким email уже существует'}), 400
        
        # Обработка реферального кода
        referral_code = data.get('referral_code', '').strip().upper() if data.get('referral_code') else None
        referrer_user = None
        bonus_points = 0
        
        if referral_code:
            # Проверяем, что код существует и активен
            referrer_user = User.query.filter_by(referral_code=referral_code).first()
            if not referrer_user:
                return jsonify({'error': 'Неверный реферальный код'}), 400
            
            # Проверяем, что пользователь не приглашает сам себя
            if referrer_user.email.lower() == data['email'].strip().lower():
                return jsonify({'error': 'Нельзя использовать свой реферальный код'}), 400
            
            bonus_points = 200  # Бонусные баллы за регистрацию по реферальному коду
        
        # Создание нового пользователя
        new_user = User(
            name=data['name'].strip(),
            email=data['email'].strip().lower(),
            phone=data['phone'].strip(),
            location=data.get('location', '').strip() if data.get('location') else None,
            password_hash=generate_password_hash(data['password']),
            referred_by=referral_code,
            bonus_points=bonus_points
        )
        
        db.session.add(new_user)
        db.session.flush()  # Получаем ID пользователя
        
        # Генерируем реферальный код для нового пользователя
        import random
        import string
        
        def generate_referral_code():
            return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        
        # Генерируем уникальный реферальный код
        while True:
            new_referral_code = generate_referral_code()
            existing_code = User.query.filter_by(referral_code=new_referral_code).first()
            if not existing_code:
                break
        
        new_user.referral_code = new_referral_code
        
        # Если использовался реферальный код, создаем запись об использовании
        if referrer_user and referral_code:
            referral_usage = ReferralUsage(
                referrer_id=referrer_user.id,
                referred_id=new_user.id,
                referral_code=referral_code,
                bonus_points_awarded=200
            )
            db.session.add(referral_usage)
            
            print(f"✅ Реферальный код {referral_code} использован. Приглашен: {new_user.name}, Пригласил: {referrer_user.name}")
        
        db.session.commit()
        
        print(f"✅ Новый пользователь зарегистрирован: {new_user.name} ({new_user.email})")
        print(f"✅ Реферальный код пользователя: {new_referral_code}")
        
        # Создание JWT токена
        access_token = create_access_token(identity=new_user.id)
        
        return jsonify({
            'success': True,
            'message': 'Регистрация прошла успешно!',
            'user': new_user.to_dict(),
            'access_token': access_token
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка при регистрации: {e}")
        return jsonify({'error': f'Ошибка при регистрации: {str(e)}'}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        # Валидация данных
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email и пароль обязательны'}), 400
        
        # Поиск пользователя
        user = User.query.filter_by(email=data['email'].lower()).first()
        if not user:
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        # Проверка пароля
        if not check_password_hash(user.password_hash, data['password']):
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        # Проверка активности аккаунта
        if not user.is_active:
            return jsonify({'error': 'Аккаунт деактивирован'}), 401
        
        # Обновление времени последнего входа
        user.last_login_at = datetime.utcnow()
        db.session.commit()
        
        print(f"✅ Пользователь вошел в систему: {user.name} ({user.email})")
        
        # Создание JWT токена
        access_token = create_access_token(identity=user.id)
        
        return jsonify({
            'success': True,
            'message': f'Добро пожаловать, {user.name}!',
            'user': user.to_dict(),
            'access_token': access_token
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при входе: {e}")
        return jsonify({'error': f'Ошибка при входе: {str(e)}'}), 500

@app.route('/api/profile', methods=['GET'])
@jwt_required()
def get_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        return jsonify({
            'success': True,
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении профиля: {e}")
        return jsonify({'error': f'Ошибка при получении профиля: {str(e)}'}), 500

@app.route('/api/users', methods=['GET'])
@jwt_required()
def get_users():
    try:
        users = User.query.all()
        print(f"🔍 Запрошен список пользователей. Всего: {len(users)}")
        return jsonify({
            'success': True,
            'users': [user.to_dict() for user in users],
            'total': len(users)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении пользователей: {e}")
        return jsonify({'error': f'Ошибка при получении пользователей: {str(e)}'}), 500

@app.route('/api/profile', methods=['PUT'])
@app.route('/api/profile/update', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        
        # Обновляем только разрешенные поля
        if 'name' in data:
            user.name = data['name'].strip()
        if 'phone' in data:
            user.phone = data['phone'].strip()
        if 'location' in data:
            user.location = data['location'].strip() if data['location'] else None
        
        db.session.commit()
        print(f"✅ Профиль пользователя {user.name} обновлен")
        
        return jsonify({
            'success': True,
            'message': 'Профиль успешно обновлен',
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при обновлении профиля: {e}")
        return jsonify({'error': f'Ошибка при обновлении профиля: {str(e)}'}), 500

@app.route('/api/profile/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        
        if not current_password or not new_password:
            return jsonify({'error': 'Текущий и новый пароль обязательны'}), 400
        
        # Проверяем текущий пароль
        if not check_password_hash(user.password_hash, current_password):
            return jsonify({'error': 'Неверный текущий пароль'}), 401
        
        # Проверяем длину нового пароля
        if len(new_password) < 6:
            return jsonify({'error': 'Новый пароль должен содержать минимум 6 символов'}), 400
        
        # Обновляем пароль
        user.password_hash = generate_password_hash(new_password)
        db.session.commit()
        
        print(f"✅ Пароль пользователя {user.name} изменен")
        
        return jsonify({
            'success': True,
            'message': 'Пароль успешно изменен'
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при изменении пароля: {e}")
        return jsonify({'error': f'Ошибка при изменении пароля: {str(e)}'}), 500

@app.route('/api/debug/users', methods=['GET'])
def debug_users():
    """Отладочный endpoint для просмотра всех пользователей без авторизации"""
    try:
        users = User.query.all()
        print(f"🔍 Отладочный запрос пользователей. Всего: {len(users)}")
        return jsonify({
            'success': True,
            'users': [user.to_dict() for user in users],
            'total': len(users),
            'database_file': 'sushi_express.db'
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при отладочном запросе: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/favorites/add', methods=['POST'])
@jwt_required()
def add_to_favorites():
    """Добавление ролла/сета в избранное"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        item_type = data.get('item_type') or data.get('type')  # 'roll' или 'set'
        item_id = data.get('item_id') or data.get('id')
        
        if not item_type or not item_id:
            return jsonify({'error': 'Тип и ID элемента обязательны'}), 400
        
        # Парсим текущие избранные
        favorites = json.loads(user.favorites) if user.favorites else {}
        
        if item_type not in favorites:
            favorites[item_type] = []
        
        if item_id not in favorites[item_type]:
            favorites[item_type].append(item_id)
            user.favorites = json.dumps(favorites)
            db.session.commit()
            
            print(f"✅ {item_type} {item_id} добавлен в избранное для {user.name}")
            
            return jsonify({
                'success': True,
                'message': f'{item_type.title()} добавлен в избранное',
                'favorites': favorites
            }), 200
        else:
            return jsonify({'error': f'{item_type.title()} уже в избранном'}), 400
            
    except Exception as e:
        print(f"❌ Ошибка при добавлении в избранное: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/favorites/remove', methods=['POST', 'DELETE'])
@jwt_required()
def remove_from_favorites():
    """Удаление ролла/сета из избранного"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 400
        
        data = request.get_json()
        item_type = data.get('item_type') or data.get('type')  # 'roll' или 'set'
        item_id = data.get('item_id') or data.get('id')
        
        if not item_type or not item_id:
            return jsonify({'error': 'Тип и ID элемента обязательны'}), 400
        
        # Парсим текущие избранные
        favorites = json.loads(user.favorites) if user.favorites else {}
        
        if item_type in favorites and item_id in favorites[item_type]:
            favorites[item_type].remove(item_id)
            user.favorites = json.dumps(favorites)
            db.session.commit()
            
            print(f"✅ {item_type} {item_id} удален из избранного для {user.name}")
            
            return jsonify({
                'success': True,
                'message': f'{item_type.title()} удален из избранного',
                'favorites': favorites
            }), 200
        else:
            return jsonify({'error': f'{item_type.title()} не найден в избранном'}), 404
            
    except Exception as e:
        print(f"❌ Ошибка при удалении из избранного: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/favorites', methods=['GET'])
@jwt_required()
def get_favorites():
    """Получение списка избранного пользователя"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        favorites = json.loads(user.favorites) if user.favorites else {}
        
        # Преобразуем в формат, ожидаемый Flutter
        favorites_list = []
        for item_type, item_ids in favorites.items():
            for item_id in item_ids:
                # Получаем данные элемента из базы
                item_data = None
                if item_type == 'roll':
                    roll = Roll.query.get(item_id)
                    if roll:
                        item_data = roll.to_dict()
                elif item_type == 'set':
                    set_item = Set.query.get(item_id)
                    if set_item:
                        item_data = set_item.to_dict()
                
                if item_data:
                    favorites_list.append({
                        'id': len(favorites_list) + 1,
                        'item_type': item_type,
                        'item_id': item_id,
                        'item': item_data,
                        'added_at': datetime.now().isoformat()
                    })
        
        return jsonify({
            'success': True,
            'favorites': favorites_list,
            'total': len(favorites_list)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении избранного: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для роллов =====
@app.route('/api/rolls', methods=['GET'])
def get_rolls():
    """Получение всех роллов"""
    try:
        rolls = Roll.query.all()
        return jsonify({
            'success': True,
            'rolls': [roll.to_dict() for roll in rolls],
            'total': len(rolls)
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении роллов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/rolls/<int:roll_id>', methods=['GET'])
def get_roll(roll_id):
    """Получение конкретного ролла"""
    try:
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        return jsonify({
            'success': True,
            'roll': roll.to_dict()
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении ролла: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для сетов =====
@app.route('/api/sets', methods=['GET'])
def get_sets():
    """Получение всех сетов"""
    try:
        sets = Set.query.all()
        return jsonify({
            'success': True,
            'sets': [set_item.to_dict() for set_item in sets],
            'total': len(sets)
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении сетов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/sets/<int:set_id>', methods=['GET'])
def get_set(set_id):
    """Получение конкретного сета"""
    try:
        set_item = Set.query.get(set_id)
        if not set_item:
            return jsonify({'error': 'Сет не найден'}), 404
        
        return jsonify({
            'success': True,
            'set': set_item.to_dict()
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении сета: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для дополнительных товаров (соусы, напитки) =====
@app.route('/api/other-items', methods=['GET'])
def get_other_items():
    """Получение всех дополнительных товаров"""
    try:
        other_items = OtherItem.query.all()
        return jsonify({
            'success': True,
            'other_items': [item.to_dict() for item in other_items],
            'total': len(other_items)
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении дополнительных товаров: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/other-items/<int:item_id>', methods=['GET'])
def get_other_item(item_id):
    """Получение конкретного дополнительного товара"""
    try:
        item = OtherItem.query.get(item_id)
        if not item:
            return jsonify({'error': 'Товар не найден'}), 404
        
        return jsonify({
            'success': True,
            'other_item': item.to_dict()
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении товара: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/other-items/category/<category>', methods=['GET'])
def get_other_items_by_category(category):
    """Получение дополнительных товаров по категории"""
    try:
        items = OtherItem.query.filter_by(category=category).all()
        return jsonify({
            'success': True,
            'category': category,
            'other_items': [item.to_dict() for item in items],
            'total': len(items)
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении товаров категории {category}: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для заказов =====
@app.route('/api/orders', methods=['POST'])
@jwt_required()
def create_order():
    """Создание нового заказа"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        
        # Получаем данные из корзины пользователя
        cart = json.loads(user.cart) if user.cart else []
        
        if not cart:
            return jsonify({'error': 'Корзина пуста'}), 400
        
        # Подготавливаем данные заказа
        phone = data.get('phone', user.phone)
        delivery_address = data.get('delivery_address', user.location or '')
        payment_method = data.get('payment_method', 'cash')
        comment = data.get('comment', '')
        
        # Вычисляем общую стоимость из корзины
        total_price = 0
        has_paid_items = False  # Флаг для проверки наличия платных товаров
        
        for cart_item in cart:
            item_type = cart_item['item_type']
            item_id = cart_item['item_id']
            quantity = cart_item['quantity']
            
            unit_price = 0
            if item_type == 'roll':
                roll = Roll.query.get(item_id)
                if roll:
                    unit_price = roll.sale_price
                    has_paid_items = True
            elif item_type == 'set':
                set_item = Set.query.get(item_id)
                if set_item:
                    unit_price = set_item.set_price
                    has_paid_items = True
            elif item_type == 'loyalty_roll':
                # Бесплатные роллы не влияют на общую стоимость
                unit_price = 0.0
            elif item_type == 'bonus_points':
                # Бонусные баллы (скидка) - не считаем как платный товар
                unit_price = cart_item.get('price', 0)  # Отрицательная цена
            
            total_price += unit_price * quantity
        
        # Если в корзине только бонусные баллы (скидки), не позволяем оформить заказ
        if not has_paid_items:
            return jsonify({'error': 'В корзине нет товаров для заказа'}), 400
        
        # Используем переданную сумму если она больше 0
        if data.get('total_amount', 0) > 0:
            total_price = data.get('total_amount', 0)
        elif data.get('total_price', 0) > 0:
            total_price = data.get('total_price', 0)
        
        # Валидация отрицательных сумм
        if total_price < 0:
            return jsonify({'error': 'Сумма заказа не может быть отрицательной'}), 400
        
        # Дополнительная валидация переданной суммы
        if data.get('total_amount', 0) < 0 or data.get('total_price', 0) < 0:
            return jsonify({'error': 'Переданная сумма заказа не может быть отрицательной'}), 400
        
        # Создаем заказ
        order = Order(
            user_id=user_id,
            phone=phone,
            delivery_address=delivery_address,
            payment_method=payment_method,
            total_price=total_price,
            comment=comment
        )
        
        db.session.add(order)
        db.session.flush()  # Получаем ID заказа
        
        # Добавляем элементы заказа из корзины
        for cart_item in cart:
            # Получаем данные товара
            item_type = cart_item['item_type']
            item_id = cart_item['item_id']
            quantity = cart_item['quantity']
            
            # Вычисляем цены
            unit_price = 0
            if item_type == 'roll':
                roll = Roll.query.get(item_id)
                if roll:
                    unit_price = roll.sale_price
            elif item_type == 'set':
                set_item = Set.query.get(item_id)
                if set_item:
                    unit_price = set_item.set_price
            elif item_type == 'loyalty_roll':
                # Бесплатные роллы из накопительных карт
                roll = Roll.query.get(item_id)
                if roll:
                    unit_price = 0.0  # Бесплатно
            elif item_type == 'bonus_points':
                # Бонусные баллы (скидка) - не создаем OrderItem для них
                continue
            
            total_item_price = unit_price * quantity
            
            order_item = OrderItem(
                order_id=order.id,
                item_type=item_type,
                item_id=item_id,
                quantity=quantity,
                unit_price=unit_price,
                total_price=total_item_price
            )
            db.session.add(order_item)
        
        # Очищаем корзину после создания заказа
        user.cart = '[]'
        
        # Обрабатываем накопительную карту
        process_loyalty_card(user_id, total_price)
        
        db.session.commit()
        
        print(f"✅ Новый заказ создан: ID {order.id}, пользователь {user_id}")
        print(f"📦 Товаров в заказе: {len(cart)}")
        print(f"💰 Общая стоимость: {total_price}₽")
        
        return jsonify({
            'success': True,
            'message': 'Заказ успешно создан',
            'order': order.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка при создании заказа: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для накопительных карт =====
@app.route('/api/loyalty/cards', methods=['GET'])
@jwt_required()
def get_loyalty_cards():
    """Получение накопительных карт пользователя"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем все карты пользователя
        cards = LoyaltyCard.query.filter_by(user_id=user_id).order_by(LoyaltyCard.created_at.desc()).all()
        
        return jsonify({
            'success': True,
            'cards': [card.to_dict() for card in cards],
            'total': len(cards)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении накопительных карт: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/loyalty/available-rolls', methods=['GET'])
@jwt_required()
def get_available_loyalty_rolls():
    """Получение доступных роллов для накопительной системы"""
    try:
        # Получаем доступные роллы
        loyalty_rolls = LoyaltyRoll.query.filter_by(is_available=True).all()
        
        return jsonify({
            'success': True,
            'rolls': [lr.to_dict() for lr in loyalty_rolls],
            'total': len(loyalty_rolls)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении доступных роллов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/loyalty/use-card', methods=['POST'])
@jwt_required()
def use_loyalty_card():
    """Использование заполненной накопительной карты"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        card_id = data.get('card_id')
        roll_id = data.get('roll_id')
        
        if not card_id or not roll_id:
            return jsonify({'error': 'ID карты и ролла обязательны'}), 400
        
        # Проверяем что карта принадлежит пользователю и заполнена
        card = LoyaltyCard.query.filter_by(
            id=card_id, 
            user_id=user_id, 
            is_completed=True
        ).first()
        
        if not card:
            return jsonify({'error': 'Карта не найдена или не заполнена'}), 404
        
        # Проверяем что ролл доступен для накопительной системы
        loyalty_roll = LoyaltyRoll.query.filter_by(
            roll_id=roll_id, 
            is_available=True
        ).first()
        
        if not loyalty_roll:
            return jsonify({'error': 'Ролл недоступен для накопительной системы'}), 400
        
        # Получаем информацию о ролле
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        # Добавляем ролл в корзину пользователя с ценой 0₽
        cart = json.loads(user.cart) if user.cart else []
        
        # Проверяем, есть ли уже такой ролл в корзине
        cart_item_exists = False
        for item in cart:
            if item.get('item_type') == 'loyalty_roll' and item.get('item_id') == roll_id:
                # Увеличиваем количество
                item['quantity'] += 1
                cart_item_exists = True
                break
        
        if not cart_item_exists:
            # Добавляем новый товар в корзину
            cart_item = {
                'item_type': 'loyalty_roll',
                'item_id': roll_id,
                'quantity': 1,
                'price': 0.0,  # Бесплатно благодаря накопительной карте
                'name': roll.name,
                'is_loyalty': True  # Флаг что это бесплатный ролл
            }
            cart.append(cart_item)
        
        # Обновляем корзину пользователя
        user.cart = json.dumps(cart)
        
        # Создаем запись об использовании карты
        usage = LoyaltyCardUsage(
            user_id=user_id,
            loyalty_card_id=card_id,
            roll_id=roll_id
        )
        db.session.add(usage)
        
        # Удаляем использованную карту
        db.session.delete(card)
        
        db.session.commit()
        
        print(f"✅ Накопительная карта использована: карта {card.card_number}, ролл {roll.name} добавлен в корзину")
        
        return jsonify({
            'success': True,
            'message': f'Ролл "{roll.name}" добавлен в корзину бесплатно!',
            'used_card': card.to_dict(),
            'selected_roll': loyalty_roll.to_dict(),
            'added_to_cart': True
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка при использовании накопительной карты: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/loyalty/history', methods=['GET'])
@jwt_required()
def get_loyalty_history():
    """Получение истории использования накопительных карт"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем историю использования
        history = LoyaltyCardUsage.query.filter_by(user_id=user_id).order_by(LoyaltyCardUsage.used_at.desc()).all()
        
        return jsonify({
            'success': True,
            'history': [h.to_dict() for h in history],
            'total': len(history)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении истории: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/orders', methods=['GET'])
@jwt_required()
def get_user_orders():
    """Получение заказов пользователя"""
    try:
        user_id = get_jwt_identity()
        orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
        
        return jsonify({
            'success': True,
            'orders': [order.to_dict() for order in orders],
            'total': len(orders)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении заказов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/orders/<int:order_id>', methods=['GET'])
@jwt_required()
def get_order(order_id):
    """Получение конкретного заказа"""
    try:
        user_id = get_jwt_identity()
        order = Order.query.get(order_id)
        
        if not order:
            return jsonify({'error': 'Заказ не найден'}), 404
        
        if order.user_id != user_id:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        return jsonify({
            'success': True,
            'order': order.to_dict()
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении заказа: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для ингредиентов =====
@app.route('/api/ingredients', methods=['GET'])
def get_ingredients():
    """Получение всех ингредиентов"""
    try:
        ingredients = Ingredient.query.all()
        return jsonify({
            'success': True,
            'ingredients': [ing.to_dict() for ing in ingredients],
            'total': len(ingredients)
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении ингредиентов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для избранного =====
# Функция get_favorites уже определена выше в файле (строка ~348)

# Функция add_to_favorites уже определена выше в файле (строка ~310)

# Функция remove_from_favorites уже определена выше в файле (строка ~330)

@app.route('/api/favorites/clear', methods=['DELETE'])
@jwt_required()
def clear_favorites():
    """Очистка избранного"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        user.favorites = '{}'
        db.session.commit()
        
        print(f"✅ Избранное очищено для пользователя {user.name}")
        
        return jsonify({
            'success': True,
            'message': 'Избранное очищено'
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при очистке избранного: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# ===== API для корзины =====
@app.route('/api/cart', methods=['GET'])
@jwt_required()
def get_cart():
    """Получение корзины пользователя"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Используем JSON поле cart в пользователе
        cart = json.loads(user.cart) if user.cart else []
        
        # Добавляем полные данные элементов
        cart_with_items = []
        for cart_item in cart:
            item_data = None
            if cart_item['item_type'] == 'roll':
                roll = Roll.query.get(cart_item['item_id'])
                if roll:
                    item_data = roll.to_dict()
            elif cart_item['item_type'] == 'set':
                set_item = Set.query.get(cart_item['item_id'])
                if set_item:
                    item_data = set_item.to_dict()
            elif cart_item['item_type'] == 'loyalty_roll':
                # Обработка бесплатных роллов из накопительных карт
                roll = Roll.query.get(cart_item['item_id'])
                if roll:
                    item_data = roll.to_dict()
                    # Переопределяем цену на 0 для бесплатных роллов
                    item_data['sale_price'] = 0.0
            elif cart_item['item_type'] == 'bonus_points':
                # Обработка бонусных баллов
                item_data = {
                    'id': 'bonus',
                    'name': cart_item.get('name', 'Бонусные баллы'),
                    'description': 'Скидка за бонусные баллы',
                    'sale_price': cart_item.get('price', 0),
                    'image_url': None
                }
            
            if item_data:
                cart_item_with_data = cart_item.copy()
                cart_item_with_data['item'] = item_data
                
                # Определяем цену в зависимости от типа товара
                if cart_item['item_type'] == 'loyalty_roll':
                    cart_item_with_data['price'] = 0.0  # Бесплатно
                    cart_item_with_data['is_loyalty'] = True
                    cart_item_with_data['is_bonus'] = False
                elif cart_item['item_type'] == 'bonus_points':
                    cart_item_with_data['price'] = item_data.get('sale_price', 0)  # Отрицательная цена = скидка
                    cart_item_with_data['is_loyalty'] = False
                    cart_item_with_data['is_bonus'] = True
                else:
                    cart_item_with_data['price'] = item_data.get('sale_price', item_data.get('set_price', 0))
                    cart_item_with_data['is_loyalty'] = False
                    cart_item_with_data['is_bonus'] = False
                
                cart_with_items.append(cart_item_with_data)
        
        # Вычисляем общую стоимость корзины
        total_price = 0
        for item in cart_with_items:
            if item.get('price'):
                total_price += item['price'] * item['quantity']
        
        return jsonify({
            'success': True,
            'cart': cart_with_items,
            'total': len(cart_with_items),
            'total_price': total_price,
            'bonus_points': user.bonus_points,
            'can_use_bonus': user.bonus_points > 0 and total_price > 0
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при получении корзины: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/add', methods=['POST'])
@jwt_required()
def add_to_cart():
    """Добавление товара в корзину"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        
        if not data.get('item_type') or not data.get('item_id') or not data.get('quantity'):
            return jsonify({'error': 'Тип, ID и количество элемента обязательны'}), 400
        
        # Валидация количества
        quantity = data.get('quantity')
        if quantity <= 0:
            return jsonify({'error': 'Количество должно быть больше 0'}), 400
        
        # Проверяем существование товара
        item_type = data['item_type']
        item_id = data['item_id']
        
        if item_type == 'roll':
            roll = Roll.query.get(item_id)
            if not roll:
                return jsonify({'error': 'Ролл не найден'}), 404
        elif item_type == 'set':
            set_item = Set.query.get(item_id)
            if not set_item:
                return jsonify({'error': 'Сет не найден'}), 404
        else:
            return jsonify({'error': 'Неизвестный тип товара'}), 400
        
        # Используем JSON поле cart в пользователе
        cart = json.loads(user.cart) if user.cart else []
        
        # Проверяем, есть ли уже такой товар в корзине
        existing_item = None
        for item in cart:
            if item['item_type'] == data['item_type'] and item['item_id'] == data['item_id']:
                existing_item = item
                break
        
        if existing_item:
            # Увеличиваем количество
            existing_item['quantity'] += quantity
        else:
            # Добавляем новый товар
            cart.append({
                'id': len(cart) + 1,
                'item_type': data['item_type'],
                'item_id': data['item_id'],
                'quantity': quantity,
                'added_at': datetime.now().isoformat()
            })
        
        user.cart = json.dumps(cart)
        db.session.commit()
        
        print(f"✅ Товар добавлен в корзину: {data['item_type']} ID {data['item_id']}, количество {quantity}")
        
        return jsonify({
            'success': True,
            'message': 'Товар добавлен в корзину',
            'cart': cart
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при добавлении в корзину: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/remove', methods=['DELETE'])
@app.route('/api/cart/remove/<int:item_id>', methods=['DELETE'])
@jwt_required()
def remove_from_cart(item_id=None):
    """Удаление товара из корзины"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Для DELETE запросов с item_id в URL, не требуем JSON
        if item_id is None:
            data = request.get_json() or {}
            item_id = data.get('item_id')
            if not item_id:
                return jsonify({'error': 'ID товара не указан'}), 400
            item_type = data.get('item_type')
            if not item_type:
                return jsonify({'error': 'Тип товара не указан'}), 400
        else:
            # Если item_id передан в URL, определяем тип по корзине
            cart = json.loads(user.cart) if user.cart else []
            item_type = None
            for item in cart:
                if item.get('id') == item_id:
                    item_type = item.get('item_type')
                    break
            
            if not item_type:
                return jsonify({'error': 'Товар не найден в корзине'}), 404
        
        # Получаем корзину из JSON поля
        cart = json.loads(user.cart) if user.cart else []
        
        # Удаляем товар с указанным ID и типом
        original_length = len(cart)
        cart = [item for item in cart if not (item.get('id') == item_id and item.get('item_type') == item_type)]
        
        if len(cart) == original_length:
            return jsonify({'error': 'Товар не найден в корзине'}), 404
        
        user.cart = json.dumps(cart)
        db.session.commit()
        
        print(f"✅ Товар удален из корзины: ID {item_id}")
        
        return jsonify({
            'success': True,
            'message': 'Товар удален из корзины'
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при удалении из корзины: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/update', methods=['PUT'])
@app.route('/api/cart/update/<int:item_id>', methods=['PUT'])
@jwt_required()
def update_cart_item(item_id=None):
    """Обновление количества товара в корзине"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        
        # Получаем данные из JSON
        if not data:
            return jsonify({'error': 'Данные не переданы'}), 400
        
        # Если item_id не передан в URL, берем из JSON
        if item_id is None:
            item_id = data.get('item_id')
            if not item_id:
                return jsonify({'error': 'ID товара не указан'}), 400
        
        item_type = data.get('item_type')
        if not item_type:
            return jsonify({'error': 'Тип товара не указан'}), 400
        
        if not data.get('quantity'):
            return jsonify({'error': 'Количество обязательно'}), 400
        
        new_quantity = int(data['quantity'])
        cart = json.loads(user.cart) if user.cart else []
        
        if new_quantity <= 0:
            # Если количество 0 или меньше, удаляем товар
            cart = [item for item in cart if not (item.get('item_id') == item_id and item.get('item_type') == item_type)]
        else:
            # Обновляем количество
            for item in cart:
                if item.get('item_id') == item_id and item.get('item_type') == item_type:
                    item['quantity'] = new_quantity
                    break
            else:
                # Если товар не найден, возвращаем ошибку
                return jsonify({'error': 'Товар не найден в корзине'}), 404
        
        user.cart = json.dumps(cart)
        
        db.session.commit()
        
        print(f"✅ Количество товара обновлено: ID {item_id}, новое количество {new_quantity}")
        
        return jsonify({
            'success': True,
            'message': 'Количество обновлено'
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при обновлении корзины: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/clear', methods=['DELETE'])
@jwt_required()
def clear_cart():
    """Очистка корзины"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Очищаем корзину
        user.cart = '[]'
        db.session.commit()
        
        print(f"✅ Корзина очищена для пользователя {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'Корзина очищена'
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при очистке корзины: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

# Админ API endpoints
@app.route('/api/admin/users', methods=['GET'])
@jwt_required()
def admin_get_users():
    """Получить всех пользователей (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        users = User.query.all()
        return jsonify({
            'users': [user.to_dict() for user in users]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/rolls', methods=['GET', 'POST'])
@jwt_required()
def admin_rolls():
    """Получить список роллов или создать новый ролл (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        if request.method == 'GET':
            # Получить список роллов
            rolls = Roll.query.all()
            return jsonify({
                'rolls': [roll.to_dict() for roll in rolls],
                'total': len(rolls)
            })
        elif request.method == 'POST':
            # Создать новый ролл
            data = request.get_json()
            
            new_roll = Roll(
                name=data['name'],
                description=data.get('description', ''),
                cost_price=float(data['cost_price']),
                sale_price=float(data['sale_price']),
                image_url=data.get('image_url', ''),
                is_popular=data.get('is_popular', False),
                is_new=data.get('is_new', False)
            )
            
            db.session.add(new_roll)
            db.session.commit()
            
            return jsonify({
                'message': 'Ролл создан успешно',
                'roll': new_roll.to_dict()
            }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/rolls/<int:roll_id>', methods=['PUT'])
@jwt_required()
def admin_update_roll(roll_id):
    """Обновить ролл (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        data = request.get_json()
        
        roll.name = data.get('name', roll.name)
        roll.description = data.get('description', roll.description)
        roll.cost_price = float(data.get('cost_price', roll.cost_price))
        roll.sale_price = float(data.get('sale_price', roll.sale_price))
        roll.image_url = data.get('image_url', roll.image_url)
        roll.is_popular = data.get('is_popular', roll.is_popular)
        roll.is_new = data.get('is_new', roll.is_new)
        roll.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Ролл обновлен успешно',
            'roll': roll.to_dict()
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/rolls/<int:roll_id>', methods=['DELETE'])
@jwt_required()
def admin_delete_roll(roll_id):
    """Удалить ролл (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        db.session.delete(roll)
        db.session.commit()
        
        return jsonify({'message': 'Ролл удален успешно'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/rolls/<int:roll_id>/recipe', methods=['GET'])
def get_roll_recipe(roll_id):
    """Получить рецептуру ролла"""
    try:
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        # Получаем ингредиенты ролла
        roll_ingredients = RollIngredient.query.filter_by(roll_id=roll_id).all()
        
        ingredients = []
        for roll_ingredient in roll_ingredients:
            ingredient = Ingredient.query.get(roll_ingredient.ingredient_id)
            if ingredient:
                ingredients.append({
                    'ingredient': ingredient.to_dict(),
                    'quantity': roll_ingredient.amount_per_roll,
                    'unit': 'гр'  # По умолчанию граммы
                })
        
        return jsonify({
            'roll': roll.to_dict(),
            'ingredients': ingredients
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении рецепта ролла: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/admin/rolls/<int:roll_id>/recipe', methods=['GET'])
@jwt_required()
def admin_get_roll_recipe(roll_id):
    """Получить рецептуру ролла (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        # Получаем ингредиенты ролла из таблицы roll_ingredients
        cursor = db.session.execute(text("""
            SELECT ri.ingredient_id, ri.amount_per_roll, i.name, i.cost_per_unit, i.unit
            FROM roll_ingredients ri
            JOIN ingredients i ON ri.ingredient_id = i.id
            WHERE ri.roll_id = :roll_id
        """), {'roll_id': roll_id})
        
        ingredients = []
        total_cost = 0
        for row in cursor:
            amount_per_roll = float(row[1])
            cost_per_unit = float(row[3])
            ingredient_cost = amount_per_roll * cost_per_unit  # amount_per_roll * cost_per_unit
            total_cost += ingredient_cost
            
            ingredients.append({
                'ingredient_id': int(row[0]),
                'amount_per_roll': amount_per_roll,
                'name': row[2],
                'cost_per_unit': cost_per_unit,
                'unit': row[4],
                'calculated_cost': ingredient_cost
            })
        
        return jsonify({
            'roll_id': roll_id,
            'roll_name': roll.name,
            'ingredients': ingredients,
            'total_cost': total_cost
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/rolls/<int:roll_id>/recipe', methods=['PUT'])
@jwt_required()
def admin_update_roll_recipe(roll_id):
    """Обновить рецептуру ролла (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        data = request.get_json()
        ingredients = data.get('ingredients', [])
        
        # Удаляем старую рецептуру
        db.session.execute(text("DELETE FROM roll_ingredients WHERE roll_id = :roll_id"), 
                          {'roll_id': roll_id})
        
        # Добавляем новую рецептуру
        total_cost = 0
        for ingredient in ingredients:
            ingredient_id = ingredient['ingredient_id']
            amount = ingredient['amount']
            
            # Получаем стоимость ингредиента
            cursor = db.session.execute(text("""
                SELECT cost_per_unit FROM ingredients WHERE id = :ingredient_id
            """), {'ingredient_id': ingredient_id})
            
            result = cursor.fetchone()
            if result:
                cost_per_unit = result[0]
                cost = cost_per_unit * amount
                total_cost += cost
                
                # Добавляем ингредиент в рецепт
                db.session.execute(text("""
                    INSERT INTO roll_ingredients (roll_id, ingredient_id, amount_per_roll)
                    VALUES (:roll_id, :ingredient_id, :amount)
                """), {
                    'roll_id': roll_id,
                    'ingredient_id': ingredient_id,
                    'amount': amount
                })
            else:
                print(f"⚠️ Ингредиент с ID {ingredient_id} не найден")
        
        # Обновляем себестоимость ролла
        roll.cost_price = total_cost
        roll.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Рецептура ролла обновлена успешно',
            'total_cost': total_cost,
            'ingredients_count': len(ingredients)
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/sets', methods=['GET', 'POST'])
@jwt_required()
def admin_sets():
    """Получить список сетов или создать новый сет (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        if request.method == 'GET':
            # Получить список сетов
            sets = Set.query.all()
            return jsonify({
                'sets': [set_item.to_dict() for set_item in sets],
                'total': len(sets)
            })
        elif request.method == 'POST':
            # Создать новый сет
            data = request.get_json()
            
            new_set = Set(
                name=data['name'],
                description=data.get('description', ''),
                cost_price=float(data['cost_price']),
                set_price=float(data['set_price']),
                discount_percent=data.get('discount_percent', 0.0),
                image_url=data.get('image_url', ''),
                is_popular=data.get('is_popular', False),
                is_new=data.get('is_new', False)
            )
            
            db.session.add(new_set)
            db.session.commit()
            
            return jsonify({
                'message': 'Сет создан успешно',
                'set': new_set.to_dict()
            }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/sets/<int:set_id>', methods=['PUT'])
@jwt_required()
def admin_update_set(set_id):
    """Обновить сет (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        set_item = Set.query.get(set_id)
        if not set_item:
            return jsonify({'error': 'Сет не найден'}), 404
        
        data = request.get_json()
        
        set_item.name = data.get('name', set_item.name)
        set_item.description = data.get('description', set_item.description)
        set_item.cost_price = float(data.get('cost_price', set_item.cost_price))
        set_item.set_price = float(data.get('set_price', set_item.set_price))
        set_item.discount_percent = float(data.get('discount_percent', set_item.discount_percent))
        set_item.image_url = data.get('image_url', set_item.image_url)
        set_item.is_popular = data.get('is_popular', set_item.is_popular)
        set_item.is_new = data.get('is_new', set_item.is_new)
        set_item.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Сет обновлен успешно',
            'set': set_item.to_dict()
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/sets/<int:set_id>', methods=['DELETE'])
@jwt_required()
def admin_delete_set(set_id):
    """Удалить сет (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        set_item = Set.query.get(set_id)
        if not set_item:
            return jsonify({'error': 'Сет не найден'}), 404
        
        db.session.delete(set_item)
        db.session.commit()
        
        return jsonify({'message': 'Сет удален успешно'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/ingredients', methods=['GET'])
@jwt_required()
def admin_get_ingredients():
    """Получить все ингредиенты (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        ingredients = Ingredient.query.all()
        return jsonify({
            'ingredients': [ing.to_dict() for ing in ingredients],
            'total': len(ingredients)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/ingredients', methods=['POST'])
@jwt_required()
def admin_create_ingredient():
    """Создать новый ингредиент (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        data = request.get_json()
        
        new_ingredient = Ingredient(
            name=data['name'],
            cost_per_unit=float(data['cost_per_unit']),
            price_per_unit=float(data['price_per_unit']),
            stock_quantity=float(data.get('stock_quantity', 0)),
            unit=data['unit']
        )
        
        db.session.add(new_ingredient)
        db.session.commit()
        
        return jsonify({
            'message': 'Ингредиент создан успешно',
            'ingredient': new_ingredient.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/ingredients/<int:ingredient_id>', methods=['PUT'])
@jwt_required()
def admin_update_ingredient(ingredient_id):
    """Обновить ингредиент (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        ingredient = Ingredient.query.get(ingredient_id)
        if not ingredient:
            return jsonify({'error': 'Ингредиент не найден'}), 404
        
        data = request.get_json()
        
        ingredient.name = data.get('name', ingredient.name)
        ingredient.cost_per_unit = float(data.get('cost_per_unit', ingredient.cost_per_unit))
        ingredient.price_per_unit = float(data.get('price_per_unit', ingredient.price_per_unit))
        ingredient.stock_quantity = float(data.get('stock_quantity', ingredient.stock_quantity))
        ingredient.unit = data.get('unit', ingredient.unit)
        ingredient.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Ингредиент обновлен успешно',
            'ingredient': ingredient.to_dict()
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/ingredients/<int:ingredient_id>', methods=['DELETE'])
@jwt_required()
def admin_delete_ingredient(ingredient_id):
    """Удалить ингредиент (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        ingredient = Ingredient.query.get(ingredient_id)
        if not ingredient:
            return jsonify({'error': 'Ингредиент не найден'}), 404
        
        db.session.delete(ingredient)
        db.session.commit()
        
        return jsonify({'message': 'Ингредиент удален успешно'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Админ API endpoints для соусов/напитков (other_items)
@app.route('/api/admin/other-items', methods=['GET', 'POST'])
@jwt_required()
def admin_other_items():
    """Получить список других товаров или создать новый (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        if request.method == 'GET':
            # Получить список других товаров
            items = OtherItem.query.all()
            return jsonify({
                'items': [item.to_dict() for item in items],
                'total': len(items)
            })
        elif request.method == 'POST':
            # Создать новый товар
            data = request.get_json()
            
            new_item = OtherItem(
                name=data['name'],
                description=data.get('description', ''),
                cost_price=float(data['cost_price']),
                sale_price=float(data['sale_price']),
                category=data['category'],
                image_url=data.get('image_url', ''),
                stock_quantity=data.get('stock_quantity', 0),
                is_available=True
            )
            
            db.session.add(new_item)
            db.session.commit()
            
            return jsonify({
                'message': 'Товар создан успешно',
                'item': new_item.to_dict()
            }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/other-items/<int:item_id>', methods=['PUT'])
@jwt_required()
def admin_update_other_item(item_id):
    """Обновить товар (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        item = OtherItem.query.get(item_id)
        if not item:
            return jsonify({'error': 'Товар не найден'}), 404
        
        data = request.get_json()
        
        item.name = data.get('name', item.name)
        item.description = data.get('description', item.description)
        item.cost_price = float(data.get('cost_price', item.cost_price))
        item.sale_price = float(data.get('sale_price', item.sale_price))
        item.category = data.get('category', item.category)
        item.image_url = data.get('image_url', item.image_url)
        item.stock_quantity = data.get('stock_quantity', item.stock_quantity)
        item.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Товар обновлен успешно',
            'item': item.to_dict()
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/other-items/<int:item_id>', methods=['DELETE'])
@jwt_required()
def admin_delete_other_item(item_id):
    """Удалить товар (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        item = OtherItem.query.get(item_id)
        if not item:
            return jsonify({'error': 'Товар не найден'}), 404
        
        db.session.delete(item)
        db.session.commit()
        
        return jsonify({'message': 'Товар удален успешно'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/stats', methods=['GET'])
@jwt_required()
def admin_get_stats():
    """Получить статистику (только для админов)"""
    try:
        current_user_id = get_jwt_identity()
        current_user = User.query.get(current_user_id)
        
        if not current_user or not current_user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        total_users = User.query.count()
        total_rolls = Roll.query.count()
        total_sets = Set.query.count()
        total_ingredients = Ingredient.query.count()
        active_users = User.query.filter_by(is_active=True).count()
        
        return jsonify({
            'stats': {
                'total_users': total_users,
                'total_rolls': total_rolls,
                'total_sets': total_sets,
                'total_ingredients': total_ingredients,
                'active_users': active_users
            }
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API для работы с составом сетов
@app.route('/api/admin/sets/<int:set_id>/composition', methods=['GET'])
@jwt_required()
def admin_get_set_composition(set_id):
    """Получить состав сета"""
    try:
        # Проверяем права администратора
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        # Получаем состав сета
        query = text("""
            SELECT sr.set_id, sr.roll_id, sr.quantity,
                   r.name, r.cost_price, r.sale_price
            FROM set_rolls sr
            JOIN rolls r ON sr.roll_id = r.id
            WHERE sr.set_id = :set_id
        """)
        
        result = db.session.execute(query, {'set_id': set_id})
        rows = result.fetchall()
        
        composition = []
        for row in rows:
            composition.append({
                'set_id': row.set_id,
                'roll_id': row.roll_id,
                'quantity': row.quantity,
                'roll_name': row.name,
                'roll_cost_price': float(row.cost_price),
                'roll_sale_price': float(row.sale_price)
            })
        
        return jsonify({
            'success': True,
            'set_id': set_id,
            'composition': composition
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/admin/sets/<int:set_id>/composition', methods=['PUT'])
@jwt_required()
def admin_update_set_composition(set_id):
    """Обновить состав сета"""
    try:
        # Проверяем права администратора
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        data = request.get_json()
        items = data.get('items', [])
        
        # Удаляем старый состав
        db.session.execute(text("DELETE FROM set_rolls WHERE set_id = :set_id"), {'set_id': set_id})
        
        # Добавляем новый состав
        total_cost = 0
        total_sale_price = 0
        composition_for_description = []
        
        for item_data in items:
            item_id = item_data['item_id']
            item_type = item_data['item_type']
            quantity = item_data['quantity']
            
            # Пока поддерживаем только роллы (другие товары можно добавить позже)
            if item_type == 'roll':
                # Добавляем в состав
                db.session.execute(text("""
                    INSERT INTO set_rolls (set_id, roll_id, quantity)
                    VALUES (:set_id, :roll_id, :quantity)
                """), {'set_id': set_id, 'roll_id': item_id, 'quantity': quantity})
                
                # Получаем цены ролла для расчета
                roll_query = text("SELECT cost_price, sale_price, name FROM rolls WHERE id = :roll_id")
                roll_result = db.session.execute(roll_query, {'roll_id': item_id}).fetchone()
                if roll_result:
                    total_cost += roll_result.cost_price * quantity
                    total_sale_price += roll_result.sale_price * quantity
                    # Для описания сета
                    composition_for_description.append(f"{roll_result.name} x{quantity}")
        
        # Обновляем цены сета (со скидкой 10%)
        set_sale_price = total_sale_price * 0.9
        discount_percent = 10.0
        
        # Собираем описание состава сета, чтобы отображать пользователям
        description_text = 'Включает: ' + ', '.join(composition_for_description) if composition_for_description else ''

        db.session.execute(text("""
            UPDATE sets 
            SET cost_price = :cost_price, 
                set_price = :set_price,
                description = :description,
                discount_percent = :discount_percent
            WHERE id = :set_id
        """), {
            'set_id': set_id,
            'cost_price': total_cost,
            'set_price': set_sale_price,
            'description': description_text,
            'discount_percent': discount_percent
        })
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Состав сета обновлен',
            'calculated_cost_price': total_cost,
            'calculated_sale_price': set_sale_price,
            'discount_percent': discount_percent,
            'description': description_text,
            'composition': composition_for_description
        })
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Функция для инициализации накопительной системы
def initialize_loyalty_system():
    """Инициализация системы накопительных карт"""
    try:
        # Проверяем, есть ли уже накопительные роллы
        if LoyaltyRoll.query.count() == 0:
            # Получаем 5 самых дешевых роллов
            cheapest_rolls = Roll.query.order_by(Roll.sale_price.asc()).limit(5).all()
            
            for roll in cheapest_rolls:
                loyalty_roll = LoyaltyRoll(
                    roll_id=roll.id,
                    is_available=True
                )
                db.session.add(loyalty_roll)
            
            db.session.commit()
            print("✅ Система накопительных карт инициализирована!")
            print(f"📋 Добавлено {len(cheapest_rolls)} роллов для накопительной системы")
        else:
            print("✅ Система накопительных карт уже инициализирована")
            
    except Exception as e:
        print(f"❌ Ошибка инициализации накопительной системы: {e}")

# Функция для обработки накопительных карт при заказе
def process_loyalty_card(user_id, order_amount):
    """Обработка накопительных карт при создании заказа"""
    try:
        # Вычисляем количество роллов для накопления (каждые 1000 сом = 1 ролл)
        rolls_to_add = int(order_amount // 1000)
        
        if rolls_to_add == 0:
            return  # Ничего не накапливаем
        
        # Получаем текущую активную карту пользователя (не заполненную)
        active_card = LoyaltyCard.query.filter_by(
            user_id=user_id, 
            is_completed=False
        ).order_by(LoyaltyCard.created_at.desc()).first()
        
        # Если нет активной карты, создаем новую
        if not active_card:
            # Генерируем номер карты
            card_count = LoyaltyCard.query.filter_by(user_id=user_id).count() + 1
            card_number = f"LC-{user_id:03d}-{card_count:03d}"
            
            active_card = LoyaltyCard(
                user_id=user_id,
                card_number=card_number,
                filled_rolls=0,
                is_completed=False
            )
            db.session.add(active_card)
            db.session.flush()  # Получаем ID
        
        # Добавляем роллы к карте
        current_filled = active_card.filled_rolls
        new_filled = min(current_filled + rolls_to_add, 8)
        active_card.filled_rolls = new_filled
        
        # Если карта заполнена, отмечаем как завершенную
        if new_filled == 8:
            active_card.is_completed = True
            active_card.completed_at = datetime.utcnow()
            
            # Если остались лишние роллы, создаем новую карту
            extra_rolls = (current_filled + rolls_to_add) - 8
            if extra_rolls > 0:
                card_count = LoyaltyCard.query.filter_by(user_id=user_id).count() + 1
                new_card_number = f"LC-{user_id:03d}-{card_count:03d}"
                
                new_card = LoyaltyCard(
                    user_id=user_id,
                    card_number=new_card_number,
                    filled_rolls=extra_rolls,
                    is_completed=False
                )
                db.session.add(new_card)
        
        db.session.commit()
        print(f"✅ Накопительная карта обновлена: +{rolls_to_add} роллов")
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка обработки накопительной карты: {e}")

# Создание таблиц при запуске
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
    print("   - loyalty_cards")
    print("   - loyalty_rolls")
    print("   - loyalty_card_usage")
    
    # Инициализируем накопительную систему
    initialize_loyalty_system()

# ===== РЕФЕРАЛЬНАЯ СИСТЕМА =====

@app.route('/api/referral/my-code', methods=['GET'])
@jwt_required()
def get_my_referral_code():
    """Получить свой реферальный код"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        return jsonify({
            'referral_code': user.referral_code,
            'bonus_points': user.bonus_points,
            'referrals_count': len(user.referrals_made)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении реферального кода: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/referral/check-code', methods=['POST'])
def check_referral_code():
    """Проверить реферальный код"""
    try:
        data = request.get_json()
        referral_code = data.get('referral_code', '').strip().upper()
        
        if not referral_code:
            return jsonify({'error': 'Реферальный код не указан'}), 400
        
        # Проверяем существование кода
        referrer_user = User.query.filter_by(referral_code=referral_code).first()
        
        if not referrer_user:
            return jsonify({'error': 'Реферальный код не найден'}), 404
        
        return jsonify({
            'valid': True,
            'referrer_name': referrer_user.name,
            'message': f'Код принадлежит пользователю {referrer_user.name}'
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при проверке реферального кода: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/referral/my-referrals', methods=['GET'])
@jwt_required()
def get_my_referrals():
    """Получить список моих рефералов"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем всех рефералов
        referrals = ReferralUsage.query.filter_by(referrer_id=user_id).all()
        
        referrals_data = []
        for referral in referrals:
            referrals_data.append({
                'id': referral.id,
                'referred_user_name': referral.referred.name,
                'referred_user_email': referral.referred.email,
                'bonus_points_awarded': referral.bonus_points_awarded,
                'created_at': referral.created_at.isoformat() if referral.created_at else None
            })
        
        return jsonify({
            'referrals': referrals_data,
            'total': len(referrals_data),
            'total_bonus_points': sum(r.bonus_points_awarded for r in referrals)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении рефералов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/referral/history', methods=['GET'])
@jwt_required()
def get_referral_history():
    """Получить историю реферальных операций"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем историю рефералов (кого пригласил)
        referrals_made = ReferralUsage.query.filter_by(referrer_id=user_id).all()
        
        # Получаем информацию о том, кто пригласил текущего пользователя
        referred_by_info = None
        if user.referred_by:
            referrer = User.query.filter_by(referral_code=user.referred_by).first()
            if referrer:
                referred_by_info = {
                    'referrer_name': referrer.name,
                    'referral_code': user.referred_by,
                    'bonus_points_received': user.bonus_points
                }
        
        referrals_made_data = []
        for referral in referrals_made:
            referrals_made_data.append({
                'id': referral.id,
                'referred_user_name': referral.referred.name,
                'bonus_points_awarded': referral.bonus_points_awarded,
                'created_at': referral.created_at.isoformat() if referral.created_at else None
            })
        
        return jsonify({
            'referred_by': referred_by_info,
            'referrals_made': referrals_made_data,
            'total_referrals_made': len(referrals_made_data),
            'total_bonus_points_earned': sum(r.bonus_points_awarded for r in referrals_made)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении истории рефералов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/use-bonus', methods=['POST'])
@jwt_required()
def use_bonus_points():
    """Использовать бонусные баллы в корзине"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        bonus_to_use = data.get('bonus_points', 0)
        
        if bonus_to_use <= 0:
            return jsonify({'error': 'Количество бонусных баллов должно быть больше 0'}), 400
        
        if bonus_to_use > user.bonus_points:
            return jsonify({'error': 'Недостаточно бонусных баллов'}), 400
        
        # Получаем корзину
        cart = json.loads(user.cart) if user.cart else []
        
        if not cart:
            return jsonify({'error': 'Корзина пуста'}), 400
        
        # Вычисляем общую стоимость корзины
        total_price = 0
        for cart_item in cart:
            item_type = cart_item['item_type']
            item_id = cart_item['item_id']
            quantity = cart_item['quantity']
            
            unit_price = 0
            if item_type == 'roll':
                roll = Roll.query.get(item_id)
                if roll:
                    unit_price = roll.sale_price
            elif item_type == 'set':
                set_item = Set.query.get(item_id)
                if set_item:
                    unit_price = set_item.set_price
            elif item_type == 'loyalty_roll':
                unit_price = 0.0  # Бесплатные роллы не влияют на стоимость
            
            total_price += unit_price * quantity
        
        if total_price <= 0:
            return jsonify({'error': 'В корзине нет товаров для оплаты'}), 400
        
        # Определяем максимальное количество бонусных баллов для использования
        max_bonus_to_use = min(bonus_to_use, user.bonus_points, total_price)
        
        # Создаем специальный элемент в корзине для бонусных баллов
        bonus_item = {
            'item_type': 'bonus_points',
            'item_id': 'bonus',
            'quantity': 1,
            'price': -max_bonus_to_use,  # Отрицательная цена = скидка
            'name': f'Бонусные баллы ({max_bonus_to_use}₽)',
            'is_bonus': True,
            'added_at': datetime.now().isoformat()
        }
        
        # Добавляем бонусный элемент в корзину
        cart.append(bonus_item)
        user.cart = json.dumps(cart)
        
        # Списываем бонусные баллы
        user.bonus_points -= max_bonus_to_use
        
        db.session.commit()
        
        print(f"✅ Использовано {max_bonus_to_use} бонусных баллов пользователем {user.name}")
        
        return jsonify({
            'success': True,
            'message': f'Использовано {max_bonus_to_use} бонусных баллов',
            'bonus_points_used': max_bonus_to_use,
            'remaining_bonus_points': user.bonus_points,
            'discount_applied': max_bonus_to_use
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка при использовании бонусных баллов: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

if __name__ == '__main__':
    print("🚀 Запуск Sushi Express API с SQLite базой данных...")
    print("🌐 API будет доступен по адресу: http://localhost:5000")
    print("📊 База данных: SQLite (sushi_express.db)")
    print("🔑 JWT токены активны 30 дней")
    print("=" * 50)
    
    app.run(debug=True, host='0.0.0.0', port=5000)
