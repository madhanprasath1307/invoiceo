/* Invoiceo website: menu, "recommended download", links from config.js,
   install help after a download starts, optional analytics. No libraries. */
(function () {
  'use strict';
  var C = window.INVOICEO || {};
  // Words this script writes into the page, in the page's language (ta.html is Tamil).
  var TA = document.documentElement.lang === 'ta';
  var HI = document.documentElement.lang === 'hi';
  var T = HI ? {
    soon: 'जल्द आ रहा है',
    phoneButton: 'लिंक कंप्यूटर पर भेजें',
    sendText: 'Invoiceo — मुफ़्त बिलिंग सॉफ़्टवेयर। अपने कंप्यूटर पर खोलकर डाउनलोड कीजिए:',
    sendUrl: 'https://invoiceo.in/hi.html#download',
    copied: 'लिंक कॉपी हो गया', copyPrompt: 'यह लिंक कॉपी कीजिए:',
    downloadFor: function (n) { return n + ' के लिए डाउनलोड'; },
    phoneMeta: 'Invoiceo, Windows, macOS और Linux कंप्यूटर के लिए डेस्कटॉप ऐप है। इंस्टॉल करने के लिए यह पेज अपने कंप्यूटर पर खोलिए।',
    free: 'मुफ़्त', version: 'संस्करण ', alsoBefore: ' · ', alsoAfter: ' के लिए भी उपलब्ध', and: ' और ',
    started: 'डाउनलोड शुरू हो गया।', steps: 'पूरे कदम', stepsPage: '', close: 'बंद करें',
    help: {
      windows: 'डाउनलोड पूरा होने पर फ़ाइल खोलिए। अगर <b>“Windows protected your PC”</b> दिखे, तो <b>More info</b> दबाइए, फिर <b>Run anyway</b>।',
      mac: 'फ़ाइल खोलकर Invoiceo को Applications में खींचिए। पहली बार macOS रोके तो <b>System Settings → Privacy &amp; Security</b> खोलकर <b>Open Anyway</b> दबाइए।',
      linux_deb: 'जिस फ़ोल्डर में डाउनलोड हुई है वहाँ <code>sudo apt install ./Invoiceo-Linux.deb</code> चलाइए।',
      linux_appimage: '<code>chmod +x Invoiceo-Linux.AppImage</code> चलाइए, फिर खोलिए।'
    }
  } : TA ? {
    soon: 'விரைவில்',
    phoneButton: 'லிங்கைக் கணினிக்கு அனுப்பு',
    sendText: 'Invoiceo — இலவச பில்லிங் சாஃப்ட்வேர். கணினியில் திறந்து டவுன்லோட் செய்யுங்கள்:',
    sendUrl: 'https://invoiceo.in/ta.html#download',
    copied: 'லிங்க் காப்பி ஆனது', copyPrompt: 'இந்த லிங்கை காப்பி செய்யுங்கள்:',
    downloadFor: function (n) { return n + '-க்கு டவுன்லோட்'; },
    phoneMeta: 'Invoiceo, Windows, macOS, Linux கணினிகளுக்கான டெஸ்க்டாப் ஆப். இன்ஸ்டால் செய்ய இந்தப் பக்கத்தை உங்கள் கணினியில் திறக்கவும்.',
    free: 'இலவசம்', version: 'பதிப்பு ', alsoBefore: ' · ', alsoAfter: '-க்கும் உண்டு', and: ' மற்றும் ',
    started: 'டவுன்லோட் தொடங்கிவிட்டது.', steps: 'முழு வழிமுறைகள்', stepsPage: '', close: 'மூடு',
    help: {
      windows: 'டவுன்லோட் முடிந்ததும் ஃபைலைத் திறக்கவும். <b>“Windows protected your PC”</b> என்று வந்தால் <b>More info</b>, பிறகு <b>Run anyway</b> அழுத்தவும்.',
      mac: 'ஃபைலைத் திறந்து Invoiceo-வை Applications-க்குள் இழுத்து விடவும். முதல் முறை macOS தடுத்தால், <b>System Settings → Privacy &amp; Security</b> திறந்து <b>Open Anyway</b> அழுத்தவும்.',
      linux_deb: 'டவுன்லோட் ஆன ஃபோல்டரில் <code>sudo apt install ./Invoiceo-Linux.deb</code> இயக்கவும்.',
      linux_appimage: '<code>chmod +x Invoiceo-Linux.AppImage</code> இயக்கி, பிறகு திறக்கவும்.'
    }
  } : {
    soon: 'Coming soon',
    phoneButton: 'Send the link to my computer',
    sendText: 'Invoiceo, free billing software for your computer. Open this on your computer to download it:',
    sendUrl: 'https://invoiceo.in/download.html',
    copied: 'Link copied', copyPrompt: 'Copy this link:',
    downloadFor: function (n) { return 'Download for ' + n; },
    phoneMeta: 'Invoiceo is a desktop app for Windows, macOS and Linux. Open this page on your computer to install it.',
    free: 'Free', version: 'Version ', alsoBefore: ' · Also for ', alsoAfter: '', and: ' and ',
    started: 'Your download has started.', steps: 'Full install steps', stepsPage: 'download.html', close: 'Close',
    pics: 'See it with pictures', warnAnchor: 'windows-warning',
    help: {
      windows: 'Open the file when it has downloaded. If a blue window says <b>“Windows protected your PC”</b>, click <b>More info</b>, then <b>Run anyway</b>.',
      mac: 'Open the file and drag Invoiceo into Applications. The first time, macOS may block it: open <b>System Settings → Privacy &amp; Security</b> and click <b>Open Anyway</b>.',
      linux_deb: 'Install it with <code>sudo apt install ./Invoiceo-Linux.deb</code> in the folder you downloaded it to.',
      linux_appimage: 'Make it runnable with <code>chmod +x Invoiceo-Linux.AppImage</code>, then open it.'
    }
  };

  // Mobile menu
  var toggle = document.querySelector('.menu-toggle');
  var nav = document.getElementById('site-nav');
  if (toggle && nav) {
    toggle.addEventListener('click', function () {
      var open = nav.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    nav.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () {
        nav.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
      });
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && nav.classList.contains('open')) {
        nav.classList.remove('open');
        toggle.setAttribute('aria-expanded', 'false');
        toggle.focus();
      }
    });
  }

  // Year in the footer
  document.querySelectorAll('[data-year]').forEach(function (el) {
    el.textContent = String(new Date().getFullYear());
  });

  // Version / date
  document.querySelectorAll('[data-version]').forEach(function (el) { if (C.version) el.textContent = C.version; });
  document.querySelectorAll('[data-release-date]').forEach(function (el) { if (C.releaseDate) el.textContent = C.releaseDate; });

  // Links that come from config.js. data-hide-empty hides the element (or the
  // closest [data-block]) when the value is not set yet.
  function value(path) {
    return path.split('.').reduce(function (o, k) { return o && o[k]; }, C) || '';
  }
  document.querySelectorAll('[data-href]').forEach(function (el) {
    var url = value(el.getAttribute('data-href'));
    if (url) {
      el.setAttribute('href', url);
    } else {
      var block = el.closest('[data-block]') || el;
      if (el.hasAttribute('data-hide-empty')) {
        block.classList.add('hidden');
      } else {
        el.setAttribute('aria-disabled', 'true');
        el.setAttribute('title', T.soon);
        el.removeAttribute('href');
      }
    }
  });

  // WhatsApp
  var wa = String(C.whatsapp || '').replace(/\D/g, '');
  document.querySelectorAll('[data-whatsapp]').forEach(function (el) {
    if (wa) {
      el.setAttribute('href', 'https://wa.me/' + wa);
    } else {
      (el.closest('[data-block]') || el).classList.add('hidden');
    }
  });
  // Indian numbers read as +91 98765 43210; others as +<digits>.
  var waShown = /^91\d{10}$/.test(wa) ? '+91 ' + wa.slice(2, 7) + ' ' + wa.slice(7) : (wa ? '+' + wa : '');
  document.querySelectorAll('[data-whatsapp-number]').forEach(function (n) { n.textContent = waShown; });

  // Embedded customization form
  var frame = document.getElementById('customization-form');
  if (frame) {
    var embed = value('forms.customizationEmbed');
    var missing = document.getElementById('customization-form-missing');
    var gate = document.getElementById('customization-form-gate');
    if (embed && gate) {   // a Google Form: loaded only when the visitor asks, so nothing from Google loads on the page view
      gate.classList.remove('hidden'); if (missing) missing.classList.add('hidden');
      gate.querySelector('button').addEventListener('click', function () { frame.src = embed; frame.classList.remove('hidden'); gate.classList.add('hidden'); });
    } else if (embed) { frame.src = embed; frame.classList.remove('hidden'); if (missing) missing.classList.add('hidden'); }
  }

  // Installer sizes
  document.querySelectorAll('[data-size]').forEach(function (el) {
    var s = value('sizes.' + el.getAttribute('data-size'));
    if (s) { el.textContent = ' · ' + s; }
  });

  // "Recommended for your computer"
  function detectOS() {
    var ua = (navigator.userAgent || '').toLowerCase();
    var platform = ((navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || '').toLowerCase();
    if (/android|iphone|ipad|ipod/.test(ua)) return 'mobile';
    // iPadOS Safari says "Macintosh"; a touch screen gives it away.
    if ((platform.indexOf('mac') > -1 || ua.indexOf('mac os') > -1) && navigator.maxTouchPoints > 1) return 'mobile';
    if (platform.indexOf('win') > -1 || ua.indexOf('windows') > -1) return 'windows';
    if (platform.indexOf('mac') > -1 || ua.indexOf('mac os') > -1) return 'mac';
    if (platform.indexOf('linux') > -1 || ua.indexOf('linux') > -1) return 'linux';
    return 'other';
  }
  var os = detectOS();
  var names = { windows: 'Windows', mac: 'macOS', linux: 'Linux' };
  var sizeKey = { windows: 'windows', mac: 'mac', linux: 'linuxDeb' };
  var myCard = document.querySelector('[data-platform="' + os + '"]');

  if (os === 'mobile') {
    document.querySelectorAll('[data-mobile-note]').forEach(function (n) { n.classList.remove('hidden'); });
    document.querySelectorAll('[data-hero-send]').forEach(function (n) { n.classList.remove('hidden'); });
  }
  // Highlight the card for this computer (none on phones or unknown systems).
  document.querySelectorAll('[data-platform]').forEach(function (card) {
    card.classList.toggle('is-recommended', card === myCard && !!names[os]);
  });

  // Phones: Invoiceo installs on a computer, so a phone visitor sends the
  // download link to themselves (share menu, WhatsApp or copy) and opens it
  // there later. Counted as send_link (method: share / whatsapp / copy).
  function trackSend(method) {
    if (typeof window.gtag === 'function') {
      window.gtag('event', 'send_link', { method: method, page_path: location.pathname, transport_type: 'beacon' });
    }
  }
  var canShare = typeof navigator.share === 'function';
  function shareLink() {
    navigator.share({ title: 'Invoiceo', text: T.sendText, url: T.sendUrl })
      .then(function () { trackSend('share'); }, function () {});
  }
  document.querySelectorAll('[data-send-share]').forEach(function (b) {
    if (!canShare) return;
    b.classList.remove('hidden');
    b.addEventListener('click', shareLink);
  });
  document.querySelectorAll('[data-send-whatsapp]').forEach(function (a) {
    // No number: WhatsApp asks who to send it to ("Message yourself" works).
    a.setAttribute('href', 'https://wa.me/?text=' + encodeURIComponent(T.sendText + ' ' + T.sendUrl));
    a.addEventListener('click', function () { trackSend('whatsapp'); });
  });
  document.querySelectorAll('[data-send-copy]').forEach(function (b) {
    b.addEventListener('click', function () {
      var label = b.querySelector('span');
      var done = function () {
        var old = label.textContent;
        label.textContent = T.copied;
        setTimeout(function () { label.textContent = old; }, 2000);
        trackSend('copy');
      };
      var manual = function () { window.prompt(T.copyPrompt, T.sendUrl); };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(T.sendUrl).then(done, manual);
      } else {
        manual();
      }
    });
  });

  // Hero button: the installer for this computer, or the download section.
  document.querySelectorAll('[data-os-download]').forEach(function (btn) {
    var label = btn.querySelector('[data-os-label]');
    var mark = btn.querySelector('[data-os-icon]');
    if (os === 'mobile') {
      // Opens the share menu; without one it goes to the download section,
      // where the WhatsApp and Copy link buttons are.
      if (label) label.textContent = T.phoneButton;
      if (canShare) {
        btn.addEventListener('click', function (e) { e.preventDefault(); shareLink(); });
      }
      return;
    }
    var target = myCard && myCard.querySelector('[data-primary-download]');
    if (!names[os] || !target) return;
    btn.setAttribute('href', target.getAttribute('href'));
    if (label) label.textContent = T.downloadFor(names[os]);
    var logo = myCard.querySelector('.tile svg');
    if (mark && logo) { mark.textContent = ''; mark.appendChild(logo.cloneNode(true)); }
  });

  // The small line under the hero buttons
  var meta = document.querySelector('[data-hero-meta]');
  if (meta) {
    if (os === 'mobile') {
      meta.textContent = T.phoneMeta;
    } else if (names[os] && myCard) {
      var size = value('sizes.' + sizeKey[os]);
      var others = Object.keys(names).filter(function (k) { return k !== os; }).map(function (k) { return names[k]; }).join(T.and);
      meta.textContent = [T.free, T.version + (C.version || ''), size, myCard.getAttribute('data-req-short')]
        .filter(Boolean).join(' · ') + T.alsoBefore;
      var more = document.createElement('a');
      more.href = '#download';
      more.textContent = others;
      meta.appendChild(more);
      if (T.alsoAfter) meta.appendChild(document.createTextNode(T.alsoAfter));
    }
  }

  // Install help that appears once a download starts
  function installer(href) {
    var m = /\/releases\/(?:latest\/)?download\/(?:[^/]+\/)?([^/?#]+)$/.exec(href);
    if (!m) return null;
    var file = m[1];
    var platform = /windows|\.exe$/i.test(file) ? 'windows'
      : /macos|\.dmg$/i.test(file) ? 'mac'
      : /\.deb$/i.test(file) ? 'linux_deb'
      : /\.appimage$/i.test(file) ? 'linux_appimage' : null;
    return platform ? { file: file, platform: platform } : null;
  }
  // [help text, anchor of the install steps]. The Tamil page has the steps on itself.
  var HELP = {
    windows: [T.help.windows, 'windows'],
    mac: [T.help.mac, 'macos'],
    linux_deb: [T.help.linux_deb, 'linux'],
    linux_appimage: [T.help.linux_appimage, 'linux']
  };
  var toast = null;
  function showHelp(platform) {
    var help = HELP[platform];
    if (!help) return;
    if (!toast) {
      toast = document.createElement('div');
      toast.className = 'dl-toast';
      toast.setAttribute('role', 'status');
      document.body.appendChild(toast);
    }
    toast.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>'
      + '<div><b>' + T.started + '</b> ' + help[0] + ' <a href="' + T.stepsPage + '#' + ((platform === 'windows' && T.warnAnchor) || help[1]) + '">' + ((platform === 'windows' && T.pics) || T.steps) + '</a></div>'
      + '<button type="button" aria-label="' + T.close + '"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>';
    toast.querySelector('button').addEventListener('click', function () { toast.remove(); toast = null; });
  }

  // Analytics: only when an ID is set in config.js, never on a local preview, and only after the visitor presses Accept in the
  // cookie box. Until then no analytics script is loaded and no cookie is set. The choice is kept in this browser (localStorage).
  var CC_KEY = 'invoiceo-cookie-choice';
  var LOCAL = /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);
  var CC_TEXT = {
    en: { t: 'Cookies', p: 'May we use Google Analytics cookies to count visits and download clicks? It helps us improve the site. Nothing is tracked unless you accept.', yes: 'Accept', no: 'Decline', more: 'Privacy policy', label: 'Cookie choice' },
    ta: { t: 'குக்கீகள்', p: 'வருகைகளையும் பதிவிறக்க கிளிக்குகளையும் எண்ண Google Analytics குக்கீகளைப் பயன்படுத்தலாமா? தளத்தை மேம்படுத்த இது உதவும். நீங்கள் ஏற்றுக்கொள்ளாவிட்டால் எதுவும் கண்காணிக்கப்படாது.', yes: 'ஏற்கிறேன்', no: 'வேண்டாம்', more: 'தனியுரிமைக் கொள்கை', label: 'குக்கீ தேர்வு' },
    hi: { t: 'कुकी', p: 'क्या हम विज़िट और डाउनलोड क्लिक गिनने के लिए Google Analytics कुकी इस्तेमाल कर सकते हैं? इससे साइट बेहतर बनाने में मदद मिलती है। आपके स्वीकार किए बिना कुछ भी ट्रैक नहीं होता।', yes: 'स्वीकार करें', no: 'मना करें', more: 'गोपनीयता नीति', label: 'कुकी का चुनाव' }
  };
  var CCT = CC_TEXT[(document.documentElement.lang || 'en').slice(0, 2)] || CC_TEXT.en;
  function ccGet() { try { return window.localStorage.getItem(CC_KEY); } catch (e) { return null; } }
  function ccSet(v) { try { window.localStorage.setItem(CC_KEY, v); } catch (e) {} }
  var analyticsOn = false;
  function startAnalytics() {
    if (analyticsOn || !C.analyticsId || LOCAL) return;
    analyticsOn = true;
    window['ga-disable-' + C.analyticsId] = false;
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(C.analyticsId);
    document.head.appendChild(s);
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    // Visit counts only: no Google signals or ad personalisation.
    window.gtag('config', C.analyticsId, {
      anonymize_ip: true,
      allow_google_signals: false,
      allow_ad_personalization_signals: false
    });
  }
  function stopAnalytics() {          // declining: stop sending and remove the analytics cookies this site could have set
    if (C.analyticsId) window['ga-disable-' + C.analyticsId] = true;
    window.gtag = undefined;
    var host = location.hostname.split('.'), domains = ['', location.hostname, '.' + location.hostname];
    if (host.length > 2) domains.push('.' + host.slice(-2).join('.'));
    document.cookie.split(';').forEach(function (c) {
      var name = c.split('=')[0].trim();
      if (name.indexOf('_ga') === 0 || name === '_gid') domains.forEach(function (d) {
        document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/' + (d ? '; domain=' + d : '');
      });
    });
    analyticsOn = false;
  }
  var ccBox = null;
  function ccClose() { if (ccBox && ccBox.parentNode) ccBox.parentNode.removeChild(ccBox); ccBox = null; }
  function ccOpen() {
    if (!C.analyticsId || ccBox) return;
    ccBox = document.createElement('div');
    ccBox.className = 'cc';
    ccBox.setAttribute('role', 'region');
    ccBox.setAttribute('aria-label', CCT.label);
    ccBox.innerHTML = '<p class="cc-t">' + CCT.t + '</p><p>' + CCT.p + ' <a href="' + (LANG_HOME_PRE() + 'privacy.html') + '">' + CCT.more + '</a></p>' +
      '<div class="cc-btns"><button type="button" class="btn btn-secondary" data-cc="no">' + CCT.no + '</button><button type="button" class="btn btn-primary" data-cc="yes">' + CCT.yes + '</button></div>';
    ccBox.addEventListener('click', function (e) {
      var b = e.target.closest && e.target.closest('[data-cc]');
      if (!b) return;
      var yes = b.getAttribute('data-cc') === 'yes';
      ccSet(yes ? 'yes' : 'no');
      if (yes) startAnalytics(); else stopAnalytics();
      ccClose();
    });
    document.body.appendChild(ccBox);
    var first = ccBox.querySelector('[data-cc="no"]');
  }
  function LANG_HOME_PRE() { return /\/(index\.html)?$/.test(location.pathname) || /\/(ta|hi)\.html$/.test(location.pathname) ? '' : '/'; }
  document.addEventListener('click', function (e) {
    var l = e.target.closest && e.target.closest('[data-cookie-settings]');
    if (!l) return;
    e.preventDefault();
    ccOpen();
  });
  if (C.analyticsId) {
    var choice = ccGet();
    if (choice === 'yes') startAnalytics();
    else if (choice !== 'no') window.setTimeout(ccOpen, 700);
  }

  // Download tracking (only sends anything when analytics is on).
  //   download_click       a click on an installer link (GitHub release file)
  //   download_page_click  a click on a link that leads to the Download page or section
  function placement(a) {
    if (a.closest('.site-header')) return 'header';
    if (a.closest('.site-footer')) return 'footer';
    if (a.closest('.dl-toast')) return 'install_help';
    if (a.closest('[data-platform]')) return 'platform_card';
    if (a.closest('.hero')) return 'hero';
    if (a.closest('.cta-band')) return 'cta_band';
    var section = a.closest('section[id]');
    return section ? section.id : 'page_body';
  }
  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[href]');
    if (!a) return;
    var href = a.href;
    var file = installer(href);
    if (file) showHelp(file.platform);
    if (typeof window.gtag !== 'function') return;
    if (file) {
      window.gtag('event', 'download_click', {
        platform: file.platform,
        file_name: file.file,
        placement: placement(a),
        detected_os: os,
        page_path: location.pathname,
        transport_type: 'beacon'
      });
    } else if (/\/download\.html(?:[?#]|$)|#download$/.test(href)) {
      window.gtag('event', 'download_page_click', {
        placement: placement(a),
        link_text: (a.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 60),
        detected_os: os,
        page_path: location.pathname,
        transport_type: 'beacon'
      });
    }
  });
})();

