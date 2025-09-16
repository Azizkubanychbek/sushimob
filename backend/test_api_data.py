#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для тестирования API данных
"""

import requests
import json

def test_api_data():
    print("🧪 ТЕСТИРОВАНИЕ API ДАННЫХ")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Тест 1: Получение роллов")
        response = requests.get(f'{base_url}/rolls')
        print(f"   Статус: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Получено роллов: {len(data.get('rolls', []))}")
            
            if data.get('rolls'):
                print("   📝 Примеры роллов:")
                for i, roll in enumerate(data['rolls'][:3]):
                    print(f"      {i+1}. {roll.get('name', 'Без названия')} - {roll.get('price', 0)} сом")
        else:
            print(f"   ❌ Ошибка: {response.text}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    try:
        print("\n📝 Тест 2: Получение сетов")
        response = requests.get(f'{base_url}/sets')
        print(f"   Статус: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Получено сетов: {len(data.get('sets', []))}")
            
            if data.get('sets'):
                print("   📝 Примеры сетов:")
                for i, set_item in enumerate(data['sets'][:3]):
                    print(f"      {i+1}. {set_item.get('name', 'Без названия')} - {set_item.get('price', 0)} сом")
        else:
            print(f"   ❌ Ошибка: {response.text}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    try:
        print("\n📝 Тест 3: Вход шеф-повара")
        login_data = {
            'email': 'chef@sushiroll.com',
            'password': 'chef123'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        if response.status_code == 200:
            token = response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            print(f"   ✅ Шеф-повар вошел")
            
            print("\n📝 Тест 4: Получение заказов шеф-поваром")
            response = requests.get(f'{base_url}/orders/all', headers=headers)
            print(f"   Статус: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"   ✅ Шеф-повар видит {data.get('total', 0)} заказов")
            else:
                print(f"   ❌ Ошибка: {response.text}")
        else:
            print(f"   ❌ Ошибка входа шеф-повара: {response.text}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")

if __name__ == "__main__":
    test_api_data()

