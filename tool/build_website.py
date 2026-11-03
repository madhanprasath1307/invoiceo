#!/usr/bin/env python3
"""Builds the redesigned Invoiceo website (design system 2, October 2026).

Usage (from the invoiso-main folder):
    python3 tool/build_website.py ../invoiceo-website

Writes plain HTML pages plus sitemap.xml, robots.txt, llms.txt and
site.webmanifest. The stylesheet (assets/css/site.css) and behaviour
(assets/js/site.js) are hand-written in the website folder. Values that can
change without a rebuild (WhatsApp, form links, analytics ID, file sizes) live
in the website's assets/js/config.js, not here."""
import hashlib
import html
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from site_text import load as load_text   # per-language text: tool/site_text/<code>.py
TEXT = {}
OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else '../invoiceo-website')
SITE = 'https://invoiceo.in'
NAME = 'Invoiceo'
BUSINESS = 'Madcreations'
EMAIL = 'madhanprasat2002r@gmail.com'
VERSION = '1.0.8'
RELEASE_DATE = '28 October 2026'
RELEASE_ISO = '2026-10-28'
# When the website's own text last changed. Set it to the publish date whenever
# page content changes between app releases; pages use the later of this and
# RELEASE_ISO as their dateModified and sitemap <lastmod>. PAGE_UPDATED can give
# a single page its own date. Privacy/terms keep their policy date (RELEASE_ISO).
SITE_UPDATED_ISO = '2026-11-03'
# The cookie box (Google Analytics only after Accept, a "Cookie settings" footer link and the matching Privacy wording).
# The code stays in site.js. False = analytics runs for everyone, as before, and no box is shown. Set True to bring the box back,
# then rebuild: this switches the box, the footer link and the Privacy text together. (Visitors from the EU/UK should be asked.)
CONSENT_BANNER = False
PAGE_UPDATED = {}
PAGE_MODIFIED = {}  # filled by page(): filename -> dateModified, reused by the sitemap
COFFEE = 'https://buymeacoffee.com/madcreations'
GH = 'https://github.com/Maddy-1303/invoiceo'
# Fixed-name copies the release workflow adds to every release (.github/workflows/build.yml).
DL = GH + '/releases/latest/download/'
FILES = {
    'windows': 'Invoiceo-Setup-Windows.exe',
    'mac': 'Invoiceo-macOS.dmg',
    'linuxDeb': 'Invoiceo-Linux.deb',
    'linuxAppImage': 'Invoiceo-Linux.AppImage',
}
# Fonts are hosted on this site (assets/fonts, declared at the top of site.css), so no visitor's browser contacts Google for them.
# The pages only preload the first files they draw with; the rest load when needed.
def _preload(*files):
    return '\n  '.join(f'<link rel="preload" href="/assets/fonts/{f}" as="font" type="font/woff2" crossorigin>' for f in files)
FONTS = _preload('manrope-latin.woff2', 'fraunces-latin.woff2')              # English pages: Manrope text, Fraunces headings
FONTS_TA = _preload('manrope-latin.woff2', 'notosanstamil-tamil.woff2')      # Tamil: Manrope draws the Latin letters
FONTS_HI = _preload('manrope-latin.woff2', 'notosansdevanagari-devanagari.woff2')
# Languages with a home page. To add one: copy tool/site_text/en.py to <code>.py, translate it, and add the code here.
HOME_LANGS = ['en', 'ta', 'hi']
for _code in HOME_LANGS:
    TEXT[_code] = load_text(_code)
FONT_LINKS = {'latin': FONTS, 'tamil': FONTS_TA, 'devanagari': FONTS_HI}   # keyed by TEXT[code]['shell']['fonts']
# The home page in each language; they point at each other with hreflang.
HOMES = {c: TEXT[c]['shell']['home'] for c in HOME_LANGS}
# Where links to a home page point. The English home is the site root, so visits are not split
# between / and /index.html (Google Analytics counts them as two pages).
HOME_HREF = {c: TEXT[c]['shell']['home_href'] for c in HOME_LANGS}
# (href, label, title) of the header's language links.
LANG_LINKS = {c: (TEXT[c]['shell']['switch']['href'], TEXT[c]['shell']['switch']['label'], TEXT[c]['shell']['switch']['title']) for c in HOME_LANGS}
MONTHS = TEXT['en']['shell']['months']


def fmt_release_date(lang):
    """The release date written the way that language writes it, e.g. 28 October 2026."""
    months = TEXT[lang]['shell']['months']
    return f'{int(RELEASE_ISO[8:])} {months[int(RELEASE_ISO[5:7]) - 1]} {RELEASE_ISO[:4]}'


# Icons: Feather (MIT, © Cole Bemis) and platform marks from Simple Icons (CC0). See licenses.html.
STROKE = {
    'arrow': '<line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>',
    'briefcase': '<rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>',
    'calendar': '<rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>',
    'chart': '<line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>',
    'check': '<polyline points="20 6 9 17 4 12"/>',
    'check-circle': '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>',
    'chevron-down': '<polyline points="6 9 12 15 18 9"/>',
    'chevron-up': '<polyline points="18 15 12 9 6 15"/>',
    'cloud-off': '<path d="M22.61 16.95A5 5 0 0 0 18 10h-1.26a8 8 0 0 0-7.05-6M5 5a8 8 0 0 0 4 15h9a5 5 0 0 0 1.7-.3"/><line x1="1" y1="1" x2="23" y2="23"/>',
    'code': '<polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>',
    'coffee': '<path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/>',
    'copy': '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    'credit-card': '<rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>',
    'database': '<ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/>',
    'download': '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>',
    'external-link': '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>',
    'file': '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>',
    'gift': '<polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><line x1="12" y1="22" x2="12" y2="7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/>',
    'globe': '<circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>',
    'hard-drive': '<line x1="22" y1="12" x2="2" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" y1="16" x2="6.01" y2="16"/><line x1="10" y1="16" x2="10.01" y2="16"/>',
    'help': '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/>',
    'laptop': '<rect x="3" y="4" width="18" height="12" rx="2"/><line x1="2" y1="20" x2="22" y2="20"/>',
    'layers': '<polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/>',
    'layout': '<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/>',
    'list': '<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>',
    'lock': '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
    'mail': '<path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/>',
    'menu': '<line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/>',
    'message': '<path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>',
    'monitor': '<rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/>',
    'package': '<path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/>',
    'percent': '<line x1="19" y1="5" x2="5" y2="19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>',
    'printer': '<polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/>',
    'qr': '<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3h-3zM20 14v.01M14 20h.01M17 20h4v-3"/>',
    'refresh': '<polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>',
    'repeat': '<polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/>',
    'share': '<path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/>',
    'shield': '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
    'shopping-bag': '<path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/>',
    'sliders': '<line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/>',
    'smartphone': '<rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/>',
    'terminal': '<polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/>',
    'tool': '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
    'truck': '<rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/>',
    'user': '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
    'users': '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    'wifi-off': '<line x1="1" y1="1" x2="23" y2="23"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/>',
    'x': '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
    'zap': '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>',
}
BRAND = {
    'apple': 'M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701',
    'github': 'M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12',
    'linux': 'M12.504 0c-.155 0-.315.008-.48.021-4.226.333-3.105 4.807-3.17 6.298-.076 1.092-.3 1.953-1.05 3.02-.885 1.051-2.127 2.75-2.716 4.521-.278.832-.41 1.684-.287 2.489a.424.424 0 00-.11.135c-.26.268-.45.6-.663.839-.199.199-.485.267-.797.4-.313.136-.658.269-.864.68-.09.189-.136.394-.132.602 0 .199.027.4.055.536.058.399.116.728.04.97-.249.68-.28 1.145-.106 1.484.174.334.535.47.94.601.81.2 1.91.135 2.774.6.926.466 1.866.67 2.616.47.526-.116.97-.464 1.208-.946.587-.003 1.23-.269 2.26-.334.699-.058 1.574.267 2.577.2.025.134.063.198.114.333l.003.003c.391.778 1.113 1.132 1.884 1.071.771-.06 1.592-.536 2.257-1.306.631-.765 1.683-1.084 2.378-1.503.348-.199.629-.469.649-.853.023-.4-.2-.811-.714-1.376v-.097l-.003-.003c-.17-.2-.25-.535-.338-.926-.085-.401-.182-.786-.492-1.046h-.003c-.059-.054-.123-.067-.188-.135a.357.357 0 00-.19-.064c.431-1.278.264-2.55-.173-3.694-.533-1.41-1.465-2.638-2.175-3.483-.796-1.005-1.576-1.957-1.56-3.368.026-2.152.236-6.133-3.544-6.139zm.529 3.405h.013c.213 0 .396.062.584.198.19.135.33.332.438.533.105.259.158.459.166.724 0-.02.006-.04.006-.06v.105a.086.086 0 01-.004-.021l-.004-.024a1.807 1.807 0 01-.15.706.953.953 0 01-.213.335.71.71 0 00-.088-.042c-.104-.045-.198-.064-.284-.133a1.312 1.312 0 00-.22-.066c.05-.06.146-.133.183-.198.053-.128.082-.264.088-.402v-.02a1.21 1.21 0 00-.061-.4c-.045-.134-.101-.2-.183-.333-.084-.066-.167-.132-.267-.132h-.016c-.093 0-.176.03-.262.132a.8.8 0 00-.205.334 1.18 1.18 0 00-.09.4v.019c.002.089.008.179.02.267-.193-.067-.438-.135-.607-.202a1.635 1.635 0 01-.018-.2v-.02a1.772 1.772 0 01.15-.768c.082-.22.232-.406.43-.533a.985.985 0 01.594-.2zm-2.962.059h.036c.142 0 .27.048.399.135.146.129.264.288.344.465.09.199.14.4.153.667v.004c.007.134.006.2-.002.266v.08c-.03.007-.056.018-.083.024-.152.055-.274.135-.393.2.012-.09.013-.18.003-.267v-.015c-.012-.133-.04-.2-.082-.333a.613.613 0 00-.166-.267.248.248 0 00-.183-.064h-.021c-.071.006-.13.04-.186.132a.552.552 0 00-.12.27.944.944 0 00-.023.33v.015c.012.135.037.2.08.334.046.134.098.2.166.268.01.009.02.018.034.024-.07.057-.117.07-.176.136a.304.304 0 01-.131.068 2.62 2.62 0 01-.275-.402 1.772 1.772 0 01-.155-.667 1.759 1.759 0 01.08-.668 1.43 1.43 0 01.283-.535c.128-.133.26-.2.418-.2zm1.37 1.706c.332 0 .733.065 1.216.399.293.2.523.269 1.052.468h.003c.255.136.405.266.478.399v-.131a.571.571 0 01.016.47c-.123.31-.516.643-1.063.842v.002c-.268.135-.501.333-.775.465-.276.135-.588.292-1.012.267a1.139 1.139 0 01-.448-.067 3.566 3.566 0 01-.322-.198c-.195-.135-.363-.332-.612-.465v-.005h-.005c-.4-.246-.616-.512-.686-.71-.07-.268-.005-.47.193-.6.224-.135.38-.271.483-.336.104-.074.143-.102.176-.131h.002v-.003c.169-.202.436-.47.839-.601.139-.036.294-.065.466-.065zm2.8 2.142c.358 1.417 1.196 3.475 1.735 4.473.286.534.855 1.659 1.102 3.024.156-.005.33.018.513.064.646-1.671-.546-3.467-1.089-3.966-.22-.2-.232-.335-.123-.335.59.534 1.365 1.572 1.646 2.757.13.535.16 1.104.021 1.67.067.028.135.06.205.067 1.032.534 1.413.938 1.23 1.537v-.043c-.06-.003-.12 0-.18 0h-.016c.151-.467-.182-.825-1.065-1.224-.915-.4-1.646-.336-1.77.465-.008.043-.013.066-.018.135-.068.023-.139.053-.209.064-.43.268-.662.669-.793 1.187-.13.533-.17 1.156-.205 1.869v.003c-.02.334-.17.838-.319 1.35-1.5 1.072-3.58 1.538-5.348.334a2.645 2.645 0 00-.402-.533 1.45 1.45 0 00-.275-.333c.182 0 .338-.03.465-.067a.615.615 0 00.314-.334c.108-.267 0-.697-.345-1.163-.345-.467-.931-.995-1.788-1.521-.63-.4-.986-.87-1.15-1.396-.165-.534-.143-1.085-.015-1.645.245-1.07.873-2.11 1.274-2.763.107-.065.037.135-.408.974-.396.751-1.14 2.497-.122 3.854a8.123 8.123 0 01.647-2.876c.564-1.278 1.743-3.504 1.836-5.268.048.036.217.135.289.202.218.133.38.333.59.465.21.201.477.335.876.335.039.003.075.006.11.006.412 0 .73-.134.997-.268.29-.134.52-.334.74-.4h.005c.467-.135.835-.402 1.044-.7zm2.185 8.958c.037.6.343 1.245.882 1.377.588.134 1.434-.333 1.791-.765l.211-.01c.315-.007.577.01.847.268l.003.003c.208.199.305.53.391.876.085.4.154.78.409 1.066.486.527.645.906.636 1.14l.003-.007v.018l-.003-.012c-.015.262-.185.396-.498.595-.63.401-1.746.712-2.457 1.57-.618.737-1.37 1.14-2.036 1.191-.664.053-1.237-.2-1.574-.898l-.005-.003c-.21-.4-.12-1.025.056-1.69.176-.668.428-1.344.463-1.897.037-.714.076-1.335.195-1.814.12-.465.308-.797.641-.984l.045-.022zm-10.814.049h.01c.053 0 .105.005.157.014.376.055.706.333 1.023.752l.91 1.664.003.003c.243.533.754 1.064 1.189 1.637.434.598.77 1.131.729 1.57v.006c-.057.744-.48 1.148-1.125 1.294-.645.135-1.52.002-2.395-.464-.968-.536-2.118-.469-2.857-.602-.369-.066-.61-.2-.723-.4-.11-.2-.113-.602.123-1.23v-.004l.002-.003c.117-.334.03-.752-.027-1.118-.055-.401-.083-.71.043-.94.16-.334.396-.4.69-.533.294-.135.64-.202.915-.47h.002v-.002c.256-.268.445-.601.668-.838.19-.201.38-.336.663-.336zm7.159-9.074c-.435.201-.945.535-1.488.535-.542 0-.97-.267-1.28-.466-.154-.134-.28-.268-.373-.335-.164-.134-.144-.333-.074-.333.109.016.129.134.199.2.096.066.215.2.36.333.292.2.68.467 1.167.467.485 0 1.053-.267 1.398-.466.195-.135.445-.334.648-.467.156-.136.149-.267.279-.267.128.016.034.134-.147.332a8.097 8.097 0 01-.69.468zm-1.082-1.583V5.64c-.006-.02.013-.042.029-.05.074-.043.18-.027.26.004.063 0 .16.067.15.135-.006.049-.085.066-.135.066-.055 0-.092-.043-.141-.068-.052-.018-.146-.008-.163-.065zm-.551 0c-.02.058-.113.049-.166.066-.047.025-.086.068-.14.068-.05 0-.13-.02-.136-.068-.01-.066.088-.133.15-.133.08-.031.184-.047.259-.005.019.009.036.03.03.05v.02h.003z',
    'windows': 'M3 5.6 10.4 4.6v7.1H3zM11.4 4.4 21 3v8.7h-9.6zM3 12.6h7.4v7.1L3 18.6zM11.4 12.6H21V21l-9.6-1.4z',
}


def asset(path):
    """path?v=<content hash>, so browsers fetch a file again only when it changes."""
    with open(os.path.join(OUT, path), 'rb') as f:
        return f'{path}?v={hashlib.sha1(f.read()).hexdigest()[:10]}'


def esc(s):
    return html.escape(s, quote=True)


def strip_tags(s):
    return re.sub(r'<[^>]+>', '', s)


def icon(name):
    if name in BRAND:
        return (f'<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" '
                f'focusable="false"><path d="{BRAND[name]}"/></svg>')
    return (f'<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
            f'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">{STROKE[name]}</svg>')


# ─────────────────────────────── Components ────────────────────────────────
def btn(label, href, kind='primary', size='', ic=None, attrs='', block=False, cls=''):
    classes = ' '.join(c for c in ['btn', f'btn-{kind}', 'btn-lg' if size == 'lg' else '',
                                   'btn-block' if block else '', cls] if c)
    return f'<a class="{classes}" href="{href}"{attrs}>{icon(ic) if ic else ""}<span>{label}</span></a>'


def badge(label, tone='brand', ic=None, cls=''):
    return f'<span class="badge badge-{tone}{(" " + cls) if cls else ""}">{icon(ic) if ic else ""}<span>{label}</span></span>'


def tile(ic, tone='', size=''):
    classes = ' '.join(c for c in ['tile', f'tile-{tone}' if tone else '', f'tile-{size}' if size else ''] if c)
    return f'<span class="{classes}">{icon(ic)}</span>'


def checks(items, cls=''):
    return f'<ul class="checks{(" " + cls) if cls else ""}">' + ''.join(f'<li>{i}</li>' for i in items) + '</ul>'


def section_head(eyebrow, title, lead=None, hid=None, left=False):
    idattr = f' id="{hid}"' if hid else ''
    lead_html = f'<p class="lead">{lead}</p>' if lead else ''
    return (f'<div class="section-head{" left" if left else ""}"><p class="eyebrow">{eyebrow}</p>'
            f'<h2{idattr}>{title}</h2>{lead_html}</div>')


def section(inner, sid=None, cls='', label=None):
    idattr = f' id="{sid}"' if sid else ''
    al = f' aria-labelledby="{label}"' if label else ''
    return f'<section class="section{(" " + cls) if cls else ""}"{idattr}{al}>\n  <div class="wrap">\n{inner}\n  </div>\n</section>'


# Real screenshots of the app (sample shop, not real customers). Made with
#   flutter test tool/screenshots/marketing_screenshots_test.dart
SHOT_W, SHOT_H = 2160, 1350
SCREENS = os.path.join(OUT, 'assets', 'images', 'screens')


def small_copy(name):
    """A 1280px JPEG next to each screenshot PNG (about a third of the size),
    made with macOS 'sips' when the PNG is newer. Returns False without it."""
    png = os.path.join(SCREENS, name + '.png')
    jpg = os.path.join(SCREENS, name + '-1280.jpg')
    if os.path.exists(png) and (not os.path.exists(jpg) or os.path.getmtime(jpg) < os.path.getmtime(png)):
        try:
            subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '82',
                            '--resampleWidth', '1280', png, '--out', jpg], check=True, capture_output=True)
        except (OSError, subprocess.CalledProcessError):
            return False
    return os.path.exists(jpg)


def window(name, alt, cls='', lazy=True, sizes='(max-width: 720px) 100vw, (max-width: 1100px) 50vw, 420px'):
    # path?v=<content hash>: a new screenshot is fetched again (the scenes over the screens depend on the exact picture)
    has_small = small_copy(name)
    full = asset(f'assets/images/screens/{name}.png')
    small = asset(f'assets/images/screens/{name}-1280.jpg') if has_small else full
    src = small
    srcset = f' srcset="{small} 1280w, {full} {SHOT_W}w" sizes="{sizes}"' if has_small else ''
    load = ' loading="lazy" decoding="async"' if lazy else ' fetchpriority="high"'
    return (f'<div class="window{(" " + cls) if cls else ""}"><div class="window-bar"><i></i><i></i><i></i><span>{NAME}</span></div>'
            f'<a href="{full}" target="_blank" rel="noopener" title="Open full size">'
            f'<img src="{src}"{srcset} width="{SHOT_W}" height="{SHOT_H}" alt="{esc(alt)}"{load}></a></div>')


TOUR_STEPS = [  # screen index, cursor x/y and the lit area (box x, y, w, h), all as % of the screen
    (0, (33, 13), (17, 9.5, 55, 8)),
    (0, (24, 31), (17, 27, 55, 50)),
    (0, (86, 12), (73.5, 9, 25, 47)),
    (0, (91, 95.5), (84, 92.7, 14.7, 5.6)),   # Create Invoice, then the "created" card, then Print and the receipt prints
    (2, (89, 33), (17, 28, 81, 8)),
    (3, (30, 28), (17, 21.5, 81, 17)),
]
TOUR_SCREENS = ('create-invoice', 'invoice-created', 'invoices', 'dashboard')


