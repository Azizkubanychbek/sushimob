#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для тестирования панели шеф-повара
"""

import requests
import json
import time

def test_chef_dashboard():
    print("🧪 ТЕСТИРОВАНИЕ ПАНЕЛИ ШЕФ-ПОВАРА")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Тест 1: Вход шеф-повара")
        login_data = {
            'email': 'chef@sushiroll.com',
            'password': 'chef123'
        }
        
        login_response = requests.post(f'{base_url}/login', json=login_data)
        if login_response.status_code == 200:
            token = login_response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            user_info = login_response.json()['user']
            print(f"✅ Шеф-повар вошел успешно")
            print(f"   Имя: {user_info['name']}")
            print(f"   Email: {user_info['email']}")
            print(f"   Админ: {'Да' if user_info['is_admin'] else 'Нет'}")
        else:
            print(f"❌ Ошибка входа шеф-повара: {login_response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при входе: {e}")
        return
    
    try:
        print("\n📝 Тест 2: Получение всех заказов")
        response = requests.get(f'{base_url}/orders/all', headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Получено заказов: {data['total']}")
            
            if data['total'] > 0:
                print("\n📋 Последние 5 заказов:")
                orders = data['orders'][:5]
                for order in orders:
                    print(f"  🆔 Заказ #{order['id']}")
                    print(f"     👤 От: {order.get('user_name', 'Не указан')} ({order.get('user_email', 'Не указан')})")
                    print(f"     📱 Телефон: {order.get('user_phone', 'Не указан')}")
                    print(f"     📍 Адрес: {order.get('delivery_address', 'Не указан')}")
                    print(f"     💰 Сумма: {order['total_price']} сом")
                    print(f"     📊 Статус: {order['status']}")
                    print(f"     📅 Дата: {order['created_at']}")
                    if order.get('comment'):
                        print(f"     💬 Комментарий: {order['comment']}")
                    print()
            else:
                print("📭 Заказов пока нет")
        else:
            print(f"❌ Ошибка получения заказов: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"❌ Исключение при получении заказов: {e}")
    
    try:
        print("\n📝 Тест 3: Создание тестового заказа")
        # Входим как обычный пользователь
        user_login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        user_login_response = requests.post(f'{base_url}/login', json=user_login_data)
        if user_login_response.status_code == 200:
            user_token = user_login_response.json()['access_token']
            user_headers = {'Authorization': f'Bearer {user_token}'}
            print("✅ Обычный пользователь вошел")
            
            # Создаем заказ
            order_data = {
                'delivery_address': 'Тестовый адрес для шеф-повара',
                'phone': '+996700708003',
                'payment_method': 'cash',
                'comment': 'Новый тестовый заказ для шеф-повара',
                'items': [
                    {
                        'item_type': 'roll',
                        'item_id': 1,
                        'quantity': 2,
                        'name': 'Калифорния',
                        'price': 370.0
                    }
                ]
            }
            
            order_response = requests.post(f'{base_url}/orders', 
                                         headers=user_headers, json=order_data)
            if order_response.status_code == 201:
                order_result = order_response.json()
                new_order_id = order_result['order']['id']
                print(f"✅ Тестовый заказ создан: #{new_order_id}")
                
                # Проверяем, что шеф-повар видит новый заказ
                print("\n📝 Тест 4: Проверка нового заказа у шеф-повара")
                chef_response = requests.get(f'{base_url}/orders/all', headers=headers)
                if chef_response.status_code == 200:
                    chef_data = chef_response.json()
                    print(f"✅ Шеф-повар видит {chef_data['total']} заказов")
                    
                    # Ищем новый заказ
                    new_order_found = False
                    for order in chef_data['orders']:
                        if order['id'] == new_order_id:
                            new_order_found = True
                            print(f"✅ Новый заказ найден у шеф-повара:")
                            print(f"   🆔 ID: {order['id']}")
                            print(f"   👤 От: {order.get('user_name')} ({order.get('user_email')})")
                            print(f"   💰 Сумма: {order['total_price']} сом")
                            print(f"   📊 Статус: {order['status']}")
                            print(f"   💬 Комментарий: {order.get('comment', 'Нет')}")
                            break
                    
                    if not new_order_found:
                        print("❌ Новый заказ не найден у шеф-повара")
                        
                        # Показываем все заказы для отладки
                        print("\n🔍 Все заказы у шеф-повара:")
                        for order in chef_data['orders'][:3]:
                            print(f"   Заказ #{order['id']}: {order['total_price']} сом, статус: {order['status']}")
                else:
                    print(f"❌ Ошибка получения заказов у шеф-повара: {chef_response.text}")
            else:
                print(f"❌ Ошибка создания заказа: {order_response.text}")
        else:
            print(f"❌ Ошибка входа пользователя: {user_login_response.text}")
    except Exception as e:
        print(f"❌ Исключение при создании заказа: {e}")
    
    print("\n✅ Тестирование завершено!")

if __name__ == "__main__":
    test_chef_dashboard()

