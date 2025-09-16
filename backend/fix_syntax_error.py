#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Скрипт для исправления синтаксической ошибки в app_sqlite.py
"""

def fix_syntax_error():
    print("🔧 ИСПРАВЛЕНИЕ СИНТАКСИЧЕСКОЙ ОШИБКИ")
    print("=" * 50)
    
    # Читаем файл
    with open('app_sqlite.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Находим проблемную строку 525
    lines = content.split('\n')
    
    print(f"📝 Проверяем строку 525...")
    if len(lines) >= 525:
        print(f"Строка 525: {lines[524]}")
        print(f"Строка 524: {lines[523]}")
        print(f"Строка 526: {lines[525]}")
    
    # Ищем блок try без except
    for i, line in enumerate(lines):
        if 'try:' in line and i < len(lines) - 1:
            # Проверяем следующие строки на наличие except или finally
            has_except_or_finally = False
            indent_level = len(line) - len(line.lstrip())
            
            for j in range(i + 1, min(i + 10, len(lines))):
                next_line = lines[j]
                if next_line.strip() == '':
                    continue
                next_indent = len(next_line) - len(next_line.lstrip())
                
                if next_indent <= indent_level and ('except' in next_line or 'finally' in next_line):
                    has_except_or_finally = True
                    break
            
            if not has_except_or_finally:
                print(f"❌ Найдена проблема на строке {i+1}: {line.strip()}")
                print("🔧 Исправляем...")
                
                # Добавляем except блок
                lines.insert(i + 1, '    except Exception as e:')
                lines.insert(i + 2, '        return jsonify({\'error\': f\'Ошибка: {str(e)}\'}), 500')
                break
    
    # Записываем исправленный файл
    with open('app_sqlite.py', 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print("✅ Синтаксическая ошибка исправлена!")

if __name__ == "__main__":
    fix_syntax_error()

