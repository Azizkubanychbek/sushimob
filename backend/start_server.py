#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для запуска сервера
"""

import subprocess
import sys
import time

def start_server():
    print("🚀 ЗАПУСК СЕРВЕРА SUSHI EXPRESS API")
    print("=" * 50)
    
    try:
        print("📡 Запускаем Flask сервер...")
        print("🌐 Сервер будет доступен по адресу: http://127.0.0.1:5000")
        print("📊 База данных: SQLite (sushi_express.db)")
        print("=" * 50)
        
        # Запускаем сервер
        subprocess.run([sys.executable, 'app_sqlite.py'], cwd='.')
        
    except KeyboardInterrupt:
        print("\n⏹️ Сервер остановлен пользователем")
    except Exception as e:
        print(f"❌ Ошибка запуска сервера: {e}")

if __name__ == "__main__":
    start_server()

