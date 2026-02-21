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

papers.sort(key=lambda x: (int(x["year"]), x["slug"]), reverse=True)
published = [p for p in papers if p.get("status") == "published"]

def nav_block(base, active, code_url):
    def cls(name):
        return "nav-link active" if name == active else "nav-link"
    return f'''<nav class="navbar navbar-expand-lg navbar-light navbar-doc">
  <div class="container">
    <a class="navbar-brand" href="{base}/">CARD</a>
    <ul class="navbar-nav ml-auto">
      <li class="nav-item"><a class="{cls('about')}" href="{base}/documentation/01_About.html">About</a></li>
      <li class="nav-item"><a class="{cls('data')}" href="{base}/documentation/03_data.html">Data Input</a></li>
      <li class="nav-item"><a class="{cls('example')}" href="{base}/documentation/04_CARD_Example.html">Example Analysis</a></li>
      <li class="nav-item"><a class="{cls('exp')}" href="{base}/documentation/05_Experiments.html">Experiments</a></li>
      <li class="nav-item"><a class="{cls('install')}" href="{base}/documentation/02_installation.html">Installation</a></li>
      <li class="nav-item"><a class="nav-link" target="_blank" rel="noreferrer" href="{html.escape(code_url)}">GitHub</a></li>
    </ul>
  </div>
</nav>'''

def page_shell(title, css_path, nav_html, body_html, js_path):
    return f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{title}</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.4.1/css/bootstrap.min.css" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/css/all.min.css" />
  <link rel="stylesheet" href="{css_path}" />
</head>
<body>
{nav_html}
<main class="doc-wrap">
{body_html}
</main>
<script src="{js_path}"></script>
</body>
</html>
'''

for p in papers:
    slug = p["slug"]
    base = f"/code/{slug}"
    paper_dir = root / slug
    doc_dir = paper_dir / "documentation"
    paper_dir.mkdir(parents=True, exist_ok=True)
    doc_dir.mkdir(parents=True, exist_ok=True)

    title = html.escape(p["title"])
    venue = html.escape(p["venue"])
    authors = html.escape(p["authors"])
    summary = html.escape(p["summary_cn"])
    code_url = p.get("code_url") or "https://github.com/kaizheng-academic"
    paper_url = p.get("paper_url") or ""
    data_url = p.get("data_url") or ""
    bibtex = html.escape(p.get("bibtex") or "")
    kws = p.get("keywords") or []

    keywords_html = " ".join([f"<span class='badge'>{html.escape(k)}</span>" for k in kws]) if kws else "<span class='badge'>N/A</span>"
    resource_buttons = [f"<a class='btn' href='{html.escape(code_url)}' target='_blank' rel='noreferrer'>GitHub</a>"]
    if paper_url:
        resource_buttons.append(f"<a class='btn' href='{html.escape(paper_url)}' target='_blank' rel='noreferrer'>Paper</a>")
    if data_url:
        resource_buttons.append(f"<a class='btn' href='{html.escape(data_url)}' target='_blank' rel='noreferrer'>Data</a>")
    resources = "\n            ".join(resource_buttons)

    overview_body = f'''  <section class="doc-card">
    <h1 class="doc-title">CARD Overview</h1>
    <p class="doc-muted">{title}</p>
    <div class="doc-hero">Overview Figure Placeholder</div>
    <div class="doc-section">
      <h2>{venue} · {int(p['year'])}</h2>
      <p><strong>Authors:</strong> {authors}</p>
      <p>{summary}</p>
      <p>Example Analysis with CARD: <a href="{base}/documentation/04_CARD_Example.html">here</a>.</p>
    </div>
  </section>'''

    about_body = f'''  <section class="doc-card">
    <h1 class="doc-title">About</h1>
    <p class="doc-muted">Paper-specific CARD-style documentation.</p>
    <div class="doc-section">
      <p><strong>Title:</strong> {title}</p>
      <p><strong>Venue:</strong> {venue} ({int(p['year'])})</p>
      <p><strong>Authors:</strong> {authors}</p>
      <p>{summary}</p>
      <div class="badges">{keywords_html}</div>
    </div>
  </section>'''

    install_body = f'''  <section class="doc-card">
    <h1 class="doc-title">Installation</h1>
    <div class="doc-section">
      <pre><code>git clone {html.escape(code_url)}