def hero_tour(lang, alt, labels):
    """The hero app window: a guided walk (cursor, click, step label, screens) over real screenshots.
    Without JS or with reduced motion it simply shows the first screen."""
    names = [shot_file(n, lang) for n in TOUR_SCREENS]
    imgs = ''
    for i, n in enumerate(names):
        has_small = small_copy(n)
        src = asset(f'assets/images/screens/{n}-1280.jpg') if has_small else asset(f'assets/images/screens/{n}.png')
        load = ' fetchpriority="high"' if i == 0 else ' loading="lazy" decoding="async"'
        imgs += (f'<img class="tour-img{" is-on" if i == 0 else ""}" src="{src}" width="{SHOT_W}" height="{SHOT_H}" '
                 f'alt="{esc(alt if i == 0 else "")}"{load}>')
    steps = []
    for i, (sc, c, b) in enumerate(TOUR_STEPS):
        st = {'s': sc, 'x': c[0], 'y': c[1], 'b': list(b), 't': labels[i]}
        if i == 3:
            # click Create (1.3 s), the created card shows (1.9 s), the cursor goes to Print (2.6 s), clicks (3.7 s), the receipt prints (3.9 s)
            st.update({'p': 1, 'd': 9800, 'sw': [1900, 1], 'm2': [2600, 73.2, 61, [65.5, 56.5, 15.5, 9.5]], 'c2': 3700, 'pt': 3900})
        steps.append(st)
    steps = json.dumps(steps, ensure_ascii=False)
    cursor = ('<svg class="tour-cursor" viewBox="0 0 24 24" width="30" height="30" aria-hidden="true" focusable="false">'
              '<path d="M5 3l14 8-6.2 1.6L9.6 19z" fill="#142033" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg>')
    return (f'<div class="window hero-shot tour" data-tour="{esc(steps)}"><div class="window-bar"><i></i><i></i><i></i><span>{NAME}</span></div>'
            f'<div class="tour-stage">{imgs}<span class="tour-box" aria-hidden="true"></span>{cursor}<span class="tour-ripple" aria-hidden="true"></span>'
            f'<div class="tour-step" aria-hidden="true"><b>1</b><span>{esc(labels[0])}</span></div></div></div>')


def receipt(cls='', lang='en'):
    t = TEXT[lang]['receipt']
    zig = ''.join(f'L{x - 6} 12L{x - 12} 4' for x in range(276, 0, -12))
    body = ''.join(f'<div class="receipt-row"><span>{a}</span><b>{b}</b></div>' for a, b in t['rows'])
    return (f'<div class="receipt{(" " + cls) if cls else ""}"><div class="receipt-paper">'
            f'<p class="receipt-title">{t["title"]}</p><hr>{body}<hr>'
            f'<div class="receipt-total"><span>{t["total"]}</span><b>0.00</b></div>'
            f'<p class="receipt-foot">{t["foot"]}</p></div>'
            f'<svg class="receipt-edge" viewBox="0 0 276 12" aria-hidden="true" focusable="false">'
            f'<path d="M0 0H276V4{zig}V0Z" fill="#fff"/></svg></div>')


def faq_item(q, a, open_=False):
    paras = ''.join(f'<p>{p}</p>' for p in (a if isinstance(a, list) else [a]))
    return f'<details class="faq-item"{" open" if open_ else ""}><summary>{q}</summary><div class="answer">{paras}</div></details>'


# ─────────────────────────────── Platforms ─────────────────────────────────
# The download cards' text (names, requirements, install steps) is in tool/site_text/<code>.py, key 'platforms'.
PLATFORMS = TEXT['en']['platforms']      # English: used by the download page and the AI-summary file


def dl_card(p, full=False, heading='h3', lang='en'):
    buttons = []
    for i, (label, file, _) in enumerate(p['buttons']):
        if i == 0:
            buttons.append(btn(label, DL + file, 'secondary', 'lg', 'download', block=True, cls='dl-main',
                               attrs=' data-primary-download'))
        else:
            buttons.append(btn(label, DL + file, 'ghost', '', 'download', block=True))
    files = '<br>'.join(f'{f}<span data-size="{k}"></span>' for k, f in p['files'])
    if full:
        note = '<ol>' + ''.join(f'<li>{s}</li>' for s in p['steps']) + '</ol>'
    else:
        note = f'<p>{p["note"]}</p>'
    rec = ' is-recommended' if p['key'] == 'windows' else ''
    return (f'<div class="dl-card{rec}" data-platform="{p["key"]}" data-req-short="{p["short"]}"'
            f'{(" id=" + chr(34) + p["anchor"] + chr(34)) if full else ""}>'
            f'<span class="dl-mark" aria-hidden="true">{icon(p["icon"])}</span>'
            f'<div class="dl-card-top">{tile(p["icon"], "neutral")}{badge(TEXT[lang]['rec_label'], "brand", cls="rec-badge")}</div>'
            f'<div><{heading}>{p["name"]}</{heading}><p class="dl-req">{p["req"]}</p></div>'
            f'<div class="dl-buttons">{"".join(buttons)}</div>'
            f'<p class="dl-file">{files}</p>'
            f'<div class="dl-note">{note}</div></div>')


def dl_grid(full=False, lang='en'):
    cards = TEXT[lang]['platforms']
    return '<div class="dl-grid">' + ''.join(dl_card(p, full, lang=lang) for p in cards) + '</div>'


def phone_note(lang='en'):
    """Shown on phones only (site.js): Invoiceo installs on a computer, so the
    visitor sends the download link to themselves. "Send to my computer"
    (the phone's share menu) appears only where the browser can share."""
    P = TEXT[lang]['phone_note']
    text, share, copy = P['text'], P['share'], P['copy']
    return (f'<div class="notice hidden" data-mobile-note>{icon("smartphone")}<div class="stack" style="gap: 12px">'
            f'<span>{text}</span><div class="send-link">'
            f'<button type="button" class="btn btn-primary hidden" data-send-share>{icon("share")}<span>{share}</span></button>'
            f'<a class="btn btn-secondary" href="#" data-send-whatsapp target="_blank" rel="noopener">{icon("message")}<span>WhatsApp</span></a>'
            f'<button type="button" class="btn btn-ghost" data-send-copy>{icon("copy")}<span>{copy}</span></button>'
            '</div></div></div>')


def hero_send(lang='en'):
    """Phones only (site.js): WhatsApp and Copy link right under the hero button,
    so the visitor does not have to scroll to the download section."""
    copy = TEXT[lang]['hero_send_copy']
    return (f'<div class="send-link hidden" data-hero-send>'
            f'<a class="btn btn-secondary" href="#" data-send-whatsapp target="_blank" rel="noopener">{icon("message")}<span>WhatsApp</span></a>'
            f'<button type="button" class="btn btn-ghost" data-send-copy>{icon("copy")}<span>{copy}</span></button></div>')


PHONE_NOTE = phone_note('en')
TRUST = ('<div class="dl-trust">' + ''.join(badge(t, 'teal', 'check') for t in
                                           ['Free forever', 'No credit card', 'No subscription', 'Open source']) + '</div>')
CHECKSUMS = (f'<p class="center small muted">Check your download with the <a href="{DL}SHA256SUMS.txt">SHA-256 checksums</a>'
             '</p>')
FIRST_STEPS = [
    ('download', 'Download', 'Pick your computer above.'),
    ('package', 'Install', 'Open the file and follow the steps.'),
    ('user', 'Sign in and set up', 'The first screen shows how to sign in. Then add your business details.'),
    ('file', 'First invoice', 'Add a customer and items, then create the invoice.'),
    ('printer', 'Print or PDF', 'Print on A4 or a thermal printer, or save a PDF.'),
]


def first_steps(level='h3', steps=FIRST_STEPS, word='Step'):
    lis = ''.join(f'<li><span class="step-label">{tile(ic, "", "sm")}{word} {i + 1}</span><{level} class="h4">{t}</{level}><p>{b}</p></li>'
                  for i, (ic, t, b) in enumerate(steps))
    return f'<ol class="steps-row">{lis}</ol>'


# ─────────────────────────────── Page frame ────────────────────────────────
def header(active, home=False, base=False, lang='en'):
    pre = '' if home else '/'
    H = TEXT[lang]['header']
    links = [(t, h.replace('{pre}', pre), k) for t, h, k in H['links']]
    more = [(t, h.replace('{pre}', pre), k) for t, h, k in H['more']]
    words = H['words']
    others = [(c, v) for c, v in LANG_LINKS.items() if c != lang]
    switch = ''.join(f'<a class="lang-switch" href="{h}" hreflang="{c}" lang="{c}" title="{ti}">{lab}</a>'
                     for c, (h, lab, ti) in others)
    mobile_langs = ('<div class="mobile-langs">' + ''.join(f'<a href="{h}" hreflang="{c}" lang="{c}">{lab}</a>'
                                                            for c, (h, lab, ti) in others) + '</div>')
    cur = lambda key: ' aria-current="page"' if key == active else ''
    nav = ''.join(f'<a href="{h}"{cur(k)}>{t}</a>' for t, h, k in links)
    mobile = ''.join(f'<a href="{h}"{cur(k)}>{t}</a>' for t, h, k in links + more) + mobile_langs
    dl_href = '#download' if home else 'download.html'
    # The 404 page has <base href="/">, where "#main" would mean the home page.
    skip = '' if base else f'<a class="skip-link" href="#main">{words["skip"]}</a>\n'
    return f'''{skip}<header class="site-header">
  <div class="wrap">
    <a class="brand" href="{HOME_HREF[lang]}" aria-label="{words['home']}"><img src="assets/images/logo.png" alt="{NAME}" width="196" height="68"></a>
    <nav class="nav" aria-label="{words['main']}">{nav}</nav>
    <div class="header-actions">
      {switch}
      {btn(words['dl'], dl_href, 'primary', '', 'download', cls='header-cta', attrs=' aria-current="page"' if active == 'download' else '')}
      <button class="menu-toggle" type="button" aria-controls="site-nav" aria-expanded="false" aria-label="{words['menu']}">{icon('menu')}</button>
    </div>
    <nav class="mobile-nav" id="site-nav" aria-label="{words['main_menu']}">{mobile}{btn(words['dl'], dl_href, 'primary', 'lg', 'download', block=True)}</nav>
  </div>
</header>'''


def footer(home=False, lang='en'):
    pre = '' if home else '/'
    F = TEXT[lang]['footer']
    col = lambda title, items: (f'<div><h2>{title}</h2><ul>' + ''.join(f'<li{" data-block" if "data-" in a else ""}><a {a}>{t}</a></li>' for t, a in items)
                                + '</ul></div>')
    cols = [(title, [(t, a.replace('{pre}', pre)) for t, a in items if CONSENT_BANNER or 'data-cookie-settings' not in a]) for title, items in F['cols']]
    # the Languages column lists every home page, from the registry
    cols.append((F['lang_title'], [(TEXT[c]['shell']['switch']['label'], f'href="{HOME_HREF[c]}" hreflang="{c}" lang="{c}"') for c in HOME_LANGS]))
    tagline, coffee, foot_dl, foot_top, credit = F['tagline'], F['coffee'], F['foot_dl'], F['foot_top'], F['credit']
    return f'''<footer class="site-footer">
  <div class="wrap">
    <div class="foot">
      <div class="foot-brand">
        <img src="assets/images/logo.png" alt="{NAME}" width="196" height="68" loading="lazy">
        <p>{tagline}</p>
        <div class="foot-actions">
          {btn(foot_dl, '#download' if home else 'download.html', 'primary', '', 'download')}
          <a class="coffee" href="{COFFEE}" target="_blank" rel="noopener">{icon('coffee')}{coffee}</a>
        </div>
      </div>
      {(chr(10) + '      ').join(col(t, items) for t, items in cols)}
    </div>
    <div class="foot-bottom">
      <span>{credit}</span>
      <span class="foot-end"><a class="foot-mail" href="mailto:{EMAIL}">{EMAIL}</a><a class="to-top" href="#" aria-label="{foot_top}">{icon('arrow')}<span>{foot_top}</span></a></span>
    </div>
  </div>
  <div class="foot-mark" aria-hidden="true">{NAME}</div>
</footer>'''



# ───────────── Smaller pictures (AVIF) and unique alt text, applied to every finished page ─────────────
_AVIF_TOOL = os.path.join('/tmp', 'invoiceo-toavif')
_AVIF_OK = None


def _avif_ready():
    """Compiles tool/toavif.swift once (macOS ImageIO writes AVIF). Without it the pages simply keep their JPEG/PNG pictures."""
    global _AVIF_OK
    if _AVIF_OK is None:
        src = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'toavif.swift')
        try:
            if not os.path.exists(_AVIF_TOOL) or os.path.getmtime(_AVIF_TOOL) < os.path.getmtime(src):
                subprocess.run(['swiftc', '-O', src, '-o', _AVIF_TOOL], check=True, capture_output=True)
            _AVIF_OK = True
        except (OSError, subprocess.CalledProcessError):
            _AVIF_OK = False
    return _AVIF_OK


def avif_copy(rel):
    """assets/images/... .png|.jpg -> .avif next to it (quality 0.7), rebuilt only when the original is newer. Returns the .avif path or None."""
    src = os.path.join(OUT, rel)
    dst = os.path.splitext(src)[0] + '.avif'
    if not os.path.exists(src):
        return None
    if not os.path.exists(dst) or os.path.getmtime(dst) < os.path.getmtime(src):
        if not _avif_ready():
            return None
        try:
            subprocess.run([_AVIF_TOOL, '0.7', src], check=True, capture_output=True)
        except (OSError, subprocess.CalledProcessError):
            return None
    return os.path.splitext(rel)[0] + '.avif' if os.path.exists(dst) else None


_IMG = re.compile(r'<img\b[^>]*>')
_ATTR = lambda tag, name: (re.search(r'\s' + name + r'="([^"]*)"', tag) or [None, None])[1]
ALT_SEEN = set()
_ALT_CTX = [('class="hero', 'the hero walkthrough'), ('id="how-it-works"', 'the five-step guide'), ('id="screenshots"', 'the screens gallery'),
            ('id="details"', 'the detailed guide'), ('id="your-data"', 'the backup section'), ('id="features"', 'the features section')]


def pictures_and_alts(doc):
    """AVIF <source> for each local screenshot or logo, and an alt text that is never the same as one already used on another picture."""
    out, last, n = [], 0, 0
    for m in _IMG.finditer(doc):
        tag = m.group(0)
        out.append(doc[last:m.start()])
        last = m.end()
        # a different alt when the same words were already used (another page, or another place on this page)
        alt = _ATTR(tag, 'alt')
        if alt:
            if alt in ALT_SEEN:
                before = doc[:m.start()]
                label = next((l for k, l in sorted(((before.rfind(k), l) for k, l in _ALT_CTX), reverse=True) if k >= 0), None) or 'another view'
                new, i = f'{html.unescape(alt)} ({label})', 2
                while esc(new) in ALT_SEEN:
                    new, i = f'{html.unescape(alt)} ({label}, view {i})', i + 1
                tag = tag.replace(f'alt="{alt}"', f'alt="{esc(new)}"', 1)
                alt = esc(new)
            ALT_SEEN.add(alt)
        # AVIF versions
        src, srcset, sizes = _ATTR(tag, 'src'), _ATTR(tag, 'srcset'), _ATTR(tag, 'sizes')
        def to_avif(u):
            path, _, q = u.partition('?')
            if not path.startswith('assets/images/') or not path.endswith(('.png', '.jpg')) or path.endswith(('icon-192.png', 'icon-512.png', 'favicon-32.png', 'apple-touch-icon.png', 'og-image.png')):
                return None
            a = avif_copy(path)
            return asset(a) if a else None
        if src and 'data:' not in src:
            parts = [x.strip() for x in (srcset or src).split(',')]
            conv = []
            for part in parts:
                u, _, desc = part.partition(' ')
                v = to_avif(u)
                if v is None:
                    conv = None
                    break
                conv.append(f'{v} {desc}'.strip())
            if conv:
                so = f'<source type="image/avif" srcset="{", ".join(conv)}"' + (f' sizes="{sizes}"' if sizes and srcset else '') + '>'
                tag = f'<picture>{so}{tag}</picture>'
                n += 1
        out.append(tag)
    out.append(doc[last:])
    return ''.join(out)


def page(filename, title, description, active, body, jsonld=None, noindex=False, lang='en', crumb=None, page_type='WebPage'):
    """crumb: the page's name in its Home > Page breadcrumb (inner pages only).
    jsonld: one schema.org object or a list; every page also gets a WebPage
    (or the given page_type) with its language and dateModified."""
    home = filename in HOMES.values()
    canonical = SITE + '/' + ('' if filename == 'index.html' else filename)
    full_title = title if home or NAME in title else f'{title} — {NAME}'
    modified = PAGE_UPDATED.get(filename, max(RELEASE_ISO, SITE_UPDATED_ISO))
    PAGE_MODIFIED[filename] = modified
    blocks = [dict(b) for b in (jsonld if isinstance(jsonld, list) else [jsonld] if jsonld else [])]
    webpage = {'@type': page_type, '@id': canonical + '#webpage', 'url': canonical, 'name': full_title,
               'description': description, 'inLanguage': lang, 'dateModified': modified,
               'isPartOf': {'@type': 'WebSite', '@id': SITE + '/#website', 'name': NAME, 'url': SITE + '/'},
               'publisher': ORG_REF}
    if crumb:
        webpage['breadcrumb'] = {'@id': canonical + '#breadcrumb'}
    if home:
        webpage['mainEntity'] = {'@id': SOFTWARE_ID}
    # A page that is already a kind of WebPage (FAQPage) gets the fields itself.
    own = next((b for b in blocks if b.get('@type') in ('FAQPage', 'ContactPage', 'AboutPage')), None)
    if own:
        own.update({k: v for k, v in webpage.items() if k != '@type'})
    else:
        blocks.append({'@context': 'https://schema.org', **webpage})
    if crumb:
        blocks.append({'@context': 'https://schema.org', '@type': 'BreadcrumbList', '@id': canonical + '#breadcrumb',
                       'itemListElement': [
                           {'@type': 'ListItem', 'position': 1, 'name': 'Home', 'item': SITE + '/'},
                           {'@type': 'ListItem', 'position': 2, 'name': crumb, 'item': canonical}]})
    ld = ''.join('\n  <script type="application/ld+json">\n' + json.dumps(b, ensure_ascii=False, indent=2) + '\n  </script>'
                 for b in blocks)
    # The home pages name each other, so Google shows Tamil and Hindi searchers their own.
    alternates = ''
    if home:
        alternates = ''.join(f'\n  <link rel="alternate" hreflang="{code}" href="{SITE}/{"" if f == "index.html" else f}">'
                             for code, f in HOMES.items())
        alternates += f'\n  <link rel="alternate" hreflang="x-default" href="{SITE}/">'
    doc = f'''<!doctype html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">{chr(10) + '  <base href="/">' if noindex else ''}
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <meta name="theme-color" content="#ffffff">
  <title>{esc(full_title)}</title>
  <meta name="description" content="{esc(description)}">
  {'<meta name="robots" content="noindex">' if noindex else f'<link rel="canonical" href="{canonical}">'}{alternates}
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="{NAME}">
  <meta property="og:locale" content="{TEXT[lang]['shell']['og_locale']}">
  <meta property="og:title" content="{esc(full_title)}">
  <meta property="og:description" content="{esc(description)}">
  <meta property="og:url" content="{canonical}">
  <meta property="og:image" content="{SITE}/assets/images/og-image.png">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{esc(full_title)}">
  <meta name="twitter:description" content="{esc(description)}">
  <meta name="twitter:image" content="{SITE}/assets/images/og-image.png">
  <link rel="alternate" type="text/markdown" href="/llms.txt" title="llms.txt">
  <link rel="icon" href="favicon.ico" sizes="any">
  <link rel="icon" type="image/png" sizes="32x32" href="assets/images/favicon-32.png">
  <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
  <link rel="manifest" href="site.webmanifest">
  {FONT_LINKS[TEXT[lang]['shell']['fonts']]}
  <link rel="stylesheet" href="{asset('assets/css/site.css')}">{ld}
</head>
<body data-consent="{'on' if CONSENT_BANNER else 'off'}">
{header(active, home=home, base=noindex, lang=lang)}
<main id="main">
{body}
</main>
{footer(home=home, lang=lang)}
<script src="{asset('assets/js/config.js')}"></script>
<script src="{asset('assets/js/site.js')}"></script>
</body>
</html>
'''
    doc = pictures_and_alts(doc)
    with open(os.path.join(OUT, filename), 'w', encoding='utf-8') as f:
        f.write(doc)


def page_head(eyebrow, title, lead=None, extra=''):
    lead_html = f'<p class="lead">{lead}</p>' if lead else ''
    return (f'<section class="page-head">\n  <div class="wrap">\n    <p class="eyebrow">{eyebrow}</p>\n    <h1>{title}</h1>\n'
            f'    {lead_html}{extra}\n  </div>\n</section>')


def byline(iso=None):
    """A visible author line for content pages: written by the business, with the date of the last update."""
    iso = iso or SITE_UPDATED_ISO
    return (f'<p class="byline">By <a rel="author" href="about.html">{BUSINESS}</a> · Last updated '
            f'<time datetime="{iso}">{int(iso[8:])} {MONTHS[int(iso[5:7]) - 1]} {iso[:4]}</time></p>')


