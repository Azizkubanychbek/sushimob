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
        
        # Проверяем, существует ли пользователь
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user:
            return jsonify({'error': 'Пользователь с таким email уже существует'}), 400
        
        # Создаем нового пользователя
        hashed_password = generate_password_hash(data['password'])
        new_user = User(
            email=data['email'],
            name=data['name'],
            phone=data.get('phone', ''),
            password_hash=hashed_password,
            created_at=datetime.utcnow()
        )
        
        db.session.add(new_user)
        db.session.commit()
        
        # Создаем токен доступа
        access_token = create_access_token(identity=new_user.id)
        
        return jsonify({
            'success': True,
            'message': 'Пользователь успешно зарегистрирован',
            'access_token': access_token,
            'user': {
                'id': new_user.id,
                'email': new_user.email,
                'name': new_user.name,
                'phone': new_user.phone
            }
        }), 201
        
    except Exception as e:
        return jsonify({'error': f'Ошибка регистрации: {str(e)}'}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        # Находим пользователя
        user = User.query.filter_by(email=data['email']).first()
        
        if not user or not check_password_hash(user.password_hash, data['password']):
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        # Создаем токен доступа
        access_token = create_access_token(identity=user.id)
        
        return jsonify({
            'success': True,
            'message': 'Вход выполнен успешно',
            'access_token': access_token,
            'user': {
                'id': user.id,
                'email': user.email,
                'name': user.name,
                'phone': user.phone,
                'is_admin': user.is_admin
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка входа: {str(e)}'}), 500

@app.route('/api/rolls', methods=['GET'])
def get_rolls():
    try:
        rolls = Roll.query.all()
        rolls_data = []
        
        for roll in rolls:
            roll_data = {
                'id': roll.id,
                'name': roll.name,
                'description': roll.description,
                'price': roll.sale_price,  # Добавляем поле price
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'category': 'roll',
                'is_available': True
            }
            rolls_data.append(roll_data)
        
        return jsonify({
            'rolls': rolls_data,
            'total': len(rolls_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения роллов: {str(e)}'}), 500

@app.route('/api/sets', methods=['GET'])
def get_sets():
    try:
        sets = Set.query.all()
        sets_data = []
        
        for set_item in sets:
            set_data = {
                'id': set_item.id,
                'name': set_item.name,
                'description': set_item.description,
                'price': set_item.set_price,  # Добавляем поле price
                'set_price': set_item.set_price,
                'image_url': set_item.image_url,
                'is_available': True
            }
            sets_data.append(set_data)
        
        return jsonify({
            'sets': sets_data,
            'total': len(sets_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения сетов: {str(e)}'}), 500

@app.route('/api/orders', methods=['POST'])
@jwt_required()
def create_order():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        
        # Получаем данные из корзины пользователя или из запроса
        cart = json.loads(user.cart) if user.cart else []
        
        # Если корзина пуста, проверяем, есть ли данные в запросе
        if not cart and not data.get('items'):
            return jsonify({'error': 'Корзина пуста'}), 400
        
        # Если есть данные в запросе, используем их
        if data.get('items'):
            cart = data.get('items', [])
        
        # Подготавливаем данные заказа
        phone = data.get('phone', user.phone)
        delivery_address = data.get('delivery_address', user.location or '')
        payment_method = data.get('payment_method', 'cash')
        comment = data.get('comment', '')
        
        # Вычисляем общую стоимость
        total_price = 0
        has_paid_items = False
        
        # Если есть данные в запросе, используем их для расчета
        if data.get('items'):
            for item in data.get('items', []):
                item_type = item.get('item_type', 'roll')
                quantity = item.get('quantity', 1)
                unit_price = item.get('price', 0)
                
                if unit_price > 0:
                    has_paid_items = True
                total_price += unit_price * quantity
        else:
            # Иначе используем корзину пользователя
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
                    unit_price = 0.0
                elif item_type == 'bonus_points':
                    unit_price = cart_item.get('price', 0)
                
                total_price += unit_price * quantity
        
        # Если нет платных товаров, не позволяем оформить заказ
        if not has_paid_items:
            return jsonify({'error': 'В заказе нет платных товаров'}), 400
        
        # Используем переданную сумму если она больше 0
        if data.get('total_amount', 0) > 0:
            total_price = data.get('total_amount', 0)
        elif data.get('total_price', 0) > 0:
            total_price = data.get('total_price', 0)
        
        # Валидация отрицательных сумм
        if total_price < 0:
            return jsonify({'error': 'Сумма заказа не может быть отрицательной'}), 400
        
        # Создаем заказ
        order = Order(
            user_id=user_id,
            phone=phone,
            delivery_address=delivery_address,
            payment_method=payment_method,
            status='Принят',
            total_price=total_price,
            comment=comment,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        db.session.add(order)
        db.session.flush()
        
        # Добавляем элементы заказа
        items_to_process = data.get('items', []) if data.get('items') else cart
        
        for item in items_to_process:
            item_type = item['item_type']
            item_id = item['item_id']
            quantity = item['quantity']
            
            unit_price = 0
            if data.get('items'):
                unit_price = item.get('price', 0)
            else:
                if item_type == 'roll':
                    roll = Roll.query.get(item_id)
                    if roll:
                        unit_price = roll.sale_price
                elif item_type == 'set':
                    set_item = Set.query.get(item_id)
                    if set_item:
                        unit_price = set_item.set_price
                elif item_type == 'loyalty_roll':
                    unit_price = 0.0
                elif item_type == 'bonus_points':
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
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Заказ успешно создан',
            'order': order.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Ошибка создания заказа: {str(e)}'}), 500

@app.route('/api/orders', methods=['GET'])
@jwt_required()
def get_user_orders():
    try:
        user_id = get_jwt_identity()
        orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
        
        return jsonify({
            'success': True,
            'orders': [order.to_dict() for order in orders],
            'total': len(orders)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка при получении заказов: {str(e)}'}), 500

@app.route('/api/orders/all', methods=['GET'])
@jwt_required()
def get_all_orders():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        orders = Order.query.order_by(Order.created_at.desc()).all()
        
        return jsonify({
            'success': True,
            'orders': [order.to_dict() for order in orders],
            'total': len(orders)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка при получении всех заказов: {str(e)}'}), 500



# ===== ENDPOINTS ДЛЯ КОРЗИНЫ =====

@app.route('/api/cart', methods=['GET'])
@jwt_required()
def get_cart():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        cart = json.loads(user.cart) if user.cart else []
        
        # Добавляем цены к товарам в корзине
        cart_with_prices = []
        for item in cart:
            item_type = item.get('item_type')
            item_id = item.get('item_id')
            quantity = item.get('quantity', 1)
            
            # Получаем цену товара
            price = 0
            name = 'Неизвестный товар'
            image_url = ''
            
            if item_type == 'roll':
                roll = Roll.query.get(item_id)
                if roll:
                    price = roll.sale_price
                    name = roll.name
                    image_url = roll.image_url or ''
                else:
                    # Если ролл не найден, пропускаем этот товар
                    continue
            elif item_type == 'set':
                set_item = Set.query.get(item_id)
                if set_item:
                    price = set_item.set_price
                    name = set_item.name
                    image_url = set_item.image_url or ''
                else:
                    # Если сет не найден, пропускаем этот товар
                    continue
            else:
                # Для других типов товаров пропускаем
                continue
            
            # Создаем объект товара для поля item
            item_data = {}
            if item_type == 'roll':
                roll = Roll.query.get(item_id)
                if roll:
                    item_data = {
                        'id': roll.id,
                        'name': roll.name,
                        'description': roll.description,
                        'sale_price': roll.sale_price,
                        'image_url': roll.image_url or '',
                        'is_popular': roll.is_popular,
                        'is_new': roll.is_new,
                        'ingredients': [ri.to_dict() for ri in roll.ingredients]
                    }
            elif item_type == 'set':
                set_item = Set.query.get(item_id)
                if set_item:
                    item_data = {
                        'id': set_item.id,
                        'name': set_item.name,
                        'description': set_item.description,
                        'set_price': set_item.set_price,
                        'image_url': set_item.image_url or '',
                        'is_popular': set_item.is_popular,
                        'is_new': set_item.is_new,
                        'composition': set_item.composition
                    }
            
            # Создаем объект с ценой
            cart_item = {
                'id': item_id,
                'item_type': item_type,
                'item_id': item_id,
                'name': name,
                'price': price,
                'quantity': quantity,
                'total_price': price * quantity,
                'image_url': image_url,
                'item': item_data  # Добавляем полную информацию о товаре
            }
            cart_with_prices.append(cart_item)

        return jsonify({
            'success': True,
            'cart': cart_with_prices,
            'total_items': len(cart_with_prices)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения корзины: {str(e)}'}), 500

@app.route('/api/cart/add', methods=['POST'])
@jwt_required()
def add_to_cart():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        item_type = data.get('item_type')
        item_id = data.get('item_id')
        quantity = data.get('quantity', 1)
        
        # Получаем текущую корзину
        cart = json.loads(user.cart) if user.cart else []
        
        # Проверяем, есть ли уже такой товар в корзине
        existing_item_index = None
        for i, cart_item in enumerate(cart):
            if cart_item['item_type'] == item_type and cart_item['item_id'] == item_id:
                existing_item_index = i
                break
        
        if existing_item_index is not None:
            # Обновляем количество существующего товара
            cart[existing_item_index]['quantity'] += quantity
        else:
            # Добавляем новый товар в корзину
            cart_item = {
                'item_type': item_type,
                'item_id': item_id,
                'quantity': quantity
            }
            cart.append(cart_item)
        
        # Сохраняем обновленную корзину
        user.cart = json.dumps(cart)
        db.session.commit()
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка добавления в корзину: {str(e)}'}), 500

@app.route('/api/cart/remove/<int:item_id>', methods=['DELETE'])
@jwt_required()
def remove_from_cart(item_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        cart = json.loads(user.cart) if user.cart else []
        
        # Удаляем товар из корзины
        cart = [item for item in cart if item['item_id'] != item_id]
        
        user.cart = json.dumps(cart)
        db.session.commit()
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка удаления из корзины: {str(e)}'}), 500

@app.route('/api/cart/clear', methods=['POST'])
@jwt_required()
def clear_cart():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        user.cart = '[]'
        db.session.commit()
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка очистки корзины: {str(e)}'}), 500

# ===== ENDPOINTS ДЛЯ ИЗБРАННОГО =====

@app.route('/api/favorites', methods=['GET'])
@jwt_required()
def get_favorites():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        favorites = json.loads(user.favorites) if user.favorites and user.favorites.strip() and user.favorites != 'null' and user.favorites != 'None' else []
        
        return jsonify({
            'favorites': favorites,
            'total_items': len(favorites)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения избранного: {str(e)}'}), 500

@app.route('/api/favorites/add', methods=['POST'])
@jwt_required()
def add_to_favorites():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        item_type = data.get('item_type')
        item_id = data.get('item_id')
        
        # Получаем избранное и приводим к правильному формату
        if user.favorites and user.favorites.strip() and user.favorites != 'null' and user.favorites != 'None':
            try:
                favorites_data = json.loads(user.favorites)
                # Если это словарь с ключами 'roll', 'set' и т.д.
                if isinstance(favorites_data, dict):
                    favorites = []
                    for item_type_key, item_ids in favorites_data.items():
                        if isinstance(item_ids, list):
                            for item_id_val in item_ids:
                                favorites.append({
                                    'item_type': item_type_key,
                                    'item_id': item_id_val
                                })
                # Если это уже список
                elif isinstance(favorites_data, list):
                    favorites = favorites_data
                else:
                    favorites = []
            except:
                favorites = []
        else:
            favorites = []
        
        # Проверяем, есть ли уже такой товар в избранном
        if not any(fav['item_type'] == item_type and fav['item_id'] == item_id for fav in favorites):
            favorites.append({
                'item_type': item_type,
                'item_id': item_id
            })
            
            # Сохраняем в формате словаря для совместимости
            favorites_dict = {}
            for fav in favorites:
                if fav['item_type'] not in favorites_dict:
                    favorites_dict[fav['item_type']] = []
                if fav['item_id'] not in favorites_dict[fav['item_type']]:
                    favorites_dict[fav['item_type']].append(fav['item_id'])
            
            user.favorites = json.dumps(favorites_dict)
            db.session.commit()
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка добавления в избранное: {str(e)}'}), 500

@app.route('/api/favorites/remove/<int:item_id>', methods=['DELETE'])
@jwt_required()
def remove_from_favorites(item_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        favorites = json.loads(user.favorites) if user.favorites and user.favorites.strip() and user.favorites != 'null' and user.favorites != 'None' else []
        
        # Удаляем товар из избранного
        favorites = [fav for fav in favorites if fav['item_id'] != item_id]
        
        user.favorites = json.dumps(favorites)
        db.session.commit()
        
        return jsonify({'success': True}), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка удаления из избранного: {str(e)}'}), 500

# ===== ENDPOINTS ДЛЯ УПРАВЛЕНИЯ ЗАКАЗАМИ ШЕФ-ПОВАРОМ =====

@app.route('/api/orders/<int:order_id>/status', methods=['PUT'])
@jwt_required()
def update_order_status(order_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'error': 'Заказ не найден'}), 404
        
        data = request.get_json()
        new_status = data.get('status')
        
        if not new_status:
            return jsonify({'error': 'Статус обязателен'}), 400
        
        # Обновляем статус
        order.status = new_status
        order.updated_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Статус заказа обновлен на {new_status}',
            'order': order.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка при обновлении статуса заказа: {str(e)}'}), 500

@app.route('/api/orders/<int:order_id>', methods=['GET'])
@jwt_required()
def get_order(order_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'error': 'Заказ не найден'}), 404
        
        # Проверяем права доступа
        if not user.is_admin and order.user_id != user_id:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        return jsonify({
            'success': True,
            'order': order.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка при получении заказа: {str(e)}'}), 500


# ===== ДОПОЛНИТЕЛЬНЫЕ ЭНДПОИНТЫ =====

@app.route('/api/rolls/<int:roll_id>', methods=['GET'])
def get_roll_details(roll_id):
    try:
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        roll_data = {
            'id': roll.id,
            'name': roll.name,
            'description': roll.description,
            'price': roll.sale_price,
            'sale_price': roll.sale_price,
            'image_url': roll.image_url,
            'category': 'roll',
            'is_available': True,
            'ingredients': [ing.to_dict() for ing in roll.ingredients]
        }
        
        return jsonify({
            'success': True,
            'roll': roll_data
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения ролла: {str(e)}'}), 500

@app.route('/api/sets/<int:set_id>', methods=['GET'])
def get_set_details(set_id):
    try:
        set_item = Set.query.get(set_id)
        if not set_item:
            return jsonify({'error': 'Сет не найден'}), 404
        
        set_data = {
            'id': set_item.id,
            'name': set_item.name,
            'description': set_item.description,
            'price': set_item.set_price,
            'set_price': set_item.set_price,
            'image_url': set_item.image_url,
            'is_available': True,
            'rolls': [sr.to_dict() for sr in set_item.rolls]
        }
        
        return jsonify({
            'success': True,
            'set': set_data
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения сета: {str(e)}'}), 500

# ===== АДМИН ЭНДПОИНТЫ =====

@app.route('/api/admin/ingredients', methods=['GET'])
@jwt_required()
def get_admin_ingredients():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        ingredients = Ingredient.query.all()
        
        return jsonify({
            'success': True,
            'ingredients': [ing.to_dict() for ing in ingredients],
            'total': len(ingredients)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения ингредиентов: {str(e)}'}), 500

@app.route('/api/admin/users', methods=['GET'])
@jwt_required()
def get_admin_users():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        users = User.query.all()
        
        return jsonify({
            'success': True,
            'users': [user.to_dict() for user in users],
            'total': len(users)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения пользователей: {str(e)}'}), 500

@app.route('/api/admin/stats', methods=['GET'])
@jwt_required()
def get_admin_stats():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        # Получаем статистику
        total_users = User.query.count()
        total_orders = Order.query.count()
        total_rolls = Roll.query.count()
        total_sets = Set.query.count()
        total_ingredients = Ingredient.query.count()
        
        # Статистика по заказам
        orders_by_status = {}
        for order in Order.query.all():
            status = order.status
            orders_by_status[status] = orders_by_status.get(status, 0) + 1
        
        return jsonify({
            'success': True,
            'stats': {
                'total_users': total_users,
                'total_orders': total_orders,
                'total_rolls': total_rolls,
                'total_sets': total_sets,
                'total_ingredients': total_ingredients,
                'orders_by_status': orders_by_status
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения статистики: {str(e)}'}), 500

@app.route('/api/admin/rolls/<int:roll_id>/recipe', methods=['GET'])
@jwt_required()
def get_roll_recipe(roll_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user or not user.is_admin:
            return jsonify({'error': 'Доступ запрещен'}), 403
        
        roll = Roll.query.get(roll_id)
        if not roll:
            return jsonify({'error': 'Ролл не найден'}), 404
        
        recipe_data = {
            'roll_id': roll.id,
            'roll_name': roll.name,
            'ingredients': [ing.to_dict() for ing in roll.ingredients]
        }
        
        return jsonify({
            'success': True,
            'recipe': recipe_data
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения рецептуры: {str(e)}'}), 500

@app.route('/api/other-items', methods=['GET'])
def get_other_items():
    try:
        other_items = OtherItem.query.all()
        
        return jsonify({
            'success': True,
            'other_items': [item.to_dict() for item in other_items],
            'total': len(other_items)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения дополнительных товаров: {str(e)}'}), 500


# ===== ЭНДПОИНТЫ ДЛЯ НАКОПИТЕЛЬНЫХ КАРТ =====

@app.route('/api/loyalty/cards', methods=['GET'])
@jwt_required()
def get_loyalty_cards():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем накопительные карты пользователя
        loyalty_cards = LoyaltyCard.query.filter_by(user_id=user_id).all()
        
        cards_data = []
        for card in loyalty_cards:
            card_data = {
                'id': card.id,
                'card_name': getattr(card, 'card_name', 'Накопительная карта'),
                'current_stamps': getattr(card, 'current_stamps', 0),
                'max_stamps': getattr(card, 'max_stamps', 10),
                'is_completed': getattr(card, 'is_completed', False),
                'created_at': card.created_at.isoformat() if hasattr(card, 'created_at') and card.created_at else None,
                'completed_at': card.completed_at.isoformat() if hasattr(card, 'completed_at') and card.completed_at else None
            }
            cards_data.append(card_data)
        
        return jsonify({
            'success': True,
            'cards': cards_data,
            'total': len(cards_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения накопительных карт: {str(e)}'}), 500

@app.route('/api/loyalty/available-rolls', methods=['GET'])
@jwt_required()
def get_loyalty_available_rolls():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем доступные роллы для накопительных карт
        loyalty_rolls = LoyaltyRoll.query.filter_by(is_available=True).all()
        
        rolls_data = []
        for loyalty_roll in loyalty_rolls:
            roll_data = {
                'id': loyalty_roll.id,
                'roll_id': getattr(loyalty_roll, 'roll_id', 0),
                'required_stamps': getattr(loyalty_roll, 'required_stamps', 10),
                'is_available': getattr(loyalty_roll, 'is_available', True),
                'roll_name': getattr(loyalty_roll, 'roll_name', 'Бесплатный ролл'),
                'roll_description': getattr(loyalty_roll, 'roll_description', 'Описание ролла')
            }
            rolls_data.append(roll_data)
        
        return jsonify({
            'success': True,
            'available_rolls': rolls_data,
            'total': len(rolls_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения доступных роллов: {str(e)}'}), 500

@app.route('/api/loyalty/history', methods=['GET'])
@jwt_required()
def get_loyalty_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем историю использования накопительных карт
        usage_history = LoyaltyCardUsage.query.filter_by(user_id=user_id).order_by(LoyaltyCardUsage.used_at.desc()).all()
        
        history_data = []
        for usage in usage_history:
            history_item = {
                'id': usage.id,
                'loyalty_roll_id': usage.loyalty_roll_id,
                'used_at': usage.used_at.isoformat() if usage.used_at else None,
                'stamps_used': usage.stamps_used,
                'roll_name': usage.roll_name
            }
            history_data.append(history_item)
        
        return jsonify({
            'success': True,
            'history': history_data,
            'total': len(history_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения истории: {str(e)}'}), 500

# ===== ЭНДПОИНТЫ ДЛЯ РЕФЕРАЛОВ =====

@app.route('/api/referral/my-code', methods=['GET'])
@jwt_required()
def get_my_referral_code():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Генерируем реферальный код если его нет
        if not user.referral_code:
            import random
            import string
            user.referral_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            db.session.commit()
        
        return jsonify({
            'success': True,
            'referral_code': user.referral_code,
            'referrals_count': 0  # Можно добавить подсчет рефералов
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения реферального кода: {str(e)}'}), 500

@app.route('/api/referral/history', methods=['GET'])
@jwt_required()
def get_referral_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        # Получаем историю рефералов
        referral_history = ReferralUsage.query.filter_by(referrer_id=user_id).order_by(ReferralUsage.created_at.desc()).all()
        
        history_data = []
        for referral in referral_history:
            history_item = {
                'id': referral.id,
                'referred_user_id': referral.referred_user_id,
                'created_at': referral.created_at.isoformat() if referral.created_at else None,
                'bonus_points_earned': referral.bonus_points_earned
            }
            history_data.append(history_item)
        
        return jsonify({
            'success': True,
            'referral_history': history_data,
            'total': len(history_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка получения истории рефералов: {str(e)}'}), 500

if __name__ == '__main__':
    with app.app_context():
        print('✅ База данных SQLite подключена!')
        print(f'📁 Файл: sushi_express.db')
        print('📊 Доступные таблицы:')
        print('   - users')
        print('   - ingredients')
        print('   - rolls')
        print('   - roll_ingredients')
        print('   - sets')
        print('   - set_rolls')
        print('   - orders')
        print('   - order_items')
        print('   - loyalty_cards')
        print('   - loyalty_rolls')
        print('   - loyalty_card_usage')
        print('✅ Система накопительных карт активна')
        print('🚀 Запуск Sushi Express API с SQLite базой данных...')
        print('🌐 API будет доступен по адресу: http://localhost:5000')
        print('📊 База данных: SQLite (sushi_express.db)')
        print('🔑 JWT токены активны 30 дней')
        print('=' * 50)
    
    app.run(host='0.0.0.0', port=5002, debug=True)
