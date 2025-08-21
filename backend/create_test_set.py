import sqlite3
import os

def create_test_set():
    """Создает новый тестовый сет для демонстрации функций редактирования"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🍱 Создаю новый тестовый сет...")
        
        # Создаем новый тестовый сет
        test_set_data = {
            'name': 'Тестовый сет для разработки',
            'cost_price': 300.0,  # Будет пересчитываться автоматически
            'set_price': 800.0,
            'discount_percent': 0.0,  # Будет рассчитываться автоматически
            'is_popular': False,
            'is_new': True,
            'description': 'Этот сет создан для тестирования функций редактирования состава',
            'image_url': 'https://via.placeholder.com/300x200?text=Test+Set'
        }
        
        cursor.execute('''
            INSERT INTO sets (name, cost_price, set_price, discount_percent, is_popular, is_new, description, image_url)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            test_set_data['name'],
            test_set_data['cost_price'],
            test_set_data['set_price'],
            test_set_data['discount_percent'],
            test_set_data['is_popular'],
            test_set_data['is_new'],
            test_set_data['description'],
            test_set_data['image_url']
        ))
        
        new_set_id = cursor.lastrowid
        print(f"✅ Создан новый сет с ID: {new_set_id}")
        print(f"📝 Название: {test_set_data['name']}")
        print(f"💰 Цена продажи: {test_set_data['set_price']}₽")
        print(f"📖 Описание: {test_set_data['description']}")
        
        conn.commit()
        print("\n✅ Тестовый сет успешно создан!")
        
        # Показываем все сеты
        print("\n📊 Все сеты в базе:")
        cursor.execute("SELECT id, name, set_price, description FROM sets ORDER BY id")
        sets = cursor.fetchall()
        
        for set_item in sets:
            status = "🆕 НОВЫЙ" if set_item[0] == new_set_id else "✅ Существующий"
            print(f"  {set_item[0]}. {set_item[1]} - {set_item[2]}₽ {status}")
            if set_item[3]:  # description
                print(f"     📖 {set_item[3]}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    create_test_set()