ORG_ID = SITE + '/#organization'
SOFTWARE_ID = SITE + '/#software'
ORG_REF = {'@type': 'Organization', '@id': ORG_ID, 'name': BUSINESS, 'url': SITE + '/'}
# Only facts the site already shows. sameAs: the business's own Buy Me a Coffee page (the only public profile the site links).
ORG = {'@type': 'Organization', '@id': ORG_ID, 'name': BUSINESS, 'email': EMAIL, 'url': SITE + '/',
       'logo': {'@type': 'ImageObject', 'url': SITE + '/assets/images/icon-512.png', 'width': 512, 'height': 512},
       'description': f'{BUSINESS} makes {NAME}, free and open-source billing software, and builds paid custom features '
                      'for businesses on request.',
       'sameAs': ['https://buymeacoffee.com/madcreations'],
       'knowsLanguage': ['en', 'ta', 'hi'],
       'address': {'@type': 'PostalAddress', 'addressCountry': 'IN'},
       'contactPoint': {'@type': 'ContactPoint', 'contactType': 'customer support', 'email': EMAIL,
                        'url': SITE + '/contact.html'}}
def nav_ld(lang):
    """The main menu as SiteNavigationElement entries (names and addresses exactly as in the header)."""
    items = []
    for text, href, _key in TEXT[lang]['header']['links']:
        href = href.replace('{pre}', '')
        url = SITE + '/' + (HOMES[lang] if href.startswith('#') and lang != 'en' else '') + (href if href.startswith('#') else href.lstrip('/'))
        items.append({'@type': 'SiteNavigationElement', 'name': html.unescape(text), 'url': url})
    return {'@context': 'https://schema.org', '@graph': items}


# The app's own languages (English, Tamil, Hindi, Nepali, French, Spanish, Chinese, Tibetan).
APP_LANGS = ['en', 'ta', 'hi', 'ne', 'fr', 'es', 'zh', 'bo']
WEBSITE_LD = {'@context': 'https://schema.org', '@type': 'WebSite', '@id': SITE + '/#website', 'name': NAME,
              'url': SITE + '/', 'inLanguage': list(HOMES),
              'description': f'{NAME}: free, open-source offline invoicing software for Windows, macOS and Linux, with your own tax rates (GST, VAT or sales tax) and your choice of 156 currencies.',
              'publisher': {'@id': ORG_ID}}


def software_ld(description, groups, shot=lambda n: n):
    """SoftwareApplication for a home page. groups: that page's feature groups.
    One @id and url on all three home pages, so they describe the same app."""
    return {
        '@context': 'https://schema.org',
        '@type': 'SoftwareApplication',
        '@id': SOFTWARE_ID,
        'name': NAME,
        'applicationCategory': 'BusinessApplication',
        'applicationSubCategory': 'Billing and invoicing software',
        'operatingSystem': 'Windows 10, Windows 11, macOS 12 or later, Linux',
        'softwareVersion': VERSION,
        'datePublished': RELEASE_ISO,
        'description': description,
        'url': SITE + '/',
        'downloadUrl': SITE + '/download.html',
        'releaseNotes': SITE + '/changelog.html',
        'image': SITE + '/assets/images/og-image.png',
        'screenshot': [f'{SITE}/assets/images/screens/{shot(n)}.png' for n in screen_cards],
        'featureList': [html.unescape(strip_tags(item)) for _, _, items, _ in groups for item in items],
        'inLanguage': APP_LANGS,
        'isAccessibleForFree': True,
        'license': 'https://opensource.org/licenses/MIT',
        'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'INR'},
        'publisher': ORG,
    }

# ─────────────────────────────── Testimonials ──────────────────────────────
# Real customers only, with their permission, in words they have approved.
# Never add one that is not real and approved (made-up reviews are also
# against Indian consumer rules). Green & Green Agri Solutions: name shown
# with their OK (13 Oct 2026); the wording was written from their own message
# and approved for use (owner's confirmation, 13 Oct 2026).
TESTIMONIALS = [{
    'name': 'Green &amp; Green Agri Solutions',
    'initial': 'G',
    'about': {'en': 'Agricultural products and solar power · Udumalai',
              'ta': 'விவசாயப் பொருட்கள், சூரிய மின் உற்பத்தி · உடுமலை'},
    'quote': {'en': 'We approached many software companies for our energy billing, but their quotes were too high. '
                    'Invoiceo built exactly what we needed, within our budget. Our monthly bill is now simple to make. '
                    'It’s the perfect solution for us.',
              'ta': 'எங்கள் மின் (energy) பில்லிங்கிற்காகப் பல மென்பொருள் நிறுவனங்களை அணுகினோம்; ஆனால் அவர்கள் சொன்ன '
                    'விலை மிக அதிகம். எங்களுக்குத் தேவையானதை Invoiceo எங்கள் பட்ஜெட்டுக்குள் சரியாக உருவாக்கித் தந்தது. '
                    'இப்போது மாதாந்திர பில் போடுவது எளிது. எங்களுக்கு இதுவே சரியான தீர்வு.'},
    'tag': {'en': 'Custom energy bill', 'ta': 'தனிப்பயன் மின் பில்'},
    # What we made for them (the Customization page's Recent work section).
    'link': 'customization.html#work',
}]


def testimonial_card(t, lang='en', link=True):
    # The Tamil page shows a translation of the customer's English words, and says so.
    note = {'ta': '<p class="testimonial-note">ஆங்கிலத்திலிருந்து தமிழாக்கம்</p>',
            'hi': '<p class="testimonial-note">ग्राहक के अपने शब्द, अंग्रेज़ी में</p>'}.get(lang, '')
    lang = 'en' if lang == 'hi' else lang       # not translated: their words are shown as they wrote them
    name = (f'<a href="{t["link"]}">{t["name"]}</a>' if link and t.get('link') else t['name'])
    return (f'<figure class="testimonial"><blockquote><p>{t["quote"][lang]}</p></blockquote>{note}'
            f'<figcaption><span class="testimonial-mark" aria-hidden="true">{t["initial"]}</span>'
            f'<span><b>{name}</b><span>{t["about"][lang]}</span></span></figcaption>'
            f'{badge(t["tag"][lang], "teal", "tool")}</figure>')


# Small decorative pictures for the "Why" cards, keyed by the card's icon (same in every language).
# They carry no words that need translating, and are hidden from screen readers.
WHY_ART = {
    'gift': '<div class="art art-free" aria-hidden="true"><span class="big"><b>₹0</b><b>$0</b><b>€0</b><b>£0</b></span>'
            '<span class="coin c1"><i>₹</i><i>$</i><i>€</i><i>£</i></span><span class="coin c2"><i>$</i><i>€</i><i>£</i><i>₹</i></span>'
            '<span class="coin c3"><i>€</i><i>£</i><i>₹</i><i>$</i></span><span class="inf">∞</span></div>',
    'wifi-off': '<div class="art art-offline" aria-hidden="true"><i></i><i></i><i></i><b></b></div>',
    'lock': '<div class="art art-data" aria-hidden="true"><span></span><span></span><span></span><b></b></div>',
    'code': '<div class="art art-code" aria-hidden="true"><span style="width:58%"></span><span style="width:82%"></span>'
            '<span style="width:46%"></span><span style="width:70%"></span><em>MIT</em></div>',
    'monitor': '<div class="art art-os" aria-hidden="true"><em>Windows</em><em>macOS</em><em>Linux</em></div>',
    'repeat': '<div class="art art-export" aria-hidden="true"><em>CSV</em><em>PDF</em><em class="loop">↻</em></div>',
}


def why_card(i, t, d):
    return f'<div class="card why-card why-{i}">{tile(i)}<h3>{t}</h3><p>{d}</p>{WHY_ART.get(i, "")}</div>'



# Features cards: a colour accent, a counter and a small picture for each group (same icons in every language).
# The pictures use symbols, numbers and universal abbreviations only, and are hidden from screen readers.
GROUP_ART = {
    'file': '<div class="gart gart-designs" aria-hidden="true">' + ''.join(f'<i class="d{n}"></i>' for n in range(1, 7)) + '<b class="th"></b></div>',
    'briefcase': '<div class="gart gart-biz" aria-hidden="true"><span><i></i>₹ 4,495</span><span><i></i>₹ 962</span>'
                 '<span><i class="due"></i>₹ 1,426</span><em class="bars"><u></u><u></u><u></u><u></u><u></u></em></div>',
    'percent': '<div class="gart gart-gst" aria-hidden="true"><span>CGST 9%</span><span>SGST 9%</span><span class="alt">IGST 18%</span></div>',
    'hard-drive': '<div class="gart gart-local" aria-hidden="true"><span class="f"></span><span class="f"></span><span class="f"></span><b></b></div>',
    'globe': '<div class="gart gart-world" aria-hidden="true"><span>EN</span><span>த</span><span>हि</span><span>₹</span><span>$</span><span>€</span></div>',
}


def group_card(i, t, items, c):
    return (f'<div class="group-card gc gc-{i} {c}"><div class="group-card-head">{tile(i)}<h3>{t}</h3>'
            f'<span class="gc-count" aria-hidden="true">{len(items):02d}</span></div>{checks(items)}{GROUP_ART.get(i, "")}</div>')



def png_size(path):
    with open(path, 'rb') as f:
        head = f.read(24)
    return int.from_bytes(head[16:20], 'big'), int.from_bytes(head[20:24], 'big')


# The energy bill we built for them, printed with made-up data (Recent work,
# Reviews and the Tamil home show it).
_energy_png = 'assets/images/docs/energy-bill.png'
_ew, _eh = png_size(os.path.join(OUT, _energy_png))


# Recent custom work. The picture is the real energy bill PDF code printing
# made-up companies and numbers (never a customer's real bill).
ENERGY_WORK = [
    'Units generated, units allotted and the net units billed at the month’s rate',
    'The month’s deductions under “Less:” — transmission, wheeling, scheduling, meter reading and more — '
    'as fixed amounts or per unit, like the 10-paise self-generation tax',
    'Total expenses, round off and the net amount, with the amount in words',
    'Remembers last month’s wording, rate and deductions, so each new bill needs only the new numbers',
    'Bill numbers in the company’s own style, starting again each financial year (for example ABC/26-27/001)',
    'Saved like any invoice, so payments, balances and reports work as usual',
]

# Recent custom work, second example: sales and purchase on one bill. The picture
# is the real receipt printing code with a made-up shop and customer (never a
# customer's real bill). The customer is named only once they agree
# (AMMA_NAMED); until then the page says "a farm-products shop in Tamil Nadu".
AMMA_NAMED = False
AMMA_WHO = 'Amma Organics, Mannargudi' if AMMA_NAMED else 'a farm-products shop in Tamil Nadu'
_amma_png = 'assets/images/docs/receipt-sale-purchase.png'
_aw, _ah = png_size(os.path.join(OUT, _amma_png))
AMMA_WORK = [
    'Sale and Purchase items on the same bill: the shop sells to the customer and also buys from the same customer',
    'Purchase items use the product’s buying price, and the rate can be changed on the bill',
    'Grand Total = Sales − Purchase, shown as “Pay customer” when the shop owes the customer',
    'Stock goes down on a sale and up on a purchase, and is corrected if a bill is edited or deleted',
    'Receipt for 58 mm and 80 mm thermal printers, with a SALES and a PURCHASE section',
    'No GST on the bill, and it works with the products already in the app',
]


# Drawn printers for the sample documents (shown only when the screens are tabs; the page or receipt is fed out of them).
PRINTERS = {
    'paper-a4': (
        '<svg class="printer-art printer-a4" viewBox="0 0 600 160" aria-hidden="true" focusable="false">'
        '<defs><linearGradient id="pg-a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f7f9fd"/><stop offset="1" stop-color="#cfd7e6"/></linearGradient>'
        '<linearGradient id="pg-b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e4e9f3"/><stop offset="1" stop-color="#b9c3d6"/></linearGradient></defs>'
        '<rect x="34" y="132" width="60" height="16" rx="6" fill="#8e9ab2"/><rect x="506" y="132" width="60" height="16" rx="6" fill="#8e9ab2"/>'
        '<rect x="14" y="46" width="572" height="94" rx="24" fill="url(#pg-a)" stroke="#bcc6d9" stroke-width="2"/>'
        '<rect x="34" y="34" width="532" height="30" rx="14" fill="url(#pg-b)" stroke="#bcc6d9" stroke-width="2"/>'
        '<rect x="48" y="42" width="504" height="13" rx="6.5" fill="#0c1226"/>'
        '<rect x="48" y="52" width="504" height="3" fill="#000" opacity=".5"/>'
        '<rect x="96" y="104" width="300" height="9" rx="4.5" fill="#cbd3e3"/>'
        '<rect x="438" y="82" width="116" height="40" rx="9" fill="#18213b"/>'
        '<circle class="led" cx="458" cy="102" r="5.5" fill="#2fe39a"/><circle cx="480" cy="102" r="5.5" fill="#5b6a8c"/>'
        '<rect x="500" y="95" width="40" height="14" rx="4" fill="#2a3556"/></svg>'),
    'paper-receipt': (
        '<svg class="printer-art printer-thermal" viewBox="0 0 360 170" aria-hidden="true" focusable="false">'
        '<defs><linearGradient id="pg-t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a4668"/><stop offset="1" stop-color="#151c33"/></linearGradient></defs>'
        '<rect x="20" y="146" width="44" height="14" rx="6" fill="#0d1224"/><rect x="296" y="146" width="44" height="14" rx="6" fill="#0d1224"/>'
        '<rect x="8" y="54" width="344" height="100" rx="20" fill="url(#pg-t)"/>'
        '<rect x="8" y="54" width="344" height="1.5" fill="#fff" opacity=".28"/>'
        '<rect x="36" y="38" width="288" height="30" rx="12" fill="#222c4a"/>'
        '<rect x="52" y="46" width="256" height="12" rx="6" fill="#04070f"/>'
        '<path d="M52 58h256" stroke="#000" stroke-width="3" opacity=".5"/>'
        '<rect x="30" y="112" width="190" height="8" rx="4" fill="#2c3858"/>'
        '<circle class="led" cx="292" cy="100" r="6" fill="#2fe39a"/><circle cx="292" cy="124" r="7" fill="#2c3858" stroke="#4a5880" stroke-width="2"/></svg>'),
}


def paper(name, cls, alt):
    src = f'assets/images/docs/{name}.png'
    w, h = png_size(os.path.join(OUT, src))
    v = asset(src)  # path?v=<content hash>: a changed picture is fetched again, not shown from a visitor's cache
    return (f'<div class="paper {cls}"><a href="{v}" target="_blank" rel="noopener" title="Open full size">'
            f'<img src="{v}" width="{w}" height="{h}" alt="{esc(alt)}" loading="lazy" decoding="async"></a>'
            f'{PRINTERS.get(cls, "")}</div>')



# ───────────── "How it works": the steps drive a picture that changes with the step ─────────────
def stage_docs(a4_alt, receipt_alt):
    """Step 4's picture: the printed A4 invoice and the 80 mm thermal receipt side by side."""
    a4, rc = 'assets/images/docs/invoice-a4.png', 'assets/images/docs/receipt-80mm.png'
    aw, ah = png_size(os.path.join(OUT, a4))
    rw, rh = png_size(os.path.join(OUT, rc))
    return (f'<div class="doc-stage"><img class="ds-a4" src="{asset(a4)}" width="{aw}" height="{ah}" alt="{esc(a4_alt)}" loading="lazy" decoding="async">'
            f'<img class="ds-rc" src="{asset(rc)}" width="{rw}" height="{rh}" alt="{esc(receipt_alt)}" loading="lazy" decoding="async"></div>')


def how_flow(head_html, steps, pictures, word, extra=''):
    """The steps on the left, one picture on the right. site.js switches the picture when a step is
    clicked or scrolled to. Every picture is also placed inside its step, shown on phones instead."""
    lis = ''.join(f'<li class="step{" is-active" if i == 0 else ""}" data-step="{i}" tabindex="0"><span class="step-num">{n}</span>'
                  f'<div><h3>{t}</h3><p>{b}</p><div class="step-shot">{pictures[i]}</div></div></li>' for i, (n, t, b) in enumerate(steps))
    stage = ''.join(f'<div class="stage-item{" is-active" if i == 0 else ""}" data-stage="{i}"{"" if i == 0 else " inert"}>{pic}</div>' for i, pic in enumerate(pictures))
    dots = ''.join(f'<button type="button" class="stage-dot{" is-active" if i == 0 else ""}" data-step="{i}" aria-label="{word} {i + 1}"></button>'
                   for i in range(len(pictures)))
    return section('<div class="flow flow-steps"><div class="flow-copy">' + head_html + f'<ol class="steps">{lis}</ol>{extra}</div>'
                   f'<div class="flow-stage"><div class="stage-sticky"><div class="stage">{stage}</div><div class="stage-dots">{dots}</div></div></div></div>',
                   'how-it-works', 'section-subtle', 'how-title')


_HW = '(max-width: 900px) 100vw, 640px'

def usecase_card(n, i, t, d):
    """A "who it is for" card: a colour accent per business, a big faded icon behind it, and a number."""
    return (f'<div class="usecase uc uc-{i}">{tile(i, "neutral")}<div><h3>{t}</h3><p>{d}</p></div>'
            f'<span class="uc-mark" aria-hidden="true">{icon(i)}</span><span class="uc-n" aria-hidden="true">{n:02d}</span></div>')



LANGS = [('English', ''), ('தமிழ்', 'ta'), ('हिन्दी', 'hi'), ('Nepali', ''), ('French', ''), ('Spanish', ''), ('Chinese', ''), ('Tibetan', '')]
langs = ''.join(f'<span class="chip"{(" lang=" + chr(34) + l + chr(34)) if l else ""}>{t}</span>' for t, l in LANGS)

# ───────────────────── Comparison (home teaser, "not built in") ─────────────────────
COMPARE_CHECKED = '31 October 2026'
compare_home = section(
    section_head('How it compares', 'Free means free here',
                 'Some free billing software limits the free plan or ends after a short trial. Invoiceo does not.', 'cmp-title')
    + '<div class="grid-auto mt-4">'
    + '<div class="card cmp-card">'
    + '<div class="art art-limit" aria-hidden="true">'
      '<div class="row"><span>10 a month</span><div class="trk"><i style="width:22%"></i></div></div>'
      '<div class="row"><span>7-day trial</span><div class="trk"><i style="width:9%"></i></div></div>'
      '<div class="row us"><span>Invoiceo</span><div class="trk"><i style="width:100%"></i></div><b>∞</b></div></div>'
    + f'{tile("gift")}<h3>No invoice limit, no trial</h3><p>Some free plans allow only a few documents a month (for example 10), or are a 7-day trial. {NAME} has no limit and no end date, on as many computers as you like.</p></div>'
    + '<div class="card cmp-card">'
    + '<div class="art art-private" aria-hidden="true"><em class="no">Cloud</em><span class="dash"></span><em class="yes">Your PC</em></div>'
    + f'{tile("lock")}<h3>Offline and private</h3><p>Your data stays on your computer. There is no sign-up and no cloud account, and it is open source, so anyone can check what it does.</p></div>'
    + '<div class="card cmp-card">'
    + '<div class="art art-world" aria-hidden="true"><em>₹</em><em>$</em><em>€</em><em>£</em><em class="tg">GST on / off<b></b></em></div>'
    + f'{tile("globe")}<h3>Works wherever you bill</h3><p>GST invoices, or turn GST off and bill in one of 156 currencies. Eight app languages, and A4 or 58/80 mm thermal printing, on Windows, macOS and Linux.</p></div>'
    + '</div>'
    + f'<p class="center mt-3">{btn("See the side-by-side comparison", "compare.html", "secondary", "", "arrow")}</p>',
    'compare', '', 'cmp-title')

NOT_YET = ['GSTR-1 and GSTR-3B files, e-invoice and e-way bill',
           'Sending an invoice on WhatsApp or email from inside the app',
           'A phone app (it runs on Windows, macOS and Linux computers)',
           'A supplier and purchase section (the app records sales)',
           'Live sharing of data between computers, or a cloud version',
           'Ledgers, balance sheet and full accounting']


# ──────────────── Home pages: ONE template, one text file per language (tool/site_text/*.py) ────────────────
SCREEN_NAMES = ['dashboard', 'create-invoice', 'invoices', 'customers', 'products', 'reports']
DOC_NAMES = [('invoice-a4', 'paper-a4'), ('receipt-80mm', 'paper-receipt')]   # (file name, picture style)
DOCS = os.path.join(OUT, 'assets', 'images', 'docs')
screen_cards = [n for n in SCREEN_NAMES if os.path.exists(os.path.join(SCREENS, n + '.png'))]
doc_cards = [(n, cls) for n, cls in DOC_NAMES if os.path.exists(os.path.join(DOCS, n + '.png'))]
# Extra home sections that exist in one language only (the English "Free means free here" comparison teaser).
HOME_EXTRA = {'en': {'compare': compare_home}}
HOME_ORDER = ['hero', 'facts', 'why', 'compare', 'how', 'features', 'shots', 'who', 'lang', 'download', 'cta']


def shot_file(name, lang):
    """The app screenshot for a language: <name>-<lang>.png when it exists (the app shown in that language), else <name>.png."""
    if lang != 'en' and os.path.exists(os.path.join(SCREENS, f'{name}-{lang}.png')):
        return f'{name}-{lang}'
    return name


