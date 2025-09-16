#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Запуск сервера на порту 5001
"""

import os
import sys

def start_server_port_5001():
    print("🚀 ЗАПУСК СЕРВЕРА НА ПОРТУ 5001")
    print("=" * 50)
    
    # Изменяем порт в app_sqlite.py
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Заменяем порт 5000 на 5001
    content = content.replace('port=5000', 'port=5001')
    content = content.replace('localhost:5000', 'localhost:5001')
    content = content.replace('127.0.0.1:5000', '127.0.0.1:5001')
    
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Порт изменен на 5001")
    print("🚀 Запуск сервера...")
    
    # Запускаем сервер
    os.system('python app_sqlite.py')

if __name__ == "__main__":
    start_server_port_5001()

