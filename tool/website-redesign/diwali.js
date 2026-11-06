/* Invoiceo Diwali 2026: banner + cracker bursts. Shows until END, then does nothing. */
(function () {
  var END = new Date('2026-11-14T00:00:00+05:30');
  if (new Date() >= END) return;
  var TX = {
    en: { sndOn: 'Sound on', sndOff: 'Sound off',
      mTitle: 'Thank you, and Happy Diwali!', mSub: 'We hope Invoiceo makes your billing easier.', mBadge: 'FREE FOREVER', mPts: ['Free forever, no subscription', 'No limit on invoices', 'No sign-up, works offline', 'Your business data stays on your computer'], mWish: 'Light a diya and make a wish', mClose: 'Close',
      cd: function (d, h, m) { return 'Diwali in <b>' + d + ' d ' + h + ' h ' + m + ' min</b>'; }, cdDone: 'Wishing you a bright year ahead',
      inv: 'Get your Diwali invoice', invT: 'DIWALI INVOICE', billed: 'Billed to', you: 'You and your family', hItem: 'Item', hQty: 'Qty', hAmt: 'Amount', rows: [['Happy customers', '108'], ['Good luck', '365 days'], ['Sweets', 'Unlimited'], ['Worries', '0']], tot: 'FREE FOREVER', paid: 'PAID IN FULL', foot: 'Made with Invoiceo, free billing software for your shop', save: 'Save image', shr: 'Share', shopPh: 'Shop name (optional)', alt: 'Your Diwali invoice', ready: 'Your Diwali invoice is ready',
      ban: '<b>Happy Diwali from Invoiceo.</b> Light up your billing, free forever.', get: 'Get the free app', close: 'Close Diwali banner',
      btn: 'Light a diya', title: 'Make a wish for your shop', sub: 'Type it, light the diya, and watch it rise into the sky. Your wish stays on your device.',
      ph: 'A busy shop and happy customers', err: 'Type a wish first', go: 'Light the diya', lit: 'Your diya is lit', dt: 'Your wish is in the sky',
      dp: 'Wishing you a bright and prosperous year. We hope Invoiceo is a small part of it.', wa: 'Send Diwali wishes on WhatsApp', again: 'Make another wish',
      share: 'Happy Diwali! Free billing software for your shop, no sign-up: https://invoiceo.in', x: 'Close' },
    ta: { sndOn: 'ஒலி இயக்கம்', sndOff: 'ஒலி நிறுத்தம்',
      mTitle: 'நன்றி! இனிய தீபாவளி!', mSub: 'Invoiceo உங்கள் பில்லிங்கை எளிதாக்கும் என நம்புகிறோம்.', mBadge: 'என்றும் இலவசம்', mPts: ['என்றும் இலவசம், சந்தா இல்லை', 'பில் எண்ணிக்கைக்கு வரம்பு இல்லை', 'பதிவு தேவையில்லை, இணையம் இல்லாமலும் வேலை செய்யும்', 'உங்கள் வணிகத் தகவல் உங்கள் கணினியிலேயே இருக்கும்'], mWish: 'தீபம் ஏற்றி வேண்டுதல் செய்யுங்கள்', mClose: 'மூடு',
      cd: function (d, h, m) { return 'தீபாவளிக்கு இன்னும் <b>' + d + ' நாள் ' + h + ' மணி ' + m + ' நிமிடம்</b>'; }, cdDone: 'ஒளிமயமான ஆண்டாக அமையட்டும்',
      inv: 'உங்கள் தீபாவளி இன்வாய்ஸ்', invT: 'தீபாவளி இன்வாய்ஸ்', billed: 'பெறுபவர்', you: 'நீங்களும் உங்கள் குடும்பமும்', hItem: 'பொருள்', hQty: 'எண்ணிக்கை', hAmt: 'தொகை', rows: [['மகிழ்ச்சியான வாடிக்கையாளர்கள்', '108'], ['நல்ல அதிர்ஷ்டம்', '365 நாட்கள்'], ['இனிப்புகள்', 'வரம்பில்லை'], ['கவலைகள்', '0']], tot: 'என்றும் இலவசம்', paid: 'முழுவதும் செலுத்தப்பட்டது', foot: 'உங்கள் கடைக்கான இலவச பில்லிங் மென்பொருள் Invoiceo', save: 'படத்தைச் சேமி', shr: 'பகிர்', shopPh: 'கடையின் பெயர் (விருப்பம்)', alt: 'உங்கள் தீபாவளி இன்வாய்ஸ்', ready: 'உங்கள் தீபாவளி இன்வாய்ஸ் தயார்',
      ban: '<b>இனிய தீபாவளி நல்வாழ்த்துகள்!</b> உங்கள் பில்லிங் ஒளிரட்டும், என்றும் இலவசம்.', get: 'இலவச செயலியைப் பெறுங்கள்', close: 'தீபாவளி அறிவிப்பை மூடு',
      btn: 'தீபம் ஏற்றுங்கள்', title: 'உங்கள் கடைக்கு ஒரு வேண்டுதல்', sub: 'எழுதுங்கள், தீபம் ஏற்றுங்கள், வானில் எழுவதைப் பாருங்கள். உங்கள் வேண்டுதல் உங்கள் சாதனத்திலேயே இருக்கும்.',
      ph: 'நிறைய மகிழ்ச்சியான வாடிக்கையாளர்கள்', err: 'முதலில் ஒரு வேண்டுதலை எழுதுங்கள்', go: 'தீபம் ஏற்று', lit: 'உங்கள் தீபம் ஏற்றப்பட்டது', dt: 'உங்கள் வேண்டுதல் வானில் உள்ளது',
      dp: 'ஒளிமயமான, செழிப்பான ஆண்டாக அமையட்டும். அதில் Invoiceo ஒரு சிறு பங்காக இருக்கும் என நம்புகிறோம்.', wa: 'வாட்ஸ்அப்பில் தீபாவளி வாழ்த்து அனுப்புங்கள்', again: 'இன்னொரு வேண்டுதல்',
      share: 'இனிய தீபாவளி வாழ்த்துகள்! உங்கள் கடைக்கு இலவச பில்லிங் மென்பொருள், பதிவு தேவையில்லை: https://invoiceo.in/ta.html', x: 'மூடு' },
    hi: { sndOn: 'आवाज़ चालू', sndOff: 'आवाज़ बंद',
      mTitle: 'धन्यवाद! दिवाली की शुभकामनाएं!', mSub: 'हमें उम्मीद है Invoiceo आपकी बिलिंग आसान करेगा।', mBadge: 'हमेशा मुफ़्त', mPts: ['हमेशा मुफ़्त, कोई सब्सक्रिप्शन नहीं', 'इनवॉइस की कोई सीमा नहीं', 'साइन-अप नहीं, ऑफ़लाइन चलता है', 'आपका कारोबारी डेटा आपके कंप्यूटर पर ही रहता है'], mWish: 'दीया जलाकर मन्नत मांगें', mClose: 'बंद करें',
      cd: function (d, h, m) { return 'दिवाली में बाकी <b>' + d + ' दिन ' + h + ' घंटे ' + m + ' मिनट</b>'; }, cdDone: 'आपका साल रोशन हो',
      inv: 'अपना दिवाली इनवॉइस पाएं', invT: 'दिवाली इनवॉइस', billed: 'बिल प्राप्तकर्ता', you: 'आप और आपका परिवार', hItem: 'विवरण', hQty: 'मात्रा', hAmt: 'राशि', rows: [['खुश ग्राहक', '108'], ['शुभ किस्मत', '365 दिन'], ['मिठाइयां', 'असीमित'], ['चिंताएं', '0']], tot: 'हमेशा मुफ़्त', paid: 'पूरा भुगतान हुआ', foot: 'आपकी दुकान के लिए मुफ़्त बिलिंग सॉफ़्टवेयर Invoiceo', save: 'इमेज सेव करें', shr: 'शेयर करें', shopPh: 'दुकान का नाम (वैकल्पिक)', alt: 'आपका दिवाली इनवॉइस', ready: 'आपका दिवाली इनवॉइस तैयार है',
      ban: '<b>दिवाली की शुभकामनाएं!</b> अपनी बिलिंग को रोशन करें, हमेशा मुफ़्त।', get: 'मुफ़्त ऐप पाएं', close: 'दिवाली बैनर बंद करें',
      btn: 'दीया जलाएं', title: 'अपनी दुकान के लिए मन्नत मांगें', sub: 'लिखें, दीया जलाएं और उसे आसमान में उठते देखें। आपकी मन्नत आपके डिवाइस पर ही रहती है।',
      ph: 'ढेर सारे खुश ग्राहक', err: 'पहले मन्नत लिखें', go: 'दीया जलाएं', lit: 'आपका दीया जल गया', dt: 'आपकी मन्नत आसमान में है',
      dp: 'आपका साल रोशन और खुशहाल हो। हमें उम्मीद है Invoiceo इसमें छोटा सा साथ देगा।', wa: 'व्हाट्सऐप पर दिवाली की शुभकामनाएं भेजें', again: 'एक और मन्नत',
      share: 'दिवाली की शुभकामनाएं! दुकानों के लिए मुफ़्त बिलिंग सॉफ़्टवेयर, साइन-अप नहीं: https://invoiceo.in/hi.html', x: 'बंद करें' }
  };
  var L = TX[(document.documentElement.lang || 'en').slice(0, 2)] || TX.en;
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  try { if (localStorage.getItem('dw26-closed') === '1') var closed = true; } catch (e) {}

  var GREET = ['Happy Diwali', 'இனிய தீபாவளி', 'दिवाली की शुभकामनाएं', 'దీపావళి శుభాకాంక్షలు', 'ദീപാവലി ആശംസകൾ', 'ದೀಪಾವಳಿ ಹಬ್ಬದ ಶುಭಾಶಯಗಳು', 'শুভ দীপাবলি', 'દિવાળીની શુભેચ્છાઓ'];
  var DIWALI_AT = new Date('2026-11-08T18:00:00+05:30');
  function countdown() {
    var ms = DIWALI_AT - new Date();
    if (ms <= 0) return L.cdDone;
    var m = Math.floor(ms / 60000);
    return L.cd(Math.floor(m / 1440), Math.floor((m % 1440) / 60), m % 60);
  }

  if (!closed) {
    var b = document.createElement('div');
    b.className = 'dw-banner';
    b.innerHTML = '<span class="dw-lamp" aria-hidden="true"></span><span class="dw-msg" aria-live="off"></span>' +
      '<a href="download.html">' + L.get + '</a>' +
      '<button type="button" class="dw-x" aria-label="' + L.close + '">&times;</button>' +
      '<div class="dw-lights" aria-hidden="true"></div>';
    document.body.insertBefore(b, document.body.firstChild);
    b.querySelector('.dw-x').onclick = function () {
      b.remove(); try { localStorage.setItem('dw26-closed', '1'); } catch (e) {}
    };
    b.querySelector('.dw-lamp').innerHTML = '<svg viewBox="-70 -90 140 140" width="26" height="26"><path d="M-60 0 Q-58 38 0 40 Q58 38 60 0Z" fill="#7c2d12"/><path d="M-60 0 Q0 -16 60 0 Q0 12 -60 0Z" fill="#9a3412"/><g class="dw-flame"><path d="M0 -8 Q-16 -42 0 -80 Q16 -42 0 -8Z" fill="#FDE68A"/><path d="M0 -10 Q-8 -34 0 -58 Q8 -34 0 -10Z" fill="#fff"/></g></svg>';

    // String lights hanging under the banner.
    var lights = b.querySelector('.dw-lights'), LC = ['#FDE68A', '#F472B6', '#34D399', '#60A5FA', '#FB923C'];
    function drawLights() {
      var w = b.clientWidth, step = 54, n = Math.ceil(w / step) + 1, p = 'M0 0', bulbs = '';
      for (var i = 0; i < n; i++) {
        var x0 = i * step; p += ' Q' + (x0 + step / 2) + ' 18 ' + (x0 + step) + ' 0';
        bulbs += '<g class="dw-bulb" style="animation-delay:' + ((i * 0.37) % 2).toFixed(2) + 's"><rect x="' + (x0 + step / 2 - 2.5) + '" y="6" width="5" height="5" rx="1" fill="#6b7280"/><ellipse cx="' + (x0 + step / 2) + '" cy="15" rx="5" ry="6.5" fill="' + LC[i % LC.length] + '"/></g>';
      }
      lights.innerHTML = '<svg width="' + w + '" height="26" viewBox="0 0 ' + w + ' 26" xmlns="http://www.w3.org/2000/svg"><path d="' + p + '" fill="none" stroke="#6b7280" stroke-width="1.5"/>' + bulbs + '</svg>';
    }
    drawLights();
    var rz; addEventListener('resize', function () { clearTimeout(rz); rz = setTimeout(drawLights, 150); });

    // The message changes: tagline, greetings in several languages, then a live countdown.
    var msg = b.querySelector('.dw-msg'), seq = [L.ban], gi = 0;
    GREET.forEach(function (g) { seq.push('<span class="dw-gr">' + g + '</span>'); });
    seq.push('COUNTDOWN');
    function show(i) {
      var h = seq[i] === 'COUNTDOWN' ? countdown() : seq[i];
      msg.innerHTML = h; msg.classList.remove('dw-in'); void msg.offsetWidth; msg.classList.add('dw-in');
    }
    show(0);
    if (!reduce) {
      (function next() {
        var cur = gi; gi = (gi + 1) % seq.length;
        setTimeout(function () { if (!document.body.contains(b)) return; show(gi); next(); }, cur === 0 || seq[cur] === 'COUNTDOWN' ? 4200 : 1700);
      })();
    }
  }
  var fx = null, rocketFrom = null, openWish = null;
  if (!reduce) initCrackers();
  initWish();
  // A real installer link (the download starts as usual): rocket, burst, then the thank-you card.
  document.addEventListener('click', function (e) {
    var dl = e.target.closest && e.target.closest('a[href]');
    if (dl && isInstaller(dl.href)) celebrate(e.clientX, e.clientY);
  }, true);

  function initCrackers() {
  var cv = document.createElement('canvas');
  cv.setAttribute('aria-hidden', 'true');
  cv.style.cssText = 'position:fixed;left:0;top:0;width:100%;height:100%;pointer-events:none;z-index:40';
  document.body.appendChild(cv);
  var ctx = cv.getContext('2d'), W = 0, H = 0, dpr = Math.min(window.devicePixelRatio || 1, 2);
  function size() {
    W = innerWidth; H = innerHeight;
    cv.width = W * dpr; cv.height = H * dpr; ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  size(); addEventListener('resize', size);

  var COLORS = ['#F59E0B', '#F97316', '#EC4899', '#10B981', '#3B82F6', '#FDE68A', '#A855F7'];
  var rockets = [], parts = [], running = false, last = 0, autoUntil = 0, nextAuto = 0, grand = null, flash = 0;
  function rnd(a, b) { return a + Math.random() * (b - a); }

  function launch(x, targetY) {
    rockets.push({ x: x, y: H + 10, vy: -rnd(9, 12), ty: targetY, c: COLORS[(Math.random() * COLORS.length) | 0], trail: [] });
    start();
  }
  function burst(x, y, c, big) {
    var m = W < 600 ? 0.7 : 1, n = big ? 150 : 60, sp = (big ? 9.5 : 4.6) * m, ring = Math.random() < 0.35, cap = big ? 1500 : 700;
    for (var i = 0; i < n && parts.length < cap; i++) {
      var a = (i / n) * Math.PI * 2, s = ring ? sp : rnd(sp * 0.25, sp);
      parts.push({ x: x, y: y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, l: 1, d: big ? rnd(0.006, 0.011) : rnd(0.008, 0.014),
        c: Math.random() < 0.2 ? '#FFF7D6' : c, r: big ? rnd(2, 4) : rnd(1.4, 2.6) });
    }
  }
  function frame(t) {
    var raw = t - last, dt = Math.min(raw / 16.67, 3); last = t;
    ctx.clearRect(0, 0, W, H);
    if (t < autoUntil && t > nextAuto) {
      var side = Math.random() < 0.5;
      launch(side ? rnd(W * 0.04, W * 0.24) : rnd(W * 0.76, W * 0.96), rnd(H * 0.15, H * 0.5));
      nextAuto = t + rnd(500, 1300);
    }
    for (var i = rockets.length - 1; i >= 0; i--) {
      var r = rockets[i]; r.y += r.vy * dt; r.vy *= 0.985; r.trail.push([r.x, r.y]); if (r.trail.length > 10) r.trail.shift();
      ctx.lineWidth = 2; ctx.strokeStyle = r.c; ctx.globalAlpha = 0.8; ctx.beginPath();
      ctx.moveTo(r.trail[0][0], r.trail[0][1]); for (var k = 1; k < r.trail.length; k++) ctx.lineTo(r.trail[k][0], r.trail[k][1]); ctx.stroke();
      if (r.y <= r.ty || r.vy > -2) {
        burst(r.x, r.y, r.c, r.big);
        if (r.cb) { burst(r.x - 90, r.y + 40, '#EC4899', true); burst(r.x + 90, r.y + 25, '#34D399', true); burst(r.x, r.y - 50, '#60A5FA', false); r.cb(); }
        rockets.splice(i, 1);
      }
    }
    if (grand) {
      grand.t += Math.min(raw, 100) / 2200;
      var u = Math.min(grand.t, 1), P = grand.pts, n = P.length - 1, f = u * n, i0 = Math.min(Math.floor(f), n - 1), q = f - i0;
      function cr(a, b, c2, d, k) { return 0.5 * ((2 * b) + (-a + c2) * k + (2 * a - 5 * b + 4 * c2 - d) * k * k + (-a + 3 * b - 3 * c2 + d) * k * k * k); }
      var p0 = P[Math.max(i0 - 1, 0)], p1 = P[i0], p2 = P[i0 + 1], p3 = P[Math.min(i0 + 2, n)];
      var gx = cr(p0[0], p1[0], p2[0], p3[0], q), gy = cr(p0[1], p1[1], p2[1], p3[1], q);
      var ang = Math.atan2(gy - grand.y, gx - grand.x); if (grand.y === null || isNaN(ang)) ang = -1.2;
      grand.ang = grand.lastX === undefined ? ang : grand.ang + (ang - grand.ang) * 0.35;
      grand.lastX = gx; grand.x = gx; grand.y = gy;
      var KK = W < 600 ? 0.75 : 1;
      for (var s2 = 0; s2 < 6 && parts.length < 700; s2++) {
        parts.push({ x: gx - Math.cos(grand.ang) * 26 * KK, y: gy - Math.sin(grand.ang) * 26 * KK, vx: rnd(-1.2, 1.2) - Math.cos(grand.ang) * 1.6, vy: rnd(-1.2, 1.2) - Math.sin(grand.ang) * 1.6,
          l: 1, d: rnd(0.02, 0.04), c: Math.random() < 0.5 ? '#FDE68A' : (Math.random() < 0.5 ? '#FB923C' : '#fff'), r: rnd(2, 4.5) * KK });
      }
      var K = W < 600 ? 2.4 : 3.2;
      ctx.save(); ctx.translate(gx, gy); ctx.rotate(grand.ang); ctx.scale(K, K); ctx.globalAlpha = 1;
      ctx.fillStyle = '#FB923C'; ctx.beginPath(); ctx.moveTo(-9, -3); ctx.lineTo(-22 - Math.random() * 7, 0); ctx.lineTo(-9, 3); ctx.fill();
      ctx.fillStyle = '#EF4444'; ctx.beginPath(); ctx.moveTo(-8, -3); ctx.lineTo(-13, -8); ctx.lineTo(-3, -3); ctx.moveTo(-8, 3); ctx.lineTo(-13, 8); ctx.lineTo(-3, 3); ctx.fill();
      ctx.fillStyle = '#fff'; ctx.fillRect(-9, -3.5, 17, 7);
      ctx.fillStyle = '#EF4444'; ctx.beginPath(); ctx.moveTo(8, -3.5); ctx.lineTo(15, 0); ctx.lineTo(8, 3.5); ctx.fill();
      ctx.restore();
      if (grand.t >= 1) {
        var g = grand; grand = null; flash = 0.7;
        var sx = W < 600 ? 0.6 : 1;
        burst(gx, gy, '#FDE68A', true); burst(gx - 190 * sx, gy + 70, '#EC4899', true); burst(gx + 190 * sx, gy + 40, '#34D399', true);
        burst(gx, gy - 150 * sx, '#60A5FA', true); burst(gx - 100 * sx, gy - 60, '#F97316', true); burst(gx + 100 * sx, gy + 120 * sx, '#A855F7', true);
        boom();
        if (g.cb) g.cb();
      }
    }
    for (var j = parts.length - 1; j >= 0; j--) {
      var p = parts[j]; p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 0.07 * dt; p.vx *= 0.988; p.vy *= 0.988; p.l -= p.d * dt;
      if (p.l <= 0) { parts.splice(j, 1); continue; }
      ctx.globalAlpha = p.l; ctx.fillStyle = p.c; ctx.beginPath(); ctx.arc(p.x, p.y, p.r * (0.5 + p.l / 2), 0, 6.283); ctx.fill();
    }
    ctx.globalAlpha = 1;
    if (flash > 0.01) { ctx.globalAlpha = flash; ctx.fillStyle = '#FFF3C4'; ctx.fillRect(0, 0, W, H); ctx.globalAlpha = 1; flash *= Math.pow(0.88, dt); }
    if (rockets.length || parts.length || grand || flash > 0.01 || t < autoUntil) requestAnimationFrame(frame); else { running = false; ctx.clearRect(0, 0, W, H); }
  }
  function start() { if (!running) { running = true; last = performance.now(); requestAnimationFrame(frame); } }

  rocketFrom = function (x, y, cb) {
    var right = x < W / 2 ? 1 : -1;
    grand = { t: 0, x: x, y: y, ang: -1.2, cb: cb, pts: [[x, y], [x - right * W * 0.22, y - H * 0.12], [W * (right > 0 ? 0.12 : 0.88), H * 0.55], [W * (right > 0 ? 0.2 : 0.8), H * 0.14],
      [W * 0.5, H * 0.07], [W * (right > 0 ? 0.86 : 0.14), H * 0.2], [W * (right > 0 ? 0.9 : 0.1), H * 0.6], [W * (right > 0 ? 0.7 : 0.3), H * 0.52], [W * 0.5, H * 0.3]] };
    var g0 = grand; setTimeout(function () { if (grand === g0) grand.t = 1; }, 4200);
    start();
  };
  fx = function (x, y) { burst(x, y, COLORS[(Math.random() * COLORS.length) | 0], true); start(); };
  autoUntil = performance.now() + 12000; nextAuto = performance.now() + 600; start();

  document.addEventListener('click', function (e) {
    if (e.target.closest && e.target.closest('.dw-x')) return;
    var dl = e.target.closest && e.target.closest('a[href]');
    if (dl && isInstaller(dl.href)) return;
    var c = COLORS[(Math.random() * COLORS.length) | 0];
    if (e.target.closest && e.target.closest('a[href*="download"],.btn-primary,button')) {
      for (var i = 0; i < 4; i++) setTimeout(function () { launch(rnd(W * 0.1, W * 0.9), rnd(H * 0.12, H * 0.45)); }, i * 150);
    }
    burst(e.clientX, e.clientY, c, false); start();
  }, true);
  }


  // Sound (made in the browser, no audio files). It starts only after a click on a download link, so browsers allow it.
  var actx = null, master = null;
  function audioInit() {
    try {
      var AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      if (!actx) {
        actx = new AC();
        var comp = actx.createDynamicsCompressor(); master = actx.createGain(); master.gain.value = 0.55;
        master.connect(comp); comp.connect(actx.destination);
      }
      if (actx.state === 'suspended') actx.resume();
    } catch (e) { actx = null; }
  }
  function noiseBuf(sec) {
    var n = Math.floor(actx.sampleRate * sec), b = actx.createBuffer(1, n, actx.sampleRate), d = b.getChannelData(0);
    for (var i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
    return b;
  }
  function whistle(dur) {
    if (!actx || !soundOn) return;
    try {
      var t = actx.currentTime, o = actx.createOscillator(), g = actx.createGain();
      o.type = 'sine'; o.frequency.setValueAtTime(450, t); o.frequency.exponentialRampToValueAtTime(2400, t + dur);
      g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(0.07, t + 0.2); g.gain.linearRampToValueAtTime(0.0001, t + dur);
      o.connect(g); g.connect(master); o.start(t); o.stop(t + dur + 0.05);
    } catch (e) {}
  }
  function boom() {
    if (!actx || !soundOn) return;
    try {
      var t = actx.currentTime;
      var nz = actx.createBufferSource(); nz.buffer = noiseBuf(1.8);
      var lp = actx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.setValueAtTime(5000, t); lp.frequency.exponentialRampToValueAtTime(180, t + 1.3);
      var g = actx.createGain(); g.gain.setValueAtTime(1, t); g.gain.exponentialRampToValueAtTime(0.001, t + 1.6);
      nz.connect(lp); lp.connect(g); g.connect(master); nz.start(t);
      var o = actx.createOscillator(), og = actx.createGain();
      o.type = 'sine'; o.frequency.setValueAtTime(130, t); o.frequency.exponentialRampToValueAtTime(38, t + 0.7);
      og.gain.setValueAtTime(1, t); og.gain.exponentialRampToValueAtTime(0.001, t + 0.9);
      o.connect(og); og.connect(master); o.start(t); o.stop(t + 1);
      pops(26, 0.7, 1.6);
      for (var i = 0; i < 14; i++) {
        var at = t + 0.12 + Math.random() * 1.1, c = actx.createBufferSource(); c.buffer = noiseBuf(0.05);
        var hp = actx.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 2500 + Math.random() * 3000;
        var cg = actx.createGain(); cg.gain.setValueAtTime(0.35, at); cg.gain.exponentialRampToValueAtTime(0.001, at + 0.05);
        c.connect(hp); hp.connect(cg); cg.connect(master); c.start(at);
      }
    } catch (e) {}
  }

  // More sounds, all made in the browser. A speaker button (banner, wish card, thank-you card) turns them off for good.
  var soundOn = true;
  try { soundOn = localStorage.getItem('dw26-sound') !== 'off'; } catch (e) {}
  var ICON_ON = '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/></svg>';
  var ICON_OFF = '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M11 5 6 9H2v6h4l5 4z"/><line x1="22" y1="9" x2="16" y2="15"/><line x1="16" y1="9" x2="22" y2="15"/></svg>';
  function sndHtml() { return '<button type="button" class="dw-snd" aria-label="' + (soundOn ? L.sndOn : L.sndOff) + '" title="' + (soundOn ? L.sndOn : L.sndOff) + '">' + (soundOn ? ICON_ON : ICON_OFF) + '</button>'; }
  function refreshSnd() {
    [].forEach.call(document.querySelectorAll('.dw-snd'), function (b) { b.innerHTML = soundOn ? ICON_ON : ICON_OFF; b.setAttribute('aria-label', soundOn ? L.sndOn : L.sndOff); b.title = soundOn ? L.sndOn : L.sndOff; });
  }
  function bindSnd(root) {
    [].forEach.call(root.querySelectorAll('.dw-snd'), function (b) {
      b.onclick = function (e) {
        e.stopPropagation(); soundOn = !soundOn;
        try { localStorage.setItem('dw26-sound', soundOn ? 'on' : 'off'); } catch (er) {}
        refreshSnd(); if (soundOn) { audioInit(); bell(880, 0, 0.18); }
      };
    });
  }
  function ok() { return actx && soundOn; }
  // A temple bell: several partials that are not whole multiples, each dying away at its own speed.
  function bell(f, delay, gain) {
    if (!ok()) return;
    try {
      var t = actx.currentTime + (delay || 0), P = [[1, 1, 2.2], [2.76, 0.55, 1.4], [5.4, 0.3, 0.9], [8.93, 0.18, 0.5]];
      P.forEach(function (p) {
        var o = actx.createOscillator(), g = actx.createGain(); o.type = 'sine'; o.frequency.value = f * p[0];
        g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime((gain || 0.25) * p[1], t + 0.008); g.gain.exponentialRampToValueAtTime(0.0001, t + p[2]);
        o.connect(g); g.connect(master); o.start(t); o.stop(t + p[2] + 0.05);
      });
    } catch (e) {}
  }
  // Rows of small crackers going off one after another, like a string of "ladi".
  function pops(n, delay, span) {
    if (!ok()) return;
    try {
      var t0 = actx.currentTime + (delay || 0);
      for (var i = 0; i < n; i++) {
        var at = t0 + (i / n) * span + Math.random() * 0.03, c = actx.createBufferSource(); c.buffer = noiseBuf(0.07);
        var bp = actx.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 900 + Math.random() * 2600; bp.Q.value = 0.8;
        var g = actx.createGain(); g.gain.setValueAtTime(0.5 + Math.random() * 0.4, at); g.gain.exponentialRampToValueAtTime(0.001, at + 0.07);
        c.connect(bp); bp.connect(g); g.connect(master); c.start(at);
      }
    } catch (e) {}
  }
  // A gentle run of notes going up (a pentatonic scale): the lantern floating away.
  function shimmer() {
    if (!ok()) return;
    try {
      var t = actx.currentTime, N = [523.25, 587.33, 659.25, 783.99, 880, 1046.5, 1174.7, 1318.5];
      N.forEach(function (f, i) {
        var o = actx.createOscillator(), g = actx.createGain(), at = t + i * 0.13; o.type = 'triangle'; o.frequency.value = f;
        g.gain.setValueAtTime(0.0001, at); g.gain.exponentialRampToValueAtTime(0.11, at + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, at + 1.1);
        o.connect(g); g.connect(master); o.start(at); o.stop(at + 1.2);
      });
    } catch (e) {}
  }
  // The diya catches: a soft "whoomp" of flame and a small bell.
  function whoomp() {
    if (!ok()) return;
    try {
      var t = actx.currentTime, nz = actx.createBufferSource(); nz.buffer = noiseBuf(0.6);
      var lp = actx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.setValueAtTime(300, t); lp.frequency.exponentialRampToValueAtTime(1800, t + 0.25); lp.frequency.exponentialRampToValueAtTime(200, t + 0.6);
      var g = actx.createGain(); g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(0.5, t + 0.12); g.gain.exponentialRampToValueAtTime(0.001, t + 0.6);
      nz.connect(lp); lp.connect(g); g.connect(master); nz.start(t);
    } catch (e) {}
    bell(1318.5, 0.25, 0.14);
  }
  // Billing joke: the "ka-ching" of a till when the Diwali invoice is ready.
  function kaching() {
    if (!ok()) return;
    bell(1760, 0, 0.2); bell(2349, 0.11, 0.2);
    try {
      var t = actx.currentTime, c = actx.createBufferSource(); c.buffer = noiseBuf(0.08);
      var hp = actx.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 3000;
      var g = actx.createGain(); g.gain.setValueAtTime(0.4, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.08);
      c.connect(hp); hp.connect(g); g.connect(master); c.start(t);
    } catch (e) {}
  }

  function isInstaller(href) {
    return /\/releases\/(?:latest\/)?download\/(?:[^/]+\/)?[^/?#]+\.(exe|dmg|deb|appimage)$/i.test(href);
  }
  var modalOpen = false;
  function celebrate(x, y) {
    if (modalOpen) return;
    modalOpen = true;
    audioInit();
    if (rocketFrom) { whistle(2.2); }
    if (rocketFrom) rocketFrom(x, y, function () { setTimeout(showModal, 700); });
    else setTimeout(showModal, 200);
  }
  function showModal() {
    // The site's own install tip (the toast) moves into this card, so there is one message, not two.
    var tip = '', t = document.querySelector('.dl-toast div');
    if (t) tip = t.innerHTML;
    var tt = document.querySelector('.dl-toast'); if (tt) tt.style.display = 'none';
    var o = document.createElement('div');
    o.className = 'dw-modal'; o.setAttribute('role', 'dialog'); o.setAttribute('aria-modal', 'true'); o.setAttribute('aria-label', L.mTitle);
    o.innerHTML = '<div class="dw-card"><button type="button" class="dw-m-x" aria-label="' + L.mClose + '">&times;</button>' +
      '<div class="dw-m-top"><div class="dw-m-diyas" aria-hidden="true"></div><h2>' + L.mTitle + '</h2><p>' + L.mSub + '</p><span class="dw-m-badge">' + L.mBadge + '</span></div>' +
      '<ul class="dw-m-list">' + L.mPts.map(function (p) { return '<li>' + p + '</li>'; }).join('') + '</ul>' +
      (tip ? '<div class="dw-m-tip">' + tip + '</div>' : '') +
      '<div class="dw-m-act"><button type="button" class="dw-go dw-m-wish">' + L.mWish + '</button><button type="button" class="dw-again dw-m-close">' + L.mClose + '</button></div></div>';
    document.body.appendChild(o);
    var d = '';
    [-1, 0, 1].forEach(function (k) { d += '<svg viewBox="-70 -90 140 140" width="' + (k === 0 ? 56 : 40) + '" height="' + (k === 0 ? 56 : 40) + '"><path d="M-60 0 Q-58 38 0 40 Q58 38 60 0Z" fill="#C2410C"/><path d="M-60 0 Q0 -16 60 0 Q0 12 -60 0Z" fill="#EA580C"/><g class="dw-flame"><path d="M0 -8 Q-16 -42 0 -80 Q16 -42 0 -8Z" fill="#FBBF24"/><path d="M0 -10 Q-8 -34 0 -58 Q8 -34 0 -10Z" fill="#FEF3C7"/></g></svg>'; });
    o.querySelector('.dw-m-diyas').innerHTML = d;
    function close() { o.remove(); modalOpen = false; document.removeEventListener('keydown', onKey, true); }
    function onKey(e) { if (e.key === 'Escape') close(); }
    document.addEventListener('keydown', onKey, true);
    o.addEventListener('click', function (e) { if (e.target === o) close(); });
    o.querySelector('.dw-m-x').onclick = close; o.querySelector('.dw-m-close').onclick = close;
    o.querySelector('.dw-m-wish').onclick = function () { close(); if (openWish) openWish(); };
    o.querySelector('.dw-card').insertAdjacentHTML('beforeend', sndHtml()); bindSnd(o);
    bell(659.25, 0, 0.3); bell(880, 0.28, 0.25); bell(1318.5, 0.6, 0.18);
    o.querySelector('.dw-m-close').focus();
  }

  function initWish() {
    var NS = 'http://www.w3.org/2000/svg';
    var diyaSvg = '<svg viewBox="-70 -90 140 140" width="__W__" height="__W__" aria-hidden="true"><ellipse cx="0" cy="40" rx="62" ry="8" fill="#000" opacity=".15"/><path d="M-60 0 Q-58 38 0 40 Q58 38 60 0Z" fill="#C2410C"/><path d="M-60 0 Q0 -16 60 0 Q0 12 -60 0Z" fill="#EA580C"/><g class="dw-flame"><path d="M0 -8 Q-16 -42 0 -80 Q16 -42 0 -8Z" fill="#FBBF24"/><path d="M0 -10 Q-8 -34 0 -58 Q8 -34 0 -10Z" fill="#FEF3C7"/></g></svg>';

    var btn = document.createElement('button');
    btn.type = 'button'; btn.className = 'dw-wish-btn'; btn.setAttribute('aria-label', L.btn);
    btn.innerHTML = diyaSvg.replace(/__W__/g, '26') + '<span>' + L.btn + '</span>';
    var panel = document.createElement('div');
    panel.className = 'dw-panel'; panel.hidden = true; panel.setAttribute('role', 'dialog'); panel.setAttribute('aria-label', L.title);
    document.body.appendChild(btn); document.body.appendChild(panel);

    var state = { wish: '', shop: '' };
    function dusk() {
      if (reduce) return;
      var d = document.createElement('div'); d.className = 'dw-dusk'; document.body.appendChild(d);
      setTimeout(function () { d.remove(); }, 6200);
    }
    function showAsk() {
      panel.innerHTML = '<button type="button" class="dw-p-x" aria-label="' + L.x + '">&times;</button>' +
        '<h3>' + L.title + '</h3>' +
        '<p>' + L.sub + '</p>' +
        '<input id="dw-wish" type="text" maxlength="60" placeholder="' + L.ph + '" aria-label="' + L.title + '">' +
        '<div class="dw-err" id="dw-err" hidden>' + L.err + '</div>' +
        '<input id="dw-shop" type="text" maxlength="40" placeholder="' + L.shopPh + '" aria-label="' + L.shopPh + '">' +
        '<button type="button" class="dw-go">' + L.go + '</button>';
      panel.querySelector('.dw-p-x').onclick = function () { panel.hidden = true; };
      panel.insertAdjacentHTML('beforeend', sndHtml()); bindSnd(panel);
      var inp = panel.querySelector('#dw-wish');
      inp.oninput = function () { panel.querySelector('#dw-err').hidden = true; };
      inp.onkeydown = function (e) { if (e.key === 'Enter') go(); };
      panel.querySelector('.dw-go').onclick = go;
      setTimeout(function () { inp.focus(); }, 50);
    }
    function go() {
      var v = panel.querySelector('#dw-wish').value.trim();
      if (!v) { panel.querySelector('#dw-err').hidden = false; return; }
      state = { wish: v, shop: panel.querySelector('#dw-shop').value.trim() };
      dusk();
      audioInit();
      panel.innerHTML = '<div class="dw-lit">' + diyaSvg.replace(/__W__/g, '110') + '</div><p class="dw-lit-t">' + L.lit + '</p>';
      var r = panel.getBoundingClientRect();
      setTimeout(function () { release(v, r.left + r.width / 2, r.top + 40); }, 1300);
      setTimeout(done, reduce ? 1500 : 3200);
    }
    function release(text, x, y) {
      if (reduce) return;
      var l = document.createElement('div');
      l.className = 'dw-lantern'; l.style.left = (x - 70) + 'px'; l.style.top = y + 'px';
      l.innerHTML = '<div class="dw-l-body"><div class="dw-l-cap"></div><div class="dw-l-paper"><span></span></div><div class="dw-l-cap"></div></div>';
      l.querySelector('span').textContent = text;
      document.body.appendChild(l);
      if (fx) { fx(x - 60, y); fx(x + 60, y - 30); }
      setTimeout(function () { l.remove(); }, 11000);
    }
    function done() {
      panel.innerHTML = '<button type="button" class="dw-p-x" aria-label="' + L.x + '">&times;</button>' +
        '<h3>' + L.dt + '</h3>' +
        '<p>' + L.dp + '</p>' +
        '<button type="button" class="dw-go dw-inv">' + L.inv + '</button>' +
        '<a class="dw-go dw-ghost" target="_blank" rel="noopener" href="https://wa.me/?text=' + encodeURIComponent(L.share) + '">' + L.wa + '</a>' +
        '<button type="button" class="dw-again">' + L.again + '</button>';
      panel.querySelector('.dw-p-x').onclick = function () { panel.hidden = true; };
      panel.querySelector('.dw-again').onclick = showAsk;
      panel.querySelector('.dw-inv').onclick = showInvoice;
    }

    function wrap(c, text, x, y, maxW, lh, maxLines) {
      var words = text.split(/\s+/), line = '', lines = [];
      words.forEach(function (w) {
        var t = line ? line + ' ' + w : w;
        if (c.measureText(t).width > maxW && line) { lines.push(line); line = w; } else line = t;
      });
      lines.push(line);
      if (lines.length > maxLines) { lines = lines.slice(0, maxLines); lines[maxLines - 1] = lines[maxLines - 1].replace(/.{0,2}$/, '…'); }
      lines.forEach(function (l, i) { c.fillText(l, x, y + i * lh); });
      return lines.length;
    }
    function drawInvoice(logo) {
      var cv = document.createElement('canvas'); cv.width = 1080; cv.height = 1350;
      var c = cv.getContext('2d'), F = 'Manrope, "Noto Sans Tamil", "Noto Sans Devanagari", system-ui, sans-serif', S = 'Fraunces, Georgia, serif';
      c.fillStyle = '#FFF8EB'; c.fillRect(0, 0, 1080, 1350);
      c.strokeStyle = '#F59E0B'; c.lineWidth = 6; c.strokeRect(24, 24, 1032, 1302);
      var g = c.createLinearGradient(0, 0, 1080, 0); g.addColorStop(0, '#F59E0B'); g.addColorStop(1, '#EA580C');
      c.fillStyle = g; c.fillRect(30, 30, 1020, 190);
      c.fillStyle = '#fff'; c.textBaseline = 'alphabetic'; c.font = '700 58px ' + S; c.fillText(L.invT, 70, 150);
      c.font = '600 24px ' + F; c.textAlign = 'right'; c.fillText('No. DW-2026-' + (1000 + Math.floor(Math.random() * 9000)), 1010, 100);
      c.fillText(new Date().toLocaleDateString(document.documentElement.lang || 'en', { day: 'numeric', month: 'long', year: 'numeric' }), 1010, 140);
      c.textAlign = 'left'; c.fillStyle = '#7c2d12'; c.font = '600 24px ' + F; c.fillText(L.billed.toUpperCase(), 70, 290);
      c.fillStyle = '#1e293b'; c.font = '700 46px ' + S; wrap(c, state.shop || L.you, 70, 345, 940, 54, 2);
      var y = 450; c.fillStyle = '#FDE7C0'; c.fillRect(70, y, 940, 58);
      c.fillStyle = '#7c2d12'; c.font = '700 22px ' + F; c.fillText(L.hItem.toUpperCase(), 90, y + 38);
      c.textAlign = 'right'; c.fillText(L.hQty.toUpperCase(), 760, y + 38); c.fillText(L.hAmt.toUpperCase(), 990, y + 38); c.textAlign = 'left';
      var rows = [[state.wish, '1']].concat(L.rows); y += 58;
      rows.forEach(function (r, i) {
        var h = i === 0 ? 140 : 84, base = y + (i === 0 ? 48 : 40);
        c.fillStyle = '#1e293b'; c.font = (i === 0 ? '700 32px ' : '500 29px ') + F;
        wrap(c, r[0], 90, base, 540, i === 0 ? 38 : 34, i === 0 ? 3 : 2);
        c.textAlign = 'right'; c.font = '500 29px ' + F; c.fillText(r[1], 770, y + 40); c.fillText('0.00', 990, y + 40); c.textAlign = 'left';
        y += h; c.strokeStyle = '#F3D9A8'; c.lineWidth = 2; c.beginPath(); c.moveTo(70, y); c.lineTo(1010, y); c.stroke();
      });
      y += 80; c.fillStyle = '#7c2d12'; c.font = '700 30px ' + F; c.fillText('TOTAL', 90, y);
      c.fillStyle = '#B45309'; c.font = '700 64px ' + S; c.textAlign = 'right'; c.fillText(L.tot, 1000, y + 6); c.textAlign = 'left';
      c.save(); c.translate(540, 1132); c.rotate(-0.1); c.font = '800 36px ' + F; var sw = c.measureText(L.paid).width + 60;
      c.strokeStyle = '#0F766E'; c.lineWidth = 7; c.strokeRect(-sw / 2, -46, sw, 92);
      c.fillStyle = '#0F766E'; c.textAlign = 'center'; c.fillText(L.paid, 0, 13); c.restore();
      c.textAlign = 'center'; c.fillStyle = '#7c2d12'; c.font = '600 28px ' + F; c.fillText('Happy Diwali', 540, 1226);
      if (logo) { var lh = 52, lw = logo.width * lh / logo.height; c.drawImage(logo, 540 - lw / 2, 1242, lw, lh); }
      c.fillStyle = '#64748b'; c.font = '500 22px ' + F; c.fillText(L.foot + ' · invoiceo.in', 540, 1315);
      return cv;
    }
    function showInvoice() {
      panel.innerHTML = '<p>…</p>';
      var logo = new Image(), fired = false;
      function build() {
        if (fired) return; fired = true;
        var fonts = document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve();
        fonts.then(function () {
          var cv = drawInvoice(logo.naturalWidth ? logo : null), url = cv.toDataURL('image/png');
          panel.innerHTML = '<button type="button" class="dw-p-x" aria-label="' + L.x + '">&times;</button>' +
            '<h3>' + L.ready + '</h3><img class="dw-prev" alt="' + L.alt + '" src="' + url + '">' +
            '<div class="dw-row"><button type="button" class="dw-go dw-save">' + L.save + '</button>' +
            (navigator.canShare ? '<button type="button" class="dw-go dw-ghost dw-shr">' + L.shr + '</button>' : '') + '</div>' +
            '<button type="button" class="dw-again">' + L.again + '</button>';
          panel.querySelector('.dw-p-x').onclick = function () { panel.hidden = true; };
          panel.querySelector('.dw-again').onclick = showAsk;
          panel.querySelector('.dw-save').onclick = function () { var a = document.createElement('a'); a.href = url; a.download = 'invoiceo-diwali-invoice.png'; document.body.appendChild(a); a.click(); a.remove(); };
          var sh = panel.querySelector('.dw-shr');
          if (sh) sh.onclick = function () {
            cv.toBlob(function (b) {
              var f = new File([b], 'invoiceo-diwali-invoice.png', { type: 'image/png' });
              if (navigator.canShare({ files: [f] })) navigator.share({ files: [f], text: L.share }).catch(function () {});
            });
          };
          if (fx) { fx(innerWidth * 0.2, innerHeight * 0.3); fx(innerWidth * 0.8, innerHeight * 0.25); }
        });
      }
      logo.onload = build; logo.onerror = build; logo.src = 'assets/images/logo.png';
    }
    btn.onclick = function () { if (panel.hidden) { showAsk(); panel.hidden = false; } else panel.hidden = true; };
    openWish = function () { showAsk(); panel.hidden = false; };
  }

  var bnr = document.querySelector('.dw-banner');
  if (bnr) { bnr.querySelector('.dw-x').insertAdjacentHTML('beforebegin', sndHtml()); bindSnd(bnr); }
})();