def home_sections(lang):
    T = TEXT[lang]
    shot = lambda n: shot_file(n, lang)
    sec = {}
    # hero
    h = T['hero']
    sec['hero'] = f"""<section class="hero" aria-labelledby="hero-title">
  <div class="wrap hero-grid">
    <div class="hero-copy">
      <div class="badges">{badge(h['badge'], 'brand', 'code')}{badge('Windows · macOS · Linux', 'neutral', 'monitor')}</div>
      <h1 class="display" id="hero-title">{h['h1']}</h1>
      <p class="lead">{h['lead']}</p>
      <div class="cta-row">
        <a class="btn btn-primary btn-lg" href="#download" data-os-download><span data-os-icon>{icon('download')}</span><span data-os-label>{h['dl_label']}</span></a>
        {btn(h['features_btn'], '#features', 'secondary', 'lg')}
      </div>
      {hero_send(lang)}
      <p class="hero-meta" data-hero-meta>{h['meta'].replace('{version}', VERSION)}</p>
      {checks(h['checks'], 'checks-inline')}
    </div>
    <div class="hero-visual">
      {hero_tour(lang, h['alt'], h['tour'])}
      <div class="print-out">{receipt('', lang)}<span class="printer" aria-hidden="true"><i></i></span></div>
      <span class="hero-chip">{badge(h['chip'], 'teal', 'lock')}</span>
    </div>
  </div>
</section>"""
    # facts strip
    sec['facts'] = ('<div class="facts-strip"><ul class="wrap facts">'
                    + ''.join(f'<li class="fact">{tile(i, "teal", "md")}<div><b>{v}</b><span>{l}</span></div></li>' for i, v, l in T['facts'])
                    + '</ul></div>')
    # why
    w = T['why']
    sec['why'] = section(section_head(w['eyebrow'], w['title'], w['lead'], 'why-title')
                         + '<div class="why-grid mt-4">' + ''.join(why_card(i, t, d) for i, t, d in w['cards']) + '</div>',
                         'why', 'section-flush', 'why-title')
    # how it works
    hw = T['how']
    docs = T['shots']['docs']
    sec['how'] = how_flow(
        section_head(hw['eyebrow'], hw['title'], hw['lead'], 'how-title', left=True), hw['steps'],
        [window(shot('company-info'), hw['alts'][0], sizes=_HW),
         window(shot('products'), hw['alts'][1], sizes=_HW),
         window(shot('create-invoice'), hw['alts'][2], sizes=_HW),
         stage_docs(docs['invoice-a4'][2], docs['receipt-80mm'][2]),
         window(shot('invoices'), hw['alts'][3], sizes=_HW)],
        hw['word'],
        extra=(f'<p class="flow-more">{btn(hw["more"][0], hw["more"][1], "secondary", "", "arrow")}</p>' if hw.get('more') else ''))
    # features
    f = T['features']
    sec['features'] = section(section_head(f['eyebrow'], f['title'], f['lead'], 'feat-title')
                              + '<div class="bento mt-4">' + ''.join(group_card(i, t, items, c) for i, t, items, c in f['groups']) + '</div>',
                              'features', '', 'feat-title')
    # screenshots
    sh = T['shots']
    sec['shots'] = section(section_head(sh['eyebrow'], sh['title'], sh['lead'], 'shots-title')
                           + '<div class="shots mt-4">'
                           + ''.join(f'<figure class="shot{" shot-wide" if i == 0 and doc_cards else ""}">'
                                     f'{window(shot(n), sh["screen_alt"].format(name=NAME, t=sh["screens"][n][0]))}'
                                     f'<figcaption><b>{sh["screens"][n][0]}</b><span>{sh["screens"][n][1]}</span></figcaption></figure>'
                                     for i, n in enumerate(screen_cards))
                           + ''.join(f'<figure class="shot">{paper(n, cls, docs[n][2])}<figcaption><b>{docs[n][0]}</b><span>{docs[n][1]}</span></figcaption></figure>'
                                     for n, cls in doc_cards)
                           + '</div>',
                           'screenshots', 'section-subtle', 'shots-title')
    # who it is for
    wh = T['who']
    sec['who'] = section(section_head(wh['eyebrow'], wh['title'], hid='who-title')
                         + '<div class="grid-auto-wide mt-4">' + ''.join(usecase_card(n + 1, i, t, d) for n, (i, t, d) in enumerate(wh['items'])) + '</div>',
                         'who', '', 'who-title')
    # languages and local billing rules
    ls = T['lang_section']
    cards = ''
    for c in ls['cards']:
        chips = (f'<div class="stack" style="gap:10px"><p class="chips-label">{c["chips_label"]}</p><div class="chips">{langs}</div></div>'
                 if c['chips_label'] else '')
        cards += (f'<div class="group-card is-subtle lg lg-{c["icon"]}"><div class="group-card-head">{tile(c["icon"])}<h3>{c["title"]}</h3></div>'
                  f'{checks(c["items"])}{chips}</div>')
    sec['lang'] = section(section_head(ls['eyebrow'], ls['title'], ls['lead'], 'lg-title')
                          + '<div class="split split-stretch mt-4">' + cards + '</div>', ls['id'], '', 'lg-title')
    # download
    d = T['download']
    date = fmt_release_date(lang)
    trust = '<div class="dl-trust">' + ''.join(badge(t, 'teal', 'check') for t in d['trust']) + '</div>'
    sec['download'] = section(
        section_head(d['eyebrow'], d['title'], d['lead'].format(name=NAME, version=VERSION, date=date), 'dl-title')
        + f'<div class="mt-2">{trust}</div><div class="mt-2">{phone_note(lang)}</div>'
        + f'<div class="mt-3">{dl_grid(full=d["full"], lang=lang)}</div>'
        + f'<div class="mt-2">{d["checksums"].replace("{url}", DL + "SHA256SUMS.txt")}</div>'
        + (f'<p class="center small mt-1">{d["help"]}</p>' if d['help'] else '')
        + f'<h3 class="h3 center" style="margin: 72px 0 20px">{d["h3"]}</h3>'
        + first_steps('h4', d['first_steps'], T['how']['word']),
        'download', 'section-subtle', 'dl-title')
    # closing call to action
    c = T['cta']
    sec['cta'] = f"""<section class="cta-section" aria-labelledby="cta-title">
  <div class="wrap">
    <div class="cta-band">
      <h2 id="cta-title">{c['title']}</h2>
      <p class="lead">{c['lead']}</p>
      <div class="cta-row">
        {btn(c['download'], '#download', 'inverse', 'lg', 'download')}
        {btn(c['contact'], 'contact.html', 'on-dark', 'lg', 'message')}
      </div>
      <p class="cta-meta">{c['meta'].replace('{version}', VERSION)}</p>
      {checks(c['checks'], 'checks-inline')}
    </div>
  </div>
</section>"""
    sec.update(HOME_EXTRA.get(lang, {}))
    return sec


for _lang in HOME_LANGS:
    _T = TEXT[_lang]
    _sec = home_sections(_lang)
    if _lang == 'en':
        EN, EN_HOME = _T, _sec          # the English text and sections, for the AI-summary files at the end
    page(HOMES[_lang], _T['page']['title'], _T['page']['description'], 'home',
         '\n\n'.join(_sec[k] for k in HOME_ORDER if k in _sec),
         lang=_lang,
         jsonld=[software_ld(_T['page']['jsonld_description'], _T['features']['groups'], lambda n, _l=_lang: shot_file(n, _l)),
                 WEBSITE_LD, nav_ld(_lang)])

# ──────────────────────────────── Download ─────────────────────────────────

# ── Windows warning: picture guide (Download page) ──────────────────────────
# The installer is not code-signed, so Windows SmartScreen asks first. These are our own
# drawings of the two screens (no Microsoft artwork); the words are the ones Windows shows.
_RING = 'fill="none" stroke="#f59e0b" stroke-width="3"'
_DLG = ('<rect x="10" y="10" width="300" height="180" rx="8" fill="#0b5cad"/>'
        '<text x="28" y="40" fill="#fff" font-size="15" font-weight="700">Windows protected your PC</text>'
        '<text x="28" y="62" fill="#d6e6fa" font-size="9.5">Microsoft Defender SmartScreen prevented an</text>'
        '<text x="28" y="76" fill="#d6e6fa" font-size="9.5">unrecognised app from starting.</text>')
WIN_PIC_1 = ('<svg class="warn-pic" viewBox="0 0 320 200" role="img" aria-label="The downloaded file Invoiceo-Setup-Windows.exe in a folder">'
             '<rect x="0" y="0" width="320" height="200" rx="12" fill="#f3f6fb"/>'
             '<rect x="40" y="50" width="240" height="96" rx="12" fill="#fff" stroke="#cbd5e1"/>'
             '<rect x="58" y="70" width="44" height="44" rx="10" fill="#1f6feb"/>'
             '<path d="M72 92h16m-8-8v16" stroke="#fff" stroke-width="3" stroke-linecap="round"/>'
             '<text x="114" y="88" fill="#142033" font-size="12" font-weight="700">Invoiceo-Setup-Windows.exe</text>'
             '<text x="114" y="108" fill="#5b687c" font-size="11">Double-click to open</text>'
             '<circle cx="232" cy="124" r="14" ' + _RING + '/></svg>')
WIN_PIC_2 = ('<svg class="warn-pic" viewBox="0 0 320 200" role="img" aria-label="The blue Windows protected your PC window with the More info link highlighted">'
             '<rect x="0" y="0" width="320" height="200" rx="12" fill="#f3f6fb"/>' + _DLG +
             '<text x="28" y="110" fill="#fff" font-size="11" text-decoration="underline">More info</text>'
             '<rect x="20" y="96" width="62" height="22" rx="6" ' + _RING + '/>'
             '<rect x="218" y="152" width="76" height="24" rx="4" fill="#fff" opacity=".18"/>'
             '<text x="256" y="168" fill="#fff" font-size="11" text-anchor="middle">Don’t run</text></svg>')
WIN_PIC_3 = ('<svg class="warn-pic" viewBox="0 0 320 200" role="img" aria-label="The same window after More info, with the Run anyway button highlighted">'
             '<rect x="0" y="0" width="320" height="200" rx="12" fill="#f3f6fb"/>' + _DLG +
             '<text x="28" y="102" fill="#fff" font-size="10.5">App: Invoiceo-Setup-Windows.exe</text>'
             '<text x="28" y="118" fill="#fff" font-size="10.5">Publisher: Unknown publisher</text>'
             '<rect x="132" y="152" width="80" height="24" rx="4" fill="#fff"/>'
             '<text x="172" y="168" fill="#0b5cad" font-size="11" font-weight="700" text-anchor="middle">Run anyway</text>'
             '<rect x="126" y="146" width="92" height="36" rx="8" ' + _RING + '/>'
             '<rect x="224" y="152" width="76" height="24" rx="4" fill="#fff" opacity=".18"/>'
             '<text x="262" y="168" fill="#fff" font-size="11" text-anchor="middle">Don’t run</text></svg>')
WINDOWS_GUIDE = f"""<section class="section section-subtle" id="windows-warning" aria-labelledby="warn-title">
  <div class="wrap">
    {section_head('Windows help', 'Windows shows a blue warning? Here is what to do',
                  'It takes about 10 seconds. Windows asks this when you open the installer.', 'warn-title')}
    <ol class="steps-row steps-3 mt-4">
      <li>{WIN_PIC_1}<span class="step-label">Step 1</span><h3 class="h4">Open the file</h3>
        <p>Open <b>{FILES['windows']}</b> from your Downloads folder, or click it in your browser’s download list.</p></li>
      <li>{WIN_PIC_2}<span class="step-label">Step 2</span><h3 class="h4">Click “More info”</h3>
        <p>If a blue window says <b>“Windows protected your PC”</b>, click the small <b>More info</b> link. Do not click <b>Don’t run</b>.</p></li>
      <li>{WIN_PIC_3}<span class="step-label">Step 3</span><h3 class="h4">Click “Run anyway”</h3>
        <p>A <b>Run anyway</b> button appears. Click it, then follow the setup. {NAME} opens from the Start menu.</p></li>
    </ol>
    <p class="small muted center mt-2">These are drawings of the two screens. Yours may look slightly different.</p>
    <div class="grid-auto mt-4">
      <div class="card">{tile('shield', 'teal')}<h3 class="h4">Why does Windows show this?</h3>
        <p>Windows shows this window for apps it does not recognise yet. {NAME}’s installer is not code-signed yet, so Windows has no record of it. It does not mean the file is harmful.</p></div>
      <div class="card">{tile('check')}<h3 class="h4">Want to check the file first?</h3>
        <p>Open PowerShell in your Downloads folder and run <code>Get-FileHash .\\{FILES['windows']}</code>. The result should match the line for {FILES['windows']} in <a href="{DL}SHA256SUMS.txt">SHA256SUMS.txt</a>.</p></div>
    </div>
    <p class="center small mt-3">Still stuck? <a href="contact.html">Tell us</a> and we will help you install it.</p>
  </div>
</section>
"""

download_body = page_head(
    'Download', f'Download {NAME}', 'Free for Windows, macOS and Linux. No sign-up, no licence key and no subscription. New here? <a href="how-it-works.html">See how it works</a>.',
    f'\n    {byline()}<div class="badges">{badge("Version <span data-version>" + VERSION + "</span>", "brand")}'
    f'{badge("Released <span data-release-date>" + RELEASE_DATE + "</span>", "neutral")}</div>'
    f'\n    <p class="small"><a href="changelog.html">What’s new in this version</a></p>') + f'''

<section class="page-body" aria-label="Installers">
  <div class="wrap">
    {TRUST}
    <div class="mt-2">{PHONE_NOTE}</div>
    <h2 class="sr-only">Download for your computer</h2>
    <div class="mt-3">{dl_grid(full=True)}</div>
    <div class="mt-2">{CHECKSUMS}</div>
  </div>
</section>

{WINDOWS_GUIDE}
<section class="section" aria-labelledby="first-steps">
  <div class="wrap">
    {section_head('After installing', 'Up and running in minutes', hid='first-steps')}
    <div class="mt-4">{first_steps()}</div>
  </div>
</section>

<section class="section section-flush" aria-label="More help">
  <div class="wrap">
    <div class="grid-auto">
      <div class="card">{tile('refresh')}<h2 class="h4">Updating to a new version</h2><p>Download the new installer and install it over the old version. Your data is kept, but make a backup first from <b>Settings → Backup</b> in the app. The <a href="changelog.html">release notes for every version</a> show what changed.</p></div>
      <div class="card">{tile('help')}<h2 class="h4">Need help installing?</h2><p>Read the <a href="faq.html#installing-and-updating">answers about installing and updating</a> or <a href="contact.html">contact us</a>, and we will help you get started.</p></div>
      <div class="card">{tile('gift', 'teal')}<h2 class="h4">Free, on every computer</h2><p>You never need to pay to download {NAME}, install it on more computers or keep using it. Only work made for you on request is paid: see <a href="customization.html">custom features</a>.</p></div>
    </div>
  </div>
</section>'''

page('download.html', f'Download {NAME} — free billing software for PC and Mac',
     f'Download {NAME} free for Windows 10/11, macOS 12+ and Linux (.deb or AppImage). No sign-up or licence key, '
     'with step-by-step install help for each system.',
     'download', download_body, crumb='Download')

# ────────────────────────────── Customization ──────────────────────────────
CUSTOM = [
    ('zap', 'Energy and power-sale bills', 'Monthly bills for wind and solar power: units, rate, deductions and net '
     'amount. <a href="#work">See the one we built</a>.'),
    ('file', 'Invoice and bill designs', 'A layout that matches your letterhead, your trade or a format your customers expect.'),
    ('list', 'Extra fields', 'More details on invoices, products or customers, printed where you need them.'),
    ('layout', 'Bill formats for your trade', 'Special bills for your kind of business, with the columns and totals your trade uses.'),
    ('chart', 'New reports', 'Reports and summaries built around the numbers you check every day or month.'),
    ('share', 'Exports', 'Send your data to Tally or another accounting app in the format it needs.'),
    ('sliders', 'Changes to how it works', 'Shortcuts, steps or screens adjusted to the way your counter works.'),
]
CUSTOM_STEPS = [('message', 'Tell us what you need', 'Fill in the request form below. Sample bills or screenshots help a lot.'),
                ('file', 'Get a quote', 'We reply with any questions and a price for the work. There is no charge for the quote.'),
                ('package', 'We build it', 'Once you approve, we build and test it, and give you your updated version.')]
recent_work = f'''<section class="section" id="work" aria-labelledby="work-title">
  <div class="wrap">
    {section_head('Recent work', 'An energy bill for a solar power company',
                  'Made for Green &amp; Green Agri Solutions, Udumalai: their monthly power-sale bill, built into ' + NAME + '.', 'work-title')}
    <div class="split split-top mt-4">
      <figure class="doc-full">
        <a href="{_energy_png}" target="_blank" rel="noopener" title="Open full size"><img src="{_energy_png}" width="{_ew}" height="{_eh}" alt="A sample energy bill made with {NAME}: units generated and allotted, net units at the rate, deductions such as transmission and wheeling charges, and the net amount" loading="lazy" decoding="async"></a>
        <figcaption>Shown with sample data: every name and number on it is made up.</figcaption>
      </figure>
      <div class="stack" style="gap: 28px">
        <div class="stack"><h3 class="h4">What it does</h3>{checks(ENERGY_WORK)}</div>
        {testimonial_card(TESTIMONIALS[0], link=False)}
        <p class="small">Read <a href="reviews.html">what Green &amp; Green Agri Solutions say about {NAME}</a>.</p>
      </div>
    </div>
  </div>
</section>'''

recent_work_2 = f'''<section class="section section-subtle" id="work-sales-purchase" aria-labelledby="work2-title">
  <div class="wrap">
    {section_head('Recent work', 'Sales and purchase on one bill', 'Made for ' + AMMA_WHO + ': the shop sells to a customer and buys from the same customer, on one bill.', 'work2-title')}
    <div class="split split-top mt-4">
      <figure class="doc-full doc-narrow">
        <a href="{_amma_png}" target="_blank" rel="noopener" title="Open full size"><img src="{_amma_png}" width="{_aw}" height="{_ah}" alt="A sales and purchase receipt printed by {NAME} on an 80 mm thermal printer: items sold, items bought from the customer and the grand total" loading="lazy" decoding="async"></a>
        <figcaption>Shown with sample data: every name and number on it is made up.</figcaption>
      </figure>
      <div class="stack" style="gap: 28px">
        <div class="stack"><h3 class="h4">What it does</h3>{checks(AMMA_WORK)}</div>
        <p class="small">It is a paid custom version of {NAME}, made for that shop. See <a href="reviews.html#sales-purchase">it on the Reviews page</a>, or <a href="#request">ask for something like it</a>.</p>
      </div>
    </div>
  </div>
</section>'''

customization_body = page_head(
    'Custom features', 'Customization',
    f'{NAME} is free to use. When your business needs something more, we can build it for you. Every request is quoted on its own, and you decide before any work starts. See <a href="reviews.html">a custom bill we built</a>.', byline()) + f'''

<section class="page-body" aria-labelledby="what-title">
  <div class="wrap">
    {section_head('What we can make', 'Made for your business', 'A few examples. If your idea is not on the list, ask anyway. '
                  'Everything already in the app stays free: see <a href="/#features">the features of the free version</a> first.', 'what-title')}
    <div class="grid-auto mt-4">{''.join(f'<div class="card">{tile(i, "neutral")}<h3>{t}</h3><p>{d}</p></div>' for i, t, d in CUSTOM)}</div>
  </div>
</section>

{recent_work}

{recent_work_2}

<section class="section section-subtle" aria-labelledby="custom-how">
  <div class="wrap">
    {section_head('How it works', 'Three steps, and you decide', hid='custom-how')}
    <ol class="steps-row steps-3 mt-4">{''.join(f'<li><span class="step-label">{tile(ic, "", "sm")}Step {n + 1}</span><h3 class="h4">{t}</h3><p>{b}</p></li>' for n, (ic, t, b) in enumerate(CUSTOM_STEPS))}</ol>
  </div>
</section>

<section class="section section-flush" id="request" aria-labelledby="request-title">
  <div class="wrap narrow">
    {section_head('Request', 'Request a customization', 'Prices depend on the work, so we do not list fixed prices. You will always see the quote first.', 'request-title')}
    <p class="center mt-2" data-block>{btn('Open the form in a new tab', '#', 'secondary', '', 'external-link', attrs=' data-href="forms.customization" data-hide-empty target="_blank" rel="noopener"')}</p>
    <div id="customization-form-gate" class="form-gate hidden mt-3"><p>The form is a Google Form. Showing it here lets Google load content and set cookies, so it only loads when you ask.</p><button type="button" class="btn btn-secondary">Show the form on this page</button></div>
    <iframe id="customization-form" class="form-frame hidden mt-3" title="Customization request form" loading="lazy"></iframe>
    <div id="customization-form-missing" class="form-missing mt-3">
      <p><b>The request form is not shown on this page.</b></p>
      <p>Open it in a new tab with the button above, or write to us at <a href="mailto:{EMAIL}?subject=Customization%20request">{EMAIL}</a><span data-block> or message us on <a data-whatsapp target="_blank" rel="noopener">WhatsApp</a></span>.</p>
    </div>
    <p class="center small mt-3">Questions first? Read the <a href="faq.html#help-and-custom-work">answers about custom work</a> or see <a href="contact.html">all the ways to contact us</a>.</p>
  </div>
</section>'''

