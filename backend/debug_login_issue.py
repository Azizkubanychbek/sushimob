#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Отладка проблемы с логином
"""

import requests
import json

def debug_login_issue():
    print("🔍 ОТЛАДКА ПРОБЛЕМЫ С ЛОГИНОМ")
    print("=" * 50)
    
    base_url = 'http://localhost:5000/api'
    
    try:
        print("📝 Тест 1: Проверка /api/login")
        login_data = {
            'email': 'oo@gmail.com',
            'password': '123456'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        print(f"   Статус: {response.status_code}")
        print(f"   Заголовки: {dict(response.headers)}")
        print(f"   Длина ответа: {len(response.text)}")
        print(f"   Ответ (первые 500 символов): {response.text[:500]}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"   ✅ JSON парсится успешно")
                print(f"   Данные: {data}")
            except json.JSONDecodeError as e:
                print(f"   ❌ Ошибка парсинга JSON: {e}")
                print(f"   Сырой ответ: {response.text}")
        else:
            print(f"   ❌ HTTP ошибка: {response.status_code}")
    
    except Exception as e:
        print(f"   ❌ Исключение: {e}")
    
    try:
        print("\n📝 Тест 2: Проверка /api/login с неправильными данными")
        login_data = {
            'email': 'wrong@email.com',
            'password': 'wrongpassword'
        }
        
        response = requests.post(f'{base_url}/login', json=login_data)
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text}")
    
    except Exception as e:
        print(f"   ❌ Исключение: {e}")

if __name__ == "__main__":
    debug_login_issue()

