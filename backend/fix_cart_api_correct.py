#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Правильное исправление API корзины
"""

def fix_cart_api_correct():
    print("🔧 ПРАВИЛЬНОЕ ИСПРАВЛЕНИЕ API КОРЗИНЫ")
    print("=" * 50)
    
    # Читаем файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем функцию get_cart
    old_get_cart = '''        cart = json.loads(user.cart) if user.cart else []

        return jsonify({
            'success': True,
            'cart': cart,
            'total_items': len(cart)
        }), 200'''
    
    new_get_cart = '''        cart = json.loads(user.cart) if user.cart else []
        
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
            elif item_type == 'set':
                set_item = Set.query.get(item_id)
                if set_item:
                    price = set_item.set_price
                    name = set_item.name
                    image_url = set_item.image_url or ''
            
            # Создаем объект с ценой
            cart_item = {
                'id': item_id,
                'item_type': item_type,
                'item_id': item_id,
                'name': name,
                'price': price,
                'quantity': quantity,
                'total_price': price * quantity,
                'image_url': image_url
            }
            cart_with_prices.append(cart_item)

        return jsonify({
            'success': True,
            'cart': cart_with_prices,
            'total_items': len(cart_with_prices)
        }), 200'''
    
    if old_get_cart in content:
        content = content.replace(old_get_cart, new_get_cart)
        print("✅ API get_cart исправлен")
    else:
        print("❌ Не найден код get_cart")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Исправление API корзины завершено!")
    print("📝 Теперь корзина возвращает полную информацию о товарах")

if __name__ == "__main__":
    fix_cart_api_correct()

