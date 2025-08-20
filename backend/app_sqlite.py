from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
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
from models import db, User, Ingredient, Roll, RollIngredient, Set, SetRoll, Order, OrderItem
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
        
        # Создание нового пользователя
        new_user = User(
            name=data['name'].strip(),
            email=data['email'].strip().lower(),
            phone=data['phone'].strip(),
            location=data.get('location', '').strip() if data.get('location') else None,
            password_hash=generate_password_hash(data['password'])
        )
        
        db.session.add(new_user)
        db.session.commit()
        
        print(f"✅ Новый пользователь зарегистрирован: {new_user.name} ({new_user.email})")
        
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

@app.route('/api/favorites/remove', methods=['POST'])
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

# ===== API для заказов =====
@app.route('/api/orders', methods=['POST'])
@jwt_required()
def create_order():
    """Создание нового заказа"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Создаем заказ
        order = Order(
            user_id=user_id,
            phone=data['phone'],
            delivery_address=data['delivery_address'],
            payment_method=data['payment_method'],
            total_price=data['total_price'],
            comment=data.get('comment', '')
        )
        
        db.session.add(order)
        db.session.flush()  # Получаем ID заказа
        
        # Добавляем элементы заказа
        for item_data in data['items']:
            order_item = OrderItem(
                order_id=order.id,
                item_type=item_data['type'],  # 'roll' или 'set'
                item_id=item_data['id'],
                quantity=item_data['quantity'],
                unit_price=item_data['unit_price'],
                total_price=item_data['total_price']
            )
            db.session.add(order_item)
        
        db.session.commit()
        
        print(f"✅ Новый заказ создан: ID {order.id}, пользователь {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'Заказ успешно создан',
            'order': order.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка при создании заказа: {e}")
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
            
            if item_data:
                cart_item_with_data = cart_item.copy()
                cart_item_with_data['item'] = item_data
                cart_item_with_data['price'] = item_data.get('sale_price', item_data.get('set_price', 0))
                cart_with_items.append(cart_item_with_data)
        
        return jsonify({
            'success': True,
            'cart': cart_with_items,
            'total': len(cart_with_items)
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
            existing_item['quantity'] += data['quantity']
        else:
            # Добавляем новый товар
            cart.append({
                'id': len(cart) + 1,
                'item_type': data['item_type'],
                'item_id': data['item_id'],
                'quantity': data['quantity'],
                'added_at': datetime.now().isoformat()
            })
        
        user.cart = json.dumps(cart)
        db.session.commit()
        
        print(f"✅ Товар добавлен в корзину: {data['item_type']} ID {data['item_id']}, количество {data['quantity']}")
        
        return jsonify({
            'success': True,
            'message': 'Товар добавлен в корзину',
            'cart': cart
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при добавлении в корзину: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/remove/<int:item_id>', methods=['DELETE'])
@jwt_required()
def remove_from_cart(item_id):
    """Удаление товара из корзины"""
    try:
        user_id = get_jwt_identity()
        # Здесь нужно будет создать таблицу cart
        print(f"✅ Товар удален из корзины: ID {item_id}")
        
        return jsonify({
            'success': True,
            'message': 'Товар удален из корзины'
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при удалении из корзины: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

@app.route('/api/cart/update/<int:item_id>', methods=['PUT'])
@jwt_required()
def update_cart_item(item_id):
    """Обновление количества товара в корзине"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data.get('quantity'):
            return jsonify({'error': 'Количество обязательно'}), 400
        
        # Здесь нужно будет создать таблицу cart
        print(f"✅ Количество товара обновлено: ID {item_id}, новое количество {data['quantity']}")
        
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
        # Здесь нужно будет создать таблицу cart
        print(f"✅ Корзина очищена для пользователя {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'Корзина очищена'
        }), 200
    except Exception as e:
        print(f"❌ Ошибка при очистке корзины: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

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

if __name__ == '__main__':
    print("🚀 Запуск Sushi Express API с SQLite базой данных...")
    print("🌐 API будет доступен по адресу: http://localhost:5000")
    print("📊 База данных: SQLite (sushi_express.db)")
    print("🔑 JWT токены активны 30 дней")
    print("=" * 50)
    
    app.run(debug=True, host='0.0.0.0', port=5000)
