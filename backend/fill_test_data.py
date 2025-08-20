from app_sqlite import app, db
from models import User, Ingredient, Roll, RollIngredient, Set, SetRoll
from werkzeug.security import generate_password_hash
from datetime import datetime

def fill_test_data():
    """Заполнение базы данных тестовыми данными"""
    
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
        
        print("🥬 Создаем ингредиенты...")
        
        # Создаем ингредиенты
        ingredients = [
            Ingredient(name='Рис', cost_per_unit=80, price_per_unit=100, stock_quantity=50, unit='кг'),
            Ingredient(name='Лосось', cost_per_unit=600, price_per_unit=800, stock_quantity=20, unit='кг'),
            Ingredient(name='Сыр сливочный', cost_per_unit=400, price_per_unit=500, stock_quantity=15, unit='кг'),
            Ingredient(name='Огурец', cost_per_unit=100, price_per_unit=120, stock_quantity=30, unit='кг'),
            Ingredient(name='Нори', cost_per_unit=15, price_per_unit=20, stock_quantity=200, unit='лист'),
            Ingredient(name='Крабовые палочки', cost_per_unit=250, price_per_unit=300, stock_quantity=25, unit='кг'),
            Ingredient(name='Авокадо', cost_per_unit=300, price_per_unit=400, stock_quantity=10, unit='кг'),
            Ingredient(name='Икра масаго', cost_per_unit=1200, price_per_unit=1500, stock_quantity=5, unit='кг'),
            Ingredient(name='Угорь', cost_per_unit=1000, price_per_unit=1200, stock_quantity=8, unit='кг'),
            Ingredient(name='Кунжут', cost_per_unit=150, price_per_unit=200, stock_quantity=3, unit='кг'),
        ]
        
        for ingredient in ingredients:
            db.session.add(ingredient)
        
        db.session.commit()
        print(f"✅ Создано {len(ingredients)} ингредиентов")
        
        print("🍣 Создаем роллы...")
        
        # Создаем роллы
        rolls = [
            Roll(name='Филадельфия', description='Лосось, сыр, огурец', cost_price=45, sale_price=350, is_popular=True),
            Roll(name='Калифорния', description='Краб, огурец, икра', cost_price=38, sale_price=280, is_popular=True),
            Roll(name='Каппа маки', description='Огурец, рис, нори', cost_price=25, sale_price=180, is_new=True),
            Roll(name='Унаги маки', description='Угорь, рис, кунжут', cost_price=42, sale_price=320),
            Roll(name='Крабовый ролл', description='Краб, сыр, огурец', cost_price=35, sale_price=260),
        ]
        
        for roll in rolls:
            db.session.add(roll)
        
        db.session.commit()
        print(f"✅ Создано {len(rolls)} роллов")
        
        print("🔗 Создаем состав роллов...")
        
        # Создаем состав роллов
        roll_ingredients = [
            # Филадельфия
            RollIngredient(roll_id=1, ingredient_id=1, amount_per_roll=0.12),  # Рис
            RollIngredient(roll_id=1, ingredient_id=2, amount_per_roll=0.06),  # Лосось
            RollIngredient(roll_id=1, ingredient_id=3, amount_per_roll=0.03),  # Сыр
            RollIngredient(roll_id=1, ingredient_id=5, amount_per_roll=1),     # Нори
            
            # Калифорния
            RollIngredient(roll_id=2, ingredient_id=1, amount_per_roll=0.10),  # Рис
            RollIngredient(roll_id=2, ingredient_id=6, amount_per_roll=0.04),  # Краб
            RollIngredient(roll_id=2, ingredient_id=4, amount_per_roll=0.02),  # Огурец
            RollIngredient(roll_id=2, ingredient_id=8, amount_per_roll=0.01),  # Икра
            RollIngredient(roll_id=2, ingredient_id=5, amount_per_roll=1),     # Нори
            
            # Каппа маки
            RollIngredient(roll_id=3, ingredient_id=1, amount_per_roll=0.08),  # Рис
            RollIngredient(roll_id=3, ingredient_id=4, amount_per_roll=0.03),  # Огурец
            RollIngredient(roll_id=3, ingredient_id=5, amount_per_roll=1),     # Нори
            
            # Унаги маки
            RollIngredient(roll_id=4, ingredient_id=1, amount_per_roll=0.09),  # Рис
            RollIngredient(roll_id=4, ingredient_id=9, amount_per_roll=0.04),  # Угорь
            RollIngredient(roll_id=4, ingredient_id=5, amount_per_roll=1),     # Нори
            RollIngredient(roll_id=4, ingredient_id=10, amount_per_roll=0.005), # Кунжут
            
            # Крабовый ролл
            RollIngredient(roll_id=5, ingredient_id=1, amount_per_roll=0.09),  # Рис
            RollIngredient(roll_id=5, ingredient_id=6, amount_per_roll=0.05),  # Краб
            RollIngredient(roll_id=5, ingredient_id=3, amount_per_roll=0.02),  # Сыр
            RollIngredient(roll_id=5, ingredient_id=5, amount_per_roll=1),     # Нори
        ]
        
        for ri in roll_ingredients:
            db.session.add(ri)
        
        db.session.commit()
        print(f"✅ Создано {len(roll_ingredients)} связей ролл-ингредиент")
        
        print("📦 Создаем сеты...")
        
        # Создаем сеты
        sets = [
            Set(name='Классический', description='Популярные роллы', cost_price=150, set_price=580, discount_percent=15, is_popular=True),
            Set(name='Бюджетный', description='Доступные роллы', cost_price=120, set_price=450, discount_percent=20, is_new=True),
            Set(name='Премиум', description='Элитные роллы', cost_price=200, set_price=800, discount_percent=10),
        ]
        
        for set_item in sets:
            db.session.add(set_item)
        
        db.session.commit()
        print(f"✅ Создано {len(sets)} сетов")
        
        print("🔗 Создаем состав сетов...")
        
        # Создаем состав сетов
        set_rolls = [
            # Классический
            SetRoll(set_id=1, roll_id=1, quantity=1),  # Филадельфия
            SetRoll(set_id=1, roll_id=2, quantity=1),  # Калифорния
            SetRoll(set_id=1, roll_id=3, quantity=1),  # Каппа маки
            
            # Бюджетный
            SetRoll(set_id=2, roll_id=3, quantity=1),  # Каппа маки
            SetRoll(set_id=2, roll_id=5, quantity=1),  # Крабовый ролл
            
            # Премиум
            SetRoll(set_id=3, roll_id=1, quantity=1),  # Филадельфия
            SetRoll(set_id=3, roll_id=4, quantity=1),  # Унаги маки
            SetRoll(set_id=3, roll_id=2, quantity=1),  # Калифорния
        ]
        
        for sr in set_rolls:
            db.session.add(sr)
        
        db.session.commit()
        print(f"✅ Создано {len(set_rolls)} связей сет-ролл")
        
        print("🎉 Тестовые данные успешно созданы!")
        print(f"📊 Статистика:")
        print(f"   👥 Пользователи: {User.query.count()}")
        print(f"   🥬 Ингредиенты: {Ingredient.query.count()}")
        print(f"   🍣 Роллы: {Roll.query.count()}")
        print(f"   📦 Сеты: {Set.query.count()}")
        print(f"   🔗 Состав роллов: {RollIngredient.query.count()}")
        print(f"   🔗 Состав сетов: {SetRoll.query.count()}")

if __name__ == '__main__':
    fill_test_data()
