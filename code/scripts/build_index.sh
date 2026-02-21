#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ONLY_SLUGS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      ONLY_SLUGS="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1"
      echo "Usage: ./code/scripts/build_index.sh [--only slug1,slug2,...]"
      exit 1
      ;;
  esac
done

python3 - "$ROOT" "$ONLY_SLUGS" <<'PY'
import html
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
only_raw = (sys.argv[2] or "").strip()
only = {s.strip() for s in only_raw.split(",") if s.strip()} if only_raw else set()

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

if only:
    unknown = sorted(list(only - seen))
    if unknown:
        raise SystemExit(f"错误: --only 中存在未知 slug: {unknown}")

papers.sort(key=lambda x: (int(x["year"]), x["slug"]), reverse=True)
published = [p for p in papers if p.get("status") == "published"]
selected = [p for p in papers if (not only or p["slug"] in only)]


def nav_html(base_prefix: str, active: str, repo_url: str):
    def li(name, href, text):
        cls = "nav-item active" if active == name else "nav-item "
        return f'''<li class="{cls}"><a class="nav-link" href="{href}">{text}</a></li>'''

    return f'''<header class="navbar navbar-expand-md navbar-custom" id="top">
  <div class="container">
    <a class="navbar-brand" href="{base_prefix}/">TRACE</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span>
    </button>
    <nav class="navbar-collapse collapse" role="navigation" id="navbarSupportedContent">
      <ul class="navbar-nav">
        {li('about', f'{base_prefix}/documentation/01_About.html', 'About')}
        {li('data', f'{base_prefix}/documentation/03_data.html', 'Data Input')}
        {li('example', f'{base_prefix}/documentation/04_CARD_Example.html', 'Example Analysis')}
        {li('exp', f'{base_prefix}/documentation/05_Experiments.html', 'Experiments')}
        {li('install', f'{base_prefix}/documentation/02_installation.html', 'Installation')}
      </ul>
      <ul class="navbar-nav ml-auto">
        <li class="nav-item "><a class="nav-link" href="{html.escape(repo_url)}"><i class="fab fa-github fa-fw " aria-hidden="true"></i> GitHub</a></li>
      </ul>
    </nav>
  </div>
</header>'''


def scripts_tail(asset_prefix: str):
    return f'''<!-- Bootstrap Related Dependencies -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.slim.js" integrity="sha256-BTlTdQO9/fascB1drekrDVkaKd9PkwBymMlHOiG+qLI=" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js" integrity="sha256-/ijcOLwFf26xEYAjW75FizKVo5tnTYiQddPZoLUHHZ8=" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha256-WqU1JavFxSAMcLP2WIOI+GB2zWmShMI82mTpLDcqFUg=" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.4.11/d3.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/trianglify/0.1.2/trianglify.min.js"></script>
<script>
  let uiColors = [];
  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {{
    uiColors = ["#062a48", "#304e67"];
  }} else {{
    uiColors = ["#080331", "#673051"];
  }}
</script>
<script src="{asset_prefix}/assets/js/docs.js"></script>'''


def footer_html(repo_url: str):
    return f'''<footer class="site-footer border-top mt-5 py-5 text-center" role="contentinfo">
  <div class="container">
    <div class="site-footer__social-links mb-4">
      <a class="github-button" href="{html.escape(repo_url)}" data-size="large" data-show-count="true" aria-label="Star repo">Star</a>
      <a class="github-button" href="{html.escape(repo_url)}/issues" data-icon="octicon-issue-opened" data-size="large" data-show-count="true" aria-label="Issue repo">Issue</a>
    </div>
    <div class="site-footer__info">
      <h2 class="h4 mb-1">TRACE</h2>
      <p class="mb-0">Code released under GNU License 3.0.</p>
    </div>
    <div class="site-footer__summary mt-3">
      <p class="mb-0">Documentation template by <a href="http://getbootstrap.com">Bootstrap team</a>, generated with <a href="https://github.com/allejo/jekyll-docs-theme">Jekyll Docs Theme</a></p>
    </div>
    <div id="disqus_thread"></div>
    <script>
      var disqus_config = function () {{
        this.page.url = window.location.href;
        this.page.identifier = window.location.pathname;
      }};
      (function() {{
        var d = document, s = d.createElement('script');
        s.src = 'https://.disqus.com/embed.js';
        s.setAttribute('data-timestamp', +new Date());
        (d.head || d.body).appendChild(s);
      }})();
    </script>
    <noscript>Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript" rel="nofollow">comments powered by Disqus.</a></noscript>
  </div>
</footer>'''


