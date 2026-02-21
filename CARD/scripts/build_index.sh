#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
json_path = root / "data" / "papers.json"
index_path = root / "index.html"

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
    page = root / "papers" / slug / "index.html"
    if not page.exists():
        raise SystemExit(f"错误: 页面不存在: {page}")

published = [p for p in papers if p.get("status") == "published"]
published.sort(key=lambda x: (int(x["year"]), x["slug"]), reverse=True)

cards = []
for p in published:
    cards.append(f'''<article class="paper-card">\n  <h3>{p["title"]}</h3>\n  <p class="paper-meta">{p["venue"]} · {p["year"]}</p>\n  <p class="paper-summary">{p["summary_cn"]}</p>\n  <div class="actions">\n    <a class="btn" href="./papers/{p["slug"]}/">进入页面</a>\n  </div>\n</article>''')

html = f'''<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>郑凯 - 论文主页入口</title>
  <meta name="description" content="CARD论文页面自动索引" />
  <link rel="stylesheet" href="./assets/card.css" />
</head>
<body>
  <main class="wrap">
    <section class="hero">
      <h1>论文主页入口（按论文分文件夹）</h1>
      <p class="subtitle">每篇论文一个独立目录，统一模板，代码通过 GitHub 链接维护。</p>
      <p class="note">当前已发布：{len(published)} 篇</p>
    </section>

    <section class="section">
      <h2>论文列表</h2>
      <div class="paper-list">
        {"\n        ".join(cards) if cards else '<p class="note">暂无已发布论文。</p>'}
      </div>
    </section>
  </main>

  <script src="./assets/card.js"></script>
</body>
</html>
'''

index_path.write_text(html, encoding="utf-8")
print(f"已生成: {index_path}")
print(f"已发布论文数: {len(published)}")
PY
