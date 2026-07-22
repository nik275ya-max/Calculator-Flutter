import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Get all user messages from the main session (ses_081c2205cffeRgTF7UTTMz5ZQQ)
# This is the primary calculator session
c.execute("""
    SELECT m.id, json_extract(m.data, '$.content') as content, m.time_created
    FROM message m
    WHERE m.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
      AND json_extract(m.data, '$.role') = 'user'
    ORDER BY m.time_created
""")
print("=== User messages in main calculator session ===")
for r in c.fetchall():
    msg_id = r[0]
    content = r[1] if r[1] else ""
    # Also check parts for text content
    c2 = conn.cursor()
    c2.execute("""
        SELECT json_extract(data, '$.text') FROM part
        WHERE message_id = ? AND json_extract(data, '$.type') = 'text'
        LIMIT 1
    """, (msg_id,))
    part_text = c2.fetchone()
    if part_text and part_text[0]:
        content = part_text[0][:400]
    elif content:
        content = content[:400]
    print(f"[{msg_id}] {content}")
    print()

conn.close()
