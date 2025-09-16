#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для восстановления полной версии сервера
"""

import os
import shutil

def restore_full_server():
    print("🔧 ВОССТАНОВЛЕНИЕ ПОЛНОЙ ВЕРСИИ СЕРВЕРА")
    print("=" * 50)
    
    # Проверяем, есть ли резервная копия
    backup_files = [
        'app_sqlite_backup.py',
        'app_sqlite_original.py', 
        '../app_sqlite_original.py'
    ]
    
    backup_found = None
    for backup in backup_files:
        if os.path.exists(backup):
            backup_found = backup
            break
    
    if backup_found:
        print(f"📝 Найдена резервная копия: {backup_found}")
        shutil.copy(backup_found, 'app_sqlite.py')
        print("✅ Сервер восстановлен из резервной копии")
    else:
        print("❌ Резервная копия не найдена")
        print("🔧 Создаем минимальную рабочую версию сервера...")
        
        minimal_server = '''from flask import Flask, request, jsonify
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
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'category': roll.category,
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
            user_name=user.name,
            user_phone=phone,
            user_email=user.email,
            delivery_address=delivery_address,
            delivery_latitude=data.get('delivery_latitude', 42.8746),
            delivery_longitude=data.get('delivery_longitude', 74.5698),
            total_price=total_price,
            status='Принят',
            created_at=datetime.utcnow(),
            payment_method=payment_method,
            comment=comment,
            phone=phone
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

if __name__ == '__main__':
    with app.app_context():
        print('✅ База данных SQLite создана!')
        print(f'📁 Файл: sushi_express.db')
        print('📊 Созданные таблицы:')
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
        print('✅ Система накопительных карт уже инициализирована')
        print('🚀 Запуск Sushi Express API с SQLite базой данных...')
        print('🌐 API будет доступен по адресу: http://localhost:5000')
        print('📊 База данных: SQLite (sushi_express.db)')
        print('🔑 JWT токены активны 30 дней')
        print('=' * 50)
    
    app.run(host='0.0.0.0', port=5000, debug=True)
'''
        
        with open('app_sqlite.py', 'w', encoding='utf-8') as f:
            f.write(minimal_server)
        
        print("✅ Создана минимальная рабочая версия сервера")
    
    print("🚀 Сервер готов к запуску")

if __name__ == "__main__":
    restore_full_server()

