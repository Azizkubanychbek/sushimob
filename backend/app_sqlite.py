from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import os
from datetime import datetime, timedelta

app = Flask(__name__)

# Конфигурация для SQLite
app.config['SECRET_KEY'] = 'your-super-secret-key-change-this-in-production'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///sushi_express.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'jwt-secret-string'
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=30)

# Инициализация расширений
db = SQLAlchemy(app)
jwt = JWTManager(app)
CORS(app)

# Модель пользователя
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login_at = db.Column(db.DateTime)
    loyalty_points = db.Column(db.Integer, default=100)
    is_active = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login_at': self.last_login_at.isoformat() if self.last_login_at else None,
            'loyalty_points': self.loyalty_points,
            'is_active': self.is_active
        }

# Создание таблиц
with app.app_context():
    db.create_all()
    print("✅ База данных SQLite создана!")
    print("📁 Файл: sushi_express.db")

# Маршруты API
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'OK', 
        'message': 'Sushi Express API is running!',
        'database': 'SQLite',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        # Валидация данных
        required_fields = ['name', 'email', 'phone', 'password']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'Поле {field} обязательно'}), 400
        
        # Проверка длины пароля
        if len(data['password']) < 6:
            return jsonify({'error': 'Пароль должен содержать минимум 6 символов'}), 400
        
        # Проверка существования пользователя
        existing_user = User.query.filter_by(email=data['email'].lower()).first()
        if existing_user:
            return jsonify({'error': 'Пользователь с таким email уже существует'}), 400
        
        # Создание нового пользователя
        new_user = User(
            name=data['name'].strip(),
            email=data['email'].strip().lower(),
            phone=data['phone'].strip(),
            password_hash=generate_password_hash(data['password'])
        )
        
        db.session.add(new_user)
        db.session.commit()
        
        print(f"✅ Новый пользователь зарегистрирован: {new_user.name} ({new_user.email})")
        
        # Создание JWT токена
        access_token = create_access_token(identity=new_user.id)
        
        return jsonify({
            'success': True,
            'message': 'Регистрация прошла успешно!',
            'user': new_user.to_dict(),
            'access_token': access_token
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"❌ Ошибка при регистрации: {e}")
        return jsonify({'error': f'Ошибка при регистрации: {str(e)}'}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        # Валидация данных
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email и пароль обязательны'}), 400
        
        # Поиск пользователя
        user = User.query.filter_by(email=data['email'].lower()).first()
        if not user:
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        # Проверка пароля
        if not check_password_hash(user.password_hash, data['password']):
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        # Проверка активности аккаунта
        if not user.is_active:
            return jsonify({'error': 'Аккаунт деактивирован'}), 401
        
        # Обновление времени последнего входа
        user.last_login_at = datetime.utcnow()
        db.session.commit()
        
        print(f"✅ Пользователь вошел в систему: {user.name} ({user.email})")
        
        # Создание JWT токена
        access_token = create_access_token(identity=user.id)
        
        return jsonify({
            'success': True,
            'message': f'Добро пожаловать, {user.name}!',
            'user': user.to_dict(),
            'access_token': access_token
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при входе: {e}")
        return jsonify({'error': f'Ошибка при входе: {str(e)}'}), 500

@app.route('/api/profile', methods=['GET'])
@jwt_required()
def get_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Пользователь не найден'}), 404
        
        return jsonify({
            'success': True,
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении профиля: {e}")
        return jsonify({'error': f'Ошибка при получении профиля: {str(e)}'}), 500

@app.route('/api/users', methods=['GET'])
@jwt_required()
def get_users():
    try:
        users = User.query.all()
        print(f"🔍 Запрошен список пользователей. Всего: {len(users)}")
        return jsonify({
            'success': True,
            'users': [user.to_dict() for user in users],
            'total': len(users)
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при получении пользователей: {e}")
        return jsonify({'error': f'Ошибка при получении пользователей: {str(e)}'}), 500

@app.route('/api/debug/users', methods=['GET'])
def debug_users():
    """Отладочный endpoint для просмотра всех пользователей без авторизации"""
    try:
        users = User.query.all()
        print(f"🔍 Отладочный запрос пользователей. Всего: {len(users)}")
        return jsonify({
            'success': True,
            'users': [user.to_dict() for user in users],
            'total': len(users),
            'database_file': 'sushi_express.db'
        }), 200
        
    except Exception as e:
        print(f"❌ Ошибка при отладочном запросе: {e}")
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500

if __name__ == '__main__':
    print("🚀 Запуск Sushi Express API с SQLite базой данных...")
    print("🌐 API будет доступен по адресу: http://localhost:5000")
    print("📊 База данных: SQLite (sushi_express.db)")
    print("🔑 JWT токены активны 30 дней")
    print("=" * 50)
    
    app.run(debug=True, host='0.0.0.0', port=5000)
