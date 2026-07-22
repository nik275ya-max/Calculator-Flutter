import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Search for user messages with key terms in calculator project
keywords = ['всегда', 'никогда', 'запомни', 'правило', 'решили', 'решение', 'decision', 'always', 'never', 'remember', 'rule', 'workflow', 'повторять', 'каждый раз']

for kw in keywords:
    c.execute("""
        SELECT m.id, m.session_id, substr(json_extract(m.data, '$.content'), 1, 300) as content
        FROM message m
        JOIN part p ON p.message_id = m.id
        WHERE m.session_id IN (SELECT id FROM session WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260')
          AND json_extract(m.data, '$.role') = 'user'
          AND (json_extract(p.data, '$.text') LIKE '%' || ? || '%'
               OR json_extract(m.data, '$.content') LIKE '%' || ? || '%')
        ORDER BY m.time_created
        LIMIT 5
    """, (kw, kw))
    results = c.fetchall()
    if results:
        print(f"\n=== Keyword '{kw}' ===")
        for r in results:
            content = r[2] if r[2] else ""
            # Try to get text from part
            c2 = conn.cursor()
            c2.execute("""
                SELECT json_extract(data, '$.text') FROM part
                WHERE message_id = ? AND json_extract(data, '$.type') = 'text'
                LIMIT 1
            """, (r[0],))
            part_text = c2.fetchone()
            if part_text and part_text[0]:
                content = part_text[0][:300]
            print(f"  [{r[0]}] session={r[1][:30]}...")
            print(f"    {content[:250]}")
            print()

conn.close()
