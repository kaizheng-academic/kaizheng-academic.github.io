#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import pathlib
import html
import sys

root = pathlib.Path(sys.argv[1])
json_path = root / "data" / "papers.json"
index_path = root / "index.html"
example_path = root / "documentation" / "04_CARD_Example.html"

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

def nav_block(active):
    def cls(name):
        return "nav-link active" if name == active else "nav-link"
    return f'''<nav class="navbar navbar-expand-lg navbar-light navbar-doc">
    <div class="container">
      <a class="navbar-brand" href="/code/">CARD</a>
      <ul class="navbar-nav ml-auto">
        <li class="nav-item"><a class="{cls('about')}" data-nav href="/code/documentation/01_About.html">About</a></li>
        <li class="nav-item"><a class="{cls('data')}" data-nav href="/code/documentation/03_data.html">Data Input</a></li>
        <li class="nav-item"><a class="{cls('example')}" data-nav href="/code/documentation/04_CARD_Example.html">Example Analysis</a></li>
        <li class="nav-item"><a class="{cls('exp')}" data-nav href="/code/documentation/05_Experiments.html">Experiments</a></li>
        <li class="nav-item"><a class="{cls('install')}" data-nav href="/code/documentation/02_installation.html">Installation</a></li>
        <li class="nav-item"><a class="nav-link" target="_blank" rel="noreferrer" href="https://github.com/kaizheng-academic">GitHub</a></li>
      </ul>
    </div>
  </nav>'''

cards = []
for p in published:
    title = html.escape(p["title"])
    venue = html.escape(p["venue"])
    summary = html.escape(p["summary_cn"])
    slug = html.escape(p["slug"])
    year = int(p["year"])
    cards.append(f'''<article class="paper-item">
        <h5><a href="/code/{slug}/">{title}</a></h5>
        <p class="paper-meta">{venue} · {year}</p>
        <p>{summary}</p>
      </article>''')

cards_html = "\n      ".join(cards) if cards else '<p class="doc-muted">No published papers yet.</p>'

overview_html = f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>CARD Overview</title>
  <meta name="description" content="Paper documentation site" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.4.1/css/bootstrap.min.css" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/css/all.min.css" />
  <link rel="stylesheet" href="/code/assets/css/styles.css" />
</head>
<body>
  {nav_block('')}
  <main class="doc-wrap">
    <section class="doc-card">
      <h1 class="doc-title">CARD Overview</h1>
      <p class="doc-muted">Structured paper documentation portal with independent article pages and reproducible resources.</p>
      <div class="doc-hero">Overview Figure Placeholder</div>
      <div class="doc-section">
        <h2>CARD Overview</h2>
        <p>Each paper is hosted at an independent URL under <code>/code/&lt;slug&gt;/</code> while this documentation layer provides organized navigation and examples.</p>
        <p>Example Analysis with CARD: <a href="/code/documentation/04_CARD_Example.html">here</a>.</p>
      </div>
    </section>
  </main>
  <script src="/code/assets/js/docs.js"></script>
</body>
</html>
'''

example_html = f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Example Analysis</title>
  <meta name="description" content="Example analysis pages" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.4.1/css/bootstrap.min.css" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/css/all.min.css" />
  <link rel="stylesheet" href="/code/assets/css/styles.css" />
</head>
<body>
  {nav_block('example')}
  <main class="doc-wrap">
    <section class="doc-card">
      <h1 class="doc-title">Example Analysis</h1>
      <p class="doc-muted">Published paper pages generated from <code>data/papers.json</code> (status = published).</p>
      <div class="doc-section">
        {cards_html}
      </div>
    </section>
  </main>
  <script src="/code/assets/js/docs.js"></script>
</body>
</html>
'''

index_path.write_text(overview_html, encoding="utf-8")
example_path.write_text(example_html, encoding="utf-8")

print(f"已生成: {index_path}")
print(f"已生成: {example_path}")
print("校验通过。已发布论文直链：")
for p in published:
    print(f"- /code/{p['slug']}/")
PY
