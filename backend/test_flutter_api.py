import requests
import json

def test_flutter_api():
    base_url = "http://localhost:5000"
    
    print("🔍 Тестирую API для Flutter...")
    print("=" * 50)
    
    # Сначала входим как админ
    print("1️⃣ Вход как админ...")
    login_data = {
        "email": "ss@gmail.com",
        "password": "admin123"
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            access_token = data.get('access_token')
            print(f"✅ Вход успешен! Токен получен")
            
            # Тестируем все админ endpoints
            headers = {"Authorization": f"Bearer {access_token}"}
            
            print("\n2️⃣ Тестирую админ API endpoints...")
            
            # Users
            try:
                users_response = requests.get(f"{base_url}/api/admin/users", headers=headers)
                print(f"   👥 Users: {users_response.status_code}")
                if users_response.status_code == 200:
                    users_data = users_response.json()
                    print(f"      📊 Получено: {len(users_data.get('users', []))} пользователей")
                else:
                    print(f"      ❌ Ошибка: {users_response.text[:100]}")
            except Exception as e:
                print(f"      ❌ Ошибка: {e}")
            
            # Ingredients
            try:
                ingredients_response = requests.get(f"{base_url}/api/admin/ingredients", headers=headers)
                print(f"   🥬 Ingredients: {ingredients_response.status_code}")
                if ingredients_response.status_code == 200:
                    ingredients_data = ingredients_response.json()
                    print(f"      📊 Получено: {len(ingredients_data.get('ingredients', []))} ингредиентов")
                else:
                    print(f"      ❌ Ошибка: {ingredients_response.text[:100]}")
            except Exception as e:
                print(f"      ❌ Ошибка: {e}")
            
            # Rolls
            try:
                rolls_response = requests.get(f"{base_url}/api/admin/rolls", headers=headers)
                print(f"   🍣 Rolls: {rolls_response.status_code}")
                if rolls_response.status_code == 200:
                    rolls_data = rolls_response.json()
                    print(f"      📊 Получено: {len(rolls_data.get('rolls', []))} роллов")
                else:
                    print(f"      ❌ Ошибка: {rolls_response.text[:100]}")
            except Exception as e:
                print(f"      ❌ Ошибка: {e}")
            
            # Sets
            try:
                sets_response = requests.get(f"{base_url}/api/admin/sets", headers=headers)
                print(f"   🍱 Sets: {sets_response.status_code}")
                if sets_response.status_code == 200:
                    sets_data = sets_response.json()
                    print(f"      📊 Получено: {len(sets_data.get('sets', []))} сетов")
                else:
                    print(f"      ❌ Ошибка: {sets_response.text[:100]}")
            except Exception as e:
                print(f"      ❌ Ошибка: {e}")
            
            # Other items
            try:
                other_response = requests.get(f"{base_url}/api/admin/other-items", headers=headers)
                print(f"   🥤 Other items: {other_response.status_code}")
                if other_response.status_code == 200:
                    other_data = other_response.json()
                    print(f"      📊 Получено: {len(other_data.get('items', []))} товаров")
                else:
                    print(f"      ❌ Ошибка: {other_response.text[:100]}")
            except Exception as e:
                print(f"      ❌ Ошибка: {e}")
            
        else:
            print(f"❌ Вход не удался: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
    
    print("\n✅ Тест завершен!")

if __name__ == "__main__":
    test_flutter_api()
