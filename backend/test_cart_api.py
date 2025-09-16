#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для тестирования API корзины
"""

import requests
import json

def test_cart_api():
    print("🧪 ТЕСТИРОВАНИЕ API КОРЗИНЫ")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Тест 1: Вход пользователя")
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        login_response = requests.post(f'{base_url}/login', json=login_data)
        if login_response.status_code == 200:
            token = login_response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            user_info = login_response.json()['user']
            print(f"✅ Пользователь вошел: {user_info['name']} ({user_info['email']})")
        else:
            print(f"❌ Ошибка входа: {login_response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при входе: {e}")
        return
    
    try:
        print("\n📝 Тест 2: Получение корзины")
        response = requests.get(f'{base_url}/cart', headers=headers)
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Корзина получена: {len(data.get('cart', []))} товаров")
        else:
            print(f"❌ Ошибка получения корзины")
    except Exception as e:
        print(f"❌ Исключение при получении корзины: {e}")
    
    try:
        print("\n📝 Тест 3: Добавление товара в корзину")
        cart_data = {
            'item_type': 'roll',
            'item_id': 153,  # Калифорния
            'quantity': 2
        }
        
        response = requests.post(f'{base_url}/cart/add', headers=headers, json=cart_data)
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text}")
        
        if response.status_code == 200:
            print("✅ Товар добавлен в корзину")
        else:
            print(f"❌ Ошибка добавления в корзину")
    except Exception as e:
        print(f"❌ Исключение при добавлении в корзину: {e}")
    
    try:
        print("\n📝 Тест 4: Проверка корзины после добавления")
        response = requests.get(f'{base_url}/cart', headers=headers)
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Корзина после добавления: {len(data.get('cart', []))} товаров")
        else:
            print(f"❌ Ошибка получения корзины")
    except Exception as e:
        print(f"❌ Исключение при получении корзины: {e}")

if __name__ == "__main__":
    test_cart_api()

