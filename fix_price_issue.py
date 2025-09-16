#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления проблемы с ценами
"""

import requests
import json

def fix_price_issue():
    print("🔧 ИСПРАВЛЕНИЕ ПРОБЛЕМЫ С ЦЕНАМИ")
    print("=" * 50)
    
    base_url = 'http://127.0.0.1:5000/api'
    
    try:
        print("📝 Проверка роллов с деталями")
        response = requests.get(f'{base_url}/rolls')
        if response.status_code == 200:
            data = response.json()
            rolls = data.get('rolls', [])
            print(f"✅ Роллов получено: {len(rolls)}")
            
            if rolls:
                print("\n📋 Детали первых 3 роллов:")
                for i, roll in enumerate(rolls[:3]):
                    print(f"   {i+1}. {roll.get('name', 'Без названия')}")
                    print(f"      Цена: {roll.get('price', 'НЕТ')}")
                    print(f"      sale_price: {roll.get('sale_price', 'НЕТ')}")
                    print(f"      Все поля: {list(roll.keys())}")
                    print()
        else:
            print(f"❌ Ошибка получения роллов: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")
    
    try:
        print("\n📝 Проверка сетов с деталями")
        response = requests.get(f'{base_url}/sets')
        if response.status_code == 200:
            data = response.json()
            sets = data.get('sets', [])
            print(f"✅ Сетов получено: {len(sets)}")
            
            if sets:
                print("\n📋 Детали первых 3 сетов:")
                for i, set_item in enumerate(sets[:3]):
                    print(f"   {i+1}. {set_item.get('name', 'Без названия')}")
                    print(f"      Цена: {set_item.get('price', 'НЕТ')}")
                    print(f"      set_price: {set_item.get('set_price', 'НЕТ')}")
                    print(f"      Все поля: {list(set_item.keys())}")
                    print()
        else:
            print(f"❌ Ошибка получения сетов: {response.status_code}")
    except Exception as e:
        print(f"❌ Исключение: {e}")

if __name__ == "__main__":
    fix_price_issue()

