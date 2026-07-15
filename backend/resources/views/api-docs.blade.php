<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jabat Kopi API — Dokumentasi</title>
    <meta name="description" content="Referensi API lengkap untuk aplikasi Jabat Kopi. Autentikasi, menu, reservasi, pesanan, dan pembayaran Midtrans.">

    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark-dimmed.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">

    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --ink: #1a1a1a;
            --ink-secondary: #555;
            --ink-muted: #888;
            --border: #e5e5e5;
            --bg: #fff;
            --bg-subtle: #f9f9f9;
            --accent: #2563eb;
            --accent-bg: #eff6ff;
            --mono: 'JetBrains Mono', monospace;
            --sans: 'Inter', system-ui, sans-serif;
            --sidebar: 240px;
            --max: 720px;
        }

        html { font-size: 15px; scroll-behavior: smooth; }

        body {
            font-family: var(--sans);
            color: var(--ink);
            background: var(--bg);
            display: flex;
            min-height: 100vh;
            line-height: 1.65;
        }

        /* ── Sidebar ── */
        #sidebar {
            width: var(--sidebar);
            flex-shrink: 0;
            position: fixed;
            top: 0; left: 0; bottom: 0;
            overflow-y: auto;
            border-right: 1px solid var(--border);
            background: var(--bg-subtle);
            padding: 32px 0 48px;
        }

        .sidebar-header {
            padding: 0 20px 24px;
        }

        .sidebar-header .logo {
            font-size: 14px;
            font-weight: 600;
            color: var(--ink);
            display: flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
        }

        .sidebar-header .logo span {
            display: inline-block;
            width: 8px; height: 8px;
            background: var(--accent);
            border-radius: 50%;
        }

        .sidebar-header .version {
            margin-top: 4px;
            font-size: 11px;
            font-family: var(--mono);
            color: var(--ink-muted);
        }

        #sidenav { margin-top: 8px; }

        .nav-group { margin-bottom: 4px; }

        .nav-label {
            display: block;
            padding: 0 20px;
            margin: 16px 0 4px;
            font-size: 10px;
            font-weight: 600;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--ink-muted);
        }

        .nav-link {
            display: block;
            padding: 6px 20px;
            font-size: 13px;
            color: var(--ink-secondary);
            text-decoration: none;
            transition: color .1s;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .nav-link:hover { color: var(--ink); }

        .nav-link.active {
            color: var(--accent);
            background: var(--accent-bg);
        }

        /* ── Main ── */
        #main {
            margin-left: var(--sidebar);
            flex: 1;
            min-height: 100vh;
        }

        #topbar {
            position: sticky;
            top: 0;
            background: rgba(255,255,255,.92);
            backdrop-filter: blur(8px);
            border-bottom: 1px solid var(--border);
            padding: 0 40px;
            height: 48px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            z-index: 50;
        }

        .base-url {
            font-family: var(--mono);
            font-size: 12px;
            color: var(--ink-muted);
            background: var(--bg-subtle);
            border: 1px solid var(--border);
            padding: 3px 10px;
            border-radius: 4px;
        }

        .status-dot {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            color: var(--ink-muted);
        }

        .status-dot::before {
            content: '';
            display: block;
            width: 6px; height: 6px;
            background: #22c55e;
            border-radius: 50%;
        }

        #content {
            padding: 48px 40px 80px;
            max-width: calc(var(--max) + 80px);
        }

        /* ── Markdown ── */
        #content h1 {
            font-size: 26px;
            font-weight: 600;
            color: var(--ink);
            margin-bottom: 8px;
            letter-spacing: -0.02em;
            text-wrap: balance;
        }

        #content > h1 + p {
            color: var(--ink-secondary);
            margin-bottom: 32px;
            font-size: 15px;
        }

        #content h2 {
            font-size: 15px;
            font-weight: 600;
            color: var(--ink);
            margin-top: 52px;
            margin-bottom: 16px;
            padding-top: 20px;
            border-top: 1px solid var(--border);
        }

        #content h2:first-of-type { margin-top: 24px; }

        #content h3 {
            font-size: 14px;
            font-weight: 600;
            color: var(--ink);
            margin-top: 28px;
            margin-bottom: 10px;
        }

        #content p {
            max-width: 65ch;
            margin-bottom: 12px;
            color: var(--ink-secondary);
        }

        #content a {
            color: var(--accent);
            text-decoration: underline;
            text-underline-offset: 2px;
        }

        #content ul, #content ol {
            margin: 8px 0 14px 16px;
            color: var(--ink-secondary);
        }

        #content li { margin-bottom: 4px; }

        #content code {
            font-family: var(--mono);
            font-size: 12.5px;
            background: var(--bg-subtle);
            border: 1px solid var(--border);
            border-radius: 3px;
            padding: 1px 5px;
            color: var(--ink);
        }

        #content pre {
            background: #1e1e1e !important;
            border-radius: 6px;
            padding: 20px;
            overflow-x: auto;
            margin: 12px 0 20px;
            border: none;
        }

        #content pre code {
            font-family: var(--mono) !important;
            font-size: 12.5px !important;
            background: transparent !important;
            border: none !important;
            padding: 0 !important;
            color: inherit;
        }

        #content table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            margin: 14px 0 20px;
        }

        #content th {
            text-align: left;
            font-weight: 500;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--ink-muted);
            padding: 8px 12px;
            border-bottom: 1px solid var(--border);
        }

        #content td {
            padding: 9px 12px;
            border-bottom: 1px solid var(--border);
            color: var(--ink-secondary);
            vertical-align: top;
        }

        #content td code { font-size: 12px; }

        #content tr:last-child td { border-bottom: none; }

        #content hr {
            display: none;
        }

        #content blockquote {
            border-left: 2px solid var(--border);
            padding: 2px 16px;
            color: var(--ink-muted);
            margin: 12px 0;
        }

        /* ── HTTP method badges ── */
        .method {
            display: inline-block;
            font-family: var(--mono);
            font-size: 11px;
            font-weight: 500;
            padding: 1px 6px;
            border-radius: 3px;
            margin-right: 6px;
        }

        /* ── Loading ── */
        #loading {
            padding: 48px 40px;
            color: var(--ink-muted);
            font-size: 14px;
        }

        /* ── Mobile ── */
        @media (max-width: 700px) {
            #sidebar { display: none; }
            #main { margin-left: 0; }
            #content { padding: 32px 20px 60px; }
            #topbar { padding: 0 20px; }
        }
    </style>