/* First-visit poster ("Help us reach 5,000 downloads", with the count so far). English home page only.
   The number comes from config.js (milestone.downloads) and nothing shows when it is
   empty, so the page never states a figure that has not been checked. Shown once per
   browser for each number; ?milestone on the address shows it again for a preview. */
(function () {
  'use strict';
  var C = window.INVOICEO || {};
  var M = C.milestone || {};
  var n = parseInt(M.downloads, 10);
  if (!n || n < 1) return;
  if (document.documentElement.lang !== 'en') return;
  if (!/^\/(index\.html)?$/.test(location.pathname)) return;
  var key = 'invoiceo_milestone_' + n;
  var preview = /[?&]milestone(?:[=&]|$)/.test(location.search);
  try { if (!preview && localStorage.getItem(key)) return; } catch (e) { return; }
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var root = null, opener = null;

  function remember() { try { localStorage.setItem(key, '1'); } catch (e) {} }
  function track(action) {
    if (typeof window.gtag === 'function') {
      window.gtag('event', 'milestone_poster', { action: action, milestone: n, transport_type: 'beacon' });
    }
  }
  function close(action) {
    if (!root) return;
    remember();
    track(action);
    document.documentElement.classList.remove('mile-open');
    root.classList.add('mile-out');
    var gone = root;
    root = null;
    document.removeEventListener('keydown', onKey, true);
    setTimeout(function () { gone.remove(); }, reduce ? 0 : 220);
    if (opener && opener.focus) opener.focus();
  }
  function onKey(e) {
    if (!root) return;
    if (e.key === 'Escape') { e.preventDefault(); close('dismiss'); return; }
    if (e.key !== 'Tab') return;
    var f = root.querySelectorAll('a[href], button');
    if (!f.length) return;
    var first = f[0], last = f[f.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }
  function confetti(box) {
    var colours = ['#60a5fa', '#34d399', '#fbbf24', '#f472b6', '#a78bfa', '#ffffff'];
    for (var i = 0; i < 30; i++) {
      var c = document.createElement('i');
      var size = 6 + Math.random() * 6;
      c.style.cssText = 'left:' + (Math.random() * 100).toFixed(1) + '%;width:' + size.toFixed(1) + 'px;height:' +
        (size * (Math.random() > 0.5 ? 1 : 0.45)).toFixed(1) + 'px;background:' + colours[i % colours.length] +
        ';animation-delay:' + (Math.random() * 1.4).toFixed(2) + 's;animation-duration:' +
        (2.6 + Math.random() * 1.8).toFixed(2) + 's;--dx:' + (Math.random() * 90 - 45).toFixed(0) + 'px';
      box.appendChild(c);
    }
  }
  function countUp(el, to) {
    if (reduce) { el.textContent = to.toLocaleString('en-IN'); return; }
    var start = null, ms = 1500;
    function step(t) {
      if (start === null) start = t;
      var k = Math.min(1, (t - start) / ms);
      var eased = 1 - Math.pow(1 - k, 3);
      el.textContent = Math.round(to * eased).toLocaleString('en-IN');
      if (k < 1) window.requestAnimationFrame(step);
    }
    window.requestAnimationFrame(step);
  }
  function open() {
    if (root) return;
    opener = document.activeElement;
    var goal = parseInt(M.goal, 10);
    var goalMode = goal > n;
    var fmt = function (v) { return v.toLocaleString('en-IN'); };
    var pct = goalMode ? Math.max(3, Math.min(100, Math.round(n * 100 / goal))) : 0;
    var asOf = M.asOf ? 'Counted up to ' + M.asOf + '.' : '';
    // The poster's font (Poppins) is declared in site.css and only loads once the poster uses it.
    root = document.createElement('div');
    root.className = 'mile';
    var head = goalMode
      ? '<p class="mile-eyebrow">Help us reach</p>' +
        '<h2 id="mile-title" class="mile-title"><span class="mile-big">' + fmt(goal) + '</span><span class="mile-unit">downloads</span></h2>' +
        '<div class="mile-bar" aria-hidden="true"><span style="--to:' + pct + '%"></span></div>' +
        '<p class="mile-so"><b class="mile-num">0</b><b>+</b> downloads so far</p>'
      : '<p class="mile-eyebrow">Thank you</p>' +
        '<h2 id="mile-title" class="mile-title"><span class="mile-just">Just crossed</span><span class="mile-big"><span class="mile-num">0</span>+</span><span class="mile-unit">downloads</span></h2>';
    root.innerHTML =
      '<div class="mile-card" role="dialog" aria-modal="true" aria-labelledby="mile-title">' +
      '<button type="button" class="mile-x" aria-label="Close"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>' +
      '<div class="mile-confetti" aria-hidden="true"></div>' +
      '<div class="mile-logo"><img src="assets/images/logo.png" alt="Invoiceo" width="196" height="68"></div>' +
      head +
      '<p class="mile-sub">Free billing software for your computer.<br>No sign-up. No invoice limit.</p>' +
      '<div class="mile-actions"><a class="mile-cta" href="download.html">Download free</a></div>' +
      (asOf ? '<p class="mile-note">' + asOf + '</p>' : '') +
      '</div>';
    document.body.appendChild(root);
    document.documentElement.classList.add('mile-open');
    var title = root.querySelector('.mile-title');
    if (goalMode) title.setAttribute('aria-label', 'Help us reach ' + fmt(goal) + ' downloads. ' + fmt(n) + ' plus so far.');
    else title.setAttribute('aria-label', 'Just crossed ' + fmt(n) + ' plus downloads');
    if (!reduce) confetti(root.querySelector('.mile-confetti'));
    countUp(root.querySelector('.mile-num'), n);
    root.querySelector('.mile-x').addEventListener('click', function () { close('close'); });
    root.querySelector('.mile-cta').addEventListener('click', function () { remember(); track('download'); });
    root.addEventListener('click', function (e) { if (e.target === root) close('backdrop'); });
    document.addEventListener('keydown', onKey, true);
    root.querySelector('.mile-cta').focus();
    track('view');
  }
  setTimeout(open, preview ? 600 : 3500);
})();

/* Screens as tabs. The gallery is plain HTML (every screen and caption is in the page);
   with JavaScript it becomes a tab list, one screen at a time. Whenever the tab bar is on screen the
   tabs play by themselves, left to right, a few seconds apart. A click or arrow key switches to that
   screen and holds it for a while, then the tabs carry on from there. Not for visitors who ask for
   less motion. */
(function () {
  var shots = document.querySelector('.shots');
  if (!shots || !shots.querySelectorAll) return;
  var figs = Array.prototype.slice.call(shots.children).filter(function (el) { return el.classList.contains('shot'); });
  if (figs.length < 2) return;
  var DELAY = 3000;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var list = document.createElement('div');
  list.className = 'tab-list';
  list.setAttribute('role', 'tablist');
  list.style.setProperty('--tab-delay', DELAY + 'ms');
  var HOLD = 5000;                                   // after a click, wait this long before playing on
  var ICONS = [   // one small outline icon per screen, in the order of the tabs
    '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
    '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M12 12v6M9 15h6"/>',
    '<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/>',
    '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    '<path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><path d="M3.3 7L12 12l8.7-5M12 22V12"/>',
    '<path d="M3 3v18h18"/><path d="M7 15l4-5 3 3 5-7"/>',
    '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/>',
    '<path d="M6 2v20l3-2 3 2 3-2 3 2V2z"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="9" y1="12" x2="15" y2="12"/>'
  ];
  var ind = document.createElement('span');
  ind.className = 'tab-ind';
  ind.setAttribute('aria-hidden', 'true');
  list.appendChild(ind);
  var tabs = [], current = 0, timer = 0, holdTimer = 0, inView = false, started = false;
  function place() {                                  // slide the pill under the active tab
    var tab = tabs[current];
    if (!tab || !tab.offsetWidth) return;
    ind.style.width = tab.offsetWidth + 'px';
    ind.style.transform = 'translateX(' + tab.offsetLeft + 'px)';
  }
  function show(i, focus) {
    current = i;
    tabs.forEach(function (t, j) {
      var on = i === j;
      t.setAttribute('aria-selected', on ? 'true' : 'false');
      t.tabIndex = on ? 0 : -1;
      t.classList.toggle('is-done', j < i);
      figs[j].classList.toggle('is-active', on);
      figs[j].hidden = !on;
    });
    place();
    // keep the active tab visible when the list scrolls sideways (phones), without moving the page
    var tab = tabs[i];
    if (list.scrollWidth > list.clientWidth + 2) {
      list.scrollTo({ left: tab.offsetLeft - (list.clientWidth - tab.offsetWidth) / 2, behavior: reduce ? 'auto' : 'smooth' });
    }
    if (focus) tab.focus();
  }
  function visibleNow() {                              // is the tab bar on screen (below the header, above the bottom edge)?
    var r = list.getBoundingClientRect(), h = window.innerHeight || document.documentElement.clientHeight;
    return r.height > 0 && r.bottom > 90 && r.top < h * 0.85;
  }
  function stopTimer() { if (timer) { window.clearTimeout(timer); timer = 0; } list.classList.remove('is-auto'); }
  function play() {
    stopTimer();
    if (reduce || !visibleNow() || document.hidden || holdTimer) return;
    // the printed invoice and the receipt need time to print before the next tab
    var wait = +figs[current].getAttribute('data-dwell') || (figs[current].querySelector('.printer-art') ? 7500 : DELAY);
    list.style.setProperty('--tab-delay', wait + 'ms');
    list.classList.add('is-auto');
    timer = window.setTimeout(function () { timer = 0; show((current + 1) % tabs.length, false); play(); }, wait);
  }
  function choose(i, focus) {                          // the visitor picked a screen: show it, hold, then play on
    stopTimer(); show(i, focus);
    if (holdTimer) window.clearTimeout(holdTimer);
    holdTimer = window.setTimeout(function () { holdTimer = 0; play(); }, HOLD);
  }
  figs.forEach(function (fig, i) {
    var cap = fig.querySelector('figcaption b');
    var tab = document.createElement('button');
    tab.type = 'button';
    tab.className = 'tab-btn';
    tab.setAttribute('role', 'tab');
    tab.id = 'shot-tab-' + i;
    tab.setAttribute('aria-controls', 'shot-panel-' + i);
    var ic = document.createElement('span');
    ic.className = 'tab-ic';
    ic.setAttribute('aria-hidden', 'true');
    ic.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" focusable="false">' + (ICONS[i] || ICONS[0]) + '</svg>';
    tab.appendChild(ic);
    tab.appendChild(document.createTextNode(cap ? cap.textContent : String(i + 1)));
    tab.addEventListener('click', function () { choose(i, false); });
    tab.addEventListener('keydown', function (e) {
      var k = e.key, n = tabs.length;
      if (k === 'ArrowRight') { e.preventDefault(); choose((i + 1) % n, true); }
      else if (k === 'ArrowLeft') { e.preventDefault(); choose((i + n - 1) % n, true); }
      else if (k === 'Home') { e.preventDefault(); choose(0, true); }
      else if (k === 'End') { e.preventDefault(); choose(n - 1, true); }
    });
    fig.id = 'shot-panel-' + i;
    fig.setAttribute('role', 'tabpanel');
    fig.setAttribute('aria-labelledby', tab.id);
    tabs.push(tab);
    list.appendChild(tab);
  });
  shots.parentNode.insertBefore(list, shots);
  window.addEventListener('resize', place);
  window.addEventListener('load', place);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(place);
  shots.classList.add('is-tabs');
  show(0, false);
  document.addEventListener('visibilitychange', play);
  function check() {                                   // on scroll and resize: start when the tab bar comes into view
    var v = visibleNow();
    if (v === inView) return;
    inView = v;
    if (v && !started && !reduce) { started = true; show(0, false); }   // start from the first screen
    play();
  }
  if (!reduce) {
    window.addEventListener('scroll', check, { passive: true });
    window.addEventListener('resize', check);
    window.addEventListener('load', check);
    window.setInterval(check, 1000);                   // a cheap safety net if a scroll event is missed
    check();
  }
})();

/* Header: plain at the top, a floating box after scrolling. --p goes from 0 to 1 over the first 80px,
   and the CSS (box and shadow) follows it, so there is no sudden jump. */
(function () {
  var header = document.querySelector('.site-header');
  if (!header) return;
  function update() {
    var y = window.pageYOffset || document.documentElement.scrollTop || 0;
    header.style.setProperty('--p', Math.max(0, Math.min(1, y / 80)).toFixed(3));
  }
  update();
  window.addEventListener('scroll', update, { passive: true });
})();

/* Hero background: aurora glow and floating documents (all CSS, see site.css). */
(function () {
  var hero = document.querySelector('.hero');
  if (!hero) return;
  var docs = [
    ['<b>INVOICE INV-00021</b><i></i><i></i><div class="tot"><span>€ 4,495.00</span><span class="paid">PAID</span></div>', 'left:3%;top:27%;--r:-2deg;animation-duration:11s'],
    ['<b>Receipt · 80 mm</b><i></i><i style="width:60%"></i><div class="tot"><span>£ 1,036.60</span><span class="paid">PAID</span></div>', 'left:5%;top:68%;--r:2deg;animation-duration:13s;animation-delay:-4s'],
    ['<b>QUOTATION Q-0007</b><i></i><i></i><div class="tot"><span>$ 12,800.00</span></div>', 'right:3%;top:25%;--r:2deg;animation-duration:12s;animation-delay:-2s'],
    ['<b>Tax invoice</b><span>VAT 19%</span><i></i><div class="tot"><span>€ 7,019.10</span><span class="due">DUE</span></div>', 'right:4%;top:64%;--r:-2deg;animation-duration:14s;animation-delay:-6s']
  ];
  var html = '<div class="bg-aurora"><span class="aur a1"></span><span class="aur a2"></span><span class="aur a3"></span></div>' +
    '<div class="bg-docs">' + docs.map(function (d) { return '<div class="doc" style="' + d[1] + '">' + d[0] + '</div>'; }).join('') + '</div>';
  var bg = document.createElement('div');
  bg.className = 'hero-bg';
  bg.setAttribute('aria-hidden', 'true');
  bg.innerHTML = html;
  hero.insertBefore(bg, hero.firstChild);
  // The cards stay in the headline area, above the app window.
  var visual = hero.querySelector('.hero-visual');
  function fit() {
    if (!visual) return;
    var h = visual.getBoundingClientRect().top - hero.getBoundingClientRect().top;
    if (h > 0) bg.style.setProperty('--copy-h', Math.round(h) + 'px');
  }
  fit();
  window.addEventListener('resize', fit);
  window.addEventListener('load', fit);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(fit);
})();

/* Closing call to action: the same floating invoices and chips as the hero, on the home pages. */
(function () {
  var band = document.querySelector('#cta-title');
  band = band && band.closest('.cta-band');
  if (!band) return;
  var deco = document.createElement('div');
  deco.className = 'cta-deco';
  deco.setAttribute('aria-hidden', 'true');
  deco.innerHTML =
    '<div class="doc" style="left:2.5%;top:12%;--r:-4deg;animation-duration:10s"><b>INVOICE INV-00024</b><i></i><i style="width:65%"></i><div class="tot"><span>$ 2,350.00</span><span class="paid">PAID</span></div></div>' +
    '<div class="doc" style="left:3.5%;top:52%;--r:3deg;animation-duration:12s;animation-delay:-4s"><b>Receipt · 58 mm</b><i></i><div class="tot"><span>£ 480.00</span><span class="paid">PAID</span></div></div>' +
    '<div class="doc" style="right:2.5%;top:10%;--r:4deg;animation-duration:11s;animation-delay:-2s"><b>QUOTATION Q-0008</b><i></i><i style="width:60%"></i><div class="tot"><span>€ 9,600.00</span></div></div>' +
    '<div class="doc" style="right:3.5%;top:50%;--r:-3deg;animation-duration:13s;animation-delay:-6s"><b>Tax invoice</b><span>VAT 20%</span><i></i><div class="tot"><span>£ 3,540.00</span><span class="paid">PAID</span></div></div>' +
    '<span class="chip2" style="left:5%;top:86%;animation-duration:8s"><i></i>Works offline</span>' +
    '<span class="chip2" style="right:5%;top:85%;animation-duration:10s;animation-delay:-3s"><i class="b"></i>No sign-up</span>';
  band.insertBefore(deco, band.firstChild);
})();

/* "How it works": clicking a step, or scrolling it to the middle of the screen, switches the picture. */
(function () {
  var flow = document.querySelector('.flow-steps');
  if (!flow) return;
  var steps = Array.prototype.slice.call(flow.querySelectorAll('.step'));
  var items = Array.prototype.slice.call(flow.querySelectorAll('.stage-item'));
  var dots = Array.prototype.slice.call(flow.querySelectorAll('.stage-dot'));
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var wide = window.matchMedia ? window.matchMedia('(min-width: 901px)') : { matches: true };
  var lockUntil = 0, current = 0;
  function activate(i) {
    if (i < 0 || i >= steps.length) return;
    current = i;
    steps.forEach(function (s, j) {
      s.classList.toggle('is-active', j === i);
      if (j === i) s.setAttribute('aria-current', 'step'); else s.removeAttribute('aria-current');
    });
    items.forEach(function (n, j) { n.classList.toggle('is-active', j === i); n.setAttribute('aria-hidden', j === i ? 'false' : 'true'); if (j === i) n.removeAttribute('inert'); else n.setAttribute('inert', ''); });
    dots.forEach(function (d, j) { d.classList.toggle('is-active', j === i); });
  }
  function choose(i) {
    lockUntil = Date.now() + 1500; // the smooth scroll passes other steps on the way; ignore them
    activate(i);
    if (wide.matches && steps[i].scrollIntoView) steps[i].scrollIntoView({ block: 'center', behavior: reduce ? 'auto' : 'smooth' });
  }
  steps.forEach(function (s, i) {
    s.addEventListener('click', function () { choose(i); });
    s.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); choose(i); }
      else if (e.key === 'ArrowDown' && steps[i + 1]) { e.preventDefault(); steps[i + 1].focus(); choose(i + 1); }
      else if (e.key === 'ArrowUp' && steps[i - 1]) { e.preventDefault(); steps[i - 1].focus(); choose(i - 1); }
    });
  });
  dots.forEach(function (d, i) { d.addEventListener('click', function () { choose(i); }); });
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      if (Date.now() < lockUntil || !wide.matches) return;
      entries.forEach(function (e) { if (e.isIntersecting) activate(steps.indexOf(e.target)); });
    }, { rootMargin: '-40% 0px -40% 0px', threshold: 0 });
    steps.forEach(function (s) { io.observe(s); });
  }
  activate(0);
})();