page('customization.html', 'Custom bill formats, reports and features',
     f'{NAME} is free; extra features, invoice designs, reports and exports for your business are built on request and quoted per job.',
     'customization', customization_body, crumb='Customization')

# ─────────────────────────────────── FAQ ───────────────────────────────────
FAQ_GROUPS = [
    ('About Invoiceo', [
        ('Is Invoiceo really free?',
         ['Yes. The app and its updates are free, with no subscription and no trial period. You can install it on as many of your computers as you like.',
          'We only charge for work done for you on request, such as a new bill format or a report. See <a href="customization.html">Customization</a>.']),
        ('Is Invoiceo open source?',
         f'Yes. {NAME} is released under the MIT License, so anyone can read, use and change the code. It is based on Invoiso by ANOOP P, which is also MIT-licensed. See <a href="about.html">about {NAME}</a> and <a href="licenses.html">the licences</a>.'),
        ('How can it be free?',
         f'There is no paid version. Development is supported by optional <a href="customization.html">paid customization</a> for businesses that need something special, and by <a href="{COFFEE}" target="_blank" rel="noopener">donations</a>.'),
        ('Do I need an internet connection?',
         'No. Invoiceo runs on your computer, so you can bill, print and see reports offline. You need a connection only to download the installer, to open our website or forms, or to share a PDF online.'),
        ('Do I need to create an account?',
         'No online account or sign-up is needed. The app has its own login on your computer, so you can protect it with a password and give each person their own username.'),
        ('Where is my data stored?',
         ['Everything you enter is saved on your own computer, in the app’s data folder. Your customers, products and invoices are not sent to us.',
          'Because the data is on your computer, keeping it safe is in your hands: use <b>Settings → Backup</b> in the app regularly.']),
        ('Does Invoiceo collect any data?',
         ['Only a few anonymous usage counts, so we know how many people use the app: when it is first opened, once a day while it is used, and once when the first invoice is made. Each count carries a random ID (the same one on that computer), the app version and the operating system, nothing else.',
          'Your customers, products, invoices, amounts and company details are never sent. You can turn the counts off in <b>Settings → Software Info</b>. See the <a href="privacy.html">privacy policy</a>.']),
    ]),
    ('Billing and printing', [
        ('Can I use Invoiceo for GST billing?',
         ['Yes. You can add your GSTIN and your customers’ GSTINs, HSN/SAC codes and tax rates per product or for the whole invoice. Invoices show CGST and SGST, or IGST for sales to another state, and you can choose titles such as Tax Invoice or Bill of Supply.',
          'Invoiceo helps you prepare correct invoices; for filing returns, please follow your accountant’s advice.']),
        ('Can I use it in my country?',
         'Yes, in any country. Choose the currency you bill in and one of eight app languages, set your own tax rates, and turn the GST fields off in the invoice settings when you don’t need them.'),
        ('Which printers can I use?',
         'Any printer your computer can print to, for A4, A5 and A6 invoices. For receipts, Invoiceo supports 58 mm and 80 mm thermal printers and can print the receipt automatically after each sale (in the Modern layout).'),
        ('Can I use it in Tamil?',
         'Yes. The app can be used in English, Tamil, Hindi, Nepali, French, Spanish, Chinese and Tibetan (partly translated), and Tamil names print correctly on PDFs and thermal receipts.'),
        ('Does it work with a barcode scanner?',
         'Yes. A USB barcode scanner that types the code works on the New Invoice screen: scan a product to add it to the bill.'),
        ('Is it right for a small shop?',
         'Yes. Barcode scanning, thermal receipts, stock levels, batch and expiry dates, and daily sales reports are built in. '
         'See <a href="/#features">all the features</a>.'),
        ('Can I manage more than one business?',
         'Yes. You can add several companies on one computer. Each company keeps its own customers, products, invoices and settings.'),
        ('Can more than one person use it?',
         'Yes, on the same computer. Each person can have their own login, as an admin or a normal user.'),
    ]),
    ('Installing and updating', [
        ('Which computers does it run on?',
         'Windows 10 and 11 (64-bit), macOS 12 Monterey or later, and Linux: a .deb for Ubuntu 22.04+, Debian 12+ and Linux Mint 21+, and an AppImage for other distributions. There is no phone app.'),
        ('Windows says “Windows protected your PC”. Is it safe?',
         'This message appears for installers that are not code-signed yet. If you downloaded Invoiceo from this website, click <b>More info</b> and then <b>Run anyway</b>. The <a href="download.html#windows-warning">Windows picture guide</a> shows both screens, and you can check the file with its <a href="download.html#windows-warning">SHA-256 fingerprint</a>.'),
        ('macOS says it cannot check the app for malicious software.',
         'The app is not notarised by Apple yet. Click <b>Done</b>, open <b>System Settings → Privacy &amp; Security</b>, scroll down to the message about Invoiceo and click <b>Open Anyway</b>. On macOS 14 or older, Control-click Invoiceo in Applications and choose <b>Open</b>. You only need to do this the first time.'),
        ('How do I update to a new version?',
         'Download the new version from the <a href="download.html">Download page</a> and install it over the old one. Your data is kept, but make a backup first to be safe. See what changed on the <a href="changelog.html">What’s new page</a>.'),
        ('How do I move to a new computer?',
         'Make a backup of each company on the old computer, copy the backup file to the new one, <a href="download.html">install Invoiceo there</a> and import the backup from <b>Settings → Backup</b>.'),
    ]),
    ('Limits and what is not built in', [
        ('Is there any limit on invoices?',
         'No. There is no limit on invoices, customers, products or computers, and no trial period. Every feature is included.'),
        ('Does Invoiceo file GST returns, or make e-invoices and e-way bills?',
         ['Not built in. Invoiceo prints correct GST invoices and gives a <b>Tax report</b> by tax rate (taxable amount and tax) that you can save as CSV or PDF and give to your accountant. It does not make GSTR-1 or GSTR-3B files, e-invoices or e-way bills.',
          'If you need these, they can be built as <a href="customization.html">paid customization</a>. Tell us the format you need.']),
        ('Can I send an invoice on WhatsApp or email from the app?',
         'Not directly. Save the invoice as a PDF (or print it) and attach it in WhatsApp or email. A one-click send button can be built as <a href="customization.html">paid customization</a>.'),
        ('Can I record purchases and supplier bills?',
         'The free app records sales and keeps a purchase price and stock count for each product. A separate supplier and purchase section is not part of the free app; it can be built as <a href="customization.html">paid customization</a>.'),
        ('Can two computers use the same data?',
         'Not live. Each computer keeps its own data, and there is no sync between computers or a cloud version. The simplest setup is one main billing computer where everyone logs in with their own user. To move data to another computer, use <b>Settings → Backup</b>. Sharing data between computers can be looked at as <a href="customization.html">paid customization</a>.'),
        ('How is Invoiceo different from Vyapar, myBillBook or Tally?',
         'Invoiceo is free with no limits, works fully offline, needs no sign-up and is open source. The others have more features, such as GST returns, e-invoicing and phone apps, but their free plans are limited or are trials. See the <a href="compare.html">side-by-side comparison</a>.'),
    ]),
    ('Help and custom work', [
        ('Can you add a feature for my business?',
         'Yes, as a paid service, quoted per request. Tell us what you need on the <a href="customization.html">Customization page</a>.'),
        ('How do I get help?',
         f'Use the support form or write to us. All the ways to reach us are on the <a href="contact.html">Contact page</a>.'),
    ]),
]
FAQ = [qa for _, items in FAQ_GROUPS for qa in items]


faq_body = page_head('Help', 'Frequently asked questions', f'Short answers about {NAME}. Can’t find yours? <a href="contact.html">Ask us</a>.', byline()) + '\n\n<section class="page-body">\n  <div class="wrap measure">\n' + '\n'.join(
    f'    <h2 class="h3{" mt-4" if i else ""}" id="{strip_tags(t).lower().replace(" ", "-")}">{t}</h2>\n    <div class="faq-list mt-2">'
    + ''.join(faq_item(q, a) for q, a in items) + '</div>'
    for i, (t, items) in enumerate(FAQ_GROUPS)) + '\n  </div>\n</section>'

# ───────────────────────────────── Reviews ─────────────────────────────────
reviews_body = page_head('Reviews', 'What our customers say',
                         f'Businesses that use {NAME}, in words they have approved. Want something built for your business? <a href="customization.html">Ask about customization</a>.', byline()) + f'''

<section class="page-body" aria-labelledby="rv-work">
  <div class="wrap">
    <div class="review-story stack">
      <div class="stack" style="gap: 10px">
        <p>{badge('Custom feature', 'brand', 'tool')}</p>
        <h2 class="h3" id="rv-work">An energy bill built for Green &amp; Green Agri Solutions</h2>
        <p>Their monthly power-sale bill: units, rate, deductions and net amount, ready in a few clicks each month.</p>
      </div>
      <figure class="doc-full"><a href="{_energy_png}" target="_blank" rel="noopener" title="Open full size"><img src="{_energy_png}" width="{_ew}" height="{_eh}" alt="The monthly power-sale bill built into {NAME} for Green &amp; Green Agri Solutions, printed with made-up names and numbers: units, rate, deductions under Less:, round off and the net amount in words" loading="lazy" decoding="async"></a>
        <figcaption>Shown with sample data: every name and number on it is made up.</figcaption></figure>
      {''.join(testimonial_card(t) for t in TESTIMONIALS)}
      <p class="center">{btn('See what this energy bill does', 'customization.html#work', 'secondary', '', 'arrow')}</p>
    </div>
  </div>
</section>

<section class="section" aria-labelledby="rv-amma" id="sales-purchase">
  <div class="wrap">
    <div class="review-story stack">
      <div class="stack" style="gap: 10px">
        <p>{badge('Custom feature', 'brand', 'tool')}</p>
        <h2 class="h3" id="rv-amma">Sales and purchase on one bill, built for {AMMA_WHO}</h2>
        <p>The shop sells to its customers and also buys farm products from them, such as groundnuts or coconut. One bill now shows both. The final total shows what the customer pays, or what the shop pays the customer when it buys more than it sells.</p>
      </div>
      <figure class="doc-full doc-narrow"><a href="{_amma_png}" target="_blank" rel="noopener" title="Open full size"><img src="{_amma_png}" width="{_aw}" height="{_ah}" alt="A sample thermal receipt made with {NAME}: items sold to the customer, items bought from the customer, and the grand total as sales minus purchase" loading="lazy" decoding="async"></a>
        <figcaption>Shown with sample data: every name and number on it is made up.</figcaption></figure>
      <div class="card stack"><h3 class="h4">What this bill does</h3>{checks(AMMA_WORK)}</div>
      <p class="center">{btn('See this and other custom work', 'customization.html#work-sales-purchase', 'secondary', '', 'arrow')}</p>
    </div>
  </div>
</section>

<section class="section section-subtle" aria-labelledby="rv-about">
  <div class="wrap">
    <div class="about-grid">
    <div class="card about-card about-wide">
    <h2 id="rv-about">About this custom work</h2>
    <p>Green &amp; Green Agri Solutions, in Udumalai, works in agricultural products and solar power. Each month they bill for the
      wind and solar power they generate, and that bill has its own rules: units, a monthly rate and a list of deductions that
      an ordinary invoice does not have. We built the bill into {NAME} for them as a paid customization.</p>
    <p>The sales-and-purchase bill was made for {AMMA_WHO}, as a paid customization too: it is delivered as a private
      version of {NAME} made for that shop, and it is not part of the free app.</p>
    <p>If your trade needs a bill of its own, see <a href="customization.html">custom bill formats
      and features</a>. Every request is quoted on its own, and you decide before any work starts.</p>
    </div>
    <div class="card about-card">
    <h2>How we show reviews</h2>
    <p>Every review on this page comes from a real business that uses {NAME}. We show it only with their permission, in words they
      have approved, and we name the business only when they agree. There are no star ratings or sample reviews here.</p>
    </div>
    <div class="card about-card">
    <h2>Share your experience</h2>
    <p>If you use {NAME}, we would like to hear from you, whether it is praise, a problem or an idea. Helpful things to tell us:</p>
    <ul>
      <li>what kind of business you run, and how many people use the app;</li>
      <li>what you use most, such as GST invoices, thermal receipts, stock or reports;</li>
      <li>what saves you time, and what could work better.</li>
    </ul>
    <p>Use the buttons below to send it. Something not working? The <a href="contact.html">contact page</a> has the support
      form, and the <a href="faq.html">frequently asked questions</a> may already have the answer. Not using {NAME} yet?
      <a href="download.html">Download it free for Windows, macOS or Linux</a>.</p>
    </div>
    </div>
  </div>
</section>

<section class="section section-flush" aria-labelledby="rv-write">
  <div class="wrap narrow center stack" style="align-items: center">
    {section_head('Your turn', f'Using {NAME}? Tell us what you think', 'Your review helps other shops decide. We only publish reviews with your permission.', 'rv-write')}
    <div class="cta-row" style="justify-content: center">
      <span data-block>{btn('Write a review', '#', 'primary', 'lg', 'message', attrs=' data-href="forms.feedback" data-hide-empty target="_blank" rel="noopener"')}</span>
      <span data-block>{btn('Send it on WhatsApp', '#', 'secondary', 'lg', 'message', attrs=' data-whatsapp target="_blank" rel="noopener"')}</span>
    </div>
  </div>
</section>'''

page('reviews.html', 'Customer reviews and custom billing work',
     f'What a customer says about {NAME}, plus the custom bills we built: an energy bill for a solar power company and a '
     'sales-and-purchase bill for a farm shop.',
     'reviews', reviews_body, crumb='Customer reviews')

page('faq.html', 'FAQ: free offline invoicing and billing software',
     f'Answers about {NAME}: price, open source, offline use, where data is stored, taxes and currencies, printers, languages, barcode scanners, installing and updating.',
     'faq', faq_body, crumb='FAQ', jsonld={
         '@context': 'https://schema.org',
         '@type': 'FAQPage',
         'mainEntity': [
             {'@type': 'Question', 'name': q,
              'acceptedAnswer': {'@type': 'Answer', 'text': re.sub(r'\s+', ' ', html.unescape(strip_tags(
                  ' '.join(a) if isinstance(a, list) else a))).strip()}}
             for q, a in FAQ],
     })

# ─────────────────────────────── Compare page ───────────────────────────────
# Facts below come from each company's own website, checked on COMPARE_CHECKED.
# Where a page did not say, the cell says "Not listed" (never a guess). Plans,
# limits and prices change, so re-check every few months and update the date.
COMPARE_COLS = [
    (NAME, None),
    ('Vyapar', 'https://vyaparapp.in/'),
    ('myBillBook', 'https://mybillbook.in/'),
    ('Tally', 'https://tallysolutions.com/gst-software/free/'),
    ('Sleek Bill', 'https://sleekbill.in/lifetime-free-gst-billing-software/'),
]
NL = 'Not listed'
COMPARE_ROWS = [
    ('The free plan',
     ['Free forever. Every feature included, no limit on invoices, customers or computers',
      'Basic features free on mobile; desktop is a free trial',
      'Free sign-up; plan prices are on a separate page',
      '7-day free trial, then paid plans',
      'Free basic version, limited to 10 documents a month']),
    ('Works without internet',
     ['Yes, fully', 'Offline billing, then syncs to the cloud', 'Apps with real-time cloud sync', 'Yes', 'Yes']),
    ('Sign-up or account',
     ['None', 'Phone number to download', 'Sign-up', 'Form for the free trial', 'Direct download, no sign-up']),
    ('Where your data is kept',
     ['Only on your computer', 'Your device, with cloud backup and sync', 'Cloud', 'Your computer', 'Your PC, with optional sync']),
    ('Open source',
     ['Yes (MIT License)', 'No', 'No', 'No', 'No']),
    ('Phone app',
     ['No, computers only', 'Yes', 'Yes', NL, NL]),
    ('GST returns, e-invoice, e-way bill',
     ['Not built in. A Tax report by rate (CSV or PDF) for your accountant',
      'E-invoice, e-way bill and GST returns', 'GSTR-1, 2, 3B, e-invoice and e-way bill',
      'GSTR-1, GSTR-3B, e-way bill and e-invoicing', 'GSTR-1, GSTR-3B and GSTR-2A reports']),
    ('Send bills on WhatsApp or email',
     ['Not built in. Save the PDF and attach it', 'WhatsApp sharing and reminders', 'WhatsApp and SMS reminders', NL,
      'Optional email of invoices']),
    ('Accounting',
     ['Sales, tax, profit, receivables and stock reports. No ledgers or balance sheet', 'Accounting as an add-on',
      'Bookkeeping and bank reconciliation', 'Full accounting', 'Ledgers, profit and loss, cash and bank book']),
    ('Languages',
     ['8 app languages; Tamil prints correctly on PDFs and receipts', '9+ Indian languages', NL, NL, NL]),
]
COMPARE_TONES = [
    'ypppp',   # free plan
    'yppyy',   # works without internet
    'yppyy',   # sign-up or account
    'yppyy',   # where data is kept
    'ynnnn',   # open source
    'nyyxx',   # phone app
    'pyyyy',   # GST returns, e-invoice, e-way bill (ours: Tax report only)
    'nyyxp',   # WhatsApp or email
    'pyyyy',   # accounting
    'yyxxx',   # languages
]
PICK_US = ['You want billing that is free for good, with no invoice cap and no trial that ends',
           'You want your data on your own computer, with no sign-up and no cloud account',
           'You print on A4 or 58/80 mm thermal printers, or need Tamil or Hindi on your bills',
           'You want open-source software, or a small custom feature made for your business at a fair price']
PICK_OTHER = ['You file GST returns from the software, or need e-invoice and e-way bill',
              'You need a phone app, or several shops or computers working on the same data',
              'You want WhatsApp or SMS reminders sent from the software',
              'You need full accounting with ledgers and a balance sheet']

# The page shows the rows where {NAME} has the feature (a tick); the rows it does not have are covered by "Choose another if…" below,
# the FAQ and the AI summary files, which keep the full table.
CMP_ICONS = {'The free plan': 'gift', 'Works without internet': 'wifi-off', 'Sign-up or account': 'user', 'Where your data is kept': 'hard-drive',
             'Open source': 'code', 'Languages': 'globe'}
compare_th = ''.join(
    (f'<th scope="col" class="us"><span class="us-pill">Free forever</span><span class="cmp-name">{n}</span></th>' if not u else
     f'<th scope="col"><a href="{u}" target="_blank" rel="noopener nofollow">{n}</a></th>')
    for n, u in COMPARE_COLS)
compare_tr = ''.join(
    f'<tr><th scope="row"><span class="cmp-ic">{icon(CMP_ICONS[t])}</span><span>{t}</span></th>' + ''.join(
        f'<td{" class=\"us\"" if i == 0 else ""} data-label="{COMPARE_COLS[i][0]}"><span class="ck ck-{COMPARE_TONES[ri][i]}" aria-hidden="true"></span><span class="ct">{c}</span></td>'
        for i, c in enumerate(cells)) + '</tr>'
    for ri, (t, cells) in enumerate(COMPARE_ROWS) if COMPARE_TONES[ri][0] == 'y')
GLANCE = [('gift', 'No invoice limit', 'free, with no trial'), ('wifi-off', 'Works offline', 'no internet needed'),
          ('lock', 'No sign-up', 'data stays on your PC'), ('code', 'Open source', 'MIT License')]
glance = ('<div class="facts-strip compare-glance"><ul class="wrap facts facts-4">'
          + ''.join(f'<li class="fact">{tile(i, "teal", "md")}<div><b>{v}</b><span>{l}</span></div></li>' for i, v, l in GLANCE)
          + '</ul></div>')
