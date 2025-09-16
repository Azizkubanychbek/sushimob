#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для перезапуска Flutter приложения
"""

import subprocess
import sys
import os
import time

def restart_flutter_app():
    print("🔄 ПЕРЕЗАПУСК FLUTTER ПРИЛОЖЕНИЯ")
    print("=" * 50)
    
    # Проверяем, что мы в корневой директории проекта
    if not os.path.exists('pubspec.yaml'):
        print("❌ pubspec.yaml не найден. Убедитесь, что вы в корневой директории Flutter проекта.")
        return
    
    try:
        print("🛑 Останавливаем предыдущие процессы Flutter...")
        
        # Останавливаем все процессы Flutter
        try:
            subprocess.run(['taskkill', '/f', '/im', 'flutter.exe'], 
                         capture_output=True, check=False)
            subprocess.run(['taskkill', '/f', '/im', 'dart.exe'], 
                         capture_output=True, check=False)
        except:
            pass
        
        time.sleep(2)
        
        print("🚀 Запуск Flutter приложения на Chrome...")
        
        # Запускаем Flutter приложение
        process = subprocess.Popen([
            'flutter', 'run', '-d', 'chrome', '--web-port=3000', '--hot'
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1, universal_newlines=True)
        
        print("✅ Flutter приложение перезапускается...")
        print("🌐 Приложение будет доступно по адресу: http://localhost:3000")
        print("📝 Логи приложения:")
        print("-" * 50)
        
        # Выводим логи в реальном времени
        for line in process.stdout:
            print(line.rstrip())
            
            # Проверяем, что приложение запустилось
            if 'Flutter run key commands' in line or 'Application finished' in line:
                print("\n🎉 Flutter приложение перезапущено!")
                print("🔗 Откройте браузер и перейдите на http://localhost:3000")
                print("🛒 Теперь корзина должна работать правильно!")
                break
        
        # Ждем завершения процесса
        process.wait()
        
    except FileNotFoundError:
        print("❌ Flutter не найден. Убедитесь, что Flutter установлен и добавлен в PATH.")
    except KeyboardInterrupt:
        print("\n⏹️  Перезапуск приложения прерван пользователем")
        if process:
            process.terminate()
    except Exception as e:
        print(f"❌ Ошибка перезапуска Flutter приложения: {e}")

if __name__ == "__main__":
    restart_flutter_app()

