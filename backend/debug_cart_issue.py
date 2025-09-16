#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для отладки проблемы с корзиной
"""

import requests
import json

def debug_cart_issue():
    print("🔍 ОТЛАДКА ПРОБЛЕМЫ С КОРЗИНОЙ")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Шаг 1: Вход пользователя")
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        login_response = requests.post(f'{base_url}/login', json=login_data)
        if login_response.status_code == 200:
            token = login_response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            print(f"✅ Токен получен: {token[:20]}...")
        else:
            print(f"❌ Ошибка входа: {login_response.text}")
            return
    except Exception as e:
        print(f"❌ Исключение при входе: {e}")
        return
    
    try:
        print("\n📝 Шаг 2: Тестируем разные запросы добавления в корзину")
        
        # Тест 1: Добавление ролла
        print("\n   Тест 1: Добавление ролла Калифорния")
        cart_data1 = {
            'item_type': 'roll',
            'item_id': 153,
            'quantity': 1
        }
        
        response1 = requests.post(f'{base_url}/cart/add', headers=headers, json=cart_data1)
        print(f"      Статус: {response1.status_code}")
        print(f"      Заголовки: {dict(response1.headers)}")
        print(f"      Ответ: {response1.text}")
        
        # Тест 2: Добавление сета
        print("\n   Тест 2: Добавление сета Классический")
        cart_data2 = {
            'item_type': 'set',
            'item_id': 81,
            'quantity': 1
        }
        
        response2 = requests.post(f'{base_url}/cart/add', headers=headers, json=cart_data2)
        print(f"      Статус: {response2.status_code}")
        print(f"      Ответ: {response2.text}")
        
        # Тест 3: Проверяем корзину
        print("\n   Тест 3: Проверка корзины")
        response3 = requests.get(f'{base_url}/cart', headers=headers)
        print(f"      Статус: {response3.status_code}")
        print(f"      Ответ: {response3.text}")
        
    except Exception as e:
        print(f"❌ Исключение при тестировании: {e}")
    
    try:
        print("\n📝 Шаг 3: Проверяем логи сервера")
        print("   (Логи сервера должны показать входящие запросы)")
        
    except Exception as e:
        print(f"❌ Исключение при проверке логов: {e}")

if __name__ == "__main__":
    debug_cart_issue()