def shell(title: str, desc: str, canonical: str, body_class: str, nav: str, masthead_title: str, masthead_desc: str, main_html: str, toc_html: str, asset_prefix: str, repo_url: str, full_layout=False):
    if full_layout:
        content = f'''<div class="container"><main class="layout-full__main scope-markdown">{main_html}</main></div>'''
    else:
        content = f'''<div class="container"><div class="row"><main class="col-md-9 layout-page__main"><section class="mobile-toc border mb-3 p-3 d-md-none"><div class="d-flex align-items-center"><h2 class="mb-0">Table of Contents</h2><button class="js-only ml-2 toggle-toc" aria-controls="mobileTOC" aria-label="Toggle table of contents" aria-expanded="true"><span aria-hidden="true" data-role="toggle">Hide</span></button></div>{toc_html}</section><section class="scope-markdown">{main_html}</section></main><div class="col-md-3 d-none d-md-block"><aside id="page-toc" class="page-sidebar"><ul class="nav bs-docs-sidenav">{toc_html}</ul></aside></div></div></div>'''

    masthead_extra = ''
    if full_layout:
        masthead_extra = f'''<div class="mt-4 mb-0"><a href="{html.escape(repo_url)}" class="site-masthead__button mx-2 mb-2"><i class="fas fa-download fa-fw mr-1" aria-hidden="true"></i>Download</a><a href="{html.escape(repo_url)}" class="site-masthead__button mx-2 mb-2"><i class="fab fa-github fa-fw mr-1" aria-hidden="true"></i>View on GitHub</a></div><p class="site-masthead__version my-0">Latest release v1.0.0</p>'''

    return f'''<!DOCTYPE html>
<html lang="en" class="no-js">
<head>
<meta charset="utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(desc)}">
<link rel="canonical" href="{html.escape(canonical)}">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha256-L/W5Wfqfa0sdBNIKN9cG6QA5F2qx4qICmU2VgLruv9Y=" crossorigin="anonymous"/>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/css/all.min.css" integrity="sha256-mmgLkCYLUQbXn0B1SRqzHar6dCnv9oZFPEC1g1cwlkk=" crossorigin="anonymous"/>
<link rel="stylesheet" href="{asset_prefix}/assets/css/styles.css"/>
</head>
<body class="{body_class}" data-spy="scroll" data-target="#page-toc" data-offset="0">
{nav}
<div class="site-masthead mb-5 py-5 {'text-center' if full_layout else 'text-left'}"><div class="container"><h1 class="site-masthead__title mb-1">{html.escape(masthead_title)}</h1>{f'<p class="site-masthead__description mb-0">{html.escape(masthead_desc)}</p>' if masthead_desc else ''}{masthead_extra}</div></div>
{content}
{footer_html(repo_url)}
{scripts_tail(asset_prefix)}
</body>
</html>'''


def toc(items):
    if not items:
        return '<ul id="mobileTOC" class="js-toc mb-0 mt-2"></ul>'
    lis = ''.join([f'<li><a href="#{k}">{v}</a></li>' for k, v in items])
    return f'<ul id="mobileTOC" class="js-toc mb-0 mt-2">{lis}</ul>'