cd $(basename {html.escape(code_url)})
# install dependencies according to project README</code></pre>
      <p class="doc-muted">Use the repository README as source of truth for environment details.</p>
    </div>
  </section>'''

    data_body = f'''  <section class="doc-card">
    <h1 class="doc-title">Data Input</h1>
    <div class="doc-section">
      <p>Describe expected input format, preprocessing, and output artifacts for this paper here.</p>
      <p><strong>Data Link:</strong> {('<a href="'+html.escape(data_url)+'" target="_blank" rel="noreferrer">Open</a>') if data_url else 'N/A'}</p>
    </div>
  </section>'''

    example_body = f'''  <section class="doc-card">
    <h1 class="doc-title">Example Analysis</h1>
    <div class="doc-section">
      <div class="paper-item">
        <h5>{title}</h5>
        <p class="paper-meta">{venue} · {int(p['year'])}</p>
        <p>{summary}</p>
        <div class="actions">
          {resources}
        </div>
      </div>
      <div class="paper-item">
        <h5>BibTeX</h5>
        <pre><code>{bibtex}</code></pre>
      </div>
    </div>
  </section>'''

    exp_body = f'''  <section class="doc-card">
    <h1 class="doc-title">Experiments</h1>
    <div class="doc-section">
      <p>Summarize experiment setup, metrics, and ablation results for <strong>{title}</strong>.</p>
      <ul>
        <li>Environment and dependencies</li>
        <li>Training configuration and random seeds</li>
        <li>Evaluation metrics and comparison baselines</li>
      </ul>
    </div>
  </section>'''

    (paper_dir / "index.html").write_text(page_shell("CARD Overview", "../assets/css/styles.css", nav_block(base, '', code_url), overview_body, "../assets/js/docs.js"), encoding="utf-8")
    (doc_dir / "01_About.html").write_text(page_shell("About", "../../assets/css/styles.css", nav_block(base, 'about', code_url), about_body, "../../assets/js/docs.js"), encoding="utf-8")
    (doc_dir / "02_installation.html").write_text(page_shell("Installation", "../../assets/css/styles.css", nav_block(base, 'install', code_url), install_body, "../../assets/js/docs.js"), encoding="utf-8")
    (doc_dir / "03_data.html").write_text(page_shell("Data Input", "../../assets/css/styles.css", nav_block(base, 'data', code_url), data_body, "../../assets/js/docs.js"), encoding="utf-8")
    (doc_dir / "04_CARD_Example.html").write_text(page_shell("Example Analysis", "../../assets/css/styles.css", nav_block(base, 'example', code_url), example_body, "../../assets/js/docs.js"), encoding="utf-8")
    (doc_dir / "05_Experiments.html").write_text(page_shell("Experiments", "../../assets/css/styles.css", nav_block(base, 'exp', code_url), exp_body, "../../assets/js/docs.js"), encoding="utf-8")

cards = []
for p in published:
    cards.append(f'''<article class="paper-item">
      <h5><a href="/code/{html.escape(p['slug'])}/">{html.escape(p['title'])}</a></h5>
      <p class="paper-meta">{html.escape(p['venue'])} · {int(p['year'])}</p>
      <p>{html.escape(p['summary_cn'])}</p>
    </article>''')

index_html = f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>CARD Overview</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.4.1/css/bootstrap.min.css" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/css/all.min.css" />
  <link rel="stylesheet" href="/code/assets/css/styles.css" />
</head>
<body>
  <nav class="navbar navbar-expand-lg navbar-light navbar-doc">
    <div class="container">
      <a class="navbar-brand" href="/code/">CARD</a>
      <ul class="navbar-nav ml-auto">
        <li class="nav-item"><a class="nav-link" href="https://github.com/kaizheng-academic" target="_blank" rel="noreferrer">GitHub</a></li>
      </ul>
    </div>
  </nav>
  <main class="doc-wrap">
    <section class="doc-card">
      <h1 class="doc-title">CARD Overview</h1>
      <p class="doc-muted">Each article under <code>/code/&lt;slug&gt;/</code> is an independent CARD-style mini-site.</p>
      <div class="doc-section">
        {''.join(cards) if cards else '<p class="doc-muted">No published papers yet.</p>'}
      </div>
    </section>
  </main>
  <script src="/code/assets/js/docs.js"></script>
</body>
</html>'''
index_path.write_text(index_html, encoding="utf-8")

print(f"已生成每篇论文CARD站点，共 {len(papers)} 篇")
print(f"已生成入口: {index_path}")
for p in published:
    print(f"- /code/{p['slug']}/")
PY