compare_body = page_head('Compare', f'{NAME} compared with Vyapar, myBillBook, Tally and Sleek Bill',
                         f'A plain side-by-side look at free billing software popular with small businesses in India. Checked on {COMPARE_CHECKED} from each company’s own website.',
                         extra=byline() + f'<div class="badges mt-2">{badge("Free forever", "teal", "gift")}{badge("Works offline", "brand", "wifi-off")}{badge("Open source", "neutral", "code")}</div>') + glance + f'''

<section class="page-body">
  <div class="wrap">
    <div class="cmp-wrap">
      <table class="cmp">
        <thead><tr><th scope="col"><span class="sr-only">Feature</span></th>{compare_th}</tr></thead>
        <tbody>{compare_tr}</tbody>
      </table>
    </div>
    <ul class="cmp-legend"><li><span class="ck ck-y"></span>Included</li><li><span class="ck ck-p"></span>Partly, or with limits</li>
      <li><span class="ck ck-n"></span>Not available</li><li><span class="ck ck-x"></span>Not listed on their page</li></ul>
    <p class="small mt-2">What {NAME} does not do yet is listed in the <a href="faq.html#limits-and-what-is-not-built-in">FAQ</a>, and the <a href="how-it-works.html">How it works</a> page shows what it does. Checked on {COMPARE_CHECKED} from the home or pricing pages linked above. Plans, limits and prices change, so please check
      their websites before you decide. “Not listed” means that page did not say. All product names belong to their owners;
      {NAME} is not connected to them.</p>
  </div>
</section>

<section class="section section-subtle" aria-labelledby="cmp-pick">
  <div class="wrap">
    <h2 id="cmp-pick" class="h3 center">Which is right for you?</h2>
    <div class="split split-stretch mt-4">
      <div class="group-card"><div class="group-card-head">{tile("check-circle", "teal")}<h3>Choose {NAME} if…</h3></div>{checks(PICK_US)}</div>
      <div class="group-card"><div class="group-card-head">{tile("help", "neutral")}<h3>Choose another if…</h3></div><ul class="plain-list">{"".join(f"<li>{i}</li>" for i in PICK_OTHER)}</ul></div>
    </div>
    <div class="stack mt-4" style="align-items: center; text-align: center; gap: 14px">
      <p>Missing something? {NAME} is free, and features such as the ones above can be built for your business as a <a href="customization.html">paid service</a>, quoted per request.</p>
      <div class="cta-row" style="justify-content: center">
        {btn(f'Download {NAME} free', 'download.html', 'primary', 'lg', 'download')}
        {btn('Ask about a customization', 'customization.html', 'secondary', 'lg', 'arrow')}
      </div>
    </div>
  </div>
</section>

<section class="cta-section" aria-labelledby="cmp-cta">
  <div class="wrap">
    <div class="cta-band">
      <h2 id="cmp-cta">Try it yourself. It is free.</h2>
      <p class="lead">Download {NAME} and make your first invoice in a few minutes. No sign-up, no card, no trial that ends.</p>
      <div class="cta-row">
        {btn(f'Download {NAME} free', 'download.html', 'inverse', 'lg', 'download')}
        {btn('Questions? Ask us', 'contact.html', 'on-dark', 'lg', 'message')}
      </div>
    </div>
  </div>
</section>'''

page('compare.html', f'{NAME} vs Vyapar, myBillBook, Tally and Sleek Bill compared',
     f'Free billing software compared: {NAME} against Vyapar, myBillBook, Tally and Sleek Bill on free-plan limits, offline use, '
     f'sign-up, open source, GST returns and more. Checked {COMPARE_CHECKED}.',
     'compare', compare_body, crumb='Compare')

# ───────────────────────────────── Contact ─────────────────────────────────
NEW_TAB = ' target="_blank" rel="noopener"'
contact_cards = [
    ('mail', '', 'Email', f'<p class="value">{EMAIL}</p><p>For anything about {NAME}.</p>', btn('Send an email', f'mailto:{EMAIL}', 'secondary'), ''),
    ('message', 'teal', 'WhatsApp', '<p class="value"><span data-whatsapp-number></span></p><p>Quick questions and help with installing.</p>',
     btn('Chat on WhatsApp', '#', 'secondary', attrs=' data-whatsapp' + NEW_TAB), ' data-block'),
    ('help', '', 'Support request', '<p>Report a problem with installing, printing or billing. Include your app version and, if you can, a screenshot.</p>',
     btn('Open the support form', '#', 'secondary', attrs=' data-href="forms.support"' + NEW_TAB), ''),
    ('refresh', '', 'Feedback', '<p>Tell us what you like and what we should improve.</p>',
     btn('Give feedback', '#', 'secondary', attrs=' data-href="forms.feedback" data-hide-empty' + NEW_TAB), ' data-block'),
    ('tool', 'note', 'Customization', '<p>Need a feature, report or bill format made for your business? It is a paid service, quoted per request.</p>',
     btn('Request a customization', 'customization.html', 'secondary'), ''),
    ('coffee', 'note', f'Like {NAME}?', f'<p>{NAME} is free. If it saves you time, you can buy me a coffee.</p>',
     btn('Buy me a coffee', COFFEE, 'secondary', attrs=NEW_TAB), ''),
]
contact_body = page_head('Contact', 'Talk to us', 'Questions, problems or ideas — choose whichever way suits you. Many answers are already in the <a href="faq.html">FAQ</a>.') + f'''

<section class="page-body">
  <div class="wrap">
    <div class="grid-auto">
{chr(10).join(f'      <div class="card contact-card"{blk}>{tile(i, tone)}<h2 class="h4">{t}</h2>{body}{b}</div>' for i, tone, t, body, b, blk in contact_cards)}
    </div>
  </div>
</section>

<section class="section section-subtle" aria-labelledby="ct-which">
  <div class="wrap">
    <div class="about-grid">
    <div class="card about-card about-wide">
    <h2 id="ct-which">Which way to choose</h2>
    <ul>
      <li><b>Something not working</b> with installing, printing or billing: use the support form above, so all the details reach us in one place.</li>
      <li data-block><b>A quick question</b> or help with installing: message us on <a data-whatsapp target="_blank" rel="noopener">WhatsApp</a>.</li>
      <li><b>Anything longer</b>, or a message with files attached: email <a href="mailto:{EMAIL}">{EMAIL}</a>.</li>
      <li data-block><b>Ideas and reviews</b>: use the <a data-href="forms.feedback" data-hide-empty target="_blank" rel="noopener">feedback form</a>. We publish a review only with your permission; <a href="reviews.html">read our customer review</a>.</li>
      <li><b>A feature, report or bill format made for your business</b>: this is a paid service, quoted per request. The quote is free, and no work starts until you approve it. <a href="customization.html#request">Request a customization</a>.</li>
    </ul>
    </div>
    <div class="card about-card">
    <h2>What to include in a support request</h2>
    <p>A few details help us find the problem quickly, often without having to ask you again:</p>
    <ol>
      <li>Your {NAME} version, shown in the app under <b>Settings → Software Info</b>. The latest version is <span data-version>{VERSION}</span>.</li>
      <li>Your computer: Windows 10 or 11, your macOS version, or your Linux distribution and whether you installed the .deb or the AppImage.</li>
      <li>What you were doing, step by step, and what you expected to happen.</li>
      <li>The exact message you saw, or a screenshot of the screen.</li>
      <li>For printing problems: the printer and the paper size (A4, A5, A6, or a 58 mm or 80 mm thermal roll).</li>
    </ol>
    <p>Your business data stays on your computer, so you do not need to send backups or customer lists; a screenshot of the
      problem is usually enough. How we use what you send us is explained in the <a href="privacy.html">privacy policy</a>.</p>
    </div>
    <div class="card about-card">
    <h2>Before you write</h2>
    <p>Many questions are already answered in the <a href="faq.html">frequently asked questions</a>: price, offline use, GST,
      printers, backups and moving to a new computer. If Windows or macOS warns you while installing, the
      <a href="download.html">download page</a> has the steps for each system. Using an older version? See
      <a href="changelog.html">what’s new in each release</a>; your problem may already be fixed in the latest one.</p>
    </div>
    </div>
  </div>
</section>'''

page('contact.html', 'Contact us: support, WhatsApp and customization',
     f'Contact {BUSINESS} about {NAME} by email, WhatsApp or the support form. What to include in a support request, and '
     'how to ask for paid customization.',
     'contact', contact_body, crumb='Contact', page_type='ContactPage')

# ───────────────────────────────── Updates ─────────────────────────────────


def date_tag(iso):
    """A release date as a <time> element, e.g. 9 October 2026."""
    return f'<time datetime="{iso}">{int(iso[8:])} {MONTHS[int(iso[5:7]) - 1]} {iso[:4]}</time>'


changelog_body = page_head('Updates', f'What’s new in {NAME}', 'Every release, newest first. Download the latest version from the '
                           '<a href="download.html">Download page</a>; the FAQ explains <a href="faq.html#installing-and-updating">how to '
                           'update without losing your data</a>.') + f'''

<section class="page-body">
  <div class="wrap measure">
    <article class="release" id="v{VERSION}">
      <h2>Version {VERSION} {badge('Latest', 'brand')}</h2>
      <p class="date">{date_tag(RELEASE_ISO)}</p>
      <ul>
        <li><b>Easier sign-in.</b> Click the arrow in the Username box to pick your account from a list, and {NAME} remembers who signed in last on that computer, so you only type the password.</li>
        <li><b>Letter case no longer matters.</b> “ravi”, “Ravi” and “RAVI” open the same account. Your username can be any name you can remember, including your email address. Two older accounts that differ only by case (for example “Bob” and “bob”) still need the exact spelling, and a new account can no longer be made with a name that differs from an existing one only by case.</li>
        <li>Your data and accounts are unchanged: this release needs no database upgrade.</li>
      </ul>
    </article>
    <article class="release" id="v1.0.7">
      <h2>Version 1.0.7</h2>
      <p class="date">{date_tag("2026-10-23")}</p>
      <ul>
        <li><b>Low-stock limit for each product.</b> Until now every product counted as “low” at 10 or less. Now you can set your own limit on a product, for example 50 for rice and 2 for an expensive item. The Low Stock list, its count, and the colour and label in the product list all follow it. Leave it blank and a product works exactly as before.</li>
        <li>The limit is in the New Product and Edit forms and in the products CSV (a new <code>low_stock_limit</code> column), and Duplicate keeps it.</li>
        <li><b>New Product / New Service window.</b> In the Modern layout, adding a product now opens a clear window with General, Pricing and Inventory sections and a Track stock switch.</li>
        <li>Fixes: the “saved” message no longer covers the Save button on the next product, and the Unit box no longer overflows in Tamil.</li>
        <li>Your existing data and backups are safe: the app upgrades its database on first start, and older backups still restore.</li>
      </ul>
    </article>
    <article class="release" id="v1.0.6">
      <h2>Version 1.0.6</h2>
      <p class="date">{date_tag("2026-10-09")}</p>
      <ul>
        <li><b>Tamil Settings screens read better.</b> PDF Settings, Invoice Settings, Company Info and Software Info now show the full Tamil words: the Reset to default button, template descriptions, and the notes under the invoice settings boxes are no longer cut off.</li>
        <li>Software Info shows the app description in Tamil, and the “Buy me a coffee” button reads clearly in Tamil.</li>
        <li>Shorter, clearer Tamil wording for a few settings labels.</li>
      </ul>
    </article>
    <article class="release" id="v1.0.5">
      <h2>Version 1.0.5</h2>
      <p class="date">{date_tag("2026-10-09")}</p>
      <ul>
        <li><b>Tamil screens read better.</b> Long Tamil labels are no longer cut off with “…”: the sidebar, page titles, dashboard cards and charts, the invoice, customer and product lists, and the Reports menu now show the full words.</li>
        <li>On the New Invoice screen, when the buttons are too narrow for their names, Create goes full width with Save Draft under it.</li>
        <li>Shorter, clearer Tamil wording for a few page subtitles and card notes.</li>
      </ul>
    </article>
    <article class="release" id="v1.0.4">
      <h2>Version 1.0.4</h2>
      <p class="date">{date_tag("2026-10-09")}</p>
      <ul>
        <li>Anonymous usage counts are now on, so we can see how many shops use {NAME}: a short message when the app is first opened, once a day while it is used, and once when the first invoice is made. They never include your business data. Turn them off any time in Settings → Software Info (see the <a href="privacy.html">privacy policy</a>).</li>
      </ul>
    </article>
    <article class="release" id="v1.0.3">
      <h2>Version 1.0.3</h2>
      <p class="date">{date_tag("2026-10-09")}</p>
      <ul>
        <li><b>Automatic backup.</b> Turn it on in Settings → Backup: every day or every week, while the app is open, a copy of your company’s data is saved by itself. Choose a folder inside Google Drive or OneDrive and the copies reach the cloud automatically.</li>
        <li>Keep the last 5, 10 or 30 automatic copies; older automatic copies are removed, and nothing else in the folder is touched.</li>
        <li>A clearer Backup page: saved backups show what they are (automatic, manual, before restore, JSON) with the right date and time.</li>
        <li>A warning on the dashboard if an automatic backup could not be saved, for example when the Drive folder is not available.</li>
      </ul>
    </article>
    <article class="release" id="v1.0.2">
      <h2>Version 1.0.2</h2>
      <p class="date">{date_tag("2026-10-08")}</p>
      <p>The app is the same as version 1.0.1: there are no new features or fixes in this release. If you already have 1.0.1, you don’t need to update.</p>
    </article>
    <article class="release" id="v1.0.1">
      <h2>Version 1.0.1</h2>
      <p class="date">{date_tag("2026-10-08")}</p>
      <p>Fixes and improvements from release testing.</p>
      <ul>
        <li>Stock can be a decimal number, so selling 0.5 kg takes exactly 0.5 from stock.</li>
        <li>Receipts now count as sales in Reports and on the dashboard.</li>
        <li>Tamil text prints correctly on payment receipts, customer statements and report PDFs.</li>
        <li>PDF Settings shows a real sample invoice with your company details as its preview.</li>
        <li>Every user can change their own password from the user menu.</li>
        <li>Importing a backup now checks the file first and never replaces your data with an empty or wrong file.</li>
        <li>Safer billing: a discount cannot make a line negative, quantity 0 is not accepted, and a converted quotation cannot be converted twice.</li>
        <li>The Windows installer also works on ARM laptops, and the Linux AppImage works on newer Ubuntu versions.</li>
      </ul>
    </article>
    <article class="release" id="v1.0.0">
      <h2>Version 1.0.0</h2>
      <p class="date">{date_tag("2026-10-08")}</p>
      <p>The first release under the {NAME} name.</p>
      <ul>
        <li>New name, logo and a clean light design.</li>
        <li>Tamil added as an app language, alongside English, Hindi, Nepali, French, Spanish, Chinese and Tibetan (partly translated).</li>
        <li>Two screen layouts to choose from in Settings: <b>Standard</b> and the new <b>Modern</b> layout, with a grouped sidebar, a top bar with a quick “new invoice, quotation or receipt” button, and a new dashboard.</li>
        <li>Thermal receipts with Tamil and other Indian-language text now print the same way they look in the preview.</li>
        <li>Receipts can print automatically after each invoice is created (Modern layout).</li>
        <li>In the Modern layout, an unfinished invoice can be saved as a draft and continued later from the Invoices list.</li>
        <li>Barcode scanning on the New Invoice screen is more reliable.</li>
        <li>In the Modern layout, Products and Services have their own pages, each with its own columns and filters, and the Customers page shows what each customer still owes.</li>
        <li>The app tells you when a newer version is out (it checks once a day while you are online; billing never needs the internet).</li>
      </ul>
    </article>
  </div>
</section>'''

page('changelog.html', 'What’s new: release notes and version history',
     f'Release notes for {NAME}, the free billing software: what changed in each version from 1.0.0 to {VERSION}, with the '
     'release dates.',
     'changelog', changelog_body, crumb='What’s new')


# ───────────────────── Legal pages: numbered cards with a topic list on the left ─────────────────────
def legalize(title, lead, chips, body):
    """Turns a plain legal page (an intro, then <h2> sections) into the site's card layout: a short intro card, one card per
    section with a number, and a sticky 'On this page' list. The text itself is untouched. chips: three short facts that float
    behind the title (site.js)."""
    prose = re.search(r'<div class="prose">(.*)</div>\s*</div>\s*</section>', body, re.S).group(1)
    parts = re.split(r'(?=<h2>)', prose)
    intro, secs = parts[0].strip(), [x for x in parts[1:] if x.strip()]
    nav, cards = '', ''
    for i, sec in enumerate(secs):
        h = re.match(r'<h2>(.*?)</h2>', sec, re.S).group(1)
        text = re.sub(r'^\d+\.\s*', '', h)                      # the card shows its own number
        slug = re.sub(r'[^a-z0-9]+', '-', re.sub(r'<[^>]+>|&[a-z]+;', '', text).lower()).strip('-')
        n, a = f'{i + 1:02d}', i % 5 + 1
        nav += f'<a class="lg{a}" href="#{slug}"><b>{n}</b><span>{text}</span></a>'
        cards += (f'<section class="legal-sec lg{a}" id="{slug}"><h2><b>{n}</b><span>{text}</span></h2>'
                  f'<div class="prose">{sec[sec.index("</h2>") + 5:].strip()}</div></section>')
    head = page_head('Legal', title, lead, f'<p class="legal-meta"><span>Last updated: {date_tag(RELEASE_ISO)}</span></p>')
    return (head + f'''

<section class="page-body">
  <div class="wrap legal-wrap">
    <nav class="legal-nav" aria-label="On this page"><p class="ln-title">On this page</p>{nav}<p class="ask">Questions? <a href="mailto:{EMAIL}">Write to us</a>.</p></nav>
    <div class="legal-main" data-chips="{esc('|'.join(chips))}">
      {f'<div class="legal-intro">{intro}</div>' if intro else ''}
      {cards}
    </div>
  </div>
</section>''')

# ───────────────────────────────── Privacy ─────────────────────────────────
ANALYTICS_BULLET = ('''<li><b>Analytics.</b> This website can use Google Analytics to count visits and see which pages and download buttons are used, <b>but only if you press Accept</b> in the cookie box. If you press Decline, or do not answer, no analytics script is loaded and no analytics cookie is set. When you accept, Google Analytics sets cookies in your browser; we have turned off its advertising features, and we use it only to improve the site. You can change your choice at any time with <b>Cookie settings</b> in the footer, and declining removes the analytics cookies. Your choice is remembered in your browser (local storage on this site), which is necessary for the box to work.</li>''' if CONSENT_BANNER else '''<li><b>Analytics.</b> This website uses Google Analytics to count visits and see which pages and download buttons are used. It sets cookies in your browser for this. Google Analytics does not store IP addresses, and we have turned off its advertising features. We use it only to improve the site. You can block these cookies in your browser settings.</li>''')
privacy_body = page_head('Legal', 'Privacy policy', f'Last updated: {date_tag(RELEASE_ISO)}') + f'''

<section class="page-body">
  <div class="wrap">
    <div class="prose">
    <p>This policy explains what information {BUSINESS} (“we”) handles when you use the {NAME} app and this website. If you have a question about it, write to <a href="mailto:{EMAIL}">{EMAIL}</a>.</p>

    <h2>The {NAME} app</h2>
    <ul>
      <li><b>Your business data stays on your computer.</b> The customers, products, invoices, payments, settings and backups you create are stored on the computer where {NAME} is installed. We do not receive a copy. The FAQ explains <a href="faq.html#about-invoiceo">where your data is stored and how to back it up</a>.</li>
      <li><b>Anonymous usage counts.</b> So that we know how many people use {NAME}, the app (from <a href="changelog.html#v1.0.4">version 1.0.4</a>) sends us a short message when it is first opened, once a day while it is used, and once when the first invoice is created. Each message carries only a random ID made for this purpose (it stays the same on that computer, so one computer is counted once), the app version and the operating system (Windows, macOS or Linux). It never includes your customers, products, invoices, amounts or company details. The messages go to a small server we run on Cloudflare, which does not store IP addresses; Cloudflare’s handling is described in the <a href="https://www.cloudflare.com/privacypolicy/" target="_blank" rel="noopener">Cloudflare Privacy Policy</a>. You can turn this off in the app under <b>Settings → Software Info</b>.</li>
      <li><b>Update check.</b> Once a day, when you are online, the app asks GitHub whether a newer version of {NAME} exists; that is an ordinary web request, so GitHub sees your IP address. Apart from this and the usage counts, the app goes online only when you click a link that opens your web browser.</li>
      <li><b>No online account.</b> The app’s usernames and passwords exist only on your computer.</li>
      <li><b>No advertising</b> and no selling of data, ever.</li>
      <li><b>Links you choose to open.</b> Some buttons in the app open a web page in your browser (for example this website, our forms or Buy Me a Coffee). What happens on those pages is covered below or by that site’s own policy.</li>
      <li><b>Backups and PDFs.</b> Files you export or share are handled by you; we have no access to them.</li>
    </ul>

    <h2>This website</h2>
    <ul>
      <li><b>Hosting.</b> This site is hosted on GitHub Pages. GitHub may record technical information such as your IP address when you visit, as described in the <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement" target="_blank" rel="noopener">GitHub Privacy Statement</a>. Installers are downloaded from GitHub as well.</li>
      <li><b>Fonts.</b> The text font (Manrope), the heading font (Fraunces), and Noto Sans Tamil or Noto Sans Devanagari on the Tamil and Hindi pages, are hosted on this website. Your browser does not contact Google to load them.</li>
      <li><b>Forms.</b> Our support, customization and feedback forms are Google Forms. What you type into them (such as your name, email, phone number and message) is sent to our Google account so that we can reply. Google’s handling of it is described in the <a href="https://policies.google.com/privacy" target="_blank" rel="noopener">Google Privacy Policy</a>. The customization page can show its form on the page, but only after you press “Show the form on this page”; until then nothing from Google is loaded there.</li>
      {ANALYTICS_BULLET}
      <li><b>Email and WhatsApp.</b> If you contact us, we keep the conversation so that we can help you and follow up.</li>
    </ul>

    <h2>How we use what you send us</h2>
    <p>Only to answer you, to provide support, to prepare and deliver customization work you asked for, and to improve {NAME}. We do not sell or rent your information.</p>

    <h2>How long we keep it</h2>
    <p>We keep form replies and messages for as long as they are useful for supporting you, and delete them when you ask us to, unless we must keep a record by law (for example, invoices for paid work).</p>

    <h2>Your choices</h2>
    <p>You can ask us what information we hold about you, ask us to correct it, or ask us to delete it, by writing to <a href="mailto:{EMAIL}">{EMAIL}</a>.</p>

    <h2>Children</h2>
    <p>{NAME} and this website are meant for businesses and are not aimed at children.</p>

    <h2>Changes</h2>
    <p>If we change this policy, we will update this page and the date at the top. The <a href="terms.html">terms of use</a> cover the rest of how you may use {NAME} and this website.</p>

    <h2>Contact</h2>
    <p>{BUSINESS}, India · <a href="mailto:{EMAIL}">{EMAIL}</a></p>
    </div>
  </div>
</section>'''

