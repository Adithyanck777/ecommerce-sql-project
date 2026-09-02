import sqlite3, glob, os, re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
conn = sqlite3.connect(os.path.join(BASE, "db", "ecommerce.db"))
cur = conn.cursor()

files = sorted(glob.glob(os.path.join(BASE, "sql", "*.sql")))
for fp in files:
    name = os.path.basename(fp)
    if name.startswith("00_"):
        continue
    print(f"\n{'='*70}\n{name}\n{'='*70}")
    sql = open(fp).read()
    # strip full-line comments, then split on semicolons that end statements
    no_comments = "\n".join(l for l in sql.split("\n") if not l.strip().startswith("--"))
    statements = [s.strip() for s in no_comments.split(";") if s.strip()]
    for i, stmt in enumerate(statements):
        stmt_clean = stmt
        try:
            cur.execute(stmt_clean)
        except Exception as e:
            print(f"  [statement {i}] ERROR: {e}")
            continue
        if cur.description is None:
            continue
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print(f"  -- statement {i}: {len(rows)} rows")
        print("  " + " | ".join(cols))
        for r in rows[:8]:
            print("  " + " | ".join(str(x) for x in r))
        if len(rows) > 8:
            print(f"  ... ({len(rows)-8} more rows)")
