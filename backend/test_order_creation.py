import requests
import json

# Данные для тестирования
base_url = "http://127.0.0.1:5000/api"

# 1. Сначала войдем как пользователь jj@gmail.com
print("🔑 Логинимся как jj@gmail.com...")
login_response = requests.post(f"{base_url}/login", json={
    "email": "jj@gmail.com",
    "password": "password123"  # Предполагаем стандартный пароль
})

if login_response.status_code == 200:
    login_data = login_response.json()
    token = login_data['access_token']
    print("✅ Успешный вход!")
    print(f"👤 Пользователь: {login_data['user']['name']}")
    
    # 2. Проверим корзину
    print("\n🛒 Проверяем корзину...")
    headers = {"Authorization": f"Bearer {token}"}
    cart_response = requests.get(f"{base_url}/cart", headers=headers)
    
    if cart_response.status_code == 200:
        cart_data = cart_response.json()
        print(f"📦 Товаров в корзине: {cart_data['total']}")
        if cart_data['total'] > 0:
            print("🛍️ Товары в корзине:")
            for item in cart_data['cart']:
                print(f"  - {item['item']['name']} x{item['quantity']} = {item['price']}₽")
            
            # 3. Создаем заказ
            print("\n📋 Создаем заказ...")
            total_amount = sum(item['price'] for item in cart_data['cart']) + 200  # + доставка
            
            order_data = {
                "total_amount": total_amount,
                "delivery_address": "ул. Тестовая, д. 1, кв. 1",
                "phone": "+7 (999) 123-45-67",
                "payment_method": "cash",
                "comment": "Тестовый заказ через API"
            }
            
            order_response = requests.post(
                f"{base_url}/orders", 
                headers=headers, 
                json=order_data
            )
            
            if order_response.status_code == 201:
                order_result = order_response.json()
                print("✅ ЗАКАЗ УСПЕШНО СОЗДАН!")
                print(f"📋 ID заказа: {order_result['order']['id']}")
                print(f"💰 Сумма: {order_result['order']['total_price']}₽")
                print(f"📍 Адрес: {order_result['order']['delivery_address']}")
                print(f"📞 Телефон: {order_result['order']['phone']}")
                print(f"💳 Оплата: {order_result['order']['payment_method']}")
                
                # 4. Проверим что корзина очистилась
                print("\n🛒 Проверяем корзину после заказа...")
                cart_response_after = requests.get(f"{base_url}/cart", headers=headers)
                if cart_response_after.status_code == 200:
                    cart_after = cart_response_after.json()
                    print(f"📦 Товаров в корзине после заказа: {cart_after['total']}")
                    
                # 5. Проверим заказы пользователя
                print("\n📋 Проверяем заказы пользователя...")
                orders_response = requests.get(f"{base_url}/orders", headers=headers)
                if orders_response.status_code == 200:
                    orders_data = orders_response.json()
                    print(f"📦 Всего заказов: {orders_data['total']}")
                    if orders_data['total'] > 0:
                        print("📋 Заказы:")
                        for order in orders_data['orders']:
                            print(f"  - Заказ #{order['id']}: {order['total_price']}₽, статус: {order['status']}")
                
            else:
                print(f"❌ Ошибка создания заказа: {order_response.status_code}")
                print(f"📝 Ответ: {order_response.text}")
        else:
            print("❌ Корзина пуста, нечего заказывать")
    else:
        print(f"❌ Ошибка получения корзины: {cart_response.status_code}")
else:
    print(f"❌ Ошибка входа: {login_response.status_code}")
    print("💡 Возможно нужно зарегистрировать пользователя или использовать другой пароль")

print("\n✅ Тест завершен!")
