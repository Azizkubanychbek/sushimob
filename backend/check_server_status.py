#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Проверка статуса сервера
"""

import requests
import time

def check_server_status():
    print("🔍 ПРОВЕРКА СТАТУСА СЕРВЕРА")
    print("=" * 40)
    
    base_url = 'http://127.0.0.1:5000'
    
    # Проверяем здоровье API
    try:
        print("📝 Проверка /api/health")
        response = requests.get(f'{base_url}/api/health', timeout=5)
        print(f"   Статус: {response.status_code}")
        if response.status_code == 200:
            print("   ✅ Сервер работает")
        else:
            print(f"   ❌ Ошибка: {response.text}")
    except requests.exceptions.ConnectionError:
        print("   ❌ Сервер не отвечает - НЕ ЗАПУЩЕН!")
        return False
    except Exception as e:
        print(f"   ❌ Ошибка: {e}")
        return False
    
    # Проверяем login endpoint
    try:
        print("\n📝 Проверка /api/login")
        response = requests.post(f'{base_url}/api/login', 
                               json={'email': 'test', 'password': 'test'}, 
                               timeout=5)
        print(f"   Статус: {response.status_code}")
        if response.status_code in [200, 401]:  # 401 - неправильные данные, но endpoint работает
            print("   ✅ Login endpoint работает")
        else:
            print(f"   ❌ Ошибка: {response.text}")
    except Exception as e:
        print(f"   ❌ Ошибка login: {e}")
    
    return True

if __name__ == "__main__":
    check_server_status()