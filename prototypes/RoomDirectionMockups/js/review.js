/* Review site logic: the gallery (index.html), one screen at a time (review.html) and the notes
   summary (summary.html). Everything is generated from js/registry.js (window.MockRegistry).

   Notes are stored with here.now Site Data in the "notes" collection (manifest: site-data.json, deployed
   as .herenow/data.json). Calls are relative to the page, so the same files work on any host name.
   When Site Data is not there (file://, a plain local server) the pages say so and keep drafts locally.

   Rules followed here:
   - every piece of submitted text is rendered with textContent, never innerHTML
   - one Idempotency-Key per draft submission, reused on retry, also stored as client_ref
   - drafts live in localStorage per screen + variant + revision and are cleared only after the server
     confirms the save
   - ?simulate=fail-once on review.html makes the next save fail before anything is sent (test hook) */
(function () {
  'use strict';
  var R = window.MockRegistry;
  var DATA_URL = './.herenow/data/notes';
  var PAGE_LIMIT = 100;
  var params = new URLSearchParams(location.search);

  /* ---------------- small helpers ---------------- */
  function el(tag, attrs, children) {
    var n = document.createElement(tag);
    if (attrs) Object.keys(attrs).forEach(function (k) {
      var v = attrs[k];
      if (v === null || v === undefined || v === false) return;
      if (k === 'text') n.textContent = v;
      else if (k === 'class') n.className = v;
      else if (k.slice(0, 2) === 'on') n.addEventListener(k.slice(2), v);
      else n.setAttribute(k, v === true ? '' : v);
    });
    (children || []).forEach(function (c) {
      if (c === null || c === undefined) return;
      n.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
    });
    return n;
  }
  function $(id) { return document.getElementById(id); }
  function clear(n) { while (n.firstChild) n.removeChild(n.firstChild); }

  function store() {
    try { var s = window.localStorage; var t = '__mps_t'; s.setItem(t, '1'); s.removeItem(t); return s; }
    catch (e) { return null; }
  }
  function newKey() {
    try { if (window.crypto && crypto.randomUUID) return crypto.randomUUID(); } catch (e) { /* not a secure context */ }
    var b = new Uint8Array(16);
    if (window.crypto && crypto.getRandomValues) crypto.getRandomValues(b);
    else for (var i = 0; i < 16; i++) b[i] = Math.floor(Math.random() * 256);
    b[6] = (b[6] & 15) | 64; b[8] = (b[8] & 63) | 128;
    var h = Array.prototype.map.call(b, function (x) { return (x + 256).toString(16).slice(1); }).join('');
    return h.slice(0, 8) + '-' + h.slice(8, 12) + '-' + h.slice(12, 16) + '-' + h.slice(16, 20) + '-' + h.slice(20);
  }

  /* ---------------- registry lookups ---------------- */
  var screenById = {}, groupById = {};
  R.screens.forEach(function (s) { screenById[s.id] = s; });
  R.groups.forEach(function (g) { groupById[g.id] = g; });
  var FLAT = R.flat();

  function variantOf(screen, key) {
    if (!screen) return null;
    for (var i = 0; i < screen.variants.length; i++) if (screen.variants[i].key === key) return screen.variants[i];
    return null;
  }
  function sizeOf(variant) { return R.sizes[variant.device] || R.sizes.phone; }
  function screenUrl(screen, variant) { return 'screens/' + screen.file + (variant.query || ''); }
  function reviewUrl(screen, variant) {
    return 'review.html?s=' + encodeURIComponent(screen.id) + '&v=' + encodeURIComponent(variant.key);
  }
  function snapshotUrl(screen, variant) { return 'snapshots/' + screen.id + '--' + variant.key + '.png'; }
  function revLabel(rev, screen) {
    var current = screen ? R.revOf(screen) : R.REVISION;
    if (!rev) return 'Unknown revision';
    return rev === current ? rev : 'Earlier revision (' + rev + ')';
  }
  function plural(n, one, many) { return n + ' ' + (n === 1 ? one : (many || one + 's')); }

  function fmtDate(iso) {
    var d = new Date(iso);
    if (isNaN(d)) return '';
    try {
      return d.toLocaleString(undefined, { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit' });
    } catch (e) { return d.toISOString(); }
  }

  /* ---------------- Site Data client ---------------- */
  function DataError(info) {
    this.status = info.status || 0;
    this.code = info.code || '';
    this.message = info.message || '';
    this.retryAfter = info.retryAfter || 0;
    this.network = !!info.network;
    this.unavailable = !!info.unavailable;
    this.simulated = !!info.simulated;
  }

  function readError(res) {
    var ct = res.headers.get('content-type') || '';
    var header = parseInt(res.headers.get('retry-after') || '', 10);
    if (ct.indexOf('json') === -1) {
      // A plain static server answers with an HTML 404: there is no Site Data behind this page.
      return Promise.resolve(new DataError({ status: res.status, unavailable: res.status === 404 || res.status === 405 || res.status === 501,
        message: 'The notes service answered with ' + res.status + '.', retryAfter: header || 0 }));
    }
    return res.json().then(function (b) {
      b = b || {};
      var code = b.code || (typeof b.error === 'string' ? b.error : '');
      var ra = parseInt(b.retry_after, 10) || header || 0;
      return new DataError({ status: res.status, code: code, retryAfter: ra,
        unavailable: code === 'account_required' || (res.status === 404 && /collection|data/i.test(code + ' ' + (b.message || ''))),
        message: b.message || (typeof b.error === 'string' ? b.error : '') || ('Error ' + res.status) });
    }, function () { return new DataError({ status: res.status, message: 'Error ' + res.status }); });
  }

  function jsonOrUnavailable(res) {
    var ct = res.headers.get('content-type') || '';
    if (!res.ok) return readError(res).then(function (e) { throw e; });
    if (ct.indexOf('json') === -1) throw new DataError({ status: res.status, unavailable: true, message: 'Not a notes service.' });
    return res.json();
  }

  function normalize(r) {
    var d = (r && r.data && typeof r.data === 'object') ? r.data : (r || {});
    return {
      id: r && r.id,
      screen_id: String(d.screen_id || ''),
      variant: String(d.variant || ''),
      revision: String(d.revision || ''),
      liked: typeof d.liked === 'string' ? d.liked : '',
      change: typeof d.change === 'string' ? d.change : '',
      submitted_at: d.submitted_at || (r && r.created_at) || '',
      client_ref: d.client_ref || '',
      edited_at: d.edited_at || ''
    };
  }
  function newestFirst(a, b) { return (Date.parse(b.submitted_at) || 0) - (Date.parse(a.submitted_at) || 0); }

  var Data = {
    previewOnly: location.protocol === 'file:',
    /* Every record, following nextCursor. Resolves to a sorted array; rejects with DataError. */
    listAll: function () {
      if (Data.previewOnly) return Promise.reject(new DataError({ unavailable: true, message: 'Opened from a file.' }));
      var all = [], seen = {}, pages = 0;
      function page(cursor) {
        var url = DATA_URL + '?limit=' + PAGE_LIMIT + (cursor ? '&cursor=' + encodeURIComponent(cursor) : '');
        return fetch(url, { headers: { accept: 'application/json' }, cache: 'no-store' })
          .catch(function () { throw new DataError({ network: true, message: 'Could not reach the notes service.' }); })
          .then(jsonOrUnavailable)
          .then(function (body) {
            if (!body || !Array.isArray(body.records)) throw new DataError({ unavailable: true, message: 'Unexpected answer.' });
            body.records.forEach(function (r) {
              var n = normalize(r);
              var k = n.id || n.client_ref || JSON.stringify(n);
              if (!seen[k]) { seen[k] = 1; all.push(n); }
            });
            pages++;
            if (body.nextCursor && pages < 250) return page(body.nextCursor);
            return all.sort(newestFirst);
          });
      }
      return page(null);
    },
    create: function (fields, key) {
      if (Data.previewOnly) return Promise.reject(new DataError({ unavailable: true, message: 'Opened from a file.' }));
      return fetch(DATA_URL, {
        method: 'POST',
        headers: { 'content-type': 'application/json', accept: 'application/json', 'Idempotency-Key': key },
        body: JSON.stringify(fields)
      })
        .catch(function () { throw new DataError({ network: true, message: 'Could not reach the notes service.' }); })
        .then(jsonOrUnavailable)
        .then(function (body) {
          if (!body || !body.record) throw new DataError({ unavailable: true, message: 'The save was not confirmed.' });
          return normalize(body.record);
        });
    },
    /* Edit or delete one saved note. The notes collection allows this from the page ("publicMutation": "open"). */
    update: function (id, fields) {
      if (Data.previewOnly) return Promise.reject(new DataError({ unavailable: true, message: 'Opened from a file.' }));
      return fetch(DATA_URL + '/' + encodeURIComponent(id), {
        method: 'PATCH',
        headers: { 'content-type': 'application/json', accept: 'application/json' },
        body: JSON.stringify(fields)
      })
        .catch(function () { throw new DataError({ network: true, message: 'Could not reach the notes service.' }); })
        .then(jsonOrUnavailable)
        .then(function (body) { return body && body.record ? normalize(body.record) : null; });
    },
    remove: function (id) {
      if (Data.previewOnly) return Promise.reject(new DataError({ unavailable: true, message: 'Opened from a file.' }));
      return fetch(DATA_URL + '/' + encodeURIComponent(id), { method: 'DELETE', headers: { accept: 'application/json' } })
        .catch(function () { throw new DataError({ network: true, message: 'Could not reach the notes service.' }); })
        .then(function (res) {
          if (res.ok || res.status === 404) return true; // 404: already gone, which is what she asked for
          return readError(res).then(function (e) { throw e; });
        });
    }
  };

  /* Messages for a failed edit or delete. */
  function changeError(e, what) {
    if (!(e instanceof DataError)) return 'The note wasn’t ' + what + '. Please try again.';
    if (e.unavailable || e.status === 403 || e.status === 405) return 'Notes can’t be ' + what + ' here. Please open the shared website link.';
    if (e.network) return 'The note wasn’t ' + what + '. Check your internet connection and try again.';
    if (e.status === 429) return 'Too many changes from this connection just now. Try again in a few minutes.';
    if (e.status === 400 || e.status === 413 || e.status === 422) return 'The change was not accepted: ' + (e.message || 'it may be too long') + '.';
    return 'The note wasn’t ' + what + ' this time. Please try again.';
  }

  function friendlyError(e) {
    if (!(e instanceof DataError)) return 'Your note didn’t save. Please try again.';
    if (e.simulated) return 'Simulated failure for testing. Nothing was sent.';
    if (e.unavailable) return "Saving isn’t available here. Please open the shared website link.";
    if (e.network) return 'Your note didn’t save. Check your internet connection, then tap Try again.';
    if (e.status === 429) {
      var s = e.retryAfter;
      var wait = !s ? 'a little while' : s < 90 ? plural(s, 'second') : plural(Math.ceil(s / 60), 'minute');
      return 'Too many saves from this connection just now. Try again in ' + wait + '.';
    }
    if (e.status === 400 || e.status === 413 || e.status === 422) return 'The note was not accepted: ' + (e.message || 'it may be too long') + '.';
    return 'Your note didn’t save this time. Please tap Try again.';
  }

  /* ---------------- drafts ---------------- */
  var LS = store();
  function draftKey(sid, vkey, rev) { return 'mps-review:draft:' + sid + ':' + vkey + ':' + rev; }
  var Drafts = {
    get: function (k) {
      if (!LS) return null;
      try { return JSON.parse(LS.getItem(k) || 'null'); } catch (e) { return null; }
    },
    set: function (k, d) { if (LS) try { LS.setItem(k, JSON.stringify(d)); } catch (e) { /* full or blocked */ } },
    remove: function (k) { if (LS) try { LS.removeItem(k); } catch (e) { /* ignore */ } }
  };

  /* ---------------- device frame (review page and gallery thumbnails) ---------------- */
  function liveFrame(screen, variant, opts) {
    var sz = sizeOf(variant);
    var f = el('iframe', {
      src: screenUrl(screen, variant),
      title: opts.title || (screen.title + ', ' + variant.label),
      width: sz.w, height: sz.h,
      loading: opts.lazy ? 'lazy' : null,
      tabindex: opts.inert ? '-1' : null,
      'aria-hidden': opts.inert ? 'true' : null
    });
    f.style.width = sz.w + 'px';
    f.style.height = sz.h + 'px';
    return f;
  }

  /* Screens still being written may not exist yet: say so instead of showing the server's 404 page.
     On file:// (no fetch) or any other answer, assume the file is there. */
  function fileMissing(url) {
    if (location.protocol === 'file:' || !window.fetch) return Promise.resolve(false);
    return fetch(url.split('?')[0], { method: 'HEAD', cache: 'no-store' })
      .then(function (r) { return r.status === 404; }, function () { return false; });
  }
  function notBuilt(cls) {
    return el('div', { class: 'not-built ' + (cls || '') }, [el('p', { text: 'This screen is not built yet.' })]);
  }

  /* =============================================================================================
     Gallery (index.html)
     ============================================================================================= */
  function gallery() {
    $('rev').textContent = 'A little preview, just for you';
    $('count').textContent = plural(R.screens.length, 'screen') + ', ' + plural(FLAT.length, 'view') + ' to look at';
    $('start').setAttribute('href', reviewUrl(FLAT[0].screen, FLAT[0].variant));

    var host = $('groups');
    var stages = [];
    R.groups.forEach(function (g) {
      var list = R.screens.filter(function (s) { return s.group === g.id; });
      if (!list.length) return;
      var hid = 'g-' + g.id;
      var grid = el('ul', { class: 'cards', role: 'list' });
      list.forEach(function (s) { grid.appendChild(card(s, stages)); });
      host.appendChild(el('section', { class: 'group', 'aria-labelledby': hid }, [
        el('h2', { id: hid }, [g.title, ' ', el('small', { text: plural(list.length, 'screen') })]),
        el('p', { class: 'blurb', text: g.blurb }),
        grid
      ]));
    });

    function fit() {
      stages.forEach(function (st) {
        var box = st.node.getBoundingClientRect();
        if (!box.width) return;
        var k = Math.min(box.width / st.w, box.height / st.h);
        var f = st.node.querySelector('iframe');
        if (f) {
          f.style.transform = 'scale(' + k + ')';
          f.style.left = Math.round((box.width - st.w * k) / 2) + 'px';
          f.style.top = Math.round((box.height - st.h * k) / 2) + 'px';
        }
      });
    }
    window.addEventListener('resize', fit);
    fit();
    gallery.fit = fit;

    Data.listAll().then(function (notes) {
      var counts = {};
      notes.forEach(function (n) { counts[n.screen_id] = (counts[n.screen_id] || 0) + 1; });
      document.querySelectorAll('[data-count-for]').forEach(function (b) {
        var n = counts[b.getAttribute('data-count-for')] || 0;
        if (!n) return;
        b.textContent = plural(n, 'note');
        b.hidden = false;
      });
      $('total').textContent = notes.length ? plural(notes.length, 'note') + ' so far' : 'Pick any screen below, or start at the beginning.';
    }, function () { /* fail quietly: badges stay hidden */ });
  }

  function card(s, stages) {
    var first = s.variants[0];
    var sz = sizeOf(first);
    var stage = el('a', { class: 'stage', href: reviewUrl(s, first), tabindex: '-1', 'aria-hidden': 'true' });
    stages.push({ node: stage, w: sz.w, h: sz.h });
    if (s.livePreview) {
      stage.appendChild(liveFrame(s, first, { lazy: true, inert: true }));
    } else {
    var img = el('img', { src: snapshotUrl(s, first), alt: '', loading: 'lazy', decoding: 'async' });
    img.addEventListener('error', function () {
      if (!img.parentNode) return;
      fileMissing(screenUrl(s, first)).then(function (missing) {
        stage.replaceChild(missing ? notBuilt() : liveFrame(s, first, { lazy: true, inert: true }), img);
        if (gallery.fit) gallery.fit();
      });
    });
    stage.appendChild(img);
    }

    var devices = [];
    s.variants.forEach(function (v) { var l = sizeOf(v).label; if (devices.indexOf(l) === -1) devices.push(l); });

    var chips = el('ul', { class: 'chips', role: 'list' });
    s.variants.forEach(function (v) {
      chips.appendChild(el('li', null, [el('a', { class: 'chip', href: reviewUrl(s, v), text: v.label })]));
    });
    var variantsBlock = s.variants.length > 1
      ? el('details', { class: 'more' }, [el('summary', { text: 'Other views (optional)' }), chips])
      : null;

    var titleId = 'c-' + s.id;
    return el('li', { class: 'card' }, [
      stage,
      el('div', { class: 'card-body' }, [
        el('div', { class: 'card-head' }, [
          el('h3', { id: titleId }, [el('a', { href: reviewUrl(s, first), text: s.title })]),
          el('span', { class: 'badge', 'data-count-for': s.id, hidden: true })
        ]),
        el('p', { class: 'desc', text: s.desc }),
        el('p', { class: 'devices', hidden: true }, devices.map(function (d) { return el('span', { class: 'device-tag', text: d }); })
          .concat(s.variants.length > 1 ? [el('span', { class: 'device-tag quiet', text: plural(s.variants.length, 'version') })] : [])),
        variantsBlock,
        el('div', { class: 'actions' }, [
          el('a', { class: 'btn', href: reviewUrl(s, first), 'aria-describedby': titleId, text: 'Look & leave a note' })
        ])
      ])
    ]);
  }

  /* =============================================================================================
     One screen at a time (review.html)
     ============================================================================================= */
  function review() {
    var screen = screenById[params.get('s')] || FLAT[0].screen;
    var variant = variantOf(screen, params.get('v')) || screen.variants[0];
    var rev = R.revOf(screen);
    var group = groupById[screen.group];
    var sz = sizeOf(variant);
    var idx = 0;
    for (var i = 0; i < FLAT.length; i++) if (FLAT[i].screen === screen && FLAT[i].variant === variant) { idx = i; break; }
    // Keep the main path short; alternate views remain available in the optional picker.
    var screenIndex = R.screens.indexOf(screen);
    var previousScreen = R.screens[screenIndex - 1], nextScreen = R.screens[screenIndex + 1];
    var prev = previousScreen ? { screen: previousScreen, variant: previousScreen.variants[0] } : null;
    var next = nextScreen ? { screen: nextScreen, variant: nextScreen.variants[0] } : null;
    var failOnce = params.get('simulate') === 'fail-once';

    document.title = screen.title + ' · Lily’s wardrobe app';
    $('group').textContent = group ? group.title : '';
    $('title').textContent = screen.title;
    $('desc').textContent = screen.desc;
    $('rev').textContent = 'Revision ' + rev;
    $('pos').textContent = (idx + 1) + ' of ' + FLAT.length;
    $('device').textContent = sz.label + ' · ' + sz.w + ' × ' + sz.h;
    $('vlabel').textContent = variant.label;
    var full = screenUrl(screen, variant);
    if (next) {
      $('next2').setAttribute('href', reviewUrl(next.screen, next.variant));
      $('next2').textContent = 'Next screen: ' + next.screen.title + (next.screen === screen ? ', ' + next.variant.label : '');
    } else $('next2').hidden = true;

    function navLink(id, item, word) {
      var a = $(id);
      if (!item) { a.removeAttribute('href'); a.setAttribute('aria-disabled', 'true'); return; }
      a.setAttribute('href', reviewUrl(item.screen, item.variant));
      a.setAttribute('aria-label', word + ': ' + item.screen.title + ', ' + item.variant.label);
      a.querySelector('.nav-sub').textContent = item.screen === screen ? item.variant.label : item.screen.title;
    }
    navLink('prev', prev, 'Previous');
    navLink('next', next, 'Next');

    var pills = $('variants');
    screen.variants.forEach(function (v) {
      var on = v === variant;
      pills.appendChild(el('li', null, [el('a', {
        class: 'pill' + (on ? ' on' : ''), href: reviewUrl(screen, v), 'aria-current': on ? 'page' : null, text: v.label
      })]));
    });
    if (screen.variants.length < 2) $('variants-wrap').hidden = true;

    document.addEventListener('keydown', function (e) {
      if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
      if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
      var t = e.target;
      if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return;
      var item = e.key === 'ArrowLeft' ? prev : next;
      if (!item) return;
      e.preventDefault();
      location.href = reviewUrl(item.screen, item.variant);
    });

    /* device frame, scaled to fit the column, never cropped */
    var clip = $('clip'), frame = $('frame');
    var iframe = liveFrame(screen, variant, { title: screen.title + ', ' + variant.label + ' (mockup)' });
    fileMissing(full).then(function (missing) {
      if (missing) clip.appendChild(notBuilt('in-frame'));
      else clip.appendChild(iframe);
    });
    frame.classList.add('dev-' + variant.device);
    function fit() {
      var col = $('stage').getBoundingClientRect().width;
      var pad = parseFloat(getComputedStyle(frame).paddingLeft) * 2 || 0;
      var k = Math.min(1, (col - pad) / sz.w);
      if (window.innerWidth >= 900) k = Math.min(k, Math.max(0.55, (window.innerHeight - 80) / sz.h));
      k = Math.max(0.2, k);
      clip.style.width = Math.floor(sz.w * k) + 'px';
      clip.style.height = Math.floor(sz.h * k) + 'px';
      iframe.style.transform = 'scale(' + k + ')';
      $('scale').textContent = k < 0.995 ? 'Shown at ' + Math.round(k * 100) + '%' : 'Shown at full size';
    }
    window.addEventListener('resize', fit);
    fit();

    /* ---------- notes form ---------- */
    var form = $('notes-form'), liked = $('liked'), change = $('change'), save = $('save');
    var status = $('status'), errBox = $('error'), errText = $('error-text'), retry = $('retry'), saved = $('saved');
    var dkey = draftKey(screen.id, variant.key, rev);
    var draft = Drafts.get(dkey) || {};
    if (draft.liked) liked.value = draft.liked;
    if (draft.change) change.value = draft.change;
    if (!LS) $('draft-note').textContent = 'This browser is not keeping drafts, so save before leaving the page.';
    else if (draft.liked || draft.change) $('draft-note').textContent = 'The words you started writing are still here.';

    var busy = false, mode = Data.previewOnly ? 'preview' : 'checking';

    function body() { return JSON.stringify([liked.value.trim(), change.value.trim()]); }
    function persist() {
      var d = Drafts.get(dkey) || {};
      d.liked = liked.value; d.change = change.value; d.at = new Date().toISOString();
      if (!liked.value && !change.value && !d.ikey) Drafts.remove(dkey); else Drafts.set(dkey, d);
    }
    function onType() {
      persist();
      saved.hidden = true;
      if (status.dataset.kind === 'empty') setStatus('', '');
    }
    liked.addEventListener('input', onType);
    change.addEventListener('input', onType);

    function setStatus(kind, msg) { status.dataset.kind = kind; status.textContent = msg; }
    function setPreview() {
      mode = 'preview';
      $('preview').hidden = false;
      save.disabled = true;
      save.setAttribute('aria-describedby', 'preview');
    }
    function showError(msg) {
      errText.textContent = msg + ' Your text is still here.';
      errBox.hidden = false;
    }

    function submit() {
      if (busy) return;
      saved.hidden = true;
      errBox.hidden = true;
      setStatus('', '');
      var l = liked.value.trim(), c = change.value.trim();
      if (!l && !c) {
        setStatus('empty', 'Write something in one of the boxes first. Either one is enough.');
        liked.focus();
        return;
      }
      if (mode === 'preview') { setPreview(); return; }
      // One key per draft submission: reuse it when retrying the same text, new one if she edited it.
      var d = Drafts.get(dkey) || {};
      if (!d.ikey || d.ikeyFor !== body()) { d.ikey = newKey(); d.ikeyFor = body(); d.submittedAt = null; }
      d.liked = liked.value; d.change = change.value;
      Drafts.set(dkey, d);
      var key = d.ikey;
      var fields = { screen_id: screen.id, variant: variant.key, revision: rev, submitted_at: d.submittedAt || new Date().toISOString(), client_ref: key };
      if (!d.submittedAt) { d.submittedAt = fields.submitted_at; Drafts.set(dkey, d); }
      if (l) fields.liked = l;
      if (c) fields.change = c;

      busy = true;
      save.disabled = true;
      retry.disabled = true;
      save.textContent = 'Saving…';
      form.setAttribute('aria-busy', 'true');

      var p = failOnce
        ? Promise.reject(new DataError({ network: true, simulated: true }))
        : Data.create(fields, key);
      failOnce = false;
      p.then(function (rec) {
        Drafts.remove(dkey);
        liked.value = ''; change.value = '';
        $('draft-note').textContent = '';
        saved.hidden = false;
        notes.unshift(rec);
        drawNotes();
        refreshNotes();
      }, function (e) {
        if (e instanceof DataError && e.unavailable) { setPreview(); return; }
        showError(friendlyError(e));
        retry.focus();
      }).then(function () {
        busy = false;
        form.removeAttribute('aria-busy');
        save.textContent = 'Save my notes';
        retry.disabled = false;
        if (mode !== 'preview') save.disabled = false;
      });
    }
    form.addEventListener('submit', function (e) { e.preventDefault(); submit(); });
    retry.addEventListener('click', submit);

    /* ---------- earlier notes for this screen ---------- */
    var notes = [];
    var list = $('notes'), listMsg = $('notes-msg');
    function drawNotes() {
      clear(list);
      var mine = notes.filter(function (n) { return n.screen_id === screen.id; });
      var seen = {};
      mine = mine.filter(function (n) { var k = n.id || n.client_ref; if (k && seen[k]) return false; if (k) seen[k] = 1; return true; });
      $('notes-count').textContent = mine.length ? '(' + mine.length + ')' : '';
      listMsg.textContent = mine.length ? '' : 'Your notes will appear here after you save them.';
      mine.forEach(function (n) {
        list.appendChild(noteItem(n, screen, n.variant === variant.key, { onChange: function (upd) {
          if (upd) return; // edited in place; the card already shows the new words
          notes = notes.filter(function (x) { return x !== n; });
          drawNotes();
          listMsg.textContent = notes.some(function (x) { return x.screen_id === screen.id; }) ? 'Note deleted.' : 'Note deleted. Your notes will appear here after you save them.';
        } }));
      });
    }
    function refreshNotes() {
      return Data.listAll().then(function (all) {
        mode = 'live';
        notes = all;
        drawNotes();
      }, function (e) {
        if (e.unavailable) { setPreview(); listMsg.textContent = 'Earlier notes appear here once the review site is published.'; return; }
        mode = 'live';
        listMsg.textContent = e.status === 429 ? 'Too many requests just now; earlier notes will show after a short wait.' : "Couldn't load earlier notes right now.";
      });
    }
    if (Data.previewOnly) { setPreview(); listMsg.textContent = 'Earlier notes appear here once the review site is published.'; }
    else refreshNotes();
  }

  /* One saved note. opts.link: a node shown under the text. opts.onChange(updatedNote | null): called after
     she edits (with the new note) or deletes it (with null), so the page can redraw its list.
     Edit swaps the text for two boxes in place; Delete asks first, inside the card. */
  function noteItem(n, screen, thisVariant, opts) {
    opts = opts || {};
    var li = el('li', { class: 'note' });

    function view(focusEl) {
      clear(li);
      var v = variantOf(screen, n.variant);
      li.appendChild(el('p', { class: 'note-meta' }, [
        el('span', { class: 'tag' + (thisVariant ? ' on' : ''), text: v ? v.label : n.variant }),
        el('span', { class: 'tag' + (n.revision && n.revision !== R.revOf(screen) ? ' old' : ''), text: revLabel(n.revision, screen) }),
        el('time', { datetime: n.submitted_at, text: fmtDate(n.submitted_at) }),
        n.edited_at ? el('span', { class: 'edited', text: 'Edited ' + fmtDate(n.edited_at) }) : null
      ]));
      if (n.liked) li.appendChild(el('div', { class: 'note-part' }, [el('h4', { text: 'What I like' }), el('p', { class: 'note-text', text: n.liked })]));
      if (n.change) li.appendChild(el('div', { class: 'note-part' }, [el('h4', { text: "What I'd change" }), el('p', { class: 'note-text', text: n.change })]));
      if (opts.link) li.appendChild(opts.link);
      if (!n.id || Data.previewOnly) return;
      var editBtn = el('button', { class: 'note-act', type: 'button', text: 'Edit', 'aria-label': 'Edit this note', onclick: edit });
      var delBtn = el('button', { class: 'note-act del', type: 'button', text: 'Delete', 'aria-label': 'Delete this note', onclick: confirmDelete });
      li.appendChild(el('div', { class: 'note-actions' }, [editBtn, delBtn]));
      if (focusEl === 'edit') editBtn.focus();
      else if (focusEl === 'delete') delBtn.focus();
    }

    function edit() {
      clear(li);
      var uid = 'e' + Math.random().toString(36).slice(2, 8);
      var l = el('textarea', { id: uid + 'l', maxlength: '4000', rows: '3', autocomplete: 'off' });
      var c = el('textarea', { id: uid + 'c', maxlength: '4000', rows: '3', autocomplete: 'off' });
      l.value = n.liked; c.value = n.change;
      var msg = el('p', { class: 'note-msg', role: 'status', 'aria-live': 'polite' });
      var saveBtn = el('button', { class: 'btn', type: 'submit', text: 'Save changes' });
      var form = el('form', { class: 'note-edit', novalidate: true }, [
        el('h4', { class: 'note-edit-h', text: 'Change your note' }),
        el('div', { class: 'field' }, [el('label', { for: uid + 'l', text: 'What I like' }), l]),
        el('div', { class: 'field' }, [el('label', { for: uid + 'c', text: "What I'd change" }), c]),
        msg,
        el('div', { class: 'note-actions' }, [saveBtn, el('button', { class: 'btn ghost', type: 'button', text: 'Cancel', onclick: function () { view('edit'); } })])
      ]);
      form.addEventListener('submit', function (e) {
        e.preventDefault();
        var lv = l.value.trim(), cv = c.value.trim();
        if (!lv && !cv) { msg.textContent = 'Write something in one of the boxes, or use Delete to remove the note.'; l.focus(); return; }
        if (lv === n.liked && cv === n.change) { view('edit'); return; }
        saveBtn.disabled = true; saveBtn.textContent = 'Saving…'; msg.textContent = '';
        var fields = { liked: lv, change: cv, edited_at: new Date().toISOString() };
        Data.update(n.id, fields).then(function (rec) {
          var upd = rec || {};
          n.liked = upd.id ? upd.liked : lv; n.change = upd.id ? upd.change : cv; n.edited_at = upd.edited_at || fields.edited_at;
          view('edit');
          li.appendChild(el('p', { class: 'note-msg ok', role: 'status', text: 'Your note is updated.' }));
          if (opts.onChange) opts.onChange(n);
        }, function (err) {
          msg.textContent = changeError(err, 'saved') + ' Your text is still here.';
          saveBtn.disabled = false; saveBtn.textContent = 'Save changes';
        });
      });
      li.appendChild(form);
      l.focus();
    }

    function confirmDelete() {
      var actions = li.querySelector('.note-actions'), done = li.querySelector('.note-msg.ok');
      if (actions) actions.remove();
      if (done) done.remove();
      var keep = el('button', { class: 'btn ghost', type: 'button', text: 'Keep it' });
      var del = el('button', { class: 'btn danger', type: 'button', text: 'Delete note' });
      var msg = el('p', { class: 'note-msg', role: 'status', 'aria-live': 'polite' });
      var uid = 'd' + Math.random().toString(36).slice(2, 8);
      var box = el('div', { class: 'note-confirm', role: 'alertdialog', 'aria-labelledby': uid + 'q', 'aria-describedby': uid + 'd' }, [
        el('p', { class: 'note-confirm-q', id: uid + 'q', text: 'Delete this note?' }),
        el('p', { id: uid + 'd', text: 'It will be gone for good, and Jose won’t see it anymore. This can’t be undone.' }),
        msg,
        el('div', { class: 'note-actions' }, [del, keep])
      ]);
      keep.addEventListener('click', function () { view('delete'); });
      box.addEventListener('keydown', function (e) { if (e.key === 'Escape') { e.preventDefault(); view('delete'); } });
      del.addEventListener('click', function () {
        del.disabled = true; keep.disabled = true; del.textContent = 'Deleting…'; msg.textContent = '';
        Data.remove(n.id).then(function () {
          if (opts.onChange) opts.onChange(null);
          else li.remove();
        }, function (err) {
          msg.textContent = changeError(err, 'deleted');
          del.disabled = false; keep.disabled = false; del.textContent = 'Delete note';
        });
      });
      li.appendChild(box);
      keep.focus();
    }

    view();
    return li;
  }

  /* =============================================================================================
     Summary (summary.html)
     ============================================================================================= */
  function summary() {
    var all = [];
    var host = $('summary'), msg = $('msg'), filter = $('filter');
    $('rev').textContent = 'Current revision ' + R.REVISION + ' · ' + R.REVISION_DATE;

    function rows() {
      return all.map(function (n) {
        var s = screenById[n.screen_id], v = variantOf(s, n.variant);
        return {
          screen_id: n.screen_id, screen_title: s ? s.title : n.screen_id,
          variant: n.variant, variant_label: v ? v.label : n.variant,
          revision: n.revision, liked: n.liked, change: n.change, submitted_at: n.submitted_at, edited_at: n.edited_at
        };
      });
    }
    function download(name, type, text) {
      var a = el('a', { href: URL.createObjectURL(new Blob([text], { type: type })), download: name });
      document.body.appendChild(a); a.click();
      setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
    }
    var stamp = new Date().toISOString().slice(0, 10);
    $('export-json').addEventListener('click', function () {
      download('mockup-notes-' + stamp + '.json', 'application/json', JSON.stringify(rows(), null, 2));
    });
    $('export-csv').addEventListener('click', function () {
      var cols = ['screen_id', 'screen_title', 'variant', 'variant_label', 'revision', 'liked', 'change', 'submitted_at', 'edited_at'];
      function cell(x) {
        x = x === undefined || x === null ? '' : String(x);
        if (/^[=+\-@\t\r]/.test(x)) x = "'" + x; // keep spreadsheets from treating notes as formulas
        return '"' + x.replace(/"/g, '""') + '"';
      }
      var csv = [cols.join(',')].concat(rows().map(function (r) { return cols.map(function (c) { return cell(r[c]); }).join(','); })).join('\r\n');
      download('mockup-notes-' + stamp + '.csv', 'text/csv;charset=utf-8', '﻿' + csv);
    });
    filter.addEventListener('change', draw);

    function draw() {
      clear(host);
      var want = filter.value;
      var shown = all.filter(function (n) { return !want || n.revision === want; });
      var by = {};
      shown.forEach(function (n) { (by[n.screen_id] = by[n.screen_id] || []).push(n); });
      var withNotes = 0;
      var order = R.screens.slice();
      Object.keys(by).forEach(function (id) { if (!screenById[id]) order.push({ id: id, title: 'Unknown screen (' + id + ')', variants: [], group: '' }); });
      order.forEach(function (s) {
        var list = by[s.id];
        if (!list) return;
        withNotes++;
        var g = groupById[s.group];
        var first = s.variants && s.variants[0];
        var ul = el('ul', { class: 'notes', role: 'list' });
        list.forEach(function (n) {
          var v = variantOf(screenById[s.id], n.variant);
          ul.appendChild(noteItem(n, screenById[s.id] || s, false, {
            link: v ? el('p', { class: 'note-link' }, [el('a', { href: reviewUrl(s, v), text: 'Look at this screen again' })]) : null,
            onChange: function (upd) {
              if (upd) return;
              all = all.filter(function (x) { return x !== n; });
              setExport(all.length > 0);
              draw();
              msg.textContent = all.length ? 'Note deleted.' : 'Note deleted. You have no saved notes now.';
            }
          }));
        });
        host.appendChild(el('section', { class: 'sum-screen', 'aria-labelledby': 'sum-' + s.id }, [
          el('div', { class: 'sum-head' }, [
            el('h2', { id: 'sum-' + s.id }, [first ? el('a', { href: reviewUrl(s, first), text: s.title }) : s.title]),
            el('span', { class: 'badge', text: plural(list.length, 'note') })
          ]),
          g && g.title !== s.title ? el('p', { class: 'blurb', text: g.title }) : null,
          ul
        ]));
      });
      $('counts').textContent = all.length
        ? plural(shown.length, 'note') + ' on ' + plural(withNotes, 'screen') + (want ? ' in ' + want : '') + (shown.length !== all.length ? ' (' + all.length + ' in all)' : '')
        : '';
      if (all.length && !shown.length) msg.textContent = 'No notes for this revision.';
      else if (all.length) msg.textContent = '';
    }

    function setExport(on) { $('export-json').disabled = !on; $('export-csv').disabled = !on; }
    setExport(false);
    msg.textContent = 'Loading notes…';
    Data.listAll().then(function (notes) {
      all = notes;
      var revs = {};
      all.forEach(function (n) { if (n.revision) revs[n.revision] = 1; });
      revs[R.REVISION] = 1;
      Object.keys(revs).sort().reverse().forEach(function (r) {
        filter.appendChild(el('option', { value: r, text: r + (r === R.REVISION ? ' (current)' : '') }));
      });
      setExport(all.length > 0);
      msg.textContent = all.length ? '' : 'No notes yet. When you save a note on a screen, it will appear here.';
      draw();
    }, function (e) {
      if (e.unavailable) msg.textContent = "Notes can't be loaded here (preview mode). They appear once the review site is published.";
      else msg.textContent = e.status === 429 ? 'Too many requests just now. Reload in a minute.' : "Couldn't load the notes right now. Reload to try again.";
    });
  }

  window.Review = { gallery: gallery, review: review, summary: summary, Data: Data, Drafts: Drafts };
})();
