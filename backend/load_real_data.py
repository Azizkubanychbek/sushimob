import pandas as pd
import os
from models import db, User, Ingredient, Roll, RollIngredient, Set, SetRoll
from werkzeug.security import generate_password_hash
from datetime import datetime
from flask import Flask

# Создаем Flask приложение для контекста
app = Flask(__name__)
# Используем абсолютный путь к базе данных
import os
db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sushi_express.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

def load_real_data():
    """Загрузка реальных данных из Excel файлов sushiback"""
    
    with app.app_context():
        print("🗑️ Очищаем существующие данные...")
        
        # Очищаем все таблицы
        SetRoll.query.delete()
        RollIngredient.query.delete()
        Set.query.delete()
        Roll.query.delete()
        Ingredient.query.delete()
        User.query.delete()
        
        db.session.commit()
        print("✅ Данные очищены")
        
        print("📝 Создаем тестовых пользователей...")
        
        # Создаем тестовых пользователей
        users = [
            User(
                name='Тестовый пользователь',
                email='test@test.com',
                phone='+7 (999) 123-45-67',
                location='Москва, ул. Тверская, 1',
                password_hash=generate_password_hash('123456'),
                loyalty_points=100
            ),
            User(
                name='Администратор',
                email='admin@sushi.com',
                phone='+7 (999) 999-99-99',
                location='Москва, ул. Арбат, 10',
                password_hash=generate_password_hash('admin123'),
                loyalty_points=500
            )
        ]
        
        for user in users:
            db.session.add(user)
        
        db.session.commit()
        print(f"✅ Создано {len(users)} пользователей")
        
        print("🥬 Загружаем ингредиенты из Excel...")
        
        # Путь к файлу ингредиентов
        ingredients_file = '../sushiback/ingredients.xlsx'
        
        if os.path.exists(ingredients_file):
            df = pd.read_excel(ingredients_file)
            print(f"📊 Найдено {len(df)} ингредиентов в Excel")
            
            for _, row in df.iterrows():
                ingredient = Ingredient(
                    name=row['name'],
                    cost_per_unit=row['price_per_unit'],  # Используем price_per_unit как cost_per_unit
                    price_per_unit=row['price_per_unit'] * 1.2,  # Добавляем 20% наценки
                    stock_quantity=row['quantity'],
                    unit=row['unit']
                )
                db.session.add(ingredient)
            
            db.session.commit()
            print(f"✅ Загружено {len(df)} ингредиентов")
        else:
            print("❌ Файл ingredients.xlsx не найден, создаем базовые ингредиенты...")
            # Создаем базовые ингредиенты
            basic_ingredients = [
                Ingredient(name='Рис', cost_per_unit=80, price_per_unit=100, stock_quantity=50, unit='кг'),
                Ingredient(name='Лосось', cost_per_unit=600, price_per_unit=800, stock_quantity=20, unit='кг'),
                Ingredient(name='Сыр сливочный', cost_per_unit=400, price_per_unit=500, stock_quantity=15, unit='кг'),
            ]
            for ing in basic_ingredients:
                db.session.add(ing)
            db.session.commit()
            print("✅ Созданы базовые ингредиенты")
        
        print("🍣 Загружаем роллы из Excel...")
        
        # Путь к файлу роллов
        rolls_file = '../sushiback/rolls.xlsx'
        
        if os.path.exists(rolls_file):
            df = pd.read_excel(rolls_file)
            print(f"📊 Найдено {len(df)} роллов в Excel")
            
            for _, row in df.iterrows():
                # Рассчитываем себестоимость (примерно 30% от цены продажи)
                sale_price = row['sale_price'] if pd.notna(row['sale_price']) else 300
                cost_price = sale_price * 0.3
                
                roll = Roll(
                    name=row['name'],
                    description=f"Ролл {row['name']}",
                    cost_price=cost_price,
                    sale_price=sale_price,
                    is_popular=True if 'фила' in row['name'].lower() else False,
                    is_new=False
                )
                db.session.add(roll)
            
            db.session.commit()
            print(f"✅ Загружено {len(df)} роллов")
        else:
            print("❌ Файл rolls.xlsx не найден, создаем базовые роллы...")
            # Создаем базовые роллы
            basic_rolls = [
                Roll(name='Филадельфия', description='Лосось, сыр, огурец', cost_price=45, sale_price=350, is_popular=True),
                Roll(name='Калифорния', description='Краб, огурец, икра', cost_price=38, sale_price=280, is_popular=True),
            ]
            for roll in basic_rolls:
                db.session.add(roll)
            db.session.commit()
            print("✅ Созданы базовые роллы")
        
        print("🔗 Создаем состав роллов...")
        
        # Создаем простые связи ролл-ингредиент
        rolls = Roll.query.all()
        ingredients = Ingredient.query.all()
        
        if rolls and ingredients:
            for roll in rolls:
                # Каждый ролл содержит рис и нори
                rice = next((ing for ing in ingredients if 'рис' in ing.name.lower()), None)
                nori = next((ing for ing in ingredients if 'нори' in ing.name.lower()), None)
                
                if rice:
                    ri = RollIngredient(roll_id=roll.id, ingredient_id=rice.id, amount_per_roll=0.1)
                    db.session.add(ri)
                
                if nori:
                    ri = RollIngredient(roll_id=roll.id, ingredient_id=nori.id, amount_per_roll=1)
                    db.session.add(ri)
            
            db.session.commit()
            print("✅ Созданы связи ролл-ингредиент")
        
        print("📦 Загружаем сеты из Excel...")
        
        # Путь к файлу сетов
        sets_file = '../sushiback/sets.xlsx'
        
        if os.path.exists(sets_file):
            df = pd.read_excel(sets_file)
            print(f"📊 Найдено {len(df)} сетов в Excel")
            
            for _, row in df.iterrows():
                set_item = Set(
                    name=row['name'],
                    description=f"Сет {row['name']}",
                    cost_price=row['cost_price'] if pd.notna(row['cost_price']) else 200,
                    set_price=row['set_price'] if pd.notna(row['set_price']) else 600,
                    discount_percent=row['discount_percent'] if pd.notna(row['discount_percent']) else 15,
                    is_popular=True if 'классический' in row['name'].lower() else False,
                    is_new=False
                )
                db.session.add(set_item)
            
            db.session.commit()
            print(f"✅ Загружено {len(df)} сетов")
        else:
            print("❌ Файл sets.xlsx не найден, создаем базовые сеты...")
            # Создаем базовые сеты
            basic_sets = [
                Set(name='Классический', description='Популярные роллы', cost_price=150, set_price=580, discount_percent=15, is_popular=True),
                Set(name='Бюджетный', description='Доступные роллы', cost_price=120, set_price=450, discount_percent=20, is_new=True),
            ]
            for set_item in basic_sets:
                db.session.add(set_item)
            db.session.commit()
            print("✅ Созданы базовые сеты")
        
        print("🔗 Создаем состав сетов...")
        
        # Создаем простые связи сет-ролл
        sets = Set.query.all()
        rolls = Roll.query.all()
        
        if sets and rolls:
            for set_item in sets:
                # Каждый сет содержит 2-3 ролла
                for i, roll in enumerate(rolls[:3]):
                    if i < 3:  # Максимум 3 ролла в сете
                        sr = SetRoll(set_id=set_item.id, roll_id=roll.id, quantity=1)
                        db.session.add(sr)
            
            db.session.commit()
            print("✅ Созданы связи сет-ролл")
        
        print("🎉 Реальные данные успешно загружены!")
        print(f"📊 Статистика:")
        print(f"   👥 Пользователи: {User.query.count()}")
        print(f"   🥬 Ингредиенты: {Ingredient.query.count()}")
        print(f"   🍣 Роллы: {Roll.query.count()}")
        print(f"   📦 Сеты: {Set.query.count()}")
        print(f"   🔗 Состав роллов: {RollIngredient.query.count()}")
        print(f"   🔗 Состав сетов: {SetRoll.query.count()}")

if __name__ == '__main__':
    load_real_data()
