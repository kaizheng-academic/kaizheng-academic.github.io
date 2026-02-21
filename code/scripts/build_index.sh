#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
json_path = root / "data" / "papers.json"

papers = json.loads(json_path.read_text(encoding="utf-8"))
required = [
    "slug", "title", "venue", "year", "authors", "summary_cn",
    "keywords", "code_url", "paper_url", "data_url", "bibtex", "status"
]

seen = set()
for i, p in enumerate(papers, 1):
    missing = [k for k in required if k not in p]
    if missing:
        raise SystemExit(f"错误: 第 {i} 条缺少字段: {missing}")
    slug = p["slug"]
    if slug in seen:
        raise SystemExit(f"错误: slug 重复: {slug}")
    seen.add(slug)
    page = root / slug / "index.html"
    if not page.exists():
        raise SystemExit(f"错误: 页面不存在: {page}")

published = [p for p in papers if p.get("status") == "published"]
published.sort(key=lambda x: (int(x["year"]), x["slug"]), reverse=True)

print("校验通过。已发布论文直链：")
for p in published:
    print(f"- /code/{p['slug']}/")
PY
