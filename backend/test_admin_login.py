import requests
import json

def test_admin_login():
    base_url = "http://localhost:5000"
    
    print("🔐 Тестирую вход админа...")
    print("=" * 50)
    
    # Данные для входа админа
    login_data = {
        "email": "ss@gmail.com",
        "password": "admin123"  # Обновленный пароль
    }
    
    print(f"📧 Email: {login_data['email']}")
    print(f"🔑 Пароль: {login_data['password']}")
    print()
    
    try:
        # Пытаемся войти
        print("1️⃣ Попытка входа...")
        response = requests.post(
            f"{base_url}/api/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"   Статус: {response.status_code}")
        print(f"   Ответ: {response.text[:200]}")
        
        if response.status_code == 200:
            data = response.json()
            access_token = data.get('access_token')
            
            if access_token:
                print(f"\n✅ Вход успешен!")
                print(f"🔑 Токен: {access_token[:50]}...")
                
                # Тестируем админ API с токеном
                print("\n2️⃣ Тестирую админ API с токеном...")
                headers = {"Authorization": f"Bearer {access_token}"}
                
                # Тест получения пользователей
                try:
                    users_response = requests.get(f"{base_url}/api/admin/users", headers=headers)
                    print(f"   Users endpoint: {users_response.status_code}")
                    if users_response.status_code == 200:
                        users_data = users_response.json()
                        print(f"   📊 Получено пользователей: {len(users_data.get('users', []))}")
                    else:
                        print(f"   ❌ Ошибка: {users_response.text}")
                except Exception as e:
                    print(f"   ❌ Ошибка при получении пользователей: {e}")
                
                # Тест получения ингредиентов
                try:
                    ingredients_response = requests.get(f"{base_url}/api/admin/ingredients", headers=headers)
                    print(f"   Ingredients endpoint: {ingredients_response.status_code}")
                    if ingredients_response.status_code == 200:
                        ingredients_data = ingredients_response.json()
                        print(f"   📊 Получено ингредиентов: {len(ingredients_data.get('ingredients', []))}")
                    else:
                        print(f"   ❌ Ошибка: {ingredients_response.text}")
                except Exception as e:
                    print(f"   ❌ Ошибка при получении ингредиентов: {e}")
                
            else:
                print("❌ Токен не найден в ответе")
        else:
            print("❌ Вход не удался")
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
    
    print("\n✅ Тест завершен!")

if __name__ == "__main__":
    test_admin_login()
