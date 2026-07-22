import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Get the last few assistant messages in the session to see if the feature was completed
c.execute("""
    SELECT m.id, substr(json_extract(m.data, '$.content'), 1, 500) as content, m.time_created
    FROM message m
    WHERE m.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
      AND json_extract(m.data, '$.role') = 'assistant'
    ORDER BY m.time_created DESC
    LIMIT 10
""")
print("=== Last 10 assistant messages ===")
for r in c.fetchall():
    print(f"  [{r[0]}] time={r[2]}")
    # Get text parts
    c2 = conn.cursor()
    c2.execute("""
        SELECT json_extract(data, '$.text') FROM part
        WHERE message_id = ? AND json_extract(data, '$.type') = 'text'
    """, (r[0],))
    parts = c2.fetchall()
    for p in parts:
        if p[0] and len(p[0]) > 10:
            print(f"    {p[0][:400]}")
    print()

# Also check the user's last message and the plan approval
c.execute("""
    SELECT m.id, json_extract(m.data, '$.content') as content, m.time_created
    FROM message m
    WHERE m.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
      AND json_extract(m.data, '$.role') = 'user'
    ORDER BY m.time_created DESC
    LIMIT 5
""")
print("\n=== Last 5 user messages ===")
for r in c.fetchall():
    print(f"  [{r[0]}] time={r[2]}")
    content = r[1] if r[1] else ""
    if not content.startswith('<system'):
        print(f"    {content[:400]}")
    print()

conn.close()
