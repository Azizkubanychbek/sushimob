import sqlite3
import os

def fill_set_compositions():
    """Заполняет составы сетов на основе существующих данных"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🍱 Заполняю составы сетов...")
        
        # Получаем все сеты
        cursor.execute("SELECT id, name FROM sets")
        sets = cursor.fetchall()
        print(f"📊 Найдено сетов: {len(sets)}")
        
        # Получаем все роллы
        cursor.execute("SELECT id, name FROM rolls")
        rolls = cursor.fetchall()
        print(f"🍣 Найдено роллов: {len(rolls)}")
        
        # Получаем все другие товары (соусы, напитки)
        cursor.execute("SELECT id, name FROM other_items")
        other_items = cursor.fetchall()
        print(f"🥤 Найдено других товаров: {len(other_items)}")
        
        # Создаем базовые составы для каждого сета
        for set_id, set_name in sets:
            print(f"\n🍱 Обрабатываю сет: {set_name}")
            
            # Для каждого сета добавляем несколько роллов
            # Это пример - в реальности нужно будет настроить правильно
            
            # Добавляем 2-3 ролла в каждый сет
            rolls_to_add = min(3, len(rolls))
            for i in range(rolls_to_add):
                roll_id = rolls[i][0]
                roll_name = rolls[i][1]
                
                cursor.execute('''
                    INSERT OR IGNORE INTO set_compositions (set_id, item_type, item_id, quantity)
                    VALUES (?, ?, ?, ?)
                ''', (set_id, 'roll', roll_id, 1))
                print(f"  ✅ Добавлен ролл: {roll_name}")
            
            # Добавляем соус или напиток в каждый сет
            if other_items:
                other_item_id = other_items[0][0]  # Берем первый доступный
                other_item_name = other_items[0][1]
                
                cursor.execute('''
                    INSERT OR IGNORE INTO set_compositions (set_id, item_type, item_id, quantity)
                    VALUES (?, ?, ?, ?)
                ''', (set_id, 'other_item', other_item_id, 1))
                print(f"  ✅ Добавлен товар: {other_item_name}")
        
        conn.commit()
        print(f"\n✅ Составы сетов заполнены!")
        
        # Показываем статистику
        cursor.execute("SELECT COUNT(*) FROM set_compositions")
        composition_count = cursor.fetchone()[0]
        print(f"📊 Всего составов создано: {composition_count}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    fill_set_compositions()
