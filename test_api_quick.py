#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Быстрая проверка API
"""

import requests
import json

def test_api_quick():
    print("🧪 БЫСТРАЯ ПРОВЕРКА API")
    print("=" * 40)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Тест 1: Роллы")
        response = requests.get(f'{base_url}/rolls')
        if response.status_code == 200:
            data = response.json()
            rolls = data.get('rolls', [])
            print(f"   ✅ Роллов: {len(rolls)}")
            if rolls:
                print(f"   📝 Первый: {rolls[0].get('name')} - {rolls[0].get('price')} сом")
        else:
            print(f"   ❌ Ошибка: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    try:
        print("\n📝 Тест 2: Сеты")
        response = requests.get(f'{base_url}/sets')
        if response.status_code == 200:
            data = response.json()
            sets = data.get('sets', [])
            print(f"   ✅ Сетов: {len(sets)}")
            if sets:
                print(f"   📝 Первый: {sets[0].get('name')} - {sets[0].get('price')} сом")
        else:
            print(f"   ❌ Ошибка: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    try:
        print("\n📝 Тест 3: Шеф-повар")
        login_data = {'email': 'chef@sushiroll.com', 'password': 'chef123'}
        response = requests.post(f'{base_url}/login', json=login_data)
        if response.status_code == 200:
            token = response.json()['access_token']
            headers = {'Authorization': f'Bearer {token}'}
            print("   ✅ Шеф-повар вошел")
            
            response = requests.get(f'{base_url}/orders/all', headers=headers)
            if response.status_code == 200:
                data = response.json()
                print(f"   ✅ Заказов: {data.get('total', 0)}")
            else:
                print(f"   ❌ Ошибка заказов: {response.status_code}")
        else:
            print(f"   ❌ Ошибка входа: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    print("\n✅ Проверка завершена!")

if __name__ == "__main__":
    test_api_quick()