/* "Up and running in minutes": while the row is on screen, the cards lift one after another, left to right
   (the same look as hovering), then rest for a moment and start again. Not for visitors who ask for less motion. */
(function () {
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var STEP = 1300, REST = 1500;
  Array.prototype.slice.call(document.querySelectorAll('.steps-row')).forEach(function (row) {
    var items = Array.prototype.slice.call(row.children).filter(function (el) { return el.tagName === 'LI'; });
    if (items.length < 2) return;
    var cur = -1, timer = 0, running = false;
    function light(i) { cur = i; items.forEach(function (li, j) { li.classList.toggle('is-lit', j === i); }); }
    function tick() {
      var next = cur + 1;
      if (next >= items.length) { light(-1); timer = window.setTimeout(tick, REST); return; }
      light(next);
      timer = window.setTimeout(tick, STEP);
    }
    function visible() {
      var r = row.getBoundingClientRect(), h = window.innerHeight || document.documentElement.clientHeight;
      return r.height > 0 && r.bottom > 90 && r.top < h * 0.85 && !document.hidden;
    }
    function check() {
      var v = visible();
      if (v && !running) { running = true; cur = -1; tick(); }
      else if (!v && running) { running = false; window.clearTimeout(timer); timer = 0; light(-1); }
    }
    window.addEventListener('scroll', check, { passive: true });
    window.addEventListener('resize', check);
    window.addEventListener('load', check);
    document.addEventListener('visibilitychange', check);
    window.setInterval(check, 1000);                 // a cheap safety net if a scroll event is missed
    check();
  });
})();

