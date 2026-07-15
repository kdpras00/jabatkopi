<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Docs — Jabat Kopi ☕️</title>
    <meta name="description" content="Dokumentasi API lengkap untuk aplikasi Jabat Kopi — autentikasi, menu, reservasi, pesanan, dan pembayaran Midtrans.">

    <!-- Marked.js for Markdown rendering -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <!-- Highlight.js for code syntax -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>

    <style>
        :root {
            --bg: #0f0e0d;
            --surface: #1a1815;
            --border: #2e2a25;
            --gold: #c9923a;
            --gold-light: #e0a84a;
            --text: #e8ddd0;
            --muted: #8a7a6a;
            --code-bg: #141210;
            --sidebar-w: 260px;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: var(--bg);
            color: var(--text);
            line-height: 1.7;
            display: flex;
            min-height: 100vh;
        }

        /* ── Sidebar ── */
        #sidebar {
            width: var(--sidebar-w);
            background: var(--surface);
            border-right: 1px solid var(--border);
            padding: 24px 0;
            position: fixed;
            top: 0; left: 0; bottom: 0;
            overflow-y: auto;
            z-index: 100;
        }

        #sidebar .logo {
            padding: 0 20px 24px;
            border-bottom: 1px solid var(--border);
        }

        #sidebar .logo h1 {
            font-size: 18px;
            font-weight: 700;
            color: var(--gold);
        }

        #sidebar .logo p {
            font-size: 12px;
            color: var(--muted);
            margin-top: 2px;
        }

        #sidebar nav {
            padding: 16px 0;
        }

        #sidebar nav a {
            display: block;
            padding: 8px 20px;
            color: var(--muted);
            text-decoration: none;
            font-size: 13px;
            transition: all .15s;
            border-left: 2px solid transparent;
        }

        #sidebar nav a:hover,
        #sidebar nav a.active {
            color: var(--gold-light);
            background: rgba(201,146,58,.08);
            border-left-color: var(--gold);
        }

        #sidebar nav .section-header {
            padding: 12px 20px 4px;
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--muted);
        }

        /* ── Main ── */
        #main {
            margin-left: var(--sidebar-w);
            flex: 1;
            max-width: 900px;
            padding: 48px 48px 80px;
        }

        /* ── Markdown Styles ── */
        #content h1 {
            font-size: 32px;
            font-weight: 800;
            color: var(--gold);
            margin-bottom: 8px;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--border);
        }

        #content h2 {
            font-size: 20px;
            font-weight: 700;
            color: var(--gold-light);
            margin-top: 48px;
            margin-bottom: 20px;
            padding: 12px 16px;
            background: rgba(201,146,58,.07);
            border-left: 3px solid var(--gold);
            border-radius: 0 6px 6px 0;
        }

        #content h3 {
            font-size: 15px;
            font-weight: 600;
            color: #b0c4de;
            margin-top: 28px;
            margin-bottom: 10px;
        }

        #content p {
            margin-bottom: 12px;
            color: var(--text);
        }

        #content a { color: var(--gold); }

        #content ul, #content ol {
            margin: 8px 0 12px 20px;
        }

        #content li { margin-bottom: 4px; }

        #content code {
            background: var(--code-bg);
            border: 1px solid var(--border);
            border-radius: 4px;
            padding: 2px 6px;
            font-size: 13px;
            font-family: 'Fira Code', 'Cascadia Code', monospace;
            color: var(--gold-light);
        }

        #content pre {
            background: var(--code-bg) !important;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 20px;
            overflow-x: auto;
            margin: 12px 0 20px;
        }

        #content pre code {
            background: transparent !important;
            border: none !important;
            padding: 0 !important;
            color: inherit;
            font-size: 13px;
        }

        #content table {
            width: 100%;
            border-collapse: collapse;
            margin: 16px 0;
            font-size: 14px;
        }

        #content th {
            background: rgba(201,146,58,.12);
            color: var(--gold);
            padding: 10px 14px;
            text-align: left;
            border: 1px solid var(--border);
        }

        #content td {
            padding: 9px 14px;
            border: 1px solid var(--border);
            color: var(--text);
        }

        #content tr:nth-child(even) td {
            background: rgba(255,255,255,.02);
        }

        #content hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 40px 0;
        }

        #content blockquote {
            border-left: 3px solid var(--gold);
            padding: 10px 16px;
            background: rgba(201,146,58,.05);
            border-radius: 0 6px 6px 0;
            color: var(--muted);
            font-style: italic;
        }

        /* ── Top bar ── */
        #topbar {
            position: fixed;
            top: 0; right: 0;
            left: var(--sidebar-w);
            height: 48px;
            background: rgba(15,14,13,.9);
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            padding: 0 24px;
            z-index: 99;
            backdrop-filter: blur(8px);
            gap: 12px;
        }

        #topbar .badge {
            background: rgba(201,146,58,.15);
            border: 1px solid var(--gold);
            color: var(--gold);
            border-radius: 20px;
            padding: 2px 12px;
            font-size: 12px;
            font-weight: 600;
        }

        #topbar .base-url {
            font-size: 12px;
            color: var(--muted);
            font-family: monospace;
        }

        #main { padding-top: 88px; }

        /* ── Mobile ── */
        @media (max-width: 768px) {
            #sidebar { display: none; }
            #main { margin-left: 0; padding: 72px 20px 60px; }
            #topbar { left: 0; }
        }

        /* ── Loading ── */
        #loading {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 200px;
            color: var(--muted);
        }
    </style>
