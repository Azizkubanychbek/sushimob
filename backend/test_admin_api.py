import requests
import json

def test_admin_api():
    base_url = "http://localhost:5000"
    
    print("🔍 Тестирую админ API endpoints...")
    print("=" * 50)
    
    # Тестируем без токена (должен вернуть 401)
    print("\n1️⃣ Тест без токена (должен вернуть 401):")
    try:
        response = requests.get(f"{base_url}/api/admin/users")
        print(f"   Users endpoint: {response.status_code} - {response.text[:100]}")
    except Exception as e:
        print(f"   ❌ Ошибка: {e}")
    
    try:
        response = requests.get(f"{base_url}/api/admin/ingredients")
        print(f"   Ingredients endpoint: {response.status_code} - {response.text[:100]}")
    except Exception as e:
        print(f"   ❌ Ошибка: {e}")
    
    # Тестируем с неверным токеном
    print("\n2️⃣ Тест с неверным токеном:")
    headers = {"Authorization": "Bearer invalid_token"}
    
    try:
        response = requests.get(f"{base_url}/api/admin/users", headers=headers)
        print(f"   Users endpoint: {response.status_code} - {response.text[:100]}")
    except Exception as e:
        print(f"   ❌ Ошибка: {e}")
    
    # Проверяем, что backend вообще отвечает
    print("\n3️⃣ Проверка доступности backend:")
    try:
        response = requests.get(f"{base_url}/api/health")
        print(f"   Health endpoint: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   ❌ Backend недоступен: {e}")
        print("   💡 Запустите backend: python app_sqlite.py")
        return
    
    print("\n✅ Тест завершен!")

if __name__ == "__main__":
    test_admin_api()
