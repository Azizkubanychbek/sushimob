import sqlite3
import os

def fill_roll_recipes():
    """Заполняет рецепты роллов на основе существующих данных"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🍣 Заполняю рецепты роллов...")
        
        # Получаем все роллы
        cursor.execute("SELECT id, name FROM rolls")
        rolls = cursor.fetchall()
        print(f"📊 Найдено роллов: {len(rolls)}")
        
        # Получаем все ингредиенты
        cursor.execute("SELECT id, name, cost_per_unit, unit FROM ingredients")
        ingredients = cursor.fetchall()
        print(f"🥬 Найдено ингредиентов: {len(ingredients)}")
        
        # Создаем базовые рецепты для каждого ролла
        for roll_id, roll_name in rolls:
            print(f"\n🍣 Обрабатываю ролл: {roll_name}")
            
            # Для каждого ролла добавляем несколько базовых ингредиентов
            # Это пример - в реальности нужно будет настроить правильно
            
            # Рис (основа для всех роллов)
            rice_ingredient = next((ing for ing in ingredients if 'рис' in ing[1].lower()), None)
            if rice_ingredient:
                cursor.execute('''
                    INSERT OR IGNORE INTO roll_recipes (roll_id, ingredient_id, quantity, unit)
                    VALUES (?, ?, ?, ?)
                ''', (roll_id, rice_ingredient[0], 100, 'г'))
                print(f"  ✅ Добавлен рис: {rice_ingredient[1]} - 100г")
            
            # Нори (водоросли)
            nori_ingredient = next((ing for ing in ingredients if 'нори' in ing[1].lower()), None)
            if nori_ingredient:
                cursor.execute('''
                    INSERT OR IGNORE INTO roll_recipes (roll_id, ingredient_id, quantity, unit)
                    VALUES (?, ?, ?, ?)
                ''', (roll_id, nori_ingredient[0], 1, 'шт'))
                print(f"  ✅ Добавлен нори: {nori_ingredient[1]} - 1шт")
            
            # Добавляем специфичные ингредиенты в зависимости от названия ролла
            if 'лосось' in roll_name.lower():
                salmon_ingredient = next((ing for ing in ingredients if 'лосось' in ing[1].lower()), None)
                if salmon_ingredient:
                    cursor.execute('''
                        INSERT OR IGNORE INTO roll_recipes (roll_id, ingredient_id, quantity, unit)
                        VALUES (?, ?, ?, ?)
                    ''', (roll_id, salmon_ingredient[0], 30, 'г'))
                    print(f"  ✅ Добавлен лосось: {salmon_ingredient[1]} - 30г")
            
            if 'курица' in roll_name.lower():
                chicken_ingredient = next((ing for ing in ingredients if 'курица' in ing[1].lower()), None)
                if chicken_ingredient:
                    cursor.execute('''
                        INSERT OR IGNORE INTO roll_recipes (roll_id, ingredient_id, quantity, unit)
                        VALUES (?, ?, ?, ?)
                    ''', (roll_id, chicken_ingredient[0], 40, 'г'))
                    print(f"  ✅ Добавлена курица: {chicken_ingredient[1]} - 40г")
            
            if 'угорь' in roll_name.lower():
                eel_ingredient = next((ing for ing in ingredients if 'угорь' in ing[1].lower()), None)
                if eel_ingredient:
                    cursor.execute('''
                        INSERT OR IGNORE INTO roll_recipes (roll_id, ingredient_id, quantity, unit)
                        VALUES (?, ?, ?, ?)
                    ''', (roll_id, eel_ingredient[0], 25, 'г'))
                    print(f"  ✅ Добавлен угорь: {eel_ingredient[1]} - 25г")
            
            if 'огурец' in roll_name.lower():
                cucumber_ingredient = next((ing for ing in ingredients if 'огурец' in ing[1].lower()), None)
                if cucumber_ingredient:
                    cursor.execute('''
                        INSERT OR IGNORE INTO roll_recipes (roll_id, ingredient_id, quantity, unit)
                        VALUES (?, ?, ?, ?)
                    ''', (roll_id, cucumber_ingredient[0], 20, 'г'))
                    print(f"  ✅ Добавлен огурец: {cucumber_ingredient[1]} - 20г")
        
        conn.commit()
        print(f"\n✅ Рецепты роллов заполнены!")
        
        # Показываем статистику
        cursor.execute("SELECT COUNT(*) FROM roll_recipes")
        recipe_count = cursor.fetchone()[0]
        print(f"📊 Всего рецептов создано: {recipe_count}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    fill_roll_recipes()
