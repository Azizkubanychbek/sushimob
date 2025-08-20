import sqlite3
import os

# Удаляем старую БД если существует
if os.path.exists('sushi_express.db'):
    os.remove('sushi_express.db')
    print("🗑️ Старая база данных удалена")

# Создаем новую БД
conn = sqlite3.connect('sushi_express.db')
cursor = conn.cursor()

print("🔨 Создаем таблицы...")

# Создаем таблицу пользователей
cursor.execute('''
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    location TEXT,
    password_hash TEXT NOT NULL,
    loyalty_points INTEGER DEFAULT 0,
    favorites TEXT,
    cart TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
)
''')
print("✅ Таблица users создана")

# Создаем таблицу ингредиентов
cursor.execute('''
CREATE TABLE ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    cost_per_unit REAL NOT NULL,
    price_per_unit REAL NOT NULL,
    stock_quantity REAL DEFAULT 0,
    unit TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
''')
print("✅ Таблица ingredients создана")

# Создаем таблицу роллов
cursor.execute('''
CREATE TABLE rolls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    cost_price REAL NOT NULL,
    sale_price REAL NOT NULL,
    image_url TEXT,
    is_popular BOOLEAN DEFAULT 0,
    is_new BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
''')
print("✅ Таблица rolls создана")

# Создаем таблицу состава роллов
cursor.execute('''
CREATE TABLE roll_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    roll_id INTEGER NOT NULL,
    ingredient_id INTEGER NOT NULL,
    amount_per_roll REAL NOT NULL,
    FOREIGN KEY (roll_id) REFERENCES rolls (id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients (id)
)
''')
print("✅ Таблица roll_ingredients создана")

# Создаем таблицу сетов
cursor.execute('''
CREATE TABLE sets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    cost_price REAL NOT NULL,
    set_price REAL NOT NULL,
    discount_percent REAL DEFAULT 0,
    image_url TEXT,
    is_popular BOOLEAN DEFAULT 0,
    is_new BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
''')
print("✅ Таблица sets создана")

# Создаем таблицу состава сетов
cursor.execute('''
CREATE TABLE set_rolls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    set_id INTEGER NOT NULL,
    roll_id INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    FOREIGN KEY (set_id) REFERENCES sets (id),
    FOREIGN KEY (roll_id) REFERENCES rolls (id)
)
''')
print("✅ Таблица set_rolls создана")

# Создаем таблицу заказов
cursor.execute('''
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    phone TEXT NOT NULL,
    delivery_address TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    status TEXT DEFAULT 'Принят',
    total_price REAL NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
)
''')
print("✅ Таблица orders создана")

# Создаем таблицу элементов заказа
cursor.execute('''
CREATE TABLE order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    item_type TEXT NOT NULL,
    item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    total_price REAL NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders (id)
)
''')
print("✅ Таблица order_items создана")

# Сохраняем изменения и закрываем соединение
conn.commit()
conn.close()

print("\n🎉 База данных успешно создана!")
print("📁 Файл: sushi_express.db")
print("📊 Созданные таблицы:")
print("   - users")
print("   - ingredients") 
print("   - rolls")
print("   - roll_ingredients")
print("   - sets")
print("   - set_rolls")
print("   - orders")
print("   - order_items")
