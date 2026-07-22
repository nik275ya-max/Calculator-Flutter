import sqlite3
import json

conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

# Check the text-output-toggle session (ses_081c2205cffeRgTF7UTTMz5ZQQ) for write/edit to source files
c.execute("""
    SELECT p.message_id, json_extract(p.data, '$.tool') as tool,
           substr(json_extract(p.data, '$.state.input'), 1, 800) as input_preview
    FROM part p
    WHERE p.session_id = 'ses_081c2205cffeRgTF7UTTMz5ZQQ'
      AND json_extract(p.data, '$.tool') IN ('write', 'edit')
      AND json_extract(p.data, '$.type') = 'tool'
      AND json_extract(p.data, '$.state.input') NOT LIKE '%checkpoint%'
      AND json_extract(p.data, '$.state.input') NOT LIKE '%MEMORY%'
      AND json_extract(p.data, '$.state.input') NOT LIKE '%notes%'
      AND json_extract(p.data, '$.state.input') NOT LIKE '%progress%'
    ORDER BY p.time_created
    LIMIT 30
""")
print("=== Source file writes/edits in calculator session ===")
for r in c.fetchall():
    tool = r[1]
    inp = r[2] if r[2] else ""
    try:
        inp_data = json.loads(inp)
        file_path = inp_data.get('file_path', 'unknown')
        print(f"  {tool}: {file_path}")
    except:
        print(f"  {tool}: {inp[:200]}")

conn.close()
