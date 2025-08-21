import sqlite3
import os

def check_db(db_path):
    print(f"\n🔍 Проверяем базу: {db_path}")
    if not os.path.exists(db_path):
        print(f"❌ Не найдена: {db_path}")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Проверяем роллы
    cursor.execute('SELECT COUNT(*) FROM rolls')
    rolls_count = cursor.fetchone()[0]
    print(f"🍣 Роллов: {rolls_count}")
    
    # Проверяем сеты
    cursor.execute('SELECT COUNT(*) FROM sets') 
    sets_count = cursor.fetchone()[0]
    print(f"🍱 Сетов: {sets_count}")
    
    # Проверяем ингредиенты
    cursor.execute('SELECT COUNT(*) FROM ingredients')
    ingredients_count = cursor.fetchone()[0]
    print(f"🧄 Ингредиентов: {ingredients_count}")
    
    # Проверяем рецептуры роллов
    cursor.execute('SELECT COUNT(*) FROM roll_ingredients')
    roll_recipes_count = cursor.fetchone()[0]
    print(f"🧄 Рецептур роллов: {roll_recipes_count}")
    
    # Проверяем состав сетов
    cursor.execute('SELECT COUNT(*) FROM set_rolls')
    set_compositions_count = cursor.fetchone()[0]
    print(f"🥢 Составов сетов: {set_compositions_count}")
    
    # Показываем первые 3 ролла
    print("\n📋 Первые 3 ролла:")
    cursor.execute('SELECT id, name, description, cost_price, sale_price FROM rolls LIMIT 3')
    for roll in cursor.fetchall():
        print(f"   ID: {roll[0]}, Name: {roll[1]}, Cost: {roll[3]}₽, Sale: {roll[4]}₽")
    
    # Показываем первые 3 сета
    print("\n📋 Первые 3 сета:")
    cursor.execute('SELECT id, name, description, cost_price, sale_price FROM sets LIMIT 3')
    for set_item in cursor.fetchall():
        print(f"   ID: {set_item[0]}, Name: {set_item[1]}, Cost: {set_item[3]}₽, Sale: {set_item[4]}₽")
    
    conn.close()

# Проверяем обе базы
check_db('backend/instance/sushi_express.db')
check_db('backend/sushi_express.db')
