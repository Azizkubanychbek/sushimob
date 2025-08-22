#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3

def restore_correct_prices():
    conn = sqlite3.connect('instance/sushi_express.db')
    cursor = conn.cursor()
    
    print('💰 ВОССТАНОВЛЕНИЕ ПРАВИЛЬНЫХ ЦЕН РОЛЛОВ')
    print('='*50)
    
    # Правильные цены от пользователя
    correct_prices = {
        'Калифорния': {'cost': 96.59, 'sale': 370},
        'Филадельфия': {'cost': 203.21, 'sale': 700},
        'Сладкий ролл': {'cost': 129.13, 'sale': 510},
        'Жареный Чикен маки': {'cost': 79.02, 'sale': 310},
        'Острый лосось': {'cost': 139.55, 'sale': 560},
        'Лосось темпура': {'cost': 160.94, 'sale': 650},
        'Курица темпура': {'cost': 82.54, 'sale': 360},
        'Угорь темпура': {'cost': 141.24, 'sale': 560},
        'Копченная фила': {'cost': 196.52, 'sale': 790},
        'Фила спешл': {'cost': 209.71, 'sale': 850},
        'Запеченный магистр': {'cost': 82.25, 'sale': 340},
        'Запеченная фила': {'cost': 203.11, 'sale': 820},
        'Саке маки': {'cost': 74.5, 'sale': 305},
        'Унаги запеченный': {'cost': 100.7, 'sale': 405},
        'Овощной ролл': {'cost': 45.85, 'sale': 230},
        'Чикаго ролл': {'cost': 86.29, 'sale': 420},
        'Запеченная Маки курица': {'cost': 48.72, 'sale': 250},
        'Фила с угрем': {'cost': 140.2, 'sale': 680},
        'Чедр ролл': {'cost': 118.17, 'sale': 470},
        'Мини ролл огурец': {'cost': 34.55, 'sale': 175},
        'Ролл запеченный нежный': {'cost': 93.86, 'sale': 375},
        'Ролл томаго': {'cost': 105.1, 'sale': 420}
    }
    
    updated_count = 0
    
    for roll_name, prices in correct_prices.items():
        try:
            cursor.execute('''
                UPDATE rolls 
                SET cost_price = ?, sale_price = ?
                WHERE name = ?
            ''', (prices['cost'], prices['sale'], roll_name))
            
            if cursor.rowcount > 0:
                print(f'✅ {roll_name}: {prices["cost"]}с -> {prices["sale"]}с')
                updated_count += 1
            else:
                print(f'⚠️ Ролл не найден: {roll_name}')
                
        except Exception as e:
            print(f'❌ Ошибка обновления {roll_name}: {e}')
    
    conn.commit()
    print(f'\n🎉 Обновлено {updated_count} роллов!')
    
    # Проверяем результат
    print('\n📊 ПРОВЕРКА ОБНОВЛЕННЫХ ЦЕН:')
    cursor.execute('SELECT name, cost_price, sale_price FROM rolls ORDER BY name')
    for roll in cursor.fetchall():
        print(f'  {roll[0]}: {roll[1]}с -> {roll[2]}с')
    
    conn.close()

if __name__ == '__main__':
    restore_correct_prices()
