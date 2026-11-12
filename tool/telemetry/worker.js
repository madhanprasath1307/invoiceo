// Invoiceo usage counter — a Cloudflare Worker with a D1 database bound as DB.
// Paste this file into the Worker's code editor and deploy.
//
//   POST /v1/ping   {"id": "<install id>", "event": "install" | "active" | "first_invoice",
//                    "version": "1.0.3", "os": "windows" | "macos" | "linux" | "other"}
//                   Stores the event (once per install for install / first_invoice,
//                   once per install per day for active). Never stores IP addresses.
//   GET  /v1/stats?key=<STATS_KEY>
//                   Totals as JSON. Needs a secret named STATS_KEY on the Worker.
//
// Download form on invoiceo.in (an email and/or a phone / WhatsApp number, left before a download;
// not an account). Table `leads`, created by migrations/0001_leads.sql. See README-leads.md.
//   POST /v1/lead   {"email", "phone", "platform", "file", "page", "lang", "placement", "hp"}
//                   From the website only (CORS: invoiceo.in, www.invoiceo.in, and localhost for testing).
//                   204 = saved (or dropped as spam), 400 = not valid, 403 = other website, 429 = too many.
//   GET  /v1/leads.csv?key=<STATS_KEY>[&since=YYYY-MM-DD]   the leads as a spreadsheet file, newest first
//   GET  /v1/leads?key=<STATS_KEY>[&since=YYYY-MM-DD]       the same as JSON
// A daily Cron Trigger (wrangler.toml [triggers]) deletes yesterday's rate-limit counters and leads
// older than 2 years.

const EVENTS = new Set(['install', 'active', 'first_invoice']);
const ONCE = new Set(['install', 'first_invoice']);
const OSES = new Set(['windows', 'macos', 'linux', 'other']);

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/v1/ping' && request.method === 'POST') return ping(request, env);
    if (url.pathname === '/v1/stats' && request.method === 'GET') return stats(url, env);
    if (url.pathname === '/v1/lead') {
      if (request.method === 'OPTIONS') return leadPreflight(request);
      if (request.method === 'POST') return lead(request, env);
    }
    if (url.pathname === '/v1/leads.csv' && request.method === 'GET') return leadsExport(url, env, 'csv');
    if (url.pathname === '/v1/leads' && request.method === 'GET') return leadsExport(url, env, 'json');
    return new Response('Not found', { status: 404 });
  },
  // Daily (wrangler.toml [triggers] crons): the clean-up the privacy page promises.
  async scheduled(event, env, ctx) {
    ctx.waitUntil(cleanUp(env));
  },
};

async function ping(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return new Response('Bad request', { status: 400 });
  }
  const id = String(body.id || '');
  const event = String(body.event || '');
  const version = String(body.version || '');
  const os = OSES.has(body.os) ? body.os : 'other';
  if (!/^[A-Za-z0-9_-]{8,64}$/.test(id) || !EVENTS.has(event) || !/^\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(version)) {
    return new Response('Bad request', { status: 400 });
  }
  const day = new Date().toISOString().slice(0, 10);
  if (ONCE.has(event)) {
    await env.DB.prepare(
      `INSERT INTO events (install_id, event, day, version, os)
       SELECT ?1, ?2, ?3, ?4, ?5
       WHERE NOT EXISTS (SELECT 1 FROM events WHERE install_id = ?1 AND event = ?2)`
    ).bind(id, event, day, version, os).run();
  } else {
    await env.DB.prepare(
      'INSERT OR IGNORE INTO events (install_id, event, day, version, os) VALUES (?1, ?2, ?3, ?4, ?5)'
    ).bind(id, event, day, version, os).run();
  }
  return new Response(null, { status: 204 });
}

async function stats(url, env) {
  if (!env.STATS_KEY || url.searchParams.get('key') !== env.STATS_KEY) {
    return new Response('Not found', { status: 404 });
  }
  const one = (sql, ...args) => env.DB.prepare(sql).bind(...args).first('n');
  const all = async (sql) => (await env.DB.prepare(sql).all()).results;
  const active = (days) => one(
    `SELECT COUNT(DISTINCT install_id) AS n FROM events
     WHERE event = 'active' AND day >= date('now', ?1)`, `-${days - 1} days`);
  const data = {
    installs: await one(`SELECT COUNT(*) AS n FROM events WHERE event = 'install'`),
    first_invoices: await one(`SELECT COUNT(*) AS n FROM events WHERE event = 'first_invoice'`),
    active_today: await active(1),
    active_7_days: await active(7),
    active_30_days: await active(30),
    installs_by_day: await all(
      `SELECT day, COUNT(*) AS installs FROM events WHERE event = 'install'
       GROUP BY day ORDER BY day DESC LIMIT 60`),
    first_invoices_by_day: await all(
      `SELECT day, COUNT(*) AS first_invoices FROM events WHERE event = 'first_invoice'
       GROUP BY day ORDER BY day DESC LIMIT 60`),
    installs_by_os: await all(
      `SELECT os, COUNT(*) AS installs FROM events WHERE event = 'install' GROUP BY os ORDER BY installs DESC`),
    active_7_days_by_version: await all(
      `SELECT version, COUNT(DISTINCT install_id) AS installs FROM events
       WHERE event = 'active' AND day >= date('now', '-6 days') GROUP BY version ORDER BY version DESC`),
  };
  return new Response(JSON.stringify(data, null, 2), {
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });
}

