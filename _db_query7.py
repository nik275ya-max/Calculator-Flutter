import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Check history_fts for this project
c.execute("""
    SELECT kind, COUNT(*)
    FROM history_fts
    WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260'
    GROUP BY kind
""")
print("=== history_fts kinds for calculator project ===")
for r in c.fetchall():
    print(f"  {r[0]}: {r[1]}")

# Search for user statements
c.execute("""
    SELECT body, time_created
    FROM history_fts
    WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260'
      AND kind = 'user'
    ORDER BY time_created
    LIMIT 30
""")
print("\n=== User messages in history_fts ===")
for r in c.fetchall():
    print(f"  [{r[1]}] {r[0][:400]}")
    print()

conn.close()
