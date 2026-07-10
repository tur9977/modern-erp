import re

with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/full_schema_dump.sql', 'r') as f:
    sql = f.read()

# We need to find all table names first to avoid matching generic words.
# "CREATE TABLE name ("
tables = re.findall(r'CREATE TABLE (\w+)', sql)
print(f"Found {len(tables)} tables: {tables}")

# Now replace every occurrence of these table names in specific SQL contexts
for table in tables:
    # CREATE TABLE table -> CREATE TABLE IF NOT EXISTS erp_table
    sql = re.sub(rf'CREATE TABLE {table}\b', f'CREATE TABLE IF NOT EXISTS erp_{table}', sql)
    # REFERENCES table -> REFERENCES erp_table
    sql = re.sub(rf'REFERENCES {table}\b', f'REFERENCES erp_{table}', sql)
    # ON table -> ON erp_table (for indexes)
    sql = re.sub(rf'ON {table}\b', f'ON erp_{table}', sql)
    # COMMENT ON COLUMN table. -> COMMENT ON COLUMN erp_table.
    sql = re.sub(rf'COMMENT ON COLUMN {table}\.', f'COMMENT ON COLUMN erp_{table}.', sql)

# Add ON CONFLICT DO NOTHING to INSERTs if there were any, but this is schema only.
# Since we created erp_items earlier and don't want to lose test data, we just run this script.
# IF NOT EXISTS will prevent overriding existing tables, but what about indexes?
# PostgreSQL will throw errors if indexes exist. We should add IF NOT EXISTS to indexes.
sql = re.sub(r'CREATE INDEX (\w+)', r'CREATE INDEX IF NOT EXISTS \1', sql)
sql = re.sub(r'CREATE UNIQUE INDEX (\w+)', r'CREATE UNIQUE INDEX IF NOT EXISTS \1', sql)

with open('/Users/nealmac/.gemini/antigravity-ide/scratch/modern-erp/prefixed_schema.sql', 'w') as f:
    f.write(sql)

print("Saved to prefixed_schema.sql")