// ───────────────────────── Download form (leads) ─────────────────────────
// What is stored: only what the visitor typed (email and/or phone), which installer, the page, the
// language, where on the page the button was, the country Cloudflare gives for the request, and a
// short browser name ("Chrome on Windows"). Never the IP address. The rate limit keeps, for one day
// only, a counter per SHA-256 of (secret + date + IP; for IPv6 only the /64 network, because one home
// line or server has a whole /64 of addresses); the date in the hash changes every day, so counters
// cannot be linked across days, and the daily clean-up deletes them. A second counter caps the new
// leads per day in all, so a flood cannot fill the database or use up D1's daily quota, which the
// app's usage counts (/v1/ping) share.

const LEAD_ORIGINS = new Set(['https://invoiceo.in', 'https://www.invoiceo.in']);
const LOCAL_ORIGIN = /^http:\/\/(127\.0\.0\.1|localhost)(:\d{1,5})?$/;
const LEAD_PLATFORMS = new Set(['windows', 'mac', 'linux_deb', 'linux_appimage']);
const LEAD_FILES = new Set(['Invoiceo-Setup-Windows.exe', 'Invoiceo-macOS.dmg', 'Invoiceo-Linux.deb', 'Invoiceo-Linux.AppImage']);
const LEAD_LANGS = new Set(['en', 'ta', 'hi']);
const LEADS_PER_HOUR = 5;          // per visitor (per hashed IP or IPv6 /64), counted on valid submissions
const NEW_LEADS_PER_DAY = 500;     // new rows per day in all (the LEADS_PER_DAY variable can change it)
const ALL = '*';                   // lead_limits.visitor of the daily total (hour = the date)
const KEEP = '-2 years';           // a lead is deleted 2 years after the form was last sent or the last contact
// The same rule as the website's form (assets/js/site.js), so anything the form accepts is accepted here.
const EMAIL_RE = /^[a-z0-9.!#$%&'*+/=?^_`{|}~-]{1,64}@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*\.[a-z]{2,24}$/;

function leadOrigin(request) {
  const o = request.headers.get('Origin') || '';
  return LEAD_ORIGINS.has(o) || LOCAL_ORIGIN.test(o) ? o : '';
}

function leadHeaders(origin, extra = {}) {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
    'Cache-Control': 'no-store',
    ...extra,
  };
}

function leadPreflight(request) {
  const origin = leadOrigin(request);
  if (!origin) return new Response(null, { status: 403, headers: { 'Vary': 'Origin' } });
  return new Response(null, { status: 204, headers: leadHeaders(origin) });
}

function normEmail(raw) {
  const s = String(raw ?? '').trim().toLowerCase();
  if (!s) return '';
  return s.length <= 254 && EMAIL_RE.test(s) ? s : null;
}

// Phone / WhatsApp number as + and digits (E.164). Without a + it is an Indian mobile: 10 digits
// starting with 6-9 (a leading 0 or 91 is accepted and dropped).
function normPhone(raw) {
  const s = String(raw ?? '').trim();
  if (!s) return '';
  if (s.length > 32 || !/^[+\d\s().-]+$/.test(s)) return null;
  let d = s.replace(/[\s().-]/g, '');
  let intl = false;
  if (d.startsWith('+')) { intl = true; d = d.slice(1); }
  else if (d.startsWith('00')) { intl = true; d = d.slice(2); }
  if (!/^\d+$/.test(d)) return null;
  if (!intl) {
    if (d.length === 11 && d[0] === '0') d = d.slice(1);
    else if (d.length === 12 && d.startsWith('91')) d = d.slice(2);
    if (!/^[6-9]\d{9}$/.test(d)) return null;
    d = '91' + d;
  }
  if (d.length === 13 && d.startsWith('910')) d = '91' + d.slice(3);
  if (d.startsWith('91') && !/^91[6-9]\d{9}$/.test(d)) return null;
  if (d.length < 8 || d.length > 15 || d[0] === '0') return null;
  return '+' + d;
}

