import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Search for write/edit tool calls in calculator project sessions to see what was modified
c.execute("""
    SELECT p.message_id, json_extract(p.data, '$.tool') as tool,
           substr(json_extract(p.data, '$.state.input'), 1, 500) as input_preview
    FROM part p
    JOIN message m ON p.message_id = m.id
    WHERE m.session_id IN (SELECT id FROM session WHERE project_id = '39bfc8ed-14bb-4ce7-8fd4-da46d66da260')
      AND json_extract(p.data, '$.tool') IN ('write', 'edit')
      AND json_extract(p.data, '$.type') = 'tool'
    ORDER BY p.time_created
    LIMIT 30
""")
print("=== Write/Edit tool calls in calculator project ===")
for r in c.fetchall():
    tool = r[1]
    inp = r[2] if r[2] else ""
    # Parse the input JSON to get file path
    try:
        inp_data = json.loads(inp)
        file_path = inp_data.get('file_path', 'unknown')
        print(f"  {tool}: {file_path}")
    except:
        print(f"  {tool}: {inp[:200]}")

conn.close()