/* "Built for local businesses. Ready for the world.": a small GST invoice with a QR code on the India card,
   and a dotted globe with currency bubbles on the other. Decoration only. */
(function () {
  var india = document.querySelector('.lg-percent'), world = document.querySelector('.lg-globe');
  function qr() {
    var n = 13, c = 4, seed = 7, out = '';
    function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; }
    function finder(x, y) {
      out += '<rect x="' + x * c + '" y="' + y * c + '" width="' + 4 * c + '" height="' + 4 * c + '" fill="#14234a"/>' +
             '<rect x="' + (x + 1) * c + '" y="' + (y + 1) * c + '" width="' + 2 * c + '" height="' + 2 * c + '" fill="#fff"/>' +
             '<rect x="' + (x + 1.5) * c + '" y="' + (y + 1.5) * c + '" width="' + c + '" height="' + c + '" fill="#14234a"/>';
    }
    finder(0, 0); finder(n - 4, 0); finder(0, n - 4);
    for (var y = 0; y < n; y++) for (var x = 0; x < n; x++) {
      if ((x < 5 && y < 5) || (x > n - 6 && y < 5) || (x < 5 && y > n - 6)) continue;
      if (rnd() > 0.5) out += '<rect x="' + x * c + '" y="' + y * c + '" width="' + c + '" height="' + c + '" fill="#14234a"/>';
    }
    return '<svg viewBox="0 0 ' + n * c + ' ' + n * c + '" aria-hidden="true" focusable="false">' + out + '</svg>';
  }
  function add(card, cls, html) {
    if (!card) return;
    var d = document.createElement('div');
    d.className = 'lg-art ' + cls;
    d.setAttribute('aria-hidden', 'true');
    d.innerHTML = html;
    card.appendChild(d);
  }
  add(india, 'lg-art-india',
    '<div class="inv"><div class="ln"><b>GSTIN</b><span>33ABCDE1234F1Z5</span></div><div class="ln"><b>HSN</b><span>0902</span></div>' +
    '<div class="ln gst"><em>CGST 2.5%</em><em>SGST 2.5%</em></div><span class="stamp">PAID</span></div>' +
    '<div class="qrw">' + qr() + '<i class="scan"></i></div>');
  add(world, 'lg-art-world', '<i class="orbit"></i><i class="globe"></i><i class="ripple"></i><i class="ripple r2"></i>' +
    '<div class="ring"><span class="c1">₹</span><span class="c2">$</span><span class="c3">€</span><span class="c4">£</span></div>');
})();


