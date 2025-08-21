import sqlite3
import os

def check_ingredients():
    """Проверяет доступные ингредиенты"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🥬 Проверяю доступные ингредиенты...")
        
        # Показываем первые 10 ингредиентов
        cursor.execute("SELECT id, name, cost_per_unit, unit FROM ingredients ORDER BY id LIMIT 10")
        ingredients = cursor.fetchall()
        
        print(f"\n📊 Первые {len(ingredients)} ингредиентов:")
        for ing in ingredients:
            print(f"  {ing[0]}. {ing[1]} - {ing[2]}₽/{ing[3]}")
        
        # Ищем рис, нори, лосось
        print("\n🔍 Ищем основные ингредиенты:")
        search_terms = ['рис', 'нори', 'лосось', 'курица', 'угорь']
        
        for term in search_terms:
            cursor.execute("SELECT id, name, cost_per_unit, unit FROM ingredients WHERE name LIKE ?", (f'%{term}%',))
            results = cursor.fetchall()
            if results:
                for result in results:
                    print(f"  {result[0]}. {result[1]} - {result[2]}₽/{result[3]}")
            else:
                print(f"  ❌ {term} не найден")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    check_ingredients()
