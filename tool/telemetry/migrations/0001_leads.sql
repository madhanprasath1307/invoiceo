-- Download form on invoiceo.in: the email and/or phone a visitor leaves before a download.
-- Run once on the real database (adds two tables; the events table is not touched):
--   npx wrangler d1 execute invoiceo-telemetry --remote --file=migrations/0001_leads.sql
-- Safe to run again (IF NOT EXISTS). See README-leads.md.
--
-- leads: one row per visitor per day (the same email or phone again that day updates the row).
--   day          UTC date of the first download that day, YYYY-MM-DD
--   email        lower-case, or '' when only a phone was given
--   phone        + and digits with the country code (e.g. +919876543210), or ''
--   platform     windows / mac / linux_deb / linux_appimage / other
--   file         the installer clicked, e.g. Invoiceo-Setup-Windows.exe
--   page         the website page, e.g. /download.html
--   lang         en / ta / hi
--   placement    where the button was (hero, platform_card, ...)
--   country      two-letter country Cloudflare gives for the request (no IP address is stored)
--   user_agent   browser and system only, e.g. "Chrome on Windows"
--   downloads    how many times this visitor sent the form that day
--   contacted    0 / 1, for you to mark; contacted_at is when (set it with the UPDATE in README-leads.md)
--   note         your own note
-- A row is deleted automatically (daily Cron Trigger) 2 years after the form was last sent (updated_at)
-- or the last contact (contacted_at), whichever is later.
CREATE TABLE IF NOT EXISTS leads (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at   TEXT NOT NULL DEFAULT (datetime('now')),
  day          TEXT NOT NULL,
  email        TEXT NOT NULL DEFAULT '',
  phone        TEXT NOT NULL DEFAULT '',
  platform     TEXT NOT NULL DEFAULT '',
  file         TEXT NOT NULL DEFAULT '',
  page         TEXT NOT NULL DEFAULT '',
  lang         TEXT NOT NULL DEFAULT '',
  placement    TEXT NOT NULL DEFAULT '',
  country      TEXT NOT NULL DEFAULT '',
  user_agent   TEXT NOT NULL DEFAULT '',
  downloads    INTEGER NOT NULL DEFAULT 1,
  contacted    INTEGER NOT NULL DEFAULT 0,
  contacted_at TEXT,
  note         TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS leads_day_email ON leads (day, email);
CREATE INDEX IF NOT EXISTS leads_day_phone ON leads (day, phone);
CREATE INDEX IF NOT EXISTS leads_created ON leads (created_at);
CREATE INDEX IF NOT EXISTS leads_updated ON leads (updated_at);

-- Rate limit for the form: submissions per hour per visitor, for today only. visitor is a SHA-256 of
-- (secret + date + IP, or the /64 network for IPv6), cut to 32 characters; no IP address is stored.
-- One more row, visitor '*' and hour = the date, counts today's new leads in all (a daily cap).
-- The worker's daily Cron Trigger deletes earlier days' rows.
CREATE TABLE IF NOT EXISTS lead_limits (
  visitor TEXT NOT NULL,
  hour    TEXT NOT NULL,
  n       INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (visitor, hour)
);
