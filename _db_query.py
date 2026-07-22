import sqlite3
conn = sqlite3.connect(r'C:\Users\User\.local\share\mimocode\mimocode.db')
c = conn.cursor()

print("=== TABLES ===")
c.execute("SELECT name, sql FROM sqlite_master WHERE type='table'")
for r in c.fetchall():
    print(r[0])
    print(r[1])
    print()

print("=== PROJECTS ===")
c.execute("SELECT * FROM project LIMIT 20")
cols = [d[0] for d in c.description]
print("Columns:", cols)
for r in c.fetchall():
    print(r)

print("\n=== SESSIONS (recent) ===")
c.execute("SELECT * FROM session ORDER BY rowid DESC LIMIT 20")
cols = [d[0] for d in c.description]
print("Columns:", cols)
for r in c.fetchall():
    print(r)

conn.close()
