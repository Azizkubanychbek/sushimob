#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Тест login endpoint
"""

import requests
import json

def test_login_endpoint():
    print("🧪 ТЕСТ LOGIN ENDPOINT")
    print("=" * 40)
    
    base_url = 'http://localhost:5000/api'
    
    try:
        print("📝 Тест 1: Обычный пользователь")
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text[:200]}...")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Пользователь вошел: {data.get('user', {}).get('name', 'Неизвестно')}")
        else:
            print(f"   ❌ Ошибка входа")
    
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    try:
        print("\n📝 Тест 2: Шеф-повар")
        login_data = {
            'email': 'chef@sushiroll.com',
            'password': 'chef123'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text[:200]}...")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Шеф-повар вошел: {data.get('user', {}).get('name', 'Неизвестно')}")
        else:
            print(f"   ❌ Ошибка входа шеф-повара")
    
    except Exception as e:
        print(f"   ❌ Исключение: {e}")

if __name__ == "__main__":
    test_login_endpoint()

