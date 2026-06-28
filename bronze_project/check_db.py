import duckdb

paths = [
    'C:/Users/noorr/OneDrive/Documents/WHO/bronze_project/bronze.duckdb',
    'C:/Users/noorr/OneDrive/Documents/WHO/bronze_project/dev.duckdb'
]

for path in paths:
    print(f'\n=== {path} ===')
    con = duckdb.connect(path)
    tables = con.execute("""
        SELECT table_name, table_type 
        FROM information_schema.tables 
        WHERE table_schema='main' 
        ORDER BY table_type, table_name
    """).df()
    print(tables.to_string())
    con.close()