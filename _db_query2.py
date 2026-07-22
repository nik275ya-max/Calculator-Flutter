import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Find sessions for calculator project
c.execute("SELECT id, slug, title, time_created, time_updated FROM session WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260' ORDER BY time_created DESC")
print("=== Calculator project sessions ===")
for r in c.fetchall():
    print(f"  {r[0]} | {r[1]} | {r[2]} | created={r[3]} updated={r[4]}")

# Check the parent session (ses_081c2205cffeRgTF7UTTMz5ZQQ) for messages
print("\n=== Messages in main session (ses_081c2205cffeRgTF7UTTMz5ZQQ) ===")
c.execute("""
    SELECT m.id, m.agent_id, json_extract(m.data, '$.role') as role, substr(json_extract(m.data, '$.content'), 1, 200) as content_preview
    FROM message m
    WHERE m.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
    ORDER BY m.time_created
""")
for r in c.fetchall():
    print(f"  {r[0]} | agent={r[1]} | role={r[2]} | {r[3][:150] if r[3] else 'None'}")

conn.close()
