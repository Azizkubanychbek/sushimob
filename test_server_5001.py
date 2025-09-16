#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Тест сервера на порту 5001
"""

import requests
import json

def test_server_5001():
    print("🧪 ТЕСТ СЕРВЕРА НА ПОРТУ 5001")
    print("=" * 40)
    
    base_url = 'http://127.0.0.1:5001/api'
    
    try:
        print("📝 Тест 1: Health check")
        response = requests.get(f'{base_url}/health')
        print(f"   Статус: {response.status_code}")
        if response.status_code == 200:
            print("   ✅ Сервер работает на порту 5001")
        else:
            print(f"   ❌ Ошибка: {response.text}")
            return
    except Exception as e:
        print(f"   ❌ Сервер не отвечает: {e}")
        return
    
    try:
        print("\n📝 Тест 2: Login")
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

if __name__ == "__main__":
    test_server_5001()

