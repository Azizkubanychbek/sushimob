#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Тест корзины с ценами
"""

import requests
import json

def test_cart_with_prices():
    print("🧪 ТЕСТ КОРЗИНЫ С ЦЕНАМИ")
    print("=" * 40)
    
    base_url = 'http://127.0.0.1:5001/api'
    
    try:
        print("📝 Шаг 1: Вход пользователя")
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        if response.status_code == 200:
            token = response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            print("✅ Пользователь вошел")
        else:
            print(f"❌ Ошибка входа: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ Исключение: {e}")
        return
    
    try:
        print("\n📝 Шаг 2: Добавление товара в корзину")
        cart_data = {
            'item_type': 'roll',
            'item_id': 153,  # Калифорния
            'quantity': 2
        }
        
        response = requests.post(f'{base_url}/cart/add', headers=headers, json=cart_data)
        if response.status_code == 200:
            print("✅ Товар добавлен в корзину")
        else:
            print(f"❌ Ошибка добавления: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    try:
        print("\n📝 Шаг 3: Проверка корзины с ценами")
        response = requests.get(f'{base_url}/cart', headers=headers)
        if response.status_code == 200:
            data = response.json()
            cart = data.get('cart', [])
            print(f"✅ Корзина получена: {len(cart)} товаров")
            
            if cart:
                print("\n📋 Товары в корзине:")
                for item in cart:
                    print(f"   {item.get('name', 'Без названия')}")
                    print(f"      Цена: {item.get('price', 0)} сом")
                    print(f"      Количество: {item.get('quantity', 0)}")
                    print(f"      Общая цена: {item.get('total_price', 0)} сом")
                    print(f"      Поля: {list(item.keys())}")
                    print()
            else:
                print("📭 Корзина пуста")
        else:
            print(f"❌ Ошибка получения корзины: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")

if __name__ == "__main__":
    test_cart_with_prices()

