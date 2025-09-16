#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для обновления API endpoints с проверкой наличия товаров
"""

import os
import re

def update_api_endpoints():
    print("🔧 ОБНОВЛЕНИЕ API ENDPOINTS С ПРОВЕРКОЙ НАЛИЧИЯ")
    print("=" * 50)
    
    # Читаем файл app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("📝 Обновляем endpoint для получения роллов...")
    
    # Находим endpoint для получения роллов
    rolls_pattern = r"(@app\.route\('/api/rolls', methods=\['GET'\]\)\ndef get_rolls\(\):.*?)(return jsonify\(.*?\)\n)"
    
    def update_rolls_endpoint(match):
        original = match.group(1)
        return_part = match.group(2)
        
        # Добавляем проверку наличия
        new_content = original + '''
    try:
        rolls = Roll.query.all()
        rolls_data = []
        
        for roll in rolls:
            # Проверяем доступность ролла
            is_available, availability_message = check_roll_availability(roll.id)
            
            roll_data = {
                'id': roll.id,
                'name': roll.name,
                'description': roll.description,
                'sale_price': roll.sale_price,
                'image_url': roll.image_url,
                'category': roll.category,
                'is_available': is_available,
                'availability_message': availability_message if not is_available else None
            }
            rolls_data.append(roll_data)
        
        ''' + return_part.replace('rolls_data', 'rolls_data')
        
        return new_content
    
    # Обновляем endpoint для роллов
    new_content = re.sub(rolls_pattern, update_rolls_endpoint, content, flags=re.DOTALL)
    
    print("📝 Обновляем endpoint для получения сетов...")
    
    # Находим endpoint для получения сетов
    sets_pattern = r"(@app\.route\('/api/sets', methods=\['GET'\]\)\ndef get_sets\(\):.*?)(return jsonify\(.*?\)\n)"
    
    def update_sets_endpoint(match):
        original = match.group(1)
        return_part = match.group(2)
        
        # Добавляем проверку наличия
        new_content = original + '''
    try:
        sets = Set.query.all()
        sets_data = []
        
        for set_item in sets:
            # Проверяем доступность сета
            is_available, availability_message = check_set_availability(set_item.id)
            
            set_data = {
                'id': set_item.id,
                'name': set_item.name,
                'description': set_item.description,
                'set_price': set_item.set_price,
                'image_url': set_item.image_url,
                'is_available': is_available,
                'availability_message': availability_message if not is_available else None
            }
            sets_data.append(set_data)
        
        ''' + return_part.replace('sets_data', 'sets_data')
        
        return new_content
    
    # Обновляем endpoint для сетов
    new_content = re.sub(sets_pattern, update_sets_endpoint, new_content, flags=re.DOTALL)
    
    print("📝 Добавляем endpoint для проверки наличия конкретного товара...")
    
    # Добавляем новые endpoints для проверки наличия
    availability_endpoints = '''

# ===== ENDPOINTS ДЛЯ ПРОВЕРКИ НАЛИЧИЯ =====

@app.route('/api/rolls/<int:roll_id>/availability', methods=['GET'])
def check_roll_availability_endpoint(roll_id):
    """Проверка доступности конкретного ролла"""
    try:
        is_available, message = check_roll_availability(roll_id)
        return jsonify({
            'roll_id': roll_id,
            'is_available': is_available,
            'message': message
        }), 200
    except Exception as e:
        return jsonify({'error': f'Ошибка проверки: {str(e)}'}), 500

@app.route('/api/sets/<int:set_id>/availability', methods=['GET'])
def check_set_availability_endpoint(set_id):
    """Проверка доступности конкретного сета"""
    try:
        is_available, message = check_set_availability(set_id)
        return jsonify({
            'set_id': set_id,
            'is_available': is_available,
            'message': message
        }), 200
    except Exception as e:
        return jsonify({'error': f'Ошибка проверки: {str(e)}'}), 500

@app.route('/api/ingredients/<int:ingredient_id>/availability', methods=['GET'])
def check_ingredient_availability_endpoint(ingredient_id):
    """Проверка наличия конкретного ингредиента"""
    try:
        is_available, message = check_ingredient_availability(ingredient_id)
        return jsonify({
            'ingredient_id': ingredient_id,
            'is_available': is_available,
            'message': message
        }), 200
    except Exception as e:
        return jsonify({'error': f'Ошибка проверки: {str(e)}'}), 500

'''
    
    # Находим место для вставки новых endpoints (перед if __name__ == '__main__')
    insert_point = content.find("if __name__ == '__main__':")
    if insert_point == -1:
        print("❌ Не удалось найти место для вставки новых endpoints")
        return
    
    # Вставляем новые endpoints
    final_content = new_content[:insert_point] + availability_endpoints + new_content[insert_point:]
    
    # Записываем обновленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(final_content)
    
    print("✅ API endpoints обновлены!")
    print("📝 Добавлены:")
    print("  - Проверка наличия в /api/rolls")
    print("  - Проверка наличия в /api/sets")
    print("  - /api/rolls/<id>/availability")
    print("  - /api/sets/<id>/availability")
    print("  - /api/ingredients/<id>/availability")

if __name__ == "__main__":
    update_api_endpoints()

