#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для тестирования интерфейса шеф-повара
"""

import requests
import json

def test_chef_interface():
    print("👨‍🍳 ТЕСТИРОВАНИЕ ИНТЕРФЕЙСА ШЕФ-ПОВАРА")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Шаг 1: Вход шеф-повара")
        login_data = {
            'email': 'chef@sushiroll.com',
            'password': 'chef123'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        if response.status_code == 200:
            token = response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            user_info = response.json()['user']
            print(f"✅ Шеф-повар вошел: {user_info['name']}")
            print(f"   Email: {user_info['email']}")
            print(f"   Админ: {user_info.get('is_admin', False)}")
        else:
            print(f"❌ Ошибка входа: {response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при входе: {e}")
        return
    
    try:
        print("\n📝 Шаг 2: Получение всех заказов")
        response = requests.get(f'{base_url}/orders/all', headers=headers)
        if response.status_code == 200:
            data = response.json()
            orders = data.get('orders', [])
            total = data.get('total', 0)
            
            print(f"✅ Шеф-повар видит {total} заказов")
            
            if orders:
                print("\n📋 Последние 5 заказов:")
                for i, order in enumerate(orders[:5]):
                    print(f"   {i+1}. Заказ #{order.get('id', '?')}")
                    print(f"      👤 От: {order.get('user_name', 'Не указан')}")
                    print(f"      📱 Телефон: {order.get('user_phone', 'Не указан')}")
                    print(f"      📍 Адрес: {order.get('delivery_address', 'Не указан')}")
                    print(f"      💰 Сумма: {order.get('total_price', 0)} сом")
                    print(f"      📊 Статус: {order.get('status', 'Не указан')}")
                    print(f"      📅 Дата: {order.get('created_at', 'Не указан')}")
                    if order.get('comment'):
                        print(f"      💬 Комментарий: {order['comment']}")
                    print()
            else:
                print("📭 Заказов нет")
        else:
            print(f"❌ Ошибка получения заказов: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"❌ Исключение при получении заказов: {e}")
    
    try:
        print("\n📝 Шаг 3: Тест изменения статуса заказа")
        if orders:
            order_id = orders[0]['id']
            print(f"   Тестируем изменение статуса заказа #{order_id}")
            
            # Пробуем изменить статус
            status_data = {'status': 'preparing'}
            response = requests.put(f'{base_url}/orders/{order_id}/status', 
                                  headers=headers, json=status_data)
            
            if response.status_code == 200:
                print(f"   ✅ Статус заказа #{order_id} изменен на 'preparing'")
            else:
                print(f"   ❌ Ошибка изменения статуса: {response.status_code}")
                print(f"      Ответ: {response.text}")
        else:
            print("   ⏭️  Нет заказов для тестирования изменения статуса")
    except Exception as e:
        print(f"❌ Исключение при изменении статуса: {e}")
    
    print("\n✅ Тестирование интерфейса шеф-повара завершено!")
    
    print("\n📋 ЧТО ДОЛЖЕН ВИДЕТЬ ШЕФ-ПОВАР:")
    print("   ✅ Все заказы от клиентов")
    print("   ✅ Детали каждого заказа (адрес, телефон, сумма)")
    print("   ✅ Возможность менять статусы заказов")
    print("   ✅ Комментарии к заказам")
    print("   ❌ НЕ должен видеть каталог товаров")
    print("   ❌ НЕ должен оформлять заказы")

if __name__ == "__main__":
    test_chef_interface()

