/* avatar.js, attempt a ("faithful"): the illustrated person in the room.
   Contract: STYLE.md, section "js/avatar.js".

   Markup:  <div data-avatar data-view="full|bust|back"
                 data-top data-layer data-bottom data-dress data-shoes
                 data-skin data-hair-style data-hair-color data-eyes
                 data-glasses data-earrings data-lips></div>
   API:     window.Avatar = { OPTIONS, DEFAULTS, DEFAULT_OUTFIT, get, set, reset, onChange, svg, mountAll }

   Drawing: one viewBox unit is one CSS px when the full view is shown 240 px wide.
   Full and back views use viewBox 0 0 240 880 (feet on y = 864, head top near y = 20);
   the bust view uses 0 0 240 260. Every part is a function that returns SVG markup,
   stacked back to front:
     back hair, body and skin, bottom (or dress), shoes, top, layer,
     hands, pocket front (the hands sit in pockets), sleeves,
     neck and head, face, front hair, glasses and earrings.
   Shade and outline tones come from each base colour through darken/lighten, so any
   skin, hair or garment colour gets matching tones. Outlines are never black.
   Plain script, no dependencies, no network. Storage may be missing; everything still renders. */
(function (global) {
  'use strict';

  var KEY = 'mps.avatar.v1';
  var CHANNEL = 'mps.avatar';
  var W = 240;

  /* ------------------------------------------------------------------ options */

  var OPTIONS = {
    skin: [
      { id: 's1', label: 'Porcelain', color: '#FCE7DA' },
      { id: 's2', label: 'Fair',      color: '#F8D9C3' },
      { id: 's3', label: 'Peach',     color: '#F5C9A7' },
      { id: 's4', label: 'Tan',       color: '#DDA67E' },
      { id: 's5', label: 'Brown',     color: '#B57A52' },
      { id: 's6', label: 'Deep',      color: '#7B4E35' }
    ],
    hairStyle: [
      { id: 'wavy-bob',      label: 'Wavy bob' },
      { id: 'long-waves',    label: 'Long waves' },
      { id: 'long-straight', label: 'Long straight' },
      { id: 'high-bun',      label: 'High bun' },
      { id: 'curly',         label: 'Curly' },
      { id: 'ponytail',      label: 'Ponytail' }
    ],
    hairColor: [
      { id: 'black',      label: 'Black',      color: '#2F272B' },
      { id: 'dark-brown', label: 'Dark brown', color: '#4B3327' },
      { id: 'chestnut',   label: 'Chestnut',   color: '#6E4A35' },
      { id: 'auburn',     label: 'Auburn',     color: '#94482D' },
      { id: 'blonde',     label: 'Blonde',     color: '#E2BF80' },
      { id: 'silver',     label: 'Silver',     color: '#CFCBD2' },
      { id: 'rose',       label: 'Rose',       color: '#E3A5B5' }
    ],
    eyes: [
      { id: 'brown', label: 'Brown', color: '#5C3B2A' },
      { id: 'hazel', label: 'Hazel', color: '#8B6A3B' },
      { id: 'green', label: 'Green', color: '#5C8A62' },
      { id: 'blue',  label: 'Blue',  color: '#5B85B6' }
    ],
    glasses: [
      { id: 'none',    label: 'None' },
      { id: 'round',   label: 'Round' },
      { id: 'cat-eye', label: 'Cat eye' }
    ],
    earrings: [
      { id: 'none',  label: 'None' },
      { id: 'hoops', label: 'Gold hoops' },
      { id: 'studs', label: 'Studs' }
    ],
    lips: [
      { id: 'rose',  label: 'Rose',  color: '#DE8E98' },
      { id: 'coral', label: 'Coral', color: '#E8907A' },
      { id: 'berry', label: 'Berry', color: '#B4566C' }
    ]
  };

  var DEFAULTS = {
    skin: 's3', hairStyle: 'wavy-bob', hairColor: 'chestnut', eyes: 'brown',
    glasses: 'none', earrings: 'hoops', lips: 'rose'
  };

  var DEFAULT_OUTFIT = {
    top: 'g-pink-blouse', bottom: 'g-navy-trousers', shoes: 'g-nude-flats', layer: null, dress: null
  };

  /* Worn garments. kind picks the drawing; f is the main colour (same as js/garments.js).
     s, h, l, d override the derived shade, highlight, outline and detail tones. */
  var GARMENTS = {
    'g-pink-blouse':    { cat: 'top',    kind: 'blouse',   f: '#F4B4C2', s: '#EC9DB0', h: '#FBD0D9', l: '#D97F97' },
    'g-cream-sweater':  { cat: 'top',    kind: 'sweater',  f: '#FFF3E0', s: '#F1DEBF', h: '#FFFCF6', l: '#C9A676', d: '#DDBE92' },
    'g-lace-top':       { cat: 'top',    kind: 'lace',     f: '#FFFDF8', s: '#F0E7D6', h: '#FFFFFF', l: '#C6AA80', d: '#D8C3A0' },
    'g-cream-crop':     { cat: 'top',    kind: 'lace',     f: '#F8ECD8', s: '#EEDCC0', h: '#FFF8EC', l: '#C3A37A', d: '#D3B88F' },
    'g-brick-top':      { cat: 'top',    kind: 'knit',     f: '#B5533C', s: '#9E4531', h: '#C76A53', l: '#7D3424', d: '#9A432F' },
    'g-black-tee':      { cat: 'top',    kind: 'tee',      f: '#2E2A30', s: '#242026', h: '#47414B', l: '#17141A', d: '#4E4855' },
    'g-gray-blazer':    { cat: 'layer',  kind: 'blazer',   f: '#A9ABB3', s: '#9799A3', h: '#C0C2C9', l: '#6F727F', d: '#868895' },
    'g-brown-jacket':   { cat: 'layer',  kind: 'blazer',   f: '#7A4B2E', s: '#683F26', h: '#93603F', l: '#4A2C19', d: '#5E3A23' },
    'g-navy-cardigan':  { cat: 'layer',  kind: 'cardigan', f: '#27335F', s: '#1F2950', h: '#36447A', l: '#151C38', d: '#4A5891' },
    'g-camel-trench':   { cat: 'layer',  kind: 'trench',   f: '#C9A06A', s: '#B88D58', h: '#DDB986', l: '#8F6A3C', d: '#A9844F' },
    'g-navy-trousers':  { cat: 'bottom', kind: 'trousers', f: '#27335F', s: '#1F2950', h: '#34427A', l: '#151C38', d: '#46558E' },
    'g-olive-trousers': { cat: 'bottom', kind: 'trousers', f: '#7C8450', s: '#6B7244', h: '#939B64', l: '#4E5430', d: '#5F663B' },
    'g-gray-leggings':  { cat: 'bottom', kind: 'trousers', f: '#8E9098', s: '#7D7F88', h: '#A3A5AC', l: '#5C5E68', d: '#70727B' },
    'g-wide-jeans':     { cat: 'bottom', kind: 'jeans',    f: '#6F93C4', s: '#5F82B4', h: '#8EAEDA', l: '#45679B', d: '#E2A95C' },
    'g-black-skirt':    { cat: 'bottom', kind: 'skirt',    f: '#2E2A30', s: '#242026', h: '#47414B', l: '#17141A', d: '#4E4855' },
    'g-blue-dress':     { cat: 'dress',  kind: 'dress',    f: '#8FB3E3', s: '#7BA0D4', h: '#AFCBEF', l: '#5D82BB', d: '#6E93C9' },
    'g-nude-flats':     { cat: 'shoes',  kind: 'flats',    f: '#F1DCC6', s: '#E5C9AD', h: '#FBF0E4', l: '#BC946C', d: '#C9A37B' },
    'g-white-sneakers': { cat: 'shoes',  kind: 'sneakers', f: '#FAFAFA', s: '#ECE7E6', h: '#FFFFFF', l: '#B9ADAA', d: '#EFE6DC' },
    'g-tan-loafers':    { cat: 'shoes',  kind: 'loafers',  f: '#B98552', s: '#A57240', h: '#D09F6C', l: '#7A5028', d: '#8E5F32' },
    'g-black-heels':    { cat: 'shoes',  kind: 'heels',    f: '#2E2A30', s: '#211E23', h: '#4C4651', l: '#141215', d: '#3A353D' }
  };
  var SLOT_CAT = { top: 'top', layer: 'layer', bottom: 'bottom', dress: 'dress', shoes: 'shoes' };

  /* ------------------------------------------------------------------ colour helpers */

  function clamp(v, a, b) { return v < a ? a : (v > b ? b : v); }
  function hexRgb(h) {
    h = String(h || '').replace('#', '');
    if (h.length === 3) h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2);
    var n = parseInt(h, 16);
    if (h.length !== 6 || isNaN(n)) n = 0x999999;
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function rgbHex(r, g, b) {
    return '#' + [r, g, b].map(function (v) {
      var s = Math.round(clamp(v, 0, 255)).toString(16);
      return s.length < 2 ? '0' + s : s;
    }).join('').toUpperCase();
  }
  function rgbHsl(c) {
    var r = c[0] / 255, g = c[1] / 255, b = c[2] / 255;
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, h = 0, s = 0;
    if (mx !== mn) {
      var d = mx - mn;
      s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
      if (mx === r) h = (g - b) / d + (g < b ? 6 : 0);
      else if (mx === g) h = (b - r) / d + 2;
      else h = (r - g) / d + 4;
      h *= 60;
    }
    return [h, s, l];
  }
  function hslHex(h, s, l) {
    h = ((h % 360) + 360) % 360; s = clamp(s, 0, 1); l = clamp(l, 0, 1);
    var c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2, r, g, b;
    if (h < 60) { r = c; g = x; b = 0; } else if (h < 120) { r = x; g = c; b = 0; }
    else if (h < 180) { r = 0; g = c; b = x; } else if (h < 240) { r = 0; g = x; b = c; }
    else if (h < 300) { r = x; g = 0; b = c; } else { r = c; g = 0; b = x; }
    return rgbHex((r + m) * 255, (g + m) * 255, (b + m) * 255);
  }
  // Darker tone of the same hue. Light colours also lose some saturation so shades stay soft.
  function darken(hex, amt, warm) {
    var c = rgbHsl(hexRgb(hex));
    return hslHex(c[0] - (warm || 0), c[1] * (1 - amt * (c[2] > 0.6 ? 1.05 : 0.3)), c[2] * (1 - amt));
  }
  function lighten(hex, amt) {
    var c = rgbHsl(hexRgb(hex));
    return hslHex(c[0], c[1], c[2] + (1 - c[2]) * amt);
  }
  function mix(a, b, t) {
    var x = hexRgb(a), y = hexRgb(b);
    return rgbHex(x[0] + (y[0] - x[0]) * t, x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t);
  }
  function lum(hex) { return rgbHsl(hexRgb(hex))[2]; }

  function skinPal(hex) {
    var L = lum(hex);
    return {
      f: hex,
      s: darken(hex, 0.08, 2),
      d: darken(hex, 0.17, 4),
      l: darken(hex, L > 0.5 ? 0.3 : 0.36, 5),
      h: lighten(hex, 0.35),
      blush: L > 0.6 ? '#F28A90' : mix('#D65F6C', hex, 0.2),
      blushOp: L > 0.6 ? 0.34 : 0.42
    };
  }
  function hairPal(hex) {
    var L = lum(hex), light = L > 0.55;
    return {
      f: hex,
      s: darken(hex, light ? 0.15 : 0.24),
      l: darken(hex, light ? 0.34 : 0.4),
      h: lighten(hex, light ? 0.42 : (L < 0.22 ? 0.13 : 0.2)),
      brow: darken(hex, light ? 0.42 : 0.28),
      lash: mix(darken(hex, 0.55), '#2B1A16', light ? 0.6 : 0.75)
    };
  }
  function gPal(g) {
    var L = lum(g.f);
    return {
      f: g.f,
      s: g.s || darken(g.f, 0.1),
      h: g.h || lighten(g.f, 0.25),
      l: g.l || darken(g.f, 0.35),
      d: g.d || (L < 0.3 ? lighten(g.f, 0.2) : darken(g.f, 0.22))
    };
  }

  /* ------------------------------------------------------------------ path helpers */

  function r2(v) { return Math.round(v * 100) / 100; }
  function mx(x) { return r2(W - x); }
  function pt(x, y) { return r2(x) + ' ' + r2(y); }

  // Mirror an absolute path (M L C S Q T H V Z) across the vertical centre line.
  function mir(d) {
    var tok = String(d).match(/[A-Za-z]|-?\d*\.?\d+(?:e[-+]?\d+)?/g) || [];
    var out = [], cmd = '', n = 0;
    for (var i = 0; i < tok.length; i++) {
      var t = tok[i];
      if (/[A-Za-z]/.test(t)) { cmd = t.toUpperCase(); out.push(cmd); n = 0; continue; }
      var v = parseFloat(t);
      if (cmd === 'H') v = mx(v);
      else if (cmd !== 'V' && n % 2 === 0) v = mx(v);
      out.push(v); n++;
    }
    return out.join(' ');
  }

  // Closed symmetric path from its left half. a[0] is the start point; each later item is
  // [x,y] (line), [qx,qy,x,y] (quadratic) or [c1x,c1y,c2x,c2y,x,y] (cubic).
  function sym(a) {
    var d = 'M ' + pt(a[0][0], a[0][1]), ends = [a[0]], i;
    for (i = 1; i < a.length; i++) {
      var s = a[i];
      if (s.length === 2) d += ' L ' + pt(s[0], s[1]);
      else if (s.length === 4) d += ' Q ' + pt(s[0], s[1]) + ' ' + pt(s[2], s[3]);
      else d += ' C ' + pt(s[0], s[1]) + ' ' + pt(s[2], s[3]) + ' ' + pt(s[4], s[5]);
      ends.push([s[s.length - 2], s[s.length - 1]]);
    }
    var last = ends[ends.length - 1];
    d += ' L ' + pt(mx(last[0]), last[1]);
    for (i = a.length - 1; i >= 1; i--) {
      var g = a[i], p0 = ends[i - 1];
      if (g.length === 2) d += ' L ' + pt(mx(p0[0]), p0[1]);
      else if (g.length === 4) d += ' Q ' + pt(mx(g[0]), g[1]) + ' ' + pt(mx(p0[0]), p0[1]);
      else d += ' C ' + pt(mx(g[2]), g[3]) + ' ' + pt(mx(g[0]), g[1]) + ' ' + pt(mx(p0[0]), p0[1]);
    }
    return d + ' Z';
  }

  function P(d, fill, stroke, sw, extra) {
    return '<path d="' + d + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 2) + '" stroke-linejoin="round" stroke-linecap="round"' : '') +
      (extra ? ' ' + extra : '') + '/>';
  }
  function PM(d, fill, stroke, sw, extra) { return P(d, fill, stroke, sw, extra) + P(mir(d), fill, stroke, sw, extra); }
  function CIR(cx, cy, r, fill, stroke, sw, extra) {
    return '<circle cx="' + r2(cx) + '" cy="' + r2(cy) + '" r="' + r + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 1.5) + '"' : '') + (extra ? ' ' + extra : '') + '/>';
  }
  function CM(cx, cy, r, fill, stroke, sw, extra) { return CIR(cx, cy, r, fill, stroke, sw, extra) + CIR(mx(cx), cy, r, fill, stroke, sw, extra); }
  function ELL(cx, cy, rx, ry, fill, extra) {
    return '<ellipse cx="' + r2(cx) + '" cy="' + r2(cy) + '" rx="' + rx + '" ry="' + ry + '" fill="' + fill + '"' + (extra ? ' ' + extra : '') + '/>';
  }
  function op(v) { return 'opacity="' + v + '"'; }
  function each(list, fn) { var s = ''; for (var i = 0; i < list.length; i++) s += fn(list[i], i); return s; }

  /* ------------------------------------------------------------------ body geometry (left side; right is mirrored) */

  var CHEST = 'M 105 136 C 106 152, 106 166, 105 178 C 103 186, 96 190, 84 193 C 70 196, 56 200, 48 206 L 50 262 L 190 262 L 192 206 C 184 200, 170 196, 156 193 C 144 190, 137 186, 135 178 C 134 166, 134 152, 135 136 Z';
  var ARM = 'M 50 202 C 39 206, 32 219, 31 236 C 30 256, 28.5 274, 28.5 290 C 28.5 310, 31.5 332, 34.5 350 L 50.5 350 C 51.5 334, 54 312, 55 292 C 56 276, 58 262, 60 248 L 58 214 Z';
  var HAND = 'M 34 344 C 33 358, 33.4 372, 35.4 384 C 37 393, 42 400, 48.6 400.6 C 54 401, 56.6 395, 56.2 385 C 55.8 373, 53.4 357, 51.6 344 Z';
  var HAND_EDGE = 'M 34 344 C 33 358, 33.4 372, 35.4 384 C 37 393, 42 400, 48.6 400.6 C 54 401, 56.6 395, 56.2 385 C 55.8 373, 53.4 357, 51.6 344';
  var LEG = 'M 44 398 C 49 470, 56 560, 60 625 C 61.5 648, 55 670, 55.6 700 C 56.6 752, 61.6 800, 62.5 840 L 76.8 840 C 77 800, 80 760, 83 722 C 87 692, 88 660, 82.5 630 C 86 590, 100 520, 120 438 L 120 398 Z';
  var FACE = 'M 120 44 C 148 44, 168 62, 169 95 C 170 117, 161 135, 147 147 C 138 154, 129 158, 120 158 C 111 158, 102 154, 93 147 C 79 135, 70 117, 71 95 C 72 62, 92 44, 120 44 Z';
  var EAR = 'M 76 100 C 69 94.5, 61.5 100, 62 110 C 62.5 119.5, 67.5 126.5, 75.5 126 Z';
  var EAR_IN = 'M 71.5 104 C 67 104.5, 65.5 110, 67.5 116 C 68.5 118.5, 70.5 119.5, 71.5 118';

  // Pocket geometry shared by every bottom, the dress and the trench: the slant opening
  // runs from (70,341) to (37,404); the part below it covers the hand.
  var POCKET_FILL = 'M 57.4 366.2 L 35.4 410 C 35.1 414.6, 34.9 419.4, 34.7 424 L 57.4 424 Z';
  var POCKET_SLANT = 'M 57.4 366.2 L 35.4 410';
  var POCKET_HIP = 'M 35.4 410 C 35.1 414.6, 34.9 419.4, 34.7 424';

  /* ------------------------------------------------------------------ context */

  function findOpt(list, id) {
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }
  function makeCtx(a, uid) {
    return {
      uid: uid,
      a: a,
      defs: [],
      skin: skinPal(findOpt(OPTIONS.skin, a.skin).color),
      hair: hairPal(findOpt(OPTIONS.hairColor, a.hairColor).color),
      eye: findOpt(OPTIONS.eyes, a.eyes).color,
      lip: findOpt(OPTIONS.lips, a.lips).color
    };
  }

  /* ------------------------------------------------------------------ body and skin */

  function bodySkin(c, withLegs) {
    var k = c.skin, o = '';
    if (withLegs) {
      o += PM(LEG, k.f, k.l, 2);
      o += PM('M 66 631 Q 71 634.5 76 632', null, k.d, 1.2);
      o += PM('M 63 760 C 63.5 780, 64.5 800, 65 820', null, k.s, 3, op(0.7));
    }
    o += PM(ARM, k.f, k.l, 2);
    o += PM('M 44 289 Q 48 292.5 52 291', null, k.d, 1.2);
    o += P(CHEST, k.f, k.l, 2);
    o += PM('M 101 199.5 C 96 202, 90 202.4, 85 201.4', null, k.d, 1.2, op(0.7));
    return o;
  }

  function handsSkin(c) {
    var k = c.skin;
    return PM(HAND, k.f, null) + PM(HAND_EDGE, null, k.l, 2) +
      PM('M 47.8 358 C 50.8 361.4, 52.4 365.4, 52 370', null, k.d, 1.2) +
      PM('M 36 352 C 40 353.5, 46 353.5, 50.6 352', null, k.s, 1.6, op(0.8));
  }

  function headSkin(c) {
    var k = c.skin, o = '';
    o += P('M 105 142 C 112 155, 128 155, 135 142 L 135.4 164 C 128 170, 112 170, 104.6 164 Z', mix(k.f, k.l, 0.28), null);
    o += PM(EAR, k.f, k.l, 1.8) + PM(EAR_IN, null, k.l, 1.2, op(0.65));
    o += P(FACE, k.f, k.l, 2);
    return o;
  }

  function faceFeatures(c) {
    var k = c.skin, hp = c.hair, o = '';
    var irisRing = darken(c.eye, 0.32), pupil = mix(darken(c.eye, 0.6), '#1D130F', 0.55);
    // blush
    o += ELL(90, 118, 10.5, 6.2, k.blush, op(k.blushOp)) + ELL(150, 118, 10.5, 6.2, k.blush, op(k.blushOp));
    // brows: soft tapered arches in the hair tone
    o += PM('M 110.6 85.4 C 106.5 81.2, 99 79.4, 92.4 80.9 C 89.4 81.6, 87.2 83.4, 85.8 86 C 88.6 84.6, 91.8 83.8, 95.4 83.6 C 100.6 83.4, 105.8 84.4, 110.6 85.4 Z', hp.brow, hp.brow, 0.8);
    // eyes
    var EYE = 'M 89 99.6 C 90 94, 95 91.4, 100.2 91.4 C 105.4 91.4, 109.4 94.6, 110.8 98.6 C 108.8 103.6, 104.4 105.8, 99.8 105.8 C 94.6 105.8, 90.6 103.6, 89 99.6 Z';
    var LID = 'M 87.6 100 C 89.4 93.8, 94.8 90.6, 100.2 90.6 C 105.8 90.6, 110 93.8, 111.8 98.6';
    var FLICK = 'M 89.8 96.6 C 88 95.6, 86.4 94.4, 85.2 92.6 C 86.8 93.4, 88.6 94, 90.6 94.6 Z';
    [0, 1].forEach(function (side) {
      var id = c.uid + '-eye' + side, ex = side ? 139.5 : 100.5;
      var d = side ? mir(EYE) : EYE;
      c.defs.push('<clipPath id="' + id + '"><path d="' + d + '"/></clipPath>');
      o += P(d, '#FFFFFF', null);
      o += '<g clip-path="url(#' + id + ')">' +
        CIR(ex, 98.6, 6.6, c.eye, irisRing, 1.2) +
        CIR(ex, 99, 3.3, pupil) +
        P(side ? mir('M 95 103.6 C 98 105.2, 103 105.2, 106 103.6') : 'M 95 103.6 C 98 105.2, 103 105.2, 106 103.6', null, lighten(c.eye, 0.35), 1.4, op(0.6)) +
        CIR(ex + 2.3, 96, 2, '#FFFFFF') + CIR(ex - 2.4, 101.6, 0.9, '#FFFFFF', null, 0, op(0.85)) +
        '</g>';
      o += P(side ? mir(LID) : LID, null, hp.lash, 2.5);
      o += P(side ? mir(FLICK) : FLICK, hp.lash, hp.lash, 0.8);
      o += P(side ? mir('M 92.4 104.8 Q 100 107.8 107.4 104.6') : 'M 92.4 104.8 Q 100 107.8 107.4 104.6', null, k.l, 1, op(0.45));
      o += P(side ? mir('M 91 91.4 Q 100 86.8 108.8 91') : 'M 91 91.4 Q 100 86.8 108.8 91', null, k.l, 1, op(0.4));
    });
    // nose: a tiny soft hook
    o += P('M 117.8 116.4 C 117.2 119, 118.6 120.6, 120.8 120.6 C 122.2 120.6, 123.3 119.9, 123.7 118.9', null, k.l, 1.5, op(0.75));
    // mouth: gentle closed smile
    var lipDark = darken(c.lip, 0.14), lipLine = darken(c.lip, 0.38);
    o += P('M 109.6 131.2 C 113.6 133.6, 126.4 133.6, 130.4 131.2 C 128.6 136.4, 124.4 138.8, 120 138.8 C 115.6 138.8, 111.4 136.4, 109.6 131.2 Z', c.lip, null);
    o += P('M 110.4 130.6 C 113.6 129.6, 116.6 129.2, 118.6 129.8 C 119.3 130, 119.7 130.2, 120 130.2 C 120.3 130.2, 120.7 130, 121.4 129.8 C 123.4 129.2, 126.4 129.6, 129.6 130.6 C 126 132.6, 114 132.6, 110.4 130.6 Z', lipDark, null);
    o += P('M 107.4 129.2 C 110.6 132, 114.6 133.2, 120 133.2 C 125.4 133.2, 129.4 132, 132.6 129.2', null, lipLine, 1.5);
    o += P('M 116 136 Q 120 137.2 124 136', null, '#FFFFFF', 1.2, op(0.4));
    o += PM('M 106.6 128.2 Q 106.9 129.4 107.9 130.2', null, lipLine, 1.1, op(0.7));
    return o;
  }

  /* ------------------------------------------------------------------ hair */

  function lock(d, hp) { return P(d, hp.f, hp.l, 1.8); }
  function browShade(c) {
    var t = c.skin.s;
    return P('M 116 48 C 128 49, 146 55, 156 67 C 162 75, 164.6 86, 164 98 L 159.6 98 C 159.6 88, 156.6 79.6, 151.6 73.6 C 142.6 63.6, 129 57, 116 55.6 Z', t, null) +
      P('M 115 33 C 110 42, 104 49, 98 56 C 86 68, 78.5 84, 76.5 97 L 80.6 98 C 82.6 86, 89.4 72.6, 100.4 61.4 C 106.4 55.4, 111.4 48.4, 116.4 40.4 Z', t, null);
  }
  function strands(list, hp, w) { return each(list, function (d) { return P(d, null, hp.l, w || 1.25, op(0.75)); }); }
  function shines(list, hp, w) { return each(list, function (d) { return P(d, null, hp.h, w || 2.4, op(0.9)); }); }
  function shades(list, hp) { return each(list, function (d) { return P(d, hp.s, null); }); }

  // Shared crown for the side-parted styles (wavy bob, long waves): the part sits left of centre,
  // the larger mass sweeps across the forehead to the right.
  var BOB_L = 'M 113 21 C 100 20.5, 80 26, 66 40 C 54 52, 47 68, 46 86 C 45 98, 41 106, 38 116 C 35 126, 37 134, 36 142 C 35 152, 29 160, 28 170 C 27 178, 30 186, 37 189 C 43 192, 50 191, 53 186 C 55 183, 55 179, 53 176 C 58 182, 64 190, 72 190 C 79 190, 83 186, 83 181 C 86 186, 91 189, 96 187 C 93 180, 88 172, 84 162 C 80 152, 73 140, 67 128 C 63 122, 61 114, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74.5 96, 76.5 97 C 78.5 84, 86 68, 98 56 C 104 49, 110 42, 115 33 Z';
  var BOB_R = 'M 101 21.3 C 105 21, 109.6 20.8, 113 20.9 C 128 20.4, 158 24, 175 40 C 187 52, 193 70, 194 88 C 195 100, 199 108, 202 118 C 205 128, 203 136, 204 144 C 205 154, 211 162, 212 172 C 213 180, 210 187, 203 190 C 197 193, 190 191, 187 186 C 185 183, 185 179, 187 176 C 182 182, 176 190, 168 190 C 161 190, 157 186, 157 181 C 154 186, 149 189, 144 187 C 147 180, 152 172, 156 162 C 160 152, 167 140, 173 128 C 177 122, 179 114, 179 106 C 178.5 100, 175.5 96.5, 171 95.8 C 168 95.4, 165.5 96, 163.5 97 C 164 86, 162 76, 156 68 C 146 56, 128 50, 116 49 C 113.6 44, 113 34, 113.4 29 C 112.8 25.6, 108 22.2, 101 21.3 Z';

  var LW_L = 'M 113 21 C 100 20.5, 80 26, 66 40 C 54 52, 47 68, 46 86 C 44 100, 40 108, 38 118 C 35 130, 39 140, 36 152 C 33 164, 28 174, 31 188 C 34 202, 40 210, 37 224 C 34 238, 30 248, 33 262 C 36 276, 42 284, 40 296 C 39 304, 44 311, 52 309 C 58 308, 60 302, 58 296 C 62 304, 70 310, 78 307 C 84 305, 86 300, 84 294 C 88 298, 93 298, 96 294 C 92 284, 88 272, 89 258 C 90 242, 94 230, 92 216 C 90 202, 86 190, 82 176 C 78 160, 72 142, 67 128 C 63 122, 61 114, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74.5 96, 76.5 97 C 78.5 84, 86 68, 98 56 C 104 49, 110 42, 115 33 Z';
  var LW_R = 'M 101 21.3 C 105 21, 109.6 20.8, 113 20.9 C 128 20.4, 158 24, 175 40 C 187 52, 193 70, 194 88 C 196 102, 200 110, 202 120 C 205 132, 201 142, 204 154 C 207 164, 212 174, 209 188 C 206 202, 200 210, 203 224 C 206 238, 210 248, 207 262 C 204 276, 198 284, 200 296 C 201 304, 196 311, 188 309 C 182 308, 180 302, 182 296 C 178 304, 170 310, 162 307 C 156 305, 154 300, 156 294 C 152 298, 147 298, 144 294 C 148 284, 152 272, 151 258 C 150 242, 146 230, 148 216 C 150 202, 154 190, 158 176 C 162 160, 168 142, 173 128 C 177 122, 179 114, 179 106 C 178.5 100, 175.5 96.5, 171 95.8 C 168 95.4, 165.5 96, 163.5 97 C 164 86, 162 76, 156 68 C 146 56, 128 50, 116 49 C 113.6 44, 113 34, 113.4 29 C 112.8 25.6, 108 22.2, 101 21.3 Z';

  var LS_L = 'M 120 22 C 98 21, 76 29, 63 44 C 51 58, 46 76, 45 98 C 44 124, 43 156, 42 190 C 41 230, 40 270, 40 302 C 40 307, 43 310, 48 310 L 88 310 C 92 310, 94 307, 93.5 303 C 92 272, 90 236, 88 206 C 86 184, 78 160, 70 140 C 64 126, 61 116, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74.5 96, 76.5 97 C 81 78, 94 56, 110 45 C 115 41, 118.5 36, 120 30 Z';

  var CAP_REAR = 'M 120 27 C 150 27, 172 48, 174 82 C 175 108, 167 132, 154 146 C 144 154, 132 151, 120 156 C 108 151, 96 154, 86 146 C 73 132, 65 108, 66 82 C 68 48, 90 27, 120 27 Z';

  var CURLY_BACK = 'M 120 16 C 130 10, 146 12, 152 20 C 162 16, 176 22, 178 34 C 190 34, 198 46, 196 58 C 206 64, 208 78, 202 88 C 210 96, 210 110, 204 118 C 212 126, 212 142, 204 148 C 210 158, 208 172, 198 176 C 200 188, 190 198, 178 194 C 172 202, 158 202, 152 194 L 88 194 C 82 202, 68 202, 62 194 C 50 198, 40 188, 42 176 C 32 172, 30 158, 36 148 C 28 142, 28 126, 36 118 C 30 110, 30 96, 38 88 C 32 78, 34 64, 44 58 C 42 46, 50 34, 62 34 C 64 22, 78 16, 88 20 C 94 12, 110 10, 120 16 Z';
  var CURLY_L = 'M 114 30 C 106 20, 88 18, 80 27 C 70 23, 56 31, 56 43 C 44 45, 38 57, 42 69 C 32 75, 32 89, 40 95 C 32 103, 32 117, 40 123 C 32 131, 32 145, 40 151 C 32 159, 34 173, 44 177 C 42 187, 52 195, 62 191 C 66 199, 80 199, 84 191 C 90 197, 98 195, 98 187 C 92 183, 88 175, 86 167 C 82 155, 76 143, 70 133 C 63 123, 61 114, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74 95.6, 76 96 C 73 88, 77 79, 84 77 C 82 69, 88 61, 96 61 C 98 53, 106 49, 113 51 Z';
  var CURLY_R = 'M 114 30 C 122 20, 140 18, 150 27 C 160 22, 175 29, 176 41 C 188 42, 196 53, 194 65 C 204 71, 206 85, 200 93 C 208 101, 208 115, 200 121 C 208 129, 208 143, 200 149 C 208 157, 206 172, 196 176 C 198 188, 188 196, 178 192 C 174 200, 160 200, 156 192 C 150 198, 142 196, 142 188 C 148 184, 152 176, 154 168 C 158 156, 164 144, 170 134 C 177 124, 179 114, 179 106 C 178.5 100, 175.5 96.5, 171 95.8 C 168 95.4, 166 95.6, 164 96 C 167 87, 163 78, 156 76 C 158 68, 152 60, 144 60 C 142 52, 134 47, 126 50 C 122 44, 112 44, 109 51 C 109 43, 111 35, 114 30 Z';

  function curlMarks(list, hp) {
    // each item: [x, y, s] small C-shaped curl
    return each(list, function (q) {
      var x = q[0], y = q[1], s = q[2] || 1;
      return P('M ' + pt(x + 4 * s, y - 3 * s) + ' C ' + pt(x, y - 5 * s) + ' ' + pt(x - 5 * s, y - 1 * s) + ' ' + pt(x - 3 * s, y + 3 * s) +
        ' C ' + pt(x - 1 * s, y + 6 * s) + ' ' + pt(x + 4 * s, y + 5 * s) + ' ' + pt(x + 4 * s, y + 1 * s), null, hp.l, 1.2, op(0.75));
    });
  }

  var HAIR = {
    'wavy-bob': {
      back: function (c) {
        var hp = c.hair;
        return P('M 113 22 C 150 21, 180 33, 190 58 C 198 80, 197 104, 200 124 C 203 144, 208 162, 207 176 C 205 186, 196 189, 186 188 L 54 188 C 44 189, 35 186, 33 176 C 32 162, 37 144, 40 124 C 43 104, 42 80, 50 58 C 60 33, 80 22, 113 22 Z', hp.s, hp.l, 1.8);
      },
      front: function (c) {
        var hp = c.hair, o = browShade(c);
        o += lock(BOB_L, hp);
        o += shades([
          'M 67 128 C 73 140, 80 152, 84 162 C 88 172, 93 180, 96 187 C 91 184, 86 176, 82 167 C 77 156, 71 144, 67 128 Z',
          'M 29 178 C 31 186, 38 190.6, 46 190.6 C 50 190.4, 52.6 188.4, 53 186 C 48 188.6, 38 186, 29 178 Z',
          'M 55 180 C 59 187, 65 190.4, 72 190 C 78 189.6, 82 186, 83 181.6 C 78 187, 64 188, 55 180 Z',
          'M 37.4 142 C 37 132, 37.4 124, 39.6 116.4 C 40.4 126, 40 134, 37.4 142 Z'
        ], hp);
        o += strands([
          'M 108 28 C 92 32, 75 44, 66 62 C 60 74, 57 88, 56 100',
          'M 56 100 C 55 112, 50 120, 49 132 C 48 144, 54 152, 50 164 C 47 172, 47 180, 50 187',
          'M 66 140 C 72 150, 68 162, 70 172 C 71 178, 70 182, 67 186',
          'M 100 40 C 88 52, 81 68, 79 86'
        ], hp);
        o += shines([
          'M 98 29 C 86 33, 76 41, 69 51',
          'M 50 108 C 47 116, 46 124, 46.4 132',
          'M 39 152 C 36 160, 36 168, 39 176',
          'M 58.4 148 C 61 156, 60 164, 61 172',
          'M 85 70 C 83 76, 82 82, 81.6 88'
        ], hp);
        o += lock(BOB_R, hp);
        o += shades([
          'M 173 128 C 167 140, 160 152, 156 162 C 152 172, 147 180, 144 187 C 149 184, 154 176, 158 167 C 163 156, 169 144, 173 128 Z',
          'M 211 178 C 209 186, 202 190.6, 194 190.6 C 190 190.4, 187.4 188.4, 187 186 C 192 188.6, 202 186, 211 178 Z',
          'M 185 180 C 181 187, 175 190.4, 168 190 C 162 189.6, 158 186, 157 181.6 C 162 187, 176 188, 185 180 Z',
          'M 202.6 142 C 203 132, 202.6 124, 200.4 116.4 C 199.6 126, 200 134, 202.6 142 Z',
          'M 116 49 C 128 50, 146 56, 156 68 C 162 76, 164 86, 163.5 97 C 160 86, 156 77, 150 71 C 140 61, 128 55.4, 116.4 54.4 Z'
        ], hp);
        o += strands([
          'M 118 27 C 136 28, 158 38, 170 56 C 178 68, 182 84, 184 100',
          'M 184 100 C 185 112, 190 120, 191 132 C 192 144, 186 152, 190 164 C 193 172, 193 180, 190 187',
          'M 174 140 C 168 150, 172 162, 170 172 C 169 178, 170 182, 173 186',
          'M 122 37 C 140 37, 157 47, 167 64'
        ], hp);
        o += shines([
          'M 128 27 C 144 29, 158 36, 167 46',
          'M 130 45 C 143 48, 153 55, 159 64',
          'M 190 108 C 193 116, 194 124, 193.6 132',
          'M 201 152 C 204 160, 204 168, 201 176',
          'M 181.6 148 C 179 156, 180 164, 179 172'
        ], hp);
        o += P('M 113.4 29 C 113.3 35, 113.7 41, 114.6 46', null, hp.l, 1.2, op(0.8));
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P('M 120 20 C 152 20, 178 33, 188 56 C 196 76, 195 100, 199 120 C 202 134, 203 142, 204 150 C 206 160, 211 166, 212 174 C 213 183, 208 190, 200 192 C 194 194, 188 192, 185 188 C 180 194, 170 196, 162 192 C 156 196, 146 197, 140 193 C 134 197, 126 197, 120 194 C 114 197, 106 197, 100 193 C 94 197, 84 196, 78 192 C 70 196, 60 194, 55 188 C 52 192, 46 194, 40 192 C 32 190, 27 183, 28 174 C 29 166, 34 160, 36 150 C 37 142, 38 134, 41 120 C 45 100, 44 76, 52 56 C 62 33, 88 20, 120 20 Z', hp.f, hp.l, 1.8);
        o += shades([
          'M 29 176 C 31 185, 37 190.6, 44 191.4 C 49 191.8, 53 190.4, 55 188 C 46 189, 36 185, 29 176 Z',
          'M 211 176 C 209 185, 203 190.6, 196 191.4 C 191 191.8, 187 190.4, 185 188 C 194 189, 204 185, 211 176 Z',
          'M 78 192 C 84 195.6, 94 196, 100 193 C 92 193.6, 85 193.4, 78 192 Z',
          'M 140 193 C 146 196, 156 195.6, 162 192 C 155 193.4, 148 193.6, 140 193 Z',
          'M 100 193.4 C 106 196.6, 114 196.8, 120 194.2 C 126 196.8, 134 196.6, 140 193.4 C 132 194.6, 108 194.6, 100 193.4 Z'
        ], hp);
        o += strands([
          'M 118 38 C 100 44, 84 60, 76 82 C 70 100, 70 116, 64 132 C 58 146, 62 162, 56 176 C 54 182, 55 186, 55 188',
          'M 122 38 C 140 44, 156 60, 164 82 C 170 100, 170 116, 176 132 C 182 146, 178 162, 184 176 C 186 182, 185 186, 185 188',
          'M 112 44 C 102 70, 100 100, 96 124 C 92 146, 96 166, 90 184 C 88 188, 84 190, 78 192',
          'M 128 44 C 138 70, 140 100, 144 124 C 148 146, 144 166, 150 184 C 152 188, 156 190, 162 192',
          'M 120 46 C 118 80, 122 120, 118 156 C 117 172, 119 184, 120 194'
        ], hp);
        o += shines([
          'M 102 31 C 88 37, 76 49, 70 63',
          'M 138 31 C 152 37, 164 49, 170 63',
          'M 47 126 C 44 136, 42 146, 38 156',
          'M 193 126 C 196 136, 198 146, 202 156',
          'M 106 62 C 103 76, 102 90, 101 102',
          'M 134 62 C 137 76, 138 90, 139 102',
          'M 70 150 C 68 160, 66 170, 64 178',
          'M 170 150 C 172 160, 174 170, 176 178'
        ], hp);
        o += P('M 124 44 C 120 40, 114 42, 115 47 C 116 51, 122 51, 123 47', null, hp.l, 1.2, op(0.8));
        return o;
      }
    },

    'long-waves': {
      back: function (c) {
        var hp = c.hair;
        return P('M 113 24 C 150 22, 180 34, 190 60 C 198 82, 196 104, 199 126 C 202 160, 206 220, 200 292 L 40 292 C 34 220, 38 160, 41 126 C 44 104, 42 82, 50 60 C 60 34, 80 24, 113 24 Z', hp.s, hp.l, 2);
      },
      front: function (c) {
        var hp = c.hair, o = browShade(c);
        o += lock(LW_L, hp);
        o += shades([
          'M 66 128 C 72 142, 78 160, 82 176 C 86 190, 90 202, 92 216 C 88 204, 82 190, 78 178 C 73 162, 68 146, 66 128 Z',
          'M 41 297 C 42 304, 46 308, 52 308 C 48 305, 44 302, 41 297 Z',
          'M 59.6 299 C 64 305, 70 308, 77 306.6 C 71 305, 65 302.6, 59.6 299 Z',
          'M 85 295.6 C 88 297.6, 92 297.6, 95 294.6 C 92 295, 88 295.4, 85 295.6 Z',
          'M 38.6 119 C 41.4 126, 42.6 136, 40 146 C 39.4 138, 38.4 130, 36.4 124 Z',
          'M 32 190 C 36 200, 40 210, 37.4 222 C 36.4 212, 34 200, 32 190 Z'
        ], hp);
        o += strands([
          'M 108 28 C 92 32, 75 44, 66 62 C 60 74, 57 88, 56 100',
          'M 56 100 C 54 116, 48 126, 48 140 C 48 154, 42 166, 44 180 C 46 194, 52 204, 50 220 C 48 236, 44 248, 47 262 C 50 276, 54 286, 52 300',
          'M 66 150 C 70 166, 70 182, 72 196 C 74 212, 70 226, 72 242 C 74 258, 72 274, 74 290 C 74.6 296, 76 302, 78 306',
          'M 100 42 C 88 54, 80 70, 78 88'
        ], hp);
        o += shines([
          'M 97 31 C 85 35, 75 43, 68 53',
          'M 49.5 112 C 46.6 120, 46.4 128, 47.2 136',
          'M 40 160 C 39 172, 42 184, 44 192',
          'M 42 236 C 40 246, 41 256, 44 264',
          'M 60 196 C 63 210, 62 222, 61 232'
        ], hp);
        o += lock(LW_R, hp);
        o += shades([
          'M 174 128 C 168 142, 162 160, 158 176 C 154 190, 150 202, 148 216 C 152 204, 158 190, 162 178 C 167 162, 172 146, 174 128 Z',
          'M 199 297 C 198 304, 194 308, 188 308 C 192 305, 196 302, 199 297 Z',
          'M 180.4 299 C 176 305, 170 308, 163 306.6 C 169 305, 175 302.6, 180.4 299 Z',
          'M 155 295.6 C 152 297.6, 148 297.6, 145 294.6 C 148 295, 152 295.4, 155 295.6 Z',
          'M 201.4 119 C 198.6 126, 197.4 136, 200 146 C 200.6 138, 201.6 130, 203.6 124 Z',
          'M 208 190 C 204 200, 200 210, 202.6 222 C 203.6 212, 206 200, 208 190 Z',
          'M 114 48 C 122 49, 130 51, 138 56 C 146 61, 153 68, 157 76 C 150 68, 141 62, 132 58 C 126 55.6, 120 54, 114.4 53 Z'
        ], hp);
        o += strands([
          'M 118 30 C 136 30, 158 40, 170 58 C 178 70, 182 86, 183.5 100',
          'M 183.5 100 C 186 114, 192 126, 192 140 C 192 154, 198 166, 196 180 C 194 194, 188 204, 190 220 C 192 236, 196 248, 193 262 C 190 276, 186 286, 188 300',
          'M 174 150 C 170 166, 170 182, 168 196 C 166 212, 170 226, 168 242 C 166 258, 168 274, 166 290 C 165.4 296, 164 302, 162 306',
          'M 124 40 C 142 40, 158 50, 166 66'
        ], hp);
        o += shines([
          'M 128 29 C 144 31, 158 38, 167 48',
          'M 129 45 C 141 47, 152 54, 158 63',
          'M 190.5 112 C 193.4 120, 193.6 128, 192.8 136',
          'M 200 160 C 201 172, 198 184, 196 192',
          'M 198 236 C 200 246, 199 256, 196 264',
          'M 180 196 C 177 210, 178 222, 179 232'
        ], hp);
        o += P('M 113.4 29 C 113.3 35, 113.7 41, 114.6 46', null, hp.l, 1.2, op(0.8));
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P('M 120 20 C 152 20, 178 34, 188 58 C 196 80, 195 104, 199 126 C 203 150, 204 172, 202 196 C 200 220, 206 240, 204 262 C 202 284, 208 300, 200 312 C 194 318, 186 316, 180 310 C 174 318, 162 318, 156 311 C 150 318, 138 318, 132 312 C 126 318, 114 318, 108 312 C 102 318, 90 318, 84 311 C 78 318, 66 318, 60 310 C 54 316, 46 318, 40 312 C 32 300, 38 284, 36 262 C 34 240, 40 220, 38 196 C 36 172, 37 150, 41 126 C 45 104, 44 80, 52 58 C 62 34, 88 20, 120 20 Z', hp.f, hp.l, 2);
        o += shades([
          'M 41 311 C 46 316, 54 316, 59 310.6 C 53 312, 47 312.4, 41 311 Z',
          'M 199 311 C 194 316, 186 316, 181 310.6 C 187 312, 193 312.4, 199 311 Z',
          'M 85 311 C 92 316.4, 102 316.4, 107 312 C 100 312.6, 92 312.6, 85 311 Z',
          'M 133 312 C 138 316.4, 148 316.4, 155 311 C 148 312.6, 140 312.6, 133 312 Z',
          'M 109 312 C 114 316.4, 126 316.4, 131 312 C 124 313, 116 313, 109 312 Z'
        ], hp);
        o += strands([
          'M 118 40 C 100 46, 84 62, 76 84 C 70 102, 72 120, 66 138 C 60 156, 64 176, 58 196 C 54 214, 60 232, 56 250 C 52 268, 58 286, 58 310',
          'M 122 40 C 140 46, 156 62, 164 84 C 170 102, 168 120, 174 138 C 180 156, 176 176, 182 196 C 186 214, 180 232, 184 250 C 188 268, 182 286, 182 310',
          'M 110 46 C 100 80, 100 120, 94 150 C 90 176, 96 200, 92 226 C 88 252, 92 280, 86 310',
          'M 130 46 C 140 80, 140 120, 146 150 C 150 176, 144 200, 148 226 C 152 252, 148 280, 154 310',
          'M 120 48 C 118 100, 122 160, 118 220 C 116 260, 122 290, 120 312'
        ], hp);
        o += shines([
          'M 102 32 C 88 38, 76 50, 70 64',
          'M 138 32 C 152 38, 164 50, 170 64',
          'M 50 130 C 48 146, 50 160, 46 176',
          'M 190 130 C 192 146, 190 160, 194 176',
          'M 48 236 C 46 250, 48 262, 46 276',
          'M 192 236 C 194 250, 192 262, 194 276'
        ], hp);
        return o;
      }
    },

    'long-straight': {
      back: function (c) {
        var hp = c.hair;
        return P('M 120 23 C 152 23, 180 36, 190 62 C 198 84, 196 120, 198 160 L 200 302 L 40 302 L 42 160 C 44 120, 42 84, 50 62 C 60 36, 88 23, 120 23 Z', hp.s, hp.l, 2);
      },
      front: function (c) {
        var hp = c.hair, o = '';
        var L = LS_L, R = mir(LS_L);
        o += lock(L, hp) + lock(R, hp);
        var sh = ['M 70 140 C 78 160, 86 184, 88 206 C 90 236, 92 272, 93.4 302 C 90 270, 86 236, 84 208 C 82 186, 76 162, 70 140 Z',
          'M 46 98 C 45 124, 44 156, 43 190 C 42.4 230, 41.6 270, 41.6 300 C 44 268, 45 230, 46.4 190 C 47.6 156, 48 124, 46 98 Z'];
        o += shades(sh.concat(sh.map(mir)), hp);
        var st = ['M 112 34 C 92 44, 76 62, 66 84 C 58 104, 57 140, 56 180 C 55 220, 56 260, 56 308',
          'M 104 44 C 88 60, 80 80, 76 100', 'M 66 132 C 70 160, 72 200, 72 240 C 72 270, 74 290, 74 308',
          'M 50 160 C 49 200, 48 250, 48 300'];
        o += strands(st.concat(st.map(mir)), hp);
        var sn = ['M 104 30 C 90 34, 78 42, 70 54', 'M 52 120 C 51 140, 51 160, 50.6 180', 'M 62 200 C 62 220, 62 240, 62.4 260'];
        o += shines(sn.concat(sn.map(mir)), hp);
        o += P('M 120 22.5 L 120 31', null, hp.l, 1.3);
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P('M 120 20 C 152 20, 178 34, 188 58 C 196 80, 196 120, 198 160 C 200 220, 202 270, 202 308 C 202 314, 198 318, 192 318 L 48 318 C 42 318, 38 314, 38 308 C 38 270, 40 220, 42 160 C 44 120, 44 80, 52 58 C 62 34, 88 20, 120 20 Z', hp.f, hp.l, 2);
        o += strands([
          'M 116 36 C 96 44, 82 62, 74 86 C 66 110, 64 150, 64 200 C 64 240, 66 280, 66 316',
          'M 124 36 C 144 44, 158 62, 166 86 C 174 110, 176 150, 176 200 C 176 240, 174 280, 174 316',
          'M 110 44 C 98 80, 94 140, 92 200 C 91 240, 92 280, 92 316',
          'M 130 44 C 142 80, 146 140, 148 200 C 149 240, 148 280, 148 316',
          'M 120 46 C 120 120, 120 220, 120 316',
          'M 52 150 C 50 200, 50 260, 50 316', 'M 188 150 C 190 200, 190 260, 190 316'
        ], hp);
        o += shines([
          'M 102 32 C 88 38, 76 50, 70 64', 'M 138 32 C 152 38, 164 50, 170 64',
          'M 58 120 C 57 150, 56 180, 56 210', 'M 182 120 C 183 150, 184 180, 184 210',
          'M 106 70 C 104 110, 104 150, 104 190', 'M 134 70 C 136 110, 136 150, 136 190'
        ], hp);
        return o;
      }
    },

    'high-bun': {
      back: function (c) {
        var hp = c.hair, o = '';
        o += P('M 120 2.5 C 133 2.5, 142 11, 142 22 C 142 33, 133 41, 120 41 C 107 41, 98 33, 98 22 C 98 11, 107 2.5, 120 2.5 Z', hp.f, hp.l, 2);
        o += P('M 101.5 16 C 110 11, 129 10.6, 138.6 17.6', null, hp.l, 1.25, op(0.8));
        o += P('M 99.6 26 C 110 30.6, 130 30.6, 140.4 25', null, hp.l, 1.25, op(0.8));
        o += P('M 108 7.6 C 116 5.4, 126 5.6, 133 9.4', null, hp.h, 2.2, op(0.9));
        o += P('M 104 21 C 112 23.6, 126 23.6, 134 20.4', null, hp.h, 2, op(0.7));
        return o;
      },
      front: function (c) {
        var hp = c.hair, o = '';
        o += lock('M 120 28 C 147 28, 167 41, 173 64 C 176 77, 176.5 90, 175 101 C 172 98, 168 96.5, 164.5 96 C 163 80, 152 62, 132 55 C 124 52.6, 116 52.6, 108 55 C 88 62, 77 80, 75.5 96 C 72 96.5, 68 98, 65 101 C 63.5 90, 64 77, 67 64 C 73 41, 93 28, 120 28 Z', hp);
        o += shades(['M 75.5 96 C 77 80, 88 62, 108 55 C 116 52.6, 124 52.6, 132 55 C 152 62, 163 80, 164.5 96 C 160 82, 150 66, 132 59.6 C 124 57.4, 116 57.4, 108 59.6 C 90 66, 80 82, 75.5 96 Z'], hp);
        o += strands([
          'M 96 61 C 100 48, 108 38, 116 32', 'M 144 61 C 140 48, 132 38, 124 32',
          'M 82 78 C 84 60, 94 44, 108 35', 'M 158 78 C 156 60, 146 44, 132 35',
          'M 120 53 L 120 31'
        ], hp);
        o += shines(['M 90 44 C 98 37, 108 33.4, 117 32.4', 'M 150 44 C 144 39, 136 35.4, 128 34'], hp);
        // face-framing wisps
        o += PM('M 76.6 92 C 72.4 104, 75.4 116, 71.4 128 C 70.8 131, 72.6 132.4, 73.6 129.6 C 77.6 118, 75.8 106, 79.4 94.4 Z', hp.f, hp.l, 1.4);
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P(CAP_REAR, hp.f, hp.l, 2);
        o += strands([
          'M 88 140 C 84 100, 94 62, 110 40', 'M 152 140 C 156 100, 146 62, 130 40',
          'M 120 152 C 120 110, 120 72, 120 42', 'M 104 148 C 100 110, 104 70, 115 42',
          'M 136 148 C 140 110, 136 70, 125 42', 'M 74 110 C 76 82, 88 56, 104 42', 'M 166 110 C 164 82, 152 56, 136 42'
        ], hp);
        o += shines(['M 96 50 C 88 64, 84 80, 83 96', 'M 144 50 C 152 64, 156 80, 157 96', 'M 112 70 C 110 90, 110 110, 111 128'], hp);
        o += HAIR['high-bun'].back(c);
        return o;
      }
    },

    'curly': {
      back: function (c) {
        return P(CURLY_BACK, c.hair.s, c.hair.l, 2);
      },
      front: function (c) {
        var hp = c.hair, o = '';
        o += lock(CURLY_L, hp) + lock(CURLY_R, hp);
        o += shades([
          'M 70 133 C 76 143, 82 155, 86 167 C 88 175, 92 183, 98 187 C 90 186, 84 178, 81 168 C 77 156, 72 145, 70 133 Z',
          'M 170 134 C 164 144, 158 156, 154 168 C 152 176, 148 184, 142 188 C 150 186, 156 178, 159 168 C 163 156, 168 145, 170 134 Z'
        ], hp);
        o += curlMarks([[50, 60, 1], [44, 84, 0.9], [46, 110, 1], [44, 138, 0.9], [50, 166, 1], [64, 184, 0.9], [84, 184, 0.8], [66, 42, 0.9], [92, 32, 0.9],
          [190, 60, 1], [196, 84, 0.9], [194, 110, 1], [196, 138, 0.9], [190, 166, 1], [176, 184, 0.9], [156, 184, 0.8], [174, 42, 0.9], [146, 32, 0.9],
          [122, 34, 0.9], [62, 120, 0.8], [178, 120, 0.8], [60, 148, 0.8], [180, 148, 0.8]], hp);
        o += shines(['M 70 30 C 78 26, 86 25, 92 27', 'M 150 27 C 158 25, 166 27, 172 32', 'M 38 100 C 37 106, 38 112, 40 116', 'M 202 100 C 203 106, 202 112, 200 116',
          'M 112 26 C 118 23, 126 23, 132 26', 'M 38 156 C 38 162, 40 166, 43 170', 'M 202 156 C 202 162, 200 166, 197 170'], hp);
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P('M 120 16 C 130 10, 146 12, 152 20 C 162 16, 176 22, 178 34 C 190 34, 198 46, 196 58 C 206 64, 208 78, 202 88 C 210 96, 210 110, 204 118 C 212 126, 212 142, 204 148 C 212 158, 210 174, 200 178 C 204 192, 194 204, 182 200 C 178 210, 162 212, 156 204 C 150 212, 134 212, 128 204 C 124 212, 116 212, 112 204 C 106 212, 90 212, 84 204 C 78 212, 62 210, 58 200 C 46 204, 36 192, 40 178 C 30 174, 28 158, 36 148 C 28 142, 28 126, 36 118 C 30 110, 30 96, 38 88 C 32 78, 34 64, 44 58 C 42 46, 50 34, 62 34 C 64 22, 78 16, 88 20 C 94 12, 110 10, 120 16 Z', hp.f, hp.l, 2);
        o += curlMarks([[60, 50, 1], [90, 36, 1], [120, 32, 1], [150, 36, 1], [180, 50, 1], [48, 80, 1], [80, 66, 1], [110, 60, 1], [140, 62, 1], [172, 72, 1], [194, 84, 1],
          [46, 112, 1], [76, 100, 1], [106, 92, 1], [136, 96, 1], [166, 104, 1], [196, 116, 1], [50, 144, 1], [84, 132, 1], [116, 126, 1], [148, 132, 1], [182, 140, 1],
          [60, 176, 1], [94, 164, 1], [126, 160, 1], [158, 168, 1], [190, 176, 1], [76, 196, 0.9], [106, 194, 0.9], [138, 196, 0.9], [168, 196, 0.9]], hp);
        o += shines(['M 72 28 C 80 24, 88 24, 94 26', 'M 146 26 C 154 24, 162 26, 168 30', 'M 112 22 C 118 19, 126 19, 132 22', 'M 40 100 C 39 106, 40 112, 42 116', 'M 200 100 C 201 106, 200 112, 198 116'], hp);
        return o;
      }
    },

    'ponytail': {
      back: function (c) {
        var hp = c.hair, o = '';
        o += P('M 160 46 C 178 52, 190 72, 192 98 C 194 124, 202 152, 198 182 C 196 198, 188 212, 177 221 C 181 205, 180 188, 174 174 C 168 158, 166 140, 166 120 C 166 96, 166 70, 160 46 Z', hp.f, hp.l, 2);
        o += P('M 170 70 C 180 90, 182 114, 186 140 C 190 164, 190 186, 184 204', null, hp.l, 1.25, op(0.75));
        o += P('M 178 84 C 184 104, 184 124, 190 150', null, hp.h, 2.4, op(0.9));
        o += P('M 174 174 C 180 188, 181 205, 177 221 C 186 210, 192 196, 193 180 C 186 186, 180 182, 174 174 Z', hp.s, null);
        o += P('M 166.6 53.6 C 172 51.8, 178.6 53.4, 183 57.4 L 182 63.8 C 177.6 60.6, 172 59.4, 167.4 60.2 Z', mix(hp.l, '#B4566C', 0.45), mix(hp.l, '#000000', 0.2), 1.3);
        return o;
      },
      front: function (c) {
        var hp = c.hair, o = '';
        o += lock('M 113 27 C 96 27, 76 36, 68 58 C 64 70, 63.5 86, 65 101 C 68 98, 72 96.5, 75.5 96 C 78 80, 90 64, 106 58 C 110 56.5, 113 55, 115 52 Z', hp);
        o += lock('M 113 27 C 140 26, 165 38, 172 62 C 176 76, 176.5 90, 175 101 C 172 98, 168 96.5, 164.5 96 C 162 80, 150 62, 132 55 C 126 53, 119 52.5, 114 53 C 112 46, 112 36, 113 27 Z', hp);
        o += shades(['M 114 53 C 119 52.5, 126 53, 132 55 C 150 62, 162 80, 164.5 96 C 158 82, 148 68, 132 60 C 126 57.4, 120 56.6, 114.4 57 Z'], hp);
        o += strands(['M 106 33 C 92 38, 80 50, 74 70', 'M 120 32 C 140 34, 158 46, 166 70', 'M 120 45 C 136 46, 150 56, 158 72'], hp);
        o += shines(['M 98 33 C 88 37, 80 44, 75 53', 'M 128 31 C 144 33, 156 40, 164 50'], hp);
        o += PM('M 76.6 92 C 72.4 104, 75.4 116, 71.4 128 C 70.8 131, 72.6 132.4, 73.6 129.6 C 77.6 118, 75.8 106, 79.4 94.4 Z', hp.f, hp.l, 1.4);
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P(CAP_REAR, hp.f, hp.l, 2);
        o += strands(['M 88 140 C 86 110, 96 84, 112 68', 'M 152 140 C 154 110, 144 84, 128 68', 'M 120 150 L 120 76', 'M 104 146 C 102 116, 106 92, 115 72', 'M 136 146 C 138 116, 134 92, 125 72',
          'M 76 96 C 82 70, 98 52, 114 66', 'M 164 96 C 158 70, 142 52, 126 66'], hp);
        o += shines(['M 98 40 C 90 50, 84 62, 82 76', 'M 142 40 C 150 50, 156 62, 158 76'], hp);
        o += P('M 111 70 C 100 92, 97 130, 103 168 C 107 198, 112 226, 120 252 C 128 226, 133 198, 137 168 C 143 130, 140 92, 129 70 Z', hp.f, hp.l, 2);
        o += P('M 120 250 C 114 230, 110 206, 107 180 C 112 200, 116 222, 120 250 Z', hp.s, null);
        o += strands(['M 114 80 C 106 110, 106 150, 112 190 C 114 210, 116 230, 120 248', 'M 126 80 C 134 110, 134 150, 128 190 C 126 210, 124 230, 120 248'], hp);
        o += shines(['M 120 84 C 118 110, 118 140, 120 170'], hp);
        o += P('M 110 64 C 116 60.4, 124 60.4, 130 64 L 129.2 74.4 C 123.4 71.6, 116.6 71.6, 110.8 74.4 Z', mix(hp.l, '#B4566C', 0.45), mix(hp.l, '#000000', 0.2), 1.4);
        return o;
      }
    }
  };

  /* ------------------------------------------------------------------ accessories */

  function earrings(c, rear) {
    var e = c.a.earrings;
    if (e === 'none') return '';
    var gold = '#D9A740', goldL = '#A7791F', goldH = '#F6DA86';
    if (e === 'studs') return CM(68.2, 124.2, 2.4, gold, goldL, 1) + CM(67.6, 123.4, 0.8, goldH);
    return CM(68.4, 131.2, 5.8, null, goldL, 3.6) + CM(68.4, 131.2, 5.8, null, gold, 2.2) +
      PM('M 64.2 127.4 C 65.2 126.4, 66.4 125.8, 67.6 125.6', null, goldH, 1.2);
  }

  function glasses(c) {
    var g = c.a.glasses;
    if (g === 'none') return '';
    var frame = '#4B3742', gid = c.uid + '-lens';
    c.defs.push('<linearGradient id="' + gid + '" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".38"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".08"/></linearGradient>');
    var o = '';
    if (g === 'round') {
      o += CIR(100.5, 99.5, 13, 'url(#' + gid + ')', frame, 2) + CIR(139.5, 99.5, 13, 'url(#' + gid + ')', frame, 2);
      o += P('M 113.4 97.6 C 116.6 94.6, 123.4 94.6, 126.6 97.6', null, frame, 2);
      o += PM('M 87.6 97 L 74.5 95.4', null, frame, 2);
      o += PM('M 92 92.6 C 94 90.6, 96.6 89.6, 99 89.4', null, '#FFFFFF', 1.4, op(0.7));
    } else {
      var F = 'M 86.4 93 C 89 88.4, 98.4 87.2, 107.8 88.8 C 112 89.6, 114.4 92.4, 113.8 97.6 C 113.2 105.4, 106.6 110.6, 99 110.6 C 91.6 110.6, 86.6 106, 86 100.2 C 85.6 97.4, 84.2 94, 80.8 90.6 C 83.2 90.8, 85.2 91.6, 86.4 93 Z';
      o += P(F, 'url(#' + gid + ')', frame, 2) + P(mir(F), 'url(#' + gid + ')', frame, 2);
      o += P('M 113.8 96.6 C 116.8 94.4, 123.2 94.4, 126.2 96.6', null, frame, 2);
      o += PM('M 82 92.4 L 74.5 95.2', null, frame, 2);
      o += PM('M 91.6 92.4 C 94 90.6, 97 89.8, 100 89.8', null, '#FFFFFF', 1.4, op(0.7));
      o += PM('M 82.6 91.6 C 84.4 92.2, 85.6 93.2, 86.2 94.6', null, mix(frame, '#FFFFFF', 0.35), 1, op(0.8));
    }
    return o;
  }

  /* ------------------------------------------------------------------ tops */

  // Torso with a neckline of half-width nw and centre depth nd; hem at hemY.
  function torsoD(nw, nd, hemY, back) {
    var x0 = 120 - nw;
    var start = back ? [120, 182.5] : [120, nd];
    var neck = back ? [110, 182.5, 104, 183.6, x0, 186] : [120 - nw * 0.55, nd, 120 - nw * 0.95, nd - (nd - 186) * 0.45, x0, 186];
    return sym([start, neck, [88, 190, 66, 194, 50, 200], [44, 203, 42, 210, 44, 220], [60, 252],
      [61, 276, 62.6, 300, 63.6, hemY - 8], [64.6, hemY - 2, 67.6, hemY + 2.4, 74, hemY + 2.8], [92, hemY + 3.6, 108, hemY + 3.4, 120, hemY + 3]]);
  }
  function neckBand(nw, nd, w) {
    var a = 120 - nw, b = 120 + nw, ky = nd - (nd - 186) * 0.45;
    return 'M ' + pt(a, 186) + ' C ' + pt(120 - nw * 0.95, ky) + ' ' + pt(120 - nw * 0.55, nd) + ' ' + pt(120, nd) +
      ' C ' + pt(120 + nw * 0.55, nd) + ' ' + pt(120 + nw * 0.95, ky) + ' ' + pt(b, 186) +
      ' L ' + pt(b + w * 0.7, 186 + w * 0.45) +
      ' C ' + pt(120 + nw * 0.95 + w * 0.4, ky + w) + ' ' + pt(120 + nw * 0.55, nd + w) + ' ' + pt(120, nd + w) +
      ' C ' + pt(120 - nw * 0.55, nd + w) + ' ' + pt(120 - nw * 0.95 - w * 0.4, ky + w) + ' ' + pt(a - w * 0.7, 186 + w * 0.45) + ' Z';
  }
  function backNeck(w) {
    return 'M 101 186 C 104 183.6, 110 182.5, 120 182.5 C 130 182.5, 136 183.6, 139 186 L ' + pt(139 + w * 0.7, 186 + w * 0.5) +
      ' C ' + pt(136, 183.6 + w) + ' ' + pt(130, 182.5 + w) + ' ' + pt(120, 182.5 + w) + ' C ' + pt(110, 182.5 + w) + ' ' + pt(104, 183.6 + w) + ' ' + pt(101 - w * 0.7, 186 + w * 0.5) + ' Z';
  }

  var SLV = {
    blouse: 'M 50 200 C 38.4 203, 31 216, 29.4 236 C 27.4 262, 22.6 292, 20.6 318 C 19.8 328, 21.4 334, 24.6 337 L 57 337 C 59 330, 60.5 318, 61 304 C 61.5 286, 61 268, 59.5 250 C 58 230, 56 212, 50 200 Z',
    sweater: 'M 50 200 C 38 203, 31 216, 29 236 C 27 262, 24 290, 23 314 C 22.5 324, 23.5 330, 25 334 L 57.5 334 C 59.5 322, 60.5 306, 61 290 C 61.5 274, 61 262, 59.5 250 C 58 230, 56 212, 50 200 Z',
    lace: 'M 50 200 C 38 203, 32 216, 30 236 C 28 262, 27 292, 27.5 318 C 27.8 330, 28.6 340, 29.6 345 L 55.6 345 C 57.6 330, 59.6 306, 60.6 286 C 61 272, 61 260, 59.5 250 C 58 230, 56 212, 50 200 Z',
    tee: 'M 50 200 C 39 203, 32 213, 29 226 C 27.5 234, 26.5 242, 26.5 250 L 61 259 C 60.6 250, 59.8 246, 60 236, 59.5 228 C 58.5 216, 55.5 206, 50 200 Z',
    flutter: 'M 50 200 C 38 203, 31 214, 28 228 C 25 238, 22 246, 21.6 252 C 26 256.6, 30 252.6, 34 255.4 C 38 258.2, 42 254.4, 46 257 C 50 259.4, 54 256.6, 61 261 C 60.4 250, 59.6 246, 60 236, 59.5 228 C 58.5 216, 55.5 206, 50 200 Z'
  };

  function ribs(x0, x1, y0, y1, step, color, w, o2) {
    var s = '';
    for (var x = x0; x <= x1 + 0.01; x += step) s += 'M ' + pt(x, y0) + ' L ' + pt(x, y1) + ' ';
    return P(s, null, color, w || 1, op(o2 || 0.7));
  }

  function topPiece(c, g, back) {
    var p = gPal(g), k = g.kind, body = '', sl = '';
    if (k === 'sweater') {
      body += P(sym([back ? [120, 182.5] : [120, 197.5], back ? [110, 182.5, 104, 183.6, 101, 186] : [109.6, 197.5, 102, 191, 101, 186], [88, 190, 66, 194, 50, 200], [44, 203, 42, 210, 44, 220], [60, 252], [61, 290, 62, 318, 62.4, 338], [80, 340, 100, 340.6, 120, 340.6]]), p.f, p.l, 2);
      body += P(back ? backNeck(5) : neckBand(19, 197.5, 5), p.f, p.l, 1.6);
      body += P(sym([[120, 339], [100, 339, 80, 338.4, 62.3, 337.4], [62.6, 353], [82, 354.4, 102, 355, 120, 355]]), p.f, p.l, 1.8);
      body += ribs(66, 174, 341, 353, 4, p.d, 1, 0.8);
      if (!back) {
        body += PM('M 100 212 C 97 230, 103 250, 100 270 C 97 290, 103 310, 100 332', null, p.d, 1.2, op(0.7));
        body += PM('M 106 212 C 103 230, 109 250, 106 270 C 103 290, 109 310, 106 332', null, p.d, 1.2, op(0.5));
        body += ribs(102, 138, 199, 201, 4, p.d, 0.9, 0.6);
      } else body += P('M 120 188 L 120 337', null, p.d, 1.1, op(0.6));
      body += PM('M 66 300 C 72 312, 78 324, 80 334', null, p.d, 1.1, op(0.6));
      sl += PM(SLV.sweater, p.f, p.l, 2);
      sl += PM('M 25.6 333 L 57.6 333 L 56 350 L 27.6 350 Z', p.f, p.l, 1.8);
      sl += PM(ribPath(29, 55, 335, 348.5, 3.4), null, p.d, 0.9, op(0.8));
      sl += PM('M 27 296 C 34 300, 44 301, 52 298', null, p.d, 1.1, op(0.7)) + PM('M 25 318 C 34 323, 46 324, 56 320', null, p.d, 1.1, op(0.6));
    } else if (k === 'tee') {
      body += P(torsoD(18, 196, 322, back), p.f, p.l, 2);
      body += P(back ? backNeck(3.6) : neckBand(18, 196, 3.6), p.s, p.l, 1.5);
      body += PM('M 68 314 C 76 310, 88 309, 96 312', null, p.d, 1.2, op(0.8)) + P('M 104 318 C 112 314.4, 126 314, 134 316.6', null, p.d, 1.2, op(0.7));
      body += PM('M 62 256 C 62.4 280, 63 300, 63.6 318', null, p.d, 1, op(0.5));
      if (back) body += P('M 120 186 L 120 322', null, p.d, 1, op(0.5));
      else body += P('M 150 300 C 136 307, 118 310, 100 308', null, p.d, 1.1, op(0.55));
      sl += PM(SLV.tee, p.f, p.l, 2);
      sl += PM('M 27.6 244.6 L 60.4 253.4', null, p.d, 1.1, op(0.9));
      sl += PM('M 34 222 C 38 226, 42 232, 44 240', null, p.d, 1, op(0.6));
    } else if (k === 'lace') {
      body += P(torsoD(21, back ? 0 : 203, 322, back), p.f, p.l, 2);
      if (!back) {
        body += scallops(neckPts(21, 203), 2.2, p.f, p.l);
        body += P(neckBand(21, 203, 4).split(' L ')[0], null, p.d, 1, op(0.8));
      } else body += P(backNeck(3), p.f, p.l, 1.4) + P('M 120 186 L 120 322', null, p.d, 1, op(0.5));
      body += laceMotif(p, back ? [[86, 220], [120, 214], [154, 220], [74, 262], [104, 252], [136, 252], [166, 262], [88, 296], [120, 288], [152, 296]]
        : [[86, 226], [154, 226], [74, 262], [104, 248], [136, 248], [166, 262], [88, 296], [120, 284], [152, 296], [120, 230]]);
      body += PM('M 70 315 C 78 311, 88 310, 96 312.6', null, p.l, 1.1, op(0.6)) + P('M 104 318 C 112 314.4, 126 314, 134 316.6', null, p.l, 1.1, op(0.55));
      sl += PM(SLV.lace, p.f, p.l, 2);
      sl += PM(scallopsD([[30, 345], [35.2, 345.4], [40.4, 345.6], [45.6, 345.6], [50.8, 345.4], [55.4, 345]], 2.6), p.f, p.l, 1.2);
      sl += PM('M 29 334 C 38 336.4, 48 336.4, 57.2 334.6', null, p.d, 1, op(0.8));
      sl += laceMotif(p, [[42, 230], [40, 270], [44, 306], [mx(42), 230], [mx(40), 270], [mx(44), 306]]);
    } else if (k === 'knit') {
      body += P(torsoD(17, 195, 322, back), p.f, p.l, 2);
      body += ribs(70, 170, back ? 192 : 204, 318, 6, p.s, 1.6, 0.8);
      body += P(back ? backNeck(5) : neckBand(17, 195, 5.4), p.f, p.l, 1.6);
      if (!back) body += ribs(104, 136, 196.5, 199.5, 3, p.l, 0.9, 0.55);
      body += PM('M 70 314 C 78 310, 88 309, 96 311.6', null, p.l, 1.2, op(0.6)) + P('M 104 318 C 112 314.4, 126 314, 134 316.6', null, p.l, 1.2, op(0.55));
      sl += PM(SLV.sweater, p.f, p.l, 2);
      sl += PM('M 34 222 C 31 250, 30 280, 30 314 M 41 214 C 38 250, 37 284, 37.6 318 M 48 216 C 46 250, 45.6 284, 46.6 320 M 54 226 C 53.6 260, 53.6 290, 54 320', null, p.s, 1.6, op(0.8));
      sl += PM('M 25.6 333 L 57.6 333 L 56 350 L 27.6 350 Z', p.f, p.l, 1.8);
      sl += PM(ribPath(29, 55, 335, 348.5, 3.4), null, p.l, 0.9, op(0.6));
    } else {
      // blouse: the relaxed pink top of the reference, tucked, with gathered cuffs
      body += P(torsoD(19, 197, 322, back), p.f, p.l, 2);
      body += P(back ? backNeck(3.4) : neckBand(19, 197, 3.4), p.f, p.l, 1.5);
      body += PM('M 70 315 C 78 311, 88 310, 96 312.6', null, p.l, 1.2, op(0.6)) + P('M 104 318 C 112 314.4, 126 314, 134 316.6', null, p.l, 1.2, op(0.55));
      if (back) body += P('M 120 186 L 120 322', null, p.l, 1, op(0.45));
      else body += P('M 154 296 C 140 305, 120 309, 100 307', null, p.l, 1.2, op(0.5)) + P('M 72 236 C 78 250, 82 262, 84 274', null, p.l, 1.1, op(0.4));
      sl += PM(SLV.blouse, p.f, p.l, 2);
      sl += PM('M 24.6 335 C 33.4 338.5, 47.4 338.5, 57.5 335.5 L 56.5 349.5 C 46 352, 34 352, 26.4 349.5 Z', p.f, p.l, 1.8);
      sl += PM('M 30.5 339.8 L 30.8 349.2 M 36 340.4 L 36.1 350 M 41.5 340.6 L 41.5 350.3 M 47 340.4 L 46.9 350 M 52.2 339.6 L 52 349.2', null, p.l, 1, op(0.6));
      sl += PM('M 22.6 318 C 30 326, 42 328, 56 324', null, p.l, 1.2, op(0.6)) + PM('M 25 294 C 32 300, 44 301, 52 297', null, p.l, 1.1, op(0.5)) +
        PM('M 30 262 C 36 267, 44 268, 50 265', null, p.l, 1.1, op(0.4));
      sl += PM('M 31 232 C 30 248, 28 262, 26 276', null, p.h, 2.4, op(0.8));
    }
    return { body: body, sleeves: sl };
  }
  function ribPath(x0, x1, y0, y1, step) {
    var s = '';
    for (var x = x0; x <= x1 + 0.01; x += step) s += 'M ' + pt(x, y0) + ' L ' + pt(x + 0.3, y1) + ' ';
    return s;
  }
  // points along a front neckline, for lace scallops
  function neckPts(nw, nd) {
    var pts = [], a = [120 - nw, 186], c1 = [120 - nw * 0.95, nd - (nd - 186) * 0.45], c2 = [120 - nw * 0.55, nd], b = [120, nd];
    for (var i = 0; i <= 5; i++) {
      var t = i / 5, u = 1 - t;
      pts.push([u * u * u * a[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t * t * t * b[0],
                u * u * u * a[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t * t * t * b[1]]);
    }
    var all = pts.slice();
    for (var j = pts.length - 2; j >= 0; j--) all.push([mx(pts[j][0]), pts[j][1]]);
    return all;
  }
  function scallops(pts, r, fill, stroke) {
    return each(pts, function (q) { return CIR(q[0], q[1] + 0.6, r, fill, stroke, 1.1); });
  }
  function scallopsD(pts, r) {
    var s = '';
    for (var i = 0; i < pts.length - 1; i++) {
      var a = pts[i], b = pts[i + 1];
      s += 'M ' + pt(a[0], a[1]) + ' C ' + pt(a[0], a[1] + r * 1.4) + ' ' + pt(b[0], b[1] + r * 1.4) + ' ' + pt(b[0], b[1]) + ' ';
    }
    return s;
  }
  function laceMotif(p, pts) {
    return each(pts, function (q) {
      var x = q[0], y = q[1];
      return CIR(x, y, 2.6, null, p.d, 1) + CIR(x, y, 0.9, p.d) +
        CIR(x - 5, y + 4, 0.8, p.d, null, 0, op(0.8)) + CIR(x + 5, y + 4, 0.8, p.d, null, 0, op(0.8)) + CIR(x, y - 5.4, 0.8, p.d, null, 0, op(0.8));
    });
  }

  /* ------------------------------------------------------------------ layers */

  function layerPiece(c, g, back) {
    var p = gPal(g), k = g.kind, body = '', sl = '', pocket = '';
    var button = mix(p.l, '#3A2A22', 0.35);
    if (k === 'trench') {
      var tr = back ? sym([[120, 182.5], [110, 182.5, 104, 183.6, 101, 186], [86, 190, 64, 194, 46, 199], [41, 202, 39, 209, 41, 218], [58, 252], [59.5, 288, 60.5, 312, 60, 332], [57, 344, 45, 352, 41, 366], [37.6, 377, 35.6, 392, 35.2, 410], [33, 450, 29.5, 560, 26, 622], [60, 627, 96, 629, 120, 629]])
        : sym([[120, 246], [104, 186], [86, 190, 64, 194, 46, 199], [41, 202, 39, 209, 41, 218], [58, 252], [59.5, 288, 60.5, 312, 60, 332], [57, 344, 45, 352, 41, 366], [37.6, 377, 35.6, 392, 35.2, 410], [33, 450, 29.5, 560, 26, 622], [60, 627, 96, 629, 120, 629]]);
      body += P(tr, p.f, p.l, 2);
      body += PM('M 30 560 C 31 590, 30 606, 29 618', null, p.s, 4, op(0.8));
      if (!back) {
        body += P('M 121 246 L 137.4 258 L 138 628', null, p.l, 1.6);
        body += PM('M 104 186 L 119 243 L 80.6 220 L 85.4 211.4 L 91.4 214.6 L 97.4 187.4 Z', p.f, p.l, 1.8);
        body += PM('M 91.4 214.6 L 103 222', null, p.l, 1.2, op(0.8));
        body += CIR(104, 268, 3, button, p.l, 1) + CIR(130, 268, 3, button, p.l, 1) + CIR(104, 298, 3, button, p.l, 1) + CIR(130, 298, 3, button, p.l, 1) +
          CIR(104, 360, 3, button, p.l, 1) + CIR(130, 360, 3, button, p.l, 1);
        body += PM('M 94 191 L 52 201.4 L 53.6 209.4 L 95.4 199 Z', p.f, p.l, 1.4) + CM(58.6, 204.6, 1.8, button);
        body += P('M 138 380 C 137.6 450, 137.6 540, 138 626', null, p.s, 3, op(0.6));
      } else {
        body += P(sym([[120, 184], [110, 184, 104, 185, 101, 186.4], [86, 190.4, 64, 194.4, 46.4, 199.4], [41.4, 202.4, 39.4, 209.4, 41.4, 218.4], [58.2, 252], [80, 256, 100, 258, 120, 258]]), p.f, p.l, 1.8);
        body += P('M 120 258 L 120 548 L 126 556 L 126 629', null, p.l, 1.5) + P('M 120 548 L 120 629', null, p.l, 1.2, op(0.6));
        body += PM('M 94 191 L 52 201.4 L 53.6 209.4 L 95.4 199 Z', p.f, p.l, 1.4);
      }
      body += P(sym([[120, 321], [100, 321, 80, 321.4, 59.8, 322], [59.9, 337.4], [80, 337.8, 100, 338.2, 120, 338.2]]), p.f, p.l, 1.6);
      if (!back) {
        body += P('M 100 317.6 L 115 317.6 C 116.4 317.6, 117 318.4, 117 319.6 L 117 339.6 C 117 340.8, 116.4 341.4, 115 341.4 L 100 341.4 C 98.6 341.4, 98 340.8, 98 339.6 L 98 319.6 C 98 318.4, 98.6 317.6, 100 317.6 Z', null, '#7C5A34', 2.2);
        body += P('M 103 329.6 L 113 329.6', null, '#7C5A34', 1.6);
        body += P('M 112 337 C 114 350, 113 362, 110 372 L 103.6 370.4 C 106.4 360, 107 350, 105.6 338 Z', p.f, p.l, 1.4);
      } else {
        body += PM('M 92 318.6 L 92 340.6 L 97 340.6 L 97 318.6 Z', p.f, p.l, 1.2);
      }
      body += PM('M 28 613 C 60 618.6, 96 620.6, 120 620.6', null, p.d, 1.1, op(0.7));
      sl += PM('M 46 198 C 35 202, 28 214, 26 232 C 23 262, 19 300, 18 330 C 17.6 340, 18.4 346, 19.6 349.4 L 58.4 349.4 C 59.8 330, 61.2 300, 61.6 276 C 62 262, 62 252, 60 244 C 58 226, 54.4 208, 46 198 Z', p.f, p.l, 2);
      sl += PM('M 18.4 326 C 32 328.6, 46 328.6, 59.6 326.4 L 59.4 335.4 C 46 337.6, 32 337.6, 18.2 335 Z', p.f, p.l, 1.4);
      sl += PM('M 46 327.6 L 51 327.6 L 51 336.4 L 46 336.4 Z', null, '#7C5A34', 1.4);
      sl += PM('M 25 250 C 24 280, 21 310, 21 322', null, p.h, 2.4, op(0.8)) + PM('M 30 290 C 38 294, 48 295, 56 292', null, p.l, 1.1, op(0.5));
      if (!back) {
        pocket += PM(POCKET_FILL, p.f, null) + PM(POCKET_HIP, null, p.l, 2) + PM(POCKET_SLANT, null, p.l, 1.8) + PM('M 61 368 L 39.6 410.6', null, p.l, 1.2, op(0.75));
      } else pocket += PM(POCKET_FILL, p.f, null) + PM(POCKET_HIP, null, p.l, 2) + PM(POCKET_SLANT, null, p.l, 1.6);
    } else if (k === 'cardigan') {
      if (back) {
        body += P(sym([[120, 182.5], [110, 182.5, 104, 183.6, 101, 186], [88, 190, 66, 194, 47, 199], [42, 202, 40, 209, 42, 218], [58, 252], [59, 284, 58.5, 318, 58, 348], [57.5, 414], [80, 415, 100, 416, 120, 416]]), p.f, p.l, 2);
        body += P(sym([[120, 403.4], [100, 403.4, 80, 402.6, 57.6, 401.6], [57.5, 414], [80, 415, 100, 416, 120, 416]]), p.f, p.l, 1.5);
        body += ribs(61, 179, 404.4, 414, 4, p.d, 1, 0.8);
        body += P(backNeck(5), p.f, p.l, 1.4);
      } else {
        var cpl = 'M 103 185 C 88 189, 66 193, 47 199 C 42 202, 40 209, 42 218 L 58 252 C 59 284, 58.5 318, 58 348 L 57.5 414 L 98.4 416 C 98.8 380, 99.2 330, 100.2 296 C 101.2 260, 103.4 220, 107 187.6 C 106 186.4, 104.6 185.4, 103 185 Z';
        body += PM(cpl, p.f, p.l, 2);
        body += PM('M 57.6 401.6 L 98.5 403.4 L 98.4 416 L 57.5 414 Z', p.f, p.l, 1.5);
        body += PM(ribPath(61, 95, 404, 414, 4), null, p.d, 1, op(0.8));
        body += PM('M 107 187.6 C 103.4 220, 101.2 260, 100.2 296 C 99.2 330, 98.8 380, 98.4 416 L 92.4 416 C 92.8 380, 93.2 330, 94.2 296 C 95.2 258, 97.4 220, 101 187.4 Z', p.f, p.l, 1.4);
        body += each([300, 330, 360, 390], function (y) { return CIR(96.3, y, 2.6, '#E7D8BF', mix('#E7D8BF', p.l, 0.5), 1) + CIR(95.7, y - 0.6, 0.7, '#FFFFFF', null, 0, op(0.8)); });
        body += each([300, 330, 360, 390], function (y) { return P('M 141.6 ' + y + ' L 145.6 ' + y, null, p.d, 1.4); });
        body += PM('M 64 300 C 66 330, 66 360, 64 396', null, p.s, 3, op(0.8));
      }
      sl += PM('M 47 198 C 36 202, 29 214, 27 232 C 24 262, 21 298, 20.6 324 C 20.4 332, 21 336, 22.4 338 L 58.4 338 C 59.8 322, 61.2 300, 61.6 276 C 62 262, 62 252, 60 244 C 58 226, 55 208, 47 198 Z', p.f, p.l, 2);
      sl += PM('M 23 336.6 L 58.4 336.6 L 57.6 351 L 25.4 351 Z', p.f, p.l, 1.6);
      sl += PM(ribPath(27, 55, 338.6, 349.4, 3.6), null, p.d, 1, op(0.85));
      sl += PM('M 26 300 C 34 304, 46 305, 56 301', null, p.d, 1.1, op(0.7)) + PM('M 24 322 C 34 326, 46 327, 58 323', null, p.d, 1.1, op(0.6)) +
        PM('M 27.6 246 C 26 270, 24 292, 23.6 310', null, p.h, 2.4, op(0.8));
    } else {
      // blazer
      if (back) {
        body += P(sym([[120, 182.5], [110, 182.5, 104, 183.6, 101, 186], [88, 190, 66, 194, 47, 199], [42, 202, 40, 209, 42, 218], [58, 252], [59, 284, 58.5, 318, 58, 348], [57.6, 410], [58, 419, 63.6, 424.6, 72, 427.2], [88, 429.8, 104, 429.6, 120, 429.6]]), p.f, p.l, 2);
        body += P('M 120 184 L 120 394 L 125 399 L 125 429.6', null, p.l, 1.5) + P('M 120 394 L 120 429.6', null, p.l, 1.1, op(0.6));
        body += PM('M 86 232 C 82 290, 81 360, 83 427', null, p.l, 1.1, op(0.5));
        body += P(backNeck(5), p.s, p.l, 1.4);
      } else {
        var bpl = 'M 104 185 C 88 189, 66 193, 47 199 C 42 202, 40 209, 42 218 L 58 252 C 59 284, 58.5 318, 58 348 L 57.6 410 C 58 419, 63.6 424.6, 72 427.2 C 82 429.6, 90 430.8, 97 431.4 C 97.6 400, 98.6 360, 100.2 302 C 101.2 268, 103.4 226, 108 188 C 107 186.4, 105.6 185.4, 104 185 Z';
        body += PM(bpl, p.f, p.l, 2);
        body += PM('M 108 188 C 103.4 226, 101.2 268, 100.2 302 C 100.6 290, 101.6 278, 103 268 C 104.6 240, 106.4 214, 108 188 Z', p.s, null);
        body += PM('M 108 188 C 103.6 226, 101.4 268, 100.2 302 L 83.4 225 L 89 217.6 L 93.6 220.8 C 96 209, 100 196.4, 104.4 186 Z', p.f, p.l, 1.8);
        body += PM('M 93.6 220.8 L 104.2 228.6', null, p.l, 1.2, op(0.8));
        body += PM('M 66 385.6 L 92 387.6 L 91.6 395.4 L 66 393.4 Z', p.f, p.l, 1.4);
        body += P('M 146 266 L 164.4 264 L 164.8 268.6 L 146.4 270.6 Z', p.f, p.l, 1.2);
        body += PM('M 84 236 C 80 300, 79 350, 79.6 384', null, p.l, 1.1, op(0.5));
        body += CIR(97.8, 336, 3, button, p.l, 1) + CIR(97.2, 335.4, 0.8, '#FFFFFF', null, 0, op(0.5)) + P('M 143.4 336 L 148.4 336', null, p.l, 1.5);
        body += PM('M 62 300 C 63 330, 62.4 370, 62 410', null, p.s, 3, op(0.8));
      }
      sl += PM('M 46 198 C 35 202, 28 214, 26 232 C 23 262, 19 300, 18 330 C 17.6 340, 18.4 346, 19.6 349 L 58.2 349 C 59.6 330, 61.2 300, 61.6 276 C 62 262, 62 252, 60 244 C 58 226, 54.4 208, 46 198 Z', p.f, p.l, 2);
      sl += PM('M 19 338 C 32 340.6, 46 340.6, 58.8 338.6', null, p.l, 1.2, op(0.8));
      sl += CM(24, 344, 1.3, button) + CM(28.4, 344.8, 1.3, button) + CM(32.8, 345.2, 1.3, button);
      sl += PM('M 25 250 C 24 280, 21 310, 21 326', null, p.h, 2.4, op(0.8)) + PM('M 30 292 C 38 296, 48 297, 56 294', null, p.l, 1.1, op(0.5));
    }
    return { body: body, sleeves: sl, pocket: pocket };
  }

  /* ------------------------------------------------------------------ bottoms and dress */

  function bottomPiece(c, g, back) {
    var p = gPal(g), k = g.kind, main = '', pocket = '';
    var WB = sym([[120, 317.5], [100, 317, 82, 318, 68, 320], [67, 341], [84, 339, 102, 338.4, 120, 338.4]]);
    if (k === 'skirt') {
      main += P(sym([[120, 317.5], [100, 317, 82, 318, 68, 320], [67, 341], [60, 345, 46, 352, 41, 366], [37.6, 377, 35.6, 392, 35.2, 410], [31, 470, 28, 560, 24, 636], [40, 641, 56, 646, 74, 643], [90, 640, 104, 647, 120, 646]]), p.f, p.l, 2);
      main += PM('M 86 414 C 82 480, 78 560, 74.6 642', null, p.d, 1.4, op(0.85));
      main += PM('M 58 520 C 56 570, 54 610, 52.6 641', null, p.d, 1.2, op(0.6));
      main += P('M 112 560 C 112 590, 111.6 620, 111 646', null, p.d, 1.2, op(0.6));
      main += PM('M 48 500 C 44 560, 42 600, 40 638', null, p.h, 3, op(0.5));
      main += P(WB, p.f, p.l, 1.8);
      if (back) main += P('M 120 338.4 L 120 404', null, p.l, 1.5) + P('M 118 342 L 122 342 L 122 348 L 118 348 Z', '#9A9AA6', p.l, 0.8);
      else main += CIR(150, 329, 2.6, '#9A9AA6', p.l, 1) + PM('M 70 341 L 57.4 366.2', null, p.l, 1.5);
      main += PM('M 26 630 C 42 634, 56 638.6, 74 636', null, p.d, 1, op(0.7));
      pocket += PM(POCKET_FILL, p.f, null) + PM(POCKET_HIP, null, p.l, 2) + PM(POCKET_SLANT, null, p.l, 1.5);
      return { main: main, pocket: pocket };
    }
    var jeans = k === 'jeans';
    var ho = jeans ? 15 : 22, hi = jeans ? 104 : 101;
    main += P(sym([[120, 317.5], [100, 317, 82, 318, 68, 320], [67, 341], [60, 345, 46, 352, 41, 366], [37.6, 377, 35.6, 392, 35.2, 410],
      [33, 470, jeans ? 25 : 28, 640, ho, 800], [ho + 26, 805, hi - 25, 808, hi, 806], [hi + 2, 700, 110, 560, 120, 438]]), p.f, p.l, 2);
    // depth: inner leg shade and outer edge shade
    main += PM('M 120 440 C 110 560, ' + (hi + 2) + ' 700, ' + hi + ' 805 L ' + (hi - 9) + ' 806 C ' + (hi - 6) + ' 700, 104 560, 116.6 448 Z', p.s, null);
    main += PM('M 35.6 416 C 34 450, ' + (jeans ? 26 : 29.4) + ' 640, ' + (ho + 0.8) + ' 798 L ' + (ho + 6) + ' 800 C ' + (jeans ? 32 : 35) + ' 640, 40 460, 42 416 Z', p.s, null, 0, op(0.7));
    main += P(WB, p.f, p.l, 1.8);
    if (jeans) {
      main += PM('M 80 430 C 78 500, 74 580, 68 660', null, p.h, 6, op(0.22));
      main += PM('M 68 337.6 C 84 335.8, 102 335.2, 120 335.2', null, p.d, 1, op(0.9));
      main += PM('M 86 318 L 90.6 317.8 L 91 344.6 L 86.4 344.8 Z', p.f, p.l, 1.3);
      main += PM('M 20 792 C 46 797, 76 799.6, 102 797.6', null, p.d, 1, op(0.9));
      if (!back) {
        main += CIR(124, 328, 3.2, '#C98A49', '#8C5A26', 1.2) + CIR(123.2, 327.2, 0.9, '#F2C88E');
        main += P('M 117.6 339 L 117.6 404', null, p.l, 1.5) + P('M 126 341 L 126 393 C 126 401, 122 405, 117.6 405', null, p.d, 1.2);
        main += P('M 146 343 L 160.4 342 L 161 352.6 L 146.6 353.6 Z', null, p.d, 1.1);
        main += PM('M 70 341 L 57.4 366.2', null, p.l, 1.5) + PM('M 73.6 341.4 L 60.6 367.4', null, p.d, 1, op(0.9));
      } else {
        main += P('M 120 338.4 C 120 380, 118 410, 120 438', null, p.l, 1.5);
        main += PM('M 78 352 L 106 355 L 104.4 386 L 92.4 393 L 80.4 384 Z', null, p.l, 1.3) + PM('M 80 356 L 104.6 358.6', null, p.d, 1, op(0.9));
        main += PM('M 98 330 L 120 334', null, p.d, 1, op(0.7));
      }
    } else {
      main += PM('M 84.6 318 L 89.6 317.8 L 90 344.6 L 85 344.8 Z', p.f, p.l, 1.3);
      main += PM('M 86 396 C 80 520, 72 660, 62 800', null, p.l, 1.2, op(0.55));
      main += PM('M 24 794 C 48 799, 76 801, 100 799', null, p.d, 1, op(0.7));
      if (!back) {
        main += CIR(124, 328, 3, '#B9BCC8', p.l, 1.1) + CIR(123.2, 327.2, 0.8, '#FFFFFF', null, 0, op(0.7));
        main += P('M 117.6 339 L 117.6 406', null, p.l, 1.5) + P('M 126 341 L 126 394 C 126 402, 122 406, 117.6 406', null, p.d, 1.2);
        main += PM('M 93 340 C 92 352, 91 364, 89.4 378', null, p.l, 1.4);
        main += PM('M 70 341 L 57.4 366.2', null, p.l, 1.5);
      } else {
        main += P('M 120 338.4 C 120 380, 118 410, 120 438', null, p.l, 1.5);
        main += PM('M 80 362 L 104 364', null, p.l, 1.8) + CM(92, 367.6, 1.6, p.d);
        main += PM('M 98 330 L 120 334', null, p.d, 1, op(0.7));
      }
    }
    pocket += PM(POCKET_FILL, p.f, null) + PM(POCKET_HIP, null, p.l, 2) + PM(POCKET_SLANT, null, p.l, 1.5);
    return { main: main, pocket: pocket };
  }

  var FLOWERS = [[86, 226], [150, 222], [112, 250], [72, 270], [138, 276], [164, 258], [96, 298], [124, 304], [158, 300],
    [80, 352], [110, 360], [142, 350], [166, 372], [92, 392], [124, 398], [150, 410], [70, 436], [102, 432], [132, 440], [160, 446],
    [56, 470], [86, 474], [118, 478], [148, 480], [180, 470], [64, 516], [96, 520], [130, 514], [162, 522], [190, 512],
    [50, 560], [80, 562], [112, 566], [144, 558], [174, 566], [62, 604], [94, 608], [126, 600], [158, 606], [186, 600], [40, 610], [200, 556]];

  function dressPiece(c, g, back) {
    var p = gPal(g), main = '', pocket = '', sl = '';
    main += P(sym([[120, 320], [100, 320, 82, 320, 66, 322], [60, 345, 46, 352, 41, 366], [37.6, 377, 35.6, 392, 35.2, 410], [31, 470, 26, 570, 22, 646], [36, 652, 52, 648, 66, 653], [80, 658, 96, 651, 108, 656], [112, 657.6, 116, 656, 120, 655.4]]), p.f, p.l, 2);
    main += PM('M 76 330 C 72 420, 64 540, 56 650 M 98 334 C 98 440, 96 560, 94 654', null, p.l, 1.2, op(0.45));
    main += PM('M 28 560 C 26 590, 25 620, 24 640', null, p.s, 4, op(0.8));
    main += P(torsoD(23, back ? 0 : 208, 320, back), p.f, p.l, 2);
    if (!back) main += P(neckBand(23, 208, 3.4).split(' L ')[0], null, p.l, 1, op(0.6));
    else main += P('M 120 184 L 120 320', null, p.l, 1.4) + P('M 118.4 186 L 121.6 186 L 121.6 193 L 118.4 193 Z', '#D9DDE6', p.l, 0.8);
    main += P('M 63.4 320.6 C 84 323.8, 104 324.8, 120 324.8 C 136 324.8, 156 323.8, 176.6 320.6', null, p.l, 1.6);
    main += ribs(70, 170, 327, 334, 6, p.l, 0.9, 0.4);
    main += each(FLOWERS, function (q, i) {
      var x = q[0], y = q[1];
      if (x < 60 && y > 360 && y < 430) return '';
      if (y < 330 && (x < 66 || x > 174)) return '';
      var col = i % 3 === 0 ? '#FFFFFF' : (i % 3 === 1 ? '#FFF4E2' : '#F7D6E0');
      return P('M ' + pt(x + 2.6, y + 2.6) + ' Q ' + pt(x + 8, y + 2.4) + ' ' + pt(x + 9.4, y + 6.6) + ' Q ' + pt(x + 4, y + 7.2) + ' ' + pt(x + 2.6, y + 2.6) + ' Z', p.d, null) +
        CIR(x - 2.5, y - 0.6, 2.1, col) + CIR(x + 2.5, y - 0.6, 2.1, col) + CIR(x - 1.5, y + 2.2, 2.1, col) + CIR(x + 1.5, y + 2.2, 2.1, col) + CIR(x, y - 2.6, 2.1, col) + CIR(x, y + 0.2, 1.3, '#F2C25C');
    });
    if (!back) main += PM('M 70 341 L 57.4 366.2', null, p.l, 1.4);
    sl += PM(SLV.flutter, p.f, p.l, 2);
    sl += PM('M 36 222 C 34 232, 33 242, 34 252', null, p.l, 1, op(0.5)) + PM('M 46 214 C 45 228, 46 242, 47 254', null, p.l, 1, op(0.5));
    sl += each([[40, 236], [mx(40), 236]], function (q) { return CIR(q[0] - 1.6, q[1], 1.5, '#FFFFFF') + CIR(q[0] + 1.6, q[1], 1.5, '#FFFFFF') + CIR(q[0], q[1] - 1.6, 1.5, '#FFFFFF') + CIR(q[0], q[1] + 1.6, 1.5, '#FFFFFF') + CIR(q[0], q[1], 0.9, '#F2C25C'); });
    pocket += PM(POCKET_FILL, p.f, null) + PM(POCKET_HIP, null, p.l, 2) + PM(POCKET_SLANT, null, p.l, 1.4);
    return { main: main, pocket: pocket, sleeves: sl };
  }

  /* ------------------------------------------------------------------ shoes (left foot drawn, right mirrored) */

  function footSkin(c, d) {
    var k = c.skin;
    return PM(d, k.f, null) + PM(d.replace(/ Z$/, ''), null, k.l, 1.8);
  }

  function shoesPiece(c, g, back) {
    var p = gPal(g), k = g.kind, o = '';
    var sole = k === 'sneakers' ? '#EFE5DA' : darken(p.f, lum(p.f) > 0.6 ? 0.22 : 0.18);
    if (back) {
      if (k === 'heels') {
        o += footSkin(c, 'M 62.5 832 C 62.4 838, 62 843, 62 848 L 77.8 848 C 77.8 843, 77.2 838, 76.8 832 Z');
        o += PM('M 63.4 849.6 C 55 849, 44.6 852, 39 856.8 C 35.8 860, 38.4 864.8, 44 864.8 L 61 862.6 Z', p.f, p.l, 1.6);
        o += PM('M 61.2 845 C 59.8 850, 61 855.4, 64.6 857.2 C 67.6 858.6, 72.4 858.6, 75.4 857.2 C 79 855.4, 80.2 850, 78.8 845 C 74.2 847.8, 65.8 847.8, 61.2 845 Z', p.f, p.l, 1.7);
        o += PM('M 62 846.2 C 66.4 848.8, 73.6 848.8, 78 846.2', null, p.s, 1.4);
        o += PM('M 66.4 857.4 L 73.6 857.4 L 73 865 L 67 865 Z', p.s, p.l, 1.4);
        o += PM('M 64 850 C 64.6 853, 66 855, 68 855.6', null, p.h, 1.4, op(0.8));
        return o;
      }
      var T = k === 'sneakers' ? 834 : (k === 'loafers' ? 844 : 846);
      o += footSkin(c, 'M 62.5 832 C 62.4 838, 62 843, 61.8 ' + (T + 2) + ' L 78 ' + (T + 2) + ' C 77.9 843, 77.2 838, 76.8 832 Z');
      if (k === 'sneakers') o += PM('M 64 846 C 55 842.6, 43 843, 37.6 848.4 C 34 852, 35 860, 42 862.6 C 50 865.2, 60 865, 66 863 Z', p.f, p.l, 1.6) +
        PM('M 36.2 856.6 C 44 859.6, 56 860, 65 858.6', null, p.l, 1, op(0.6));
      else o += PM('M 64 849.6 C 56 846.4, 45.4 846.2, 39.8 850.4 C 35.8 853.6, 37.2 859.4, 44 861 C 51 862.6, 59 862.2, 65 860.2 Z', p.f, p.l, 1.6);
      o += PM('M 61.2 ' + T + ' C 59.4 851, 60.6 860, 64.4 863.4 C 66.4 865, 74.4 865, 76.4 863.4 C 80.2 860, 81.4 851, 79.6 ' + T + ' C 74.8 ' + (T + 3) + ', 66 ' + (T + 3) + ', 61.2 ' + T + ' Z', p.f, p.l, 1.8);
      o += PM('M 61.8 ' + (T + 0.9) + ' C 66.2 ' + (T + 3.8) + ', 74.6 ' + (T + 3.8) + ', 79 ' + (T + 0.9), null, p.s, 1.6);
      o += PM('M 63.6 ' + (T + 6) + ' C 63.4 ' + (T + 10) + ', 64 ' + (T + 13) + ', 65.6 ' + (T + 15), null, p.h, 1.5, op(0.85));
      if (k === 'sneakers') {
        o += PM('M 60.4 856.4 C 66 858, 75 858, 80.4 856.4 C 80 860.6, 78 864, 74 865 L 66.6 865 C 62.6 864, 60.8 860.6, 60.4 856.4 Z', sole, p.l, 1.2);
        o += PM('M 66.8 833 L 74 833 L 73.6 843 L 67.2 843 Z', '#F4B4C2', mix('#F4B4C2', p.l, 0.5), 1);
      } else {
        o += PM('M 63 862.4 C 66 864.6, 74.8 864.6, 77.8 862.4', null, k === 'loafers' ? p.l : sole, 2.2);
        if (k === 'loafers') o += PM('M 65.6 860.6 L 75.2 860.6 L 74.8 865 L 66 865 Z', p.s, p.l, 1.2);
      }
      return o;
    }
    if (k === 'sneakers') {
      o += PM('M 81 840 C 84.6 846, 85 854, 82.4 858.4 L 82.4 864.6 L 35 864.6 C 25 864.6, 20 861, 21.4 855.6 C 23 849.6, 31 845.6, 41 843.4 C 47 842, 53 840, 57.6 837.4 C 60 833.4, 63.4 831.4, 66.6 831.2 L 77.6 831.4 C 80 833.2, 81 836.4, 81 840 Z', p.f, p.l, 1.8);
      o += PM('M 64.4 832 C 64.8 827.6, 71.4 826.6, 76.4 828.4 L 77.4 833.2 Z', p.h, p.l, 1.2);
      o += PM('M 21.2 856.8 C 38 857.8, 62 858.4, 82.4 858.6 L 82.4 864.6 L 35 864.6 C 26.6 864.6, 21 861.4, 21.2 856.8 Z', sole, p.l, 1.3);
      o += PM('M 24.4 861.2 C 42 861.8, 64 862, 82 862', null, p.l, 0.8, op(0.55));
      o += PM('M 40 844 C 32.6 846.6, 27.6 851, 27.4 856.2', null, p.l, 1.1, op(0.7));
      o += PM('M 66.6 835 L 58 844.6 M 77 836 L 70.4 846.8', null, p.s, 2.8);
      o += PM('M 65.4 837 L 75.2 838.6 M 62.8 840.2 L 73 842.2 M 60 843.4 L 71 846', null, p.l, 1.2);
      o += PM('M 30.6 850.6 C 35 847.6, 41.6 846, 48 845.2', null, '#FFFFFF', 1.8, op(0.95));
      o += PM('M 79.4 834.4 L 82.6 838.6', null, '#F4B4C2', 2.4);
      return o;
    }
    if (k === 'heels') {
      o += footSkin(c, 'M 62.5 830 C 62.5 836, 62 841, 59.4 844.8 C 53 847.6, 45 850.2, 39 852.6 L 66 853.4 L 78.6 848.6 C 78 842, 77.2 836, 76.8 830 Z');
      o += PM('M 73.6 856.6 L 81.4 854.2 L 81.8 865 L 74.4 865 Z', p.s, p.l, 1.4);
      o += PM('M 79.6 844.6 C 82.2 848, 82.2 852, 80.2 854.6 L 75 857 C 66 859.6, 55 862.4, 44 864.4 C 35 866, 25.4 865.2, 23 861.6 C 21.4 858.6, 24.8 855.2, 31 852.8 C 38 850.4, 47 849.6, 56 850.4 C 64 851, 72 849.4, 79.6 844.6 Z', p.f, p.l, 1.8);
      o += PM('M 28.4 857.6 C 35 854.6, 44 853.2, 51 853.2', null, p.h, 1.7, op(0.95));
      o += PM('M 78.8 848 C 72 851.4, 63 853.2, 55 852.8', null, p.s, 1.4, op(0.9));
      return o;
    }
    if (k === 'loafers') {
      o += footSkin(c, 'M 62.5 832 C 62.5 837, 62.2 840.6, 61 843 L 79.8 844.6 C 78.6 841, 77.4 837, 76.8 832 Z');
      o += PM('M 80.8 843.6 C 84.8 849.4, 84.4 860, 78 863.6 C 72 865.4, 54 865.6, 42 865 C 30 864.4, 21.6 860.4, 23.2 853.6 C 24.8 846.6, 34 841.4, 46 840.2 C 52 839.6, 57.6 840.4, 61.4 842 C 65.8 845, 73.6 846, 80.8 843.6 Z', p.f, p.l, 1.8);
      o += PM('M 83.4 857 C 82 861.4, 79 863.6, 74 864.4 C 62 865.6, 50 865.6, 41 865 C 31 864.4, 24.6 861.6, 23.4 857.2', null, p.l, 2.6);
      o += PM('M 43.6 842.6 C 50 846.6, 57.6 847.4, 63.6 845.4 L 64.8 850 C 58 852, 49.6 851.2, 42 847.6 Z', p.s, p.l, 1.2);
      o += PM('M 50.4 847.4 L 56.4 848', null, p.l, 1.7);
      o += PM('M 27.4 853.6 C 31 847.6, 37.6 844.6, 43.6 843.6', null, p.l, 1, op(0.7));
      o += PM('M 29.6 855.4 C 33 852, 38 850, 43 849.4', null, p.h, 1.5, op(0.8));
      o += PM('M 74 863.8 L 83 861.4 L 82.6 865 L 74.4 865.2 Z', p.l, null);
      return o;
    }
    // flats: nude pointed flats with a tiny bow
    o += footSkin(c, 'M 62.5 832 C 62.5 838, 62 842, 60.6 845 L 79.6 847 C 78.2 843, 77.2 838, 76.8 832 Z');
    o += PM('M 80.6 845.6 C 84.6 851, 84 860.6, 77.6 863.8 C 72 865.4, 54 865.6, 42 865 C 32 864.4, 22.4 861.8, 21.2 857 C 20.4 852.6, 26.6 847.6, 35 844 C 41 841.6, 47 840.4, 52 840.4 C 56 840.4, 59 841.2, 61.2 843 C 65.6 846.6, 73.6 847.8, 80.6 845.6 Z', p.f, p.l, 1.8);
    o += PM('M 83.2 857.6 C 82 861.6, 79 863.6, 74 864.4 C 62 865.6, 50 865.6, 41 865 C 31 864.4, 23.6 862, 21.8 858.4', null, sole, 2.4);
    o += PM('M 62.6 844.6 C 67 847.8, 74 848.8, 80.2 847', null, p.s, 1.6);
    o += PM('M 50.6 843.6 C 47 839.8, 43.6 840.6, 44.6 843.6 C 45.4 845.6, 48.6 845.2, 50.6 843.6 Z M 50.6 843.6 C 54.2 840.2, 58 840.8, 57 843.8 C 56.2 845.8, 53 845.2, 50.6 843.6 Z', p.h, p.l, 1);
    o += PM('M 50.2 844 L 48 847.8 M 51 844 L 53.4 847.6', null, p.l, 1);
    o += CM(50.6, 843.8, 1.3, p.l);
    o += PM('M 27.6 852.4 C 32 848.6, 38 846.4, 43 845.6', null, p.h, 1.8, op(0.95));
    return o;
  }

  /* ------------------------------------------------------------------ normalising */

  function extend(a, b) { var o = {}, k; for (k in a) if (Object.prototype.hasOwnProperty.call(a, k)) o[k] = a[k]; if (b) for (k in b) if (Object.prototype.hasOwnProperty.call(b, k)) o[k] = b[k]; return o; }

  var KEYS = { skin: 'skin', hairStyle: 'hairStyle', hairColor: 'hairColor', eyes: 'eyes', glasses: 'glasses', earrings: 'earrings', lips: 'lips' };
  function normAppearance(x) {
    var out = extend(DEFAULTS);
    if (x && typeof x === 'object') {
      for (var k in KEYS) {
        if (x[k] != null && findOpt(OPTIONS[k], String(x[k]))) out[k] = String(x[k]);
      }
    }
    return out;
  }
  function slotGarment(slot, id) {
    var g = id ? GARMENTS[id] : null;
    if (g && g.cat === SLOT_CAT[slot]) return id;
    return DEFAULT_OUTFIT[slot];
  }
  function normOutfit(x) {
    var o = extend(DEFAULT_OUTFIT);
    if (x && typeof x === 'object') {
      ['top', 'bottom', 'shoes', 'layer', 'dress'].forEach(function (s) {
        if (x[s] !== undefined) o[s] = (x[s] === null || x[s] === '') ? DEFAULT_OUTFIT[s] : slotGarment(s, String(x[s]));
      });
    }
    ['top', 'bottom', 'shoes'].forEach(function (s) { if (!o[s] || !GARMENTS[o[s]]) o[s] = DEFAULT_OUTFIT[s]; });
    if (o.layer && !GARMENTS[o.layer]) o.layer = null;
    if (o.dress && !GARMENTS[o.dress]) o.dress = null;
    return o;
  }

  /* ------------------------------------------------------------------ composition */

  var counter = 0;

  function compose(a, o, view, uid) {
    var c = makeCtx(a, uid);
    var hair = HAIR[a.hairStyle] || HAIR['wavy-bob'];
    var full = view !== 'bust', back = view === 'back';
    var dress = o.dress ? dressPiece(c, GARMENTS[o.dress], back) : null;
    var bottom = !dress && full ? bottomPiece(c, GARMENTS[o.bottom], back) : null;
    var top = dress ? null : topPiece(c, GARMENTS[o.top], back);
    var layer = o.layer ? layerPiece(c, GARMENTS[o.layer], back) : null;
    var s = [];
    if (full) s.push(ELL(120, 864, 98, 7.5, '#C48F7E', op(0.14)));
    if (!back) s.push('<g transform="rotate(2 120 166)">' + hair.back(c) + '</g>');
    s.push(bodySkin(c, full));
    if (back) s.push(P('M 105 138 L 135 138 L 135 186 L 105 186 Z', c.skin.f, null));
    if (dress) s.push(dress.main);
    else if (bottom) s.push(bottom.main);
    if (full) s.push(shoesPiece(c, GARMENTS[o.shoes], back));
    if (top) s.push(top.body);
    if (layer) s.push(layer.body);
    if (full) {
      s.push(handsSkin(c));
      s.push(layer && layer.pocket ? layer.pocket : (dress ? dress.pocket : bottom.pocket));
    }
    if (!layer) s.push(dress ? dress.sleeves : top.sleeves);
    else s.push(layer.sleeves);
    if (back) {
      s.push(PM(EAR, c.skin.f, c.skin.l, 1.8));
      s.push(P(FACE, c.skin.f, c.skin.l, 2));
      s.push(hair.rear(c));
      if (a.hairStyle === 'high-bun' || a.hairStyle === 'ponytail') s.push(earrings(c, true));
    } else {
      s.push('<g transform="rotate(2 120 166)">' + headSkin(c) + faceFeatures(c) + hair.front(c) + earrings(c) + glasses(c) + '</g>');
    }
    return { defs: c.defs.join(''), body: s.join('') };
  }

  function svg(appearance, outfit, opts) {
    var view = opts && opts.view;
    if (view !== 'bust' && view !== 'back') view = 'full';
    var a = normAppearance(appearance), o = normOutfit(outfit);
    var uid = 'mpsav' + (++counter);
    var out;
    try { out = compose(a, o, view, uid); }
    catch (e) { out = compose(extend(DEFAULTS), extend(DEFAULT_OUTFIT), view, uid); }
    var vb = view === 'bust' ? '0 0 240 260' : '0 0 240 880';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + vb + '" width="100%" height="100%" preserveAspectRatio="xMidYMax meet"' +
      ' role="img" aria-label="Illustrated avatar" data-view="' + view + '" focusable="false">' +
      (out.defs ? '<defs>' + out.defs + '</defs>' : '') + out.body + '</svg>';
  }

  /* ------------------------------------------------------------------ state, storage, sync */

  var mem = null;
  var listeners = [];
  var channel = null;

  function readStore() {
    try {
      var raw = global.localStorage ? global.localStorage.getItem(KEY) : null;
      if (raw) return JSON.parse(raw);
    } catch (e) { /* storage blocked or bad JSON */ }
    return null;
  }
  function writeStore(v) {
    try { if (global.localStorage) global.localStorage.setItem(KEY, JSON.stringify(v)); } catch (e) { /* ignore */ }
  }
  function clearStore() {
    try { if (global.localStorage) global.localStorage.removeItem(KEY); } catch (e) { /* ignore */ }
  }
  function get() { return normAppearance(readStore() || mem || DEFAULTS); }

  function notify(v) {
    for (var i = 0; i < listeners.length; i++) {
      try { listeners[i](extend(v)); } catch (e) { /* a listener error must not stop the rest */ }
    }
  }
  function broadcast(v) {
    try { if (channel) channel.postMessage({ type: 'avatar', value: v }); } catch (e) { /* ignore */ }
  }
  function refreshAll() {
    if (typeof document === 'undefined') return;
    mountAll(document);
  }
  function set(patch) {
    var next = normAppearance(extend(get(), patch || {}));
    mem = next;
    writeStore(next);
    refreshAll();
    notify(next);
    broadcast(next);
    return extend(next);
  }
  function reset() {
    mem = extend(DEFAULTS);
    clearStore();
    refreshAll();
    notify(mem);
    broadcast(mem);
    return extend(mem);
  }
  function onChange(fn) {
    if (typeof fn !== 'function') return function () {};
    listeners.push(fn);
    return function () { var i = listeners.indexOf(fn); if (i >= 0) listeners.splice(i, 1); };
  }

  var ATTR_APPEARANCE = { skin: 'skin', hairStyle: 'hairStyle', hairColor: 'hairColor', eyes: 'eyes', glasses: 'glasses', earrings: 'earrings', lips: 'lips' };
  function renderEl(el) {
    var ds = el.dataset || {};
    var app = get();
    for (var k in ATTR_APPEARANCE) if (ds[k]) app[k] = ds[k];
    var outfit = {};
    ['top', 'layer', 'bottom', 'dress', 'shoes'].forEach(function (s) { if (ds[s] !== undefined) outfit[s] = ds[s] || null; });
    el.innerHTML = svg(app, outfit, { view: ds.view || 'full' });
  }
  function mountAll(root) {
    if (typeof document === 'undefined') return;
    root = root || document;
    var list = [];
    if (root.nodeType === 1 && root.hasAttribute('data-avatar')) list.push(root);
    if (root.querySelectorAll) {
      var q = root.querySelectorAll('[data-avatar]');
      for (var i = 0; i < q.length; i++) list.push(q[i]);
    }
    for (var j = 0; j < list.length; j++) {
      try { renderEl(list[j]); } catch (e) { /* one bad element must not stop the rest */ }
    }
  }

  if (typeof global.addEventListener === 'function') {
    global.addEventListener('storage', function (e) {
      if (e && e.key !== null && e.key !== KEY) return;
      mem = null;
      refreshAll();
      notify(get());
    });
  }
  try {
    if (typeof global.BroadcastChannel === 'function') {
      channel = new global.BroadcastChannel(CHANNEL);
      channel.onmessage = function (e) {
        if (e && e.data && e.data.value) mem = normAppearance(e.data.value);
        refreshAll();
        notify(get());
      };
    }
  } catch (e) { channel = null; }

  global.Avatar = {
    OPTIONS: OPTIONS,
    DEFAULTS: DEFAULTS,
    DEFAULT_OUTFIT: DEFAULT_OUTFIT,
    get: get,
    set: set,
    reset: reset,
    onChange: onChange,
    svg: svg,
    mountAll: mountAll
  };

  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
    else mountAll(document);
  }
})(typeof window !== 'undefined' ? window : this);
