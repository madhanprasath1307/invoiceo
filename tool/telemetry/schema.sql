-- Invoiceo usage counter: one table in a Cloudflare D1 database.
-- Paste this into the D1 database's Console and run it once.
--
-- One row per event. No business data and no IP addresses are stored:
--   install_id  random ID the app creates on first start (not a hardware ID)
--   event       'install' (first start), 'active' (once a day), 'first_invoice'
--   day         UTC date of the event, YYYY-MM-DD
--   version     app version, e.g. 1.0.3
--   os          windows / macos / linux / other
CREATE TABLE IF NOT EXISTS events (
  install_id TEXT NOT NULL,
  event      TEXT NOT NULL,
  day        TEXT NOT NULL,
  version    TEXT NOT NULL,
  os         TEXT NOT NULL,
  at         TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (install_id, event, day)
);
CREATE INDEX IF NOT EXISTS events_event_day ON events (event, day);

-- Download form on invoiceo.in (added November 2026). The same as migrations/0001_leads.sql, which
-- is the file to run on the existing database; it is copied here so schema.sql builds the whole database.
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
