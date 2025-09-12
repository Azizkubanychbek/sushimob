import sqlite3
import json

# Подключаемся к базе данных
conn = sqlite3.connect('sushi_express.db')
cursor = conn.cursor()

print("🔍 ПРОВЕРКА СИСТЕМЫ ЗАКАЗОВ")
print("=" * 50)

# Проверяем пользователей
cursor.execute('SELECT id, name, email, cart FROM users')
users = cursor.fetchall()

print("👥 ПОЛЬЗОВАТЕЛИ:")
for user in users:
    print(f"ID: {user[0]}, Имя: {user[1]}, Email: {user[2]}")
    if user[3]:  # cart не пустой
        cart = json.loads(user[3])
        print(f"  Корзина: {cart}")
    else:
        print("  Корзина: пуста")
    print()

# Проверяем заказы
cursor.execute('SELECT COUNT(*) FROM orders')
order_count = cursor.fetchone()[0]
print(f"📦 ЗАКАЗОВ В БАЗЕ: {order_count}")

if order_count > 0:
    cursor.execute('SELECT * FROM orders ORDER BY created_at DESC LIMIT 5')
    orders = cursor.fetchall()
    print("\n📋 ПОСЛЕДНИЕ ЗАКАЗЫ:")
    for order in orders:
        print(f"Заказ ID: {order[0]}, Пользователь: {order[1]}, Сумма: {order[7]}₽, Статус: {order[6]}")
        
    # Проверяем элементы заказов
    cursor.execute('SELECT COUNT(*) FROM order_items')
    items_count = cursor.fetchone()[0]
    print(f"\n🛒 ЭЛЕМЕНТОВ ЗАКАЗОВ: {items_count}")
    
    if items_count > 0:
        cursor.execute('SELECT * FROM order_items ORDER BY id DESC LIMIT 10')
        items = cursor.fetchall()
        print("\n📦 ПОСЛЕДНИЕ ЭЛЕМЕНТЫ ЗАКАЗОВ:")
        for item in items:
            print(f"Заказ: {item[1]}, Тип: {item[2]}, ID товара: {item[3]}, Количество: {item[4]}, Цена: {item[6]}₽")
else:
    print("\n❌ ЗАКАЗОВ ПОКА НЕТ")
    print("💡 Попробуйте создать заказ через приложение!")

conn.close()
print("\n✅ Проверка завершена!")
