import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Get all user messages with their text parts from main calculator session
c.execute("""
    SELECT m.id, json_extract(m.data, '$.content') as content, m.time_created
    FROM message m
    WHERE m.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
      AND json_extract(m.data, '$.role') = 'user'
    ORDER BY m.time_created
""")
print("=== User messages with parts ===")
for r in c.fetchall():
    msg_id = r[0]
    content = r[1] if r[1] else ""
    
    # Get text parts
    c2 = conn.cursor()
    c2.execute("""
        SELECT json_extract(data, '$.text') FROM part
        WHERE message_id = ? AND json_extract(data, '$.type') = 'text'
    """, (msg_id,))
    parts = c2.fetchall()
    
    if parts:
        for p in parts:
            if p[0] and not p[0].startswith('<system-reminder>'):
                print(f"  [{msg_id}] {p[0][:500]}")
                print()
    elif content and not content.startswith('<system-reminder>'):
        print(f"  [{msg_id}] {content[:500]}")
        print()

# Now look for the specific user request about text output toggle
print("\n=== Looking for text output toggle request ===")
c.execute("""
    SELECT m.id, json_extract(m.data, '$.content') as content, m.time_created
    FROM message m
    WHERE m.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
      AND json_extract(m.data, '$.role') = 'user'
      AND (json_extract(m.data, '$.content') LIKE '%текст%' 
           OR json_extract(m.data, '$.content') LIKE '%настройки%'
           OR json_extract(m.data, '$.content') LIKE '%маст%'
           OR json_extract(m.data, '$.content') LIKE '%переключатель%')
    ORDER BY m.time_created
""")
for r in c.fetchall():
    content = r[1] if r[1] else ""
    # Also check parts
    c2 = conn.cursor()
    c2.execute("""
        SELECT json_extract(data, '$.text') FROM part
        WHERE message_id = ? AND json_extract(data, '$.type') = 'text'
    """, (r[0],))
    parts = c2.fetchall()
    for p in parts:
        if p[0] and not p[0].startswith('<system-reminder>'):
            content = p[0]
    print(f"  [{r[0]}] {content[:600]}")
    print()

conn.close()
