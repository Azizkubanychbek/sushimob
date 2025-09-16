#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для добавления проверки наличия товаров при добавлении в корзину
"""

import os
import re

def add_cart_availability_check():
    print("🔧 ДОБАВЛЕНИЕ ПРОВЕРКИ НАЛИЧИЯ В КОРЗИНУ")
    print("=" * 50)
    
    # Читаем файл app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("📝 Обновляем endpoint добавления в корзину...")
    
    # Находим endpoint для добавления в корзину
    cart_add_pattern = r"(@app\.route\('/api/cart/add', methods=\['POST'\]\)\n@jwt_required\(\)\ndef add_to_cart\(\):.*?)(return jsonify\(.*?\)\n)"
    
    def update_cart_add_endpoint(match):
        original = match.group(1)
        return_part = match.group(2)
        
        # Добавляем проверку наличия перед добавлением в корзину
        new_content = original + '''
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        data = request.get_json()
        item_type = data.get('item_type')
        item_id = data.get('item_id')
        quantity = data.get('quantity', 1)
        
        # Проверяем наличие товара перед добавлением в корзину
        if item_type == 'roll':
            is_available, availability_message = check_roll_availability(item_id)
            if not is_available:
                return jsonify({
                    'error': f'Товар недоступен: {availability_message}'
                }), 400
        
        elif item_type == 'set':
            is_available, availability_message = check_set_availability(item_id)
            if not is_available:
                return jsonify({
                    'error': f'Товар недоступен: {availability_message}'
                }), 400
        
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
        
        ''' + return_part.replace("'success': True", "'success': True, 'message': 'Товар добавлен в корзину'")
        
        return new_content
    
    # Обновляем endpoint добавления в корзину
    new_content = re.sub(cart_add_pattern, update_cart_add_endpoint, content, flags=re.DOTALL)
    
    print("📝 Добавляем endpoint для проверки корзины...")
    
    # Добавляем endpoint для проверки корзины
    cart_check_endpoint = '''

@app.route('/api/cart/check-availability', methods=['GET'])
@jwt_required()
def check_cart_availability():
    """Проверка доступности всех товаров в корзине"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        cart = json.loads(user.cart) if user.cart else []
        unavailable_items = []
        
        for cart_item in cart:
            item_type = cart_item['item_type']
            item_id = cart_item['item_id']
            
            if item_type == 'roll':
                is_available, message = check_roll_availability(item_id)
                if not is_available:
                    roll = Roll.query.get(item_id)
                    unavailable_items.append({
                        'type': 'roll',
                        'id': item_id,
                        'name': roll.name if roll else f'Ролл #{item_id}',
                        'message': message
                    })
            
            elif item_type == 'set':
                is_available, message = check_set_availability(item_id)
                if not is_available:
                    set_item = Set.query.get(item_id)
                    unavailable_items.append({
                        'type': 'set',
                        'id': item_id,
                        'name': set_item.name if set_item else f'Сет #{item_id}',
                        'message': message
                    })
        
        return jsonify({
            'has_unavailable_items': len(unavailable_items) > 0,
            'unavailable_items': unavailable_items,
            'message': 'В корзине есть недоступные товары' if unavailable_items else 'Все товары в корзине доступны'
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Ошибка проверки корзины: {str(e)}'}), 500

'''
    
    # Находим место для вставки (перед if __name__ == '__main__')
    insert_point = new_content.find("if __name__ == '__main__':")
    if insert_point == -1:
        print("❌ Не удалось найти место для вставки")
        return
    
    # Вставляем новый endpoint
    final_content = new_content[:insert_point] + cart_check_endpoint + new_content[insert_point:]
    
    # Записываем обновленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(final_content)
    
    print("✅ Проверка наличия в корзину добавлена!")
    print("📝 Добавлены:")
    print("  - Проверка наличия при добавлении в корзину")
    print("  - /api/cart/check-availability - проверка всей корзины")

if __name__ == "__main__":
    add_cart_availability_check()

