#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для запуска Flutter приложения
"""

import subprocess
import sys
import os

def start_flutter_app():
    print("🚀 ЗАПУСК FLUTTER ПРИЛОЖЕНИЯ")
    print("=" * 50)
    
    # Проверяем, что мы в корневой директории проекта
    if not os.path.exists('pubspec.yaml'):
        print("❌ pubspec.yaml не найден. Убедитесь, что вы в корневой директории Flutter проекта.")
        return
    
    try:
        print("📱 Запуск Flutter приложения на Chrome...")
        
        # Запускаем Flutter приложение
        process = subprocess.Popen([
            'flutter', 'run', '-d', 'chrome', '--web-port=3000'
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1, universal_newlines=True)
        
        print("✅ Flutter приложение запускается...")
        print("🌐 Приложение будет доступно по адресу: http://localhost:3000")
        print("📝 Логи приложения:")
        print("-" * 50)
        
        # Выводим логи в реальном времени
        for line in process.stdout:
            print(line.rstrip())
            
            # Проверяем, что приложение запустилось
            if 'Flutter run key commands' in line:
                print("\n🎉 Flutter приложение успешно запущено!")
                print("🔗 Откройте браузер и перейдите на http://localhost:3000")
                print("📱 Теперь вы можете:")
                print("   1. Войти как обычный пользователь: oo@gmail.com / 123456")
                print("   2. Войти как шеф-повар: chef@sushiroll.com / chef123")
                print("   3. Оформить заказ и увидеть его у шеф-повара")
                break
        
        # Ждем завершения процесса
        process.wait()
        
    except FileNotFoundError:
        print("❌ Flutter не найден. Убедитесь, что Flutter установлен и добавлен в PATH.")
    except KeyboardInterrupt:
        print("\n⏹️  Запуск приложения прерван пользователем")
        if process:
            process.terminate()
    except Exception as e:
        print(f"❌ Ошибка запуска Flutter приложения: {e}")

if __name__ == "__main__":
    start_flutter_app()