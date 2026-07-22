import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Get user text messages from history_fts
c.execute("""
    SELECT body, time_created, tool_name
    FROM history_fts
    WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260'
      AND kind = 'user_text'
    ORDER BY time_created
""")
print("=== User text messages in history_fts ===")
for r in c.fetchall():
    print(f"  [{r[1]}] {r[0][:500]}")
    print()

# Also get assistant text to find decisions
c.execute("""
    SELECT body, time_created
    FROM history_fts
    WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260'
      AND kind = 'assistant_text'
    ORDER BY time_created
""")
print("\n=== Assistant text messages in history_fts ===")
for r in c.fetchall():
    print(f"  [{r[1]}] {r[0][:500]}")
    print()

conn.close()
