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
template_path = root / "templates" / "paper.template.html"
page_dir = root / slug
page_path = page_dir / "index.html"

papers = json.loads(json_path.read_text(encoding="utf-8"))
if any(p.get("slug") == slug for p in papers):
    raise SystemExit(f"错误: slug 已存在: {slug}")

entry = {
    "slug": slug,
    "title": title,
    "venue": venue,
    "year": year,
    "authors": "",
    "summary_cn": "请补充中文摘要。",
    "keywords": [],
    "code_url": "https://github.com/kaizheng-academic",
    "paper_url": "",
    "data_url": "",
    "bibtex": "",
    "status": "draft"
}
papers.append(entry)
json_path.write_text(json.dumps(papers, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

page_dir.mkdir(parents=True, exist_ok=True)
keywords_badges = "<span class=\"badge\">待补充</span>"
paper_button = ""
data_button = ""
content = template_path.read_text(encoding="utf-8")
content = content.replace("__TITLE__", title)
content = content.replace("__VENUE__", venue)
content = content.replace("__YEAR__", str(year))
content = content.replace("__AUTHORS__", "待补充")
content = content.replace("__SUMMARY_CN__", "请补充中文摘要。")
content = content.replace("__CODE_URL__", "https://github.com/kaizheng-academic")
content = content.replace("__PAPER_BUTTON__", paper_button)
content = content.replace("__DATA_BUTTON__", data_button)
content = content.replace("__KEYWORDS_BADGES__", keywords_badges)
content = content.replace("__BIBTEX__", "")
page_path.write_text(content, encoding="utf-8")

print(f"已创建: {page_path}")
print(f"已更新: {json_path}")
print("下一步: 补全 papers.json 对应条目的 summary_cn/authors/keywords/链接，并将 status 改为 published")
PY
