import sqlite3
import os

def analyze_database():
    """Анализ структуры базы данных"""
    
    # Путь к базе данных
    db_path = os.path.join(os.path.dirname(__file__), 'sushi_express.db')
    
    if not os.path.exists(db_path):
        print("❌ База данных не найдена!")
        return
    
    print("🔍 АНАЛИЗ СТРУКТУРЫ БАЗЫ ДАННЫХ SUSHI EXPRESS")
    print("=" * 60)
    
    # Подключение к базе данных
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Получаем список всех таблиц
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    
    print(f"📊 НАЙДЕНО ТАБЛИЦ: {len(tables)}")
    print()
    
    # Анализируем каждую таблицу
    for table_name, in tables:
        print(f"🗂️  ТАБЛИЦА: {table_name.upper()}")
        print("-" * 40)
        
        # Получаем структуру таблицы
        cursor.execute(f"PRAGMA table_info({table_name});")
        columns = cursor.fetchall()
        
        print("📋 ПОЛЯ:")
        for col in columns:
            col_id, name, data_type, not_null, default_val, pk = col
            pk_mark = " 🔑" if pk else ""
            not_null_mark = " ⚠️" if not_null else ""
            default_mark = f" (по умолчанию: {default_val})" if default_val else ""
            print(f"   • {name} ({data_type}){pk_mark}{not_null_mark}{default_mark}")
        
        # Получаем количество записей
        cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
        count = cursor.fetchone()[0]
        print(f"📈 ЗАПИСЕЙ: {count}")
        
        # Получаем индексы
        cursor.execute(f"PRAGMA index_list({table_name});")
        indexes = cursor.fetchall()
        if indexes:
            print("🔍 ИНДЕКСЫ:")
            for idx in indexes:
                print(f"   • {idx[1]}")
        
        # Получаем внешние ключи
        cursor.execute(f"PRAGMA foreign_key_list({table_name});")
        foreign_keys = cursor.fetchall()
        if foreign_keys:
            print("🔗 ВНЕШНИЕ КЛЮЧИ:")
            for fk in foreign_keys:
                print(f"   • {fk[3]} → {fk[2]}.{fk[4]}")
        
        print()
    
    # Анализ связей между таблицами
    print("🔗 АНАЛИЗ СВЯЗЕЙ МЕЖДУ ТАБЛИЦАМИ")
    print("=" * 60)
    
    # Связи из foreign keys
    relationships = {}
    for table_name, in tables:
        cursor.execute(f"PRAGMA foreign_key_list({table_name});")
        fks = cursor.fetchall()
        if fks:
            relationships[table_name] = []
            for fk in fks:
                relationships[table_name].append({
                    'from_column': fk[3],
                    'to_table': fk[2],
                    'to_column': fk[4]
                })
    
    for table, rels in relationships.items():
        print(f"📊 {table.upper()}:")
        for rel in rels:
            print(f"   {rel['from_column']} → {rel['to_table']}.{rel['to_column']}")
        print()
    
    # Статистика по данным
    print("📊 СТАТИСТИКА ДАННЫХ")
    print("=" * 60)
    
    for table_name, in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
        count = cursor.fetchone()[0]
        
        if count > 0:
            print(f"📈 {table_name}: {count} записей")
            
            # Показываем примеры данных для основных таблиц
            if table_name in ['users', 'rolls', 'sets', 'ingredients', 'other_items']:
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 3;")
                sample_data = cursor.fetchall()
                
                # Получаем названия колонок
                cursor.execute(f"PRAGMA table_info({table_name});")
                columns_info = cursor.fetchall()
                column_names = [col[1] for col in columns_info]
                
                print("   Примеры данных:")
                for i, row in enumerate(sample_data, 1):
                    print(f"   {i}. ", end="")
                    for j, value in enumerate(row):
                        if j < len(column_names):
                            print(f"{column_names[j]}: {value}", end=", " if j < len(row)-1 else "")
                    print()
        else:
            print(f"📈 {table_name}: 0 записей")
        print()
    
    conn.close()
    
    print("✅ Анализ завершен!")

if __name__ == "__main__":
    analyze_database()
