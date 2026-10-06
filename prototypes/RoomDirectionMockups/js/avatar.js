/* avatar.js: the illustrated person in the room, shared by every screen.
   Contract: STYLE.md, section "js/avatar.js". Built on attempt a, with the face, curly hair,
   ponytail, pearl studs and garment details grafted from attempts b and c.

   Markup:  <div data-avatar data-view="portrait|bust|full|back"
                 data-preset data-face-shape
                 data-top data-layer data-bottom data-dress data-shoes
                 data-skin data-hair-style data-hair-color data-eyes
                 data-glasses data-earrings data-lips></div>
   API:     window.Avatar = { OPTIONS, PRESETS, DEFAULTS, DEFAULT_OUTFIT, get, set, reset, onChange, svg, mountAll }

   Revision 2 (STYLE.md, "Revision 2: portrait, not avatar"): screens show only the 'portrait'
   view (head and shoulders, plain neutral top, viewBox 0 0 240 260; 'bust' is an alias).
   PRESETS p1..p6 are the six choices; OPTIONS.faceShape is slim, medium or round. The
   appearance gains preset (default p3) and faceShape (default medium); set({preset}) applies
   that preset's fields, set({faceShape}) changes only the face shape. Full and back views and
   the outfit attributes remain for older pages, but no screen may use them.

   Drawing: one viewBox unit is one CSS px when the full view is shown 240 px wide.
   Full and back views use viewBox 0 0 240 880 (feet on y = 864, head top near y = 20);
   the bust view uses 0 0 240 260. Every part is a function that returns SVG markup,
   stacked back to front:
     back hair, body and skin (seen from behind, forearms that swing forward behind the hips),
     bottom (or dress), shoes, top and waistband (a tucked top goes under the waistband and
     blouses over it, an untucked one covers it), layer, hands (clipped to the pocket line),
     sleeves, pocket front, ponytail, neck and head, face, front hair, earrings and glasses.
   Hands: with no layer they slip into the slant pockets of the bottom or dress; under a
   layer the sleeve is clipped along the layer's own pocket line, so the cuff runs straight
   into a jacket welt or cardigan patch pocket and nothing shows between cuff and pocket.
   Shade and outline tones come from each base colour through darken/lighten, so any
   skin, hair or garment colour gets matching tones. Outlines are never black; main
   contours are 1.5 units and detail lines 1.2 or less.
   Closet pieces without a cut of their own borrow the nearest one in their own colour:
   brown jacket uses the blazer cut, cream crop the lace cut (cropped), gray leggings a slim leg.
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
      { id: 'black',      label: 'Black',      color: '#3A3036' },
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
    ],
    faceShape: [
      { id: 'slim',   label: 'Slim' },
      { id: 'medium', label: 'Medium' },
      { id: 'round',  label: 'Round' }
    ]
  };

  var DEFAULTS = {
    skin: 's3', hairStyle: 'wavy-bob', hairColor: 'chestnut', eyes: 'brown',
    glasses: 'none', earrings: 'hoops', lips: 'rose',
    preset: 'p3', faceShape: 'medium'
  };

  /* Revision 2: six ready-made portraits. Together they cover all six skin tones and a spread
     of hair styles and colours. p3 is the original default. Labels are short captions. */
  var PRESET_FIELDS = ['skin', 'hairStyle', 'hairColor', 'eyes', 'glasses', 'earrings', 'lips'];
  var PRESETS = [
    { id: 'p1', label: 'Long blonde',     skin: 's1', hairStyle: 'long-straight', hairColor: 'blonde',     eyes: 'blue',  glasses: 'none',    earrings: 'studs', lips: 'rose'  },
    { id: 'p2', label: 'Auburn ponytail', skin: 's2', hairStyle: 'ponytail',      hairColor: 'auburn',     eyes: 'green', glasses: 'none',    earrings: 'hoops', lips: 'coral' },
    { id: 'p3', label: 'Chestnut bob',    skin: 's3', hairStyle: 'wavy-bob',      hairColor: 'chestnut',   eyes: 'brown', glasses: 'none',    earrings: 'hoops', lips: 'rose'  },
    { id: 'p4', label: 'Black waves',     skin: 's4', hairStyle: 'long-waves',    hairColor: 'black',      eyes: 'hazel', glasses: 'cat-eye', earrings: 'studs', lips: 'berry' },
    { id: 'p5', label: 'Silver bun',      skin: 's5', hairStyle: 'high-bun',      hairColor: 'silver',     eyes: 'brown', glasses: 'round',   earrings: 'studs', lips: 'coral' },
    { id: 'p6', label: 'Dark curls',      skin: 's6', hairStyle: 'curly',         hairColor: 'dark-brown', eyes: 'brown', glasses: 'none',    earrings: 'hoops', lips: 'berry' }
  ];
  function presetById(id) { for (var i = 0; i < PRESETS.length; i++) if (PRESETS[i].id === id) return PRESETS[i]; return null; }
  // The preset a set of fields belongs to: an exact match, else the closest one (p3 on a tie).
  function inferPreset(a) {
    var best = 'p3', bestN = -1;
    for (var i = 0; i < PRESETS.length; i++) {
      var n = 0;
      for (var j = 0; j < PRESET_FIELDS.length; j++) if (PRESETS[i][PRESET_FIELDS[j]] === a[PRESET_FIELDS[j]]) n++;
      if (n > bestN || (n === bestN && PRESETS[i].id === 'p3')) { best = PRESETS[i].id; bestN = n; }
    }
    return best;
  }
  function applyPreset(out, id) {
    var p = presetById(id);
    if (!p) return out;
    for (var j = 0; j < PRESET_FIELDS.length; j++) out[PRESET_FIELDS[j]] = p[PRESET_FIELDS[j]];
    out.preset = id;
    return out;
  }

  var DEFAULT_OUTFIT = {
    top: 'g-pink-blouse', bottom: 'g-navy-trousers', shoes: 'g-nude-flats', layer: null, dress: null
  };

  /* Worn garments. kind picks the drawing; f is the main colour (same as js/garments.js).
     s, h, l, d override the derived shade, highlight, outline and detail tones. */
  var GARMENTS = {
    'g-pink-blouse':    { cat: 'top',    kind: 'blouse',   tucked: true, f: '#F4B4C2', s: '#EC9DB0', h: '#FBD0D9', l: '#D97F97' },
    'g-cream-sweater':  { cat: 'top',    kind: 'sweater',  f: '#FFF3E0', s: '#F1DEBF', h: '#FFFCF6', l: '#C9A676', d: '#DDBE92' },
    'g-lace-top':       { cat: 'top',    kind: 'lace',     f: '#FFFDF8', s: '#F0E7D6', h: '#FFFFFF', l: '#C6AA80', d: '#D8C3A0' },
    'g-cream-crop':     { cat: 'top',    kind: 'lace',     crop: true, f: '#F8ECD8', s: '#EEDCC0', h: '#FFF8EC', l: '#C3A37A', d: '#D3B88F' },
    'g-brick-top':      { cat: 'top',    kind: 'knit',     f: '#B5533C', s: '#9E4531', h: '#C76A53', l: '#7D3424', d: '#9A432F' },
    'g-black-tee':      { cat: 'top',    kind: 'tee',      tucked: true, f: '#2E2A30', s: '#242026', h: '#47414B', l: '#17141A', d: '#4E4855' },
    'g-gray-blazer':    { cat: 'layer',  kind: 'blazer',   f: '#A9ABB3', s: '#9799A3', h: '#C0C2C9', l: '#6F727F', d: '#868895' },
    'g-brown-jacket':   { cat: 'layer',  kind: 'blazer',   f: '#7A4B2E', s: '#683F26', h: '#93603F', l: '#4A2C19', d: '#5E3A23' },
    'g-navy-cardigan':  { cat: 'layer',  kind: 'cardigan', f: '#27335F', s: '#1F2950', h: '#36447A', l: '#151C38', d: '#4A5891' },
    'g-camel-trench':   { cat: 'layer',  kind: 'trench',   f: '#C9A06A', s: '#B88D58', h: '#DDB986', l: '#8F6A3C', d: '#A9844F' },
    'g-navy-trousers':  { cat: 'bottom', kind: 'trousers', f: '#27335F', s: '#1F2950', h: '#34427A', l: '#151C38', d: '#46558E' },
    'g-olive-trousers': { cat: 'bottom', kind: 'tapered',  f: '#7C8450', s: '#6B7244', h: '#939B64', l: '#4E5430', d: '#5F663B' },
    'g-gray-leggings':  { cat: 'bottom', kind: 'leggings', f: '#8E9098', s: '#7D7F88', h: '#A3A5AC', l: '#5C5E68', d: '#70727B' },
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
      s: darken(hex, 0.08, 1.5),
      d: darken(hex, 0.17, 4),
      l: darken(hex, L > 0.5 ? 0.3 : 0.36, 5),
      h: lighten(hex, 0.35),
      blush: L > 0.6 ? '#F28A90' : mix('#D65F6C', hex, 0.2),
      blushOp: L > 0.6 ? 0.34 : 0.42
    };
  }
  // Hair outline stays a soft mid-dark of the fill (about the weight of the skin outline),
  // never near-black; strands are a touch darker than the outline so they still read.
  function hairPal(hex) {
    var L = lum(hex), light = L > 0.55;
    return {
      f: hex,
      s: darken(hex, light ? 0.15 : 0.2),
      l: darken(hex, light ? 0.3 : (L < 0.25 ? 0.2 : 0.24)),
      st: darken(hex, light ? 0.34 : (L < 0.25 ? 0.24 : 0.3)),
      h: lighten(hex, light ? 0.42 : (L < 0.22 ? 0.13 : 0.2)),
      brow: darken(hex, light ? 0.42 : 0.28),
      lash: mix(darken(hex, 0.55), '#2B1A16', light ? 0.6 : 0.75),
      sw: lighten(hex, L < 0.25 ? 0.3 : (light ? 0.5 : 0.26)),
      dark: L < 0.25
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
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 1.5) + '" stroke-linejoin="round" stroke-linecap="round"' : '') +
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

  // Catmull-Rom curve through points, written as cubic Beziers. A point [x, y, 1] is a corner.
  function SM(pts, closed) {
    var n = pts.length;
    if (n < 2) return '';
    var t = 1 / 6;
    function g(i) { return closed ? pts[((i % n) + n) % n] : pts[Math.max(0, Math.min(n - 1, i))]; }
    var d = 'M ' + pt(pts[0][0], pts[0][1]);
    var segs = closed ? n : n - 1;
    for (var i = 0; i < segs; i++) {
      var p0 = g(i - 1), p1 = g(i), p2 = g(i + 1), p3 = g(i + 2);
      var c1x = p1[2] ? p1[0] : p1[0] + (p2[0] - p0[0]) * t, c1y = p1[2] ? p1[1] : p1[1] + (p2[1] - p0[1]) * t;
      var c2x = p2[2] ? p2[0] : p2[0] - (p3[0] - p1[0]) * t, c2y = p2[2] ? p2[1] : p2[1] - (p3[1] - p1[1]) * t;
      d += ' C ' + pt(c1x, c1y) + ' ' + pt(c2x, c2y) + ' ' + pt(p2[0], p2[1]);
    }
    return d + (closed ? ' Z' : '');
  }
  // Soft scalloped edge: one quadratic bump per segment, bulging to the left of travel
  // (outward on a clockwise outline). A point's third value sets the bump of its segment.
  function BUMPY(pts, amp, closed, cont) {
    var n = pts.length, d = cont ? '' : 'M ' + pt(pts[0][0], pts[0][1]);
    var segs = closed ? n : n - 1;
    for (var i = 0; i < segs; i++) {
      var a = pts[i], b = pts[(i + 1) % n];
      var dx = b[0] - a[0], dy = b[1] - a[1], m = Math.sqrt(dx * dx + dy * dy) || 1;
      var am = (a[2] != null) ? a[2] : amp;
      d += ' Q ' + pt((a[0] + b[0]) / 2 + dy / m * am * 2, (a[1] + b[1]) / 2 - dx / m * am * 2) + ' ' + pt(b[0], b[1]);
    }
    return d + (closed ? ' Z' : '');
  }


  /* ------------------------------------------------------------------ body geometry (left side; right is mirrored) */

  var CHEST = 'M 105 136 C 106 152, 106 166, 105 178 C 103 186, 96 190, 84 193 C 70 196, 56 200, 48 206 L 50 262 L 190 262 L 192 206 C 184 200, 170 196, 156 193 C 144 190, 137 186, 135 178 C 134 166, 134 152, 135 136 Z';
  var ARM = 'M 50 202 C 39 206, 32 219, 31 236 C 30 256, 28.5 274, 28.5 290 C 28.5 310, 31.5 332, 34.5 350 L 50.5 350 C 51.5 334, 54 312, 55 292 C 56 276, 58 262, 60 248 L 58 214 Z';
  // The forearm angles in a little toward the pocket, so the hand meets the slant at the hip.
  var HAND_EDGE = 'M 34.2 344 C 34 358, 35.6 372, 38.6 384 C 41 393, 45.6 399.6, 51.4 400.4 C 56.6 401, 59 395, 58.4 385 C 57.6 373, 54.2 357, 51.8 344';
  var HAND = HAND_EDGE + ' Z';
  // Seen from behind, the forearm swings forward and the hand disappears behind the hip.
  var FOREARM_BACK_EDGE = 'M 34.2 344 C 34.4 358, 37.2 372, 42.6 384 C 45.6 390, 50 395, 56 396 L 64 386 C 59 376, 55 360, 51.8 344';
  var FOREARM_BACK = FOREARM_BACK_EDGE + ' Z';
  var LEG = 'M 44 398 C 49 470, 56 560, 60 625 C 61.5 648, 55 670, 55.6 700 C 56.6 752, 61.6 800, 62.5 840 L 76.8 840 C 77 800, 80 760, 83 722 C 87 692, 88 660, 82.5 630 C 86 590, 100 520, 120 438 L 120 398 Z';
  // An oval face, a little narrower than wide-round, with a soft tapered chin.
  var FACE = 'M 120 44 C 146.6 44, 165.4 62, 166.4 94 C 167.2 112, 162 126, 152.6 138 C 143 149.6, 129 160, 120 160 C 111 160, 97 149.6, 87.4 138 C 78 126, 72.8 112, 73.6 94 C 74.6 62, 93.4 44, 120 44 Z';
  var EAR = 'M 78.2 100 C 71.2 94.5, 63.7 100, 64.2 110 C 64.7 119.5, 69.7 126.5, 77.7 126 Z';
  var EAR_IN = 'M 73.7 104 C 69.2 104.5, 67.7 110, 69.7 116 C 70.7 118.5, 72.7 119.5, 73.7 118';
  var EAR_X = 70.6;   // earlobe centre, for earrings

  // Map the x values of an absolute path (M L C S Q T H V Z) through fx; y values are kept.
  function mapX(d, fx) {
    var tok = String(d).match(/[A-Za-z]|-?\d*\.?\d+(?:e[-+]?\d+)?/g) || [];
    var out = [], cmd = '', n = 0;
    for (var i = 0; i < tok.length; i++) {
      var t = tok[i];
      if (/[A-Za-z]/.test(t)) { cmd = t.toUpperCase(); out.push(cmd); n = 0; continue; }
      var v = parseFloat(t);
      if (cmd === 'H' || (cmd !== 'V' && n % 2 === 0)) v = r2(fx(v));
      out.push(v); n++;
    }
    return out.join(' ');
  }

  /* Face shapes (Revision 2). Medium is the original face. Slim is a little narrower with a
     slightly longer taper. Round is a fuller face: wider cheeks, a fuller jaw that turns lower,
     a soft wide chin, and (in the portrait) a fuller neck and shoulders. The eyes, nose and
     mouth stay put; the ears, earrings, blush and glasses temples follow the face edge, and the
     hair is widened or narrowed a touch so it still frames the face. */
  var SHAPES = {
    slim: {
      face: 'M 120 45 C 144.6 45, 161.4 62.6, 162.2 93.6 C 162.8 111, 158 125, 149.4 137.6 C 140.6 149.8, 128 160, 120 160 C 112 160, 99.4 149.8, 90.6 137.6 C 82 125, 77.2 111, 77.8 93.6 C 78.6 62.6, 95.4 45, 120 45 Z',
      earDx: 3.6, hairSx: 0.965, blush: [94.4, 120, 9.2, 5.3], jaw: [13.6, 146.4, 165],
      neck: 13.4, bodySx: 0.95
    },
    medium: {
      face: FACE,
      earDx: 0, hairSx: 1, blush: [92, 119.4, 10, 5.8], jaw: [15.4, 146, 165.6],
      neck: 15, bodySx: 1
    },
    round: {
      face: 'M 120 44 C 149 44, 170.6 62, 171.6 97 C 172.2 117, 169.4 133, 161.4 144.6 C 152 157.4, 134.6 164, 120 164 C 105.4 164, 88 157.4, 78.6 144.6 C 70.6 133, 67.8 117, 68.4 97 C 69.4 62, 91 44, 120 44 Z',
      earDx: -4.6, hairSx: 1.06, blush: [88.6, 122, 12.2, 7], jaw: [19, 152, 170],
      neck: 19, bodySx: 1.1
    }
  };
  function shapeOf(id) { return SHAPES[id] || SHAPES.medium; }
  function earD(c, d) { var dx = c.shape.earDx; return dx ? mapX(d, function (x) { return x + dx; }) : d; }
  // horizontal scale about the centre line, for hair and the portrait shoulders
  function sx(k, inner) { return k === 1 ? inner : '<g transform="matrix(' + k + ' 0 0 1 ' + r2(120 * (1 - k)) + ' 0)">' + inner + '</g>'; }

  // Front slant pocket shared by every bottom and the dress. The opening runs from the
  // waistband corner (76.6, 341) to the hip (39.5, 406). The hand is clipped to the side of
  // the line it enters from, so the garment under it is never repainted (no seams, no notch).
  var POCKET_UPPER = 'M 76.6 341 L 61.2 368';
  var POCKET_LOWER = 'M 61.2 368 L 39.5 406';
  // everything up and out from the slant line, both sides
  var HAND_CLIP = 'M 0 0 L 120 0 L 120 265 L 8.7 460 L 0 460 Z M 240 0 L 120 0 L 120 265 L 231.3 460 L 240 460 Z';

  // Layer (jacket, cardigan, trench) hand pocket. Line y = 404 - (x - 37.8) * 0.7752 from the
  // jacket side (37.8, 404) up to (63.6, 384). The layer sleeve is clipped along the same line,
  // so the cuff runs straight into the pocket and no wrist, cuff or bottom fabric shows below it.
  function lineY(x) { return 404 - (x - 37.8) * 0.7752; }
  var LP_A = [37.8, 404], LP_B = [63.6, 384];
  var SLEEVE_CLIP = 'M 0 0 L 120 0 L 120 ' + r2(lineY(120)) + ' L 0 ' + r2(lineY(0)) + ' Z M 240 0 L 120 0 L 120 ' + r2(lineY(120)) + ' L 240 ' + r2(lineY(0)) + ' Z';

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
      lip: findOpt(OPTIONS.lips, a.lips).color,
      shape: shapeOf(a.faceShape)
    };
  }

  /* ------------------------------------------------------------------ body and skin */

  function bodySkin(c, withLegs) {
    var k = c.skin, o = '';
    if (withLegs) {
      o += PM(LEG, k.f, k.l, 1.5);
      o += PM('M 66 631 Q 71 634.5 76 632', null, k.d, 1.2);
      o += PM('M 63 760 C 63.5 780, 64.5 800, 65 820', null, k.s, 3, op(0.7));
    }
    o += PM(ARM, k.f, k.l, 1.5);
    o += PM('M 44 289 Q 48 292.5 52 291', null, k.d, 1.2);
    o += P(CHEST, k.f, k.l, 1.5);
    o += PM('M 101 199.5 C 96 202, 90 202.4, 85 201.4', null, k.d, 1.2, op(0.7));
    return o;
  }

  function handsSkin(c) {
    var k = c.skin;
    return PM(HAND, k.f, null) + PM(HAND_EDGE, null, k.l, 1.5) +
      PM('M 49.4 358 C 52.6 361.6, 54.4 365.6, 54.2 370.4', null, k.d, 1.2) +
      PM('M 36.2 352 C 40.4 353.5, 46.4 353.5, 51 352', null, k.s, 1.6, op(0.8));
  }
  // back view: the forearm angles forward; its end is hidden under the trousers or skirt
  function forearmsBack(c) {
    var k = c.skin;
    return PM(FOREARM_BACK, k.f, null) + PM(FOREARM_BACK_EDGE, null, k.l, 1.5) +
      PM('M 36.2 352 C 40.4 353.5, 46.4 353.5, 51 352', null, k.s, 1.6, op(0.8)) +
      PM('M 46.6 360 C 48.6 366, 49 372, 47.6 378', null, k.d, 1.1, op(0.6));
  }

  function headSkin(c) {
    var k = c.skin, o = '';
    // soft crescent shadow under the jaw, tapering to a point at each side of the neck
    var j = c.shape.jaw, w = j[0], yt = j[1], yb = j[2];
    o += P('M ' + pt(120 - w, yt) + ' C ' + pt(125.4 - w, yt + 10.6) + ' ' + pt(114.6 + w, yt + 10.6) + ' ' + pt(120 + w, yt) +
      ' C ' + pt(117 + w, yb - 7) + ' ' + pt(126.4, yb) + ' ' + pt(120, yb) + ' C ' + pt(113.6, yb) + ' ' + pt(123 - w, yb - 7) + ' ' + pt(120 - w, yt) + ' Z',
      mix(k.f, k.l, 0.26), null);
    o += PM(earD(c, EAR), k.f, k.l, 1.5) + PM(earD(c, EAR_IN), null, k.l, 1.2, op(0.65));
    o += P(c.shape.face, k.f, k.l, 1.5);
    return o;
  }

  // Eye parts are drawn for the right eye (+x points outward) and mirrored for the left.
  var EYE_CX = 140, EYE_CY = 100, EYE_S = 1.12;
  function eyePts(arr) { return arr.map(function (p) { return [EYE_CX + p[0] * EYE_S, EYE_CY + p[1] * EYE_S, p[2]]; }); }
  var EYE_WHITE = SM(eyePts([[11.6, 0.8], [7.4, -4.9], [0.6, -7.2], [-6.6, -6.1], [-11.2, -0.9], [-7.8, 4.7], [-0.4, 6.9], [6.8, 5.3]]), true);
  var EYE_LID = SM(eyePts([[16.2, -4.8, 1], [12.7, -3.2], [7.2, -7.8], [0.4, -9.4], [-6.9, -8], [-11.9, -1.5, 1], [-6.7, -6], [0.4, -7.4], [7, -5.4], [11.8, 0.9, 1], [13.4, -1.8]]), true);
  var EYE_LOWER = SM(eyePts([[8.6, 4.8], [3, 7.1], [-3, 7.1], [-7.4, 5]]), false);
  var EYE_CREASE = SM(eyePts([[9.8, -8.2], [3, -12], [-4.6, -11.8], [-9.3, -8]]), false);
  var BROW = SM(eyePts([[14.2, -16.2, 1], [7.4, -20.6], [-0.8, -21.6], [-8.8, -19.9], [-11.6, -18.2], [-11.4, -16.4, 1], [-8.6, -17.3], [-0.8, -18.8], [6.8, -17.9]]), true);
  var MOUTH_T = 'matrix(1.4 0 0 1.4 -48 -55.2)';

  function faceFeatures(c) {
    var k = c.skin, hp = c.hair, o = '';
    var irisRing = darken(c.eye, 0.36), irisTop = darken(c.eye, 0.3), irisLow = lighten(c.eye, 0.42);
    var pupil = mix(darken(c.eye, 0.6), '#1D130F', 0.55);
    // blush, two soft layers
    var b = c.shape.blush, brx = b[2], bry = b[3];
    o += ELL(b[0], b[1], brx, bry, k.blush, op(k.blushOp * 0.8)) + ELL(mx(b[0]), b[1], brx, bry, k.blush, op(k.blushOp * 0.8));
    o += ELL(b[0], b[1] + 0.2, r2(brx * 0.58), r2(bry * 0.57), k.blush, op(k.blushOp * 0.6)) + ELL(mx(b[0]), b[1] + 0.2, r2(brx * 0.58), r2(bry * 0.57), k.blush, op(k.blushOp * 0.6));
    [1, 0].forEach(function (right) {
      var M = right ? function (d) { return d; } : mir;
      var ix = right ? 140.3 : mx(140.3), iy = 100.7, id = c.uid + '-eye' + right;
      var white = M(EYE_WHITE);
      c.defs.push('<clipPath id="' + id + '"><path d="' + white + '"/></clipPath>');
      o += P(white, '#FFFDFB', null);
      o += '<g clip-path="url(#' + id + ')">' +
        P(white, null, k.d, 3, op(0.3)) +
        CIR(ix, iy, 8.3, c.eye) +
        P('M ' + pt(ix - 8.3, iy) + ' C ' + pt(ix - 8.3, iy - 11) + ' ' + pt(ix + 8.3, iy - 11) + ' ' + pt(ix + 8.3, iy) +
          ' C ' + pt(ix + 5, iy - 4.6) + ' ' + pt(ix - 5, iy - 4.6) + ' ' + pt(ix - 8.3, iy) + ' Z', irisTop, null, 0, op(0.75)) +
        CIR(ix, iy, 8.3, null, irisRing, 0.9) +
        CIR(ix, iy + 0.4, 4, pupil) +
        P('M ' + pt(ix - 5.4, iy + 4.4) + ' C ' + pt(ix - 2.6, iy + 6.8) + ' ' + pt(ix + 2.6, iy + 6.8) + ' ' + pt(ix + 5.4, iy + 4.4), null, irisLow, 1.3, op(0.7)) +
        CIR(ix + 3.2, iy - 3.3, 2.5, '#FFFFFF') + CIR(ix - 2.8, iy + 3.6, 1.15, '#FFFFFF', null, 0, op(0.85)) +
        '</g>';
      o += P(M(EYE_LID), hp.lash, null);
      o += P(M(EYE_LOWER), null, k.l, 0.9, op(0.5));
      o += P(M(EYE_CREASE), null, k.d, 0.95, op(0.8));
      o += P(M(BROW), hp.brow, null);
    });
    // nose: a small soft hook with a highlight dot
    o += P('M 122.2 111.4 C 123.6 114.8, 124 118.2, 122 120 C 121 120.9, 119.4 121.1, 118 120.6', null, k.l, 1.3, op(0.8));
    o += CIR(118.8, 116.6, 1.2, k.h, null, 0, op(0.85));
    // mouth: cupid's bow, fuller lower lip, a soft smile line
    var lipD = darken(c.lip, 0.36), lipH = lighten(c.lip, 0.45), m = '';
    m += P(SM([[114.4, 134.6, 1], [117.2, 133.5], [120, 134.3], [122.8, 133.5], [125.6, 134.6, 1], [120, 136.4]], true), c.lip, null, 0, op(0.9));
    m += P(SM([[115.4, 136.3, 1], [117.6, 139], [120, 139.8], [122.4, 139], [124.6, 136.3, 1], [120, 137.7]], true), c.lip, null);
    m += CIR(121.4, 138.1, 0.8, lipH, null, 0, op(0.85));
    m += P(SM([[113.6, 134.2], [117, 136.9], [120, 137.5], [123, 136.9], [126.4, 134.2]], false), null, lipD, 1);
    m += P('M 112.6 133.2 L 113.7 134.7', null, lipD, 0.7, op(0.8)) + P('M 127.4 133.2 L 126.3 134.7', null, lipD, 0.7, op(0.8));
    o += '<g transform="' + MOUTH_T + '">' + m + '</g>';
    return o;
  }

  /* ------------------------------------------------------------------ hair */

  function lock(d, hp) { return P(d, hp.f, hp.l, 1.4); }
  // Side-parted crowns: fill the lock, but leave the part edge unstroked near the crown,
  // so the part line fades out before it reaches the outline (no dent at the top).
  function lockOpen(d, hp, trimLast) {
    var open = d.replace(/\s*Z\s*$/, '');
    if (trimLast) open = open.slice(0, open.lastIndexOf(' C '));
    return P(d, hp.f, null) + P(open, null, hp.l, 1.4);
  }
  function browShade(c) {
    var t = c.skin.s;
    return P('M 116 48 C 128 49, 146 55, 156 67 C 162 75, 164.6 86, 164 98 L 159.6 98 C 159.6 88, 156.6 79.6, 151.6 73.6 C 142.6 63.6, 129 57, 116 55.6 Z', t, null) +
      P('M 115 33 C 110 42, 104 49, 98 56 C 86 68, 78.5 84, 76.5 97 L 80.6 98 C 82.6 86, 89.4 72.6, 100.4 61.4 C 106.4 55.4, 111.4 48.4, 116.4 40.4 Z', t, null);
  }
  function strands(list, hp, w) { return each(list, function (d) { return P(d, null, hp.st, w || 1.25, op(0.7)); }); }
  function shines(list, hp, w) { return each(list, function (d) { return P(d, null, hp.h, w || 2.4, op(0.9)); }); }
  function shades(list, hp) { return each(list, function (d) { return P(d, hp.s, null); }); }

  // Shared crown for the side-parted styles (wavy bob, long waves): the part sits left of centre,
  // the larger mass sweeps across the forehead to the right.
  var BOB_L = 'M 113 21 C 100 20.5, 80 26, 66 40 C 54 52, 47 68, 46 86 C 45 98, 41 106, 38 116 C 35 126, 37 134, 36 142 C 35 152, 29 160, 28 170 C 27 178, 30 186, 37 189 C 43 192, 50 191, 53 186 C 55 183, 55 179, 53 176 C 58 182, 64 190, 72 190 C 79 190, 83 186, 83 181 C 86 186, 91 189, 96 187 C 93 180, 88 172, 84 162 C 80 152, 73 140, 67 128 C 63 122, 61 114, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74.5 96, 76.5 97 C 78.5 84, 86 68, 98 56 C 104 49, 110 42, 115 33 Z';
  var BOB_R = 'M 113 20.9 C 128 20.4, 158 24, 175 40 C 187 52, 193 70, 194 88 C 195 100, 199 108, 202 118 C 205 128, 203 136, 204 144 C 205 154, 211 162, 212 172 C 213 180, 210 187, 203 190 C 197 193, 190 191, 187 186 C 185 183, 185 179, 187 176 C 182 182, 176 190, 168 190 C 161 190, 157 186, 157 181 C 154 186, 149 189, 144 187 C 147 180, 152 172, 156 162 C 160 152, 167 140, 173 128 C 177 122, 179 114, 179 106 C 178.5 100, 175.5 96.5, 171 95.8 C 168 95.4, 165.5 96, 163.5 97 C 164 86, 162 76, 156 68 C 146 56, 128 50, 116 49 C 113.6 44, 113 34, 113.4 29 C 113.6 26.4, 113.4 23.4, 113 20.9 Z';

  var LW_L = 'M 113 21 C 100 20.5, 80 26, 66 40 C 54 52, 47 68, 46 86 C 44 100, 40 108, 38 118 C 35 130, 39 140, 36 152 C 33 164, 28 174, 31 188 C 34 202, 40 210, 37 224 C 34 238, 30 248, 33 262 C 36 276, 42 284, 40 296 C 39 304, 44 311, 52 309 C 58 308, 60 302, 58 296 C 62 304, 70 310, 78 307 C 84 305, 86 300, 84 294 C 88 298, 93 298, 96 294 C 92 284, 88 272, 89 258 C 90 242, 94 230, 92 216 C 90 202, 86 190, 82 176 C 78 160, 72 142, 67 128 C 63 122, 61 114, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74.5 96, 76.5 97 C 78.5 84, 86 68, 98 56 C 104 49, 110 42, 115 33 Z';
  var LW_R = 'M 113 20.9 C 128 20.4, 158 24, 175 40 C 187 52, 193 70, 194 88 C 196 102, 200 110, 202 120 C 205 132, 201 142, 204 154 C 207 164, 212 174, 209 188 C 206 202, 200 210, 203 224 C 206 238, 210 248, 207 262 C 204 276, 198 284, 200 296 C 201 304, 196 311, 188 309 C 182 308, 180 302, 182 296 C 178 304, 170 310, 162 307 C 156 305, 154 300, 156 294 C 152 298, 147 298, 144 294 C 148 284, 152 272, 151 258 C 150 242, 146 230, 148 216 C 150 202, 154 190, 158 176 C 162 160, 168 142, 173 128 C 177 122, 179 114, 179 106 C 178.5 100, 175.5 96.5, 171 95.8 C 168 95.4, 165.5 96, 163.5 97 C 164 86, 162 76, 156 68 C 146 56, 128 50, 116 49 C 113.6 44, 113 34, 113.4 29 C 113.6 26.4, 113.4 23.4, 113 20.9 Z';

  // Hair ends broken into soft layered tips (tips and notches alternate), as a path continuation.
  function layered(start, tips, notches, end, w) {
    var dir = end[0] > start[0] ? 1 : -1, pts = [start];
    w = w || 3.2;
    for (var i = 0; i < tips.length; i++) {
      var t = tips[i];
      pts.push([t[0] - w * dir, t[1] - 3.2], [t[0] - w * 0.3 * dir, t[1] - 0.2], [t[0] + w * 0.35 * dir, t[1] - 0.4], [t[0] + w * dir, t[1] - 3.4]);
      if (i < notches.length) pts.push([notches[i][0], notches[i][1], 1]);
    }
    pts.push(end);
    return ' ' + SM(pts, false).replace(/^M [^C]*/, '');
  }
  // Long straight: a blunt, softly rounded cut in two broad locks (front) and three (back).
  var LS_L = 'M 120 22 C 98 21, 76 29, 63 44 C 51 58, 46 76, 45 98 C 44 124, 43.4 156, 43.6 190 C 43.8 226, 45 262, 47.4 288' +
    ' C 48.2 300, 52 309.6, 58.6 313.4 C 63 315.8, 67.6 315.6, 70.8 313.2 C 74.4 315.4, 79.2 314.4, 82.6 310.4 C 86 306, 87.4 296, 87.2 280' +
    ' C 88 252, 88.4 226, 87 206 C 85 184, 78 160, 70 140 C 64 126, 61 116, 61 106 C 61.5 100, 64.5 96.5, 69 95.8 C 72 95.4, 74.5 96, 76.5 97 C 81 78, 94 56, 110 45 C 115 41, 118.5 36, 120 30 Z';
  var LS_REAR = 'M 120 20 C 152 20, 178 34, 188 58 C 196 80, 196 120, 197.6 160 C 199 210, 199 258, 196 294' +
    ' C 197 306, 192.6 316, 183 320.6 C 173 325, 161 325.4, 152.4 323 C 144 326.8, 132 328, 120 326.8 C 108 328, 96 326.8, 87.6 323' +
    ' C 79 325.4, 67 325, 57 320.6 C 47.4 316, 43 306, 44 294' +
    ' C 41 258, 41 210, 42.4 160 C 44 120, 44 80, 52 58 C 62 34, 88 20, 120 20 Z';

  var CAP_REAR = 'M 120 27 C 150 27, 172 48, 174 82 C 175 108, 167 132, 154 146 C 144 154, 132 151, 120 156 C 108 151, 96 154, 86 146 C 73 132, 65 108, 66 82 C 68 48, 90 27, 120 27 Z';

  // Pulled-back styles (high bun, ponytail): a smooth hairline with two broad soft waves
  // meeting in a slight peak at the centre.
  var SLICK_CAP = 'M 120 28 C 147 28, 167 41, 173 64 C 176 77, 176.5 90, 175 101 C 172 98, 168 96.5, 164.5 96' +
    ' C 163.6 86, 160 77, 153.4 69.4 C 147 62.4, 138.6 57.4, 129.6 56.4 C 125.6 56, 122.4 57.4, 120 58.6' +
    ' C 117.6 57.4, 114.4 56, 110.4 56.4 C 101.4 57.4, 93 62.4, 86.6 69.4 C 80 77, 76.4 86, 75.5 96' +
    ' C 72 96.5, 68 98, 65 101 C 63.5 90, 64 77, 67 64 C 73 41, 93 28, 120 28 Z';
  var SLICK_SHADE = 'M 75.5 96 C 77 80, 88 62, 108 55 C 116 52.6, 124 52.6, 132 55 C 152 62, 163 80, 164.5 96 C 160 82, 150 66, 132 59.4 C 124 57.2, 116 57.2, 108 59.4 C 90 66, 80 82, 75.5 96 Z';
  // a fine tapered wisp at the temple that ends well above the earlobe
  var TENDRIL = 'M 77.4 92 C 74.6 98.4, 73.8 105, 75.2 111.6 C 76.6 106.4, 78 100.6, 80.6 94.4 Z';

  // Curly: an irregular bumpy outline (outer edge, lock ends, inner edges, fringe), clockwise.
  var CURLY_OUT = [[60, 200, 3], [46, 192, 3.6], [37, 174, 3.1], [33, 152, 3.9], [33, 128, 3.3], [35, 104, 4], [41, 80, 3.2], [52, 58, 3.9], [68, 40, 3.1], [88, 28, 3.7],
    [110, 22, 3.2], [132, 22, 3.9], [154, 28, 3.1], [174, 40, 3.8], [190, 58, 3.3], [201, 80, 3.9], [206, 104, 3.1], [207, 128, 3.7], [206, 152, 3.2], [202, 174, 3.9], [194, 192, 3.1], [180, 200]];
  var CURLY_LOCK_R = [[180, 200, 2.8], [170, 205.6, 2.4], [160, 199]];
  var CURLY_IN_R = [[160, 199, 2.2], [163, 178, 2.6], [168, 158, 2], [172, 138, 2.5], [174, 118, 2.1], [172, 100]];
  var CURLY_FRINGE = [[172, 100, 1.8], [167, 84, 2.3], [156, 72, 1.9], [142, 65, 2.4], [129, 63.4, 1.7], [118, 66, 2.2], [106, 64, 2.4], [94, 68, 1.9], [83, 78, 2.3], [75, 90, 1.8], [70, 102]];
  var CURLY_IN_L = [[70, 102, 2.3], [67, 120, 2.5], [69, 140, 2.1], [73, 160, 2.6], [77, 180, 2.1], [80, 199]];
  var CURLY_LOCK_L = [[80, 199, 2.4], [70, 205.6, 2.8], [60, 200]];
  // Open highlight arcs on the curls: [x, y, radius, start angle in degrees, sweep in degrees]
  var CURL_ARCS = [[50, 70, 5, 200, 150], [41, 100, 6, 160, 170], [39, 132, 5, 190, 140], [45, 164, 5.6, 170, 160], [60, 188, 4.4, 120, 150],
    [70, 44, 5, 230, 140], [96, 30, 6, 210, 150], [124, 27, 5.4, 240, 130], [150, 31, 6, 250, 150], [172, 44, 5, 270, 140],
    [192, 70, 5.6, 280, 150], [200, 102, 5, 300, 140], [201, 134, 6, 290, 150], [196, 164, 5, 310, 140], [182, 188, 4.4, 340, 150],
    [58, 112, 4, 180, 140], [182, 112, 4, 300, 140], [86, 44, 4, 220, 130], [156, 46, 4, 260, 130]];
  var CURL_ARCS_REAR = CURL_ARCS.concat([[96, 76, 5, 220, 150], [128, 72, 5.4, 250, 140], [158, 86, 5, 270, 150], [80, 112, 5, 200, 140], [112, 104, 6, 230, 150],
    [146, 114, 5.4, 260, 140], [170, 136, 5, 280, 150], [72, 148, 5.6, 190, 150], [104, 142, 5, 220, 140], [136, 150, 6, 250, 150], [90, 178, 5, 210, 140],
    [122, 182, 5.4, 240, 150], [156, 178, 5, 270, 140], [76, 200, 4.4, 200, 140], [168, 202, 4.4, 280, 140]]);
  function shrink(pts, k, cx, cy) { return pts.map(function (q) { return [cx + (q[0] - cx) * k, cy + (q[1] - cy) * k]; }); }
  function arcD(q) {
    var a0 = q[3] * Math.PI / 180, a1 = (q[3] + q[4]) * Math.PI / 180, r = q[2];
    return 'M ' + pt(q[0] + r * Math.cos(a0), q[1] + r * Math.sin(a0)) + ' A ' + r + ' ' + r + ' 0 0 1 ' + pt(q[0] + r * Math.cos(a1), q[1] + r * Math.sin(a1));
  }
  function curlTexture(hp, rear) {
    var o = '', col = hp.dark ? hp.sw : hp.l, base = CURLY_OUT.slice(1, -1);
    if (rear) {
      // curl clumps falling from the crown, plus one ring that follows the outline
      o += P(BUMPY(shrink(base, 0.9, 120, 112), 1.8, false), null, col, 1.1, op(0.6));
      [-3, -2, -1, 0, 1, 2, 3].forEach(function (k) {
        var pts = [];
        for (var t = 0; t <= 1.001; t += 0.1) pts.push([120 + k * (5 + 23 * Math.sin(t * Math.PI * 0.6)), 38 + t * 162]);
        o += P(BUMPY(pts, k % 2 ? 1.5 : -1.5, false), null, col, 1.1, op(0.5));
      });
    } else {
      o += P(BUMPY(shrink(base, 0.9, 120, 118), 1.7, false), null, col, 1.1, op(0.6));
      o += P(BUMPY(shrink(base, 0.8, 120, 118), 1.5, false), null, col, 1.1, op(0.5));
      o += P(BUMPY(shrink(base.slice(5, 15), 0.7, 120, 118), 1.4, false), null, col, 1, op(0.45));
    }
    o += each(rear ? CURL_ARCS_REAR : CURL_ARCS, function (q) { return P(arcD(q), null, hp.sw, 1.4, op(0.75)); });
    return o;
  }

  // pink scrunchie, or cream when the hair itself is rose so the two do not merge
  function scrunchie(c) {
    return c.a.hairColor === 'rose' ? { f: '#FFF7EA', l: '#C9B08A', h: '#FFFFFF' } : { f: '#F4B4C2', l: '#D97F97', h: '#FBD0D9' };
  }

  var HAIR = {
    'wavy-bob': {
      back: function (c) {
        var hp = c.hair;
        return P('M 113 27 C 148 26, 176 37, 186 60 C 194 82, 194 104, 197 124 C 200 144, 205 162, 204 176 C 202 186, 194 189, 186 188 L 54 188 C 46 189, 38 186, 36 176 C 35 162, 40 144, 43 124 C 46 104, 46 82, 54 60 C 64 37, 82 27, 113 27 Z', hp.s, hp.l, 1.4);
      },
      front: function (c) {
        var hp = c.hair, o = browShade(c);
        o += lockOpen(BOB_L, hp);
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
        o += lockOpen(BOB_R, hp, true);
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
        o += P('M 120 20 C 152 20, 178 33, 188 56 C 196 76, 195 100, 199 120 C 202 134, 203 142, 204 150 C 206 160, 211 166, 212 174 C 213 183, 208 190, 200 192 C 194 194, 188 192, 185 188 C 180 194, 170 196, 162 192 C 156 196, 146 197, 140 193 C 134 197, 126 197, 120 194 C 114 197, 106 197, 100 193 C 94 197, 84 196, 78 192 C 70 196, 60 194, 55 188 C 52 192, 46 194, 40 192 C 32 190, 27 183, 28 174 C 29 166, 34 160, 36 150 C 37 142, 38 134, 41 120 C 45 100, 44 76, 52 56 C 62 33, 88 20, 120 20 Z', hp.f, hp.l, 1.4);
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
        return P('M 113 28 C 148 27, 176 38, 186 62 C 194 84, 193 104, 196 126 C 199 160, 203 220, 197 292 L 43 292 C 37 220, 41 160, 44 126 C 47 104, 46 84, 54 62 C 64 38, 82 28, 113 28 Z', hp.s, hp.l, 1.4);
      },
      front: function (c) {
        var hp = c.hair, o = browShade(c);
        o += lockOpen(LW_L, hp);
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
        o += lockOpen(LW_R, hp, true);
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
        o += P('M 120 20 C 152 20, 178 34, 188 58 C 196 80, 195 104, 199 126 C 203 150, 204 172, 202 196 C 200 220, 206 240, 204 262 C 202 284, 208 300, 200 312 C 194 318, 186 316, 180 310 C 174 318, 162 318, 156 311 C 150 318, 138 318, 132 312 C 126 318, 114 318, 108 312 C 102 318, 90 318, 84 311 C 78 318, 66 318, 60 310 C 54 316, 46 318, 40 312 C 32 300, 38 284, 36 262 C 34 240, 40 220, 38 196 C 36 172, 37 150, 41 126 C 45 104, 44 80, 52 58 C 62 34, 88 20, 120 20 Z', hp.f, hp.l, 1.4);
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
        return P('M 120 27 C 150 27, 176 39, 186 64 C 194 86, 193 120, 194 160 C 195 200, 193 250, 190 296 L 50 296 C 47 250, 45 200, 46 160 C 47 120, 46 86, 54 64 C 64 39, 90 27, 120 27 Z', hp.s, hp.l, 1.4);
      },
      front: function (c) {
        var hp = c.hair, o = '';
        o += lock(LS_L, hp) + lock(mir(LS_L), hp);
        var sh = ['M 70 140 C 77 160, 84 184, 86.4 206 C 88 236, 88.6 262, 87.4 284 C 86 268, 85 240, 83 210 C 81 186, 76 162, 70 140 Z',
          'M 46 100 C 45 130, 44.4 160, 44.6 190 C 44.8 230, 46 262, 48.6 290 C 48.4 262, 48 230, 48.2 190 C 48.4 160, 48.6 130, 46 100 Z'];
        o += shades(sh.concat(sh.map(mir)), hp);
        var st = ['M 112 34 C 92 44, 76 62, 67 84 C 60 104, 58 140, 57.6 180 C 57.4 220, 58.6 262, 60.4 300',
          'M 104 44 C 89 60, 81 80, 77 100', 'M 69 136 C 73 164, 75 200, 75.4 240 C 75.6 266, 74.6 290, 72 306'];
        o += strands(st.concat(st.map(mir)), hp, 1.1);
        var sn = ['M 104 30 C 91 34, 79 42, 71 54', 'M 52 124 C 51.4 142, 51.2 158, 51.4 172'];
        o += each(sn.concat(sn.map(mir)), function (d) { return P(d, null, hp.h, 2, op(0.6)); });
        o += P('M 120 22.5 L 120 30', null, hp.l, 1.2, op(0.8));
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P(LS_REAR, hp.f, hp.l, 1.4);
        o += shades(['M 50 318 C 47 311, 45 304, 44 294 C 43 270, 43 250, 43.4 230 C 45 252, 46.6 280, 50 300 Z',
          'M 190 318 C 193 311, 195 304, 196 294 C 197 270, 197 250, 196.6 230 C 195 252, 193.4 280, 190 300 Z'], hp);
        o += strands([
          'M 116 36 C 96 44, 82 62, 74 86 C 66 110, 64 150, 64 200 C 64 240, 66 280, 66 316',
          'M 124 36 C 144 44, 158 62, 166 86 C 174 110, 176 150, 176 200 C 176 240, 174 280, 174 316',
          'M 110 44 C 98 80, 94 140, 93 200 C 92.4 240, 93 280, 94 306',
          'M 130 44 C 142 80, 146 140, 147 200 C 147.6 240, 147 280, 146 306',
          'M 120 46 C 120 120, 120 220, 120 308'
        ], hp, 1.1);
        o += each(['M 102 32 C 88 38, 76 50, 70 64', 'M 138 32 C 152 38, 164 50, 170 64', 'M 106 70 C 104 100, 104 130, 104.4 156', 'M 134 70 C 136 100, 136 130, 135.6 156'],
          function (d) { return P(d, null, hp.h, 2, op(0.6)); });
        return o;
      }
    },

    'high-bun': {
      back: function (c) {
        // a round swirl bun on top of the head
        var hp = c.hair, o = '';
        o += P(SM([[120, 2.6], [132.6, 5.6], [139.4, 15.4], [138.4, 27], [130.4, 35], [120, 37], [109.6, 35], [101.6, 27], [100.6, 15.4], [107.4, 5.6]], true), hp.f, hp.l, 1.4);
        o += P('M 105 25 C 102.6 13.6, 113.4 6, 124 8 C 133.4 9.8, 137 21.6, 129.6 27.4 C 122.6 32.8, 112.4 28.6, 113.8 20.6 C 114.8 15.4, 121.6 13.4, 125 17.6 C 127 20.4, 125.2 23.8, 122 23.4', null, hp.l, 1.1, op(0.75));
        o += P('M 104.4 30.4 C 110 35, 123 36, 131.4 31', null, hp.l, 1, op(0.6));
        o += P('M 108.6 9.8 C 112.6 6.6, 118.6 5.2, 124.4 5.8', null, hp.h, 2, op(0.85));
        o += P('M 131 14 C 133.4 17, 134.4 20.4, 134 24', null, hp.h, 1.6, op(0.6));
        return o;
      },
      front: function (c) {
        var hp = c.hair, o = '';
        o += lock(SLICK_CAP, hp);
        o += clipTo(c, SLICK_CAP, P(SLICK_SHADE, hp.s, null, 0, op(0.55)));
        o += strands([
          'M 96 61 C 100 48, 108 38, 116 32', 'M 144 61 C 140 48, 132 38, 124 32',
          'M 82 78 C 84 60, 94 44, 108 35', 'M 158 78 C 156 60, 146 44, 132 35',
          'M 108 55 C 110 46, 114 38, 118 33', 'M 132 55 C 130 46, 126 38, 122 33',
          'M 120 52 L 120 32'
        ], hp, 1.1);
        o += shines(['M 90 44 C 98 37, 108 33.4, 117 32.4', 'M 150 44 C 144 39, 136 35.4, 128 34'], hp, 2);
        o += PM(TENDRIL, hp.f, hp.l, 1);
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P(CAP_REAR, hp.f, hp.l, 1.4);
        o += strands([
          'M 88 140 C 84 100, 94 62, 110 40', 'M 152 140 C 156 100, 146 62, 130 40',
          'M 120 152 C 120 110, 120 72, 120 42', 'M 104 148 C 100 110, 104 70, 115 42',
          'M 136 148 C 140 110, 136 70, 125 42', 'M 74 110 C 76 82, 88 56, 104 42', 'M 166 110 C 164 82, 152 56, 136 42'
        ], hp, 1.1);
        o += shines(['M 96 50 C 88 64, 84 80, 83 96', 'M 144 50 C 152 64, 156 80, 157 96', 'M 112 70 C 110 90, 110 110, 111 128'], hp, 2);
        o += P('M 92 146 C 100 150.6, 110 152, 120 152 C 130 152, 140 150.6, 148 146', null, hp.l, 1, op(0.5));
        o += HAIR['high-bun'].back(c);
        return o;
      }
    },

    'curly': {
      back: function (c) {
        return P(BUMPY(CURLY_OUT.concat([[180, 202, 3], [150, 206, 3.2], [120, 203, 3], [90, 206, 3.2], [60, 202, 3]]), 3.4, true), c.hair.s, c.hair.l, 1.5);
      },
      front: function (c) {
        var hp = c.hair, o = '';
        var d = BUMPY(CURLY_OUT, 3.4, false) + BUMPY(CURLY_LOCK_R, 2.6, false, true) + BUMPY(CURLY_IN_R, 2.2, false, true) +
          BUMPY(CURLY_FRINGE, 2, false, true) + BUMPY(CURLY_IN_L, 2.2, false, true) + BUMPY(CURLY_LOCK_L, 2.6, false, true) + ' Z';
        o += P(d, hp.f, hp.l, 1.4);
        o += shades([
          'M 72 160 C 75 172, 78 186, 80 198 C 75 192, 72 178, 72 160 Z',
          'M 168 160 C 165 172, 162 186, 160 198 C 165 192, 168 178, 168 160 Z'
        ], hp);
        o += curlTexture(hp, false);
        o += shines(['M 92 30 C 100 26, 110 24.4, 118 25', 'M 37 116 C 36.4 122, 36.8 128, 38.4 132', 'M 203 112 C 203.6 118, 203.2 124, 201.6 128'], hp, 2);
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P(BUMPY(CURLY_OUT.concat([[182, 210, 3.4], [160, 214, 3], [140, 210, 3.4], [120, 214, 3], [100, 210, 3.4], [80, 214, 3], [58, 210, 3.4]]), 3.4, true), hp.f, hp.l, 1.4);
        o += curlTexture(hp, true);
        o += shines(['M 98 30 C 108 25.6, 122 24.6, 134 27', 'M 37 116 C 36.4 122, 36.8 128, 38.4 132', 'M 203 112 C 203.6 118, 203.2 124, 201.6 128'], hp, 2);
        return o;
      }
    },

    'ponytail': {
      back: function (c) {
        // hair gathered behind her left ear, on its way to the nape
        var hp = c.hair;
        return P('M 160 94 C 173 102, 177 124, 172 142 C 168 155, 161 164, 152 170 L 141 163 C 150 154, 155 138, 156 116 Z', hp.s, hp.l, 1.2);
      },
      front: function (c) {
        var hp = c.hair, o = '';
        o += lock(SLICK_CAP, hp);
        o += clipTo(c, SLICK_CAP, P(SLICK_SHADE, hp.s, null, 0, op(0.55)));
        // side part on her right; the hair sweeps back toward the tail on her left
        o += P('M 104.6 29.6 C 105.4 38, 105.8 46, 105.6 55', null, hp.l, 1.2, op(0.85));
        o += strands([
          'M 110 55 C 116 44, 128 36, 142 33', 'M 122 54 C 132 46, 146 42, 158 44', 'M 136 57 C 146 52, 156 52, 164 58',
          'M 150 64 C 158 62, 166 66, 170 74', 'M 100 57 C 96 48, 98 40, 104 33', 'M 88 66 C 84 54, 88 44, 98 36', 'M 79 84 C 76 68, 80 54, 92 42'
        ], hp, 1.1);
        o += shines(['M 112 33 C 124 30, 138 31, 150 36', 'M 86 48 C 90 42, 95 38, 101 35'], hp, 2);
        o += P(TENDRIL, hp.f, hp.l, 1);
        return o;
      },
      tail: function (c) {
        // low ponytail swept forward over her left shoulder; it leaves the nape well below
        // the earring, and the scrunchie sits clear of the hoop
        var hp = c.hair, o = '', sc = scrunchie(c);
        var T = SM([[140, 162], [150, 158], [161, 164], [169.6, 177], [176, 197], [180.6, 220], [182, 244], [179, 268], [174, 290], [170, 304], [164, 314], [160, 304], [155, 310], [153, 295], [156, 275], [155, 252], [151.4, 233], [147, 213], [142.4, 195], [138.6, 179], [136.6, 169]], true);
        o += P(T, hp.f, null);
        o += P(SM([[153, 184], [166, 206], [172, 230], [174, 260], [168, 290], [163, 302], [165, 276], [165, 248], [159.4, 226], [152, 206]], true), hp.s, null, 0, op(0.8));
        o += strands([SM([[147.6, 174], [160, 195], [168, 218], [172, 248], [168, 286]], false), SM([[143.4, 184], [152, 206], [158, 230], [162, 262], [160, 300]], false),
          SM([[155.6, 170], [170, 191], [177, 216], [179, 250], [174, 286]], false)], hp, 1.05);
        o += P(SM([[167, 198], [174.6, 216], [178, 236]], false), null, hp.h, 2.2, op(0.75)) + P(SM([[178, 252], [179, 264]], false), null, hp.h, 2, op(0.6));
        o += P(T, null, hp.l, 1.4);
        o += P(SM([[138, 164], [144, 157.6], [152, 156], [158.6, 160.4], [158, 168.6], [151, 173.6], [143.6, 173.4], [138.4, 170]], true), sc.f, sc.l, 1.2);
        o += P(SM([[144.4, 159], [142.6, 165.4], [144.6, 172.6]], false), null, sc.l, 0.9) + P(SM([[152.2, 157.4], [150.6, 165], [152.2, 173]], false), null, sc.l, 0.9);
        o += P('M 141.6 161 C 144 159.6, 147 158.8, 150 158.8', null, sc.h, 1.1, op(0.9));
        return o;
      },
      rear: function (c) {
        var hp = c.hair, o = '';
        o += P(CAP_REAR, hp.f, hp.l, 1.4);
        o += strands(['M 150 136 C 148 112, 130 104, 104 140', 'M 160 112 C 156 82, 128 76, 100 136', 'M 120 152 C 116 148, 108 146, 100 144',
          'M 132 148 C 128 138, 116 136, 102 142', 'M 76 112 C 78 90, 90 74, 96 132', 'M 140 56 C 160 66, 166 92, 156 120', 'M 110 40 C 92 54, 84 82, 90 128'], hp, 1.1);
        o += shines(['M 98 40 C 90 50, 84 62, 82 76', 'M 142 40 C 150 50, 156 62, 158 76'], hp, 2);
        // the tail leaves the nape on her left (viewer's left) and goes over that shoulder
        var BT = SM([[88, 142], [104, 141], [108, 153], [102, 167], [92, 181], [80, 194], [68, 204], [56, 209], [50, 204], [53, 196], [64, 186], [75, 172], [83, 158], [86, 149]], true);
        o += P(BT, hp.f, hp.l, 1.4);
        o += P(SM([[100, 158], [90, 176], [76, 192], [60, 203]], false), null, hp.l, 1.05, op(0.6));
        o += P(SM([[95, 150], [84, 166], [70, 184], [56, 198]], false), null, hp.h, 1.8, op(0.6));
        var sc = scrunchie(c);
        o += P(SM([[85, 140], [93, 136.4], [102, 137.2], [108, 142], [106.6, 149], [98.6, 152], [90, 151], [85, 146.4]], true), sc.f, sc.l, 1.2);
        o += P(SM([[91, 137.6], [89.6, 144], [91, 150.6]], false), null, sc.l, 0.9) + P(SM([[99.6, 137.4], [98.6, 144.4], [99.8, 151.6]], false), null, sc.l, 0.9);
        return o;
      }
    }
  };

  /* ------------------------------------------------------------------ accessories */

  function earrings(c, rear) {
    var e = c.a.earrings, EAR_X = 70.6 + c.shape.earDx;
    if (e === 'none') return '';
    if (e === 'studs') {
      // small pearls on the lobes
      return CM(EAR_X, 124.6, 2.7, '#FFF7EA', '#C9B48F', 1) + CM(EAR_X - 0.8, 123.7, 0.95, '#FFFFFF') +
        PM(earD(c, 'M 68.6 126.2 C 69.8 127.4, 71.8 127.4, 72.8 126'), null, '#E6D6BA', 0.8);
    }
    // gold hoops: a filled ring with a thin darker outline and a short shine
    var gold = '#E3B652', goldL = '#B98632', goldH = '#F7DE9A';
    function ring(cx, cy) {
      var R = 6.4, r = 4.5;
      return '<path d="M ' + pt(cx - R, cy) + ' a ' + R + ' ' + R + ' 0 1 0 ' + 2 * R + ' 0 a ' + R + ' ' + R + ' 0 1 0 ' + (-2 * R) + ' 0 Z' +
        ' M ' + pt(cx - r, cy) + ' a ' + r + ' ' + r + ' 0 1 0 ' + 2 * r + ' 0 a ' + r + ' ' + r + ' 0 1 0 ' + (-2 * r) + ' 0 Z" fill="' + gold +
        '" fill-rule="evenodd" stroke="' + goldL + '" stroke-width="0.9"/>' +
        P('M ' + pt(cx - 4.6, cy - 3.2) + ' C ' + pt(cx - 3.6, cy - 4.5) + ' ' + pt(cx - 2, cy - 5.2) + ' ' + pt(cx - 0.4, cy - 5.4), null, goldH, 1.1);
    }
    return ring(EAR_X, 131) + ring(mx(EAR_X), 131);
  }

  function glasses(c) {
    var g = c.a.glasses;
    if (g === 'none') return '';
    var gid = c.uid + '-lens', o = '';
    c.defs.push('<linearGradient id="' + gid + '" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".1"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".03"/></linearGradient>');
    if (g === 'round') {
      var frame = '#5A4150';
      o += CIR(100, 100.4, 14.2, 'url(#' + gid + ')', frame, 1.6) + CIR(140, 100.4, 14.2, 'url(#' + gid + ')', frame, 1.6);
      o += P('M 114.2 99 C 117 96, 123 96, 125.8 99', null, frame, 1.6);
      o += PM('M 85.8 98.6 L ' + pt(77 + c.shape.earDx, 96.8), null, frame, 1.6);
      o += PM('M 91 93.6 C 93 91.4, 95.6 90.4, 98.4 90.2', null, '#FFFFFF', 1.3, op(0.7));
      return o;
    }
    // cat-eye: flat brow-line top rim with a sharp upswept outer wing
    var fr = '#6B2F45', frH = '#9A5670';
    var LENS = 'M 126 88.6 C 134 86.8, 146 87, 153 89.6 C 156 87.6, 159 85, 161.2 82.8 C 160.8 88.4, 158.6 94.8, 155.8 99.8 C 153.6 108.4, 146.6 112.6, 138.6 112.4 C 130.2 112.2, 125.2 105.4, 126 88.6 Z';
    var RIM = 'M 125.2 87.6 C 134 85.4, 146 85.6, 153 88.4 C 156.2 86.2, 159.2 83.4, 161.8 80.8 L 161.6 84.6 C 159.2 87.8, 156.8 90.2, 153.8 92.2 C 146 89.6, 134 89.4, 125.6 91.4 Z';
    o += P(LENS, 'url(#' + gid + ')', fr, 1.5) + P(mir(LENS), 'url(#' + gid + ')', fr, 1.5);
    o += P(RIM, fr, fr, 0.8, 'stroke-linejoin="round"') + P(mir(RIM), fr, fr, 0.8);
    o += P('M 128.4 87.6 C 136 86, 146 86.2, 152.4 88.4', null, frH, 0.9, op(0.9)) + P(mir('M 128.4 87.6 C 136 86, 146 86.2, 152.4 88.4'), null, frH, 0.9, op(0.9));
    o += P('M 114.6 91.2 C 117.4 88.8, 122.6 88.8, 125.4 91.2', null, fr, 1.6);
    o += PM('M 79.6 88.4 L ' + pt(76.8 + c.shape.earDx, 92.6), null, fr, 1.6);
    o += PM('M 92.4 93.2 C 94.4 91.8, 96.8 91.2, 99.2 91.2', null, '#FFFFFF', 1.3, op(0.7));
    return o;
  }

  /* ------------------------------------------------------------------ tops */

  // Torso side below the arm. Tucked tops and the dress bodice nip in to the waist (x 72 to 76);
  // loose tops fall a little straighter.
  function torsoSide(hemY, loose) {
    return loose
      ? [[60, 252], [61.6, 282, 64, 310, 66.4, hemY - 8], [67.4, hemY - 2, 70, hemY + 2.4, 76, hemY + 2.8], [92, hemY + 3.6, 108, hemY + 3.4, 120, hemY + 3]]
      : [[60, 252], [62.4, 278, 67, 298, 72.4, hemY - 12], [74.4, hemY - 6, 75.6, hemY, 80, hemY + 2.6], [96, hemY + 3.4, 110, hemY + 3.2, 120, hemY + 3]];
  }
  // Torso with a neckline of half-width nw and centre depth nd; hem at hemY.
  function torsoD(nw, nd, hemY, back, loose) {
    var x0 = 120 - nw;
    var start = back ? [120, 182.5] : [120, nd];
    var neck = back ? [110, 182.5, 104, 183.6, x0, 186] : [120 - nw * 0.55, nd, 120 - nw * 0.95, nd - (nd - 186) * 0.45, x0, 186];
    return sym([start, neck, [88, 190, 66, 194, 50, 200], [44, 203, 42, 210, 44, 220]].concat(torsoSide(hemY, loose)));
  }
  // A tucked top blouses softly over the waistband: a curved, slightly uneven hem edge with
  // a few fold lines, drawn on top of the band.
  var BLOUSE_OVER = sym([[72.2, 311], [73.4, 316.8, 74.8, 320.2, 77.6, 322.6], [82.6, 324.8, 88.6, 324.8, 94, 323.4], [100, 325, 106, 325.6, 112, 324.2], [115.6, 323.4, 118, 323.4, 120, 323.8]]);
  function blouseOver(p) {
    return P(BLOUSE_OVER, p.f, null) + P(BLOUSE_OVER.replace(/ Z$/, ''), null, p.l, 1.5) +
      P('M 94 323.2 C 94.8 318.6, 96.6 314.6, 99.6 311.2 M 112.4 324 C 112.6 320, 111.6 316.4, 109.6 313.2 M 140.6 323.4 C 141.6 319, 143.4 315.4, 146.4 312.4 M 82.6 324.4 C 82 320.6, 80.6 317.6, 78.6 315.4', null, p.l, 1.1, op(0.55));
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

  function clipTo(c, d, inner) {
    var id = c.uid + '-k' + c.defs.length;
    c.defs.push('<clipPath id="' + id + '"><path d="' + d + '"/></clipPath>');
    return '<g clip-path="url(#' + id + ')">' + inner + '</g>';
  }
  // Torso with a V neckline that reaches down to vd.
  function vTorsoD(nw, vd, hemY, back, loose) {
    if (back) return torsoD(nw, 0, hemY, true, loose);
    return sym([[120, vd], [120 - nw, 186], [88, 190, 66, 194, 50, 200], [44, 203, 42, 210, 44, 220]].concat(torsoSide(hemY, loose)));
  }
  function vBand(nw, vd, w) {
    var a = 120 - nw, b = 120 + nw;
    return 'M ' + pt(a, 186) + ' L 120 ' + vd + ' L ' + pt(b, 186) + ' L ' + pt(b + w, 187.6) + ' L ' + pt(120, vd + w * 1.5) + ' L ' + pt(a - w, 187.6) + ' Z';
  }
  // A rope cable knitted down the front, centred on x0.
  function cable(x0, y0, y1, w, col) {
    var per = 12, s = '', y;
    var edges = 'M ' + pt(x0 - w, y0) + ' L ' + pt(x0 - w, y1) + ' M ' + pt(x0 + w, y0) + ' L ' + pt(x0 + w, y1);
    for (y = y0; y + per <= y1 + 0.01; y += per) {
      s += 'M ' + pt(x0 - w * 0.62, y) + ' C ' + pt(x0 - w * 0.62, y + per * 0.5) + ' ' + pt(x0 + w * 0.62, y + per * 0.5) + ' ' + pt(x0 + w * 0.62, y + per) + ' ';
      s += 'M ' + pt(x0 + w * 0.62, y) + ' C ' + pt(x0 + w * 0.62, y + per * 0.28) + ' ' + pt(x0 + w * 0.3, y + per * 0.4) + ' ' + pt(x0 + w * 0.14, y + per * 0.44) + ' ';
      s += 'M ' + pt(x0 - w * 0.14, y + per * 0.56) + ' C ' + pt(x0 - w * 0.3, y + per * 0.6) + ' ' + pt(x0 - w * 0.62, y + per * 0.72) + ' ' + pt(x0 - w * 0.62, y + per) + ' ';
    }
    return P(edges, null, col, 1, op(0.6)) + P(s, null, col, 1.15, op(0.85));
  }

  function topPiece(c, g, back) {
    var p = gPal(g), k = g.kind, body = '', sl = '', d;
    if (k === 'sweater') {
      // long, untucked, cable-knit front, ribbed hem band below the waistband
      d = sym([back ? [120, 182.5] : [120, 197.5], back ? [110, 182.5, 104, 183.6, 101, 186] : [109.6, 197.5, 102, 191, 101, 186], [88, 190, 66, 194, 50, 200], [44, 203, 42, 210, 44, 220], [60, 252], [61.8, 290, 64, 326, 64.8, 352], [82, 353.6, 100, 354.2, 120, 354.2]]);
      body += P(d, p.f, null);
      var tex = PM('M 68 300 C 74 314, 79 330, 81 348', null, p.d, 1.1, op(0.55)) + PM('M 62 236 C 63.2 280, 64.4 320, 65.4 350', null, p.s, 3, op(0.7));
      if (!back) {
        tex += cable(96, 210, 342, 6.4, p.d) + cable(120, 214, 346, 6.4, p.d) + cable(144, 210, 342, 6.4, p.d);
        tex += PM('M 108 210 L 108 346 M 82 214 L 82 344', null, p.d, 0.9, op(0.45));
      } else tex += P('M 120 188 L 120 352', null, p.d, 1, op(0.5)) + ribs(74, 166, 196, 348, 8, p.d, 0.8, 0.35);
      body += clipTo(c, d, tex) + P(d, null, p.l, 1.5);
      body += P(back ? backNeck(5) : neckBand(19, 197.5, 5), p.f, p.l, 1.4);
      if (!back) body += ribs(102, 138, 199, 201.6, 3.6, p.d, 0.9, 0.6);
      body += P(sym([[120, 352.4], [100, 352.4, 82, 351.8, 64.4, 350.8], [65, 366], [84, 367.4, 102, 368, 120, 368]]), p.f, p.l, 1.5);
      body += ribs(68, 172, 354, 366, 4, p.d, 1, 0.8);
      sl += PM(SLV.sweater, p.f, p.l, 1.5);
      sl += PM('M 25.6 333 L 57.6 333 L 56 350 L 27.6 350 Z', p.f, p.l, 1.5);
      sl += PM(ribPath(29, 55, 335, 348.5, 3.4), null, p.d, 0.9, op(0.8));
      sl += PM('M 27 296 C 34 300, 44 301, 52 298', null, p.d, 1.1, op(0.7)) + PM('M 25 318 C 34 323, 46 324, 56 320', null, p.d, 1.1, op(0.6));
      sl += PM('M 31 234 C 30 250, 28 266, 27 280', null, p.h, 2.2, op(0.9));
    } else if (k === 'tee') {
      // short boxy tee, tucked; the waistband is drawn over its hem
      d = torsoD(18, 196, 326, back);
      body += P(d, p.f, p.l, 1.5);
      body += P(back ? backNeck(3.6) : neckBand(18, 196, 3.6), p.s, p.l, 1.4);
      body += PM('M 73 309 C 78 304, 85 302, 92 302', null, p.d, 1.1, op(0.7)) + P('M 148 310 C 142 305.6, 134 303.4, 126 303.6', null, p.d, 1.1, op(0.6));
      body += PM('M 62.4 258 C 64 282, 67.4 300, 71.2 311', null, p.d, 1, op(0.5));
      if (back) body += P('M 120 186 L 120 322', null, p.d, 1, op(0.5));
      else body += P('M 150 286 C 136 294, 118 297, 100 295', null, p.d, 1.1, op(0.55));
      sl += PM(SLV.tee, p.f, p.l, 1.5);
      sl += PM('M 27.6 244.6 L 60.4 253.4', null, p.d, 1.1, op(0.9));
      sl += PM('M 34 222 C 38 226, 42 232, 44 240', null, p.d, 1, op(0.6));
      sl += PM('M 33 214 C 31 222, 30 230, 29.6 238', null, p.h, 1.8, op(0.8));
    } else if (k === 'lace') {
      // fitted lace top, untucked, finished with a scalloped hem just below the waistband
      var crop = !!g.crop, hemY = crop ? 316 : 336;
      var hemPts = [];
      for (var hx = 70.4; hx <= 169.7; hx += 6.6) hemPts.push([hx, hemY + 3.4 + Math.sin((hx - 70) / 100 * Math.PI) * 0.8]);
      body += each(hemPts, function (q) { return CIR(q[0], q[1], 3.4, p.f, p.l, 1.1); });
      d = torsoD(21, back ? 0 : 203, hemY, back, true);
      body += P(d, p.f, p.l, 1.5);
      if (!back) {
        body += scallops(neckPts(21, 203), 2.2, p.f, p.l);
        body += P(neckBand(21, 203, 4).split(' L ')[0], null, p.d, 1, op(0.8));
      } else body += P(backNeck(3), p.f, p.l, 1.4) + P('M 120 186 L 120 ' + hemY, null, p.d, 1, op(0.5));
      var mot = back ? [[86, 220], [120, 214], [154, 220], [74, 262], [104, 252], [136, 252], [166, 262], [88, 296], [120, 288], [152, 296]]
        : [[86, 226], [154, 226], [74, 262], [104, 248], [136, 248], [166, 262], [88, 296], [120, 284], [152, 296], [120, 230]];
      if (!crop) mot = mot.concat([[78, 324], [104, 318], [136, 318], [162, 324]]);
      body += laceMotif(p, mot.filter(function (q) { return q[1] < hemY - 4; }));
      body += P('M 69 ' + (hemY - 1) + ' C 92 ' + (hemY + 1.6) + ', 148 ' + (hemY + 1.6) + ', 171 ' + (hemY - 1), null, p.d, 1, op(0.7));
      if (crop) {
        sl += PM(SLV.tee, p.f, p.l, 1.5);
        sl += PM(scallopsD([[27.6, 245], [33.2, 246.4], [38.8, 247.9], [44.4, 249.4], [50, 250.9], [55.6, 252.4], [60.6, 253.6]], 2.4), p.f, p.l, 1.1);
      } else {
        sl += PM(SLV.lace, p.f, p.l, 1.5);
        sl += PM(scallopsD([[30, 345], [35.2, 345.4], [40.4, 345.6], [45.6, 345.6], [50.8, 345.4], [55.4, 345]], 2.6), p.f, p.l, 1.1);
        sl += PM('M 29 334 C 38 336.4, 48 336.4, 57.2 334.6', null, p.d, 1, op(0.8));
        sl += laceMotif(p, [[42, 230], [40, 270], [44, 306], [mx(42), 230], [mx(40), 270], [mx(44), 306]]);
      }
    } else if (k === 'knit') {
      // brick knit: V-neck, untucked, ribbed all over, deep ribbed hem band
      d = vTorsoD(16, 226, 344, back, true);
      body += P(d, p.f, null);
      body += clipTo(c, d, ribs(68, 172, back ? 190 : 196, 346, 5.2, p.s, 1.5, 0.8) + PM('M 62 238 C 63.4 280, 65 318, 66.4 342', null, p.s, 3, op(0.8)));
      body += P(d, null, p.l, 1.5);
      if (back) body += P(backNeck(5), p.f, p.l, 1.4);
      else body += P(vBand(16, 226, 5), p.f, p.l, 1.3) + P('M 120 226 L 120 233.4', null, p.l, 1, op(0.8));
      body += P(sym([[120, 343.4], [100, 343.4, 82, 342.6, 67, 341.4], [67.8, 359], [84, 360.2, 102, 360.6, 120, 360.6]]), p.f, p.l, 1.5);
      body += ribs(70.4, 170, 345, 358.6, 3.4, p.l, 0.9, 0.55);
      sl += PM(SLV.sweater, p.f, p.l, 1.5);
      sl += PM('M 34 222 C 31 250, 30 280, 30 314 M 41 214 C 38 250, 37 284, 37.6 318 M 48 216 C 46 250, 45.6 284, 46.6 320 M 54 226 C 53.6 260, 53.6 290, 54 320', null, p.s, 1.5, op(0.8));
      sl += PM('M 25.6 333 L 57.6 333 L 56 350 L 27.6 350 Z', p.f, p.l, 1.5);
      sl += PM(ribPath(29, 55, 335, 348.5, 3.4), null, p.l, 0.9, op(0.6));
      sl += PM('M 30 240 C 29 256, 28 270, 27.6 284', null, p.h, 2, op(0.7));
    } else {
      // blouse: the relaxed pink top of the reference, tucked, with puffed sleeves and gathered cuffs
      body += P(torsoD(19, 197, 326, back), p.f, p.l, 1.5);
      body += P(back ? backNeck(3.4) : neckBand(19, 197, 3.4), p.f, p.l, 1.4);
      body += PM('M 73 309 C 78 304.4, 85 302.4, 92 302.2', null, p.l, 1.1, op(0.55));
      if (back) body += P('M 120 186 L 120 322', null, p.l, 1, op(0.45));
      else body += P('M 154 290 C 140 299, 120 303, 100 301', null, p.l, 1.1, op(0.5)) + P('M 72 236 C 78 250, 82 262, 84 274', null, p.l, 1.1, op(0.4));
      sl += PM(SLV.blouse, p.f, p.l, 1.5);
      sl += PM('M 24.6 335 C 33.4 338.5, 47.4 338.5, 57.5 335.5 L 56.5 349.5 C 46 352, 34 352, 26.4 349.5 Z', p.f, p.l, 1.5);
      sl += PM('M 30.5 339.8 L 30.8 349.2 M 36 340.4 L 36.1 350 M 41.5 340.6 L 41.5 350.3 M 47 340.4 L 46.9 350 M 52.2 339.6 L 52 349.2', null, p.l, 1, op(0.6));
      sl += PM('M 22.6 318 C 30 326, 42 328, 56 324', null, p.l, 1.1, op(0.6)) + PM('M 25 294 C 32 300, 44 301, 52 297', null, p.l, 1.1, op(0.5)) +
        PM('M 30 262 C 36 267, 44 268, 50 265', null, p.l, 1.1, op(0.4));
      sl += PM('M 31 232 C 30 248, 28 262, 26 276', null, p.h, 2.2, op(0.8));
    }
    return { body: body, sleeves: sl, tucked: !!g.tucked, blouse: g.tucked ? blouseOver(p) : '', long: k === 'sweater' || k === 'knit' };
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

  // Layer sleeve: runs down the forearm and straight into the hand pocket. Its outer edge meets
  // the pocket line at A; everything below the line is clipped off, so the cuff ends exactly
  // on the pocket opening (front) or tucks behind the hip (back).
  function layerSleeveD(A) {
    return 'M 46 198 C 35 202, 28 214, 26 232 C 23 262, 20 300, 20.4 330 C 20.8 352, 26 380, ' + pt(A[0], A[1]) +
      ' L ' + pt(A[0] + 3, A[1] + 12) + ' L 64 404 L 58.6 387.6 C 58.6 370, 59.6 350, 60.8 330 C 61.8 300, 62 262, 60 244 C 58 226, 54.4 208, 46 198 Z';
  }

  // under: { pal, long } for the top worn beneath. Only a long-sleeved top (sweater, knit)
  // shows a narrow cuff between the layer sleeve and the pocket, clipped to the sleeve.
  function longSleeve(c, p, under, extra, A) {
    var d = layerSleeveD(A), s = '';
    s += PM(d, p.f, p.l, 1.5);
    s += PM('M 25.6 250 C 23.6 280, 22.4 310, 22.6 340', null, p.h, 2.2, op(0.8));
    s += PM('M 29 290 C 37 294, 48 295, 56 292', null, p.l, 1.1, op(0.5)) + PM('M 26 326 C 35 330, 47 331, 58 328', null, p.l, 1.1, op(0.45));
    s += PM('M 57.4 262 C 58.4 300, 58 340, 56.8 386', null, p.s, 2.6, op(0.7));
    s += extra || '';
    if (under && under.long) {
      var u = under.pal, y10 = lineY(10), y70 = lineY(70);
      var band = 'M 10 ' + r2(y10 + 2) + ' L 70 ' + r2(y70 + 2) + ' L 70 ' + r2(y70 - 6) + ' L 10 ' + r2(y10 - 6) + ' Z';
      var rib = '';
      for (var x = 27; x <= 60; x += 3.2) rib += 'M ' + pt(x, lineY(x) - 0.8) + ' L ' + pt(x + 0.6, lineY(x) - 5.2) + ' ';
      s += clipTo(c, d + ' ' + mir(d),
        PM(band, u.f, null) + PM(rib, null, u.l, 0.9, op(0.6)) + PM('M 10 ' + r2(y10 - 6) + ' L 70 ' + r2(y70 - 6), null, u.l, 1.2));
      s += clipTo(c, band + ' ' + mir(band), PM(d, null, u.l, 1.5));
    }
    var B = [58.7, lineY(58.7)];
    return clipTo(c, SLEEVE_CLIP, s) + PM('M ' + pt(A[0], A[1]) + ' L ' + pt(B[0], B[1]), null, p.l, 1.5);
  }

  // Jacket side contour from the underarm to the hem: front and back views share it, and it
  // always reaches past the hip line of any bottom or dress underneath (x 37.8 at y 404).
  var BLAZER_SIDE = [[52, 252], [46, 300, 38.6, 372, 36.6, 431]];
  var CARDI_SIDE = [[52, 252], [46, 300, 38.4, 380, 36.2, 440]];
  var TRENCH_SIDE = [[58, 252], [59.5, 288, 62, 306, 62.4, 321], [62.2, 338], [61.4, 350, 46, 356, 42, 368], [39.4, 380, 38, 392, 37.8, 404], [33.6, 452, 26, 560, 20, 632]];
  var SHOULDER = [[86, 190, 64, 194, 46, 199], [41, 202, 39, 209, 41, 218]];
  var SHOULDER_J = [[88, 190, 66, 194, 47, 199], [42, 202, 40, 209, 42, 218]];
  var BACK_NECK = [[120, 182.5], [110, 182.5, 104, 183.6, 101, 186]];

  function layerPiece(c, g, back, under) {
    var p = gPal(g), k = g.kind, body = '', sl = '', pocket = '';
    var button = mix(p.l, '#3A2A22', 0.35);
    // slant welt on the hip; the hand goes in here
    var welt = PM('M 63.6 384 L 37.8 404 L 39.9 407.2 L 65.2 387 Z', p.f, p.l, 1.2) + PM('M 63 386.6 L 39.6 404.8', null, p.h, 0.9, op(0.8));
    if (k === 'trench') {
      var tr = back ? sym(BACK_NECK.concat(SHOULDER, TRENCH_SIDE, [[56, 637.6, 96, 639, 120, 639]]))
        : sym([[120, 246], [104, 186]].concat(SHOULDER, TRENCH_SIDE, [[56, 637.6, 96, 639, 120, 639]]));
      body += P(tr, p.f, null);
      body += clipTo(c, tr, PM('M 36.2 446 C 33.4 510, 28.6 570, 24 628', null, p.s, 4.4, op(0.8)) +
        PM('M 40.4 410 C 39.8 420, 39.2 430, 38.6 440', null, p.s, 2.6, op(0.6)));
      body += P(tr, null, p.l, 1.5);
      body += PM('M 22 622 C 56 628, 96 629.6, 120 629.6', null, p.d, 1.1, op(0.7));
      if (!back) {
        // storm flap on her right chest, under the lapel
        body += P('M 99 189.4 L 60.4 196.4 C 59.4 214, 60 236, 62.4 256 C 72 260.4, 84 262, 93.6 261 C 96 240, 98 214, 99 189.4 Z', p.f, p.l, 1.3);
        body += P('M 63.4 252 C 72 256, 84 257.6, 93.4 256.6', null, p.l, 1, op(0.6)) + CIR(88, 251, 2.2, button, p.l, 0.8);
        body += P('M 121 246 L 137.4 258 L 138 630', null, p.l, 1.5);
        // collar and lapels, with the top showing as a V at the neck
        body += PM('M 104 186 L 119 243 L 80.6 220 L 85.4 211.4 L 91.4 214.6 L 97.4 187.4 Z', p.f, p.l, 1.5);
        body += PM('M 91.4 214.6 L 103 222', null, p.l, 1.1, op(0.8)) + PM('M 98.6 192 L 116 240', null, p.h, 1.4, op(0.7));
        body += each([268, 298, 360, 392], function (y) { return CIR(104, y, 2.8, button, p.l, 0.9) + CIR(130, y, 2.8, button, p.l, 0.9); });
        body += PM('M 94 191 L 52 201.4 L 53.6 209.4 L 95.4 199 Z', p.f, p.l, 1.3) + CM(58.6, 205.4, 1.8, button);
        body += P('M 138 380 C 137.6 450, 137.6 540, 138 626', null, p.s, 3, op(0.6));
      } else {
        // back yoke (storm shield), centre seam and vent
        body += P(sym([[120, 184], [110, 184, 104, 185, 101, 186.4], [86, 190.4, 64, 194.4, 46.4, 199.4], [41.4, 202.4, 39.4, 209.4, 41.4, 218.4], [58.2, 252], [80, 257, 100, 259.4, 120, 259.4]]), p.f, p.l, 1.4);
        body += P('M 120 259 L 120 550 L 126 558 L 126 638', null, p.l, 1.4) + P('M 120 550 L 120 638', null, p.l, 1.1, op(0.6));
        body += PM('M 94 191 L 52 201.4 L 53.6 209.4 L 95.4 199 Z', p.f, p.l, 1.3);
      }
      // belt with buckle and tail
      body += P(sym([[120, 321], [100, 321, 80, 321.4, 62.4, 322], [62.2, 337.4], [80, 337.8, 100, 338.2, 120, 338.2]]), p.f, p.l, 1.4);
      body += P(sym([[120, 323.6], [100, 323.6, 80, 324, 63.6, 324.6]]).split(' L ')[0], null, p.h, 1.2, op(0.7));
      if (!back) {
        body += P('M 100 317.6 L 115 317.6 C 116.4 317.6, 117 318.4, 117 319.6 L 117 339.6 C 117 340.8, 116.4 341.4, 115 341.4 L 100 341.4 C 98.6 341.4, 98 340.8, 98 339.6 L 98 319.6 C 98 318.4, 98.6 317.6, 100 317.6 Z', null, '#7C5A34', 1.6);
        body += P('M 103 329.6 L 113 329.6', null, '#7C5A34', 1.4);
        body += P('M 112 337 C 114 350, 113 362, 110 372 L 103.6 370.4 C 106.4 360, 107 350, 105.6 338 Z', p.f, p.l, 1.3);
      } else {
        body += PM('M 92 318.6 L 92 340.6 L 97 340.6 L 97 318.6 Z', p.f, p.l, 1.2);
      }
      sl += longSleeve(c, p, under,
        PM('M 21.4 348.6 C 34 351.4, 47 352.6, 60.4 352.8 L 60.2 360 C 47 359.8, 34 358.6, 22.3 356 Z', p.f, p.l, 1.2) +
        PM('M 43.6 350.8 L 49.6 351.4 L 49.4 359.4 L 43.4 358.8 Z', null, '#7C5A34', 1.2) + PM('M 46.6 351.2 L 46.4 359', null, '#7C5A34', 1), LP_A);
      if (!back) pocket += welt;
    } else if (k === 'cardigan') {
      var cpA = [39.6, lineY(39.6)];
      if (back) {
        var cb = sym(BACK_NECK.concat(SHOULDER_J, CARDI_SIDE, [[80, 441.4, 100, 442, 120, 442]]));
        body += P(cb, p.f, null) + clipTo(c, cb, PM('M 62 230 C 56 300, 51 360, 48 428', null, p.s, 3, op(0.7))) + P(cb, null, p.l, 1.5);
        body += P(sym([[120, 429.4], [100, 429.4, 70, 428.6, 36.7, 427.4], [36.2, 440], [80, 441.4, 100, 442, 120, 442]]), p.f, p.l, 1.4);
        body += ribs(40, 200, 430.4, 440, 4, p.d, 1, 0.8);
        body += P(backNeck(5), p.f, p.l, 1.4);
      } else {
        var cpl = 'M 103 185 C 88 189, 66 193, 47 199 C 42 202, 40 209, 42 218 L 52 252 C 46 300, 38.4 380, 36.2 440 L 98.2 442 C 98.6 400, 99.2 330, 100.2 296 C 101.2 260, 103.4 220, 107 187.6 C 106 186.4, 104.6 185.4, 103 185 Z';
        body += PM(cpl, p.f, null) + clipTo(c, cpl + ' ' + mir(cpl), PM('M 61 300 C 62 330, 62.2 356, 62 380', null, p.s, 3, op(0.8)) +
          PM('M 40.6 428 C 40 410, 40.4 380, 44 350', null, p.s, 2.4, op(0.5))) + PM(cpl, null, p.l, 1.5);
        body += PM('M 36.7 427 L 98.3 428.8 L 98.2 442 L 36.2 440 Z', p.f, p.l, 1.4);
        body += PM(ribPath(40, 95, 429.8, 440, 4), null, p.d, 1, op(0.8));
        body += PM('M 107 187.6 C 103.4 220, 101.2 260, 100.2 296 C 99.2 330, 98.6 390, 98.2 442 L 92.2 442 C 92.6 390, 93.2 330, 94.2 296 C 95.2 258, 97.4 220, 101 187.4 Z', p.f, p.l, 1.3);
        // gold buttons
        body += each([232, 266, 300, 334, 368, 402], function (y) { return CIR(96.4 + (y - 232) * -0.004, y, 2.7, '#E7BC6E', '#B98632', 0.9) + CIR(95.6, y - 0.8, 0.8, '#FFF3D0', null, 0, op(0.9)); });
        body += each([232, 266, 300, 334, 368, 402], function (y) { return P('M 141.4 ' + y + ' L 145.6 ' + y, null, p.d, 1.3); });
        // patch pockets with a slanted ribbed top; the hands sit in them
        var ptop = function (x) { return lineY(x); };
        var PP = 'M ' + pt(65.4, ptop(65.4)) + ' L ' + pt(39.6, ptop(39.6)) + ' L 39.6 419.4 C 39.6 421, 40.4 421.8, 42 421.8 L 64 421.2 C 65.6 421.2, 66.4 420.4, 66.4 418.8 L 66.2 ' + r2(ptop(65.4) + 0.6) + ' Z';
        var PB = 'M ' + pt(65.4, ptop(65.4)) + ' L ' + pt(39.6, ptop(39.6)) + ' L ' + pt(39.6, ptop(39.6) + 6.4) + ' L ' + pt(66.2, ptop(66.2) + 6.4) + ' Z';
        var prib = '';
        for (var rx = 42.4; rx <= 64; rx += 3) prib += 'M ' + pt(rx, ptop(rx) + 1) + ' L ' + pt(rx + 0.2, ptop(rx) + 5.6) + ' ';
        pocket += PM(PP, p.f, p.l, 1.3) + PM(PB, p.f, p.l, 1.1) + PM(prib, null, p.d, 0.9, op(0.8)) + PM('M 43 418 C 52 418.6, 58 418.4, 63.4 417.8', null, p.s, 1.4, op(0.7));
      }
      sl += longSleeve(c, p, under, '', cpA);
    } else {
      // blazer (also the cut used for the brown jacket)
      if (back) {
        var bb = sym(BACK_NECK.concat(SHOULDER_J, BLAZER_SIDE, [[60, 431.4, 90, 431.6, 120, 431.6]]));
        body += P(bb, p.f, null);
        body += clipTo(c, bb, PM('M 60 236 C 54 300, 48 360, 45 428', null, p.s, 3, op(0.7)));
        body += P(bb, null, p.l, 1.5);
        body += P('M 120 184 L 120 388 L 125 393 L 125 431.6', null, p.l, 1.4) + P('M 120 388 L 120 431.6', null, p.l, 1.1, op(0.6));
        body += PM('M 84 232 C 80 290, 78 360, 78.6 430', null, p.l, 1.1, op(0.5));
        body += P(backNeck(5), p.s, p.l, 1.4);
      } else {
        var bpl = 'M 104 185 C 88 189, 66 193, 47 199 C 42 202, 40 209, 42 218 L 52 252 C 46 300, 38.6 372, 36.6 431 C 56 433, 78 433.6, 90 432.6 C 94.6 432, 97 429.6, 97.2 425.6 C 97.8 400, 98.6 360, 100.2 302 C 101.2 268, 103.4 226, 108 188 C 107 186.4, 105.6 185.4, 104 185 Z';
        body += PM(bpl, p.f, null);
        body += clipTo(c, bpl + ' ' + mir(bpl), PM('M 60.4 300 C 61.4 330, 61.6 356, 61.4 380', null, p.s, 3, op(0.8)) +
          PM('M 40.4 410 C 39.8 418, 39.4 424, 39 430', null, p.s, 2.6, op(0.6)));
        body += PM(bpl, null, p.l, 1.5);
        body += PM('M 108 188 C 103.4 226, 101.2 268, 100.2 302 C 100.6 290, 101.6 278, 103 268 C 104.6 240, 106.4 214, 108 188 Z', p.s, null);
        // two-tone lapel: lighter facing, darker roll edge
        body += PM('M 108 188 C 103.6 226, 101.4 268, 100.2 302 L 83.4 225 L 89 217.6 L 93.6 220.8 C 96 209, 100 196.4, 104.4 186 Z', p.h, p.l, 1.4);
        body += PM('M 100.2 302 L 83.4 225 L 86.6 225.6 L 101.6 290 Z', p.s, null, 0, op(0.8));
        body += PM('M 93.6 220.8 L 104.2 228.6', null, p.l, 1.1, op(0.8));
        body += P('M 146 266 L 164.4 264 L 164.8 268.6 L 146.4 270.6 Z', p.f, p.l, 1.1);
        body += PM('M 84 236 C 80 300, 79 360, 79.8 428', null, p.l, 1.1, op(0.5));
        body += CIR(97.8, 336, 3, button, p.l, 1) + CIR(97.2, 335.4, 0.8, '#FFFFFF', null, 0, op(0.5)) + P('M 143.4 336 L 148.4 336', null, p.l, 1.4);
      }
      sl += longSleeve(c, p, under, PM('M 24.4 368 C 35 370.6, 47 372.4, 59.1 373.4', null, p.l, 1.1, op(0.8)) +
        CM(30.6, 375.4, 1.5, button) + CM(32.8, 380.6, 1.5, button) + CM(35.4, 385.8, 1.5, button), LP_A);
      if (!back) pocket += welt;
    }
    return { body: body, sleeves: sl, pocket: pocket };
  }

  /* ------------------------------------------------------------------ bottoms and dress */

  // Waist at x 75 (88 wide), a smooth curve out to the hip at x 39.2, then the leg drops nearly straight.
  var HIP = [[120, 317.5], [100, 317, 86, 318, 76, 320], [75, 341], [64, 352, 40.6, 376, 39.2, 410]];
  // Leg cuts: outer hip-to-hem curve (o1, o2 to ho, hy), hem, inner hem-to-crotch curve (i1, i2).
  var CUTS = {
    trousers: { o1: [37.6, 480], o2: [32.4, 650], ho: 29.6, hy: 814, hi: 99, i1: [100.4, 710], i2: [110, 566] },
    jeans:    { o1: [35.4, 474], o2: [21, 640], ho: 12, hy: 800, hi: 107.4, i1: [109, 700], i2: [112.4, 560] },
    tapered:  { o1: [38.4, 482], o2: [42.4, 662], ho: 46, hy: 804, hi: 97.4, i1: [98.6, 692], i2: [107, 560] }
  };
  function pantsD(q) {
    return sym(HIP.concat([[q.o1[0], q.o1[1], q.o2[0], q.o2[1], q.ho, q.hy],
      [q.ho + (q.hi - q.ho) * 0.33, q.hy + 5, q.hi - (q.hi - q.ho) * 0.32, q.hy + 8, q.hi, q.hy + 6],
      [q.i1[0], q.i1[1], q.i2[0], q.i2[1], 120, 438]]));
  }
  var LEGGINGS_D = sym(HIP.concat([[38.6, 452, 42.4, 516, 49.4, 566], [53.4, 592, 58.4, 610, 58.8, 628], [60, 650, 53.4, 672, 54, 700], [54.8, 742, 58.6, 784, 59.6, 816],
    [66, 817.4, 73, 817.6, 79.6, 817], [80, 786, 81.6, 752, 83.6, 722], [87.6, 692, 88.6, 660, 83.4, 630], [87, 590, 101, 520, 120, 438]]));
  // A band laid across the bottom of a leg: from the hem up by h (cuffs, rolled hems).
  function hemBand(q, h) {
    var a = q.ho + 0.6, b = q.hi - 0.4;
    return 'M ' + pt(a + 0.4, q.hy - h) + ' C ' + pt(a + (b - a) * 0.33, q.hy - h + 5) + ' ' + pt(b - (b - a) * 0.32, q.hy - h + 8) + ' ' + pt(b + 0.1, q.hy - h + 6) +
      ' L ' + pt(b, q.hy + 6) + ' C ' + pt(b - (b - a) * 0.32, q.hy + 8) + ' ' + pt(a + (b - a) * 0.33, q.hy + 5) + ' ' + pt(a, q.hy) + ' Z';
  }

  function bottomPiece(c, g, back) {
    var p = gPal(g), k = g.kind, main = '', band = '', pocket = '';
    var WB = sym([[120, 317.5], [100, 317, 86, 318, 76, 320], [75, 341], [88, 339.2, 104, 338.6, 120, 338.6]]);
    var BAND_LINE = 'M 75.6 337.4 C 88 336, 104 335.4, 120 335.4';
    // front slant pocket: the upper half sits under any untucked hem; the lower half is drawn
    // after the hand, which is clipped to the line, so it reads as the hand going in
    var upper = back ? '' : PM(POCKET_UPPER, null, p.l, 1.4);
    if (!back) pocket += PM(POCKET_LOWER, null, p.l, 1.4);
    if (k === 'skirt') {
      // pleated midi: knife pleats fan out from the hip to a softly scalloped hem
      var hem = [[26, 636], [42, 638], [58, 639.6], [73, 640.6], [88, 641.2], [104, 641.6], [120, 641.8]];
      var left = HIP.concat([[35, 470, 30, 560, 26, 636]]);
      for (var i = 1; i < hem.length; i++) left.push([(hem[i - 1][0] + hem[i][0]) / 2, Math.max(hem[i - 1][1], hem[i][1]) + 5.4, hem[i][0], hem[i][1]]);
      var sd = sym(left);
      main += P(sd, p.f, null);
      var pl = '';
      for (var j = 1; j <= 6; j++) {
        var wx = 76 + 44 * (j / 6), hx = hem[j][0], hy = hem[j][1];
        if (j % 2 === 1 && j < 6) {
          var nx = hem[j + 1][0], ny = hem[j + 1][1], wx2 = 76 + 44 * ((j + 1) / 6);
          var panel = 'M ' + pt(wx, 352) + ' L ' + pt(hx, hy) + ' Q ' + pt((hx + nx) / 2, Math.max(hy, ny) + 5.4) + ' ' + pt(nx, ny) + ' L ' + pt(wx2, 352) + ' Z';
          pl += P(panel, p.s, null, 0, op(0.85)) + P(mir(panel), p.s, null, 0, op(0.85));
        }
        if (j < 6) pl += PM('M ' + pt(wx, 350) + ' L ' + pt(hx, hy), null, p.d, 1.1, op(0.9));
        else pl += P('M 120 350 L 120 ' + hy, null, p.d, 1.1, op(0.9));
      }
      pl += PM('M 48 470 C 44 540, 40 590, 37.4 630', null, p.h, 3, op(0.45)) + PM('M 82 440 C 79 520, 77 580, 75.6 632', null, p.h, 2, op(0.35));
      main += clipTo(c, sd, pl) + P(sd, null, p.l, 1.5);
      band += P(WB, p.h, p.l, 1.4);
      band += P(sym([[120, 321.4], [100, 321, 86, 322, 76.4, 323.6]]).split(' L ')[0], null, lighten(p.h, 0.25), 1, op(0.8));
      if (back) main += P('M 120 341 L 120 404', null, p.l, 1.4) + P('M 118 343 L 122 343 L 122 349 L 118 349 Z', '#9A9AA6', p.l, 0.8);
      else band += CIR(150, 329, 2.4, '#9A9AA6', p.l, 0.9);
      return { main: main + upper, band: band, pocket: pocket };
    }
    if (k === 'leggings') {
      main += P(LEGGINGS_D, p.f, p.l, 1.5);
      main += PM('M 82 452 C 70 540, 64 620, 63 700 C 62.4 740, 64 780, 65 812', null, p.h, 2.4, op(0.5));
      main += PM('M 116 450 C 104 520, 90 580, 86 630', null, p.s, 3, op(0.6));
      main += PM('M 60.6 806 C 66 807.2, 73 807.4, 79 806.8', null, p.d, 1, op(0.7));
      main += P(back ? 'M 120 341 C 120 380, 118 410, 120 438' : 'M 120 342 L 120 404', null, p.l, 1.3, op(0.8));
      band += P(WB, p.f, p.l, 1.4) + PM(BAND_LINE, null, p.d, 0.9, op(0.7));
      return { main: main + upper, band: band, pocket: pocket };
    }
    var q = CUTS[k] || CUTS.trousers, jeans = k === 'jeans', tap = k === 'tapered';
    var dmain = pantsD(q), legs = '';
    // depth: inner leg shade, and an outer edge shade that tapers in from nothing at the hip
    legs += PM('M 120 440 C 110 560, ' + pt(q.hi + 1.6, 700) + ', ' + pt(q.hi, q.hy + 5) + ' L ' + pt(q.hi - 8, q.hy + 6) + ' C ' + pt(q.hi - 5, 700) + ', 104 560, 116.6 448 Z', p.s, null);
    legs += PM('M 39.2 410 C ' + pt(q.o1[0], q.o1[1]) + ', ' + pt(q.o2[0], q.o2[1]) + ', ' + pt(q.ho, q.hy) + ' L ' + pt(q.ho + 6.4, q.hy + 1) +
      ' C ' + pt(q.o2[0] + 6.4, q.o2[1]) + ', ' + pt(q.o1[0] + 3.6, q.o1[1] + 6) + ', 39.6 414 Z', p.s, null, 0, op(0.7));
    main += P(dmain, p.f, null) + clipTo(c, dmain, legs) + P(dmain, null, p.l, 1.5);
    var mid = (q.ho + q.hi) / 2;
    if (jeans) {
      main += PM('M 80 430 C 78 500, 72 580, 64 660', null, p.h, 6, op(0.22));
      // rolled hem in the lighter inside of the denim
      main += PM(hemBand(q, 15), p.h, p.l, 1.3) + PM('M ' + pt(q.ho + 2, q.hy - 9) + ' C ' + pt(q.ho + 30, q.hy - 4) + ' ' + pt(q.hi - 30, q.hy - 1) + ' ' + pt(q.hi - 1, q.hy - 3), null, p.d, 0.9, op(0.9));
      if (!back) {
        main += P('M 117.6 339 L 117.6 404', null, p.l, 1.4) + P('M 126 341 L 126 393 C 126 401, 122 405, 117.6 405', null, p.d, 1.1);
        main += P('M 142 343 L 156.4 342 L 157 352.6 L 142.6 353.6 Z', null, p.d, 1);
        main += PM('M 80.2 341.4 L 64.6 369.6', null, p.d, 1, op(0.9));
        pocket += PM('M 64.6 369.6 L 43 407.6', null, p.d, 1, op(0.9));
      } else {
        main += P('M 120 338.4 C 120 380, 118 410, 120 438', null, p.l, 1.4);
        main += PM('M 78 352 L 106 355 L 104.4 386 L 92.4 393 L 80.4 384 Z', null, p.l, 1.2) + PM('M 80 356 L 104.6 358.6', null, p.d, 1, op(0.9));
        main += PM('M 98 330 L 120 334', null, p.d, 1, op(0.7));
      }
      band += P(WB, p.f, p.l, 1.4) + PM(BAND_LINE, null, p.d, 1, op(0.9));
      band += PM('M 90 318 L 94.6 317.8 L 95 344.6 L 90.4 344.8 Z', p.f, p.l, 1.2);
      if (!back) band += CIR(124, 328, 3.2, '#C98A49', '#8C5A26', 1.1) + CIR(123.2, 327.2, 0.9, '#F2C88E');
    } else {
      main += PM('M 89 398 C 82 520, ' + pt(mid + 6, 660) + ', ' + pt(mid, q.hy), null, p.l, 1.1, op(0.55));
      if (tap) {
        // turned-up cuffs
        main += PM(hemBand(q, 15), p.f, p.l, 1.3) + PM('M ' + pt(q.ho + 2, q.hy - 11) + ' C ' + pt(q.ho + 22, q.hy - 7) + ' ' + pt(q.hi - 20, q.hy - 5) + ' ' + pt(q.hi - 1, q.hy - 6), null, p.h, 1.2, op(0.7));
        main += PM('M ' + pt(q.ho + 3, q.hy - 18) + ' C ' + pt(q.ho + 20, q.hy - 22) + ' ' + pt(q.hi - 18, q.hy - 20) + ' ' + pt(q.hi - 3, q.hy - 17), null, p.d, 1, op(0.6));
      } else main += PM('M ' + pt(q.ho + 1.2, q.hy - 5) + ' C ' + pt(q.ho + 24, q.hy) + ' ' + pt(q.hi - 24, q.hy + 2.4) + ' ' + pt(q.hi - 1, q.hy + 0.6), null, p.d, 1, op(0.7));
      if (!back) {
        main += P('M 117.6 339 L 117.6 406', null, p.l, 1.4) + P('M 126 341 L 126 394 C 126 402, 122 406, 117.6 406', null, p.d, 1.1);
        main += PM('M 96 340 C 95 352, 94 364, 92.6 378', null, p.l, 1.3);
      } else {
        main += P('M 120 338.4 C 120 380, 118 410, 120 438', null, p.l, 1.4);
        main += PM('M 82 362 L 104 364', null, p.l, 1.5) + CM(93, 367.6, 1.6, p.d);
        main += PM('M 98 330 L 120 334', null, p.d, 1, op(0.7));
      }
      band += P(WB, p.f, p.l, 1.4);
      band += PM('M 89.6 318 L 94.6 317.8 L 95 344.6 L 90 344.8 Z', p.f, p.l, 1.2);
      if (!back) band += CIR(124, 328, 3, '#B9BCC8', p.l, 1) + CIR(123.2, 327.2, 0.8, '#FFFFFF', null, 0, op(0.7));
    }
    return { main: main + upper, band: band, pocket: pocket };
  }

  var FLOWERS = [[86, 226], [150, 222], [112, 250], [76, 272], [138, 276], [162, 258], [96, 298], [124, 304], [156, 300],
    [82, 352], [110, 360], [142, 350], [166, 372], [92, 392], [124, 398], [150, 410], [70, 436], [102, 432], [132, 440], [160, 446],
    [56, 470], [86, 474], [118, 478], [148, 480], [180, 470], [64, 516], [96, 520], [130, 514], [162, 522], [190, 512],
    [50, 560], [80, 562], [112, 566], [144, 558], [174, 566], [62, 604], [94, 608], [126, 600], [158, 606], [186, 600], [40, 610], [200, 556]];

  function dressPiece(c, g, back) {
    var p = gPal(g), main = '', pocket = '', sl = '';
    var skirt = sym([[120, 320], [100, 320, 86, 320, 74.4, 322]].concat(HIP.slice(3), [[34.6, 470, 27, 570, 23, 646], [37, 652, 53, 648, 67, 653], [81, 658, 96, 651, 108, 656], [112, 657.6, 116, 656, 120, 655.4]]));
    main += P(skirt, p.f, null);
    main += clipTo(c, skirt, PM('M 80 334 C 74 420, 64 540, 57 650 M 99 336 C 99 440, 97 560, 95 654', null, p.l, 1.1, op(0.45)) +
      PM('M 31.6 540 C 29 580, 27.4 616, 26 646', null, p.s, 4, op(0.8)));
    main += P(skirt, null, p.l, 1.5);
    // bodice with a V neckline
    main += P(vTorsoD(22, back ? 0 : 236, 320, back), p.f, p.l, 1.5);
    if (!back) main += P('M 99.6 189 L 120 230.4 L 140.4 189', null, p.l, 1, op(0.6)) + P('M 120 236 L 120 241', null, p.l, 1, op(0.6));
    else main += P('M 120 184 L 120 320', null, p.l, 1.3) + P('M 118.4 186 L 121.6 186 L 121.6 193 L 118.4 193 Z', '#D9DDE6', p.l, 0.8);
    main += ribs(78, 162, 330, 337, 6, p.l, 0.9, 0.4);
    main += each(FLOWERS, function (q, i) {
      var x = q[0], y = q[1];
      if (y < 330 && (x < 72 || x > 168)) return '';
      if (!back && y < 246 && Math.abs(x - 120) < 26) return '';
      var col = i % 3 === 0 ? '#FFFFFF' : (i % 3 === 1 ? '#FFF4E2' : '#F7D6E0');
      // a small sage leaf tucked under every other flower (light, so it never reads as a shadow)
      var leaf = i % 2 ? '' : P('M ' + pt(x + 2.4, y + 2.2) + ' Q ' + pt(x + 7.4, y + 1.6) + ' ' + pt(x + 9.2, y + 5.6) + ' Q ' + pt(x + 4.4, y + 6.6) + ' ' + pt(x + 2.4, y + 2.2) + ' Z', '#B9D9B4', null) +
        P('M ' + pt(x + 3.4, y + 3) + ' L ' + pt(x + 8, y + 5), null, '#8DBB8E', 0.6);
      return leaf + CIR(x - 2.5, y - 0.6, 2.1, col) + CIR(x + 2.5, y - 0.6, 2.1, col) + CIR(x - 1.5, y + 2.2, 2.1, col) + CIR(x + 1.5, y + 2.2, 2.1, col) + CIR(x, y - 2.6, 2.1, col) + CIR(x, y + 0.2, 1.3, '#F2C25C');
    });
    // self-fabric tie belt, bow at the front
    main += P(sym([[120, 317.6], [100, 317.6, 86, 318.2, 74.8, 318.8], [74.4, 329], [86, 329.8, 102, 330.4, 120, 330.4]]), p.s, p.l, 1.3);
    main += P(sym([[120, 320.4], [100, 320.4, 86, 321, 75.4, 321.6]]).split(' L ')[0], null, p.h, 1.1, op(0.7));
    if (!back) {
      var bow = '';
      bow += P('M 129.4 326.6 C 127 336, 124.4 346, 121.4 356 L 124 354.4 L 126 357.4 C 128.6 347, 130.6 337, 132 327.4 Z', p.f, p.l, 1.1);
      bow += P('M 132.6 326.6 C 135.4 336, 138 346, 141 354.6 L 138.2 353.6 L 136.8 356.8 C 134.6 346.6, 132.8 337, 130.6 327.4 Z', p.f, p.l, 1.1);
      bow += P('M 131 324 C 124.6 316.4, 116.4 317, 117 323.4 C 117.6 330, 125 330.6, 131 324 Z', p.f, p.l, 1.2) + P('M 131 324 C 137.4 316.4, 145.6 317, 145 323.4 C 144.4 330, 137 330.6, 131 324 Z', p.f, p.l, 1.2);
      bow += P('M 121 323.4 C 123.6 322, 126.6 322.4, 129 323.6 M 141 323.4 C 138.4 322, 135.4 322.4, 133 323.6', null, p.l, 0.9, op(0.7));
      bow += '<ellipse cx="131" cy="324.2" rx="3" ry="3.4" fill="' + p.s + '" stroke="' + p.l + '" stroke-width="1.1"/>';
      main += '<g transform="matrix(1.25 0 0 1.25 -32.75 -81)">' + bow + '</g>';
      main += PM(POCKET_UPPER, null, p.l, 1.3);
      pocket += PM(POCKET_LOWER, null, p.l, 1.3);
    }
    sl += PM(SLV.flutter, p.f, p.l, 1.5);
    sl += PM('M 36 222 C 34 232, 33 242, 34 252', null, p.l, 1, op(0.5)) + PM('M 46 214 C 45 228, 46 242, 47 254', null, p.l, 1, op(0.5));
    sl += each([[40, 236], [mx(40), 236]], function (q) { return CIR(q[0] - 1.6, q[1], 1.5, '#FFFFFF') + CIR(q[0] + 1.6, q[1], 1.5, '#FFFFFF') + CIR(q[0], q[1] - 1.6, 1.5, '#FFFFFF') + CIR(q[0], q[1] + 1.6, 1.5, '#FFFFFF') + CIR(q[0], q[1], 0.9, '#F2C25C'); });
    return { main: main, pocket: pocket, sleeves: sl };
  }

  /* ------------------------------------------------------------------ shoes (left foot drawn, right mirrored) */

  function footSkin(c, d) {
    var k = c.skin;
    return PM(d, k.f, null) + PM(d.replace(/ Z$/, ''), null, k.l, 1.5);
  }

  // Front view: the feet turn out about 35 degrees, so each shoe is seen in three-quarter view,
  // toe forward and out (left foot toe to the viewer's left), heel tucked behind the ankle.
  // Back view: a heel counter on its sole, with a thin sliver of toe past the heel on the outside.
  function shoesPiece(c, g, back) {
    var p = gPal(g), k = g.kind, o = '';
    var sole = k === 'sneakers' ? '#EFE5DA' : (k === 'loafers' ? '#7A5028' : darken(p.f, lum(p.f) > 0.6 ? 0.24 : 0.18));
    var soleL = k === 'loafers' ? '#5C3A1C' : p.l;
    if (back) {
      var sliver = function (y0, x1) {
        return PM('M ' + pt(62.6, y0) + ' C ' + pt(58, y0 + 0.6) + ' ' + pt(x1 + 3, y0 + 2.6) + ' ' + pt(x1, 863.4) +
          ' C ' + pt(x1 + 3.4, 865.2) + ' ' + pt(58.6, 865.6) + ' ' + pt(62.8, 865.2) + ' Z', p.f, p.l, 1.3);
      };
      if (k === 'heels') {
        o += footSkin(c, 'M 62.5 832 C 62.4 838, 61.8 843, 61.8 849 L 78.2 849 C 78.2 843, 77.6 838, 76.8 832 Z');
        o += sliver(857.4, 52);
        o += PM('M 66.2 857 L 73.8 857 L 73.4 866 L 66.6 866 Z', p.s, p.l, 1.4);
        o += PM('M 61.4 846 C 60.4 851, 61.4 855.6, 64.4 857.6 C 67 859, 73 859, 75.6 857.6 C 78.6 855.6, 79.6 851, 78.6 846 C 74 848.6, 66 848.6, 61.4 846 Z', p.f, p.l, 1.5);
        o += PM('M 62.2 847.2 C 66.6 849.4, 73.4 849.4, 77.8 847.2', null, p.h, 1.2, op(0.7));
        o += PM('M 64 851 C 64.4 853.4, 65.6 855, 67.4 855.8', null, p.h, 1.3, op(0.8));
        return o;
      }
      if (k === 'sneakers') {
        o += sliver(855.6, 49.6);
        o += PM('M 61 834 C 59.6 846, 59.8 855, 62.4 860 C 64.6 862.6, 75.4 862.6, 77.6 860 C 80.2 855, 80.4 846, 79 834 C 74.6 836.2, 65.4 836.2, 61 834 Z', p.f, p.l, 1.5);
        o += PM('M 61.6 835.4 C 66 837.6, 74 837.6, 78.4 835.4', null, p.s, 1.4);
        o += PM('M 66.8 832.6 L 73.2 832.6 L 72.8 842.4 L 67.2 842.4 Z', '#F4B4C2', mix('#F4B4C2', p.l, 0.5), 1);
        o += PM('M 59.6 857.6 C 66 859.8, 74 859.8, 80.4 857.6 C 80.8 862.2, 78.8 865.4, 74.6 866.2 L 65.4 866.2 C 61.2 865.4, 59.2 862.2, 59.6 857.6 Z', sole, p.l, 1.2);
        o += PM('M 60.6 862 C 66 863.4, 74 863.4, 79.4 862', null, p.l, 0.8, op(0.5));
        o += PM('M 63.4 840 C 63 846, 63.4 851, 64.8 855', null, p.h, 1.5, op(0.9));
        return o;
      }
      if (k === 'loafers') {
        o += footSkin(c, 'M 62.5 832 C 62.4 838, 61.8 843, 61.8 848 L 78.2 848 C 78.2 843, 77.6 838, 76.8 832 Z');
        o += sliver(856.4, 51);
        o += PM('M 61.2 844.4 C 59.8 851.6, 60.4 858.6, 63.4 861.8 C 65.8 863.8, 74.2 863.8, 76.6 861.8 C 79.6 858.6, 80.2 851.6, 78.8 844.4 C 74.2 847.2, 65.8 847.2, 61.2 844.4 Z', p.f, p.l, 1.5);
        o += PM('M 62 845.8 C 66.4 848.4, 73.6 848.4, 78 845.8', null, p.s, 1.4);
        o += PM('M 62.4 861 C 66 864.2, 74 864.2, 77.6 861 L 77.8 863.6 C 74.6 866.6, 65.4 866.6, 62.2 863.6 Z', sole, soleL, 1);
        o += PM('M 64.4 849.6 C 64.2 853.6, 65 857, 66.6 859', null, p.h, 1.4, op(0.85));
        return o;
      }
      // mule: the bare heel rests on the sole; the vamp shows as a sliver on the outside
      o += sliver(856.8, 51);
      o += PM('M 60.6 858.6 C 62.4 862.6, 66 864, 70 864 C 74 864, 77.6 862.6, 79.4 858.6 L 79.6 861.6 C 78.2 865.2, 74.4 866.6, 70 866.6 C 65.6 866.6, 61.8 865.2, 60.4 861.6 Z', sole, p.l, 1);
      o += PM('M 60.8 857.4 C 62.4 861, 66 862.4, 70 862.4 C 74 862.4, 77.6 861, 79.2 857.4 L 79.4 858.8 C 77.8 862.8, 74 864.2, 70 864.2 C 66 864.2, 62.2 862.8, 60.6 858.8 Z', p.h, p.l, 0.9);
      o += footSkin(c, 'M 62.5 832 C 62.4 840, 61.6 847, 62 852.6 C 62.6 857.4, 65.6 860.6, 70 860.8 C 74.4 860.6, 77.4 857.4, 78 852.6 C 78.4 847, 77.6 840, 76.8 832 Z');
      o += PM('M 66 855.6 C 67.4 857.2, 69 857.8, 70.6 857.8', null, c.skin.d, 1.1, op(0.7));
      return o;
    }
    var F = '';
    if (k === 'sneakers') {
      F += P('M 33.4 856.6 C 33 862, 37.4 865.6, 44 866.4 C 56 867.4, 72 867.2, 80.6 865.6 C 84 864.8, 86 862, 85.8 857.2 C 70 860.8, 50 861.6, 33.4 856.6 Z', sole, p.l, 1.3);
      F += P('M 35.4 861.4 C 46 864, 68 864, 85 861.2', null, p.l, 0.8, op(0.55));
      F += P('M 34.4 857.2 C 32.6 852.2, 36 847.6, 42.4 845.2 C 48.4 843, 54.2 841.6, 58.6 839.4 C 60.4 836.6, 63.4 835, 67 834.8 L 75.8 835 C 79 836, 81.2 838.6, 82.2 842 C 83.8 846.4, 85.2 851.2, 85.4 857 C 70 860.4, 50 861.2, 34.4 857.2 Z', p.f, p.l, 1.5);
      // tongue and laces down the instep
      F += P('M 61.6 840.4 C 61.2 836.4, 63.8 833.6, 68.2 833.2 C 70.8 833, 72.2 834.4, 72.4 836.2 L 70.4 843 Z', p.h, p.l, 1.1);
      F += P('M 59.8 838.4 L 49.4 845.6 M 70.4 840.4 L 58.4 849.4', null, p.s, 2.4);
      var lace = '';
      [0.12, 0.38, 0.64, 0.9].forEach(function (t) { lace += 'M ' + pt(60 - 10.6 * t, 838.6 + 7.2 * t) + ' L ' + pt(70 - 11.6 * t, 840.6 + 8.8 * t) + ' '; });
      F += P(lace, null, p.l, 1.2);
      F += P('M 37.6 852.4 C 40 855.6, 44 857.4, 48.6 857.8', null, p.l, 1.1, op(0.7));
      F += P('M 39.4 850.2 C 43 847.8, 47.6 846.4, 51.6 846', null, '#FFFFFF', 1.5, op(0.95));
      F += P('M 81.8 838.6 C 83.8 841, 85 844, 85.2 847.6', null, '#F4B4C2', 2.4);
    } else if (k === 'heels') {
      F += P('M 74.4 856.4 L 82.8 854.6 L 82.6 866.2 L 75.2 866.2 Z', p.s, p.l, 1.4);
      F += footSkinOne(c, 'M 62.5 832 C 62.4 837.6, 61.4 842, 58.4 846 L 50 852.6 L 60 857.6 L 80 854.4 C 81.8 851.2, 81.4 846.4, 79.6 842.4 C 78.2 839, 77.2 835.6, 76.8 832 Z');
      F += P('M 32.4 863.4 C 37.4 859.4, 45.6 855, 54.6 853.4 C 59.6 852.6, 63.6 854.2, 67.2 855.8 C 72 857, 76.8 855.8, 80.6 852.2 C 82.6 853.2, 83.4 855.6, 83 857.8 C 76 859.8, 66 862.4, 56 864.6 C 48 866.4, 38 866.8, 33.6 865.4 C 32 864.8, 31.6 864, 32.4 863.4 Z', p.f, p.l, 1.5);
      F += P('M 55.4 855.4 C 59.6 854.8, 63.4 856.2, 66.8 857.6', null, p.s, 1.4, op(0.9));
      F += P('M 36 862.4 C 41 859.2, 47.4 856.6, 53.2 855.6', null, p.h, 1.6, op(0.95));
    } else if (k === 'loafers') {
      F += P('M 35 861 C 36 864.4, 40.6 866, 46 866.4 C 58 867, 72 866.6, 79.6 865.2 C 82.6 864.4, 84.4 862, 84.6 858.6 C 85.8 862.6, 84.8 866.6, 80.2 867.6 C 72 869, 56 869, 45.6 868.4 C 38.8 867.8, 35 865.4, 35 861 Z', sole, soleL, 1);
      F += footSkinOne(c, 'M 62.5 832 C 62.4 837, 61.6 841, 59.4 844 L 66 851 L 79.6 847 C 78.4 842, 77.2 837, 76.8 832 Z');
      F += P('M 35 860.6 C 33.6 855.2, 37.4 849.6, 44 847 C 50 844.6, 56 843.4, 60.4 843.6 C 63.2 846.8, 67.8 849.4, 73.4 849.4 C 76.4 849.4, 78.6 848, 79.8 845.6 C 82.8 846.8, 84.8 850.8, 84.8 856 C 84.8 860.6, 82.6 863.8, 78.8 864.8 C 70 866.4, 54 866.6, 44 865.8 C 38.6 865.4, 35.6 863.6, 35 860.6 Z', p.f, p.l, 1.5);
      F += P('M 60.8 845.2 C 63.6 848, 68 850.2, 73.4 850.2 C 76 850.2, 77.8 849.2, 79 847.4', null, p.s, 1.4);
      F += P('M 45 847.2 C 50.4 849, 56.4 849.4, 61.6 848 L 63 852.6 C 56.8 854.6, 49.6 854, 43.6 851.4 Z', p.s, p.l, 1.1);
      F += P('M 50.6 851.4 L 56.4 851.6', null, p.l, 1.6);
      F += P('M 80.4 848.6 C 81.2 853.4, 81 858, 79.6 862', null, p.s, 1.2, op(0.8));
      F += P('M 38.4 855.4 C 39.8 851.8, 43.4 849, 47.6 847.8', null, p.h, 1.5, op(0.85));
    } else {
      // flats: a soft nude mule with a little bow, lining showing at the heel
      F += P('M 32.2 861.4 C 33.2 864.4, 38 865.8, 45 866.2 C 58 866.8, 72 866.4, 79.2 865 C 82.4 864.2, 84.4 862, 84.8 859 C 85.8 863, 84.6 866.4, 80 867.4 C 72 868.8, 56 868.8, 44.6 868.2 C 37.2 867.6, 32.4 865, 32.2 861.4 Z', sole, p.l, 1);
      F += P('M 52 859.6 C 62 858.6, 73 856.8, 80.4 854.6 C 83.4 853.8, 85.2 856.2, 84.6 859 C 84 861.8, 81.8 863.6, 78.6 864.2 C 70 865.6, 56 865.8, 46 865.2 Z', lighten(p.f, 0.5), p.l, 1.2);
      F += footSkinOne(c, 'M 62.5 832 C 62.4 837.6, 61.4 841.6, 58.6 845 L 52 851 L 60 859 L 79.6 855.6 C 81.8 853, 81.8 848.6, 79.8 844.2 C 78.4 840.8, 77.2 836.4, 76.8 832 Z');
      F += P('M 58.8 846.2 C 51.4 845, 41.4 846.8, 35.6 851.4 C 31.8 854.6, 31 859.8, 34.4 862.8 C 38.6 865.8, 52 866.2, 60 865.4 C 64.2 865, 66.8 863.8, 67.2 861.4 C 67 856, 64 850, 58.8 846.2 Z', p.f, p.l, 1.5);
      F += P('M 59 848.2 C 62.6 851.4, 64.8 856, 65 860.8', null, p.s, 1.6, op(0.9));
      F += P('M 37.8 853.8 C 40.4 850.6, 44.6 848.6, 49 847.8', null, p.h, 1.6, op(0.95));
      F += P('M 53.4 848 C 50.4 844.6, 46.4 845, 47 847.6 C 47.6 849.8, 51 849.6, 53.4 848 Z M 53.4 848 C 56.4 844.8, 60.4 845.4, 59.8 848 C 59.2 850.2, 55.8 849.8, 53.4 848 Z', p.h, p.l, 1);
      F += P('M 53 848.4 L 50.8 852.4 M 53.8 848.4 L 56.2 852', null, p.l, 1);
      F += CIR(53.4, 848.2, 1.3, p.l);
    }
    // drawn 8 percent up from the ankle so the feet carry like the reference, and lifted so the
    // sole sits on the baseline (y 864 to 865)
    return '<g transform="matrix(1.08 0 0 1.08 -5.6 -73.4)">' + F + '</g><g transform="matrix(-1.08 0 0 1.08 245.6 -73.4)">' + F + '</g>';
  }
  function footSkinOne(c, d) {
    var k = c.skin;
    return P(d, k.f, null) + P(d.replace(/ Z$/, ''), null, k.l, 1.5);
  }

  /* ------------------------------------------------------------------ normalising */

  function extend(a, b) { var o = {}, k; for (k in a) if (Object.prototype.hasOwnProperty.call(a, k)) o[k] = a[k]; if (b) for (k in b) if (Object.prototype.hasOwnProperty.call(b, k)) o[k] = b[k]; return o; }

  var KEYS = { skin: 'skin', hairStyle: 'hairStyle', hairColor: 'hairColor', eyes: 'eyes', glasses: 'glasses', earrings: 'earrings', lips: 'lips', faceShape: 'faceShape' };
  // Appearances saved before Revision 2 have no preset or faceShape: they keep their own fields,
  // get the medium face, and are matched to the closest preset.
  function normAppearance(x) {
    var out = extend(DEFAULTS);
    if (x && typeof x === 'object') {
      for (var k in KEYS) {
        if (x[k] != null && findOpt(OPTIONS[k], String(x[k]))) out[k] = String(x[k]);
      }
      out.preset = (x.preset != null && presetById(String(x.preset))) ? String(x.preset) : inferPreset(out);
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

  /* Revision 2 portrait: head and shoulders in a plain neutral top, cropped by the bottom edge
     (viewBox 0 0 240 260). No garments. The neck and shoulders follow the face shape. */
  var PORTRAIT_TOP = { f: '#E9DED3', s: '#DDCFC2', h: '#F5EEE6', l: '#B9A491', d: '#CDBCAD' };
  function portraitBody(c) {
    var k = c.skin, sh = c.shape, nw = sh.neck, q = sh.bodySx, o = '';
    function X(x) { return 120 + (x - 120) * q; }
    // neck and the skin of the upper chest inside the neckline
    var neck = sym([[120, 128], [120 - nw, 128], [121 - nw, 150, 121 - nw, 166, 120 - nw, 178],
      [119 - nw, 185, X(98), 189, X(88), 192], [X(78), 194, X(70), 197, X(64), 200], [X(64), 230], [120, 230]]);
    o += P(neck, k.f, k.l, 1.5);
    // soft shadow down each side of the neck
    o += PM('M ' + pt(123.4 - nw, 150) + ' C ' + pt(123.6 - nw, 162) + ' ' + pt(123.4 - nw, 172) + ' ' + pt(122 - nw, 180), null, k.s, 3, op(0.75));
    // the top: a soft crew neck, rounded shoulders, cropped at the bottom edge
    var cw = nw + 5.6, nd = 199.5, ky = nd - (nd - 186) * 0.45, t = c.uid + '-top', p = PORTRAIT_TOP;
    var top = sym([[120, nd], [120 - cw * 0.55, nd, 120 - cw * 0.95, ky, 120 - cw, 186], [X(90), 189, X(68), 193, X(52), 199],
      [X(40), 203.6, X(32.4), 213, X(30), 228], [X(28.4), 240, X(27.6), 252, X(27.2), 264], [120, 264]]);
    c.defs.push('<clipPath id="' + t + '"><path d="' + top + '"/></clipPath>');
    o += P(top, p.f, null);
    o += '<g clip-path="url(#' + t + ')">' +
      // underarm and side shade, shoulder highlight, sleeve seams
      PM('M ' + pt(X(30), 236) + ' C ' + pt(X(36), 240) + ' ' + pt(X(44), 246) + ' ' + pt(X(52), 264) + ' L ' + pt(X(20), 264) + ' Z', p.s, null) +
      PM('M ' + pt(X(40), 207) + ' C ' + pt(X(46), 203.4) + ' ' + pt(X(56), 200.4) + ' ' + pt(X(68), 198.4), null, p.h, 3, op(0.9)) +
      PM('M ' + pt(X(52), 200) + ' C ' + pt(X(56), 216) + ' ' + pt(X(58), 238) + ' ' + pt(X(58.6), 264), null, p.d, 1.1, op(0.8)) +
      // a soft fold under the neckline
      P('M ' + pt(120 - cw * 0.7, nd + 9) + ' C ' + pt(116, nd + 12.6) + ' ' + pt(124, nd + 12.6) + ' ' + pt(120 + cw * 0.7, nd + 9), null, p.d, 1, op(0.55)) +
      '</g>';
    o += P(top, null, p.l, 1.5);   // the bottom edge lies below the viewBox
    o += P(neckBand(cw, nd, 3.6), p.s, p.l, 1.3);
    return o;
  }

  function composePortrait(a, uid) {
    var c = makeCtx(a, uid);
    var hair = HAIR[a.hairStyle] || HAIR['wavy-bob'], hs = c.shape.hairSx;
    function R(x) { return '<g transform="rotate(2 120 166)">' + x + '</g>'; }
    var s = [];
    s.push(R(sx(hs, hair.back(c))));
    s.push(portraitBody(c));
    if (hair.tail) s.push(R(sx(hs, hair.tail(c))));
    s.push(R(headSkin(c) + faceFeatures(c) + sx(hs, hair.front(c)) + earrings(c) + glasses(c)));
    return { defs: c.defs.join(''), body: s.join('') };
  }

  function compose(a, o, view, uid) {
    if (view === 'portrait') return composePortrait(a, uid);
    var c = makeCtx(a, uid);
    var hair = HAIR[a.hairStyle] || HAIR['wavy-bob'];
    var full = view !== 'bust', back = view === 'back';
    var gd = o.dress ? GARMENTS[o.dress] : null, gt = GARMENTS[o.top];
    var dress = gd ? dressPiece(c, gd, back) : null;
    var bottom = !dress && full ? bottomPiece(c, GARMENTS[o.bottom], back) : null;
    var top = dress ? null : topPiece(c, gt, back);
    var under = top ? { pal: gPal(gt), long: top.long } : null;
    var layer = o.layer ? layerPiece(c, GARMENTS[o.layer], back, under) : null;
    var front = full && !back;
    function R(x) { return '<g transform="rotate(2 120 166)">' + x + '</g>'; }
    var s = [];
    if (full) s.push(ELL(120, 864, 98, 7.5, '#C48F7E', op(0.14)));
    if (!back) s.push(R(hair.back(c)));
    s.push(bodySkin(c, full));
    if (back) s.push(P('M 105 138 L 135 138 L 135 186 L 105 186 Z', c.skin.f, null));
    // Seen from behind, the forearms swing forward and the hands disappear behind the hips.
    if (full && back && !layer) s.push(forearmsBack(c));
    if (dress) s.push(dress.main);
    else if (bottom) s.push(bottom.main);
    if (full) s.push(shoesPiece(c, GARMENTS[o.shoes], back));
    if (top) {
      // tucked tops sit under the waistband and blouse softly over it; untucked tops cover it
      if (bottom && !top.tucked) s.push(bottom.band);
      s.push(top.body);
      if (bottom && top.tucked) s.push(bottom.band + top.blouse);
    }
    if (layer) s.push(layer.body);
    // Front, no layer: the hands go into the pockets of the bottom or dress, clipped to the
    // pocket line. Under a layer the sleeves run straight into the layer's own pockets.
    if (front && !layer) s.push(clipTo(c, HAND_CLIP, handsSkin(c)));
    s.push(layer ? layer.sleeves : (dress ? dress.sleeves : top.sleeves));
    if (front) s.push(layer ? layer.pocket : (dress ? dress.pocket : bottom.pocket));
    if (!back && hair.tail) s.push(R(hair.tail(c)));
    if (back) {
      s.push(PM(earD(c, EAR), c.skin.f, c.skin.l, 1.5));
      s.push(P(c.shape.face, c.skin.f, c.skin.l, 1.5));
      s.push(hair.rear(c));
      if (a.hairStyle === 'high-bun' || a.hairStyle === 'ponytail') s.push(earrings(c, true));
    } else {
      s.push(R(headSkin(c) + faceFeatures(c) + hair.front(c) + earrings(c) + glasses(c)));
    }
    return { defs: c.defs.join(''), body: s.join('') };
  }

  // A valid patch.preset is applied first; any explicit fields in the patch then win.
  // A patch that changes preset fields without naming a preset is matched to the closest one.
  function mergeAppearance(base, patch) {
    var out = normAppearance(base);
    if (patch && typeof patch === 'object') {
      var named = patch.preset != null && presetById(String(patch.preset)), touched = false;
      if (named) applyPreset(out, String(patch.preset));
      for (var k in KEYS) {
        if (patch[k] != null && findOpt(OPTIONS[k], String(patch[k]))) {
          if (k !== 'faceShape' && out[k] !== String(patch[k])) touched = true;
          out[k] = String(patch[k]);
        }
      }
      if (!named && touched) out.preset = inferPreset(out);
    }
    return out;
  }

  // svg(appearance, outfit, {view}): a partial appearance is laid over the saved one,
  // so a swatch preview such as svg({hairStyle:'curly'}) keeps the user's skin and colours,
  // and svg({preset:'p5'}, null, {view:'portrait'}) draws preset 5 with the saved face shape.
  // Views: 'portrait' (and its alias 'bust'), plus the unused 'full' and 'back'.
  function svg(appearance, outfit, opts) {
    var view = opts && opts.view;
    if (view === 'bust') view = 'portrait';
    if (view !== 'portrait' && view !== 'back') view = 'full';
    var a = mergeAppearance(get(), appearance), o = normOutfit(outfit);
    var uid = 'mpsav' + (++counter);
    var out;
    try { out = compose(a, o, view, uid); }
    catch (e) { out = compose(extend(DEFAULTS), extend(DEFAULT_OUTFIT), view, uid); }
    var vb = view === 'portrait' ? '0 0 240 260' : '0 0 240 880';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + vb + '" width="100%" height="100%" preserveAspectRatio="xMidYMax meet"' +
      ' role="img" aria-label="' + (view === 'portrait' ? 'Illustrated portrait' : 'Illustrated avatar') + '" data-view="' + view + '" focusable="false">' +
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
  // The in-memory value is the latest one this frame knows of (set here, or received over the
  // BroadcastChannel); storage is the fallback, and DEFAULTS when storage is empty or blocked.
  function get() { return normAppearance(mem || readStore() || DEFAULTS); }

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
    var next = mergeAppearance(get(), patch);
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

  // data-face-shape arrives as dataset.faceShape. data-preset is applied before the other overrides.
  var ATTR_APPEARANCE = { skin: 'skin', hairStyle: 'hairStyle', hairColor: 'hairColor', eyes: 'eyes', glasses: 'glasses', earrings: 'earrings', lips: 'lips', faceShape: 'faceShape' };
  function renderEl(el) {
    var ds = el.dataset || {};
    var app = get();
    if (ds.preset && presetById(ds.preset)) applyPreset(app, ds.preset);
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
    PRESETS: PRESETS,
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
