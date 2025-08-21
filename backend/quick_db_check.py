import sqlite3

def main():
    db_path = 'instance/sushi_express.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("🔍 ПРОВЕРКА БАЗЫ ДАННЫХ")
    print("="*50)
    
    # Роллы
    cursor.execute('SELECT COUNT(*) FROM rolls')
    print(f"🍣 Роллов: {cursor.fetchone()[0]}")
    
    # Сеты  
    cursor.execute('SELECT COUNT(*) FROM sets')
    print(f"🍱 Сетов: {cursor.fetchone()[0]}")
    
    # Ингредиенты
    cursor.execute('SELECT COUNT(*) FROM ingredients')
    print(f"🧄 Ингредиентов: {cursor.fetchone()[0]}")
    
    # Рецептуры роллов
    cursor.execute('SELECT COUNT(*) FROM roll_ingredients')
    print(f"🧄 Рецептур роллов: {cursor.fetchone()[0]}")
    
    # Состав сетов
    cursor.execute('SELECT COUNT(*) FROM set_rolls')
    print(f"🥢 Составов сетов: {cursor.fetchone()[0]}")
    
    print("\n📋 ПЕРВЫЕ 3 РОЛЛА:")
    cursor.execute('SELECT id, name, description, cost_price, sale_price FROM rolls LIMIT 3')
    for row in cursor.fetchall():
        print(f"  ID:{row[0]} {row[1]} - Cost:{row[3]}₽ Sale:{row[4]}₽")
    
    print("\n📋 ПЕРВЫЕ 3 СЕТА:")
    cursor.execute('SELECT id, name, description, cost_price, sale_price FROM sets LIMIT 3')
    for row in cursor.fetchall():
        print(f"  ID:{row[0]} {row[1]} - Cost:{row[3]}₽ Sale:{row[4]}₽")
    
    print("\n🧄 ПЕРВЫЕ 5 ИНГРЕДИЕНТОВ:")
    cursor.execute('SELECT id, name, cost_per_unit, unit FROM ingredients LIMIT 5')
    for row in cursor.fetchall():
        print(f"  ID:{row[0]} {row[1]} - {row[2]}₽/{row[3]}")
    
    # Проверяем роллы без рецептур
    print("\n❌ РОЛЛЫ БЕЗ РЕЦЕПТУР:")
    cursor.execute('''
        SELECT r.id, r.name 
        FROM rolls r 
        LEFT JOIN roll_ingredients ri ON r.id = ri.roll_id 
        WHERE ri.roll_id IS NULL
        LIMIT 5
    ''')
    no_recipe_rolls = cursor.fetchall()
    if no_recipe_rolls:
        for row in no_recipe_rolls:
            print(f"  ID:{row[0]} {row[1]}")
    else:
        print("  ✅ Все роллы имеют рецептуры")
    
    # Проверяем сеты без состава
    print("\n❌ СЕТЫ БЕЗ СОСТАВА:")
    cursor.execute('''
        SELECT s.id, s.name 
        FROM sets s 
        LEFT JOIN set_rolls sr ON s.id = sr.set_id 
        WHERE sr.set_id IS NULL
        LIMIT 5
    ''')
    no_composition_sets = cursor.fetchall()
    if no_composition_sets:
        for row in no_composition_sets:
            print(f"  ID:{row[0]} {row[1]}")
    else:
        print("  ✅ Все сеты имеют состав")
    
    conn.close()

if __name__ == "__main__":
    main()
