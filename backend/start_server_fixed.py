#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Запуск сервера с правильными настройками
"""

import subprocess
import time

def start_server_fixed():
    print("🚀 ЗАПУСК СЕРВЕРА С ПРАВИЛЬНЫМИ НАСТРОЙКАМИ")
    print("=" * 50)
    
    print("🔧 Проблема: Flutter обращается к localhost:5000")
    print("🔧 Решение: Запустить сервер на localhost:5000")
    
    try:
        print("\n🛑 Останавливаем старый сервер...")
        # Останавливаем старые процессы
        try:
            subprocess.run(['taskkill', '/f', '/im', 'python.exe'], 
                         capture_output=True, check=False)
        except:
            pass
        
        time.sleep(2)
        
        print("🚀 Запуск нового сервера...")
        # Запускаем сервер
        process = subprocess.Popen([
            'python', 'app_sqlite.py'
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1, universal_newlines=True)
        
        print("⏳ Ожидание запуска сервера...")
        
        # Выводим логи
        for line in process.stdout:
            print(line.rstrip())
            
            if 'Running on http://127.0.0.1:5000' in line or 'Running on http://localhost:5000' in line:
                print("\n✅ СЕРВЕР ЗАПУЩЕН!")
                print("🌐 Доступен по адресам:")
                print("   - http://localhost:5000")
                print("   - http://127.0.0.1:5000")
                print("\n📱 Теперь Flutter приложение должно работать!")
                break
        
        # Ждем завершения
        process.wait()
        
    except Exception as e:
        print(f"❌ Ошибка запуска сервера: {e}")

if __name__ == "__main__":
    start_server_fixed()

