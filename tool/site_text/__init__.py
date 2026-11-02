"""Per-language text for the website's home pages.

One module per language (en.py, ta.py, hi.py, ...) holds a TEXT dictionary: pure data, no HTML-building code.
tool/build_website.py has ONE home-page template that reads it. To add a language, copy en.py to <code>.py,
translate the values, and add the code to HOME_LANGS in build_website.py.
"""
from importlib import import_module


def load(code):
    return import_module(f'site_text.{code}').TEXT
