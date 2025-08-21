import requests
import json

def test_new_api():
    """Тестирует новые API endpoints для админ-панели"""
    
    base_url = "http://localhost:5000"
    
    print("🧪 Тестирую новые API endpoints...")
    print("=" * 50)
    
    # 1. Тестируем вход админа
    print("\n1️⃣ Тестирую вход админа...")
    login_data = {
        "email": "ss@gmail.com",
        "password": "admin123"
    }
    
    response = requests.post(f"{base_url}/api/login", json=login_data)
    if response.status_code == 200:
        token = response.json()['access_token']
        headers = {'Authorization': f'Bearer {token}'}
        print("✅ Вход успешен, токен получен")
    else:
        print(f"❌ Ошибка входа: {response.status_code}")
        return
    
    # 2. Тестируем получение рецептуры ролла
    print("\n2️⃣ Тестирую получение рецептуры ролла...")
    roll_id = 54  # ID тестового ролла
    
    response = requests.get(f"{base_url}/api/admin/rolls/{roll_id}/recipe", headers=headers)
    print(f"   Статус: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"   ✅ Рецептура получена для ролла: {data['roll_name']}")
        print(f"   📊 Ингредиентов: {len(data['ingredients'])}")
        print(f"   💰 Общая стоимость: {data['total_cost']}₽")
    else:
        print(f"   ❌ Ошибка: {response.text}")
    
    # 3. Тестируем обновление рецептуры ролла
    print("\n3️⃣ Тестирую обновление рецептуры ролла...")
    new_recipe = {
        "ingredients": [
            {"ingredient_id": 94, "amount": 100},  # Рис - 100г
            {"ingredient_id": 87, "amount": 1},    # Нори - 1шт
            {"ingredient_id": 73, "amount": 30},   # Лосось - 30г
        ]
    }
    
    response = requests.put(f"{base_url}/api/admin/rolls/{roll_id}/recipe", 
                           json=new_recipe, headers=headers)
    print(f"   Статус: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"   ✅ Рецептура обновлена!")
        print(f"   📊 Ингредиентов: {data['ingredients_count']}")
        print(f"   💰 Новая себестоимость: {data['total_cost']}₽")
    else:
        print(f"   ❌ Ошибка: {response.text}")
    
    # 4. Проверяем обновленную себестоимость
    print("\n4️⃣ Проверяю обновленную себестоимость...")
    response = requests.get(f"{base_url}/api/admin/rolls", headers=headers)
    if response.status_code == 200:
        rolls = response.json()['rolls']
        test_roll = next((r for r in rolls if r['id'] == roll_id), None)
        if test_roll:
            print(f"   ✅ Ролл: {test_roll['name']}")
            print(f"   💰 Себестоимость: {test_roll['cost_price']}₽")
            print(f"   💰 Цена продажи: {test_roll['sale_price']}₽")
        else:
            print("   ❌ Тестовый ролл не найден")
    else:
        print(f"   ❌ Ошибка получения роллов: {response.status_code}")
    
    print("\n" + "=" * 50)
    print("✅ Тестирование завершено!")

if __name__ == "__main__":
    test_new_api()