</head>
<body>

<aside id="sidebar">
    <div class="sidebar-header">
        <a class="logo" href="/api-docs">
            <span></span>
            Jabat Kopi API
        </a>
        <div class="version">v1.0 · Sandbox</div>
    </div>

    <nav id="sidenav">
        <span class="nav-label">Mulai</span>
        <a class="nav-link" href="#dokumentasi-api-jabat-kopi">Pengantar</a>

        <span class="nav-label">Endpoint</span>
        <a class="nav-link" href="#-1-authentication">Authentication</a>
        <a class="nav-link" href="#-2-menus">Menus</a>
        <a class="nav-link" href="#-3-tables-meja">Tables</a>
        <a class="nav-link" href="#-4-reservations">Reservations</a>
        <a class="nav-link" href="#-5-orders--pembayaran">Orders & Bayar</a>
        <a class="nav-link" href="#-6-admin-endpoints">Admin</a>
        <a class="nav-link" href="#-7-image-proxy">Image Proxy</a>

        <span class="nav-label">Referensi</span>
        <a class="nav-link" href="#-error-codes">Error Codes</a>
    </nav>
</aside>

<div id="main">
    <div id="topbar">
        <span class="base-url">https://jabatkopi.my.id/api</span>
        <span class="status-dot">Sandbox aktif</span>
    </div>

    <div id="loading">Memuat dokumentasi…</div>
    <div id="content" style="display:none"></div>
</div>

<script>
    fetch('/api-docs-raw')
        .then(r => r.ok ? r.text() : Promise.reject(r.status))
        .then(md => {
            document.getElementById('loading').style.display = 'none';
            const el = document.getElementById('content');
            el.style.display = 'block';

            marked.setOptions({ gfm: true, breaks: false });
            el.innerHTML = marked.parse(md);

            // Syntax highlight
            el.querySelectorAll('pre code').forEach(b => hljs.highlightElement(b));

            // Active nav on scroll
            const links = document.querySelectorAll('.nav-link[href^="#"]');
            const headings = [...el.querySelectorAll('h2, h3')];

            const ioOpts = { rootMargin: '-20% 0px -75% 0px' };
            const io = new IntersectionObserver(entries => {
                entries.forEach(e => {
                    if (!e.isIntersecting) return;
                    links.forEach(a => {
                        a.classList.toggle('active',
                            a.getAttribute('href') === '#' + e.target.id);
                    });
                });
            }, ioOpts);

            headings.forEach(h => io.observe(h));
        })
        .catch(err => {
            document.getElementById('loading').textContent =
                'Gagal memuat dokumentasi (' + err + ').';
        });
</script>
</body>
</html>
