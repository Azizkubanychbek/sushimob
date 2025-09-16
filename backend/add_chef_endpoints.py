#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для добавления недостающих endpoints для шеф-повара
"""

def add_chef_endpoints():
    print("🔧 ДОБАВЛЕНИЕ ENDPOINTS ДЛЯ ШЕФ-ПОВАРА")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Добавляем недостающие endpoints перед if __name__ == '__main__'
    additional_endpoints = '''

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
        
        return jsonify({
            'cart': cart,
            'total_items': len(cart)
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
        
        favorites = json.loads(user.favorites) if user.favorites else []
        
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
        
        favorites = json.loads(user.favorites) if user.favorites else []
        
        # Проверяем, есть ли уже такой товар в избранном
        if not any(fav['item_type'] == item_type and fav['item_id'] == item_id for fav in favorites):
            favorites.append({
                'item_type': item_type,
                'item_id': item_id
            })
            
            user.favorites = json.dumps(favorites)
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
        
        favorites = json.loads(user.favorites) if user.favorites else []
        
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

'''
    
    # Находим место для вставки (перед if __name__ == '__main__')
    insert_point = content.find("if __name__ == '__main__':")
    if insert_point == -1:
        print("❌ Не удалось найти место для вставки")
        return
    
    # Вставляем дополнительные endpoints
    new_content = content[:insert_point] + additional_endpoints + content[insert_point:]
    
    # Записываем обновленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("✅ Endpoints для шеф-повара добавлены!")
    print("📝 Добавлены:")
    print("  - /api/cart - получение корзины")
    print("  - /api/cart/add - добавление в корзину")
    print("  - /api/cart/remove - удаление из корзины")
    print("  - /api/cart/clear - очистка корзины")
    print("  - /api/favorites - избранное")
    print("  - /api/orders/<id>/status - обновление статуса заказа")
    print("  - /api/orders/<id> - получение конкретного заказа")

if __name__ == "__main__":
    add_chef_endpoints()

