#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для диагностики проблем с запуском сервера
"""

import sys
import traceback

def debug_server_startup():
    print("🔍 ДИАГНОСТИКА ЗАПУСКА СЕРВЕРА")
    print("=" * 50)
    
    try:
        print("📝 Проверяем импорт модулей...")
        
        print("  - Импорт Flask...")
        from flask import Flask, request, jsonify
        print("    ✅ Flask импортирован")
        
        print("  - Импорт SQLAlchemy...")
        from flask_sqlalchemy import SQLAlchemy
        print("    ✅ SQLAlchemy импортирован")
        
        print("  - Импорт JWT...")
        from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
        print("    ✅ JWT импортирован")
        
        print("  - Импорт CORS...")
        from flask_cors import CORS
        print("    ✅ CORS импортирован")
        
        print("  - Импорт других модулей...")
        from werkzeug.security import generate_password_hash, check_password_hash
        import os
        import json
        from datetime import datetime, timedelta
        print("    ✅ Остальные модули импортированы")
        
        print("\n📝 Проверяем импорт моделей...")
        from models import db, User, Ingredient, Roll, RollIngredient, Set, SetRoll, Order, OrderItem, OtherItem, LoyaltyCard, LoyaltyRoll, LoyaltyCardUsage, ReferralUsage
        print("    ✅ Модели импортированы")
        
        print("\n📝 Проверяем создание Flask приложения...")
        app = Flask(__name__)
        print("    ✅ Flask приложение создано")
        
        print("\n📝 Проверяем конфигурацию...")
        app.config['SECRET_KEY'] = 'your-super-secret-key-change-this-in-production'
        db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sushi_express.db')
        app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
        app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
        app.config['JWT_SECRET_KEY'] = 'jwt-secret-string'
        app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=30)
        print("    ✅ Конфигурация установлена")
        
        print("\n📝 Проверяем инициализацию расширений...")
        db.init_app(app)
        print("    ✅ SQLAlchemy инициализирован")
        
        jwt = JWTManager()
        jwt.init_app(app)
        print("    ✅ JWT инициализирован")
        
        CORS(app)
        print("    ✅ CORS инициализирован")
        
        print("\n📝 Проверяем создание маршрутов...")
        
        @app.route('/api/health', methods=['GET'])
        def health_check():
            return jsonify({
                'status': 'OK', 
                'message': 'Sushi Express API is running!',
                'database': 'SQLite',
                'timestamp': datetime.now().isoformat()
            })
        
        print("    ✅ Маршрут /api/health создан")
        
        print("\n📝 Проверяем подключение к базе данных...")
        with app.app_context():
            # Проверяем подключение к базе данных
            try:
                User.query.first()
                print("    ✅ Подключение к базе данных работает")
            except Exception as e:
                print(f"    ❌ Ошибка подключения к БД: {e}")
                return
        
        print("\n✅ ВСЕ ПРОВЕРКИ ПРОШЛИ УСПЕШНО!")
        print("🚀 Сервер готов к запуску")
        
        print("\n📝 Запускаем сервер...")
        app.run(host='0.0.0.0', port=5000, debug=True)
        
    except ImportError as e:
        print(f"❌ Ошибка импорта: {e}")
        print("🔧 Установите недостающие пакеты:")
        print("   pip install flask flask-sqlalchemy flask-jwt-extended flask-cors")
    except Exception as e:
        print(f"❌ Неожиданная ошибка: {e}")
        print("\n🔍 Подробная информация об ошибке:")
        traceback.print_exc()

if __name__ == "__main__":
    debug_server_startup()

