#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для создания рабочего сервера без проверки наличия товаров
"""

def create_working_server():
    print("🔧 СОЗДАНИЕ РАБОЧЕГО СЕРВЕРА")
    print("=" * 50)
    
    # Читаем оригинальный файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Удаляем добавленные функции проверки наличия
    print("📝 Удаляем функции проверки наличия...")
    
    # Удаляем функции проверки наличия
    functions_to_remove = [
        '# ===== ФУНКЦИИ ПРОВЕРКИ НАЛИЧИЯ ТОВАРОВ =====',
        'def check_ingredient_availability',
        'def check_roll_availability', 
        'def check_set_availability',
        '# ===== ENDPOINTS ДЛЯ ПРОВЕРКИ НАЛИЧИЯ =====',
        '@app.route(\'/api/rolls/<int:roll_id>/availability\'',
        '@app.route(\'/api/sets/<int:set_id>/availability\'',
        '@app.route(\'/api/ingredients/<int:ingredient_id>/availability\'',
        '@app.route(\'/api/cart/check-availability\'',
    ]
    
    lines = content.split('\n')
    new_lines = []
    skip_until_empty = False
    skip_until_def = False
    skip_until_route = False
    
    for line in lines:
        # Пропускаем строки с функциями проверки наличия
        if any(func in line for func in functions_to_remove):
            if 'def check_' in line:
                skip_until_def = True
                continue
            elif '@app.route' in line and 'availability' in line:
                skip_until_route = True
                continue
            else:
                continue
        
        if skip_until_def:
            if line.strip() == '' and 'def ' in lines[lines.index(line) + 1] if lines.index(line) + 1 < len(lines) else True:
                skip_until_def = False
            continue
            
        if skip_until_route:
            if line.strip() == '' and not line.startswith('    ') and not line.startswith('\t'):
                skip_until_route = False
                new_lines.append('')
            continue
        
        new_lines.append(line)
    
    # Записываем очищенный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
    
    print("✅ Функции проверки наличия удалены")
    print("✅ Сервер готов к запуску")

if __name__ == "__main__":
    create_working_server()

