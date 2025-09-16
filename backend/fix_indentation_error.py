#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления ошибки отступов в app_sqlite.py
"""

def fix_indentation_error():
    print("🔧 ИСПРАВЛЕНИЕ ОШИБКИ ОТСТУПОВ")
    print("=" * 50)
    
    # Читаем файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Находим проблемную строку 36-37
    lines = content.split('\n')
    
    print(f"📝 Проверяем строки 36-37...")
    if len(lines) >= 37:
        print(f"Строка 36: '{lines[35]}'")
        print(f"Строка 37: '{lines[36]}'")
    
    # Исправляем отступы
    for i, line in enumerate(lines):
        if i == 36 and line.strip() == 'except Exception as e:':
            # Добавляем правильный отступ
            lines[i] = '    except Exception as e:'
            print(f"✅ Исправлена строка {i+1}")
        elif i == 37 and 'return jsonify' in line:
            # Добавляем правильный отступ
            lines[i] = '        return jsonify({\'error\': f\'Ошибка: {str(e)}\'}), 500'
            print(f"✅ Исправлена строка {i+1}")
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print("✅ Ошибка отступов исправлена!")

if __name__ == "__main__":
    fix_indentation_error()

