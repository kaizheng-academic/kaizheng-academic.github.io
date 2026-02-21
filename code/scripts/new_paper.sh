#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "用法: ./code/scripts/new_paper.sh <slug> <title> <venue> <year>"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SLUG="$1"
TITLE="$2"
VENUE="$3"
YEAR="$4"

python3 - "$ROOT" "$SLUG" "$TITLE" "$VENUE" "$YEAR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
slug, title, venue, year = sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
json_path = root / "data" / "papers.json"
papers = json.loads(json_path.read_text(encoding="utf-8"))

if any(p.get("slug") == slug for p in papers):
    raise SystemExit(f"错误: slug 已存在: {slug}")

entry = {
    "slug": slug,
    "title": title,
    "venue": venue,
    "year": year,
    "authors": "",
    "summary_cn": "Please add summary.",
    "keywords": [],
    "code_url": "https://github.com/kaizheng-academic",
    "paper_url": "",
    "data_url": "",
    "bibtex": "",
    "status": "draft"
}
papers.append(entry)
json_path.write_text(json.dumps(papers, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"已追加元数据: {json_path}")
print("下一步: 编辑该条目并将 status 改为 published，再运行 ./code/scripts/build_index.sh")
PY

./code/scripts/build_index.sh