for p in selected:
    slug = p["slug"]
    title = p["title"]
    venue = p["venue"]
    year = int(p["year"])
    authors = p["authors"]
    summary = p["summary_cn"]
    code_url = p.get("code_url") or "https://github.com/kaizheng-academic"
    paper_url = p.get("paper_url") or ""
    data_url = p.get("data_url") or ""
    bibtex = p.get("bibtex") or ""
    keywords = p.get("keywords") or []

    base = f"/code/{slug}"
    paper_dir = root / slug
    doc_dir = paper_dir / "documentation"
    paper_dir.mkdir(parents=True, exist_ok=True)
    doc_dir.mkdir(parents=True, exist_ok=True)

    about_toc = toc([
        ("paper-overview", "Paper Overview"),
        ("keywords", "Keywords"),
        ("contact", "Contact"),
    ])
    about_main = f'''<h2 id="paper-overview">Paper Overview</h2>
<p><strong>Title:</strong> {html.escape(title)}</p>
<p><strong>Venue:</strong> {html.escape(venue)} ({year})</p>
<p><strong>Authors:</strong> {html.escape(authors)}</p>
<p>{html.escape(summary)}</p>
<h2 id="keywords">Keywords</h2>
<ul>{''.join([f'<li>{html.escape(k)}</li>' for k in keywords]) if keywords else '<li>N/A</li>'}</ul>
<h2 id="contact">Contact</h2>
<p>For questions or collaboration, please open an issue in the GitHub repository.</p>'''

    install_toc = toc([
        ("requirements", "Requirements"),
        ("installation", "Installation"),
        ("quickstart", "Quickstart"),
    ])
    install_main = f'''<h2 id="requirements">Requirements</h2>
<ul><li>Linux/macOS</li><li>Python 3.9+</li><li>CUDA optional</li></ul>
<h2 id="installation">Installation</h2>
<div class="highlight"><pre class="highlight"><code>git clone {html.escape(code_url)}
cd $(basename {html.escape(code_url)})
# install dependencies according to README</code></pre></div>
<h2 id="quickstart">Quickstart</h2>
<p>Follow the repository README to reproduce results and run demos.</p>'''

    data_toc = toc([
        ("required-input-data", "Required input data"),
        ("data-format", "Data format"),
        ("output", "Output"),
    ])
    data_main = f'''<h2 id="required-input-data">Required input data</h2>
<ul><li>Primary dataset files</li><li>Metadata and split definitions</li></ul>
<h2 id="data-format">Data format</h2>
<p>Document expected schema, preprocessing steps, and validation checks.</p>
<h2 id="output">Output</h2>
<p>Model artifacts, metrics reports, and inference results.</p>
<p><strong>Data link:</strong> {f'<a href="{html.escape(data_url)}">Open</a>' if data_url else 'N/A'}</p>'''

    example_toc = toc([
        ("example-analysis", "Example Analysis"),
        ("resources", "Resources"),
        ("citation", "Citation"),
    ])
    resources = [f'<a href="{html.escape(code_url)}" class="site-masthead__button mx-2 mb-2"><i class="fab fa-github fa-fw mr-1" aria-hidden="true"></i>GitHub</a>']
    if paper_url:
        resources.append(f'<a href="{html.escape(paper_url)}" class="site-masthead__button mx-2 mb-2"><i class="fas fa-file-alt fa-fw mr-1" aria-hidden="true"></i>Paper</a>')
    if data_url:
        resources.append(f'<a href="{html.escape(data_url)}" class="site-masthead__button mx-2 mb-2"><i class="fas fa-database fa-fw mr-1" aria-hidden="true"></i>Data</a>')

    example_main = f'''<h2 id="example-analysis">Example Analysis</h2>
<p>This page shows a TRACE-style example analysis workflow for <strong>{html.escape(title)}</strong>.</p>
<p><img src="/code/assets/images/example-placeholder-01.png" alt="example-1" /></p>
<p><img src="/code/assets/images/example-placeholder-02.png" alt="example-2" /></p>
<p><img src="/code/assets/images/example-placeholder-03.png" alt="example-3" /></p>
<p><img src="/code/assets/images/example-placeholder-04.png" alt="example-4" /></p>
<h2 id="resources">Resources</h2>
<p>{''.join(resources)}</p>
<h2 id="citation">Citation</h2>
<div class="highlight"><pre class="highlight"><code>{html.escape(bibtex)}</code></pre></div>'''

    exp_toc = toc([
        ("experimental-setup", "Experimental setup"),
        ("metrics", "Metrics"),
        ("reproducibility", "Reproducibility"),
    ])
    exp_main = f'''<h2 id="experimental-setup">Experimental setup</h2>
<ul><li>Model and baseline configuration</li><li>Hardware and runtime environment</li></ul>
<h2 id="metrics">Metrics</h2>
<p>Report key metrics and compare with strong baselines.</p>
<h2 id="reproducibility">Reproducibility</h2>
<p>Provide seed settings and scripts to fully reproduce results.</p>'''

    overview_main = f'''<h2>Overview</h2>
<p><strong>{html.escape(title)}</strong></p>
<p>{html.escape(venue)} ({year})</p>
<p>{html.escape(summary)}</p>
<p><img src="/code/assets/images/overview-placeholder.jpg" alt="overview" /></p>
<p>Example Analysis with TRACE: <a href="{base}/documentation/04_CARD_Example.html">here</a>.</p>'''

    files = {
        paper_dir / "index.html": shell("TRACE Overview", summary, f"https://kaizheng-academic.github.io{base}/", "layout-full", nav_html(base, "", code_url), "TRACE Overview", f"{venue}", overview_main, "", "/code", code_url, full_layout=True),
        doc_dir / "01_About.html": shell("About", "", f"https://kaizheng-academic.github.io{base}/documentation/01_About.html", "layout-page", nav_html(base, "about", code_url), "About", "", about_main, about_toc, "/code", code_url, full_layout=False),
        doc_dir / "02_installation.html": shell("Installation", "", f"https://kaizheng-academic.github.io{base}/documentation/02_installation.html", "layout-page", nav_html(base, "install", code_url), "Installation", "", install_main, install_toc, "/code", code_url, full_layout=False),
        doc_dir / "03_data.html": shell("Data Input", "", f"https://kaizheng-academic.github.io{base}/documentation/03_data.html", "layout-page", nav_html(base, "data", code_url), "Data Input", "", data_main, data_toc, "/code", code_url, full_layout=False),
        doc_dir / "04_CARD_Example.html": shell("Example Analysis", "", f"https://kaizheng-academic.github.io{base}/documentation/04_CARD_Example.html", "layout-page", nav_html(base, "example", code_url), "Example Analysis", "", example_main, example_toc, "/code", code_url, full_layout=False),
        doc_dir / "05_Experiments.html": shell("Experiments", "", f"https://kaizheng-academic.github.io{base}/documentation/05_Experiments.html", "layout-page", nav_html(base, "exp", code_url), "Experiments", "", exp_main, exp_toc, "/code", code_url, full_layout=False),
    }

    for path, content in files.items():
        path.write_text(content, encoding="utf-8")

