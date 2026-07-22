import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Search history_fts for user messages with rules/decisions
c.execute("""
    SELECT body, time_created
    FROM history_fts
    WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260'
      AND kind = 'user'
      AND (body LIKE '%всегда%' OR body LIKE '%никогда%' OR body LIKE '%запомни%'
           OR body LIKE '%решили%' OR body LIKE '%решение%'
           OR body LIKE '%нужно%' OR body LIKE '%хочу%' OR body LIKE '%делай%'
           OR body LIKE '%надо%' OR body LIKE '%только%')
    ORDER BY time_created
    LIMIT 20
""")
print("=== User statements with keywords in history_fts ===")
for r in c.fetchall():
    print(f"  [{r[1]}] {r[0][:300]}")
    print()

conn.close()
