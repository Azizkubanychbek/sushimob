#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def add_missing_endpoints():
    print("🔧 ДОБАВЛЕНИЕ НЕДОСТАЮЩИХ ЭНДПОИНТОВ")
    print("=" * 50)
    
    # Читаем текущий файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Добавляем недостающие эндпоинты перед if __name__ == '__main__':
    missing_endpoints = '''
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

'''
    
    # Находим место для вставки (перед if __name__ == '__main__':)
    insert_position = content.find("if __name__ == '__main__':")
    
    if insert_position == -1:
        print("❌ Не найдено место для вставки")
        return
    
    # Вставляем новые эндпоинты
    new_content = content[:insert_position] + missing_endpoints + content[insert_position:]
    
    # Записываем обновленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("✅ Недостающие эндпоинты добавлены:")
    print("   - GET /api/rolls/<id> - детали ролла")
    print("   - GET /api/sets/<id> - детали сета")
    print("   - GET /api/admin/ingredients - ингредиенты для админа")
    print("   - GET /api/admin/users - пользователи для админа")
    print("   - GET /api/admin/stats - статистика для админа")
    print("   - GET /api/admin/rolls/<id>/recipe - рецептура ролла")
    print("   - GET /api/other-items - дополнительные товары")

if __name__ == "__main__":
    add_missing_endpoints()
