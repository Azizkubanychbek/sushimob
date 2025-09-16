#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления блока try-except в функции check_ingredient_availability
"""

def fix_try_except_block():
    print("🔧 ИСПРАВЛЕНИЕ БЛОКА TRY-EXCEPT")
    print("=" * 50)
    
    # Читаем файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Исправляем функцию check_ingredient_availability
    old_function = '''def check_ingredient_availability(ingredient_id, required_quantity=1):
    """Проверяет наличие ингредиента в достаточном количестве"""
    try:
    except Exception as e:
        return jsonify({'error': f'Ошибка: {str(e)}'}), 500
        ingredient = Ingredient.query.get(ingredient_id)
        if not ingredient:
            return False, "Ингредиент не найден"
        
        if ingredient.stock_quantity is None or ingredient.stock_quantity <= 0:
            return False, f"Ингредиент '{ingredient.name}' закончился"
        
        if ingredient.stock_quantity < required_quantity:
            return False, f"Недостаточно ингредиента '{ingredient.name}'. Доступно: {ingredient.stock_quantity}, требуется: {required_quantity}"
        
        return True, "В наличии"
    except Exception as e:
        return False, f"Ошибка проверки наличия: {str(e)}"'''
    
    new_function = '''def check_ingredient_availability(ingredient_id, required_quantity=1):
    """Проверяет наличие ингредиента в достаточном количестве"""
    try:
        ingredient = Ingredient.query.get(ingredient_id)
        if not ingredient:
            return False, "Ингредиент не найден"
        
        if ingredient.stock_quantity is None or ingredient.stock_quantity <= 0:
            return False, f"Ингредиент '{ingredient.name}' закончился"
        
        if ingredient.stock_quantity < required_quantity:
            return False, f"Недостаточно ингредиента '{ingredient.name}'. Доступно: {ingredient.stock_quantity}, требуется: {required_quantity}"
        
        return True, "В наличии"
    except Exception as e:
        return False, f"Ошибка проверки наличия: {str(e)}"'''
    
    # Заменяем старую функцию на новую
    if old_function in content:
        content = content.replace(old_function, new_function)
        print("✅ Функция check_ingredient_availability исправлена")
    else:
        print("❌ Функция не найдена для замены")
        # Попробуем найти и исправить по-другому
        lines = content.split('\n')
        new_lines = []
        in_broken_function = False
        fixed = False
        
        for i, line in enumerate(lines):
            if 'def check_ingredient_availability' in line:
                in_broken_function = True
                new_lines.append(line)
                continue
            
            if in_broken_function:
                if line.strip() == 'try:':
                    new_lines.append('    try:')
                    new_lines.append('        ingredient = Ingredient.query.get(ingredient_id)')
                    new_lines.append('        if not ingredient:')
                    new_lines.append('            return False, "Ингредиент не найден"')
                    new_lines.append('        ')
                    new_lines.append('        if ingredient.stock_quantity is None or ingredient.stock_quantity <= 0:')
                    new_lines.append('            return False, f"Ингредиент \'{ingredient.name}\' закончился"')
                    new_lines.append('        ')
                    new_lines.append('        if ingredient.stock_quantity < required_quantity:')
                    new_lines.append('            return False, f"Недостаточно ингредиента \'{ingredient.name}\'. Доступно: {ingredient.stock_quantity}, требуется: {required_quantity}"')
                    new_lines.append('        ')
                    new_lines.append('        return True, "В наличии"')
                    new_lines.append('    except Exception as e:')
                    new_lines.append('        return False, f"Ошибка проверки наличия: {str(e)}"')
                    fixed = True
                    continue
                
                if line.strip().startswith('except') or line.strip().startswith('return jsonify') or 'ingredient = Ingredient.query.get' in line:
                    continue
                
                if line.strip() == '' and fixed:
                    in_broken_function = False
                    new_lines.append(line)
                    continue
            
            new_lines.append(line)
        
        content = '\n'.join(new_lines)
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Блок try-except исправлен!")

if __name__ == "__main__":
    fix_try_except_block()

