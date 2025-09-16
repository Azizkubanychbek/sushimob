#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для тестирования системы проверки наличия товаров
"""

import requests
import json

def test_availability_system():
    print("🧪 ТЕСТИРОВАНИЕ СИСТЕМЫ ПРОВЕРКИ НАЛИЧИЯ")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    # Тестируем без авторизации
    print("📝 Тест 1: Получение роллов с проверкой наличия")
    try:
        response = requests.get(f'{base_url}/rolls')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Получено роллов: {len(data['rolls'])}")
            
            # Проверяем первые 3 ролла на наличие
            for i, roll in enumerate(data['rolls'][:3]):
                print(f"  {i+1}. {roll['name']} - {roll['sale_price']} сом")
                print(f"     Доступен: {'✅' if roll['is_available'] else '❌'}")
                if not roll['is_available']:
                    print(f"     Причина: {roll['availability_message']}")
        else:
            print(f"❌ Ошибка: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    print("\n📝 Тест 2: Получение сетов с проверкой наличия")
    try:
        response = requests.get(f'{base_url}/sets')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Получено сетов: {len(data['sets'])}")
            
            # Проверяем первые 3 сета на наличие
            for i, set_item in enumerate(data['sets'][:3]):
                print(f"  {i+1}. {set_item['name']} - {set_item['set_price']} сом")
                print(f"     Доступен: {'✅' if set_item['is_available'] else '❌'}")
                if not set_item['is_available']:
                    print(f"     Причина: {set_item['availability_message']}")
        else:
            print(f"❌ Ошибка: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    print("\n📝 Тест 3: Проверка конкретного ролла")
    try:
        response = requests.get(f'{base_url}/rolls/1/availability')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Ролл ID 1:")
            print(f"   Доступен: {'✅' if data['is_available'] else '❌'}")
            print(f"   Сообщение: {data['message']}")
        else:
            print(f"❌ Ошибка: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    print("\n📝 Тест 4: Проверка конкретного сета")
    try:
        response = requests.get(f'{base_url}/sets/1/availability')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Сет ID 1:")
            print(f"   Доступен: {'✅' if data['is_available'] else '❌'}")
            print(f"   Сообщение: {data['message']}")
        else:
            print(f"❌ Ошибка: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    print("\n📝 Тест 5: Авторизация и добавление в корзину")
    try:
        # Входим как пользователь
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        login_response = requests.post(f'{base_url}/login', json=login_data)
        if login_response.status_code == 200:
            token = login_response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            print("✅ Авторизация успешна")
            
            # Пытаемся добавить ролл в корзину
            cart_data = {
                'item_type': 'roll',
                'item_id': 1,
                'quantity': 1
            }
            
            cart_response = requests.post(f'{base_url}/cart/add', 
                                        headers=headers, json=cart_data)
            if cart_response.status_code == 200:
                print("✅ Товар добавлен в корзину")
            else:
                print(f"❌ Ошибка добавления в корзину: {cart_response.text}")
                
        else:
            print(f"❌ Ошибка авторизации: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    print("\n✅ Тестирование завершено!")

if __name__ == "__main__":
    test_availability_system()

