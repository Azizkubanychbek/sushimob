import sqlite3
import os

def create_test_roll():
    """Создает новый тестовый ролл для демонстрации функций редактирования"""
    
    db_path = 'sushi_express.db'
    if not os.path.exists(db_path):
        db_path = 'instance/sushi_express.db'
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🍣 Создаю новый тестовый ролл...")
        
        # Создаем новый тестовый ролл
        test_roll_data = {
            'name': 'Тестовый ролл для разработки',
            'cost_price': 150.0,  # Будет пересчитываться автоматически
            'sale_price': 450.0,
            'image_url': 'https://via.placeholder.com/300x200?text=Test+Roll',
            'is_popular': False,
            'is_new': True,
            'description': 'Этот ролл создан для тестирования функций редактирования рецептуры'
        }
        
        cursor.execute('''
            INSERT INTO rolls (name, cost_price, sale_price, image_url, is_popular, is_new, description)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (
            test_roll_data['name'],
            test_roll_data['cost_price'],
            test_roll_data['sale_price'],
            test_roll_data['image_url'],
            test_roll_data['is_popular'],
            test_roll_data['is_new'],
            test_roll_data['description']
        ))
        
        new_roll_id = cursor.lastrowid
        print(f"✅ Создан новый ролл с ID: {new_roll_id}")
        print(f"📝 Название: {test_roll_data['name']}")
        print(f"💰 Цена продажи: {test_roll_data['sale_price']}₽")
        print(f"📖 Описание: {test_roll_data['description']}")
        
        conn.commit()
        print("\n✅ Тестовый ролл успешно создан!")
        
        # Показываем все роллы
        print("\n📊 Все роллы в базе:")
        cursor.execute("SELECT id, name, sale_price, description FROM rolls ORDER BY id")
        rolls = cursor.fetchall()
        
        for roll in rolls:
            status = "🆕 НОВЫЙ" if roll[0] == new_roll_id else "✅ Существующий"
            print(f"  {roll[0]}. {roll[1]} - {roll[2]}₽ {status}")
            if roll[3]:  # description
                print(f"     📖 {roll[3]}")
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    create_test_roll()