function uaShort(ua) {
  ua = String(ua || '');
  const os = /Windows/.test(ua) ? 'Windows' : /Android/.test(ua) ? 'Android' : /iPhone|iPad|iPod/.test(ua) ? 'iOS'
    : /Macintosh|Mac OS X/.test(ua) ? 'macOS' : /CrOS/.test(ua) ? 'ChromeOS' : /Linux/.test(ua) ? 'Linux' : 'other';
  const br = /Edg\//.test(ua) ? 'Edge' : /OPR\/|Opera/.test(ua) ? 'Opera' : /SamsungBrowser/.test(ua) ? 'Samsung Internet'
    : /Firefox\//.test(ua) ? 'Firefox' : /Chrome\//.test(ua) ? 'Chrome' : /Safari\//.test(ua) ? 'Safari' : 'other';
  return `${br} on ${os}`;
}

// The part of the address that stands for one visitor: an IPv4 address as it is, an IPv6 address's
// first 4 groups (its /64 network).
function ipKey(ip) {
  ip = String(ip || '').trim().toLowerCase().split('%')[0];
  if (!ip.includes(':')) return ip;
  const [head, tail] = ip.includes('::') ? ip.split('::') : [ip, null];
  const h = head ? head.split(':') : [];
  const t = tail ? tail.split(':') : [];
  const v4 = t.length && t[t.length - 1].includes('.') ? 1 : 0;   // an IPv4 ending takes 2 groups
  const groups = tail === null ? h : [...h, ...Array(Math.max(8 - h.length - t.length - v4, 0)).fill('0'), ...t];
  return groups.slice(0, 4).map((g) => (parseInt(g, 16) || 0).toString(16)).join(':') + '::/64';
}

async function sha256Hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

