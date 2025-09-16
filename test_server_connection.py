#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Тест подключения к серверу
"""

import requests
import json

def test_server_connection():
    print("🔍 ТЕСТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ")
    print("=" * 40)
    
    # Пробуем разные адреса
    urls = [
        'http://127.0.0.1:5001/api/health',
        'http://localhost:5001/api/health',
        'http://[::1]:5001/api/health'
    ]
    
    for url in urls:
        try:
            print(f"📡 Тестирую: {url}")
            response = requests.get(url, timeout=5)
            print(f"✅ Статус: {response.status_code}")
            if response.status_code == 200:
                print(f"📄 Ответ: {response.text}")
                return url.replace('/health', '')
        except Exception as e:
            print(f"❌ Ошибка: {e}")
    
    print("\n🔍 Пробуем без /health:")
    base_urls = [
        'http://127.0.0.1:5001',
        'http://localhost:5001'
    ]
    
    for base_url in base_urls:
        try:
            print(f"📡 Тестирую: {base_url}")
            response = requests.get(base_url, timeout=5)
            print(f"✅ Статус: {response.status_code}")
            return base_url
        except Exception as e:
            print(f"❌ Ошибка: {e}")
    
    return None

if __name__ == "__main__":
    working_url = test_server_connection()
    if working_url:
        print(f"\n✅ Рабочий URL: {working_url}")
    else:
        print("\n❌ Сервер недоступен")

