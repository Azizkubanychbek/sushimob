#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для тестирования API и создания заказов
"""

import requests
import json
import time

def test_api_and_orders():
    print("🧪 ТЕСТИРОВАНИЕ API И ЗАКАЗОВ")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    # Ждем запуска сервера
    print("⏳ Ожидание запуска сервера...")
    time.sleep(3)
    
    try:
        print("📝 Тест 1: Проверка здоровья API")
        response = requests.get(f'{base_url}/health')
        if response.status_code == 200:
            print("✅ API работает")
        else:
            print(f"❌ API не работает: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ API недоступен: {e}")
        return
    
    try:
        print("\n📝 Тест 2: Получение роллов")
        response = requests.get(f'{base_url}/rolls')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Получено роллов: {len(data['rolls'])}")
            if data['rolls']:
                print("   🍣 Примеры роллов:")
                for roll in data['rolls'][:3]:
                    print(f"      {roll['name']} - {roll['price']} сом")
        else:
            print(f"❌ Ошибка получения роллов: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"❌ Исключение при получении роллов: {e}")
    
    try:
        print("\n📝 Тест 3: Получение сетов")
        response = requests.get(f'{base_url}/sets')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Получено сетов: {len(data['sets'])}")
            if data['sets']:
                print("   🍱 Примеры сетов:")
                for set_item in data['sets'][:3]:
                    print(f"      {set_item['name']} - {set_item['price']} сом")
        else:
            print(f"❌ Ошибка получения сетов: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"❌ Исключение при получении сетов: {e}")
    
    try:
        print("\n📝 Тест 4: Вход обычного пользователя")
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        login_response = requests.post(f'{base_url}/login', json=login_data)
        if login_response.status_code == 200:
            user_token = login_response.json()['access_token']
            user_headers = {'Authorization': f'Bearer {user_token}'}
            user_info = login_response.json()['user']
            print(f"✅ Пользователь вошел: {user_info['name']} ({user_info['email']})")
        else:
            print(f"❌ Ошибка входа пользователя: {login_response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при входе пользователя: {e}")
        return
    
    try:
        print("\n📝 Тест 5: Создание тестового заказа")
        order_data = {
            'delivery_address': 'ул. Чуй 12, Бишкек',
            'phone': '+996700708003',
            'payment_method': 'cash',
            'comment': 'Тестовый заказ для шеф-повара - поскорее!',
            'items': [
                {
                    'item_type': 'roll',
                    'item_id': 153,  # Калифорния
                    'quantity': 2,
                    'name': 'Калифорния',
                    'price': 370.0
                },
                {
                    'item_type': 'roll',
                    'item_id': 154,  # Филадельфия
                    'quantity': 1,
                    'name': 'Филадельфия',
                    'price': 700.0
                }
            ]
        }
        
        order_response = requests.post(f'{base_url}/orders', 
                                     headers=user_headers, json=order_data)
        if order_response.status_code == 201:
            order_result = order_response.json()
            new_order_id = order_result['order']['id']
            print(f"✅ Тестовый заказ создан: #{new_order_id}")
            print(f"   💰 Сумма: {order_result['order']['total_price']} сом")
            print(f"   📊 Статус: {order_result['order']['status']}")
        else:
            print(f"❌ Ошибка создания заказа: {order_response.status_code}")
            print(f"   Ответ: {order_response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при создании заказа: {e}")
        return
    
    try:
        print("\n📝 Тест 6: Вход шеф-повара")
        chef_login_data = {
            'email': 'chef@sushiroll.com',
            'password': 'chef123'
        }
        
        chef_login_response = requests.post(f'{base_url}/login', json=chef_login_data)
        if chef_login_response.status_code == 200:
            chef_token = chef_login_response.json()['access_token']
            chef_headers = {'Authorization': f'Bearer {chef_token}'}
            chef_info = chef_login_response.json()['user']
            print(f"✅ Шеф-повар вошел: {chef_info['name']} ({chef_info['email']})")
            print(f"   🔑 Админ: {'Да' if chef_info['is_admin'] else 'Нет'}")
        else:
            print(f"❌ Ошибка входа шеф-повара: {chef_login_response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при входе шеф-повара: {e}")
        return
    
    try:
        print("\n📝 Тест 7: Шеф-повар видит заказы")
        chef_response = requests.get(f'{base_url}/orders/all', headers=chef_headers)
        if chef_response.status_code == 200:
            chef_data = chef_response.json()
            print(f"✅ Шеф-повар видит {chef_data['total']} заказов")
            
            if chef_data['total'] > 0:
                print("\n📋 Последние заказы:")
                orders = chef_data['orders'][:3]
                for order in orders:
                    print(f"   🆔 Заказ #{order['id']}")
                    print(f"      👤 От: {order.get('user_name', 'Не указан')}")
                    print(f"      📱 Телефон: {order.get('user_phone', 'Не указан')}")
                    print(f"      📍 Адрес: {order.get('delivery_address', 'Не указан')}")
                    print(f"      💰 Сумма: {order['total_price']} сом")
                    print(f"      📊 Статус: {order['status']}")
                    print(f"      💬 Комментарий: {order.get('comment', 'Нет')}")
                    print()
            else:
                print("📭 Заказов пока нет")
        else:
            print(f"❌ Ошибка получения заказов у шеф-повара: {chef_response.status_code}")
            print(f"   Ответ: {chef_response.text}")
    except Exception as e:
        print(f"❌ Исключение при получении заказов у шеф-повара: {e}")
    
    print("\n✅ Тестирование завершено!")

if __name__ == "__main__":
    test_api_and_orders()

