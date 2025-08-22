
import pandas as pd
import sqlite3
import os
from werkzeug.security import generate_password_hash
from datetime import datetime

def load_real_data():
    """Загрузка реальных данных из Excel файлов sushiback в новую SQLite БД"""
    
    # Подключаемся к БД
    conn = sqlite3.connect('instance/sushi_express.db')
    cursor = conn.cursor()
    
    try:
        print("🗑️ Очищаем существующие данные...")
        
        # Очищаем все таблицы (в обратном порядке из-за foreign keys)
        cursor.execute("DELETE FROM order_items")
        cursor.execute("DELETE FROM orders")
        cursor.execute("DELETE FROM set_rolls")
        cursor.execute("DELETE FROM roll_ingredients")
        cursor.execute("DELETE FROM sets")
        cursor.execute("DELETE FROM rolls")
        cursor.execute("DELETE FROM ingredients")
        cursor.execute("DELETE FROM users")
        
        conn.commit()
        print("✅ Данные очищены")
        
        print("📝 Создаем тестовых пользователей...")
        
        # Создаем тестовых пользователей
        users_data = [
            ('Тестовый пользователь', 'test@test.com', '+7 (999) 123-45-67', 'Москва, ул. Тверская, 1', 
             generate_password_hash('123456'), 100, None, datetime.now(), None, 1),
            ('Администратор', 'admin@sushi.com', '+7 (999) 999-99-99', 'Москва, ул. Арбат, 10',
             generate_password_hash('admin123'), 500, None, datetime.now(), None, 1)
        ]
        
        cursor.executemany('''
            INSERT INTO users (name, email, phone, location, password_hash, loyalty_points, 
                             favorites, created_at, last_login_at, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', users_data)
        
        conn.commit()
        print(f"✅ Создано {len(users_data)} пользователей")
        
        print("🥬 Загружаем ингредиенты из Excel...")
        
        # Путь к файлу ингредиентов
        ingredients_file = 'assets/data/ingredients.xlsx'
        
        if os.path.exists(ingredients_file):
            df = pd.read_excel(ingredients_file)
            print(f"📊 Найдено {len(df)} ингредиентов в Excel")
            
            for _, row in df.iterrows():
                cost_per_unit = row['price_per_unit'] if pd.notna(row['price_per_unit']) else 100
                price_per_unit = cost_per_unit * 1.2  # Добавляем 20% наценки
                stock_quantity = row['quantity'] if pd.notna(row['quantity']) else 10
                unit = row['unit'] if pd.notna(row['unit']) else 'шт'
                
                cursor.execute('''
                    INSERT INTO ingredients (name, cost_per_unit, price_per_unit, stock_quantity, unit, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (row['name'], cost_per_unit, price_per_unit, stock_quantity, unit, datetime.now(), datetime.now()))
            
            conn.commit()
            print(f"✅ Загружено {len(df)} ингредиентов")
        else:
            print("❌ Файл ingredients.xlsx не найден, создаем базовые ингредиенты...")
            # Создаем базовые ингредиенты
            basic_ingredients = [
                ('Рис', 80, 100, 50, 'кг'),
                ('Лосось', 600, 800, 20, 'кг'),
                ('Сыр сливочный', 400, 500, 15, 'кг'),
                ('Нори', 200, 250, 100, 'шт'),
                ('Авокадо', 300, 400, 25, 'кг'),
                ('Огурец', 150, 200, 30, 'кг'),
                ('Краб', 800, 1000, 15, 'кг'),
                ('Угорь', 1200, 1500, 10, 'кг'),
                ('Тунец', 700, 900, 18, 'кг'),
                ('Креветка', 900, 1200, 12, 'кг')
            ]
            
            for ing in basic_ingredients:
                cursor.execute('''
                    INSERT INTO ingredients (name, cost_per_unit, price_per_unit, stock_quantity, unit, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (*ing, datetime.now(), datetime.now()))
            
            conn.commit()
            print("✅ Созданы базовые ингредиенты")
        
        print("🍣 Загружаем роллы из Excel...")
        
        # Путь к файлу роллов
        rolls_file = 'assets/data/rolls.xlsx'
        
        if os.path.exists(rolls_file):
            df = pd.read_excel(rolls_file)
            print(f"📊 Найдено {len(df)} роллов в Excel")
            
            for _, row in df.iterrows():
                # Рассчитываем себестоимость (примерно 30% от цены продажи)
                sale_price = row['sale_price'] if pd.notna(row['sale_price']) else 300
                cost_price = sale_price * 0.3
                
                cursor.execute('''
                    INSERT INTO rolls (name, description, cost_price, sale_price, image_url, is_popular, is_new, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    row['name'],
                    row.get('description', 'Вкусный ролл'),
                    cost_price,
                    sale_price,
                    row.get('image_url', 'https://via.placeholder.com/300x200?text=Roll'),
                    row.get('is_popular', 0),
                    row.get('is_new', 0),
                    datetime.now(),
                    datetime.now()
                ))
            
            conn.commit()
            print(f"✅ Загружено {len(df)} роллов")
        else:
            print("❌ Файл rolls.xlsx не найден, создаем базовые роллы...")
            # Создаем базовые роллы
            basic_rolls = [
                ('Филадельфия', 'Лосось, сыр, огурец', 120, 400, 'https://via.placeholder.com/300x200?text=Philadelphia', 1, 0),
                ('Калифорния', 'Краб, авокадо, огурец', 100, 350, 'https://via.placeholder.com/300x200?text=California', 1, 0),
                ('Дракон', 'Угорь, огурец, соус', 150, 500, 'https://via.placeholder.com/300x200?text=Dragon', 0, 1),
                ('Аляска', 'Лосось, авокадо, икра', 140, 450, 'https://via.placeholder.com/300x200?text=Alaska', 0, 0),
                ('Бонито', 'Тунец, огурец, соус', 130, 420, 'https://via.placeholder.com/300x200?text=Bonito', 0, 0)
            ]
            
            for roll in basic_rolls:
                cursor.execute('''
                    INSERT INTO rolls (name, description, cost_price, sale_price, image_url, is_popular, is_new, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (*roll, datetime.now(), datetime.now()))
            
            conn.commit()
            print("✅ Созданы базовые роллы")
        
        print("🔗 Создаем состав роллов...")
        
        # Получаем ID роллов и ингредиентов
        cursor.execute("SELECT id, name FROM rolls")
        rolls = cursor.fetchall()
        
        cursor.execute("SELECT id, name FROM ingredients")
        ingredients = cursor.fetchall()
        
        # Создаем связи ролл-ингредиент (примерные)
        roll_ingredients_data = []
        for roll_id, roll_name in rolls:
            # Каждый ролл содержит 3-5 ингредиентов
            num_ingredients = min(5, len(ingredients))
            selected_ingredients = ingredients[:num_ingredients]
            
            for ing_id, ing_name in selected_ingredients:
                amount = 0.1 if 'кг' in ing_name else 1  # 100г для весовых, 1 шт для штучных
                roll_ingredients_data.append((roll_id, ing_id, amount))
        
        cursor.executemany('''
            INSERT INTO roll_ingredients (roll_id, ingredient_id, amount_per_roll)
            VALUES (?, ?, ?)
        ''', roll_ingredients_data)
        
        conn.commit()
        print(f"✅ Создано {len(roll_ingredients_data)} связей ролл-ингредиент")
        
        print("📦 Загружаем сеты из Excel...")
        
        # Путь к файлу сетов
        sets_file = 'assets/data/sets.xlsx'
        
        if os.path.exists(sets_file):
            df = pd.read_excel(sets_file)
            print(f"📊 Найдено {len(df)} сетов в Excel")
            
            for _, row in df.iterrows():
                sale_price = row['set_price'] if pd.notna(row['set_price']) else 800
                cost_price = sale_price * 0.4  # 40% от цены продажи для сетов
                
                cursor.execute('''
                    INSERT INTO sets (name, description, cost_price, set_price, discount_percent, image_url, is_popular, is_new, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    row['name'],
                    row.get('description', 'Вкусный сет'),
                    cost_price,
                    sale_price,
                    row.get('discount_percent', 0),
                    row.get('image_url', 'https://via.placeholder.com/300x200?text=Set'),
                    row.get('is_popular', 0),
                    row.get('is_new', 0),
                    datetime.now(),
                    datetime.now()
                ))
            
            conn.commit()
            print(f"✅ Загружено {len(df)} сетов")
        else:
            print("❌ Файл sets.xlsx не найден, создаем базовые сеты...")
            # Создаем базовые сеты
            basic_sets = [
                ('Сет "Филадельфия"', 'Филадельфия + Калифорния + напиток', 200, 650, 10, 'https://via.placeholder.com/300x200?text=Philadelphia+Set', 1, 0),
                ('Сет "Дракон"', 'Дракон + Аляска + напиток', 250, 800, 15, 'https://via.placeholder.com/300x200?text=Dragon+Set', 0, 1),
                ('Сет "Семейный"', '4 ролла + 2 напитка', 400, 1200, 20, 'https://via.placeholder.com/300x200?text=Family+Set', 1, 0)
            ]
            
            for set_item in basic_sets:
                cursor.execute('''
                    INSERT INTO sets (name, description, cost_price, set_price, discount_percent, image_url, is_popular, is_new, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (*set_item, datetime.now(), datetime.now()))
            
            conn.commit()
            print("✅ Созданы базовые сеты")
        
        print("🔗 Создаем состав сетов...")
        
        # Путь к файлу состава сетов
        set_composition_file = 'assets/data/set_composition.xlsx'
        
        if os.path.exists(set_composition_file):
            df = pd.read_excel(set_composition_file)
            print(f"📊 Найдено {len(df)} связей сет-ролл в Excel")
            
            # Создаем связи сет-ролл из Excel
            set_rolls_data = []
            for _, row in df.iterrows():
                set_id_excel = row['set_id']
                roll_name_excel = row['roll_name']
                
                # Ищем сет по названию из Excel (используем Excel названия)
                excel_set_names = {
                    1: 'Классический',
                    2: 'Бюджетный', 
                    3: 'Темпура',
                    4: 'Запечённый',
                    5: 'Фила Премиум',
                    6: 'Хит Комбо',
                    7: 'Party Mix',
                    8: 'Для компании',
                    9: 'Anteyko',
                    10: 'Набор на двоих',
                    11: 'Набор на троих',
                    12: 'Chill на Филармонии'
                }
                
                # Словарь соответствий названий роллов Excel -> БД
                roll_name_mapping = {
                    'Филадельфия': 'филадельфия',
                    'Темпура Чикен маки': 'чикен маки',
                    'Саке маки': 'саке маки',
                    'Овощной ролл': 'овощьной ролл',
                    'Мини ролл огурец': 'мини рол огурец',
                    'Запеченная Маки курица': 'маки курица',
                    'Лосось темпура': 'лосось темпура',
                    'Курица темпура': 'курица темпура',
                    'Угорь темпура': 'угорь темпура',
                    'Запечённый магистр': 'запеч магистр',
                    'Запечённая фила': 'запеч фила',
                    'Унаги запечённый': 'унаги запеч',
                    'Фила спешл': 'фила спешл',
                    'Копчёная фила': 'копченная фила',
                    'Фила с угрём': 'фила с угрем',
                    'Сладкий ролл': 'сладкий ролл',
                    'Чедр ролл': 'чедр ролл',
                    'Острый лосось': 'острый лосось',
                    'Ролл нежный (запеч.)': 'запеч фила',
                    'Ролл Чикаго': 'чикаго ролл',
                    'Запеченная филадельфия': 'запеч фила',
                    'Чикаго ролл': 'чикаго ролл',
                    'Филадельфия спешл': 'фила спешл',
                    'Ролл нежный': 'запеч фила',
                    'Ролл томаго': 'саке маки',
                    'Ролл запеченный нежный': 'запеч фила',
                    'Запеченная Филадельфия': 'запеч фила',
                    'Запеченный Маки курица': 'маки курица'
                }
                
                set_name_excel = excel_set_names.get(set_id_excel)
                if set_name_excel:
                    # Ищем сет по названию в БД
                    cursor.execute("SELECT id FROM sets WHERE name = ?", (set_name_excel,))
                    set_result = cursor.fetchone()
                    
                    if set_result:
                        set_id = set_result[0]
                        # Ищем ролл по названию (сначала по точному совпадению, потом по словарю)
                        roll_name_db = roll_name_mapping.get(roll_name_excel, roll_name_excel)
                        
                        cursor.execute("SELECT id FROM rolls WHERE name = ?", (roll_name_db,))
                        roll_result = cursor.fetchone()
                        
                        if roll_result:
                            roll_id = roll_result[0]
                            set_rolls_data.append((set_id, roll_id, 1))
                            print(f"✅ Связь: сет {set_id} ({set_name_excel}) -> ролл {roll_id} ({roll_name_excel})")
                        else:
                            print(f"⚠️ Ролл не найден: {roll_name_excel} -> {roll_name_db}")
                    else:
                        print(f"⚠️ Сет не найден: {set_name_excel}")
                else:
                    print(f"⚠️ Неизвестный ID сета: {set_id_excel}")
            
            if set_rolls_data:
                cursor.executemany('''
                    INSERT INTO set_rolls (set_id, roll_id, quantity)
                    VALUES (?, ?, ?)
                ''', set_rolls_data)
                
                conn.commit()
                print(f"✅ Создано {len(set_rolls_data)} связей сет-ролл из Excel")
            else:
                print("⚠️ Не удалось создать связи из Excel, создаем базовые...")
                _create_basic_set_rolls(cursor, conn)
        else:
            print("❌ Файл set_composition.xlsx не найден, создаем базовые связи...")
            _create_basic_set_rolls(cursor, conn)
        
        print("🎉 Реальные данные успешно загружены!")
        
        # Показываем статистику
        cursor.execute("SELECT COUNT(*) FROM users")
        users_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM ingredients")
        ingredients_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM rolls")
        rolls_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM sets")
        sets_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM set_rolls")
        set_rolls_count = cursor.fetchone()[0]
        
        print(f"\n📊 Статистика загруженных данных:")
        print(f"   👥 Пользователи: {users_count}")
        print(f"   🥬 Ингредиенты: {ingredients_count}")
        print(f"   🍣 Роллы: {rolls_count}")
        print(f"   📦 Сеты: {sets_count}")
        print(f"   🔗 Связи сет-ролл: {set_rolls_count}")
        
    except Exception as e:
        print(f"❌ Ошибка при загрузке данных: {e}")
        conn.rollback()
        raise
    finally:
        conn.close()

def _create_basic_set_rolls(cursor, conn):
    """Создание базовых связей сет-ролл если Excel не найден"""
    # Получаем ID сетов
    cursor.execute("SELECT id, name FROM sets")
    sets = cursor.fetchall()
    
    # Создаем связи сет-ролл
    set_rolls_data = []
    for set_id, set_name in sets:
        if 'Филадельфия' in set_name:
            # Сет Филадельфия: Филадельфия + Калифорния
            set_rolls_data.extend([(set_id, 1, 1), (set_id, 2, 1)])
        elif 'Дракон' in set_name:
            # Сет Дракон: Дракон + Аляска
            set_rolls_data.extend([(set_id, 3, 1), (set_id, 4, 1)])
        elif 'Семейный' in set_name:
            # Семейный сет: все роллы по 1
            for roll_id in range(1, 6):
                set_rolls_data.append((set_id, roll_id, 1))
    
    if set_rolls_data:
        cursor.executemany('''
            INSERT INTO set_rolls (set_id, roll_id, quantity)
            VALUES (?, ?, ?)
        ''', set_rolls_data)
        
        conn.commit()
        print(f"✅ Создано {len(set_rolls_data)} базовых связей сет-ролл")
    else:
        print("⚠️ Не удалось создать базовые связи сет-ролл")

if __name__ == '__main__':
    load_real_data()