/* Compare page: the same soft glow and little documents as the home hero, behind the title. Decoration only. */
(function () {
  var head = document.querySelector('.page-head');
  if (!head || !document.querySelector('.compare-glance')) return;
  head.classList.add('compare-hero');
  var docs = [
    ['<b>INVOICE INV-00031</b><i></i><i></i><div class="tot"><span>$ 3,280.00</span><span class="paid">PAID</span></div>', 'right:7%;top:16%;--r:3deg;animation-duration:11s'],
    ['<b>QUOTATION Q-0012</b><i></i><i style="width:60%"></i><div class="tot"><span>€ 8,450.00</span></div>', 'right:17%;top:52%;--r:-3deg;animation-duration:13s;animation-delay:-4s'],
    ['<b>Receipt · 80 mm</b><i></i><div class="tot"><span>£ 640.00</span><span class="paid">PAID</span></div>', 'right:3%;top:68%;--r:2deg;animation-duration:12s;animation-delay:-7s']
  ];
  var bg = document.createElement('div');
  bg.className = 'hero-bg';
  bg.setAttribute('aria-hidden', 'true');
  bg.innerHTML = '<div class="bg-aurora"><span class="aur a1"></span><span class="aur a2"></span><span class="aur a3"></span></div>' +
    '<div class="bg-docs">' + docs.map(function (d) { return '<div class="doc" style="' + d[1] + '">' + d[0] + '</div>'; }).join('') + '</div>';
  head.insertBefore(bg, head.firstChild);
})();

/* Reviews page: the same soft glow and little documents behind the title (decoration only). */
(function () {
  var head = document.querySelector('.page-head');
  if (!head || !document.querySelector('#rv-work') || head.querySelector('.hero-bg')) return;
  head.classList.add('reviews-hero');
  var docs = [
    ['<b>Monthly power bill</b><i></i><i style="width:65%"></i><div class="tot"><span>$ 51,360.00</span><span class="paid">PAID</span></div>', 'right:8%;top:14%;--r:3deg;animation-duration:12s'],
    ['<b>Receipt · 58 mm</b><i></i><i style="width:55%"></i><div class="tot"><span>€ 575.00</span><span class="paid">PAID</span></div>', 'right:19%;top:54%;--r:-3deg;animation-duration:13s;animation-delay:-5s'],
    ['<b>INVOICE INV-00044</b><i></i><div class="tot"><span>£ 6,210.00</span><span class="paid">PAID</span></div>', 'right:3%;top:70%;--r:2deg;animation-duration:11s;animation-delay:-8s']
  ];
  var bg = document.createElement('div');
  bg.className = 'hero-bg';
  bg.setAttribute('aria-hidden', 'true');
  bg.innerHTML = '<div class="bg-aurora"><span class="aur a1"></span><span class="aur a2"></span><span class="aur a3"></span></div>' +
    '<div class="bg-docs">' + docs.map(function (d) { return '<div class="doc" style="' + d[1] + '">' + d[0] + '</div>'; }).join('') + '</div>';
  head.insertBefore(bg, head.firstChild);
})();

/* FAQ and Contact pages: the soft glow behind the title with a few floating cards, and (FAQ) a sticky topic list. Decoration and navigation only. */
(function () {
  var head = document.querySelector('.page-head');
  var faq = document.querySelector('.faq-list'), contact = document.querySelector('.contact-card');
  if (!head || !(faq || contact) || head.querySelector('.hero-bg')) return;
  head.classList.add(faq ? 'faq-hero' : 'contact-hero');
  var cards = faq ? [
    ['<b>Do I need an internet connection?</b><span>No. Invoiceo runs on your computer.</span>', 'bub', 'right:8%;top:30%;--r:2deg;animation-duration:12s'],
    ['<b>Is Invoiceo really free?</b><span>Yes.</span>', 'bub me', 'right:22%;top:62%;--r:-2deg;animation-duration:13s;animation-delay:-5s'],
    ['<b>Where is my data stored?</b><span>On your own computer.</span>', 'bub', 'right:3%;top:72%;--r:2deg;animation-duration:11s;animation-delay:-8s']
  ] : [
    ['<i></i>Email', 'pill', 'right:10%;top:30%;--r:2deg;animation-duration:11s'],
    ['<i class="b"></i>WhatsApp', 'pill', 'right:22%;top:58%;--r:-2deg;animation-duration:12s;animation-delay:-4s'],
    ['<i class="o"></i>Support request', 'pill', 'right:5%;top:74%;--r:2deg;animation-duration:13s;animation-delay:-7s']
  ];
  var bg = document.createElement('div');
  bg.className = 'hero-bg';
  bg.setAttribute('aria-hidden', 'true');
  bg.innerHTML = '<div class="bg-aurora"><span class="aur a1"></span><span class="aur a2"></span><span class="aur a3"></span></div>' +
    '<div class="bg-docs">' + cards.map(function (d) { return '<div class="doc ' + d[1] + '" style="' + d[2] + '">' + d[0] + '</div>'; }).join('') + '</div>';
  head.insertBefore(bg, head.firstChild);

  if (!faq) return;
  var wrap = faq.closest('.measure');
  var groups = Array.prototype.slice.call(wrap.querySelectorAll(':scope > h2'));
  if (groups.length < 2) return;
  var nav = document.createElement('nav');
  nav.className = 'faq-nav';
  nav.setAttribute('aria-label', 'Topics');
  var links = groups.map(function (h, i) {
    h.classList.add('faq-g' + ((i % 5) + 1));
    var list = h.nextElementSibling;
    if (list && list.classList.contains('faq-list')) list.classList.add('faq-g' + ((i % 5) + 1));
    var a = document.createElement('a');
    a.href = '#' + h.id;
    a.className = 'faq-g' + ((i % 5) + 1);
    a.innerHTML = '<b>' + ('0' + (i + 1)).slice(-2) + '</b><span></span>';
    a.lastChild.textContent = h.textContent;
    nav.appendChild(a);
    return a;
  });
  var ask = head.querySelector('.lead a');
  if (ask) {
    var box = document.createElement('p');
    box.className = 'ask';
    box.innerHTML = 'Can’t find yours? <a href="' + ask.getAttribute('href') + '">Ask us</a>.';
    nav.appendChild(box);
  }
  wrap.insertBefore(nav, wrap.firstChild);
  function current() {
    var y = window.innerHeight * 0.3, idx = 0;
    groups.forEach(function (h, i) { if (h.getBoundingClientRect().top < y) idx = i; });
    links.forEach(function (a, i) { a.classList.toggle('is-current', i === idx); });
  }
  window.addEventListener('scroll', current, { passive: true });
  window.addEventListener('resize', current);
  current();
})();

/* Home pages: the facts row (GST & UPI QR, A4 & thermal, 8 languages, ...) becomes an endless marquee.
   The set is repeated once for the loop; the copies are hidden from screen readers. Visitors who ask for
   less motion keep the still grid. */
(function () {
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var strip = document.querySelector('.facts-strip:not(.compare-glance)');
  var list = strip && strip.querySelector('.facts');
  if (!list || list.classList.contains('facts-4')) return;
  var items = Array.prototype.slice.call(list.children);
  if (items.length < 3) return;
  items.forEach(function (li) {
    var c = li.cloneNode(true);
    c.setAttribute('aria-hidden', 'true');
    list.appendChild(c);
  });
  list.classList.remove('wrap');
  strip.classList.add('is-marquee');
})();


/* Hero app window: walks through the app on its own. A cursor glides to the next spot, clicks, the lit area and the
   step label follow, and the screen changes (New invoice -> Invoices -> Dashboard). It runs only while the window is on
   screen. With reduced motion, or without JS, the first screen simply stays. */
(function () {
  var root = document.querySelector('[data-tour]');
  if (!root || (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches)) return;
  var steps;
  try { steps = JSON.parse(root.getAttribute('data-tour')); } catch (e) { return; }
  var stage = root.querySelector('.tour-stage'), imgs = root.querySelectorAll('.tour-img'),
      box = root.querySelector('.tour-box'), cur = root.querySelector('.tour-cursor'),
      rip = root.querySelector('.tour-ripple'), pill = root.querySelector('.tour-step'),
      num = pill.querySelector('b'), txt = pill.querySelector('span');
  var STEP = 4000, i = -1, timers = [], playing = false, hv = root.closest('.hero-visual') || root.parentNode;
  function later(fn, ms) { timers.push(setTimeout(fn, ms)); }
  function clearPrint() { hv.classList.remove('is-printing', 'is-done'); }
  function go(n) {
    var s = steps[n];
    pill.style.setProperty('--tour-ms', (s.d || STEP) + 'ms');
    if (n === 0) { clearPrint(); void hv.offsetWidth; }   // a new round: the old receipt goes, the next one prints at step 4
    imgs.forEach(function (im, k) { im.classList.toggle('is-on', k === s.s); });
    box.style.left = s.b[0] + '%'; box.style.top = s.b[1] + '%'; box.style.width = s.b[2] + '%'; box.style.height = s.b[3] + '%';
    cur.style.left = s.x + '%'; cur.style.top = s.y + '%';
    pill.classList.add('swap'); pill.classList.remove('run');
    later(function () { num.textContent = n + 1; txt.textContent = s.t; pill.classList.remove('swap'); void pill.offsetWidth; pill.classList.add('run'); }, 250);
    if (s.p) {   // Create Invoice: the created card shows, the cursor goes to Print, and the printer under the window prints the receipt
      var pt = s.pt || 1700;
      if (s.sw) later(function () { imgs.forEach(function (im, k) { im.classList.toggle('is-on', k === s.sw[1]); }); }, s.sw[0]);
      if (s.m2) later(function () {
        cur.style.left = s.m2[1] + '%'; cur.style.top = s.m2[2] + '%';
        box.style.left = s.m2[3][0] + '%'; box.style.top = s.m2[3][1] + '%'; box.style.width = s.m2[3][2] + '%'; box.style.height = s.m2[3][3] + '%';
      }, s.m2[0]);
      if (s.c2) later(function () { rip.style.left = s.m2[1] + '%'; rip.style.top = s.m2[2] + '%'; rip.classList.remove('go'); void rip.offsetWidth; rip.classList.add('go'); }, s.c2);
      later(function () { hv.classList.add('is-printing'); }, pt);
      later(function () { hv.classList.add('is-done'); }, pt + 3300);   // the receipt then stays where it is
    }
    later(function () { rip.style.left = s.x + '%'; rip.style.top = s.y + '%'; rip.classList.remove('go'); void rip.offsetWidth; rip.classList.add('go'); }, 1300);
  }
  function next() {
    if (!playing) return;
    i = (i + 1) % steps.length;
    go(i);
    later(next, steps[i].d || STEP);
  }
  function visible() {
    var r = root.getBoundingClientRect();
    return r.bottom > 80 && r.top < window.innerHeight - 80 && !document.hidden;
  }
  function check() {
    var v = visible();
    if (v && !playing) { playing = true; root.classList.add('is-live'); hv.classList.add('tour-live'); next(); }
    else if (!v && playing) { playing = false; timers.forEach(clearTimeout); timers = []; pill.classList.remove('run'); }
  }
  window.addEventListener('scroll', check, { passive: true });
  window.addEventListener('resize', check);
  document.addEventListener('visibilitychange', check);
  setInterval(check, 1000);
  check();
})();