// Compares the key with the secret in constant time (both are hashed first, so lengths do not leak).
async function sameSecret(given, secret) {
  if (!secret || typeof given !== 'string' || !given) return false;
  const [a, b] = await Promise.all([sha256Hex(given), sha256Hex(secret)]);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function lead(request, env) {
  const origin = leadOrigin(request);
  if (!origin) return new Response('Forbidden', { status: 403, headers: { 'Vary': 'Origin' } });
  const reply = (status, body = null) => new Response(body, { status, headers: leadHeaders(origin) });

  if (Number(request.headers.get('Content-Length') || 0) > 4096) return reply(413, 'Too large');
  let body;
  try {
    const text = await request.text();
    if (text.length > 4096) return reply(413, 'Too large');
    body = JSON.parse(text);
  } catch {
    return reply(400, 'Bad request');
  }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return reply(400, 'Bad request');
  if (String(body.hp ?? '').trim()) return reply(204);        // the hidden field was filled in: a bot

  const email = normEmail(body.email);
  const phone = normPhone(body.phone);
  if (email === null || phone === null || (!email && !phone)) return reply(400, 'Bad request');
  const str = (v) => (typeof v === 'string' ? v : '');
  const platform = LEAD_PLATFORMS.has(body.platform) ? body.platform : 'other';
  const file = LEAD_FILES.has(body.file) ? body.file : '';
  const page = /^\/[A-Za-z0-9._\/-]{0,80}$/.test(str(body.page)) ? str(body.page) : '';
  const lang = LEAD_LANGS.has(body.lang) ? body.lang : 'other';
  const placement = /^[a-z0-9_-]{1,40}$/.test(str(body.placement)) ? str(body.placement) : '';
  const country = /^[A-Z0-9]{2}$/.test(String(request.cf?.country || '')) ? request.cf.country : '';
  const browser = uaShort(request.headers.get('User-Agent'));

  const now = new Date().toISOString();
  const day = now.slice(0, 10);
  const hour = now.slice(0, 13);
  const ip = ipKey(request.headers.get('CF-Connecting-IP'));
  const visitor = (await sha256Hex(`${env.LEAD_SALT || env.STATS_KEY || ''}|${day}|${ip}`)).slice(0, 32);
  const perDay = Number(env.LEADS_PER_DAY) || NEW_LEADS_PER_DAY;
  try {
    // The daily total first: once it is reached, a request costs one read and no writes.
    const total = await env.DB.prepare('SELECT n FROM lead_limits WHERE visitor = ?1 AND hour = ?2')
      .bind(ALL, day).first('n');
    if (total >= perDay) return reply(429, 'Too many requests');
    // Per visitor: a counter per hashed IP (IPv6: /64) and hour, kept for today only.
    const count = await env.DB.prepare(
      `INSERT INTO lead_limits (visitor, hour, n) VALUES (?1, ?2, 1)
       ON CONFLICT (visitor, hour) DO UPDATE SET n = n + 1 RETURNING n`
    ).bind(visitor, hour).first('n');
    if (count > LEADS_PER_HOUR) return reply(429, 'Too many requests');

    // The same email or phone again on the same day updates that row instead of adding another, but
    // only when nothing in it differs: an empty email or phone is filled in, a stored one is never
    // replaced (a different email or phone with it is a new row).
    const same = await env.DB.prepare(
      `SELECT id FROM leads WHERE day = ?1 AND ((?2 <> '' AND email = ?2) OR (?3 <> '' AND phone = ?3))
         AND (?2 = '' OR email = '' OR email = ?2) AND (?3 = '' OR phone = '' OR phone = ?3)
       ORDER BY id DESC LIMIT 1`
    ).bind(day, email, phone).first('id');
    if (same) {
      await env.DB.prepare(
        `UPDATE leads SET email = CASE WHEN email = '' THEN ?2 ELSE email END,
                          phone = CASE WHEN phone = '' THEN ?3 ELSE phone END,
                          platform = ?4, file = ?5, page = ?6, lang = ?7, placement = ?8, country = ?9,
                          user_agent = ?10, downloads = downloads + 1, updated_at = datetime('now')
         WHERE id = ?1`
      ).bind(same, email, phone, platform, file, page, lang, placement, country, browser).run();
    } else {
      await env.DB.batch([
        env.DB.prepare(
          `INSERT INTO leads (day, email, phone, platform, file, page, lang, placement, country, user_agent)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)`
        ).bind(day, email, phone, platform, file, page, lang, placement, country, browser),
        env.DB.prepare(
          `INSERT INTO lead_limits (visitor, hour, n) VALUES (?1, ?2, 1)
           ON CONFLICT (visitor, hour) DO UPDATE SET n = n + 1`
        ).bind(ALL, day),
      ]);
    }
  } catch {
    return reply(503, 'Try again later');   // e.g. the table is not there yet; the website retries once later
  }
  return reply(204);
}

// Daily clean-up (the Cron Trigger), also run before the leads are read: earlier days' rate-limit
// counters, and leads 2 years after the form was last sent (updated_at) or the last contact.
async function cleanUp(env) {
  const today = new Date().toISOString().slice(0, 10);
  await env.DB.batch([
    env.DB.prepare('DELETE FROM lead_limits WHERE hour < ?1').bind(today),
    env.DB.prepare(
      `DELETE FROM leads WHERE updated_at < datetime('now', ?1)
         AND (contacted_at IS NULL OR contacted_at < datetime('now', ?1))`
    ).bind(KEEP),
  ]);
}

function phoneShown(p) {
  return /^\+91\d{10}$/.test(p) ? `+91 ${p.slice(3, 8)} ${p.slice(8)}` : p;
}

// A spreadsheet never runs a cell that starts with = + - @ (or a tab / return) as a formula when it
// starts with an apostrophe instead. Every cell is quoted.
function csvCell(v) {
  let s = v === null || v === undefined ? '' : String(v);
  if (/^[=+\-@\t\r]/.test(s)) s = "'" + s;
  return '"' + s.replace(/"/g, '""') + '"';
}

async function leadsExport(url, env, format) {
  if (!(await sameSecret(url.searchParams.get('key'), env.STATS_KEY))) {
    return new Response('Not found', { status: 404 });
  }
  await cleanUp(env);
  const since = url.searchParams.get('since') || '';
  if (since && !/^\d{4}-\d{2}-\d{2}$/.test(since)) return new Response('since must be YYYY-MM-DD', { status: 400 });
  const rows = (await env.DB.prepare(
    `SELECT id, created_at, updated_at, email, phone, platform, file, page, lang, placement, country,
            user_agent, downloads, contacted, contacted_at, note
     FROM leads WHERE created_at >= ?1 ORDER BY created_at DESC, id DESC LIMIT 5000`
  ).bind(since || '0000-00-00').all()).results;
  const noStore = { 'Cache-Control': 'no-store', 'X-Robots-Tag': 'noindex' };
  if (format === 'json') {
    return new Response(JSON.stringify({ count: rows.length, leads: rows }, null, 2), {
      headers: { 'Content-Type': 'application/json; charset=utf-8', ...noStore },
    });
  }
  const cols = ['id', 'created_at_utc', 'updated_at_utc', 'email', 'phone', 'whatsapp_link', 'platform', 'file', 'page', 'lang',
    'placement', 'country', 'browser', 'downloads', 'contacted', 'contacted_at_utc', 'note'];
  const lines = [cols.map(csvCell).join(',')];
  for (const r of rows) {
    lines.push([r.id, r.created_at, r.updated_at, r.email, phoneShown(r.phone),
      r.phone ? `https://wa.me/${r.phone.slice(1)}` : '', r.platform, r.file, r.page, r.lang, r.placement, r.country,
      r.user_agent, r.downloads, r.contacted, r.contacted_at, r.note].map(csvCell).join(','));
  }
  const today = new Date().toISOString().slice(0, 10);
  return new Response('﻿' + lines.join('\r\n') + '\r\n', {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="invoiceo-leads-${today}.csv"`,
      ...noStore,
    },
  });
}