page('privacy.html', 'Privacy policy: business data stays on your PC',
     f'How {BUSINESS} handles information for the {NAME} app and website. Your business data stays on your computer, and '
     'anonymous usage counts can be turned off.',
     'privacy', legalize('Privacy policy', 'What the app and this website handle, in plain words.', ['Stays on your PC', 'No ads, ever', 'No account needed'], privacy_body), crumb='Privacy policy')

# ────────────────────────────────── Terms ──────────────────────────────────
terms_body = page_head('Legal', 'Terms of use', f'Last updated: {date_tag(RELEASE_ISO)}') + f'''

<section class="page-body">
  <div class="wrap">
    <div class="prose">
    <p>These terms apply to the {NAME} app and to this website, which are provided by {BUSINESS} (“we”). By downloading or using {NAME}, you agree to them.</p>

    <h2>1. Using {NAME}</h2>
    <p>You may download, install and use {NAME} free of charge, for personal or business use, on as many of your computers as you like. You may share the link to our <a href="download.html">Download page</a>. You may not sell {NAME}, charge others for copies of it, or present it as your own product.</p>

    <h2>2. Your data and your invoices</h2>
    <p>{NAME} stores your data on your own computer. You are responsible for keeping backups, for the details you enter, and for checking that your invoices, tax rates and returns are correct for your business. {NAME} is a tool to help you prepare invoices; it is not tax or legal advice. How we handle information is explained in the <a href="privacy.html">privacy policy</a>.</p>

    <h2>3. No warranty</h2>
    <p>{NAME} is provided “as is”, without any warranty. We work to keep it reliable, but we cannot promise that it will be free of errors or suitable for every purpose.</p>

    <h2>4. Limitation of liability</h2>
    <p>To the extent the law allows, we are not liable for any loss of data, profit or business, or for any indirect damage, arising from the use of {NAME} or this website. Where liability cannot be excluded, it is limited to the amount you paid us for the work concerned.</p>

    <h2>5. Paid customization</h2>
    <p>Custom features and changes are a separate, paid service. For each request we agree in writing on what will be delivered, the price, the payment terms and an expected timeline before any work starts. Delivery dates are estimates. Work we deliver for you comes with the same terms as the rest of {NAME} unless we agree otherwise in writing. See <a href="customization.html">how custom work is requested and quoted</a>.</p>

    <h2>6. Third-party software</h2>
    <p>{NAME} is built on Invoiso, which is released under the MIT License. The licence text and other notices are on the <a href="licenses.html">Licenses page</a>. Those licences apply to the parts they cover.</p>

    <h2>7. Links to other sites</h2>
    <p>This website and the app link to services we do not run, such as Google Forms, GitHub, WhatsApp and Buy Me a Coffee. Their own terms apply when you use them.</p>

    <h2>8. Changes</h2>
    <p>We may update these terms. The date at the top shows the latest version. Continuing to use {NAME} after a change means you accept the new terms.</p>

    <h2>9. Governing law</h2>
    <p>These terms are governed by the laws of India.</p>

    <h2>10. Contact</h2>
    <p>{BUSINESS}, India · <a href="mailto:{EMAIL}">{EMAIL}</a></p>
    </div>
  </div>
</section>'''

page('terms.html', 'Terms of use for the free billing app and website',
     f'Terms for the free {NAME} billing app and this website, and for paid customization from {BUSINESS}: your '
     'data, no warranty, liability and Indian law.',
     'terms', legalize('Terms of use', 'The simple rules for using the app and this website.', ['Free for any business', 'Your data, your backups', 'Open source (MIT)'], terms_body), crumb='Terms of use')

# ───────────────────────────────── Licenses ────────────────────────────────
mit = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'LICENSE'), encoding='utf-8').read().strip()
licenses_body = page_head('Legal', 'Licenses',
                          f'{NAME} is based on Invoiso, whose licence is below. The licences of the open-source packages and fonts built into the app are listed in the app under <b>Settings → Software Info</b>.') + f'''

<section class="page-body">
  <div class="wrap">
    <div class="prose">
    <h2>Invoiso</h2>
    <p>{NAME} is based on Invoiso by ANOOP P, released under the MIT License:</p>
    <pre>{html.escape(mit)}</pre>

    <h2>What the MIT License means</h2>
    <p>The MIT License is a short, permissive open-source licence. In plain words:</p>
    <ul>
      <li><b>It allows</b> anyone to use, copy, change and share the software, for personal or business use, free of charge. The licence text above lists every permission.</li>
      <li><b>It asks one thing:</b> the copyright notice and the licence text must stay with every copy or substantial part of the software. That is why the Invoiso notice, © 2025 ANOOP P, is on this page, at the foot of every page of this website and on the Software Info screen of the app.</li>
      <li><b>It gives no warranty:</b> the software is provided “as is”, and its authors are not liable for problems that come from using it. Our <a href="terms.html">terms of use</a> say the same for {NAME}.</li>
    </ul>

    <h2>How {NAME} relates to Invoiso</h2>
    <p>{NAME} is built on Invoiso, an open-source invoicing app by ANOOP P. {BUSINESS} develops {NAME} from that code and releases it under the MIT License as well. Version 1.0.0 was the first release under the {NAME} name; the <a href="changelog.html">release notes</a> list what has changed in each version since then.</p>

    <h2>Other licences in the app</h2>
    <p>The app also includes open-source packages and fonts, each under its own licence. To read them, open <b>Settings → Software Info</b> in {NAME} and choose <b>View licenses</b>. The same screen shows your app version and the Invoiso notice.</p>

    <h2>This website</h2>
    <ul>
      <li><b>Feather icons</b>, released under the MIT License, © 2013–2017 Cole Bemis.</li>
      <li><b>Platform logos</b> (Windows, Apple, Linux) from Simple Icons, released under CC0 1.0. The logos are trademarks of their owners.</li>
      <li><b>Manrope</b> typeface by Mikhail Sharanda, released under the SIL Open Font License 1.1, and hosted on this website.</li>
      <li><b>Fraunces</b> typeface by Undercase Type, released under the SIL Open Font License 1.1, and hosted on this website. It is used for the headings.</li>\n      <li><b>Noto Sans Tamil</b> and <b>Noto Sans Devanagari</b> typefaces by The Noto Project Authors, released under the SIL Open Font License 1.1, and hosted on this website. They are loaded only on the Tamil and Hindi pages.</li>\n
    </ul>
    <p>Questions about licences? Write to <a href="mailto:{EMAIL}">{EMAIL}</a>, or see the other ways to <a href="contact.html">contact us</a>.</p>
    </div>
  </div>
</section>'''

page('licenses.html', 'Licenses: MIT License and open-source credits',
     f'Licences for {NAME}: the MIT License of Invoiso by ANOOP P that it is built on, what that licence allows, and credits '
     'for this website’s icons and fonts.',
     'licenses', legalize('Licenses', f'{NAME} is based on Invoiso, whose licence is below. The licences of the open-source packages and fonts built into the app are listed in the app under <b>Settings → Software Info</b>.', ['MIT License', 'Free to use and change', 'Keep the notice'], licenses_body), crumb='Licenses')

# ──────────────────────── How it works (its own page: the five steps, then each step in detail) ────────────────────────
# Each step: the sub-steps on the left, one screen on the right. The sub-step on show lights up its part of the screen
# (boxes are x, y, width, height in a 1280 x 800 picture) and the screen changes when the sub-step needs another one.
HOW_DETAIL = [
    {'t': 'Set up your business',
     'lead': 'Do this once. Everything you enter here is printed on your bills, so the first invoice already looks like yours.',
     'tip': ('Good to know', 'A short first-run guide walks you through company details, invoice settings and the look. Several companies and logins can be added later in Settings.'),
     'screens': [('company-info', 'Settings → Company Info in Invoiceo: company name, GSTIN, PAN, address, phone, email and website of a sample shop'),
                 ('settings-invoice', 'Invoiceo Invoice Settings: invoice prefix, leading zeros, currency, date and time format'),
                 ('settings-pdf', 'The Invoiceo PDF Settings: page size, invoice designs and theme colour with a live preview')],
     'steps': [('Company details', 'Your name, address, phone, email, website and tax number (the box is labelled GSTIN for India and Tax/VAT No for other countries), in Settings → Company Info.', 0, [[541, 100, 711, 195]]),
               ('Logo and UPI QR', 'Add your logo, and turn on the UPI QR code so it prints on every invoice. Bank details go in the same place.', 0, [[324, 112, 162, 164], [541, 714, 711, 70]]),
               ('Invoice settings', 'Choose the invoice prefix, how numbers are padded (00000007 or 7), the currency, the date and time format, and whether tax is on.', 1, [[563, 160, 665, 320]]),
               ('Design and paper', 'Pick the invoice design and the page size you like. You can change them any time.', 2, [[316, 95, 222, 545]])]},
    {'t': 'Add customers and products',
     'lead': 'Add them before you bill, or as you go. Your lists grow with your business.',
     'tip': ('Good to know', 'Products that are running low or are out of stock are marked on the Products screen, so you can reorder in time.'),
     'screens': [('customer-new', 'The New Customer form in Invoiceo: name, business name, phone, email, tax number and address'),
                 ('product-new', 'The Add New Product form in Invoiceo: name, HSN/SAC code, prices, tax and stock'),
                 ('customers', 'The Invoiceo Customers screen with the Import and Export buttons'),
                 ('create-invoice', 'The Invoiceo New Invoice screen with its search box for items')],
     'steps': [('Add a customer', 'Name, business name, phone, email, tax number and address. For a walk-in customer, just type a name while billing.', 0, [[815, 140, 440, 420]]),
               ('Add products and services', 'Name, HSN/SAC code, selling and buying price, tax rate, stock, unit and expiry date.', 1, [[437, 150, 605, 440]]),
               ('Import from a file', 'Already have a list? Import customers or products from a CSV file, and export them again any time.', 2, [[745, 8, 196, 42]]),
               ('Scan barcodes', 'A USB barcode scanner works at the counter: scan, and the item is on the bill.', 3, [[229, 226, 545, 48]])]},
    {'t': 'Create an invoice',
     'lead': 'Customer, items and totals on one screen. Tax is worked out as you type.',
     'tip': ('Good to know', 'A quotation can be turned into an invoice, already filled in, and any bill can be duplicated for a repeat order.'),
     'screens': [('create-invoice', 'The Invoiceo New Invoice screen with customer Kannan, four items, tax and a total of Rs. 39,023.78')],
     'steps': [('Pick the customer', 'Choose from your list, or type a walk-in customer’s name.', 0, [[218, 72, 712, 126]]),
               ('Add items', 'Search by name (Ctrl+F) or scan a barcode. Add a one-off custom item with Ctrl+M.', 0, [[229, 226, 690, 48]]),
               ('Quantity, price and discount', 'Change them on the line. Tax, extra charges and the total update at once.', 0, [[228, 376, 690, 240]]),
               ('Type, date and notes', 'Make an invoice, a quotation or a receipt. Set the date, the due date and a note for the customer.', 0, [[943, 72, 318, 380]]),
               ('Create', 'Press Create (Ctrl+S). Not finished? Save a draft and carry on later.', 0, [[1075, 738, 190, 52], [1118, 626, 142, 100]])]},
    {'t': 'Print, save or share',
     'lead': 'The moment an invoice is created, you can look at it, save it or print it.',
     'tip': ('Good to know', 'Tamil, Hindi and other Indian-language text prints correctly on thermal receipts, the same as on screen. More in the <a href="faq.html#billing-and-printing">printing answers</a>.'),
     'screens': [('invoice-created', 'The Invoiceo Invoice Created Successfully card, with View Details, Preview PDF, Download PDF and Print Invoice'),
                 ('settings-pdf', 'The Invoiceo PDF Settings: page size, invoice designs and theme colour with a live preview'),
                 ('company-info', 'Settings → Company Info in Invoiceo, with the Show QR Code on Invoices switch')],
     'steps': [('Preview, download or print', 'The “created” card has one button for each. Preview the PDF first if you like.', 0, [[480, 458, 520, 84]]),
               ('Choose a design', 'Several invoice designs, a thermal receipt layout, and your own theme colour and logo.', 1, [[316, 160, 222, 470]]),
               ('Choose the paper', 'A4, A5, A6, or a 58 mm or 80 mm thermal roll.', 1, [[316, 95, 222, 55]]),
               ('Add a payment QR', 'Show your UPI QR code on the bill so the customer can pay straight away.', 2, [[541, 714, 711, 70]]),
               ('Send it', 'Save the PDF and send it to your customer on WhatsApp or email.', 0, [[744, 458, 124, 84]])]},
    {'t': 'Track payments',
     'lead': 'Know what you have been paid and who still owes you, without a notebook.',
     'tip': ('Good to know', 'Reports use the buying price you saved on a product, so profit shows real figures.'),
     'screens': [('invoices', 'The Invoiceo Invoices list: paid, unpaid and partly paid invoices and the amount outstanding'),
                 ('customers', 'The Invoiceo Customers screen showing what each customer still owes'),
                 ('dashboard', 'The Invoiceo dashboard: money collected, money still due, sales by month and invoice status'),
                 ('reports', 'The Invoiceo Reports screen: total billed, collected, outstanding and a monthly revenue chart')],
     'steps': [('See every bill’s status', 'The Invoices list shows Paid, Unpaid and Partly paid, and the amount still outstanding.', 0, [[922, 200, 210, 520]]),
               ('Record a payment', 'Full or part payment, by cash, UPI or bank. Each payment gets its own receipt number.', 0, [[1118, 236, 142, 490]]),
               ('See who owes you', 'The Customers screen shows what each customer still owes.', 1, [[945, 340, 120, 440]]),
               ('Check the dashboard', 'Money collected, money still due, sales by month and your latest invoices, at a glance.', 2, [[220, 175, 1038, 115]]),
               ('Run a report', 'Revenue, receivables, tax, customers, products, a daily report and stock. Export most of them to CSV or PDF.', 3, [[206, 64, 160, 330]])]},
]

HOW_DAY = [('zap', 'Morning', 'Open Invoiceo. Scan the customer’s items, create the bill and print a thermal receipt at the counter.'),
           ('file', 'Midday', 'A customer asks for a price. Make a quotation, send the PDF, and turn it into an invoice when they say yes.'),
           ('credit-card', 'Afternoon', 'A customer pays half now. Record the part payment and the balance is kept for later.'),
           ('chart', 'Evening', 'Open the dashboard: today’s sales, money still due and items running low.'),
           ('calendar', 'Month end', 'Run the tax and receivables reports, export them to CSV for your accountant, and make a backup.')]


def hd_block(i, d):
    imgs = ''.join(
        window_img(shot_file(n, 'en'), alt if k == 0 else alt, 'is-on' if k == 0 else '', lazy=(i > 0 or k > 0))
        for k, (n, alt) in enumerate(d['screens']))
    data = json.dumps([{'s': s, 'b': b} for _, _, s, b in d['steps']])
    items = ''.join(
        f'<li class="hd-item{" is-on" if k == 0 else ""}" data-k="{k}"><button type="button" class="hd-btn" aria-expanded="{"true" if k == 0 else "false"}">'
        f'<span class="hd-n">{k + 1}</span><b>{t}</b></button><p class="hd-body">{b}</p></li>'
        for k, (t, b, _, _) in enumerate(d['steps']))
    return (f'<article class="hd hd-{i + 1}" id="step-{i + 1}" data-steps="{esc(data)}"><div class="hd-copy">'
            f'<p class="hd-kicker"><span>{i + 1:02d}</span>Step {i + 1}</p><h3>{d["t"]}</h3><p class="hd-lead">{d["lead"]}</p>'
            f'<ol class="hd-acc">{items}</ol>'
            f'<p class="hd-tip">{icon("zap")}<span><b>{d["tip"][0]}.</b> {d["tip"][1]}</span></p></div>'
            f'<div class="hd-stage"><div class="window hd-win"><div class="window-bar"><i></i><i></i><i></i><span>{NAME}</span></div>'
            f'<div class="hd-view">{imgs}<span class="hd-spot"></span><span class="hd-spot"></span><span class="hd-pin"></span></div></div></div></article>')


def window_img(name, alt, cls='', lazy=True):
    """One screenshot as a plain <img> (the 1280 px copy, with a content hash in its address), for the step stages."""
    has_small = small_copy(name)
    src = asset(f'assets/images/screens/{name}-1280.jpg') if has_small else asset(f'assets/images/screens/{name}.png')
    load = ' loading="lazy" decoding="async"' if lazy else ''
    return f'<img class="hd-img {cls}" src="{src}" width="{SHOT_W}" height="{SHOT_H}" alt="{esc(alt)}"{load}>'


_hw = TEXT['en']['how']
_pics = [window(shot_file('company-info', 'en'), _hw['alts'][0], sizes=_HW),
         window(shot_file('products', 'en'), _hw['alts'][1], sizes=_HW),
         window(shot_file('create-invoice', 'en'), _hw['alts'][2], sizes=_HW),
         stage_docs(TEXT['en']['shots']['docs']['invoice-a4'][2], TEXT['en']['shots']['docs']['receipt-80mm'][2]),
         window(shot_file('invoices', 'en'), _hw['alts'][3], sizes=_HW)]
how_flow_en = how_flow(section_head('The five steps', 'The whole flow, at a glance', 'Click a step, or scroll, to see its screen.', 'how-title', left=True),
                       _hw['steps'], _pics, _hw['word'])

how_detail_en = section(
    section_head('In detail', 'Each step, one screen at a time',
                 'What to click, what to type and what you get, with the real screens from Invoiceo.', 'hd-title')
    + '<nav class="hd-strip" aria-label="The five steps">'
    + ''.join(f'<a href="#step-{i + 1}"><b>{i + 1}</b><span>{d["t"]}</span></a>' for i, d in enumerate(HOW_DETAIL)) + '</nav>'
    + ''.join(hd_block(i, d) for i, d in enumerate(HOW_DETAIL)),
    'details', 'hd-section', 'hd-title')

how_day_en = section(
    section_head('A day in the shop', 'What a normal day looks like',
                 'The same five steps, repeated: bill, get paid, check, back up.', 'day-title')
    + '<ol class="day mt-4">' + ''.join(
        f'<li class="day-{i + 1}"><span class="day-ic">{icon(ic)}</span><p class="day-t">{t}</p><p>{b}</p></li>'
        for i, (ic, t, b) in enumerate(HOW_DAY)) + '</ol>',
    'a-day', 'section-subtle', 'day-title')

how_data_en = section(
    '<div class="data-grid"><div class="data-copy">'
    + section_head('Your data', 'Safe on your computer, easy to move', 'There is no cloud and no account. Your records live on your computer, and you decide when to copy them. <a href="privacy.html">Read the privacy policy.</a>', 'data-title', left=True)
    + '<ul class="data-list">'
      f'<li>{tile("hard-drive", "teal", "sm")}<div><b>Stored on your computer</b><span>Customers, products, invoices and payments never leave it.</span></div></li>'
      f'<li>{tile("refresh", "teal", "sm")}<div><b>Automatic backup</b><span>Turn it on in Settings → Backup, and a copy is saved while the app is open.</span></div></li>'
      f'<li>{tile("download", "teal", "sm")}<div><b>Back up now, or export</b><span>Make a backup whenever you like, or export your data as JSON.</span></div></li>'
      f'<li>{tile("laptop", "teal", "sm")}<div><b>Move to a new computer</b><span>Install Invoiceo there, choose Import / restore and pick your backup.</span></div></li>'
      '</ul></div>'
    + f'<div class="data-pic">{window(shot_file("settings-backup", "en"), "The Invoiceo Backup settings: automatic backup, create a backup, export as JSON and import or restore", sizes="(max-width: 900px) 100vw, 600px")}'
    '<div class="data-flow" aria-hidden="true"><span><b>Your computer</b>Invoiceo data</span><i></i><span><b>Backup file</b>a folder you choose</span><i></i><span><b>New computer</b>restore from the backup</span></div></div></div>',
    'your-data', '', 'data-title')

