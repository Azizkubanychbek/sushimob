# 🍣 Sushi Express - Full Stack Application

## 🚀 Backend API с PostgreSQL базой данных

### 📋 Требования
- Docker и Docker Compose
- Python 3.11+ (для локальной разработки)

### 🗄️ Запуск базы данных и backend

#### 1. Запуск через Docker Compose (рекомендуется)
```bash
# Запуск PostgreSQL и backend
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f
```

#### 2. Локальная разработка
```bash
# Установка зависимостей
cd backend
pip install -r requirements.txt

# Запуск PostgreSQL (через Docker)
docker run -d \
  --name sushi_express_db \
  -e POSTGRES_DB=sushi_express \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15

# Запуск backend
python app.py
```

### 🌐 API Endpoints

#### Регистрация
```http
POST http://localhost:5000/api/register
Content-Type: application/json

{
  "name": "Иван Иванов",
  "email": "ivan@example.com",
  "phone": "+79001234567",
  "password": "password123"
}
```

#### Вход
```http
POST http://localhost:5000/api/login
Content-Type: application/json

{
  "email": "ivan@example.com",
  "password": "password123"
}
```

#### Профиль (требует JWT токен)
```http
GET http://localhost:5000/api/profile
Authorization: Bearer <JWT_TOKEN>
```

#### Все пользователи (требует JWT токен)
```http
GET http://localhost:5000/api/users
Authorization: Bearer <JWT_TOKEN>
```

### 🔧 Конфигурация

Файл `backend/config.env` содержит:
- `SECRET_KEY` - секретный ключ Flask
- `JWT_SECRET_KEY` - секретный ключ для JWT токенов
- `DATABASE_URL` - URL подключения к PostgreSQL

### 📊 База данных

PostgreSQL база данных `sushi_express` с таблицей `users`:
- `id` - уникальный идентификатор
- `name` - имя пользователя
- `email` - email (уникальный)
- `phone` - телефон
- `password_hash` - хеш пароля
- `created_at` - дата создания
- `last_login_at` - последний вход
- `loyalty_points` - бонусные баллы
- `is_active` - активность аккаунта

### 🛑 Остановка
```bash
# Остановка всех сервисов
docker-compose down

# Удаление данных базы (осторожно!)
docker-compose down -v
```

### 🔍 Проверка работы
```bash
# Проверка API
curl http://localhost:5000/api/health

# Проверка базы данных
docker exec -it sushi_express_db psql -U postgres -d sushi_express -c "SELECT * FROM users;"
```
