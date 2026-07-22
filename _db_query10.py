import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Check what the latest session (current dream session) has done
c.execute("""
    SELECT m.id, m.agent_id, json_extract(m.data, '$.role') as role, 
           substr(json_extract(m.data, '$.content'), 1, 200) as content,
           m.time_created
    FROM message m
    WHERE m.session_id = 'ses_07693251fffeLUTYFAWZ1iFF02'
    ORDER BY m.time_created
""")
print("=== Messages in current dream session ===")
for r in c.fetchall():
    print(f"  [{r[0]}] agent={r[1]} role={r[2]} time={r[4]}")
    if r[3] and not r[3].startswith('<system'):
        print(f"    {r[3][:200]}")
    print()

# Also check what happened in the user's text-output-toggle request (msg_f896cd6f2001)
# Find what assistant did in response
c.execute("""
    SELECT p.message_id, json_extract(p.data, '$.tool') as tool,
           substr(json_extract(p.data, '$.state.output'), 1, 500) as output_preview
    FROM part p
    WHERE p.message_id IN (
        SELECT id FROM message 
        WHERE session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
        AND time_created > 1784716295000
        AND json_extract(data, '$.role') = 'assistant'
    )
    AND json_extract(p.data, '$.type') = 'tool'
    ORDER BY p.time_created
    LIMIT 20
""")
print("\n=== Recent tool calls after text-output-toggle request ===")
for r in c.fetchall():
    print(f"  msg={r[0]} tool={r[1]} output={r[2][:300] if r[2] else 'None'}")
    print()

conn.close()