if not only:
    cards = []
    for p in published:
        cards.append(f'''<article><h3><a href="/code/{html.escape(p['slug'])}/">{html.escape(p['title'])}</a></h3><p>{html.escape(p['summary_cn'])}</p></article>''')
    main = f'''<h2>Overview</h2><p>Independent TRACE-style paper pages.</p>{''.join(cards) if cards else '<p>No published papers yet.</p>'}'''
    html_index = shell(
        "TRACE Overview",
        "TRACE multi-paper portal",
        "https://kaizheng-academic.github.io/code/",
        "layout-full",
        '<header class="navbar navbar-expand-md navbar-custom" id="top"><div class="container"><a class="navbar-brand" href="/code/">TRACE</a><button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation"><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><nav class="navbar-collapse collapse" role="navigation" id="navbarSupportedContent"><ul class="navbar-nav ml-auto"><li class="nav-item "><a class="nav-link" href="https://github.com/kaizheng-academic"><i class="fab fa-github fa-fw " aria-hidden="true"></i> GitHub</a></li></ul></nav></div></header>',
        "TRACE Overview",
        "Independent paper mini-sites",
        main,
        "",
        "/code",
        "https://github.com/kaizheng-academic",
        full_layout=True,
    )
    index_path.write_text(html_index, encoding="utf-8")

print(f"已生成论文页面: {len(selected)}")
for p in selected:
    print(f"- /code/{p['slug']}/")
print(f"入口页改动: {'否（--only模式）' if only else '是（全量模式）'}")
PY