how_install_en = section(
    section_head('Before you install', 'What you need', 'Very little. Questions? See the <a href="faq.html#installing-and-updating">install answers in the FAQ</a>.', 'need-title')
    + '<div class="grid-auto mt-4">'
    + f'<div class="card">{tile("monitor")}<h3>A computer</h3><p>Windows 10 or 11 (64-bit), macOS 12 or later, or Linux (a .deb package or an AppImage). Invoiceo is a desktop app; it is not for phones.</p></div>'
    + f'<div class="card">{tile("wifi-off")}<h3>No internet, no account</h3><p>You need the internet only to download it. Billing, printing and reports all work offline, and there is nothing to sign up for.</p></div>'
    + f'<div class="card">{tile("shield")}<h3>A moment on Windows</h3><p>Windows may ask before it opens the installer, because it is not code-signed yet. The <a href="download.html">Download page</a> shows the two clicks, with pictures.</p></div>'
    + '</div>',
    'need', 'section-subtle', 'need-title')

how_cta_en = f"""<section class="cta-section" aria-labelledby="cta-title">
  <div class="wrap">
    <div class="cta-band">
      <h2 id="cta-title">Ready to try it?</h2>
      <p class="lead">Download Invoiceo, set up your business in a few minutes and make your first invoice today. It is free. New here? <a href="about.html">Read who makes it</a>.</p>
      <div class="cta-row">
        {btn('Download free', 'download.html', 'inverse', 'lg', 'download')}
        {btn('Read the FAQ', 'faq.html', 'on-dark', 'lg', 'help')}
      </div>
      <p class="cta-meta">Version {VERSION} · Windows, macOS and Linux</p>
      {checks(['Free forever', 'No invoice limit', 'Works offline', 'No sign-up'], 'checks-inline')}
    </div>
  </div>
</section>"""

how_ld = {'@context': 'https://schema.org', '@type': 'HowTo', 'name': f'How to make an invoice with {NAME}',
          'description': f'{NAME} in five steps: set up your business, add customers and products, create an invoice, print or save it, and track payments.',
          'step': [{'@type': 'HowToStep', 'position': i + 1, 'name': d['t'], 'url': f'{SITE}/how-it-works.html#step-{i + 1}',
                    'text': d['lead'] + ' ' + ' '.join(f'{a}: {b}' for a, b, _, _ in d['steps'])} for i, d in enumerate(HOW_DETAIL)]}

how_body = (page_head('How it works', f'How {NAME} works, step by step',
                      'From the first setup to the last payment: what you do in each step, with the real screens.', byline())
            + '\n\n' + how_flow_en + '\n\n' + how_detail_en + '\n\n' + how_day_en + '\n\n' + how_data_en + '\n\n' + how_install_en + '\n\n' + how_cta_en)

page('how-it-works.html', f'How {NAME} works: from setup to payment in five steps',
     f'See how {NAME} works, step by step: set up your business, add customers and products, create an invoice, print or save it and track payments, with the real screens.',
     'how', how_body, jsonld=how_ld, crumb='How it works')


# ───────────────────────────────────── About ─────────────────────────────────────
# Only facts the site already states elsewhere (Privacy, Licenses, FAQ, Customization, Changelog).
about_body = page_head('About', f'About {NAME}', f'Free, open-source billing software from {BUSINESS}, a small software business in India.', byline()) + f'''

<section class="page-body">
  <div class="wrap">
    <div class="about-grid">
      <article class="about-card"><h2 class="h3">Who makes {NAME}</h2>
        <p>{NAME} is made by {BUSINESS}, a small software business in India. We make free billing software for small shops and businesses, and we build custom features for businesses that ask for them.</p>
        <p>The <a href="how-it-works.html">How it works</a> page shows what the app does, step by step, and the <a href="compare.html">comparison page</a> shows how it differs from other free billing apps.</p></article>
      <article class="about-card"><h2 class="h3">Where it comes from</h2>
        <p>{NAME} is built on <b>Invoiso</b>, an open-source invoicing app by ANOOP P, released under the MIT License. {BUSINESS} develops {NAME} from that code and releases it under the same licence.</p>
        <p>Version 1.0.0 was the first release under the {NAME} name, in October 2026. The <a href="changelog.html">release notes</a> list every change since, and the <a href="licenses.html">Licenses page</a> has the full notice.</p></article>
      <article class="about-card"><h2 class="h3">How it stays free</h2>
        <p>There is no paid version, no trial and no limit on invoices. Development is paid for by <a href="customization.html">custom work</a> that businesses ask us to build, and by donations through <a href="https://buymeacoffee.com/madcreations" target="_blank" rel="noopener">Buy me a coffee</a>.</p>
        <p>More in the FAQ: <a href="faq.html#about-invoiceo">how can it be free?</a></p></article>
      <article class="about-card"><h2 class="h3">Your data</h2>
        <p>{NAME} keeps your business data on your own computer. There is no online account and no cloud copy. The only things the app sends are a daily update check to GitHub and anonymous usage counts, which you can turn off in the app.</p>
        <p>The <a href="privacy.html">privacy policy</a> explains this in full, and the <a href="terms.html">terms of use</a> cover the rest.</p></article>
      <article class="about-card"><h2 class="h3">{NAME} at a glance</h2>
        <ul class="plain-list">
          <li><b>Current version:</b> {VERSION}, released {RELEASE_DATE}</li>
          <li><b>Runs on:</b> Windows 10 and 11, macOS 12 or later, and Linux</li>
          <li><b>App languages:</b> 8, including Tamil and Hindi</li>
          <li><b>Licence:</b> MIT, free to use, copy and change</li>
          <li><b>Price:</b> free; custom features are quoted per request</li>
        </ul></article>
      <article class="about-card"><h2 class="h3">Talk to us</h2>
        <p>Questions, problems or ideas? See the <a href="contact.html">contact page</a>, or write to <a href="mailto:{EMAIL}">{EMAIL}</a>. Before you write, the <a href="faq.html">FAQ</a> may already have the answer.</p>
        <p class="mt-2">{btn(f'Download {NAME} free', 'download.html', 'primary', '', 'download')}</p></article>
    </div>
  </div>
</section>'''

page('about.html', f'About {NAME}: the free billing software from {BUSINESS}',
     f'About {NAME} and {BUSINESS}: who makes the free, open-source billing software, where it comes from, how it stays free and how to contact us.',
     'about', about_body, crumb='About',
     jsonld={'@context': 'https://schema.org', '@type': 'AboutPage', 'about': {'@id': ORG_ID}})

# ─────────────────────────────────── 404 ───────────────────────────────────
nf_body = f'''<section class="wrap not-found">
  <div class="err-code" aria-hidden="true">404</div>
  <h1 class="h2">This page could not be found</h1>
  <p class="lead">The link may be old, or the page may have moved.</p>
  <div class="cta-row" style="justify-content: center">
    {btn('Go to the home page', '/', 'primary', 'lg')}
    {btn(f'Download {NAME}', 'download.html', 'secondary', 'lg', 'download')}
  </div>
</section>'''

page('404.html', 'Page not found', f'This page could not be found on the {NAME} website.', '', nf_body, noindex=True)

print('pages written')

# ───────────────────────── sitemap / robots / llms / manifest ──────────────
pages = ['', 'ta.html', 'hi.html', 'how-it-works.html', 'about.html', 'download.html', 'compare.html', 'customization.html', 'reviews.html', 'faq.html', 'changelog.html', 'contact.html',
         'privacy.html', 'terms.html', 'licenses.html']
with open(os.path.join(OUT, 'sitemap.xml'), 'w') as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n')
    for p in pages:
        f.write(f'  <url><loc>{SITE}/{p}</loc><lastmod>{PAGE_MODIFIED[p or "index.html"]}</lastmod></url>\n')
    f.write('</urlset>\n')

with open(os.path.join(OUT, 'robots.txt'), 'w') as f:
    f.write('User-agent: *\nAllow: /\n\n'
            # stated on purpose: search and assistant crawlers are welcome (they were already allowed by default)
            + ''.join(f'User-agent: {bot}\nAllow: /\n\n' for bot in ('OAI-SearchBot', 'ChatGPT-User', 'Claude-SearchBot', 'Claude-User', 'PerplexityBot'))
            + f'Sitemap: {SITE}/sitemap.xml\n')

with open(os.path.join(OUT, 'llms.txt'), 'w') as f:
    f.write(f'''# {NAME}

> {NAME} is free, open-source (MIT) offline invoicing software for Windows, macOS and Linux, made by {BUSINESS} (India). It works in any country: set your own tax rates (GST, VAT or sales tax) and choose any currency. It creates invoices, quotations and payment receipts, prints on A4/A5/A6 paper or 58/80 mm thermal printers, and works in English, Tamil, Hindi, Nepali, French, Spanish, Chinese and Tibetan (partly translated). All business data is stored on the user's own computer. The app is free with no subscription; custom features are a paid service quoted per request.

## Full text

- [llms-full.txt]({SITE}/llms-full.txt): the site's main text in one Markdown file: features, install steps for each system, every FAQ answer, privacy, terms of use, customization, contact, release notes and licences

## Pages

- [Home]({SITE}/): what {NAME} does
- [Home in Tamil]({SITE}/ta.html): the same page in Tamil (தமிழ்)
- [Home in Hindi]({SITE}/hi.html): the same page in Hindi (हिन्दी)
- [Download]({SITE}/download.html): installers for Windows, macOS and Linux, with install steps
- [About]({SITE}/about.html): who makes Invoiceo, where it comes from and how it stays free
- [How it works]({SITE}/how-it-works.html): the five steps from setup to payment, with each step explained
- [Compare]({SITE}/compare.html): Invoiceo next to Vyapar, myBillBook, Tally and Sleek Bill, checked {COMPARE_CHECKED}
- [Customization]({SITE}/customization.html): paid custom features, quoted per request
- [Reviews]({SITE}/reviews.html): what customers say, and recent custom work
- [FAQ]({SITE}/faq.html): price, open source, offline use, data storage, GST, printers, languages
- [What's new]({SITE}/changelog.html): release notes
- [Contact]({SITE}/contact.html): email {EMAIL}
- [Privacy policy]({SITE}/privacy.html): what the app and website handle; business data stays on the user's computer
- [Terms of use]({SITE}/terms.html): terms for the app, the website and paid customization
- [Licenses]({SITE}/licenses.html): MIT License of Invoiso by ANOOP P, and website credits

## Key facts

- Price: free, no subscription, no invoice limit; paid customization on request
- Not built in: GSTR-1/3B files, e-invoice, e-way bill, WhatsApp/email sending, phone app, supplier and purchase section, live sync between computers
- Open source: MIT License
- Platforms: Windows 10/11 (64-bit), macOS 12 or later, Linux (.deb and AppImage)
- Works offline; no online account needed
- GST: GSTIN, HSN/SAC, CGST + SGST or IGST, Tax Invoice / Bill of Supply titles
- Current version: {VERSION} ({RELEASE_DATE})
- Based on Invoiso by ANOOP P (MIT License)
''')

# llms-full.txt: the whole site as one Markdown file for AI assistants, built
# from the same data and page text as the HTML above (no facts of its own).
# Page text that points at its place on the page, reworded for a file read on its own.
MD_PHRASES = {
    'Pick your computer above.': f'Pick your computer on the download page ({SITE}/download.html).',
    'Fill in the request form below.': f'Fill in the request form at {SITE}/customization.html#request.',
}


def md(s, page=None):
    """Page HTML to Markdown: links made absolute, bold and code kept, the rest plain text.
    page: the file the text comes from, so its in-page #anchor links can be made absolute."""
    for old, new in MD_PHRASES.items():
        s = s.replace(old, new)

    def link(m):
        href, text = m.group(1), m.group(2)
        if href is None or (href.startswith('#') and not page):
            return text
        if href.startswith('#'):
            href = page + href
        if not href.startswith(('http:', 'https:', 'mailto:')):
            if href.startswith('index.html'):
                href = href[len('index.html'):]
            href = SITE + (href if href.startswith('/') else '/' + href)
        return f'[{text}]({href})'
    s = re.sub(r'<a\b(?:[^>]*?\bhref="([^"]*)")?[^>]*>(.*?)</a>', link, s, flags=re.S)
    s = re.sub(r'</?(b|strong)>', '**', s)
    s = re.sub(r'</?code>', '`', s)
    s = html.unescape(strip_tags(s))
    return re.sub(r'\s+', ' ', s).strip()


def first(pattern, text):
    return md(re.search(pattern, text, re.S).group(1))


full = [f'# {NAME}: full description',
        '',
        f'> {NAME} is free, open-source (MIT) offline invoicing software for Windows, macOS and Linux (works in any country, with your own tax rates and currency), made by '
        f'{BUSINESS} (India). This file collects the main text of {SITE}/ in one place, for AI assistants and other readers.',
        '',
        f'- Current version: {VERSION}, released {RELEASE_DATE} ({RELEASE_ISO})',
        f'- Made by: {BUSINESS}, India',
        f'- Website: {SITE}/ (also in Tamil: {SITE}/ta.html, and Hindi: {SITE}/hi.html)',
        f'- Price: free, with no subscription, trial or paid tier; custom features are a paid service, quoted per request',
        f'- Licence: MIT License. Built on Invoiso by ANOOP P (MIT License, © 2025 ANOOP P)',
        '',
        f'## What {NAME} is',
        '',
        first(r'<h1[^>]*>(.*?)</h1>', EN_HOME['hero']) + '. ' + first(r'<p class="lead">(.*?)</p>', EN_HOME['hero']),
        '',
        f'## Why {NAME}',
        '']
full += [f'- **{md(t)}**: {md(d)}' for _, t, d in EN['why']['cards']]
full += ['', '## How it works', '']
full += [f'{int(n)}. **{md(t)}**: {md(b)}' for n, t, b in EN['how']['steps']]
full += ['', '## Features', '']
for _, t, items, _ in EN['features']['groups']:
    full += [f'### {md(t)}', ''] + [f'- {md(i)}' for i in items] + ['']
full += ['## Who it is for', '']
full += [f'- **{md(t)}**: {md(d)}' for _, t, d in EN['who']['items']]
full += ['', '## Local billing rules, works anywhere', ''] + [f'- {md(i)}' for c in EN['lang_section']['cards'] for i in c['items']]
full += ['', 'App languages: English, Tamil, Hindi, Nepali, French, Spanish, Chinese and Tibetan (partly translated).']
full += ['', '## Screens', ''] + [f'- **{md(EN['shots']['screens'][n][0])}**: {md(EN['shots']['screens'][n][1])}' for n in screen_cards]
full += ['', '## Download and install', '',
         f'Download page: {SITE}/download.html. Every installer is free, with no sign-up, no licence key and no subscription. '
         f'SHA-256 checksums are linked on the download page.', '']
for p in PLATFORMS:
    full += [f'### {p["name"]}', '', f'- Requirements: {md(p["req"])}',
             '- Files: ' + ', '.join(f for _, f in p['files']) + f' ({SITE}/download.html#{p["anchor"]})', '- Steps:']
    full += [f'  {i + 1}. {md(st)}' for i, st in enumerate(p['steps'])] + ['']
full += ['### First steps', ''] + [f'{i + 1}. **{t}**: {md(b)}' for i, (_, t, b) in enumerate(EN['download']['first_steps'])]
full += ['', '### Updating to a new version', '', first(r'Updating to a new version</h2><p>(.*?)</p>', download_body)]
full += ['', f'## How {NAME} compares ({SITE}/compare.html)', '',
         f'Checked on {COMPARE_CHECKED} from each company’s own website. "Not listed" means their page did not say. Plans and limits change.', '']
for ri, (rt, cells) in enumerate(COMPARE_ROWS):
    full += [f'**{rt}**', ''] + [f'- {COMPARE_COLS[i][0]}: {c}' for i, c in enumerate(cells)] + ['']
full += ['Choose Invoiceo if: ' + '; '.join(PICK_US) + '.', '', 'Choose another if: ' + '; '.join(PICK_OTHER) + '.', '',
         'Not built in to Invoiceo: ' + '; '.join(NOT_YET) + '.']
full += ['', '## Frequently asked questions', '']
for t, items in FAQ_GROUPS:
    full += [f'### {md(t)}', '']
    for q, a in items:
        full += [f'**{md(q)}**', '', ' '.join(md(x) for x in (a if isinstance(a, list) else [a])), '']
full += ['## Privacy', '', f'{NAME} keeps your business data on your computer. Nothing about your customers, prices or sales is sent to us or anyone else.', '',
         f'Summary of the privacy policy ({SITE}/privacy.html):', '']
for h, ul in re.findall(r'<h2>(.*?)</h2>\s*<ul>(.*?)</ul>', privacy_body, re.S):
    full += [f'### {md(h)}', ''] + [f'- {md(li)}' for li in re.findall(r'<li>(.*?)</li>', ul, re.S)] + ['']
full += ['## Terms of use (summary)', '', f'Full terms: {SITE}/terms.html', '']
for h, para in re.findall(r'<h2>(.*?)</h2>\s*<p>(.*?)</p>', terms_body, re.S):
    full += [f'### {md(h)}', '', md(para), '']
full += ['## Customization (paid, quoted per request)', '',
         f'{NAME} is free to use. When a business needs something more, {BUSINESS} can build it. Every request is quoted on its '
         'own, and the customer decides before any work starts. Prices depend on the work, so no fixed prices are listed. '
         f'Request form: {SITE}/customization.html#request', '', 'Examples of what can be made:', '']
full += [f'- **{md(t)}**: {md(d, "customization.html")}' for _, t, d in CUSTOM]
full += ['', 'How it works:', ''] + [f'{i + 1}. **{t}**: {md(b)}' for i, (_, t, b) in enumerate(CUSTOM_STEPS)]
full += ['', '### Recent work: an energy bill for a solar power company', '',
         'Made for Green & Green Agri Solutions, Udumalai: their monthly power-sale bill for wind and solar generation, built '
         f'into {NAME}. It shows (sample images use made-up names and numbers):', '']
full += [f'- {md(i)}' for i in ENERGY_WORK]
full += ['', f'### Recent work: sales and purchase on one bill, for {AMMA_WHO}', '',
         'The shop sells to a customer and also buys from the same customer, on one bill. A private version of '
         f'{NAME} made for that shop, not part of the free app. It shows (sample images use made-up names and numbers):', '']
full += [f'- {md(i)}' for i in AMMA_WORK]
full += ['', '## Customer reviews', '',
         f'Real customers only, shown with their permission, in words they have approved ({SITE}/reviews.html).', '']
for t in TESTIMONIALS:
    full += [f'> {md(t["quote"]["en"])}', '>', f'> — {md(t["name"])}, {md(t["about"]["en"])} ({md(t["tag"]["en"])})', '']
full += ['## Contact', '',
         f'- Email: {EMAIL}',
         f'- WhatsApp, the support form, the feedback form and the customization request form are linked from {SITE}/contact.html',
         f'- Support requests help most with: the app version (Settings → Software Info), the operating system, the steps that '
         'led to the problem, the exact message or a screenshot, and for printing problems the printer and paper size',
         '', '## Release notes', '', f'Every release, newest first ({SITE}/changelog.html).', '']
for ver, art in re.findall(r'<article class="release" id="v([\d.]+)">(.*?)</article>', changelog_body, re.S):
    date = re.search(r'<time datetime="([\d-]+)">(.*?)</time>', art)
    full += [f'### Version {ver} ({date.group(2)}, {date.group(1)})', '']
    full += [md(x) for x in re.findall(r'<p>(.*?)</p>', art, re.S)]
    full += [f'- {md(li)}' for li in re.findall(r'<li>(.*?)</li>', art, re.S)] + ['']
full += ['## License and credits', '',
         f'{NAME} is released under the MIT License. It is built on Invoiso by ANOOP P, released under the MIT License, '
         '© 2025 ANOOP P. The licences of the open-source packages and fonts built into the app are listed in the app under '
         f'Settings → Software Info → View licenses. Full licence text: {SITE}/licenses.html', '',
         'Credits for this website:', '']
full += [f'- {md(li)}' for li in re.findall(r'<h2>This website</h2>\s*<ul>(.*?)</ul>', licenses_body, re.S)[0].split('</li>') if li.strip()]
full += ['']
with open(os.path.join(OUT, 'llms-full.txt'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(full))

with open(os.path.join(OUT, 'site.webmanifest'), 'w') as f:
    json.dump({
        'name': NAME, 'short_name': NAME, 'start_url': '/', 'display': 'browser',
        'background_color': '#ffffff', 'theme_color': '#ffffff',
        'icons': [
            {'src': '/assets/images/icon-192.png', 'sizes': '192x192', 'type': 'image/png'},
            {'src': '/assets/images/icon-512.png', 'sizes': '512x512', 'type': 'image/png'},
        ],
    }, f, indent=2)
    f.write('\n')
print('extras written')