/* Privacy, Terms and Licenses: the soft glow with three floating chips behind the title, and the topic list that follows the reader. */
(function () {
  var main = document.querySelector('.legal-main'), head = document.querySelector('.page-head');
  if (!main || !head) return;
  var chips = (main.getAttribute('data-chips') || '').split('|').filter(Boolean);
  if (chips.length && !head.querySelector('.hero-bg')) {
    head.classList.add('faq-hero', 'legal-hero');
    var pos = ['right:10%;top:28%;--r:2deg;animation-duration:11s', 'right:22%;top:58%;--r:-2deg;animation-duration:12s;animation-delay:-4s', 'right:5%;top:74%;--r:2deg;animation-duration:13s;animation-delay:-7s'];
    var dots = ['', 'b', 'o'];
    var bg = document.createElement('div');
    bg.className = 'hero-bg';
    bg.setAttribute('aria-hidden', 'true');
    bg.innerHTML = '<div class="bg-aurora"><span class="aur a1"></span><span class="aur a2"></span><span class="aur a3"></span></div>' +
      '<div class="bg-docs">' + chips.map(function (c, i) { return '<div class="doc pill" style="' + pos[i % 3] + '"><i class="' + dots[i % 3] + '"></i>' + c + '</div>'; }).join('') + '</div>';
    head.insertBefore(bg, head.firstChild);
  }
  var secs = Array.prototype.slice.call(main.querySelectorAll('.legal-sec'));
  var links = Array.prototype.slice.call(document.querySelectorAll('.legal-nav a[href^="#"]'));
  if (secs.length < 2 || links.length !== secs.length) return;
  function current() {
    var y = window.innerHeight * 0.3, idx = 0;
    secs.forEach(function (h, i) { if (h.getBoundingClientRect().top < y) idx = i; });
    links.forEach(function (a, i) { a.classList.toggle('is-current', i === idx); });
  }
  window.addEventListener('scroll', current, { passive: true });
  window.addEventListener('resize', current);
  current();
})();


/* Screens as tabs, each one alive: when a tab opens (and the tab bar is on screen) its screen plays a short scene on top of
   the real screenshot. Dashboard and Reports: the numbers count up and the charts draw in. Customers and Products: the New
   button is clicked, a form is filled in and the new row slides into the list. Invoices and New invoice: the rows come in one
   by one and the totals add up. The pieces are drawn over the picture in the app's own style and fade away at the end, so the
   real screenshot is what stays. Everything is placed in 1280 x 800 picture units. Skipped for visitors who ask for less motion.
   The figures (revenue, counts) are the ones in the sample-shop screenshots: update VALUES below if the screenshots change. */
