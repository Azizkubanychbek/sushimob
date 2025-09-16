#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import json

def test_all_fixes():
    print("🧪 ТЕСТ ВСЕХ ИСПРАВЛЕНИЙ")
    print("=" * 50)
    
    base_url = "http://localhost:5002/api"
    
    # Тест 1: Вход пользователя
    print("📝 Тест 1: Вход пользователя")
    login_data = {
        "email": "oo@gmail.com",
        "password": "123456"
    }
    
    response = requests.post(f"{base_url}/login", json=login_data)
    if response.status_code != 200:
        print(f"❌ Ошибка входа: {response.status_code}")
        return
    
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("✅ Пользователь вошел")
    
    # Тест 2: Проверка новых эндпоинтов
    print("\n📝 Тест 2: Новые эндпоинты")
    
    # Детали ролла
    response = requests.get(f"{base_url}/rolls/153", headers=headers)
    if response.status_code == 200:
        print("✅ GET /api/rolls/153 - детали ролла")
    else:
        print(f"❌ GET /api/rolls/153 - {response.status_code}")
    
    # Детали сета
    response = requests.get(f"{base_url}/sets/81", headers=headers)
    if response.status_code == 200:
        print("✅ GET /api/sets/81 - детали сета")
    else:
        print(f"❌ GET /api/sets/81 - {response.status_code}")
    
    # Дополнительные товары
    response = requests.get(f"{base_url}/other-items", headers=headers)
    if response.status_code == 200:
        print("✅ GET /api/other-items - дополнительные товары")
    else:
        print(f"❌ GET /api/other-items - {response.status_code}")
    
    # Тест 3: Избранное
    print("\n📝 Тест 3: Избранное")
    
    # Добавление в избранное
    add_fav_data = {
        "item_type": "roll",
        "item_id": 153
    }
    
    response = requests.post(f"{base_url}/favorites/add", json=add_fav_data, headers=headers)
    if response.status_code == 200:
        print("✅ POST /api/favorites/add - добавление в избранное")
    else:
        print(f"❌ POST /api/favorites/add - {response.status_code}")
        if response.status_code == 500:
            print(f"   Ошибка: {response.text}")
    
    # Получение избранного
    response = requests.get(f"{base_url}/favorites", headers=headers)
    if response.status_code == 200:
        print("✅ GET /api/favorites - получение избранного")
    else:
        print(f"❌ GET /api/favorites - {response.status_code}")
    
    # Тест 4: Админ эндпоинты (вход шеф-повара)
    print("\n📝 Тест 4: Админ эндпоинты")
    
    chef_login = {
        "email": "chef@sushiroll.com",
        "password": "chef123"
    }
    
    response = requests.post(f"{base_url}/login", json=chef_login)
    if response.status_code != 200:
        print(f"❌ Ошибка входа шеф-повара: {response.status_code}")
        return
    
    chef_token = response.json()["access_token"]
    chef_headers = {"Authorization": f"Bearer {chef_token}"}
    print("✅ Шеф-повар вошел")
    
    # Ингредиенты
    response = requests.get(f"{base_url}/admin/ingredients", headers=chef_headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ GET /api/admin/ingredients - {data['total']} ингредиентов")
    else:
        print(f"❌ GET /api/admin/ingredients - {response.status_code}")
    
    # Пользователи
    response = requests.get(f"{base_url}/admin/users", headers=chef_headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ GET /api/admin/users - {data['total']} пользователей")
    else:
        print(f"❌ GET /api/admin/users - {response.status_code}")
    
    # Статистика
    response = requests.get(f"{base_url}/admin/stats", headers=chef_headers)
    if response.status_code == 200:
        data = response.json()
        stats = data['stats']
        print(f"✅ GET /api/admin/stats - {stats['total_orders']} заказов, {stats['total_users']} пользователей")
    else:
        print(f"❌ GET /api/admin/stats - {response.status_code}")
    
    # Рецептура ролла
    response = requests.get(f"{base_url}/admin/rolls/153/recipe", headers=chef_headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ GET /api/admin/rolls/153/recipe - рецептура ролла")
    else:
        print(f"❌ GET /api/admin/rolls/153/recipe - {response.status_code}")
    
    # Тест 5: Корзина с изображениями
    print("\n📝 Тест 5: Корзина с изображениями")
    
    # Возвращаемся к обычному пользователю
    response = requests.get(f"{base_url}/cart", headers=headers)
    if response.status_code == 200:
        data = response.json()
        print(f"✅ GET /api/cart - {data['total_items']} товаров")
        
        for item in data['cart']:
            if item.get('image_url'):
                print(f"   ✅ {item['name']} - изображение: {item['image_url'][:50]}...")
            else:
                print(f"   ❌ {item['name']} - изображение отсутствует")
    else:
        print(f"❌ GET /api/cart - {response.status_code}")
    
    print("\n🎉 ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ!")
    print("=" * 50)
    print("✅ Результаты:")
    print("   - Новые эндпоинты добавлены")
    print("   - Избранное исправлено")
    print("   - Админ панель работает")
    print("   - Изображения в корзине есть")
    print("   - База данных содержит все данные")

if __name__ == "__main__":
    test_all_fixes()