</head>
<body>

<aside id="sidebar">
    <div class="logo">
        <h1>☕️ Jabat Kopi</h1>
        <p>API Documentation</p>
    </div>
    <nav id="sidenav">
        <div class="section-header">Referensi</div>
        <a href="#autentikasi">🔐 Authentication</a>
        <a href="#menus">🍽 Menus</a>
        <a href="#tables">🪑 Tables</a>
        <a href="#reservations">📅 Reservations</a>
        <a href="#orders">🛒 Orders & Bayar</a>
        <div class="section-header">Lainnya</div>
        <a href="#admin">🛡 Admin</a>
        <a href="#image-proxy">🖼 Image Proxy</a>
        <a href="#error-codes">⚠️ Error Codes</a>
    </nav>
</aside>

<div id="topbar">
    <span class="badge">v1.0</span>
    <span class="base-url">https://jabatkopi.my.id/api</span>
</div>

<main id="main">
    <div id="loading">Memuat dokumentasi...</div>
    <div id="content" style="display:none"></div>
</main>

<script>
    // Load markdown from the same server
    fetch('/api-docs-raw')
        .then(r => r.text())
        .then(md => {
            document.getElementById('loading').style.display = 'none';
            const el = document.getElementById('content');
            el.style.display = 'block';

            marked.setOptions({ breaks: true, gfm: true });
            el.innerHTML = marked.parse(md);

            // Syntax highlight
            el.querySelectorAll('pre code').forEach(block => {
                hljs.highlightElement(block);
            });

            // Smooth scroll anchors
            el.querySelectorAll('h2, h3').forEach(h => {
                const id = h.textContent.trim().toLowerCase()
                    .replace(/[^\w\s]/g, '')
                    .replace(/\s+/g, '-')
                    .replace(/^[\d-]+/, '');
                h.id = id;
            });

            // Active nav on scroll
            const navLinks = document.querySelectorAll('#sidenav a');
            const headings = el.querySelectorAll('h2');

            const observer = new IntersectionObserver(entries => {
                entries.forEach(e => {
                    if (e.isIntersecting) {
                        navLinks.forEach(a => a.classList.remove('active'));
                        const active = [...navLinks].find(a =>
                            a.getAttribute('href').slice(1) === e.target.id
                        );
                        if (active) active.classList.add('active');
                    }
                });
            }, { rootMargin: '-30% 0px -60% 0px' });

            headings.forEach(h => observer.observe(h));
        })
        .catch(() => {
            document.getElementById('loading').innerHTML =
                '<p style="color:#c44">Gagal memuat dokumentasi. Pastikan server berjalan.</p>';
        });
</script>
</body>
</html>