(function () {
  var shots = document.querySelector('.shots.is-tabs');
  if (!shots || (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches)) return;
  var LANG = (document.documentElement.lang || 'en').slice(0, 2);
  var TXT = {
    en: { newCust: 'New Customer', cname: 'Customer Name', biz: 'Business Name', phone: 'Phone', save: 'Save', bizPill: 'Business', custAdded: 'Customer added',
          newProd: 'New Product', pname: 'Item Name', price: 'Unit Price', stock: 'Stock', inStock: 'In Stock', prodAdded: 'Product added' },
    ta: { newCust: 'புதிய வாடிக்கையாளர்', cname: 'வாடிக்கையாளர் பெயர்', biz: 'வணிகப் பெயர்', phone: 'தொலைபேசி', save: 'சேமிக்கவும்', bizPill: 'வணிகம்', custAdded: 'வாடிக்கையாளர் சேர்க்கப்பட்டார்',
          newProd: 'புதிய பொருள்', pname: 'உருப்படியின் பெயர்', price: 'அலகு விலை', stock: 'இருப்பு', inStock: 'இருப்பில் உள்ளது', prodAdded: 'பொருள் சேர்க்கப்பட்டது' },
    hi: { newCust: 'नया ग्राहक', cname: 'ग्राहक का नाम', biz: 'व्यवसाय का नाम', phone: 'फ़ोन', save: 'सहेजें', bizPill: 'व्यवसाय', custAdded: 'ग्राहक जोड़ा गया',
          newProd: 'नया उत्पाद', pname: 'आइटम का नाम', price: 'इकाई मूल्य', stock: 'स्टॉक', inStock: 'स्टॉक में', prodAdded: 'उत्पाद जोड़ा गया' }
  };
  var T = TXT[LANG] || TXT.en;
  var VALUES = {
    dash: { collected: 152581.8, outstanding: 101844.28, invoices: 10, products: 8 },
    rep: { billed: 428962.32, collected: 301772.82, out: 127189.5, avg: 23831.24, profit: 69093, real: 48453.04 },
    inv: { sub: 33071, tax: 5952.78, total: 39023.78 }
  };
  var DWELL = { dashboard: 5200, customers: 10000, products: 10000, reports: 5200, invoices: 5000, 'create-invoice': 6200 };
  var CUR = '<svg class="sc-cursor-svg" viewBox="0 0 24 24" width="30" height="30" aria-hidden="true" focusable="false"><path d="M5 3l14 8-6.2 1.6L9.6 19z" fill="#142033" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg>';

  var figs = Array.prototype.slice.call(shots.children).filter(function (f) { return f.classList.contains('shot'); });
  var kind = function (fig) {
    var im = fig.querySelector('.window img');
    var m = im && /screens\/([a-z-]+?)(?:-(?:ta|hi))?-1280\.jpg|screens\/([a-z-]+?)(?:-(?:ta|hi))?\.png/.exec(im.currentSrc || im.src);
    return m && (m[1] || m[2]);
  };
  figs.forEach(function (f) { var k = kind(f); if (DWELL[k]) f.setAttribute('data-dwell', DWELL[k]); });

  var state = null;   // the scene that is running: { fig, scene, timers, anims }
  function stop() {
    if (!state) return;
    state.timers.forEach(clearTimeout);
    state.anims.forEach(function (a) { try { a.cancel(); } catch (e) {} });
    if (state.scene && state.scene.parentNode) state.scene.parentNode.removeChild(state.scene);
    state = null;
  }

  function start(fig) {
    var k = kind(fig), win = fig.querySelector('.window'), img = win && win.querySelector('img'), link = img && img.parentNode;
    if (!SCENES[k]) return true;                                   // nothing to play on this screen
    if (!img || !img.complete || !img.naturalWidth) return false;  // the picture is not loaded yet: try again soon
    var scene = document.createElement('div');
    scene.className = 'scene';
    scene.setAttribute('aria-hidden', 'true');
    link.appendChild(scene);
    var S = state = { fig: fig, scene: scene, timers: [], anims: [] };
    var src = img.currentSrc || img.src;

    // sample colours from the picture itself, so every patch matches its card
    var cv = document.createElement('canvas'); cv.width = 1280; cv.height = 800;
    var cx = cv.getContext('2d', { willReadFrequently: true }), ok = true;
    try { cx.drawImage(img, 0, 0, 1280, 800); cx.getImageData(0, 0, 1, 1); } catch (e) { ok = false; }
    function px(x, y) { var d = cx.getImageData(Math.max(0, Math.min(1279, Math.round(x))), Math.max(0, Math.min(799, Math.round(y))), 1, 1).data; return [d[0], d[1], d[2]]; }
    function bgAt(x, y) { if (!ok) return '#fff'; var c = px(x, y); return 'rgb(' + c.join(',') + ')'; }
    function inkAt(x, y, w, h) {    // the darkest pixel in a box: the colour of the text there
      if (!ok) return '#111';
      var best = [255, 255, 255], bl = 999, d = cx.getImageData(Math.round(x), Math.round(y), Math.round(w), Math.round(h)).data;
      for (var i = 0; i < d.length; i += 4) { var l = d[i] * 0.3 + d[i + 1] * 0.59 + d[i + 2] * 0.11; if (l < bl) { bl = l; best = [d[i], d[i + 1], d[i + 2]]; } }
      return 'rgb(' + best.join(',') + ')';
    }
    function later(fn, ms) { S.timers.push(setTimeout(function () { if (state === S) fn(); }, ms)); }
    function anim(node, frames, opts) { var a = node.animate(frames, opts); S.anims.push(a); return a; }
    function ease() { return 'cubic-bezier(.4,0,.2,1)'; }
    var pct = function (v, d) { return (v / d * 100).toFixed(3) + '%'; };
    function boxCss(x, y, w, h) { return 'left:' + pct(x, 1280) + ';top:' + pct(y, 800) + ';width:' + pct(w, 1280) + ';height:' + pct(h, 800) + ';'; }
    function mk(cls, css, html, parent) { var d = document.createElement('div'); d.className = cls; d.style.cssText = css || ''; if (html != null) d.innerHTML = html; (parent || scene).appendChild(d); return d; }
    function crop(x, y, w, h, parent, css) {   // a piece of the screenshot, shown exactly where it is
      return mk('sc-crop', 'background-image:url("' + src + '");background-size:' + (128000 / w) + '% ' + (80000 / h) + '%;background-position:' + (x / (1280 - w) * 100) + '% ' + (y / (800 - h) * 100) + '%;' + (css || ''), '', parent);
    }
    function cover(x, y, w, h, bg) { return mk('sc-patch', boxCss(x, y, w, h) + 'background:' + (bg || bgAt(x + 2, y + 2)) + ';'); }
    function money(v) { return 'Rs. ' + v.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }
    function whole(v) { return String(Math.round(v)); }
    // a number that counts up in place, over the real one; it fades out at the end and the real number shows
    function count(x, y, w, h, to, fmt, size, opts) {
      opts = opts || {};
      var from = opts.from || 0, delay = opts.delay || 0, dur = opts.dur || 1500;
      var p = mk('sc-patch sc-num', boxCss(x, y, w, h) + 'background:' + bgAt(x + 2, y + 2) + ';color:' + (opts.color || inkAt(x, y, w, h)) + ';font-size:calc(var(--u)*' + size + ');justify-content:' + (opts.right ? 'flex-end' : 'flex-start') + ';', fmt(from));
      var t0 = null;
      function step(ts) {
        if (state !== S) return;
        if (t0 === null) t0 = ts + delay;
        var q = Math.max(0, Math.min(1, (ts - t0) / dur)), e = 1 - Math.pow(1 - q, 3);
        p.textContent = fmt(from + (to - from) * e);
        if (q < 1) requestAnimationFrame(step);
        else if (!opts.keep) later(function () { p.style.display = 'none'; }, 450);
      }
      requestAnimationFrame(step);
      return p;
    }
    // a patch over a region that is drawn in: wipe = 'right' (left to right) or 'up' (from the bottom up)
    function drawIn(x, y, w, h, dir, delay, dur, bg) {
      var c = cover(x, y, w, h, bg);
      anim(c, [{ clipPath: 'inset(0 0 0 0)' }, { clipPath: dir === 'up' ? 'inset(0 0 100% 0)' : 'inset(0 0 0 100%)' }], { delay: delay, duration: dur, easing: ease(), fill: 'forwards' });
      return c;
    }
    function cursor(x, y) { return mk('sc-cursor', 'left:' + pct(x, 1280) + ';top:' + pct(y, 800) + ';', CUR); }
    function moveTo(c, x, y, delay, dur) { later(function () { c.style.transitionDuration = dur + 'ms'; c.style.left = pct(x, 1280); c.style.top = pct(y, 800); }, delay); }
    function click(x, y, delay, ring) {
      later(function () {
        var r = mk('sc-ripple', 'left:' + pct(x, 1280) + ';top:' + pct(y, 800) + ';');
        anim(r, [{ opacity: 0.9, transform: 'scale(0.2)' }, { opacity: 0, transform: 'scale(1.6)' }], { duration: 650, easing: 'ease-out', fill: 'forwards' });
        if (ring) { var b = mk('sc-ring', boxCss(ring[0], ring[1], ring[2], ring[3])); anim(b, [{ opacity: 0 }, { opacity: 1 }, { opacity: 0 }], { duration: 900, fill: 'forwards' }); }
      }, delay);
    }
    function typeInto(node, text, delay, per) {
      for (var i = 1; i <= text.length; i++) (function (n) { later(function () { node.textContent = text.slice(0, n); }, delay + n * per); })(i);
    }
    function toast(text, delay) {
      later(function () {
        var t = mk('sc-toast', 'right:2%;top:8%;', '<i></i>' + text);
        anim(t, [{ opacity: 0, transform: 'translateY(-14px)' }, { opacity: 1, transform: 'none' }], { duration: 350, easing: ease(), fill: 'forwards' });
        anim(t, [{ opacity: 1 }, { opacity: 0 }], { delay: 2600, duration: 500, fill: 'forwards' });
      }, delay);
    }
    // a form in a dialog over a dimmed screen; returns the value cells and the save button
    function dialog(title, fields, saveText, openAt) {
      var dim = mk('sc-dim', ''), d = mk('sc-dlg', boxCss(430, 130, 600, 100 + fields.length * 78 + 80));
      var h = '<h4>' + title + '</h4>';
      fields.forEach(function (f, i) { h += '<div class="sc-field"><span>' + f + '</span><b></b></div>'; });
      h += '<div class="sc-btns"><i class="sc-save">' + saveText + '</i></div>';
      d.innerHTML = h;
      dim.style.opacity = 0; d.style.opacity = 0;
      later(function () {
        anim(dim, [{ opacity: 0 }, { opacity: 1 }], { duration: 300, fill: 'forwards' });
        anim(d, [{ opacity: 0, transform: 'translateY(18px) scale(.96)' }, { opacity: 1, transform: 'none' }], { duration: 380, easing: 'cubic-bezier(.2,.9,.3,1.1)', fill: 'forwards' });
      }, openAt);
      return { dim: dim, dlg: d, vals: d.querySelectorAll('.sc-field b'), fields: d.querySelectorAll('.sc-field'), save: d.querySelector('.sc-save'),
        close: function (at) { later(function () { anim(d, [{ opacity: 1, transform: 'none' }, { opacity: 0, transform: 'scale(.96)' }], { duration: 260, fill: 'forwards' }); anim(dim, [{ opacity: 1 }, { opacity: 0 }], { duration: 320, fill: 'forwards' }); }, at); } };
    }
    function centerOf(node) {
      var a = scene.getBoundingClientRect(), r = node.getBoundingClientRect();
      return [(r.left + r.width / 2 - a.left) / a.width * 1280, (r.top + r.height / 2 - a.top) / a.height * 800];
    }
    // a list that gets a new first row: the rows slide down one place and the new row appears in the gap
    function newRow(region, rowH, build, at, renumber) {
      var R = mk('sc-region', boxCss(region[0], region[1], region[2], region[3]));
      var inner = crop(region[0], region[1], region[2], region[3], R);
      var rb = bgAt(region[0] + 30, region[1] + 6);
      var row = mk('sc-row', 'left:0;top:0;width:100%;height:' + pct(rowH, region[3]) + ';background:' + rb + ';', '', R);
      row.style.opacity = 0;
      build(row, region);
      later(function () {
        anim(inner, [{ transform: 'translateY(0)' }, { transform: 'translateY(' + (rowH / region[3] * 100) + '%)' }], { duration: 650, easing: ease(), fill: 'forwards' });
        anim(row, [{ opacity: 0, backgroundColor: '#d8f5e4' }, { opacity: 1, backgroundColor: '#d8f5e4' }, { opacity: 1, backgroundColor: rb }], { duration: 1800, fill: 'forwards' });
        if (renumber) renumber.forEach(function (r) { var n = cover(r[0], r[1] - 9, 24, 18, bgAt(r[0] + 31, r[1] - rowH)); n.className += ' sc-num sc-small'; n.textContent = r[2]; n.style.opacity = 0; anim(n, [{ opacity: 0 }, { opacity: 1 }], { delay: 500, duration: 200, fill: 'forwards' }); });
      }, at);
    }
    SCENES[k]({ S: S, TXT: T, V: VALUES, boxCss: boxCss, pct: pct, mk: mk, crop: crop, cover: cover, count: count, drawIn: drawIn, cursor: cursor, moveTo: moveTo, click: click,
      typeInto: typeInto, toast: toast, dialog: dialog, centerOf: centerOf, newRow: newRow, later: later, anim: anim, bgAt: bgAt, money: money, whole: whole, ease: ease });
    return true;
  }

  var SCENES = {
    dashboard: function (c) {
      var v = c.V.dash;
      c.count(298, 213, 175, 30, v.collected, c.money, 24, {});
      c.count(561, 213, 175, 30, v.outstanding, c.money, 24, { delay: 150 });
      c.count(824, 213, 60, 30, v.invoices, c.whole, 24, { delay: 300, dur: 1100 });
      c.count(1087, 213, 60, 30, v.products, c.whole, 24, { delay: 450, dur: 900 });
      c.drawIn(262, 366, 560, 190, 'right', 300, 1900);                      // the sales chart draws in
      var donut = c.cover(862, 356, 160, 160);                                 // the status ring sweeps round
      donut.className += ' sc-sweep';
      c.anim(donut, [{ '--a': '0deg' }, { '--a': '360deg' }], { delay: 500, duration: 1600, easing: c.ease(), fill: 'forwards' });
    },
    customers: function (c) {
      var t = c.TXT, cur = c.cursor(660, 420);
      c.cursor && c.anim(cur, [{ opacity: 0 }, { opacity: 1 }], { duration: 300, fill: 'forwards' });
      c.moveTo(cur, 1066, 30, 300, 1000);
      c.click(1066, 30, 1450, [999, 11, 135, 35]);
      var d = c.dialog(t.newCust, [t.cname, t.biz, t.phone], t.save, 1600);
      c.later(function () { d.fields[0].className += ' on'; }, 1900); c.typeInto(d.vals[0], 'Alex Morgan', 2000, 75);
      c.later(function () { d.fields[0].className = 'sc-field'; d.fields[1].className += ' on'; }, 2950); c.typeInto(d.vals[1], 'Morgan Studio', 3050, 70);
      c.later(function () { d.fields[1].className = 'sc-field'; d.fields[2].className += ' on'; }, 4050); c.typeInto(d.vals[2], '12345 00018', 4150, 70);
      c.later(function () { var p = c.centerOf(d.save); c.cursor && (cur.style.transitionDuration = '800ms', cur.style.left = c.pct(p[0], 1280), cur.style.top = c.pct(p[1], 800)); }, 5150);
      c.later(function () { var p = c.centerOf(d.save); c.click(p[0], p[1], 0); d.save.className += ' press'; }, 6050);
      d.close(6350);
      c.newRow([222, 401, 1036, 389], 64.8, function (row) {
        var w = 1036;
        c.mk('sc-cb', 'left:' + c.pct(18, w) + ';top:50%;', '', row);
        c.mk('sc-t', 'left:' + c.pct(46, w) + ';top:50%;color:#6b7280;font-size:calc(var(--u)*13);', '1', row);
        c.mk('sc-av', 'left:' + c.pct(82, w) + ';top:50%;', 'AM', row);
        c.mk('sc-t', 'left:' + c.pct(124, w) + ';top:30%;font-weight:700;font-size:calc(var(--u)*15);', 'Alex Morgan', row);
        c.mk('sc-t', 'left:' + c.pct(124, w) + ';top:68%;color:#6b7280;font-size:calc(var(--u)*13);', 'Morgan Studio', row);
        c.mk('sc-t', 'left:' + c.pct(345, w) + ';top:30%;font-size:calc(var(--u)*13.5);', '12345 00018', row);
        c.mk('sc-t', 'left:' + c.pct(345, w) + ';top:68%;color:#6b7280;font-size:calc(var(--u)*13.5);', '—', row);
        c.mk('sc-t', 'left:' + c.pct(508, w) + ';top:50%;color:#6b7280;', '—', row);
        c.mk('sc-pill', 'left:' + c.pct(629, w) + ';top:50%;background:#dcf3e4;color:#1f7a45;', t.bizPill, row);
        c.mk('sc-t', 'left:' + c.pct(740, w) + ';top:50%;color:#6b7280;', '—', row);
        c.crop(1083, 412, 156, 44, row, 'left:' + c.pct(861, w) + ';top:50%;width:' + c.pct(156, w) + ';height:' + c.pct(44, 64.8) + ';transform:translateY(-50%);');
      }, 6700, [[259, 497.8, 2], [259, 562.6, 3], [259, 627.4, 4], [259, 692.2, 5], [259, 757, 6]]);
      c.count(288, 118, 34, 26, 8, c.whole, 24, { from: 7, delay: 6900, dur: 600, keep: true });
      c.count(551, 118, 34, 26, 5, c.whole, 24, { from: 4, delay: 6900, dur: 600, keep: true });
      c.toast(t.custAdded, 6950);
    },
    products: function (c) {
      var t = c.TXT, cur = c.cursor(660, 420);
      c.anim(cur, [{ opacity: 0 }, { opacity: 1 }], { duration: 300, fill: 'forwards' });
      c.moveTo(cur, 1071, 30, 300, 1000);
      c.click(1071, 30, 1450, [1009, 11, 125, 35]);
      var d = c.dialog(t.newProd, [t.pname, t.price, t.stock], t.save, 1600);
      c.later(function () { d.fields[0].className += ' on'; }, 1900); c.typeInto(d.vals[0], 'Bluetooth Speaker', 2000, 65);
      c.later(function () { d.fields[0].className = 'sc-field'; d.fields[1].className += ' on'; }, 3200); c.typeInto(d.vals[1], '1599.00', 3300, 90);
      c.later(function () { d.fields[1].className = 'sc-field'; d.fields[2].className += ' on'; }, 4150); c.typeInto(d.vals[2], '25', 4250, 120);
      c.later(function () { var p = c.centerOf(d.save); cur.style.transitionDuration = '800ms'; cur.style.left = c.pct(p[0], 1280); cur.style.top = c.pct(p[1], 800); }, 5150);
      c.later(function () { var p = c.centerOf(d.save); c.click(p[0], p[1], 0); d.save.className += ' press'; }, 6050);
      d.close(6350);
      c.newRow([222, 401, 1036, 389], 64.8, function (row) {
        var w = 1036, X = function (x) { return c.pct(x - 222, w); };
        c.mk('sc-cb', 'left:' + X(240) + ';top:50%;', '', row);
        c.mk('sc-t', 'left:' + X(268) + ';top:50%;color:#6b7280;font-size:calc(var(--u)*13);', '1', row);
        c.mk('sc-t', 'left:' + X(303) + ';top:50%;font-weight:700;font-size:calc(var(--u)*15);', 'Bluetooth Speaker', row);
        c.mk('sc-t', 'left:' + X(447) + ';top:50%;', '8518', row);
        c.mk('sc-t', 'left:' + X(543) + ';top:50%;', 'Rs. 1,150.00', row);
        c.mk('sc-t', 'left:' + X(638) + ';top:50%;color:#1d4ed8;font-weight:700;', 'Rs. 1,599.00', row);
        c.mk('sc-t', 'left:' + X(734) + ';top:50%;color:#16a34a;font-weight:700;', '25', row);
        c.mk('sc-pill', 'left:' + X(829) + ';top:50%;background:#dcf3e4;color:#1f7a45;', t.inStock, row);
        c.mk('sc-t', 'left:' + X(940) + ';top:50%;', '18%', row);
        c.mk('sc-t', 'left:' + X(988) + ';top:50%;color:#6b7280;', '—', row);
        c.crop(1083, 412, 156, 44, row, 'left:' + X(1083) + ';top:50%;width:' + c.pct(156, w) + ';height:' + c.pct(44, 64.8) + ';transform:translateY(-50%);');
      }, 6700, [[259, 497.8, 2], [259, 562.6, 3], [259, 627.4, 4], [259, 692.2, 5], [259, 757, 6]]);
      c.count(288, 118, 34, 26, 9, c.whole, 24, { from: 8, delay: 6900, dur: 600, keep: true });
      c.count(551, 118, 34, 26, 6, c.whole, 24, { from: 5, delay: 6900, dur: 600, keep: true });
      c.toast(t.prodAdded, 6950);
    },
    reports: function (c) {
      var v = c.V.rep;
      [[403, 126, v.billed], [700, 126, v.collected], [997, 126, v.out], [403, 235, v.avg], [700, 235, v.profit], [997, 235, v.real]].forEach(function (p, i) {
        c.count(p[0], p[1], 200, 30, p[2], c.money, 20, { delay: i * 120 });
      });
      c.drawIn(452, 432, 800, 196, 'up', 500, 1700);                         // the bars grow up from the line
    },
    invoices: function (c) {
      for (var i = 0; i < 8; i++) c.drawIn(222, 236 + i * 61.3, 1036, 61.3, 'right', 150 + i * 160, 650);
    },
    'create-invoice': function (c) {
      var v = c.V.inv, tops = [377, 437, 496, 556];
      tops.forEach(function (y, i) { c.drawIn(228, y, 690, 60, 'right', 200 + i * 520, 650); });
      c.count(1110, 626, 138, 26, v.sub, c.money, 17, { right: true, delay: 2300, dur: 900 });
      c.count(1110, 650, 138, 26, v.tax, c.money, 17, { right: true, delay: 2450, dur: 900 });
      c.count(1090, 686, 158, 36, v.total, c.money, 22, { right: true, delay: 2600, dur: 1100 });
    }
  };

  // run a scene when its tab opens and the screen is on show; stop it when the tab changes
  var played = null;
  function inView(fig) {
    var r = fig.getBoundingClientRect(), h = window.innerHeight || document.documentElement.clientHeight;
    return r.height > 0 && r.top < h * 0.7 && r.bottom > 140;
  }
  function tick() {
    var active = shots.querySelector('.shot.is-active');
    if (!active) return;
    if (state && state.fig !== active) stop();
    if (played !== active) {
      if (document.hidden || !inView(active)) return;
      if (start(active)) played = active;
    }
  }
  var mo = new MutationObserver(function () { var a = shots.querySelector('.shot.is-active'); if (a !== played) { stop(); played = null; tick(); } });
  figs.forEach(function (f) { mo.observe(f, { attributes: true, attributeFilter: ['class'] }); });
  window.addEventListener('scroll', tick, { passive: true });
  window.addEventListener('resize', tick);
  window.setInterval(tick, 700);
  tick();
})();


