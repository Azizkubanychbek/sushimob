#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import json

def test_cart_images():
    print("🧪 ТЕСТ ИЗОБРАЖЕНИЙ В КОРЗИНЕ")
    print("=" * 50)
    
    base_url = "http://localhost:5002/api"
    
    # Вход пользователя
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
    
    # Получаем корзину
    response = requests.get(f"{base_url}/cart", headers=headers)
    if response.status_code != 200:
        print(f"❌ Ошибка получения корзины: {response.status_code}")
        return
    
    cart_data = response.json()
    print(f"✅ Корзина получена: {cart_data['total_items']} товаров")
    
    # Проверяем изображения в корзине
    for item in cart_data['cart']:
        print(f"\n📦 Товар: {item['name']}")
        print(f"   ID: {item['id']}")
        print(f"   Тип: {item['item_type']}")
        print(f"   Цена: {item['price']} сом")
        print(f"   Количество: {item['quantity']}")
        print(f"   Изображение: {item.get('image_url', 'НЕТ')}")
        
        if item.get('image_url'):
            print(f"   ✅ Изображение есть: {item['image_url']}")
        else:
            print(f"   ❌ Изображение отсутствует")
    
    # Добавляем товар в корзину
    add_data = {
        "item_type": "roll",
        "item_id": 153,  # Калифорния
        "quantity": 1
    }
    
    response = requests.post(f"{base_url}/cart/add", json=add_data, headers=headers)
    if response.status_code != 200:
        print(f"❌ Ошибка добавления в корзину: {response.status_code}")
        return
    
    print("\n✅ Товар добавлен в корзину")
    
    # Получаем корзину снова
    response = requests.get(f"{base_url}/cart", headers=headers)
    cart_data = response.json()
    
    print(f"\n📦 Корзина после добавления: {cart_data['total_items']} товаров")
    
    # Проверяем последний добавленный товар
    if cart_data['cart']:
        last_item = cart_data['cart'][-1]
        print(f"\n📦 Последний товар: {last_item['name']}")
        print(f"   Изображение: {last_item.get('image_url', 'НЕТ')}")
        
        if last_item.get('image_url'):
            print(f"   ✅ Изображение есть: {last_item['image_url']}")
        else:
            print(f"   ❌ Изображение отсутствует")

if __name__ == "__main__":
    test_cart_images()
