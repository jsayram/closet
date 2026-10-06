/* My Petite Style, room direction: js/avatar.js (attempt b, "charming").
 * The illustrated person the user sets up to look like herself. Implements the
 * js/avatar.js contract in STYLE.md. Plain script, no modules, no dependencies, no network.
 *
 * Drawing space: centre line x = 120, hair top y = 20, soles on y = 864.
 *   full / back  viewBox 0 0 240 880
 *   bust         viewBox 0 0 240 260 (same drawing, cropped)
 * Head (hair top to chin) is 20..172, about 1/5.5 of the figure. Shoulders y 208..226,
 * waist y 330, hips y 404, crotch y 470, knees y 648, ankles y 826.
 * Paths are written for the left half or the left limb; sym() closes a half into a whole
 * symmetric shape and pair() mirrors a limb across the centre line.
 * Layers back to front: back hair, skin (legs, torso, neck), tucked top, bottom or dress,
 * shoes, arms and hands, top, layer, head, face, front hair, glasses, earrings.
 */
(function (global) {
  'use strict';

  var STORAGE_KEY = 'mps.avatar.v1';
  var CHANNEL_NAME = 'mps.avatar';
  var CX = 120;

  /* ------------------------------------------------------------------ options */

  var OPTIONS = {
    skin: [
      { id: 's1', label: 'Porcelain', color: '#FBE4D4' },
      { id: 's2', label: 'Light', color: '#F6D2B8' },
      { id: 's3', label: 'Warm beige', color: '#F0C5A2' },
      { id: 's4', label: 'Tan', color: '#D9A178' },
      { id: 's5', label: 'Brown', color: '#A8714D' },
      { id: 's6', label: 'Deep', color: '#6F4630' }
    ],
    hairStyle: [
      { id: 'wavy-bob', label: 'Wavy bob' },
      { id: 'long-waves', label: 'Long waves' },
      { id: 'long-straight', label: 'Long straight' },
      { id: 'high-bun', label: 'High bun' },
      { id: 'curly', label: 'Curly' },
      { id: 'ponytail', label: 'Ponytail' }
    ],
    hairColor: [
      { id: 'black', label: 'Black', color: '#2E2629' },
      { id: 'dark-brown', label: 'Dark brown', color: '#4B3227' },
      { id: 'chestnut', label: 'Chestnut', color: '#6E4834' },
      { id: 'auburn', label: 'Auburn', color: '#9A4B2C' },
      { id: 'blonde', label: 'Blonde', color: '#E3BE7E' },
      { id: 'silver', label: 'Silver', color: '#CBCAD0' },
      { id: 'rose', label: 'Rose', color: '#E7A2B4' }
    ],
    eyes: [
      { id: 'brown', label: 'Brown', color: '#5A3726' },
      { id: 'hazel', label: 'Hazel', color: '#8A6634' },
      { id: 'green', label: 'Green', color: '#5B8A5E' },
      { id: 'blue', label: 'Blue', color: '#5784BC' }
    ],
    glasses: [
      { id: 'none', label: 'None' },
      { id: 'round', label: 'Round' },
      { id: 'cat-eye', label: 'Cat-eye' }
    ],
    earrings: [
      { id: 'none', label: 'None' },
      { id: 'hoops', label: 'Hoops' },
      { id: 'studs', label: 'Studs' }
    ],
    lips: [
      { id: 'rose', label: 'Rose', color: '#D9798A' },
      { id: 'berry', label: 'Berry', color: '#B04760' },
      { id: 'coral', label: 'Coral', color: '#E5866F' }
    ]
  };

  var DEFAULTS = {
    skin: 's3', hairStyle: 'wavy-bob', hairColor: 'chestnut', eyes: 'brown',
    glasses: 'none', earrings: 'hoops', lips: 'rose'
  };

  var DEFAULT_OUTFIT = { top: 'g-pink-blouse', bottom: 'g-navy-trousers', shoes: 'g-nude-flats', layer: null, dress: null };

  var KEYS = { skin: 'skin', hairStyle: 'hairStyle', hairColor: 'hairColor', eyes: 'eyes', glasses: 'glasses', earrings: 'earrings', lips: 'lips' };

  function clone(o) { var r = {}; for (var key in o) if (Object.prototype.hasOwnProperty.call(o, key)) r[key] = o[key]; return r; }
  function findOpt(group, id) {
    var list = OPTIONS[group] || [];
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }
  function sanitize(a) {
    var out = {};
    a = a && typeof a === 'object' ? a : {};
    for (var key in KEYS) out[key] = findOpt(key, a[key]) ? a[key] : DEFAULTS[key];
    return out;
  }
  function colorOf(group, id) { var o = findOpt(group, id) || findOpt(group, DEFAULTS[group]); return o.color; }

  /* ------------------------------------------------------------------ colour */

  function clamp(v, a, b) { return v < a ? a : (v > b ? b : v); }
  function hexToRgb(h) {
    h = String(h || '').replace('#', '');
    if (h.length === 3) h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2);
    var n = parseInt(h, 16);
    if (h.length !== 6 || isNaN(n)) return [200, 190, 190];
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function rgbToHex(r, g, b) {
    return '#' + [r, g, b].map(function (v) {
      v = Math.round(clamp(v, 0, 255));
      return (v < 16 ? '0' : '') + v.toString(16);
    }).join('').toUpperCase();
  }
  function rgbToHsl(r, g, b) {
    r /= 255; g /= 255; b /= 255;
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), h = 0, s = 0, l = (mx + mn) / 2;
    if (mx !== mn) {
      var d = mx - mn;
      s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
      if (mx === r) h = (g - b) / d + (g < b ? 6 : 0);
      else if (mx === g) h = (b - r) / d + 2;
      else h = (r - g) / d + 4;
      h /= 6;
    }
    return [h * 360, s, l];
  }
  function hslToHex(h, s, l) {
    h = (((h % 360) + 360) % 360) / 360;
    function f(p, q, t) {
      if (t < 0) t += 1; if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }
    var r, g, b;
    if (s === 0) { r = g = b = l; } else {
      var q = l < 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q;
      r = f(p, q, h + 1 / 3); g = f(p, q, h); b = f(p, q, h - 1 / 3);
    }
    return rgbToHex(r * 255, g * 255, b * 255);
  }
  /* darken: lower lightness by t (0..1), nudge saturation up, optionally drift the hue. */
  function darken(hex, t, hue) {
    var c = hexToRgb(hex), x = rgbToHsl(c[0], c[1], c[2]);
    return hslToHex(x[0] + (hue || 0) * t, clamp(x[1] * (1 + 0.2 * t), 0, 1), x[2] * (1 - t));
  }
  function lighten(hex, t) {
    var c = hexToRgb(hex), x = rgbToHsl(c[0], c[1], c[2]);
    return hslToHex(x[0], x[1], x[2] + (1 - x[2]) * t);
  }
  function mix(a, b, t) {
    var A = hexToRgb(a), B = hexToRgb(b);
    return rgbToHex(A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t, A[2] + (B[2] - A[2]) * t);
  }
  function lum(hex) { var c = hexToRgb(hex); return rgbToHsl(c[0], c[1], c[2])[2]; }

  /* Garment tones, shared with js/garments.js so the worn pieces match the closet drawings.
     f fill, s shade, h highlight, o outline, d detail lines. */
  var GT = {
    'g-pink-blouse':    { f: '#F4B4C2', s: '#EC9DB0', h: '#FBD0D9', o: '#D97F97', d: '#D97F97' },
    'g-cream-sweater':  { f: '#FFF3E0', s: '#F1DEBF', h: '#FFFCF6', o: '#C9A676', d: '#DDBE92' },
    'g-lace-top':       { f: '#FFFDF8', s: '#F0E7D6', h: '#FFFFFF', o: '#C6AA80', d: '#D6C09C' },
    'g-brick-top':      { f: '#B5533C', s: '#9E4531', h: '#CC6E56', o: '#772E1F', d: '#8E3C2A' },
    'g-black-tee':      { f: '#2E2A30', s: '#221F24', h: '#4E4853', o: '#131115', d: '#5A535F' },
    'g-cream-crop':     { f: '#F8ECD8', s: '#EAD9BC', h: '#FFF8EC', o: '#BDA070', d: '#CDB38B' },
    'g-navy-cardigan':  { f: '#27335F', s: '#1D2749', h: '#374780', o: '#121A33', d: '#5B6CA3' },
    'g-gray-blazer':    { f: '#A9ABB3', s: '#93959F', h: '#C4C6CD', o: '#6A6C78', d: '#7C7E8A' },
    'g-brown-jacket':   { f: '#7A4B2E', s: '#633A21', h: '#9C6A44', o: '#3F2210', d: '#4F2D18' },
    'g-camel-trench':   { f: '#C9A06A', s: '#B88C54', h: '#DEBC8C', o: '#906C3B', d: '#A07A45', b: '#6B4728' },
    'g-navy-trousers':  { f: '#27335F', s: '#1D2749', h: '#334277', o: '#121A33', d: '#4A5A96' },
    'g-olive-trousers': { f: '#7C8450', s: '#69713F', h: '#959D68', o: '#4B522B', d: '#5C6436' },
    'g-wide-jeans':     { f: '#6F93C4', s: '#5B80B3', h: '#8BACD8', o: '#3D6097', d: '#4C6FA8', t: '#F0D28E' },
    'g-black-skirt':    { f: '#2E2A30', s: '#221F24', h: '#443E49', o: '#131115', d: '#5A535F' },
    'g-gray-leggings':  { f: '#8E9098', s: '#7B7D86', h: '#A4A6AE', o: '#565862', d: '#6C6E78' },
    'g-blue-dress':     { f: '#8FB3E3', s: '#789FD5', h: '#AAC8EF', o: '#4E77B2', d: '#5F87C0', fl: '#FFF7EA', fc: '#F3D97C', fp: '#F4B4C2', lf: '#5C9670' },
    'g-nude-flats':     { f: '#F1DCC6', s: '#E2C8AC', h: '#F9ECDD', o: '#B48F68', d: '#C4A07A', sole: '#C8A27C', in: '#E8D0B4' },
    'g-black-heels':    { f: '#2E2A30', s: '#1F1C21', h: '#4E4853', o: '#111013', d: '#5A535F', sole: '#B8926C', in: '#5A535F' },
    'g-white-sneakers': { f: '#FAFAFA', s: '#E9E4DE', h: '#FFFFFF', o: '#B3A79B', d: '#C7BCB1', sole: '#EFE6DA', tab: '#F4B4C2' },
    'g-tan-loafers':    { f: '#B98552', s: '#A2713F', h: '#CB9B6B', o: '#7A532A', d: '#8E6234', sole: '#5E3E22', in: '#D8B68C' }
  };

  /* ------------------------------------------------------------------ path helpers */

  function r1(v) { return Math.round(v * 10) / 10; }
  function parseD(d) {
    var re = /([MLCQZ])([^MLCQZ]*)/gi, m, out = [];
    while ((m = re.exec(d))) {
      var nums = (m[2].match(/-?\d*\.?\d+/g) || []).map(Number), pts = [];
      for (var i = 0; i + 1 < nums.length; i += 2) pts.push([nums[i], nums[i + 1]]);
      out.push({ c: m[1].toUpperCase(), p: pts });
    }
    return out;
  }
  function mx(p) { return r1(2 * CX - p[0]) + ',' + r1(p[1]); }
  /* Close a left-half outline (starting and ending on the centre line) into a symmetric shape. */
  function sym(d) {
    var s = parseD(d), out = d.trim(), i, cur, prev;
    for (i = s.length - 1; i >= 1; i--) {
      cur = s[i]; prev = s[i - 1].p[s[i - 1].p.length - 1];
      if (cur.c === 'L') out += ' L' + mx(prev);
      else if (cur.c === 'C') out += ' C' + mx(cur.p[1]) + ' ' + mx(cur.p[0]) + ' ' + mx(prev);
      else if (cur.c === 'Q') out += ' Q' + mx(cur.p[0]) + ' ' + mx(prev);
    }
    return out + ' Z';
  }
  /* Mirror every point of a path across the centre line. */
  function mirD(d) {
    return parseD(d).map(function (seg) {
      return seg.c + seg.p.map(mx).join(' ');
    }).join(' ');
  }

  function P(d, fill, stroke, sw, extra) {
    return '<path d="' + d + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 1.5) + '" stroke-linecap="round" stroke-linejoin="round"' : '') +
      (extra || '') + '/>';
  }
  function Ln(d, c, sw, op) { return P(d, null, c, sw || 1, op != null && op < 1 ? ' opacity="' + op + '"' : ''); }
  function Fo(d, c, op) { return P(d, c, null, null, op != null && op < 1 ? ' opacity="' + op + '"' : ''); }
  function Ci(x, y, r, fill, stroke, sw, extra) {
    return '<circle cx="' + r1(x) + '" cy="' + r1(y) + '" r="' + r + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 1.2) + '"' : '') + (extra || '') + '/>';
  }
  function El(x, y, rx, ry, fill, extra) {
    return '<ellipse cx="' + r1(x) + '" cy="' + r1(y) + '" rx="' + rx + '" ry="' + ry + '" fill="' + fill + '"' + (extra || '') + '/>';
  }
  var MIRROR = ' transform="matrix(-1 0 0 1 240 0)"';
  function pair(s) { return s + '<g' + MIRROR + '>' + s + '</g>'; }
  function flip(s) { return '<g' + MIRROR + '>' + s + '</g>'; }

  function clipUrl(k, d) {
    var id = k.U + '-c' + (++k.n);
    k.defs.push('<clipPath id="' + id + '"><path d="' + d + '"/></clipPath>');
    return 'url(#' + id + ')';
  }
  /* Filled shape, inner shading clipped to it, outline on top. */
  function shape(k, d, t, inner, sw) {
    var s = P(d, t.f);
    if (inner) s += '<g clip-path="' + clipUrl(k, d) + '">' + inner + '</g>';
    return s + P(d, null, t.o, sw || k.sw);
  }
  function vlines(x0, x1, step, y0, y1) {
    var s = '';
    for (var x = x0; x <= x1 + 0.01; x += step) s += 'M' + r1(x) + ',' + y0 + ' L' + r1(x) + ',' + y1 + ' ';
    return s;
  }

  /* ------------------------------------------------------------------ body */

  var TORSO = sym('M120,156 L106,156 L106,186 C106,195 98,199 86,202 C70,205 54,209 48,220 C44,228 46,240 56,250 L64,262 C66,290 72,314 74,330 C72,358 62,382 58,404 C70,440 92,462 120,470');
  var LEG = 'M58,400 C55,450 58,520 64,580 C68,612 72,632 73,648 C70,676 71,712 76,752 C79,784 81,806 81,830 L97,830 C98,806 101,782 105,752 C109,722 111,694 108,666 C107,650 108,632 111,604 C115,560 119,516 120,470 L120,420 Z';
  var ARM = 'M47,236 C45,262 41,300 38,336 C37,368 39,398 42,424 L58,424 C58,400 60,370 61,340 C62,310 64,284 64,262 C62,248 56,238 47,236 Z';
  var HAND = 'M42,416 C39,428 37,444 38,456 C39,469 44,477 51,477 C57,477 61,470 61.5,461 C62,455 64.5,451 64.5,445 C64.5,437 61.5,432 58.5,429 L58.5,416 Z';
  var FOOT = 'M81,818 L97,818 C97,828 99,834 101,840 L92,851 L70,846 C70,842 74,840 77,836 C80,831 81,826 81,818 Z';

  function drawLegs(k) {
    var t = k.skin;
    var inner = Fo('M108,666 C111,694 109,722 105,752 C101,782 98,806 97,830 L93,830 C94,804 97,776 100,748 C103,720 104,694 102,670 Z', t.s) +
      Fo('M111,604 C115,560 119,516 120,470 L113,470 C112,520 109,560 106,600 Z', t.s);
    var knee = Ln('M80,640 C84,644 90,645 96,643', t.o, 1, 0.45);
    return pair(shape(k, LEG, t, inner) + knee);
  }
  function drawTorso(k) {
    var t = k.skin;
    var inner = Fo('M106,150 C112,170 128,170 134,150 L134,184 C126,192 114,192 106,184 Z', t.s) +
      (k.back ? '' : Ln('M98,214 C104,218 110,219 114,218 M142,214 C136,218 130,219 126,218', t.o, 1, 0.4));
    return shape(k, TORSO, t, inner);
  }
  function drawArms(k) {
    var t = k.skin;
    var inner = Fo('M61,340 C62,310 65,282 66,258 L60,258 C58,290 56,316 55,340 C54,370 54,400 54,424 L58,424 C58,400 60,370 61,340 Z', t.s);
    var hand = shape(k, HAND, t, Fo('M64.5,445 C64.5,437 61.5,432 58.5,429 L58.5,416 L54,416 L54,440 C56,446 60,452 61.5,461 Z', t.s, 0.6)) +
      (k.back ? Ln('M44,462 C47,467 52,469 56,467', t.o, 1, 0.45) : Ln('M61.4,460 C59.2,455 58.4,450 59.2,444.5', t.o, 1.1, 0.75));
    return pair(shape(k, ARM, t, inner) + hand);
  }

  /* ------------------------------------------------------------------ head and face */

  var FACE = sym('M120,42 C95,42 73,58 72,95 C71,125 78,147 96,161 C105,168 112,171 120,171');
  var EAR = 'M75,107 C67,102 61,109 62,120 C63,130 69,137 76,134 Z';

  function drawHead(k, earsVisible) {
    var t = k.skin, s = '';
    s += pair(P(EAR, t.f, t.o, k.sw) + (earsVisible ? Ln('M71.5,112 C66.5,113 65.5,120 68.5,126.5', t.o, 1.1, 0.7) : ''));
    if (k.back) return s;
    s += shape(k, FACE, t, '');
    return s;
  }

  function drawEye(k, ex, ey, dir, irisC) {
    var t = k.skin, U = k.U + '-eye' + (dir < 0 ? 'l' : 'r');
    var al = 'M-11,2 C-9.6,-9.4 8,-11.4 11.8,-1 C9.6,8.6 -6,9.8 -11,2 Z';
    k.defs.push('<clipPath id="' + U + '"><path d="' + al + '"/></clipPath>');
    var g = '';
    g += P(al, '#FFFDFB');
    g += '<g clip-path="url(#' + U + ')">' +
      El(0.6, 0.6, 7.9, 9.4, irisC) +
      Fo('M-10,-10 L10,-10 L10,-2.4 C5,-5.6 -5,-5.6 -10,-2.4 Z', darken(irisC, 0.38)) +
      El(0.6, 1, 4, 4.8, darken(irisC, 0.66)) +
      Fo('M-6,6.8 C-2,10 4,10 7.8,6.4 L7.8,11 L-6,11 Z', lighten(irisC, 0.2), 0.7) +
      '</g>';
    g += Ln('M-6.2,10 C-1.8,11.6 4.4,11.2 8.6,8.4', t.o, 1, 0.45);
    g += P('M-11.8,2.6 C-10,-10 7.6,-12.8 12.6,-1.6 C13.6,-2.2 14.8,-3.8 15.8,-6 C15,-3 14,-0.8 12.4,0.4 C8.4,-9.6 -8.4,-8.6 -11.8,2.6 Z', k.lash, k.lash, 1.1);
    var S = 1.18;
    var s = '<g transform="translate(' + ex + ',' + ey + ') scale(' + (dir * S) + ',' + S + ')">' + g + '</g>';
    s += Ci(ex + 4, ey - 3.2, 3, '#FFFFFF') + Ci(ex - 3, ey + 4.4, 1.35, '#FFFFFF', null, null, ' opacity="0.9"');
    return s;
  }
  function drawBrow(k, ex, ey, dir) {
    var d = 'M-10.6,-18.6 C-5,-25 4.6,-26.4 12,-21.6 C12.6,-21.2 12.4,-20.4 11.6,-20.6 C4.6,-23.2 -3.4,-22.4 -8.8,-17.6 C-9.8,-16.8 -11.2,-17.6 -10.6,-18.6 Z';
    return '<g transform="translate(' + ex + ',' + ey + ') scale(' + dir + ',1)">' + P(d, k.brow, k.brow, 0.8) + '</g>';
  }
  function drawFace(k) {
    var t = k.skin, s = '';
    var eyeC = colorOf('eyes', k.app.eyes), lipC = colorOf('lips', k.app.lips);
    s += El(85, 141, 10, 5.6, k.blush, ' opacity="0.45"') + El(155, 141, 10, 5.6, k.blush, ' opacity="0.45"');
    s += drawBrow(k, 98, 116, -1) + drawBrow(k, 142, 116, 1);
    s += drawEye(k, 98, 119, -1, eyeC) + drawEye(k, 142, 119, 1, eyeC);
    s += Ln('M121.2,132 C119.2,136 119.6,139 122.6,139.4', t.o, 1.5, 0.6);
    s += P('M113.2,152.6 C116.6,158 123.4,158 126.8,152.6 C123.4,154.8 116.6,154.8 113.2,152.6 Z', lipC);
    s += Ln('M111.6,151.2 C115.8,155.6 124.2,155.6 128.4,151.2', darken(lipC, 0.22), 1.7);
    return s;
  }

  /* ------------------------------------------------------------------ hair */

  function hairShape(k, d, inner) {
    var t = k.hair;
    return shape(k, d, { f: t.f, o: t.o }, inner);
  }
  function strands(k, d, op) { return Ln(d, k.hair.d, 1.2, op == null ? 0.9 : op); }
  function shine(k, d) { return Fo(d, k.hair.h, 0.75); }

  var HAIR = {};

  /* Wavy bob, side part, ends flick at the jaw. Matches the reference. */
  HAIR['wavy-bob'] = {
    ears: false,
    back: function (k) {
      return P(sym('M120,20 C84,20 56,36 47,70 C40,96 44,122 40,146 C36,168 38,186 48,196 C56,204 68,204 76,198 C86,206 100,206 108,200 L120,200'), k.hair.s, k.hair.o, k.sw);
    },
    front: function (k) {
      var L = 'M112,22 C82,21 56,36 49,68 C45,92 50,114 45,136 C40,158 35,176 45,190 C51,198 62,200 68,193 C71,189 71,183 68,179 C75,172 78,162 77,150 C76,138 73,128 73,116 C74,98 80,80 92,70 C100,63 108,59 114,58 Q110,40 112,22 Z';
      var R = 'M112,22 C150,18 186,34 193,70 C198,96 192,118 196,140 C200,160 206,178 196,191 C190,199 178,200 172,193 C169,189 169,183 172,179 C165,171 162,161 163,149 C164,135 167,126 167,116 C165,100 158,82 144,72 C132,64 122,60 114,58 Q110,40 112,22 Z';
      var s = '';
      s += hairShape(k, L, shine(k, 'M100,32 C84,36 70,46 62,60 C60,65 64,67 67,63 C75,51 87,43 102,38 C106,37 104,31 100,32 Z'));
      s += strands(k, 'M108,36 C88,44 70,62 62,92 M55,106 C51,128 51,150 47,172 M68,104 C66,124 68,148 62,178');
      s += Ln('M50,190 C54,184 61,184 64,189', k.hair.d, 1.2, 0.9);
      s += hairShape(k, R, shine(k, 'M124,31 C148,29 170,40 180,58 C182,63 178,65 175,61 C166,49 148,41 126,37 C121,36 120,32 124,31 Z'));
      s += strands(k, 'M116,33 C146,35 172,53 182,86 M186,106 C190,128 186,150 192,172 M126,45 C150,57 166,78 172,104 M176,124 C176,146 178,164 182,180');
      s += Ln('M190,190 C186,184 179,184 176,189', k.hair.d, 1.2, 0.9);
      return s;
    },
    rear: function (k) {
      var d = sym('M120,19 C84,19 55,35 47,70 C42,96 46,118 42,142 C38,164 36,184 46,196 C54,204 66,204 74,198 C82,206 96,208 104,200 C110,206 116,206 120,204');
      return hairShape(k, d, shine(k, 'M92,30 C108,24 132,24 148,30 C152,32 150,36 146,35 C130,30 110,30 94,35 C90,36 88,32 92,30 Z')) +
        strands(k, 'M120,40 C100,60 86,100 84,150 M118,42 C110,72 104,122 104,186 M122,42 C130,72 136,122 136,186 M120,40 C140,60 154,100 156,150 M70,80 C60,110 60,150 56,182 M170,80 C180,110 180,150 184,182');
    }
  };

  /* Long waves past the shoulders. */
  HAIR['long-waves'] = {
    ears: false,
    back: function (k) {
      return P(sym('M120,22 C86,22 58,38 48,70 C40,98 44,130 40,170 C36,210 44,250 40,290 C38,314 48,332 62,334 C76,336 88,328 96,320 L120,318'), k.hair.s, k.hair.o, k.sw);
    },
    front: function (k) {
      var L = 'M112,22 C82,21 56,36 49,68 C45,94 50,118 46,142 C42,168 50,194 46,220 C42,246 50,272 46,298 C44,318 54,334 66,332 C74,330 76,322 72,316 C78,302 80,282 76,262 C72,240 80,218 78,196 C76,176 75,156 76,140 C76,130 73,124 73,116 C74,98 80,80 92,70 C100,63 108,59 114,58 Q110,40 112,22 Z';
      var R = 'M112,22 C150,18 186,34 193,70 C198,98 192,122 196,148 C200,174 192,200 196,226 C200,252 192,278 196,302 C198,320 188,334 176,332 C168,330 166,322 170,316 C164,302 162,282 166,262 C170,240 162,218 164,196 C166,176 165,156 164,140 C164,128 167,124 167,116 C165,100 158,82 144,72 C132,64 122,60 114,58 Q110,40 112,22 Z';
      var s = '';
      s += hairShape(k, L, shine(k, 'M100,32 C84,36 70,46 62,60 C60,65 64,67 67,63 C75,51 87,43 102,38 C106,37 104,31 100,32 Z'));
      s += strands(k, 'M104,35 C82,42 64,60 58,88 M56,104 C52,130 58,156 54,184 C50,210 58,236 54,262 C52,282 56,300 54,318 M66,150 C70,176 64,204 68,232 C70,256 62,284 64,310');
      s += hairShape(k, R, shine(k, 'M124,31 C148,29 170,40 180,58 C182,63 178,65 175,61 C166,49 148,41 126,37 C121,36 120,32 124,31 Z'));
      s += strands(k, 'M121,33 C150,33 176,53 184,86 M184,104 C188,130 182,156 186,184 C190,210 182,236 186,262 C188,282 184,300 186,318 M174,150 C170,176 176,204 172,232 C170,256 178,284 176,310 M140,52 C158,64 170,84 174,108');
      return s;
    },
    rear: function (k) {
      var d = sym('M120,20 C86,20 56,36 48,70 C42,98 46,130 42,170 C38,210 46,250 42,290 C40,314 50,334 66,336 C80,338 92,330 100,322 C108,330 114,332 120,330');
      return hairShape(k, d, shine(k, 'M92,30 C108,24 132,24 148,30 C152,32 150,36 146,35 C130,30 110,30 94,35 C90,36 88,32 92,30 Z')) +
        strands(k, 'M120,40 C100,70 84,120 88,180 C92,230 80,280 84,320 M118,42 C110,90 108,160 112,230 C114,270 108,300 110,326 M122,42 C130,90 132,160 128,230 C126,270 132,300 130,326 M120,40 C140,70 156,120 152,180 C148,230 160,280 156,320 M66,90 C58,130 64,170 58,210 C54,250 62,280 58,316 M174,90 C182,130 176,170 182,210 C186,250 178,280 182,316');
    }
  };

  /* Long and straight with a centre part and blunt ends. */
  HAIR['long-straight'] = {
    ears: false,
    back: function (k) {
      return P(sym('M120,22 C88,22 60,38 52,70 C47,96 48,140 47,200 L45,332 L120,332'), k.hair.s, k.hair.o, k.sw);
    },
    front: function (k) {
      var L = 'M120,26 C92,26 64,40 56,70 C51,96 52,140 51,200 L49,330 C58,332 68,332 78,330 C77,280 77,230 78,190 C78,160 75,130 74,108 C74,88 90,62 120,56 Z';
      var s = '';
      var band = shine(k, 'M66,62 C80,44 100,38 118,37 L118,43 C100,44 84,52 72,68 C70,70 64,66 66,62 Z');
      s += hairShape(k, L, band) + hairShape(k, mirD(L), flip(band));
      var st = 'M108,40 C88,50 72,72 66,100 L63,326 M72,140 L71,326 M58,120 L56,326';
      s += strands(k, st) + flip(strands(k, st));
      return s;
    },
    rear: function (k) {
      var d = sym('M120,20 C88,20 58,36 52,70 C47,96 48,140 47,200 L45,334 L120,334');
      return hairShape(k, d, shine(k, 'M68,58 C84,36 156,36 172,58 C173,62 169,64 166,61 C150,44 90,44 74,61 C71,64 67,62 68,58 Z')) +
        strands(k, 'M120,30 L120,332 M100,34 C82,48 74,80 72,120 L70,332 M140,34 C158,48 166,80 168,120 L170,332 M60,120 L58,332 M180,120 L182,332 M96,90 L94,332 M144,90 L146,332');
    }
  };

  /* High bun, hair pulled up off the face, ears showing. */
  var CAP = 'M120,26 C92,26 72,40 68,72 C66,90 67,102 72,111 C73,92 80,72 96,58 C106,50 113,47 120,47 C127,47 134,50 144,58 C160,72 167,92 168,111 C173,102 174,90 172,72 C168,40 148,26 120,26 Z';
  HAIR['high-bun'] = {
    ears: true,
    back: function (k) {
      var bun = 'M120,3 C137,3 147,13 147,26 C147,38 136,45 120,45 C104,45 93,38 93,26 C93,13 103,3 120,3 Z';
      return hairShape(k, bun, shine(k, 'M104,12 C110,7 122,6 130,9 C132,10 131,13 128,12 C121,10 111,11 106,15 C104,17 102,14 104,12 Z')) +
        strands(k, 'M104,22 C108,12 124,8 134,14 M106,32 C114,38 130,38 138,28 M112,20 C116,16 124,16 128,20');
    },
    front: function (k) {
      var s = hairShape(k, CAP, shine(k, 'M92,36 C104,30 118,29 128,30 C131,31 130,34 127,34 C116,34 104,36 95,40 C91,42 89,38 92,36 Z'));
      s += strands(k, 'M80,86 C84,64 98,46 114,36 M96,60 C104,48 112,40 118,34 M160,86 C156,64 142,46 126,36 M144,60 C136,48 128,40 122,34');
      s += P('M104,34 C112,38 128,38 136,34 C136,30 104,30 104,34 Z', k.hair.d, k.hair.o, 1);
      s += Ln('M72,108 C69,120 71,132 75,141 M168,108 C171,120 169,132 165,141', k.hair.f, 1.6) + Ln('M72,108 C69,120 71,132 75,141 M168,108 C171,120 169,132 165,141', k.hair.o, 0.6, 0.6);
      return s;
    },
    rear: function (k) {
      var d = sym('M120,24 C90,24 70,40 66,70 C63,96 66,124 74,140 C84,150 100,154 120,154');
      var bun = 'M120,3 C137,3 147,13 147,26 C147,38 136,45 120,45 C104,45 93,38 93,26 C93,13 103,3 120,3 Z';
      return hairShape(k, d, shine(k, 'M84,52 C96,40 144,40 156,52 C158,55 154,57 151,55 C140,46 100,46 89,55 C86,57 82,55 84,52 Z')) +
        strands(k, 'M84,130 C88,90 100,60 114,40 M100,146 C104,100 110,70 118,42 M156,130 C152,90 140,60 126,40 M140,146 C136,100 130,70 122,42') +
        hairShape(k, bun, shine(k, 'M104,12 C110,7 122,6 130,9 C132,10 131,13 128,12 C121,10 111,11 106,15 C104,17 102,14 104,12 Z')) +
        strands(k, 'M104,22 C108,12 124,8 134,14 M106,32 C114,38 130,38 138,28') +
        P('M104,42 C112,46 128,46 136,42 C136,38 104,38 104,42 Z', k.hair.d, k.hair.o, 1);
    }
  };

  /* Curly, full and round. */
  var CURLY_OUT = 'M120,14 C104,10 88,14 78,22 C64,18 48,28 46,44 C34,50 30,66 36,80 C26,92 28,110 36,120 C28,134 30,152 40,160 C34,174 38,192 52,198';
  HAIR.curly = {
    ears: false,
    back: function (k) {
      return P(sym(CURLY_OUT + ' C58,210 74,212 84,204 C94,212 108,210 114,202 L120,202'), k.hair.s, k.hair.o, k.sw);
    },
    front: function (k) {
      var d = sym(CURLY_OUT + ' C60,206 72,206 76,198 C80,190 77,182 74,176 C80,170 80,160 76,152 C80,144 78,134 74,128 C78,120 76,110 73,104 C78,96 79,86 77,80 C85,78 91,72 91,63 C97,68 105,66 109,59 C113,63 118,63 120,61');
      var curls = 'M54,56 C58,50 66,52 65,58 M44,90 C48,84 56,86 55,92 M42,132 C46,126 54,128 53,134 M48,172 C52,166 60,168 59,174 M66,34 C70,28 78,30 77,36 M88,24 C92,18 100,20 99,26 M60,110 C64,104 72,106 71,112 M58,150 C62,144 70,146 69,152 M84,46 C88,40 96,42 95,48 M106,36 C110,30 118,32 117,38';
      return hairShape(k, d, shine(k, 'M78,30 C90,22 104,20 114,21 C117,22 116,25 113,25 C103,25 92,28 82,34 C78,36 75,32 78,30 Z') + flip(shine(k, 'M78,30 C90,22 104,20 114,21 C117,22 116,25 113,25 C103,25 92,28 82,34 C78,36 75,32 78,30 Z'))) +
        strands(k, curls) + flip(strands(k, curls));
    },
    rear: function (k) {
      var d = sym(CURLY_OUT + ' C58,210 74,212 84,204 C94,212 108,210 114,202 L120,204');
      var curls = 'M54,56 C58,50 66,52 65,58 M44,90 C48,84 56,86 55,92 M42,132 C46,126 54,128 53,134 M48,172 C52,166 60,168 59,174 M66,34 C70,28 78,30 77,36 M88,24 C92,18 100,20 99,26 M60,110 C64,104 72,106 71,112 M58,150 C62,144 70,146 69,152 M84,46 C88,40 96,42 95,48 M106,36 C110,30 118,32 117,38 M80,80 C84,74 92,76 91,82 M100,110 C104,104 112,106 111,112 M80,140 C84,134 92,136 91,142 M104,170 C108,164 116,166 115,172 M82,190 C86,184 94,186 93,192 M106,60 C110,54 118,56 117,62';
      return hairShape(k, d, shine(k, 'M78,30 C90,22 104,20 114,21 C117,22 116,25 113,25 C103,25 92,28 82,34 C78,36 75,32 78,30 Z')) + strands(k, curls) + flip(strands(k, curls));
    }
  };

  /* High ponytail with a soft side-swept fringe. */
  HAIR.ponytail = {
    ears: true,
    back: function (k) {
      var tail = 'M146,40 C176,44 194,72 192,108 C190,140 196,172 190,202 C186,224 174,242 160,250 C166,230 168,208 164,186 C160,162 164,132 160,108 C158,86 152,66 138,54 Z';
      return hairShape(k, tail, '') + strands(k, 'M160,62 C176,80 180,104 178,130 C176,160 182,186 176,214 M150,70 C164,92 168,118 168,146 C168,176 172,200 168,228');
    },
    front: function (k) {
      var s = hairShape(k, CAP, shine(k, 'M126,30 C138,30 150,34 158,42 C160,45 157,47 154,45 C146,38 136,35 126,35 C122,34 122,30 126,30 Z'));
      s += strands(k, 'M160,86 C156,64 142,46 126,36 M144,60 C136,48 128,40 122,34');
      var fringe = 'M146,36 C120,36 96,48 84,68 C78,80 74,94 72,108 C80,96 90,84 102,76 C116,68 134,64 158,68 C156,52 152,42 146,36 Z';
      s += hairShape(k, fringe, shine(k, 'M134,40 C118,42 104,48 94,58 C92,61 95,63 98,61 C108,53 120,47 134,45 C138,44 138,40 134,40 Z'));
      s += strands(k, 'M140,44 C116,46 98,58 86,78 M150,56 C128,56 108,64 92,80');
      s += Ln('M168,108 C171,120 169,132 165,141', k.hair.f, 1.6) + Ln('M168,108 C171,120 169,132 165,141', k.hair.o, 0.6, 0.6);
      return s;
    },
    rear: function (k) {
      var d = sym('M120,24 C90,24 70,40 66,70 C63,96 66,124 74,140 C84,150 100,154 120,154');
      var tail = 'M113,66 C104,96 98,140 102,184 C106,224 112,254 120,282 C128,254 136,222 138,184 C140,140 136,98 127,66 Z';
      return hairShape(k, d, shine(k, 'M84,52 C96,40 144,40 156,52 C158,55 154,57 151,55 C140,46 100,46 89,55 C86,57 82,55 84,52 Z')) +
        strands(k, 'M84,130 C90,100 102,80 114,68 M100,146 C104,110 110,86 116,70 M156,130 C150,100 138,80 126,68 M140,146 C136,110 130,86 124,70') +
        hairShape(k, tail, shine(k, 'M114,80 C108,110 106,140 108,170 C108,174 112,174 112,170 C112,140 114,110 118,82 C119,78 115,76 114,80 Z')) +
        strands(k, 'M120,74 C114,110 112,150 116,196 C118,226 120,250 120,270 M126,80 C130,120 130,160 126,210') +
        P('M110,60 C116,56 124,56 130,60 L131,72 C124,76 116,76 109,72 Z', k.hair.d, k.hair.o, 1);
    }
  };

  /* ------------------------------------------------------------------ glasses and earrings */

  function drawGlasses(k) {
    var g = k.app.glasses, c = '#5E3B4E', s = '';
    if (g === 'round') {
      s += Ci(99, 116, 13.5, '#FFFFFF', c, 1.9, ' fill-opacity="0.18"') + Ci(141, 116, 13.5, '#FFFFFF', c, 1.9, ' fill-opacity="0.18"');
      s += Ln('M112.4,113.4 C116,109.8 124,109.8 127.6,113.4', c, 1.9);
      s += Ln('M85.6,113 L74,109.6 M154.4,113 L166,109.6', c, 1.7);
      s += Ln('M91,108 C93,105.6 96,104.6 99,104.6 M133,108 C135,105.6 138,104.6 141,104.6', '#FFFFFF', 1.3, 0.8);
    } else if (g === 'cat-eye') {
      var lens = 'M-14.6,-6.4 C-6,-8.8 6,-8.4 13,-4.6 C16.4,-7.4 19,-10 21,-12.6 C20.6,-7 18.6,-1.6 15.2,2.4 C13,10 6,13 -2,12.6 C-10,12.2 -15,6 -14.6,-6.4 Z';
      var one = P(lens, '#FFFFFF', c, 1.9, ' fill-opacity="0.18"');
      s += '<g transform="translate(141,117)">' + one + '</g><g transform="translate(99,117) scale(-1,1)">' + one + '</g>';
      s += Ln('M113,112.4 C116,109.6 124,109.6 127,112.4', c, 1.9);
      s += Ln('M80.6,108 L74,107 M159.4,108 L166,107', c, 1.7);
    }
    return s;
  }
  function drawEarrings(k, earsVisible) {
    var e = k.app.earrings, gold = '#D9A940', lt = '#F6DC8E', dk = '#A9781E', s = '';
    if (e === 'hoops') {
      var hx = earsVisible ? 68.5 : 74, hy = earsVisible ? 142 : 145;
      var one = Ci(hx, hy, 7, 'none', dk, 3.2) + Ci(hx, hy, 7, 'none', gold, 2.2) + P('M' + (hx - 6) + ',' + (hy - 3) + ' C' + (hx - 5) + ',' + (hy - 6) + ' ' + (hx - 2) + ',' + (hy - 7.4) + ' ' + (hx + 1) + ',' + (hy - 7), null, lt, 0.9);
      s += one + flip(one);
    } else if (e === 'studs') {
      var sx = earsVisible ? 68.6 : 75.4, sy = earsVisible ? 134 : 136;
      var st = Ci(sx, sy, 2.8, gold, dk, 0.8) + Ci(sx - 0.8, sy - 0.9, 0.9, lt);
      s += st + flip(st);
    }
    return s;
  }

  /* ------------------------------------------------------------------ tops */

  var NECK = {
    crew: 'M120,206 C111,206 106,200 104,192 C92,197 70,202 57,208',
    scoop: 'M120,214 C108,214 100,206 98,194 C88,198 70,202 57,208',
    boat: 'M120,199 C106,199 94,197 86,195 C78,198 66,203 57,208',
    back: 'M120,193 C112,193 107,191 105,188 C93,195 70,202 57,208'
  };
  var SIDE = { fit: ' C48,213 44,222 46,234 C50,246 58,254 63,262 C65,290 69,314 71,332', loose: ' C46,213 42,222 44,234 C48,246 56,254 61,262 C60,284 63,308 69,331' };
  var HEM = {
    tucked: ' L72,346 L120,346',
    hip: ' C68,350 62,372 60,392 C80,397 100,399 120,399',
    hipLoose: ' C64,350 58,372 57,392 C78,398 100,400 120,400',
    crop: ' L71,330 C88,332 104,333 120,333'
  };
  var SLEEVE = {
    long: 'M58,207 C47,210 40,219 38,234 C35,262 32,298 33,334 C34,364 36,388 39,405 L62,405 C63,388 64,366 64,342 C65,312 67,284 66,258 C66,240 64,222 58,207 Z',
    loose: 'M58,206 C46,209 40,218 38,232 C34,262 31,300 31,340 C31,366 33,386 35,400 L64,400 C65,386 67,364 67,340 C68,310 68,282 67,258 C67,240 64,222 58,206 Z',
    short: 'M58,207 C48,210 42,218 40,232 C38,250 37,268 36,286 C46,290 58,290 66,286 C66,276 66,268 66,258 C66,240 64,222 58,207 Z'
  };

  var TOPS = {
    'g-pink-blouse':   { neck: 'crew', fit: 'loose', hem: 'tucked', sleeve: 'long', cuff: 'gather' },
    'g-cream-sweater': { neck: 'crew', fit: 'loose', hem: 'hipLoose', sleeve: 'loose', cuff: 'rib', knit: 'cable', band: true },
    'g-lace-top':      { neck: 'scoop', fit: 'fit', hem: 'tucked', sleeve: 'long', cuff: 'scallop', lace: true },
    'g-brick-top':     { neck: 'boat', fit: 'fit', hem: 'tucked', sleeve: 'long', cuff: 'rib', knit: 'rib' },
    'g-black-tee':     { neck: 'crew', fit: 'fit', hem: 'tucked', sleeve: 'short' },
    'g-cream-crop':    { neck: 'scoop', fit: 'fit', hem: 'crop', sleeve: 'short', lace: true }
  };

  function scallopRow(x0, x1, y, rr, up) {
    var s = 'M' + x0 + ',' + y, n = Math.max(1, Math.round((x1 - x0) / (rr * 2))), w = (x1 - x0) / n;
    for (var i = 0; i < n; i++) s += ' Q' + r1(x0 + w * i + w / 2) + ',' + r1(y + (up ? -rr * 1.6 : rr * 1.6)) + ' ' + r1(x0 + w * (i + 1)) + ',' + y;
    return s;
  }
  function laceFlower(x, y, c) {
    return Ci(x, y, 2.3, 'none', c, 0.8) + Ci(x, y, 0.7, c) + Ci(x - 3.6, y + 2.6, 0.6, c) + Ci(x + 3.6, y + 2.6, 0.6, c);
  }

  function topTorso(k, id) {
    var cfg = TOPS[id], t = GT[id], back = k.back;
    var neck = back ? NECK.back : NECK[cfg.neck];
    var d = sym(neck + SIDE[cfg.fit] + HEM[cfg.hem]);
    var inner = '';
    inner += Fo('M30,226 C46,250 58,290 64,400 L20,400 Z', t.s) + Fo('M210,226 C194,250 182,290 176,400 L220,400 Z', t.s);
    if (!back) { var sheen = 'M68,208 C86,203 98,199 103.5,195 C105.5,201 110,206 116,208 C104,209 92,212 82,216 C76,218 70,216 68,208 Z'; inner += Fo(sheen, t.h, 0.4) + flip(Fo(sheen, t.h, 0.4)); }
    if (cfg.hem === 'tucked' && !back) inner += Ln('M80,268 C84,284 88,298 92,312 M160,268 C156,284 152,298 148,312', t.d, 0.9, 0.45);
    if (cfg.hem === 'tucked') inner += Ln('M88,302 C91,318 93,332 95,346 M152,302 C149,318 147,332 145,346 M116,322 C117,332 118,340 119,346 M102,330 C104,336 105,342 106,346', t.d, 1, 0.7);
    if (cfg.knit === 'cable' && !back) {
      var cab = function (x) {
        var c = '';
        for (var y = 226; y < 384; y += 12) c += 'M' + (x - 4) + ',' + y + ' C' + (x - 4) + ',' + (y + 6) + ' ' + (x + 4) + ',' + (y + 6) + ' ' + (x + 4) + ',' + (y + 12) + ' M' + (x + 4) + ',' + y + ' C' + (x + 4) + ',' + (y + 4) + ' ' + (x + 1) + ',' + (y + 5) + ' ' + (x + 0.5) + ',' + (y + 5.5) + ' M' + (x - 0.5) + ',' + (y + 6.5) + ' C' + (x - 1) + ',' + (y + 7) + ' ' + (x - 4) + ',' + (y + 8) + ' ' + (x - 4) + ',' + (y + 12) + ' ';
        return c;
      };
      inner += Ln(cab(98) + cab(142), t.d, 1, 0.9) + Ln(vlines(88, 88, 6, 222, 384) + vlines(108, 108, 6, 222, 384) + vlines(132, 132, 6, 222, 384) + vlines(152, 152, 6, 222, 384), t.d, 0.9, 0.6);
    }
    if (cfg.knit === 'rib') inner += Ln(vlines(54, 186, 6, 196, 350), t.d, 0.9, 0.55);
    if (cfg.lace && !back) {
      var lc = '';
      for (var row = 0; row < 3; row++) for (var x = 78 + (row % 2) * 8; x <= 162; x += 16) lc += laceFlower(x, 226 + row * 12, t.d);
      inner += lc + Ln(scallopRow(66, 174, 262, 4, false), t.d, 0.9, 0.9);
      inner += Ci(96, 296, 0.9, t.d) + Ci(120, 290, 0.9, t.d) + Ci(144, 298, 0.9, t.d) + Ci(108, 316, 0.9, t.d) + Ci(132, 318, 0.9, t.d);
    }
    if (back) inner += Ln('M120,196 L120,' + (cfg.hem === 'tucked' ? 346 : 398), t.d, 1, 0.6);
    var s = shape(k, d, t, inner);
    // neckline finish
    if (!back) {
      if (cfg.neck === 'crew') s += P('M101.5,193 C103.6,204 110,210.5 120,210.5 C130,210.5 136.4,204 138.5,193 L136,192 C134,200 129,206 120,206 C111,206 106,200 104,192 Z', cfg.knit === 'cable' ? t.s : t.s, t.o, 1.1);
      if (cfg.neck === 'boat') s += Ln('M88,199 C100,203.4 140,203.4 152,199', t.d, 1, 0.8);
      if (cfg.neck === 'scoop' && cfg.lace) s += Ln(scallopRow(99, 141, 216, 2.6, false), t.o, 1, 0.9);
      else if (cfg.neck === 'scoop') s += Ln('M100,197 C102,211 110,218 120,218 C130,218 138,211 140,197', t.d, 1, 0.7);
    } else {
      s += Ln('M106,190 C112,195.4 128,195.4 134,190', t.d, 1, 0.7);
    }
    if (cfg.band) s += shape(k, sym('M120,385 C100,385 80,383 59,379 L57,392 C78,398 100,400 120,400'), { f: t.f, o: t.o }, Ln(vlines(62, 178, 4.5, 380, 400), t.d, 0.9, 0.7), 1.2);
    return s;
  }
  function topSleeves(k, id) {
    var cfg = TOPS[id], t = GT[id];
    var d = SLEEVE[cfg.sleeve];
    var inner = Fo('M65,236 C66,290 64,330 62,410 L54,410 C56,330 59,280 65,236 Z', t.s, 0.9);
    if (cfg.sleeve !== 'short') inner += Ln('M60,324 C56,328 55,334 56,340 M38,330 C42,333 46,333 49,331', t.d, 1, 0.7);
    if (cfg.knit === 'rib') inner += Ln(vlines(40, 64, 6, 210, 410), t.d, 0.9, 0.5);
    if (cfg.lace && !k.back) inner += laceFlower(48, 300, t.d) + laceFlower(54, 352, t.d);
    var s = shape(k, d, t, inner);
    if (cfg.cuff === 'gather') {
      s += Ln('M42,397 L43,405 M50,398 L50,406 M57.5,397 L57,405', t.d, 0.9, 0.8);
      s += shape(k, 'M39,404 C46,406.4 55,406.4 62,404 L61.5,421 C55,423.4 46,423.4 40.5,421 Z', { f: t.s, o: t.o }, Ln(vlines(43.5, 59.5, 4, 406, 421), t.o, 0.8, 0.5), 1.2);
    } else if (cfg.cuff === 'rib') {
      var y0 = cfg.sleeve === 'loose' ? 398 : 404;
      s += shape(k, 'M37,' + y0 + ' C46,' + (y0 + 2) + ' 55,' + (y0 + 2) + ' 63,' + y0 + ' L61.6,422 C55,424.4 46,424.4 39.6,422 Z', { f: t.f, o: t.o }, Ln(vlines(41, 60, 3.6, y0, 424), t.d, 0.9, 0.75), 1.2);
    } else if (cfg.cuff === 'scallop') {
      s += P('M38,404 L62,404 L61.6,416 ' + scallopRow(61.6, 39.6, 416, 2.2, false).replace(/^M[^ ]+/, '') + ' Z', t.f, t.o, 1.2);
      s += Ln('M39,407 L62,407', t.d, 0.8, 0.8) + Ci(45, 411, 0.8, t.d) + Ci(51, 411.4, 0.8, t.d) + Ci(57, 411, 0.8, t.d);
    } else if (cfg.sleeve === 'short') {
      s += Ln('M37.4,281 C47,285 58,285 66,281', t.d, 1, 0.8);
    }
    return pair(s);
  }

  /* ------------------------------------------------------------------ layers */

  var JK_SLEEVE = 'M56,203 C45,207 39,216 38,232 C35,262 32,300 32,340 C32,370 34,394 36,412 L64,412 C65,394 67,368 67,340 C68,310 68,282 67,258 C67,238 64,220 56,203 Z';
  var JK_SIDE = 'M106,187 C94,192 70,198 55,205 C45,211 40,221 42,235 C46,247 58,255 62,262 C64,292 68,316 70,334';

  var LAYERS = {
    'g-gray-blazer': { kind: 'blazer' },
    'g-brown-jacket': { kind: 'blazer', short: true },
    'g-navy-cardigan': { kind: 'cardigan' },
    'g-camel-trench': { kind: 'trench' }
  };

  function jacketSleeves(k, id, kind) {
    var t = GT[id], d = kind === 'trench' ? 'M54,202 C43,206 37,215 36,232 C33,262 30,300 30,340 C30,370 32,394 34,414 L66,414 C67,394 69,368 69,340 C70,310 70,282 69,258 C69,238 64,218 54,202 Z' : JK_SLEEVE;
    var inner = Fo('M67,250 C67,290 66,330 64,416 L55,416 C57,330 60,290 61,250 Z', t.s, 0.9) + Ln('M62,322 C58,327 57,333 58,339 M36,328 C40,331 45,331 48,329', t.d, 1, 0.7);
    var s = shape(k, d, t, inner);
    if (kind === 'blazer') s += Ln('M35.4,400 C45,402.4 56,402.4 64.6,400', t.d, 1, 0.8) + Ci(42, 406, 1.3, t.s, t.o, 0.7) + Ci(47, 407, 1.3, t.s, t.o, 0.7);
    if (kind === 'cardigan') s += shape(k, 'M35.6,396 C45,398.4 56,398.4 65,396 L64.2,413 C56,415.4 45,415.4 36.2,413 Z', { f: t.f, o: t.o }, Ln(vlines(39, 62, 3.4, 396, 416), t.d, 0.9, 0.8), 1.2);
    if (kind === 'trench') s += shape(k, 'M32.6,392 C44,396 56,396 67.6,392 L67.4,401 C56,405 44,405 33,401 Z', { f: t.f, o: t.o }, '', 1.2) + Ci(60, 397, 1.6, t.b || t.o, null) + Ln('M34,408 C44,411 56,411 66,408', t.d, 1, 0.7);
    return pair(s);
  }

  function layerBody(k, id) {
    var cfg = LAYERS[id], t = GT[id], kind = cfg.kind, back = k.back, s = '';
    if (back) {
      var hemY = kind === 'trench' ? 652 : (kind === 'cardigan' ? 414 : (cfg.short ? 392 : 434));
      var side = kind === 'trench' ? ' C64,380 54,480 46,644 C70,650 98,' + hemY + ' 120,' + hemY : (kind === 'cardigan' ? ' C67,358 60,384 58,412 C78,414 100,' + hemY + ' 120,' + hemY : (cfg.short ? ' C68,352 64,372 62,388 C80,391 100,' + hemY + ' 120,' + hemY : ' C67,362 59,394 57,426 C80,432 104,' + hemY + ' 120,' + hemY));
      var bd = sym('M120,184 L106,184 L106,187 ' + (kind === 'trench' ? 'C94,192 68,198 53,205 C43,211 38,221 40,235 C44,247 56,255 60,262 C62,292 66,316 68,332' : JK_SIDE.slice(9)) + side);
      var inner = Fo('M30,226 C46,250 58,290 64,660 L20,660 Z', t.s) + Fo('M210,226 C194,250 182,290 176,660 L220,660 Z', t.s);
      inner += Ln('M120,192 L120,' + (kind === 'trench' ? 560 : hemY), t.d, 1, 0.8);
      if (kind === 'trench') inner += Ln('M120,560 L120,652 M46,250 C80,262 160,262 194,250', t.d, 1, 0.8);
      if (kind === 'blazer' && !cfg.short) inner += Ln('M120,396 L124,' + hemY, t.d, 1, 0.8);
      if (kind === 'cardigan') inner += Ln(vlines(60, 180, 4, 398, 414), t.d, 0.9, 0.7) + Ln('M58,398 C90,401 150,401 182,398', t.d, 1, 0.8);
      s += shape(k, bd, t, inner);
      s += P('M104,186 C110,192.6 130,192.6 136,186 L134,182 C128,186 112,186 106,182 Z', t.s, t.o, 1.1);
      if (kind === 'trench') s += P(sym('M120,327 L66,325 L65,341 L120,343'), t.f, t.o, 1.2) + Ln('M66,333 L174,333', t.d, 0.8, 0.5);
      return s;
    }
    var panel, lapel, inner2 = '';
    if (kind === 'blazer') {
      var hem = cfg.short ? ' C68,352 64,372 62,390 C74,394 94,395 106,392 C110,380 116,360 120,344' : ' C67,362 59,394 57,426 C74,432 94,433 106,430 C112,410 117,372 120,342';
      panel = JK_SIDE + hem + ' C118,300 112,240 106,187 Z';
      lapel = 'M119.4,322 C110,300 96,272 84,246 L82,238 L94,236 L90,228 C94,214 100,200 106,189 C109,236 114,280 119.4,322 Z';
      inner2 = Fo('M30,226 C46,250 58,290 64,440 L20,440 Z', t.s) + Fo('M106,190 C110,240 115,290 119,326 L114,326 C110,290 104,240 101,196 Z', t.s, 0.8);
      if (!cfg.short) inner2 += P('M63,384 L94,382.6 L94.4,391.4 C84,392.6 72,392.8 63.4,392 Z', t.f, t.o, 1.1);
    } else if (kind === 'cardigan') {
      panel = JK_SIDE + ' C67,358 60,384 58,412 L102,414 C103,360 104,280 106,187 Z';
      inner2 = Fo('M30,226 C46,250 58,290 64,440 L20,440 Z', t.s) +
        shape(k, 'M106,187 L99.6,189.6 C98.6,270 97,350 95.4,414 L102,414 C103,360 104,280 106,187 Z', { f: t.f, o: t.o }, '', 1) +
        shape(k, 'M58,398 L102,400 L102,414 L58,412 Z', { f: t.f, o: t.o }, Ln(vlines(61, 100, 3.4, 398, 414), t.d, 0.9, 0.8), 1);
    } else {
      panel = 'M106,187 C94,192 68,198 53,205 C43,211 38,221 40,235 C44,247 56,255 60,262 C62,292 66,316 68,332 C64,380 54,480 46,644 C66,650 92,650 110,646 C112,560 116,420 120,346 L120,282 C114,252 110,220 106,187 Z';
      lapel = 'M120,284 C108,264 90,240 76,222 L72,212 L88,212 L84,204 C94,198 100,193 106,188 C110,222 114,256 120,284 Z';
      inner2 = Fo('M30,226 C46,250 58,290 64,660 L20,660 Z', t.s) + Fo('M120,346 C116,420 112,560 110,646 L102,646 C106,560 112,420 116,346 Z', t.s, 0.8) +
        Ln('M92,350 C88,430 82,540 76,644 M70,354 C64,450 58,550 54,644', t.d, 1, 0.6) +
        Ln('M106,214 C100,236 98,252 100,264 C88,262 76,258 64,252', t.d, 1, 0.6);
    }
    var one = shape(k, panel, t, inner2);
    if (lapel) one += shape(k, lapel, { f: kind === 'trench' ? t.f : t.h, o: t.o }, Fo('M84,246 C96,272 110,300 119.4,322 L119.4,330 C108,304 94,276 82,250 Z', t.s, 0.5), 1.3);
    if (kind === 'trench') one += P('M62,203.6 L95,193.4 L96.6,199.6 L64,210 Z', t.f, t.o, 1.1) + Ci(91.6, 197.6, 1.4, t.b, null);
    s += pair(one);
    // collar band behind the neck
    if (kind === 'blazer') {
      s += Ci(120, cfg.short ? 344 : 342, 3.4, t.s, t.o, 1.1) + Ci(119.2, cfg.short ? 343.2 : 341.2, 1, t.h);
      if (!cfg.short) s += Ln('M139,270.6 L157,268.4', t.o, 1.6) + Ln('M139.4,272.6 L156.6,270.4', t.d, 0.8, 0.6);
      if (cfg.short) s += Ln('M120,344 L120,392', t.o, 1.2) + Ln('M118,350 L118,388', '#CFC6BA', 1.4);
    } else if (kind === 'cardigan') {
      s += Ci(141.6, 232, 2.6, t.h, t.o, 1) + Ci(142.2, 276, 2.6, t.h, t.o, 1) + Ci(142.8, 320, 2.6, t.h, t.o, 1) + Ci(143.4, 364, 2.6, t.h, t.o, 1);
      s += Ln('M137,232 L139.6,232 M137.6,276 L140.2,276', t.d, 1, 0.6);
    } else if (kind === 'trench') {
      s += P(sym('M120,327 L68,325.4 L67.4,341.4 L120,343'), t.f, t.o, 1.2) + Ln('M68,333.4 L172,333.4', t.d, 0.8, 0.5);
      s += P('M139,322.6 L153,322.6 L153,345.4 L139,345.4 Z', 'none', t.b, 1.8) + Ln('M146,322.6 L146,345.4', t.b, 1.2);
      s += P('M149,344 L156.6,384 L150.4,386 L144,345 Z', t.f, t.o, 1.1);
      s += Ci(107, 296, 2.6, t.b, null) + Ci(133, 296, 2.6, t.b, null) + Ci(107, 314, 2.6, t.b, null) + Ci(133, 314, 2.6, t.b, null);
    }
    return s;
  }

  /* ------------------------------------------------------------------ bottoms */

  var BOTTOMS = {
    'g-navy-trousers': { kind: 'trousers', leg: 'wide', pleats: true },
    'g-olive-trousers': { kind: 'trousers', leg: 'straight', pleats: true },
    'g-wide-jeans': { kind: 'trousers', leg: 'jeans', jeans: true },
    'g-gray-leggings': { kind: 'trousers', leg: 'slim' },
    'g-black-skirt': { kind: 'skirt' }
  };
  var LEGSHAPE = {
    wide: 'M120,322 L72,322 C70,350 62,380 56,404 C52,440 48,620 44,822 L114,822 C115,700 117,580 120,472',
    straight: 'M120,322 L72,322 C70,350 62,380 57,404 C54,450 54,640 56,822 L111,822 C112,700 116,580 120,472',
    jeans: 'M120,322 L72,322 C70,350 62,380 56,404 C51,450 46,640 42,824 L114,824 C115,700 117,580 120,472',
    slim: 'M120,322 L72,322 C70,350 62,380 58,404 C55,450 58,520 64,580 C68,612 72,632 73,648 C70,676 71,712 76,752 C79,784 81,806 81,822 L97,822 C98,806 101,782 105,752 C109,722 111,694 108,666 C107,650 108,632 111,604 C115,560 119,516 120,472'
  };
  var HEMX = { wide: [44, 114], straight: [56, 111], jeans: [42, 114], slim: [81, 97] };

  function drawBottom(k, id) {
    var cfg = BOTTOMS[id], t = GT[id], back = k.back, s = '';
    if (cfg.kind === 'skirt') {
      var sd = sym('M120,322 L72,322 C68,350 60,380 56,404 C50,470 44,560 40,648 C66,656 96,658 120,658');
      var folds = 'M100,412 C98,490 96,570 96,656 L86,654 C88,570 92,490 100,412 Z M70,420 C64,490 58,570 54,650 L46,648 C52,570 60,490 70,420 Z';
      var inner = Fo(folds, t.s) + flip(Fo(folds, t.s)) + Ln('M80,406 C74,480 68,560 62,650 M110,410 C110,490 110,570 110,658', t.d, 1, 0.7) + flip(Ln('M80,406 C74,480 68,560 62,650 M110,410 C110,490 110,570 110,658', t.d, 1, 0.7));
      if (back) inner += Ln('M120,336 L120,392', t.d, 1.2, 0.9) + Ln('M120,640 L120,657', t.d, 1, 0.8);
      s += shape(k, sd, t, inner);
      s += shape(k, 'M72,322 L168,322 L168.6,336 L71.4,336 Z', { f: t.f, o: t.o }, '', 1.2);
      if (!back) s += Ci(150, 329, 1.3, t.d, null);
      return s;
    }
    var leg = LEGSHAPE[cfg.leg], hx = HEMX[cfg.leg];
    var d = sym(leg);
    var inner = '';
    var innerShade = 'M120,472 C117,580 ' + (hx[1] + 1) + ',700 ' + hx[1] + ',830 L' + (hx[1] - 12) + ',830 C' + (hx[1] - 9) + ',700 108,580 112,470 Z';
    var outerShade = 'M58,404 C' + (hx[0] + 8) + ',440 ' + (hx[0] + 4) + ',620 ' + hx[0] + ',830 L' + (hx[0] + 9) + ',830 C' + (hx[0] + 12) + ',620 ' + (hx[0] + 16) + ',440 66,404 Z';
    if (cfg.leg !== 'slim') inner += Fo(innerShade, t.s) + flip(Fo(innerShade, t.s)) + Fo(outerShade, t.s, 0.7) + flip(Fo(outerShade, t.s, 0.7));
    else inner += Fo(innerShade.replace(/L\d+,830/, 'L104,830'), t.s, 0.8) + flip(Fo(innerShade.replace(/L\d+,830/, 'L104,830'), t.s, 0.8));
    var mid = (hx[0] + hx[1]) / 2;
    if (!back) {
      inner += Ln('M106,456 C110,462 114,467 118,470 M134,456 C130,462 126,467 122,470', t.d, 1, 0.7);
      if (cfg.pleats) inner += Ln('M98,338 C99,350 99,362 98,374 M98,374 C95,520 ' + (mid + 6) + ',680 ' + mid + ',820', t.d, 1, 0.75) + flip(Ln('M98,338 C99,350 99,362 98,374 M98,374 C95,520 ' + (mid + 6) + ',680 ' + mid + ',820', t.d, 1, 0.75));
      if (cfg.leg === 'wide' || cfg.leg === 'straight') inner += Ln('M74,339 C71,356 66,372 62,386', t.o, 1.1) + flip(Ln('M74,339 C71,356 66,372 62,386', t.o, 1.1));
      if (cfg.jeans) {
        inner += Ln('M73,340 C80,354 90,360 101,357', t.o, 1.1) + flip(Ln('M73,340 C80,354 90,360 101,357', t.o, 1.1));
        inner += Ln('M73,343 C80,357 90,363 101,360', t.t, 0.9, 0.9) + flip(Ln('M73,343 C80,357 90,363 101,360', t.t, 0.9, 0.9));
        inner += Ln('M126,339 L126,402 C126,408 123,412 120,413', t.t, 0.9) + Ln('M120,338 L120,412', t.o, 1);
        inner += Ln('M141,342 L152,342 L152,352', t.t, 0.8, 0.8);
        inner += Ci(101, 357, 1.3, t.t, null) + Ci(139, 357, 1.3, t.t, null);
        inner += Ln('M88,380 C88,520 ' + (mid + 4) + ',680 ' + mid + ',806', t.d, 1, 0.5) + flip(Ln('M88,380 C88,520 ' + (mid + 4) + ',680 ' + mid + ',806', t.d, 1, 0.5));
      } else if (cfg.leg !== 'slim') {
        inner += Ln('M120,338 L120,410', t.o, 1.1) + Ln('M126,339 L126,402 C126,408 123,412 120,413', t.d, 0.9, 0.9);
      }
    } else {
      inner += Ln('M120,338 L120,472', t.o, 1.1);
      if (cfg.leg !== 'slim') inner += Ln('M82,358 L104,355', t.o, 1.2) + flip(Ln('M82,358 L104,355', t.o, 1.2)) + Ln('M92,400 C90,540 ' + (mid + 4) + ',690 ' + mid + ',820', t.d, 1, 0.45) + flip(Ln('M92,400 C90,540 ' + (mid + 4) + ',690 ' + mid + ',820', t.d, 1, 0.45));
      if (cfg.jeans) inner += P('M80,364 L104,361 L105,388 L93,396 L82,390 Z', 'none', t.t, 0.9) + flip(P('M80,364 L104,361 L105,388 L93,396 L82,390 Z', 'none', t.t, 0.9));
    }
    if (cfg.jeans) inner += Fo('M30,806 L210,806 L210,830 L30,830 Z', t.h, 0.55) + Ln('M42,807 L114,807 M126,807 L198,807', t.o, 1, 0.8);
    else if (cfg.leg !== 'slim') inner += Ln('M' + (hx[0] + 6) + ',812 C' + (hx[0] + 22) + ',815.6 ' + (hx[1] - 22) + ',815.6 ' + (hx[1] - 6) + ',813', t.d, 1, 0.5) + flip(Ln('M' + (hx[0] + 6) + ',812 C' + (hx[0] + 22) + ',815.6 ' + (hx[1] - 22) + ',815.6 ' + (hx[1] - 6) + ',813', t.d, 1, 0.5));
    s += shape(k, d, t, inner);
    // waistband
    var wb = cfg.leg === 'slim' ? 'M72,322 L168,322 L168.6,333 L71.4,333 Z' : 'M72,322 L168,322 L168.8,338 L71.2,338 Z';
    s += shape(k, wb, { f: t.f, o: t.o }, cfg.jeans ? Ln('M72,325 L168,325 M72,335 L168,335', t.t, 0.8, 0.9) : '', 1.2);
    if (cfg.leg !== 'slim') {
      var loops = 'M83,320.4 L87,320.4 L87,341 L83,341 Z M104,320.4 L108,320.4 L108,341 L104,341 Z';
      s += P(loops, t.f, t.o, 1) + flip(P(loops, t.f, t.o, 1));
      if (!back) s += Ci(120, 330, 2.8, cfg.jeans ? t.t : t.h, t.o, 1);
    }
    return s;
  }

  /* ------------------------------------------------------------------ dress */

  var DRESS = 'M120,214 C108,214 100,206 98,194 C88,198 70,202 57,208 C48,213 44,222 46,234 C50,246 58,254 63,262 C65,290 69,314 71,332 C67,352 60,380 56,404 C50,470 44,560 40,648 C66,656 96,658 120,658';
  var DRESS_BACK = 'M120,196 C112,196 107,192 105,188 C93,195 70,202 57,208 C48,213 44,222 46,234 C50,246 58,254 63,262 C65,290 69,314 71,332 C67,352 60,380 56,404 C50,470 44,560 40,648 C66,656 96,658 120,658';
  var FLOWERS = [[84, 240], [150, 232], [116, 270], [92, 300], [146, 296], [70, 380], [104, 372], [140, 388], [170, 366], [84, 432], [124, 424], [158, 448], [64, 488], [100, 480], [138, 500], [176, 520], [80, 548], [118, 556], [156, 584], [58, 604], [96, 618], [136, 632], [182, 626], [112, 330]];
  function flower(x, y, t) {
    var s = '', i, a;
    s += P('M' + (x + 3) + ',' + (y + 2) + ' C' + (x + 6) + ',' + (y + 1) + ' ' + (x + 8) + ',' + (y + 3) + ' ' + (x + 8) + ',' + (y + 5) + ' C' + (x + 6) + ',' + (y + 5.4) + ' ' + (x + 4) + ',' + (y + 4.4) + ' ' + (x + 3) + ',' + (y + 2) + ' Z', t.lf);
    for (i = 0; i < 5; i++) { a = i * 72 * Math.PI / 180 - Math.PI / 2; s += Ci(x + Math.cos(a) * 2.3, y + Math.sin(a) * 2.3, 1.7, t.fl); }
    return s + Ci(x, y, 1.1, t.fc);
  }
  function drawDress(k, id) {
    var t = GT['g-blue-dress'], back = k.back;
    var d = sym(back ? DRESS_BACK : DRESS);
    var folds = 'M100,412 C98,490 96,570 96,656 L86,654 C88,570 92,490 100,412 Z M70,420 C64,490 58,570 54,650 L46,648 C52,570 60,490 70,420 Z';
    var inner = Fo('M30,226 C46,250 58,290 64,330 L20,330 Z', t.s) + Fo('M210,226 C194,250 182,290 176,330 L220,330 Z', t.s) + Fo(folds, t.s, 0.8) + flip(Fo(folds, t.s, 0.8));
    var fl = '';
    for (var i = 0; i < FLOWERS.length; i++) fl += flower(FLOWERS[i][0] + (back ? 6 : 0), FLOWERS[i][1], t);
    inner += fl;
    inner += Ln('M80,408 C74,480 68,560 62,650 M110,412 C110,490 110,570 110,658', t.d, 1, 0.6) + flip(Ln('M80,408 C74,480 68,560 62,650 M110,412 C110,490 110,570 110,658', t.d, 1, 0.6));
    if (back) inner += Ln('M120,198 L120,330', t.o, 1.1, 0.8);
    var s = shape(k, d, t, inner);
    s += P('M71,332 C90,337 150,337 169,332 L169.4,338 C150,343 90,343 70.6,338 Z', t.s, t.o, 1.1);
    if (!back) s += Ln('M100,197 C102,211 110,218 120,218 C130,218 138,211 140,197', t.d, 1, 0.8);
    return s;
  }
  function dressSleeves(k) {
    var t = GT['g-blue-dress'];
    var d = 'M58,207 C48,210 41,218 39,232 C36,250 33,266 30,283 C34,287 38,284 42,288 C46,292 50,288 54,291 C58,293 62,289 67,287 C67,276 66,268 66,258 C66,240 64,222 58,207 Z';
    var inner = Fo('M66,250 C66,270 66,280 67,292 L58,292 C60,280 60,268 60,250 Z', t.s) + flower(48, 252, t) + Ln('M44,262 C42,270 40,278 38,286 M56,262 C56,272 56,280 56,290', t.d, 0.9, 0.6);
    return pair(shape(k, d, t, inner));
  }

  /* ------------------------------------------------------------------ shoes */

  var SHOES = { 'g-nude-flats': 'flat', 'g-white-sneakers': 'sneaker', 'g-tan-loafers': 'loafer', 'g-black-heels': 'heel' };

  function shoeFront(k, id) {
    var kind = SHOES[id], t = GT[id], sk = k.skin, s = '';
    if (kind === 'heel') {
      s += P('M81,816 L97,816 C97,826 99,832 102,836 L74,846 C72,842 75,838 78,834 C80,828 81,822 81,816 Z', sk.f, sk.o, k.sw);
      s += Fo('M93,818 L97,818 C97,826 99,832 102,836 L96,838 C95,832 94,826 93,818 Z', sk.s);
      s += shape(k, 'M95,850 L103,850 L102,864 L96,864 Z', { f: t.s, o: t.o }, '', 1.2);
      var hb = 'M103,834 C107,838 107,846 103,851 L97,851 C88,855 70,861 54,864 C44,864.6 39,860 43,853.4 C49,847 60,845 70,845 C82,845 94,841 103,834 Z';
      s += shape(k, hb, t, Fo('M100,846 C90,852 70,858 50,860 L46,866 L104,866 Z', t.s) + Ln('M52,849 C58,847 64,846 70,846.4', t.h, 1.2, 0.7));
      return s;
    }
    s += P(FOOT, sk.f, sk.o, k.sw) + Fo('M93,820 L97,820 C97,830 99,838 101,846 L95,848 C95,838 94,830 93,820 Z', sk.s);
    if (kind === 'flat') {
      var body = 'M101,836 C104.6,843 104.6,854 100.6,860 C92,864 64,865 52,862.6 C43,860.6 40,852 45,846 C51,839 62,836.4 72,838.6 C78,840 82,845 88,847 C94,848 99,843 101,836 Z';
      s += shape(k, body, t, Fo('M101,853 C92,858 66,859 49,857 L46,866 L106,866 Z', t.s) + Ln('M49,849 C54,843 61,840 68,840', t.h, 1.6, 0.9) + Ln('M78,841.6 C82,845 85,846.6 88,847 C94,848 98,843.6 100,838', t.in || t.d, 1.6, 0.9));
      s += P('M103.6,856 C104.4,860.4 101,864 95,864 L53,864 C45,864 40.6,860 41.6,854.6 C44,859 50,861 57,861.2 L95,861.2 C99.4,861.2 102.4,859.4 103.6,856 Z', t.sole, t.o, 1);
      s += P('M72.6,841.2 C69,837.6 65,838.6 66,842 C66.8,844.4 70.4,843.6 72.6,841.2 Z M73.4,841.2 C77,837.6 81,838.6 80,842 C79.2,844.4 75.6,843.6 73.4,841.2 Z', t.f, t.o, 0.9) + Ci(73, 841.4, 1.2, t.d, null) + Ln('M72.4,842.4 L70.6,846 M73.6,842.4 L75.6,845.8', t.o, 0.9);
    } else if (kind === 'loafer') {
      var lb = 'M101,836 C104.6,843 104.6,854 100.6,860 C92,864 64,865 52,862.6 C43,860.6 40,852 45,845 C52,837 64,834 76,835.6 C84,837 86,844 90,846 C95,847 99,842 101,836 Z';
      s += shape(k, lb, t, Fo('M101,853 C92,858 66,859 49,857 L46,866 L106,866 Z', t.s) + Ln('M52,848 C57,844 63,842 69,842', t.h, 1.4, 0.8));
      s += P('M60,843.4 C68,839 80,839 89,842.6 L87.6,849 C79,846 69,846 62,849.6 Z', t.s, t.o, 1.1) + P('M70.6,844.2 L79.4,844.2 L79,846.4 L71,846.4 Z', t.o, null);
      s += P('M103.6,856 C104.4,860.4 101,864 95,864 L53,864 C45,864 40.6,860 41.6,854.6 C44,859 50,861 57,861.2 L95,861.2 C99.4,861.2 102.4,859.4 103.6,856 Z', t.sole, t.o, 1);
    } else {
      var sb = 'M102,834 C106,841 106.6,850 104,856 L44,858 C38.6,856 38,847 44,842.6 C52,835.6 64,833.4 76,835 C86,833 95,831 102,834 Z';
      s += shape(k, sb, t, Fo('M104,848 L44,852 L44,866 L108,866 Z', t.s) + Ln('M58,842.6 C54,846 52,852 53,857', t.d, 1, 0.8));
      s += P('M79,835 C79,829 88,826.6 95,830 L96,836 C90,836 84,836 79,835 Z', t.h, t.o, 1);
      s += Ln('M74.6,840 L84,836.4 M76.6,836.6 L86.6,840.4 M84,839.4 L93,835.8 M86,835.8 L95,839', t.o, 1, 0.9);
      s += P('M105.6,853 L105.8,859.6 C105.8,862.6 103,864 99,864 L46,864 C40,864 37.4,861 38,856.6 C42,857.4 46,857.6 50,857.6 L104,855 Z', t.sole, t.o, 1.1) + Ln('M40,860.6 L105.4,859.6', t.o, 0.8, 0.6);
      s += P('M100.4,836 C103,840 104,846 103,851 L99,849.4 C99.6,845 99,840.6 97.6,837.6 Z', t.tab, t.o, 0.9);
    }
    return s;
  }
  function shoeBack(k, id) {
    var kind = SHOES[id], t = GT[id], sk = k.skin, s = '';
    s += P('M81,818 L97,818 C97.6,830 98,838 98,846 L80,846 C80,836 81,828 81,818 Z', sk.f, sk.o, k.sw);
    if (kind === 'heel') {
      s += shape(k, 'M80,838 C70,840 54,850 46,858 C43,862 46,864 52,864 L82,862 Z', t, '', 1.3);
      s += shape(k, 'M79,836 C78,844 79,850 82,852 L96,852 C99,850 100,844 99,836 C92,840 86,840 79,836 Z', t, Fo('M90,836 L100,836 L100,852 L92,852 Z', t.s, 0.7));
      s += shape(k, 'M85,851 L93,851 L92.4,864 L85.6,864 Z', { f: t.s, o: t.o }, '', 1.2);
      return s;
    }
    var toe = 'M80,849 C72,851 63,855 59,859 C56.6,862.6 60,864.4 66,864.4 L84,864 Z';
    var heelCup = kind === 'sneaker' ? 'M77,836 C76,846 76,856 79,862 L99,862 C102,856 102,846 101,836 C94,840 84,840 77,836 Z' : 'M78,842 C77,850 77,856 80,861 L98,861 C101,856 101,850 100,842 C93,845 85,845 78,842 Z';
    s += shape(k, toe, t, Fo('M84,858 L44,858 L44,866 L84,866 Z', t.s));
    s += shape(k, heelCup, t, Fo('M90,830 L104,830 L104,866 L92,866 Z', t.s, 0.6));
    var sole = t.sole || t.o;
    s += P('M78,859 L100,859 C101,862 99.6,864 97,864 L81,864 C78.4,864 77,862 78,859 Z', sole, t.o, 1);
    if (kind === 'sneaker') s += P('M84,836.6 L94,836.6 L93.4,846 L84.6,846 Z', t.tab, t.o, 0.9);
    return s;
  }

  /* ------------------------------------------------------------------ outfit resolution */

  function catOf(id) {
    if (TOPS[id]) return 'top';
    if (LAYERS[id]) return 'layer';
    if (BOTTOMS[id]) return 'bottom';
    if (id === 'g-blue-dress') return 'dress';
    if (SHOES[id]) return 'shoes';
    return null;
  }
  function resolveOutfit(o) {
    o = o && typeof o === 'object' ? o : {};
    function pick(slot, fallback) {
      var v = o[slot];
      if (v === undefined || v === '') return fallback;
      if (v === null || v === 'none') return null;
      return catOf(v) === slot ? v : fallback;
    }
    var out = {
      top: pick('top', DEFAULT_OUTFIT.top) || DEFAULT_OUTFIT.top,
      bottom: pick('bottom', DEFAULT_OUTFIT.bottom) || DEFAULT_OUTFIT.bottom,
      shoes: pick('shoes', DEFAULT_OUTFIT.shoes) || DEFAULT_OUTFIT.shoes,
      layer: pick('layer', null),
      dress: null
    };
    if (o.dress) out.dress = catOf(o.dress) === 'dress' ? o.dress : 'g-blue-dress';
    if (out.dress) { out.top = null; out.bottom = null; }
    return out;
  }

  /* ------------------------------------------------------------------ compose */

  var seq = 0;
  var VIEWBOX = { full: '0 0 240 880', back: '0 0 240 880', bust: '0 0 240 260' };

  function makeCtx(app, view) {
    var skinC = colorOf('skin', app.skin), hairC = colorOf('hairColor', app.hairColor);
    var k = { U: 'mpsav' + (++seq), n: 0, defs: [], view: view, back: view === 'back', sw: 1.5, app: app };
    var light = lum(skinC) > 0.5;
    k.skin = { f: skinC, s: mix(skinC, light ? '#C8645C' : '#3A1A10', light ? 0.13 : 0.16), o: mix(skinC, light ? '#7A3E2E' : '#2A140C', light ? 0.44 : 0.5), h: lighten(skinC, 0.3) };
    var hl = lum(hairC);
    k.hair = { f: hairC, s: darken(hairC, 0.2), o: darken(hairC, hl > 0.6 ? 0.42 : 0.45), d: darken(hairC, hl > 0.6 ? 0.24 : 0.3), h: lighten(hairC, hl > 0.6 ? 0.45 : 0.24) };
    k.brow = hl > 0.6 ? darken(hairC, 0.42) : darken(hairC, 0.16);
    k.lash = mix(darken(hairC, 0.6), '#2A1915', 0.7);
    k.blush = mix(skinC, '#EE6F86', lum(skinC) > 0.5 ? 0.55 : 0.4);
    return k;
  }

  function svg(appearance, outfit, opts) {
    var view = opts && VIEWBOX[opts.view] ? opts.view : 'full';
    var app = sanitize(appearance || {});
    var o = resolveOutfit(outfit);
    var k = makeCtx(app, view);
    var back = k.back;
    var hs = HAIR[app.hairStyle] || HAIR['wavy-bob'];
    var top = o.top && TOPS[o.top] ? o.top : null;
    var tucked = top && TOPS[top].hem === 'tucked';
    var s = '';
    try {
      if (view !== 'bust') s += El(120, 863, 82, 6.5, '#B98A7C', ' opacity="0.14"');
      if (!back) s += hs.back(k);
      s += drawLegs(k) + drawTorso(k);
      if (top && tucked) s += topTorso(k, top);
      if (o.dress) s += drawDress(k, o.dress);
      else s += drawBottom(k, o.bottom);
      s += back ? pair(shoeBack(k, o.shoes)) : pair(shoeFront(k, o.shoes));
      s += drawArms(k);
      if (top && !tucked) s += topTorso(k, top);
      if (top) s += topSleeves(k, top);
      if (o.dress) s += dressSleeves(k);
      if (o.layer && LAYERS[o.layer]) s += layerBody(k, o.layer) + jacketSleeves(k, o.layer, LAYERS[o.layer].kind);
      s += drawHead(k, hs.ears);
      if (!back) {
        s += drawFace(k);
        s += hs.front(k);
        s += drawGlasses(k);
        s += drawEarrings(k, hs.ears);
      } else {
        s += hs.rear(k);
        if (hs.ears) s += drawEarrings(k, true);
      }
    } catch (err) {
      s = '';
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + VIEWBOX[view] + '" width="100%" height="100%" preserveAspectRatio="xMidYMax meet" role="img" aria-label="' +
      (view === 'back' ? 'Your avatar seen from behind' : 'Your avatar') + '"><defs>' + k.defs.join('') + '</defs>' + s + '</svg>';
  }

  /* ------------------------------------------------------------------ state, storage, sync */

  var memory = null;
  var listeners = [];
  var channel = null;

  function readStored() {
    var raw = null;
    try { raw = global.localStorage ? global.localStorage.getItem(STORAGE_KEY) : null; } catch (e) { raw = null; }
    if (raw) {
      try { return sanitize(JSON.parse(raw)); } catch (e2) { /* fall through */ }
    }
    return null;
  }
  function get() {
    var s = readStored();
    if (s) return s;
    return memory ? sanitize(memory) : clone(DEFAULTS);
  }
  function writeStored(a) {
    try { if (global.localStorage) global.localStorage.setItem(STORAGE_KEY, JSON.stringify(a)); } catch (e) { /* storage blocked */ }
  }
  function notify(a) {
    for (var i = 0; i < listeners.length; i++) {
      try { listeners[i](clone(a)); } catch (e) { /* a listener failing must not stop the others */ }
    }
  }
  function broadcast(a) {
    try { if (channel) channel.postMessage({ type: 'avatar', appearance: a }); } catch (e) { /* ignore */ }
  }
  function set(patch) {
    var next = sanitize(Object.assign ? Object.assign(get(), patch || {}) : get());
    if (!Object.assign && patch) for (var key in patch) next[key] = patch[key];
    next = sanitize(next);
    memory = clone(next);
    writeStored(next);
    rerender();
    notify(next);
    broadcast(next);
    return clone(next);
  }
  function reset() {
    memory = null;
    try { if (global.localStorage) global.localStorage.removeItem(STORAGE_KEY); } catch (e) { /* ignore */ }
    var a = clone(DEFAULTS);
    rerender();
    notify(a);
    broadcast(a);
    return a;
  }
  function onChange(fn) {
    if (typeof fn !== 'function') return function () {};
    listeners.push(fn);
    return function () { var i = listeners.indexOf(fn); if (i >= 0) listeners.splice(i, 1); };
  }

  /* ------------------------------------------------------------------ DOM */

  var APP_ATTRS = { skin: 'data-skin', hairStyle: 'data-hair-style', hairColor: 'data-hair-color', eyes: 'data-eyes', glasses: 'data-glasses', earrings: 'data-earrings', lips: 'data-lips' };
  var OUTFIT_ATTRS = { top: 'data-top', layer: 'data-layer', bottom: 'data-bottom', dress: 'data-dress', shoes: 'data-shoes' };

  function renderEl(el) {
    try {
      var view = el.getAttribute('data-view') || 'full';
      var app = get();
      for (var key in APP_ATTRS) {
        var v = el.getAttribute(APP_ATTRS[key]);
        if (v && findOpt(key, v)) app[key] = v;
      }
      var outfit = {};
      for (var slot in OUTFIT_ATTRS) {
        if (el.hasAttribute(OUTFIT_ATTRS[slot])) outfit[slot] = el.getAttribute(OUTFIT_ATTRS[slot]);
      }
      el.innerHTML = svg(app, outfit, { view: VIEWBOX[view] ? view : 'full' });
      el.setAttribute('data-avatar-mounted', '');
    } catch (e) { /* never break the page */ }
  }
  function mountAll(root) {
    var scope = root || (typeof document !== 'undefined' ? document : null);
    if (!scope) return;
    var list = [];
    if (scope.nodeType === 1 && scope.hasAttribute && scope.hasAttribute('data-avatar')) list.push(scope);
    if (scope.querySelectorAll) {
      var found = scope.querySelectorAll('[data-avatar]');
      for (var i = 0; i < found.length; i++) list.push(found[i]);
    }
    for (var j = 0; j < list.length; j++) renderEl(list[j]);
  }
  function rerender() {
    if (typeof document === 'undefined') return;
    var found = document.querySelectorAll('[data-avatar]');
    for (var i = 0; i < found.length; i++) renderEl(found[i]);
  }

  try {
    if (typeof BroadcastChannel !== 'undefined') {
      channel = new BroadcastChannel(CHANNEL_NAME);
      channel.onmessage = function (ev) {
        var a = ev && ev.data && ev.data.appearance;
        if (a) memory = sanitize(a);
        rerender();
        notify(get());
      };
    }
  } catch (e) { channel = null; }
  try {
    global.addEventListener('storage', function (ev) {
      if (!ev || ev.key === STORAGE_KEY || ev.key === null) { rerender(); notify(get()); }
    });
  } catch (e) { /* no window events */ }

  global.Avatar = {
    OPTIONS: OPTIONS,
    DEFAULTS: clone(DEFAULTS),
    DEFAULT_OUTFIT: clone(DEFAULT_OUTFIT),
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