/* How it works page: the glow with floating step chips behind the title, the step bar that follows the reader, and each step
   block that comes in as it is scrolled to. */
(function () {
  var strip = document.querySelector('.hd-strip'), head = document.querySelector('.page-head');
  if (!strip || !head) return;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!head.querySelector('.hero-bg')) {
    head.classList.add('faq-hero');
    var chips = ['<i></i>1 · Set up', '<i class="b"></i>3 · Create', '<i class="o"></i>5 · Track payments'];
    var pos = ['right:10%;top:28%;--r:2deg;animation-duration:11s', 'right:22%;top:58%;--r:-2deg;animation-duration:12s;animation-delay:-4s', 'right:5%;top:74%;--r:2deg;animation-duration:13s;animation-delay:-7s'];
    var bg = document.createElement('div');
    bg.className = 'hero-bg';
    bg.setAttribute('aria-hidden', 'true');
    bg.innerHTML = '<div class="bg-aurora"><span class="aur a1"></span><span class="aur a2"></span><span class="aur a3"></span></div>' +
      '<div class="bg-docs">' + chips.map(function (c, i) { return '<div class="doc pill" style="' + pos[i] + '">' + c + '</div>'; }).join('') + '</div>';
    head.insertBefore(bg, head.firstChild);
  }
  var blocks = Array.prototype.slice.call(document.querySelectorAll('.hd'));
  var links = Array.prototype.slice.call(strip.querySelectorAll('a'));
  var section = document.getElementById('details');
  if (!reduce && section) section.classList.add('hd-js');
  function tick() {
    var h = window.innerHeight || document.documentElement.clientHeight, idx = -1;
    blocks.forEach(function (b, i) {
      var r = b.getBoundingClientRect();
      if (r.top < h * 0.82) b.classList.add('is-in');
      if (r.top < h * 0.4) idx = i;
    });
    links.forEach(function (a, i) { a.classList.toggle('is-current', i === idx); });
    var cur = strip.querySelector('a.is-current');           // keep the current step visible when the bar scrolls sideways (phones)
    if (cur && strip.scrollWidth > strip.clientWidth + 2) strip.scrollTo({ left: cur.offsetLeft - (strip.clientWidth - cur.offsetWidth) / 2, behavior: reduce ? 'auto' : 'smooth' });
  }
  window.addEventListener('scroll', tick, { passive: true });
  window.addEventListener('resize', tick);
  window.setInterval(tick, 800);
  tick();
})();


/* How it works page, each step: its sub-steps open one after another while the step is on screen, and the screen on the
   right lights up the part that sub-step is about (and changes screen when it needs to). A click picks a sub-step and
   holds it for a while. Without motion, a click is all it needs. */
(function () {
  var blocks = Array.prototype.slice.call(document.querySelectorAll('.hd[data-steps]'));
  if (!blocks.length) return;
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var STEP = 5200, HOLD = 10000;
  blocks.forEach(function (b) {
    var steps;
    try { steps = JSON.parse(b.getAttribute('data-steps')); } catch (e) { return; }
    var items = Array.prototype.slice.call(b.querySelectorAll('.hd-item')), imgs = Array.prototype.slice.call(b.querySelectorAll('.hd-img')),
        spots = Array.prototype.slice.call(b.querySelectorAll('.hd-spot')), pin = b.querySelector('.hd-pin'), cur = -1, timer = 0, hold = 0;
    b.style.setProperty('--hd-ms', STEP + 'ms');
    function show(k) {
      cur = k;
      var s = steps[k];
      imgs.forEach(function (im, i) { im.classList.toggle('is-on', i === s.s); });
      spots.forEach(function (sp, i) {
        var bx = s.b[i];
        if (!bx) { sp.classList.remove('on'); return; }
        sp.style.left = (bx[0] / 12.8) + '%'; sp.style.top = (bx[1] / 8) + '%'; sp.style.width = (bx[2] / 12.8) + '%'; sp.style.height = (bx[3] / 8) + '%';
        sp.classList.add('on');
      });
      pin.textContent = k + 1; pin.style.left = (s.b[0][0] / 12.8) + '%'; pin.style.top = (s.b[0][1] / 8) + '%'; pin.style.opacity = 1;
      items.forEach(function (it, i) {
        var on = i === k;
        it.classList.toggle('is-on', on);
        it.classList.remove('run');
        it.querySelector('.hd-btn').setAttribute('aria-expanded', on ? 'true' : 'false');
        if (on && !reduce && !hold) { void it.offsetWidth; it.classList.add('run'); }
      });
    }
    function visible() {
      var r = b.getBoundingClientRect(), h = window.innerHeight || document.documentElement.clientHeight;
      return r.top < h * 0.7 && r.bottom > 200 && !document.hidden;
    }
    function loop() {
      clearTimeout(timer); timer = 0;
      if (reduce || hold || !visible()) return;
      timer = setTimeout(function () { timer = 0; show((cur + 1) % steps.length); loop(); }, STEP);
    }
    items.forEach(function (it, k) {
      it.querySelector('.hd-btn').addEventListener('click', function () {
        clearTimeout(timer); timer = 0; clearTimeout(hold);
        hold = setTimeout(function () { hold = 0; if (items[cur]) { items[cur].classList.remove('run'); void items[cur].offsetWidth; items[cur].classList.add('run'); } loop(); }, HOLD);
        show(k);
      });
    });
    show(0);
    window.setInterval(function () { if (visible()) { if (!timer && !hold) { var it = items[cur]; if (it && !it.classList.contains('run') && !reduce) it.classList.add('run'); loop(); } } else if (timer) { clearTimeout(timer); timer = 0; if (items[cur]) items[cur].classList.remove('run'); } }, 700);
  });
})();
