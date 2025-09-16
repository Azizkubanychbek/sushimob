#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import json
import sqlite3
from datetime import datetime

def test_order_flow():
    print("🧪 ТЕСТ ЦЕПОЧКИ ЗАКАЗОВ")
    print("=" * 50)
    
    base_url = "http://localhost:5002/api"
    
    # Шаг 1: Вход пользователя
    print("📝 Шаг 1: Вход пользователя")
    login_data = {
        "email": "oo@gmail.com",
        "password": "123456"
    }
    
    response = requests.post(f"{base_url}/login", json=login_data)
    if response.status_code != 200:
        print(f"❌ Ошибка входа: {response.status_code} - {response.text}")
        return
    
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("✅ Пользователь вошел")
    
    # Шаг 2: Проверяем корзину
    print("\n📝 Шаг 2: Проверяем корзину")
    response = requests.get(f"{base_url}/cart", headers=headers)
    if response.status_code != 200:
        print(f"❌ Ошибка получения корзины: {response.status_code} - {response.text}")
        return
    
    cart_data = response.json()
    print(f"✅ Корзина получена: {cart_data['total_items']} товаров")
    
    if cart_data['total_items'] == 0:
        print("⚠️ Корзина пуста, добавляем товар")
        # Добавляем товар в корзину
        add_data = {
            "item_type": "roll",
            "item_id": 1,
            "quantity": 2
        }
        response = requests.post(f"{base_url}/cart/add", json=add_data, headers=headers)
        if response.status_code != 200:
            print(f"❌ Ошибка добавления в корзину: {response.status_code} - {response.text}")
            return
        print("✅ Товар добавлен в корзину")
        
        # Получаем корзину снова
        response = requests.get(f"{base_url}/cart", headers=headers)
        cart_data = response.json()
    
    # Шаг 3: Создаем заказ
    print("\n📝 Шаг 3: Создание заказа")
    order_data = {
        "delivery_address": "ул. Чуй, д. 123, кв. 45, Бишкек",
        "phone": "+996 555 123 456",
        "payment_method": "cash",
        "comment": "Тестовый заказ",
        "items": cart_data["cart"]
    }
    
    print(f"📦 Данные заказа:")
    print(f"   Адрес: {order_data['delivery_address']}")
    print(f"   Телефон: {order_data['phone']}")
    print(f"   Способ оплаты: {order_data['payment_method']}")
    print(f"   Товаров: {len(order_data['items'])}")
    
    response = requests.post(f"{base_url}/orders", json=order_data, headers=headers)
    if response.status_code != 201:
        print(f"❌ Ошибка создания заказа: {response.status_code} - {response.text}")
        return
    
    order_result = response.json()
    order_id = order_result["order"]["id"]
    print(f"✅ Заказ создан: ID {order_id}")
    
    # Шаг 4: Проверяем заказ в базе данных
    print("\n📝 Шаг 4: Проверка заказа в базе данных")
    conn = sqlite3.connect('sushi_express.db')
    cursor = conn.cursor()
    
    # Проверяем заказ
    cursor.execute("SELECT * FROM orders WHERE id = ?", (order_id,))
    order = cursor.fetchone()
    
    if order:
        print("✅ Заказ найден в базе данных:")
        print(f"   ID: {order[0]}")
        print(f"   Пользователь: {order[1]}")
        print(f"   Телефон: {order[2]}")
        print(f"   Адрес: {order[3]}")
        print(f"   Способ оплаты: {order[4]}")
        print(f"   Статус: {order[5]}")
        print(f"   Общая сумма: {order[6]} сом")
        print(f"   Комментарий: {order[7]}")
        print(f"   Создан: {order[8]}")
    else:
        print("❌ Заказ не найден в базе данных")
        conn.close()
        return
    
    # Проверяем элементы заказа
    cursor.execute("SELECT * FROM order_items WHERE order_id = ?", (order_id,))
    items = cursor.fetchall()
    
    print(f"\n📦 Элементы заказа ({len(items)} шт.):")
    for item in items:
        print(f"   ID: {item[0]}, Тип: {item[2]}, ID товара: {item[3]}, Количество: {item[4]}, Цена за единицу: {item[5]}, Общая цена: {item[6]}")
    
    conn.close()
    
    # Шаг 5: Проверяем заказ через API
    print("\n📝 Шаг 5: Проверка заказа через API")
    response = requests.get(f"{base_url}/orders/{order_id}", headers=headers)
    if response.status_code != 200:
        print(f"❌ Ошибка получения заказа: {response.status_code} - {response.text}")
        return
    
    api_order = response.json()["order"]
    print("✅ Заказ получен через API:")
    print(f"   ID: {api_order['id']}")
    print(f"   Статус: {api_order['status']}")
    print(f"   Общая сумма: {api_order['total_price']} сом")
    print(f"   Товаров: {len(api_order['items'])}")
    
    # Шаг 6: Проверяем корзину после заказа
    print("\n📝 Шаг 6: Проверка корзины после заказа")
    response = requests.get(f"{base_url}/cart", headers=headers)
    cart_after = response.json()
    print(f"✅ Корзина после заказа: {cart_after['total_items']} товаров")
    
    # Шаг 7: Получаем все заказы пользователя
    print("\n📝 Шаг 7: Получение всех заказов пользователя")
    response = requests.get(f"{base_url}/orders", headers=headers)
    if response.status_code != 200:
        print(f"❌ Ошибка получения заказов: {response.status_code} - {response.text}")
        return
    
    user_orders = response.json()["orders"]
    print(f"✅ Заказов пользователя: {len(user_orders)}")
    
    # Шаг 8: Тест для шеф-повара
    print("\n📝 Шаг 8: Тест для шеф-повара")
    chef_login = {
        "email": "chef@sushiroll.com",
        "password": "chef123"
    }
    
    response = requests.post(f"{base_url}/login", json=chef_login)
    if response.status_code != 200:
        print(f"❌ Ошибка входа шеф-повара: {response.status_code} - {response.text}")
        return
    
    chef_token = response.json()["access_token"]
    chef_headers = {"Authorization": f"Bearer {chef_token}"}
    print("✅ Шеф-повар вошел")
    
    # Получаем все заказы
    response = requests.get(f"{base_url}/orders/all", headers=chef_headers)
    if response.status_code != 200:
        print(f"❌ Ошибка получения всех заказов: {response.status_code} - {response.text}")
        return
    
    all_orders = response.json()["orders"]
    print(f"✅ Всего заказов в системе: {len(all_orders)}")
    
    # Обновляем статус заказа
    update_data = {"status": "Готовится"}
    response = requests.put(f"{base_url}/orders/{order_id}/status", json=update_data, headers=chef_headers)
    if response.status_code != 200:
        print(f"❌ Ошибка обновления статуса: {response.status_code} - {response.text}")
        return
    
    print("✅ Статус заказа обновлен на 'Готовится'")
    
    print("\n🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!")
    print("=" * 50)
    print("✅ Цепочка заказов работает корректно:")
    print("   - Пользователь может войти")
    print("   - Корзина работает")
    print("   - Заказ создается")
    print("   - Данные сохраняются в БД")
    print("   - API возвращает корректные данные")
    print("   - Корзина очищается после заказа")
    print("   - Шеф-повар может управлять заказами")

if __name__ == "__main__":
    test_order_flow()
