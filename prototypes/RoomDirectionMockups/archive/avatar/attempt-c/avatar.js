/* avatar.js, attempt c: the paper doll.
   Contract: STYLE.md, "js/avatar.js".
   The figure stands front on with her arms held a little away from the body, so every garment
   (coats, the dress, the skirt, wide trousers) swaps cleanly with nothing crossing the arms.
   Layers, back to front: back hair, body and skin, bottom, shoes, top, waistband (tucked tops),
   layer, head, face, front hair, glasses and earrings. Plain script, no dependencies, no network,
   no text inside the art. */
(function (global) {
  'use strict';

  var KEY = 'mps.avatar.v1';
  var CHANNEL = 'mps.avatar';

  /* ------------------------------------------------------------------ options */

  var OPTIONS = {
    skin: [
      { id: 's1', label: 'Porcelain', color: '#FBE4D8' },
      { id: 's2', label: 'Fair', color: '#F6D3BD' },
      { id: 's3', label: 'Light', color: '#EFC2A2' },
      { id: 's4', label: 'Tan', color: '#D9A07A' },
      { id: 's5', label: 'Brown', color: '#B07450' },
      { id: 's6', label: 'Deep', color: '#7B4B35' }
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
      { id: 'black', label: 'Black', color: '#2B2326' },
      { id: 'dark-brown', label: 'Dark brown', color: '#4B3226' },
      { id: 'chestnut', label: 'Chestnut', color: '#76482F' },
      { id: 'auburn', label: 'Auburn', color: '#9A4529' },
      { id: 'blonde', label: 'Blonde', color: '#E3C07E' },
      { id: 'silver', label: 'Silver', color: '#CFCBD2' },
      { id: 'rose', label: 'Rose', color: '#E8A2B5' }
    ],
    eyes: [
      { id: 'brown', label: 'Brown', color: '#6A4129' },
      { id: 'hazel', label: 'Hazel', color: '#8A6B35' },
      { id: 'green', label: 'Green', color: '#4F8058' },
      { id: 'blue', label: 'Blue', color: '#4F7FB8' }
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
      { id: 'rose', label: 'Rose', color: '#D9737F' },
      { id: 'nude', label: 'Nude', color: '#C98B7B' },
      { id: 'berry', label: 'Berry', color: '#A8475F' }
    ]
  };

  var DEFAULTS = { skin: 's3', hairStyle: 'wavy-bob', hairColor: 'chestnut', eyes: 'brown',
                   glasses: 'none', earrings: 'hoops', lips: 'rose' };
  var DEFAULT_OUTFIT = { top: 'g-pink-blouse', bottom: 'g-navy-trousers', shoes: 'g-nude-flats', layer: null, dress: null };

  function assign(t) {
    for (var i = 1; i < arguments.length; i++) {
      var s = arguments[i];
      if (s) for (var k in s) if (Object.prototype.hasOwnProperty.call(s, k)) t[k] = s[k];
    }
    return t;
  }
  function optById(group, id) {
    var list = OPTIONS[group] || [];
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }
  function normalize(a) {
    var out = {};
    a = a || {};
    for (var k in DEFAULTS) out[k] = optById(k, a[k]) ? a[k] : DEFAULTS[k];
    return out;
  }

  /* ------------------------------------------------------------------ colour */
  // Shade and outline tones come from the base colour, so any skin or hair colour gets a matching
  // shade and a darker outline of its own hue (never black).

  function hexRgb(h) {
    h = String(h || '').replace('#', '');
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    var n = parseInt(h, 16);
    if (isNaN(n)) n = 0x888888;
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function rgbHex(r, g, b) {
    return '#' + [r, g, b].map(function (v) {
      v = Math.max(0, Math.min(255, Math.round(v)));
      return (v < 16 ? '0' : '') + v.toString(16);
    }).join('').toUpperCase();
  }
  function toHcl(hex) { // hue, chroma, lightness
    var c = hexRgb(hex), r = c[0] / 255, g = c[1] / 255, b = c[2] / 255;
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, h = 0, d = mx - mn;
    if (d > 0) {
      if (mx === r) h = ((g - b) / d) % 6; else if (mx === g) h = (b - r) / d + 2; else h = (r - g) / d + 4;
      h *= 60; if (h < 0) h += 360;
    }
    return [h, d, l];
  }
  function fromHcl(h, c, l) {
    h = ((h % 360) + 360) % 360;
    l = Math.max(0, Math.min(1, l));
    c = Math.max(0, Math.min(c, 1 - Math.abs(2 * l - 1)));
    var x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2, r = 0, g = 0, b = 0;
    if (h < 60) { r = c; g = x; } else if (h < 120) { r = x; g = c; } else if (h < 180) { g = c; b = x; }
    else if (h < 240) { g = x; b = c; } else if (h < 300) { r = x; b = c; } else { r = c; b = x; }
    return rgbHex((r + m) * 255, (g + m) * 255, (b + m) * 255);
  }
  function darken(hex, amt, dh) {
    var q = toHcl(hex), l = q[2] * (1 - amt);
    var c = q[1] * Math.sqrt(l / Math.max(q[2], 0.001)) * (1 + 3 * amt * Math.max(0, q[2] - 0.45));
    return fromHcl(q[0] + (dh || 0), c, l);
  }
  function lighten(hex, amt, dh) {
    var q = toHcl(hex), l = q[2] + (1 - q[2]) * amt;
    return fromHcl(q[0] + (dh || 0), q[1] * (1 - amt * 0.35), l);
  }
  function mix(a, b, t) {
    var x = hexRgb(a), y = hexRgb(b);
    return rgbHex(x[0] + (y[0] - x[0]) * t, x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t);
  }
  function lum(hex) { return toHcl(hex)[2]; }

  /* ------------------------------------------------------------------ path helpers */

  var C = 120; // centre line
  function f(n) { return String(Math.round(n * 10) / 10); }

  // Catmull-Rom through points, as cubic Beziers. A point [x, y, 1] is a corner.
  function smooth(pts, closed) {
    var n = pts.length;
    if (n < 2) return '';
    var t = 1 / 6;
    function g(i) { return closed ? pts[((i % n) + n) % n] : pts[Math.max(0, Math.min(n - 1, i))]; }
    var d = 'M' + f(pts[0][0]) + ' ' + f(pts[0][1]);
    var segs = closed ? n : n - 1;
    for (var i = 0; i < segs; i++) {
      var p0 = g(i - 1), p1 = g(i), p2 = g(i + 1), p3 = g(i + 2);
      var c1x = p1[2] ? p1[0] : p1[0] + (p2[0] - p0[0]) * t, c1y = p1[2] ? p1[1] : p1[1] + (p2[1] - p0[1]) * t;
      var c2x = p2[2] ? p2[0] : p2[0] - (p3[0] - p1[0]) * t, c2y = p2[2] ? p2[1] : p2[1] - (p3[1] - p1[1]) * t;
      d += 'C' + f(c1x) + ' ' + f(c1y) + ' ' + f(c2x) + ' ' + f(c2y) + ' ' + f(p2[0]) + ' ' + f(p2[1]);
    }
    return d + (closed ? 'Z' : '');
  }
  // Scalloped edge: one quadratic bump per segment, bulging to the left of travel (outward on a
  // clockwise outline). A point's third value, when not 1, overrides the bump size of its segment.
  function bumpy(pts, amp, closed) {
    var n = pts.length, d = 'M' + f(pts[0][0]) + ' ' + f(pts[0][1]);
    var segs = closed ? n : n - 1;
    for (var i = 0; i < segs; i++) {
      var a = pts[i], b = pts[(i + 1) % n];
      var dx = b[0] - a[0], dy = b[1] - a[1], m = Math.sqrt(dx * dx + dy * dy) || 1;
      var am = (a[2] != null) ? a[2] : amp;
      d += 'Q' + f((a[0] + b[0]) / 2 + dy / m * am * 2) + ' ' + f((a[1] + b[1]) / 2 - dx / m * am * 2) + ' ' + f(b[0]) + ' ' + f(b[1]);
    }
    return d + (closed ? 'Z' : '');
  }
  function mir(pts) { return pts.map(function (p) { return [2 * C - p[0], p[1], p[2]]; }); }
  // Symmetric closed outline from the left half, listed from top centre down to bottom centre.
  function sym(left) {
    var right = [];
    for (var i = left.length - 1; i >= 0; i--) {
      var p = left[i];
      if ((i === 0 || i === left.length - 1) && Math.abs(p[0] - C) < 0.01) continue;
      right.push([2 * C - p[0], p[1], p[2]]);
    }
    return left.concat(right);
  }
  // Symmetric open line from a left half that ends on the centre line.
  function symLine(left) {
    var r = mir(left).reverse();
    if (Math.abs(left[left.length - 1][0] - C) < 0.01) r.shift();
    return left.concat(r);
  }
  function P(d, fill, stroke, sw, extra) {
    return '<path d="' + d + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 1.5) + '" stroke-linejoin="round" stroke-linecap="round"' : '') +
      (extra ? ' ' + extra : '') + '/>';
  }
  function L(pts, stroke, sw, extra) { return P(smooth(pts, false), 'none', stroke, sw, extra); }
  function circ(x, y, r, fill, stroke, sw, extra) {
    return '<circle cx="' + f(x) + '" cy="' + f(y) + '" r="' + f(r) + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + (sw || 1) + '"' : '') + (extra ? ' ' + extra : '') + '/>';
  }
  function MIR(s) { return s ? '<g transform="matrix(-1 0 0 1 240 0)">' + s + '</g>' : ''; }
  function both(s) { return s + MIR(s); }
  // Fill, then inner shading clipped to the shape, then the outline on top.
  function shape(k, d, fill, stroke, sw, inner) {
    if (!inner) return P(d, fill, stroke, sw);
    var id = k.id('c');
    k.defs.push('<clipPath id="' + id + '"><path d="' + d + '"/></clipPath>');
    return P(d, fill) + '<g clip-path="url(#' + id + ')">' + inner + '</g>' + P(d, 'none', stroke, sw);
  }

  /* ------------------------------------------------------------------ body geometry */
  // viewBox 0 0 240 880, feet on y = 864, head top near y = 22. Left-side numbers; the right side mirrors.

  var ARM = [[66, 199, 12.6], [59.6, 240, 11.8], [53, 282, 10.6], [46.6, 320, 9.5], [40.8, 358, 8.7], [35.8, 396, 7.9], [31.8, 430, 7.1]];
  var PROFILE = [[236, 70.5], [262, 72.5], [292, 75.5], [322, 78], [358, 71], [392, 63], [428, 61], [460, 62]];
  function sideX(y) {
    if (y <= PROFILE[0][0]) return PROFILE[0][1];
    for (var i = 1; i < PROFILE.length; i++) {
      if (y <= PROFILE[i][0]) {
        var a = PROFILE[i - 1], b = PROFILE[i], u = (y - a[0]) / (b[0] - a[0]);
        u = u * u * (3 - 2 * u) * 0.5 + u * 0.5; // ease between samples
        return a[1] + (b[1] - a[1]) * u;
      }
    }
    return PROFILE[PROFILE.length - 1][1];
  }
  function skAt(t) {
    var n = ARM.length - 1; t = Math.max(0, Math.min(n, t));
    var i = Math.min(n - 1, Math.floor(t)), u = t - i, a = ARM[i], b = ARM[i + 1];
    return [a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u, a[2] + (b[2] - a[2]) * u];
  }
  function skDir(t) {
    var a = skAt(t - 0.4), b = skAt(t + 0.4), dx = b[0] - a[0], dy = b[1] - a[1], m = Math.sqrt(dx * dx + dy * dy) || 1;
    return [dx / m, dy / m];
  }
  // Point at arm parameter t, offset `off` toward the outer edge (negative: toward the body).
  function armPt(t, off) { var p = skAt(t), d = skDir(t); return [p[0] - d[1] * off, p[1] + d[0] * off]; }
  function exFn(ex) { return typeof ex === 'function' ? ex : function () { return ex || 0; }; }
  function armTs(t0, t1) {
    var ts = [t0];
    for (var i = Math.floor(t0) + 1; i < t1 - 0.2; i++) ts.push(i);
    ts.push(t1);
    return ts;
  }
  function armHalf(t, ex) { return skAt(t)[2] + exFn(ex)(t); }
  function capPt(e) { return [67.4, 189.4 - e * 0.35]; }
  function shoulderPt(ex) { return armPt(0, armHalf(0, ex)); }
  // Closed sleeve outline from t0 to t1. endStyle: number (bulge of the end) or {scallop: n}.
  // With cap (a point on the bodice shoulder line) the sleeve starts with a rounded shoulder and
  // returns up an armhole seam, so it can sit on top of the bodice.
  function sleevePts(t0, t1, ex, endStyle, cap) {
    var ts = armTs(t0, t1), outer = [], inner = [];
    if (cap) ts = [0.32].concat(ts.filter(function (t) { return t >= 0.9; }));
    ts.forEach(function (t) { var w = armHalf(t, ex); outer.push(armPt(t, w)); inner.push(armPt(t, -w)); });
    var a = outer[outer.length - 1].slice(), b = inner[inner.length - 1].slice(), d = skDir(t1);
    a[2] = 1; b[2] = 1;
    var pts = outer.slice(0, -1);
    if (cap) {
      var top = armPt(0, armHalf(0, ex));
      pts.unshift([top[0] + 1.6, top[1] - 1.6]);
      pts.unshift([cap[0], cap[1], 1]);
    } else {
      pts[0] = pts[0].slice(); pts[0][2] = 1;
    }
    pts.push(a);
    if (endStyle && endStyle.scallop) {
      var n = endStyle.scallop;
      for (var i = 1; i < n * 2; i++) {
        var u = i / (n * 2), bump = (i % 2) ? endStyle.amp || 2.4 : 0;
        pts.push([a[0] + (b[0] - a[0]) * u + d[0] * bump, a[1] + (b[1] - a[1]) * u + d[1] * bump, bump ? 0 : 1]);
      }
    } else {
      var bl = endStyle == null ? 1.6 : endStyle;
      pts.push([(a[0] + b[0]) / 2 + d[0] * bl, (a[1] + b[1]) / 2 + d[1] * bl]);
    }
    pts.push(b);
    var rin = inner.slice(0, -1).reverse();
    if (cap) {
      rin = rin.filter(function (p, i) { return i < rin.length - 1; }); // drop t = 0.32 on the inside
      var pit = armPt(1, -armHalf(1, ex));
      if (!rin.length || Math.abs(rin[rin.length - 1][1] - pit[1]) > 2) rin.push(pit);
      rin[rin.length - 1] = rin[rin.length - 1].slice(); rin[rin.length - 1][2] = 1;
      var p0 = rin[rin.length - 1];
      rin.push([p0[0] - 3.4, p0[1] - 17], [cap[0] + 1.2, cap[1] + 17]);
      return pts.concat(rin);
    }
    rin[rin.length - 1] = rin[rin.length - 1].slice(); rin[rin.length - 1][2] = 1;
    return pts.concat(rin);
  }
  // A band of the sleeve between two offsets (for shading strips), as a closed outline.
  function armBand(t0, t1, offA, offB) {
    var ts = armTs(t0, t1), a = [], b = [];
    ts.forEach(function (t) { a.push(armPt(t, offA(t))); b.push(armPt(t, offB(t))); });
    return smooth(a.concat(b.reverse()), true);
  }
  // Line across the sleeve at t (cuff seams, bands), following the end bulge a little.
  function armAcross(t, ex, bulge) {
    var w = armHalf(t, ex), d = skDir(t), m = armPt(t, 0);
    return [armPt(t, w - 0.4), [m[0] + d[0] * (bulge || 1.2), m[1] + d[1] * (bulge || 1.2)], armPt(t, -w + 0.4)];
  }

  var TORSO = [[120, 132, 1], [107.2, 136], [106.8, 164], [103, 175.6], [90, 182], [73, 187.6], [60, 194], [54.5, 203],
               [57, 221], [65, 234], [71, 242], [72.5, 262], [75.5, 292], [78, 322], [71, 358], [63, 392], [61, 428],
               [70, 450], [95, 460], [120, 463]];
  var LEG_OUT = [[63, 392, 1], [60.6, 450], [62, 520], [66.6, 598], [70.6, 646], [68.6, 680], [67.6, 708], [69.6, 744], [74.6, 790], [78.4, 822], [79.8, 840]];
  var FOOT_SX = 1.22, FOOT_SY = 1.1, FOOT_OX = 96, FOOT_OY = 864.4;
  var FOOT_T = 'matrix(' + FOOT_SX + ' 0 0 ' + FOOT_SY + ' ' + f(FOOT_OX - FOOT_OX * FOOT_SX) + ' ' + f(FOOT_OY - FOOT_OY * FOOT_SY) + ')';
  var FOOT = [[78.4, 849], [72.4, 854.6], [67.4, 859.2], [67.6, 863.6, 1], [95.6, 864, 1], [97.6, 858.4], [95.2, 849]].map(function (p) {
    return [FOOT_OX + (p[0] - FOOT_OX) * FOOT_SX, FOOT_OY + (p[1] - FOOT_OY) * FOOT_SY, p[2]];
  });
  var LEG_IN = [[93.6, 840], [94.8, 822], [97.8, 790], [101.6, 750], [103.6, 712], [103.2, 684], [101.6, 646], [109, 570], [116, 500], [119.4, 456, 1]];

  /* ------------------------------------------------------------------ garment tones */
  // Worn garments use the same tones as js/garments.js so the closet and the figure match.
  var GT = {
    'g-pink-blouse':    { f: '#F4B4C2', s: '#EC9DB0', h: '#FBD0D9', l: '#D97F97', d: '#D97F97', i: '#E08EA4' },
    'g-cream-sweater':  { f: '#FFF3E0', s: '#F1DEBF', h: '#FFFCF6', l: '#C9A676', d: '#DDBE92', i: '#E8D0A8' },
    'g-lace-top':       { f: '#FFFDF8', s: '#F0E7D6', h: '#FFFFFF', l: '#C6AA80', d: '#D6C09C', i: '#E6D7BD', p: '#D9C5A1' },
    'g-brick-top':      { f: '#B5533C', s: '#9E4531', h: '#CC6E56', l: '#772E1F', d: '#8E3C2A', i: '#88392A' },
    'g-black-tee':      { f: '#2E2A30', s: '#221F24', h: '#4E4853', l: '#131115', d: '#5A535F', i: '#1C191E' },
    'g-navy-cardigan':  { f: '#27335F', s: '#1D2749', h: '#374780', l: '#121A33', d: '#5B6CA3', i: '#182040', b: '#E7BC6E', bl: '#B98632' },
    'g-gray-blazer':    { f: '#A9ABB3', s: '#93959F', h: '#C4C6CD', l: '#6A6C78', d: '#7C7E8A', i: '#F0DCDF', b: '#55576A', bl: '#3E404F' },
    'g-camel-trench':   { f: '#C9A06A', s: '#B88C54', h: '#DEBC8C', l: '#906C3B', d: '#A07A45', i: '#A87E48', b: '#6B4728', bl: '#4F331B' },
    'g-navy-trousers':  { f: '#27335F', s: '#1D2749', h: '#334277', l: '#121A33', d: '#4A5A96', b: '#3A4A80' },
    'g-olive-trousers': { f: '#7C8450', s: '#69713F', h: '#959D68', l: '#4B522B', d: '#5C6436', b: '#5C6436' },
    'g-wide-jeans':     { f: '#6F93C4', s: '#5B80B3', h: '#8BACD8', l: '#3D6097', d: '#4C6FA8', t: '#F0D28E', b: '#C8964A' },
    'g-black-skirt':    { f: '#2E2A30', s: '#221F24', h: '#443E49', l: '#131115', d: '#5A535F' },
    'g-blue-dress':     { f: '#8FB3E3', s: '#789FD5', h: '#AAC8EF', l: '#4E77B2', d: '#5F87C0', i: '#6B92CC',
                          fl: '#FFF7EA', fc: '#F3D97C', fp: '#F4B4C2', lf: '#5C9670' },
    'g-nude-flats':     { f: '#F1DCC6', s: '#E2C8AC', h: '#F9ECDD', l: '#B48F68', d: '#C4A07A', i: '#C9A684', sole: '#C8A27C' },
    'g-black-heels':    { f: '#2E2A30', s: '#1F1C21', h: '#5A535F', l: '#111013', d: '#5A535F', i: '#D6B898', sole: '#B8926C' },
    'g-white-sneakers': { f: '#FAFAFA', s: '#E9E4DE', h: '#FFFFFF', l: '#B3A79B', d: '#C7BCB1', i: '#DCD4CB', sole: '#EADBC2', tab: '#F4B4C2' },
    'g-tan-loafers':    { f: '#B98552', s: '#A2713F', h: '#CB9B6B', l: '#7A532A', d: '#8E6234', i: '#8A5B30', sole: '#5E3E22' }
  };
  function derivedTones(base) {
    var dark = lum(base) < 0.35;
    return { f: base, s: darken(base, 0.09), h: lighten(base, 0.3), l: darken(base, dark ? 0.45 : 0.32),
             d: dark ? lighten(base, 0.22) : darken(base, 0.2), i: darken(base, 0.18), b: darken(base, 0.35), bl: darken(base, 0.5),
             t: '#F0D28E', sole: darken(base, 0.4), fl: '#FFF7EA', fc: '#F3D97C', fp: '#F4B4C2', lf: '#5C9670', tab: '#F4B4C2', p: darken(base, 0.15) };
  }

  var WORN = {
    top: ['g-pink-blouse', 'g-cream-sweater', 'g-lace-top', 'g-brick-top', 'g-black-tee'],
    layer: ['g-gray-blazer', 'g-navy-cardigan', 'g-camel-trench'],
    bottom: ['g-navy-trousers', 'g-olive-trousers', 'g-wide-jeans', 'g-black-skirt'],
    dress: ['g-blue-dress'],
    shoes: ['g-nude-flats', 'g-white-sneakers', 'g-tan-loafers', 'g-black-heels']
  };
  // Closet pieces without a worn drawing of their own borrow the nearest cut, in their own colour.
  var ALIAS = {
    'g-cream-crop': { slot: 'top', use: 'g-lace-top', color: '#F8ECD8' },
    'g-brown-jacket': { slot: 'layer', use: 'g-gray-blazer', color: '#7A4B2E' },
    'g-gray-leggings': { slot: 'bottom', use: 'g-olive-trousers', color: '#8E9098' }
  };
  var TUCKED = { 'g-pink-blouse': 1, 'g-lace-top': 1, 'g-black-tee': 1 };

  function resolveSlot(slot, id) {
    if (id && WORN[slot].indexOf(id) >= 0) return { id: id, c: GT[id] };
    if (id && ALIAS[id] && ALIAS[id].slot === slot) {
      var t = derivedTones(ALIAS[id].color);
      if (ALIAS[id].use === 'g-lace-top') t.p = darken(ALIAS[id].color, 0.2);
      return { id: ALIAS[id].use, c: t };
    }
    var def = slot === 'layer' ? null : (slot === 'dress' ? null : DEFAULT_OUTFIT[slot]);
    if (slot === 'layer' || slot === 'dress') return null;
    return { id: def, c: GT[def] };
  }
  function isNone(v) { return v == null || v === '' || v === 'none' || v === 'null' || v === false; }
  function resolveOutfit(o) {
    o = o || {};
    var r = {};
    r.dress = isNone(o.dress) ? null : (resolveSlot('dress', o.dress) || { id: 'g-blue-dress', c: GT['g-blue-dress'] });
    r.top = resolveSlot('top', isNone(o.top) ? DEFAULT_OUTFIT.top : o.top);
    r.bottom = resolveSlot('bottom', isNone(o.bottom) ? DEFAULT_OUTFIT.bottom : o.bottom);
    r.shoes = resolveSlot('shoes', isNone(o.shoes) ? DEFAULT_OUTFIT.shoes : o.shoes);
    r.layer = isNone(o.layer) ? null : (resolveSlot('layer', o.layer) || null);
    if (!isNone(o.layer) && !r.layer && WORN.layer.indexOf(o.layer) < 0) r.layer = null;
    return r;
  }

  /* ------------------------------------------------------------------ context */

  var uid = 0;
  function makeCtx(app, view) {
    var u = 'av' + (++uid) + 'x';
    var n = 0;
    var skin = optById('skin', app.skin).color;
    var hair = optById('hairColor', app.hairColor).color;
    var eye = optById('eyes', app.eyes).color;
    var lip = optById('lips', app.lips).color;
    var hl = lum(hair);
    return {
      view: view, back: view === 'back', app: app, defs: [],
      id: function (s) { n++; return u + s + n; },
      sk: { f: skin, s: darken(skin, 0.07, -2), s2: darken(skin, 0.15, -4), l: darken(skin, 0.3, -7), h: lighten(skin, 0.4),
            blush: mix('#F07F8E', skin, 0.25) },
      hr: { f: hair, s: darken(hair, 0.16), l: darken(hair, hl > 0.6 ? 0.34 : 0.4), h: lighten(hair, hl > 0.6 ? 0.45 : 0.28, 4),
            brow: hl > 0.6 ? darken(hair, 0.42) : (hl < 0.2 ? lighten(hair, 0.08) : darken(hair, 0.12)) },
      ey: { f: eye, s: darken(eye, 0.32), h: lighten(eye, 0.3), l: darken(eye, 0.5), p: '#24160F' },
      lp: { f: lip, d: darken(lip, 0.22), h: lighten(lip, 0.35) },
      lash: mix('#2E1C17', hair, hl > 0.6 ? 0.25 : 0.1)
    };
  }

  /* ------------------------------------------------------------------ body */

  function handLocal(u, v) { // wrist frame: u along the hand, v toward the body
    var W = skAt(6), d = skDir(6);
    return [W[0] + d[0] * u + d[1] * v, W[1] + d[1] * u - d[0] * v];
  }
  var HAND = [[7.6, -8.4], [16.2, -9.8], [24.8, -10.2], [32.4, -9.4], [38.6, -7.6], [43.4, -4.6], [46.6, -0.6], [47, 3], [44.8, 6.2], [40.2, 8.4], [34.4, 9.8], [28.2, 10.9], [20.6, 11.4], [12.4, 10.6], [5.4, 8.8]];
  var THUMB = [[9, 5], [17, 6.6], [25.4, 7.6], [30.6, 9.2], [30.4, 11.2], [24, 11.6], [15.6, 10.8], [9, 9.4]];

  function armSkin(k) {
    var s = k.sk, ts = armTs(0, 6), outer = [], inner = [];
    ts.forEach(function (t) { var w = armHalf(t, 0); outer.push(armPt(t, w)); inner.push(armPt(t, -w)); });
    outer[0] = outer[0].slice(); outer[0][2] = 1;
    var hand = HAND.map(function (p) { return handLocal(p[0], p[1]); });
    var pts = outer.concat(hand, inner.reverse());
    pts[pts.length - 1] = pts[pts.length - 1].slice(); pts[pts.length - 1][2] = 1;
    var d = smooth(pts, true);
    var shadeIn = armBand(0.5, 6, function (t) { return -armHalf(t, 0) - 2; }, function (t) { return -armHalf(t, 0) + 4.2; });
    var handShade = smooth([handLocal(2, -9), handLocal(18, -10.6), handLocal(34, -9.8), handLocal(46, -4.6), handLocal(40, -5.4), handLocal(24, -6.4), handLocal(8, -5.6)], true);
    var o = shape(k, d, s.f, s.l, 1.4, P(shadeIn, s.s) + P(handShade, s.s));
        if (!k.back) {
      o += L([handLocal(8.4, 5), handLocal(17, 6.6), handLocal(25.4, 7.6), handLocal(30.6, 9.4), handLocal(30.2, 11.2)], s.l, 1.1);
      o += L([handLocal(37.4, -5.6), handLocal(43.6, -4)], s.l, 0.95, 'opacity="0.8"');
      o += L([handLocal(37.6, -1.2), handLocal(46, 0.6)], s.l, 0.95, 'opacity="0.8"');
      o += L([handLocal(36.8, 3.4), handLocal(44.2, 5)], s.l, 0.95, 'opacity="0.8"');
    } else {
      o += L([handLocal(35.5, -2.2), handLocal(43.6, -0.4)], s.l, 0.95, 'opacity="0.6"');
      o += L([handLocal(35, 2), handLocal(42.8, 3.6)], s.l, 0.95, 'opacity="0.6"');
    }
    return both(o);
  }
  function legSkin(k) {
    var s = k.sk;
    var pts = LEG_OUT.concat(FOOT, LEG_IN);
    var d = smooth(pts, true);
    var inner = smooth([[121, 470], [116, 500], [109, 570], [101.6, 646], [103.2, 684], [103.6, 712], [101.6, 750], [97.8, 790], [93.6, 846],
                        [88.6, 846], [92.6, 790], [96.4, 750], [98.2, 712], [97.8, 684], [96.2, 646], [103, 570], [110, 500], [114, 470]], true);
    var o = shape(k, d, s.f, s.l, 1.4, P(inner, s.s));
    o += L([[78.4, 652], [86, 656], [94, 653]], s.s2, 1, 'opacity="0.8"');
    o += L([[83, 834], [86.4, 838]], s.s2, 0.9, 'opacity="0.7"');
    return both(o);
  }
  function torsoSkin(k) {
    var s = k.sk, d = smooth(sym(TORSO), true);
    var o = P(d, s.f, s.l, 1.4);
    o += P(smooth([[107, 139, 1], [133, 139, 1], [133, 154.6], [127, 160.4], [120, 161.8], [113, 160.4], [107, 154.6]], true), s.s);
    o += both(L([[106, 183.5], [98.5, 186], [91, 185.4]], s.s2, 1, 'opacity="0.6"'));
    if (k.back) o += L([[120, 168], [120, 176]], s.s2, 1, 'opacity="0.5"');
    return o;
  }
  function bodyLayer(k) { return armSkin(k) + legSkin(k) + torsoSkin(k); }

  /* ------------------------------------------------------------------ head and face */

  var FACE = [[120, 150.6], [105.6, 149.2], [92.4, 141.6], [83, 129.6], [78.4, 114], [78, 96], [81, 78], [92, 63.5], [106, 56], [120, 54],
              [134, 56], [148, 63.5], [159, 78], [162, 96], [161.6, 114], [157, 129.6], [147.6, 141.6], [134.4, 149.2]];
  var FACE_D = smooth(FACE, true);
  function headLayer(k) {
    var s = k.sk, o = '';
    var ear = smooth([[79.4, 101.6], [73.4, 99], [70.6, 105.6], [71.4, 113.6], [74.6, 120.6], [79.4, 123.4]], true);
    var earIn = L([[76.9, 106.2], [74.5, 109.8], [75.2, 115], [77.4, 118.2]], s.s2, 1.1);
    o += both(P(ear, s.f, s.l, 1.4) + earIn);
    if (k.back) {
      // back of the head: skull and nape
      o += P(smooth([[120, 46], [146, 52], [162, 72], [164, 100], [158, 126], [142, 142], [133.2, 150, 1], [106.8, 150, 1], [98, 142], [82, 126], [76, 100], [78, 72], [94, 52]], true), s.f, s.l, 1.4);
      return o;
    }
    o += shape(k, FACE_D, s.f, s.l, 1.45, P(smooth([[84, 124], [92, 138], [106, 147.6], [120, 150.6], [134, 147.6], [148, 138], [156, 124], [150, 134], [136, 143.4], [120, 146.4], [104, 143.4], [90, 134]], true), s.s, null, null, 'opacity="0.7"'));
    return o;
  }

  function eye(k, cx, side) {
    var cy = 108;
    function pts(arr) { return arr.map(function (p) { return [cx + p[0] * side * 1.08, cy + p[1] * 1.08, p[2]]; }); }
    var white = smooth(pts([[11.6, 0.8], [7.4, -4.9], [0.6, -7.2], [-6.6, -6.1], [-11.2, -0.9], [-7.8, 4.7], [-0.4, 6.9], [6.8, 5.3]]), true);
    var cid = k.id('eye'), gid = k.id('iris');
    k.defs.push('<clipPath id="' + cid + '"><path d="' + white + '"/></clipPath>');
    k.defs.push('<linearGradient id="' + gid + '" x1="0" y1="0" x2="0" y2="1"><stop offset="0.15" stop-color="' + k.ey.s + '"/><stop offset="1" stop-color="' + k.ey.h + '"/></linearGradient>');
    var ix = cx + 0.4 * side, iy = cy + 0.5;
    var o = P(white, '#FFFDFB');
    o += '<g clip-path="url(#' + cid + ')">' +
      P(white, 'none', k.sk.s2, 3, 'opacity="0.35"') +
      circ(ix, iy, 8.1, 'url(#' + gid + ')', k.ey.l, 0.9) +
      circ(ix, iy + 0.4, 3.9, k.ey.p) +
      circ(ix + 3, iy - 3.1, 2.4, '#FFFFFF') +
      circ(ix - 2.7, iy + 3.4, 1.1, '#FFFFFF', null, null, 'opacity="0.85"') +
      '</g>';
    var lid = smooth(pts([[15.9, -4.4, 1], [12.7, -3.2], [7.2, -7.8], [0.4, -9.4], [-6.9, -8], [-11.9, -1.5, 1], [-6.7, -6], [0.4, -7.4], [7, -5.4], [11.8, 0.9, 1], [13.4, -1.8]]), true);
    o += P(lid, k.lash);
    o += L(pts([[8.6, 4.8], [3, 7.1], [-3, 7.1], [-7.4, 5]]), k.sk.l, 0.9, 'opacity="0.5"');
    o += L(pts([[9.8, -8], [3, -11.8], [-4.6, -11.6], [-9.3, -7.8]]), k.sk.s2, 0.95, 'opacity="0.75"');
    var brow = smooth(pts([[14.2, -16.2, 1], [7.4, -20.6], [-0.8, -21.6], [-8.8, -19.9], [-11.6, -18.2], [-11.4, -16.4, 1], [-8.6, -17.3], [-0.8, -18.8], [6.8, -17.9]]), true);
    o += P(brow, k.hr.brow);
    return o;
  }
  function faceLayer(k) {
    var s = k.sk, o = '';
    o += eye(k, 101, -1) + eye(k, 139, 1);
    o += '<ellipse cx="94.5" cy="125.5" rx="9.5" ry="5.4" fill="' + s.blush + '" opacity="0.28"/>' +
         '<ellipse cx="145.5" cy="125.5" rx="9.5" ry="5.4" fill="' + s.blush + '" opacity="0.28"/>' +
         '<ellipse cx="94.5" cy="125.8" rx="5.6" ry="3.2" fill="' + s.blush + '" opacity="0.22"/>' +
         '<ellipse cx="145.5" cy="125.8" rx="5.6" ry="3.2" fill="' + s.blush + '" opacity="0.22"/>';
    o += L([[121.6, 117.6], [122.8, 122.4], [121.2, 125.2], [118.8, 125.7]], s.l, 1.25);
    o += circ(118.6, 120.2, 1.1, s.h, null, null, 'opacity="0.8"');
    var m = '';
    m += P(smooth([[114.4, 134.6, 1], [117.2, 133.5], [120, 134.3], [122.8, 133.5], [125.6, 134.6, 1], [120, 136.4]], true), k.lp.f, null, null, 'opacity="0.85"');
    m += P(smooth([[115.4, 136.3, 1], [117.6, 139], [120, 139.8], [122.4, 139], [124.6, 136.3, 1], [120, 137.7]], true), k.lp.f);
    m += circ(121.4, 138.1, 0.8, k.lp.h, null, null, 'opacity="0.8"');
    m += L([[113.6, 134.2], [117, 136.9], [120, 137.5], [123, 136.9], [126.4, 134.2]], k.lp.d, 1.25);
    m += L([[112.6, 133.2], [113.7, 134.7]], k.lp.d, 0.85, 'opacity="0.8"');
    m += L([[127.4, 133.2], [126.3, 134.7]], k.lp.d, 0.85, 'opacity="0.8"');
    o += '<g transform="matrix(1.16 0 0 1.16 -19.2 -21.8)">' + m + '</g>';
    return o;
  }

  /* ------------------------------------------------------------------ hair */

  function hairSet(style) {
    var H = HAIR[style] || HAIR['wavy-bob'];
    return H;
  }
  function strands(k, lines, w, op) {
    return lines.map(function (p) { return L(p, k.hr.l, w || 1.1, 'opacity="' + (op || 0.5) + '"'); }).join('');
  }
  function lens(pts, w) {
    if (pts.length === 2) pts = [pts[0], [(pts[0][0] + pts[1][0]) / 2, (pts[0][1] + pts[1][1]) / 2], pts[1]];
    var a = pts[0], b = pts[pts.length - 1], dx = b[0] - a[0], dy = b[1] - a[1], m = Math.sqrt(dx * dx + dy * dy) || 1;
    var nx = -dy / m, ny = dx / m, top = [], bot = [];
    pts.forEach(function (p, i) {
      var u = i / (pts.length - 1), t = Math.sin(Math.PI * u) * w / 2, end = (i === 0 || i === pts.length - 1) ? 1 : 0;
      top.push([p[0] + nx * t, p[1] + ny * t, end]);
      if (!end) bot.push([p[0] - nx * t, p[1] - ny * t]);
    });
    return smooth(top.concat(bot.reverse()), true);
  }
  function sheen(k, lines, w, op) {
    return lines.map(function (p) { return P(lens(p, w || 4.4), k.hr.h, null, null, 'opacity="' + (op || 0.6) + '"'); }).join('');
  }

  var BOB_OUTER_R = [[146, 26], [168, 38], [184, 60], [192, 88], [193, 112], [189, 132], [194, 154], [193, 176], [186, 192]];
  var HAIRLINE_SWOOP = [[161, 108], [157, 90], [149, 77], [137, 69], [125, 64], [115, 59.5, 1], [106, 63], [95, 71], [86, 85], [81, 103]];

  var HAIR = {
    'wavy-bob': {
      back: [[120, 30], [147, 33], [169, 47], [183, 72], [188, 104], [184, 124], [189, 144], [192, 162], [186, 180], [176, 192], [160, 190], [146, 186], [132, 190], [120, 188], [108, 190], [94, 186], [80, 190], [64, 192], [54, 180], [48, 162], [51, 144], [56, 124], [52, 104], [57, 72], [71, 47], [93, 33]],
      front: [[120, 23], [146, 26], [168, 37], [184, 58], [192, 84], [191, 108], [186, 124], [192, 142], [196, 160], [190, 176], [194, 190], [190, 198], [180, 199], [172, 194], [165, 199], [157, 193, 1], [160, 178], [157, 164], [161, 146], [163, 128], [160, 110], [157, 92], [149, 78], [137, 69], [125, 64], [115, 59.5, 1], [106, 63], [95, 71], [86, 85], [81, 103], [79.5, 122], [82, 140], [79, 160], [81, 178], [84, 193, 1], [76, 199], [68, 194], [60, 199], [50, 196], [46, 188], [50, 176], [44, 160], [48, 142], [54, 124], [49, 108], [48, 84], [56, 58], [72, 37], [94, 26]],
      lines: [[[115, 59.5], [116, 46], [118, 31]],
              [[118, 40], [140, 46], [160, 60], [174, 84], [180, 108], [176, 124], [182, 144], [186, 162], [180, 178], [184, 192]],
              [[124, 54], [144, 62], [158, 80], [166, 104], [170, 124], [168, 140], [174, 160], [170, 178], [174, 194]],
              [[112, 40], [92, 46], [72, 62], [62, 86], [58, 108], [64, 124], [58, 144], [54, 162], [60, 178], [56, 192]],
              [[110, 52], [94, 60], [82, 78], [74, 102], [70, 124], [72, 140], [66, 160], [70, 178], [66, 194]]],
      shine: [[[94, 40], [110, 33], [130, 32], [142, 35]], [[186, 134], [190, 146], [190, 158]], [[54, 134], [50, 146], [50, 158]], [[171, 50], [178, 60]]],
      backView: [[120, 23], [146, 26], [168, 37], [184, 58], [192, 84], [191, 108], [186, 124], [192, 142], [196, 160], [190, 176], [194, 190], [188, 199], [176, 200], [164, 195], [150, 201], [136, 196], [120, 201], [104, 196], [90, 201], [76, 195], [64, 200], [52, 199], [46, 190], [50, 176], [44, 160], [48, 142], [54, 124], [49, 108], [48, 84], [56, 58], [72, 37], [94, 26]],
      backLines: [[[120, 48], [118, 90], [122, 130], [116, 166], [120, 196]], [[128, 46], [146, 86], [150, 124], [144, 150], [152, 180], [148, 196]], [[112, 46], [94, 86], [90, 124], [96, 150], [88, 180], [92, 196]],
                  [[134, 40], [166, 64], [180, 100], [176, 124], [184, 150], [180, 176], [184, 192]], [[106, 40], [74, 64], [60, 100], [64, 124], [56, 150], [60, 176], [56, 192]]],
      backShine: [[[96, 44], [112, 36], [130, 35], [146, 40]], [[186, 134], [190, 146], [190, 158]], [[54, 134], [50, 146], [50, 158]]]
    },
    'long-waves': {
      back: [[120, 30], [147, 33], [169, 47], [183, 72], [188, 104], [184, 124], [189, 144], [190, 166], [180, 190], [168, 214], [164, 260], [160, 300], [120, 302], [80, 300], [76, 260], [72, 214], [60, 190], [50, 166], [51, 144], [56, 124], [52, 104], [57, 72], [71, 47], [93, 33]],
      front: [[120, 23], [146, 26], [168, 37], [184, 58], [192, 84], [191, 108], [186, 124], [192, 142], [196, 162], [190, 182], [194, 204], [190, 226], [194, 248], [188, 270], [190, 290], [184, 304], [176, 310], [168, 304], [160, 309], [154, 300, 1], [157, 282], [154, 262], [158, 240], [155, 218], [159, 196], [157, 176], [161, 154], [163, 130], [160, 110], [157, 92], [149, 78], [137, 69], [125, 64], [115, 59.5, 1], [106, 63], [95, 71], [86, 85], [81, 103], [77.4, 130], [79, 154], [83, 176], [81, 196], [85, 218], [82, 240], [86, 262], [83, 282], [86, 300, 1], [80, 309], [72, 304], [64, 310], [56, 304], [50, 290], [52, 270], [46, 248], [50, 226], [46, 204], [50, 182], [44, 162], [48, 142], [54, 124], [49, 108], [48, 84], [56, 58], [72, 37], [94, 26]],
      lines: [[[115, 59.5], [116, 46], [118, 32]],
              [[118, 40], [140, 46], [160, 60], [174, 84], [180, 108], [176, 126], [182, 146], [186, 166], [180, 186], [184, 206], [180, 228], [184, 250], [178, 272], [180, 292]],
              [[124, 54], [144, 62], [158, 80], [166, 104], [170, 126], [168, 146], [172, 166], [168, 186], [172, 206], [168, 228], [172, 250], [166, 272], [168, 296]],
              [[112, 40], [92, 46], [72, 62], [62, 86], [58, 108], [64, 126], [58, 146], [54, 166], [60, 186], [56, 206], [60, 228], [56, 250], [62, 272], [60, 292]],
              [[110, 52], [94, 60], [82, 78], [74, 102], [70, 126], [72, 146], [68, 166], [72, 186], [68, 206], [72, 228], [68, 250], [74, 272], [72, 296]]],
      shine: [[[94, 40], [110, 33], [130, 32], [142, 35]], [[188, 138], [192, 150], [192, 162]], [[52, 138], [48, 150], [48, 162]], [[186, 222], [190, 234], [188, 246]], [[54, 222], [50, 234], [52, 246]]],
      backView: [[120, 23], [146, 26], [168, 37], [184, 58], [192, 84], [191, 108], [186, 124], [192, 142], [196, 162], [190, 182], [194, 204], [190, 226], [194, 248], [188, 270], [190, 292], [184, 306], [170, 312], [154, 306], [138, 312], [120, 306], [102, 312], [86, 306], [70, 312], [56, 306], [50, 292], [52, 270], [46, 248], [50, 226], [46, 204], [50, 182], [44, 162], [48, 142], [54, 124], [49, 108], [48, 84], [56, 58], [72, 37], [94, 26]],
      backLines: [[[120, 48], [118, 100], [122, 160], [116, 220], [120, 300]], [[128, 46], [146, 96], [150, 140], [144, 186], [152, 240], [146, 300]], [[112, 46], [94, 96], [90, 140], [96, 186], [88, 240], [94, 300]],
                  [[134, 40], [166, 64], [180, 100], [176, 126], [184, 160], [178, 200], [184, 240], [178, 300]], [[106, 40], [74, 64], [60, 100], [64, 126], [56, 160], [62, 200], [56, 240], [62, 300]]],
      backShine: [[[96, 44], [112, 36], [130, 35], [146, 40]], [[188, 138], [192, 150], [192, 162]], [[52, 138], [48, 150], [48, 162]]]
    },
    'long-straight': {
      back: [[120, 32], [146, 35], [166, 50], [178, 76], [183, 110], [184, 150], [184, 186], [170, 206], [166, 300], [120, 302], [74, 300], [70, 206], [56, 186], [56, 150], [57, 110], [62, 76], [74, 50], [94, 35]],
      front: [[120, 26], [146, 29], [166, 42], [180, 66], [186, 98], [187, 140], [187.5, 190], [188.5, 240], [189, 290], [188, 306, 1], [174, 307.5], [158, 306, 1], [157, 262], [157, 214], [158.5, 172], [160.5, 140], [161.5, 112], [158, 92], [149, 74], [135, 63.5], [121, 60, 1], [106, 63.5], [92, 74], [83, 92], [79, 112], [79.5, 140], [81.5, 172], [83, 214], [83, 262], [82, 306, 1], [66, 307.5], [52, 306, 1], [51, 290], [51.5, 240], [52.5, 190], [53, 140], [54, 98], [60, 66], [74, 42], [94, 29]],
      lines: [[[121, 60], [121, 30]], [[126, 44], [150, 52], [168, 76], [174, 112], [174, 180], [175, 300]], [[132, 62], [152, 76], [164, 104], [168, 150], [168, 230], [168, 300]],
              [[116, 44], [90, 52], [72, 76], [66, 112], [66, 180], [65, 300]], [[108, 62], [88, 76], [76, 104], [72, 150], [72, 230], [72, 300]],
              [[182, 190], [182, 290]], [[58, 190], [58, 290]]],
      shine: [[[96, 42], [110, 35], [130, 35]], [[180, 120], [181, 150]], [[60, 120], [59, 150]]],
      backView: [[120, 26], [146, 29], [166, 42], [180, 66], [186, 98], [187, 140], [187.5, 190], [188.5, 240], [189, 290], [188, 307, 1], [52, 307, 1], [51, 290], [51.5, 240], [52.5, 190], [53, 140], [54, 98], [60, 66], [74, 42], [94, 29]],
      backLines: [[[120, 44], [120, 300]], [[130, 44], [154, 80], [160, 150], [160, 300]], [[110, 44], [86, 80], [80, 150], [80, 300]], [[140, 46], [172, 90], [176, 300]], [[100, 46], [68, 90], [64, 300]]],
      backShine: [[[94, 46], [120, 38], [146, 46]]]
    },
    'high-bun': {
      back: [[120, 42], [150, 48], [166, 72], [169, 104], [164, 128], [120, 130], [76, 128], [71, 104], [74, 72], [90, 48]],
      bun: true,
      front: [[74.6, 109, 1], [72, 86], [80, 62], [98, 46.5], [120, 41.5], [142, 46.5], [160, 62], [168, 86], [165.4, 109, 1], [161.2, 104], [158, 90], [150, 76.5], [136, 66.5], [120, 63], [104, 66.5], [90, 76.5], [82, 90], [78.8, 104]],
      lines: [[[100, 67], [104, 56], [112, 46]], [[120, 63], [120, 52], [120, 44]], [[140, 67], [136, 56], [128, 46]], [[88, 80], [92, 64], [104, 50]], [[152, 80], [148, 64], [136, 50]], [[80, 98], [80, 80], [90, 60]], [[160, 98], [160, 80], [150, 60]]],
      shine: [[[100, 50], [116, 45.5], [134, 47]]],
      wisps: true,
      backView: [[120, 40], [146, 45], [164, 64], [170, 92], [168, 118], [158, 134], [146, 141], [132, 144], [120, 145], [108, 144], [94, 141], [82, 134], [72, 118], [70, 92], [76, 64], [94, 45]],
      backLines: [[[120, 140], [120, 100], [120, 60]], [[134, 140], [136, 100], [126, 56]], [[106, 140], [104, 100], [114, 56]], [[150, 132], [156, 100], [134, 54]], [[90, 132], [84, 100], [106, 54]]],
      backShine: [[[96, 56], [120, 48], [144, 56]]]
    },
    'curly': {
      curly: true,
      backBase: [[60, 200], [48, 182], [44, 160], [46, 134], [46, 108], [52, 82], [64, 58], [86, 40], [108, 32], [132, 32], [154, 40], [176, 58], [188, 82], [194, 108], [194, 134], [196, 160], [192, 182], [180, 200], [160, 196], [140, 198], [120, 194], [100, 198], [80, 196]],
      outer: [[58, 206], [44, 188], [39, 164], [41, 138], [40, 112], [46, 84], [60, 56], [82, 36], [107, 26], [133, 26], [158, 36], [180, 56], [194, 84], [200, 112], [199, 138], [201, 164], [196, 188], [182, 206]],
      lockR: [[182, 206], [172, 209], [162, 204]],
      innerR: [[162, 204], [163, 180], [162, 154], [163, 128], [161, 104]],
      fringe: [[161, 104], [156, 86], [144, 76], [130, 72.5], [116, 74], [102, 74.5], [90, 82], [81.5, 98]],
      innerL: [[81.5, 98], [79, 124], [79.5, 152], [78, 180], [78, 204]],
      lockL: [[78, 204], [68, 209], [58, 206]],
      curls: [[100, 40], [124, 36], [146, 44], [86, 56], [112, 52], [136, 54], [160, 58], [70, 76], [170, 80], [56, 102], [184, 104], [62, 128], [178, 130], [50, 150], [190, 152], [66, 160], [174, 162], [56, 184], [184, 186], [70, 196], [170, 196]],
      backOuter: [[58, 208], [44, 190], [39, 164], [41, 138], [40, 112], [46, 84], [60, 56], [82, 36], [107, 26], [133, 26], [158, 36], [180, 56], [194, 84], [200, 112], [199, 138], [201, 164], [196, 190], [182, 208], [160, 212], [140, 208], [120, 212], [100, 208], [80, 212]]
    },
    'ponytail': {
      back: [[120, 34], [150, 40], [170, 64], [173, 100], [167, 128], [120, 130], [73, 128], [67, 100], [70, 64], [90, 40]],
      front: [[74.4, 112, 1], [68.4, 88], [72, 60], [91.6, 40], [120, 32.6], [148.4, 40], [168, 60], [171.6, 88], [165.6, 112, 1], [161.4, 104], [159, 92], [152, 82], [140, 76.4], [126, 71.4], [112, 67.4], [102, 62.5, 1], [96, 70], [88, 80], [82.4, 92], [78.8, 105]],
      lines: [[[102, 62.5], [108, 50], [120, 41]], [[112, 67.4], [124, 54], [140, 47]], [[126, 71.4], [142, 60], [156, 58]], [[140, 76.4], [156, 70], [164, 78]], [[96, 70], [90, 56], [102, 45]], [[86, 84], [80, 68], [90, 52]]],
      shine: [[[104, 45], [122, 39.6], [142, 44]], [[150, 66], [158, 74]]],
      wisps: true,
      tail: [[136, 150], [146, 146], [157, 152], [168, 166], [178, 188], [185, 214], [188, 242], [185, 268], [179, 290], [175, 304], [168, 314], [164, 304], [159, 311], [157, 296], [160, 276], [159, 254], [155, 232], [149, 210], [143, 190], [138, 172], [134.6, 160]],
      tailShade: [[152, 176], [166, 200], [174, 228], [176, 260], [170, 290], [164, 302], [166, 276], [166, 248], [160, 222], [152, 200]],
      tailLines: [[[146, 162], [160, 186], [170, 214], [174, 246], [170, 284]], [[142, 174], [152, 198], [160, 226], [164, 260], [162, 300]], [[154, 158], [170, 182], [180, 214], [182, 250], [176, 286]]],
      backView: [[120, 36], [146, 41], [165, 60], [171, 88], [168, 118], [158, 134], [146, 141], [132, 144], [120, 145], [108, 144], [94, 141], [82, 134], [72, 118], [69, 88], [75, 60], [94, 41]],
      backLines: [[[120, 46], [120, 80], [120, 118]], [[134, 48], [134, 84], [126, 120]], [[106, 48], [106, 84], [114, 120]], [[150, 56], [156, 92], [132, 124]], [[90, 56], [84, 92], [108, 124]]],
      backShine: [[[96, 52], [120, 44], [144, 52]]],
      backTail: [[110, 126], [128, 122], [133, 134], [128, 150], [116, 168], [102, 184], [88, 196], [74, 203], [62, 200], [60, 192], [72, 182], [88, 168], [100, 154], [107, 141]]
    }
  };

  function hairBackLayer(k, style) { // behind the body, front view
    var H = hairSet(style), hr = k.hr, o = '';
    if (H.curly) {
      o += P(bumpy(H.backBase, 3.2, true), hr.s, hr.l, 1.4);
      return o;
    }
    if (H.bun) o += bun(k);
    o += P(smooth(H.back, true), hr.s, hr.l, 1.4);
    return o;
  }
  function bun(k) {
    var hr = k.hr;
    return circ(120, 30, 19.5, hr.f, hr.l, 1.5) +
      L([[106, 24], [114, 16], [126, 15], [134, 22]], hr.l, 1.1, 'opacity="0.5"') +
      L([[104, 34], [110, 42], [124, 44], [134, 36], [134, 28]], hr.l, 1.1, 'opacity="0.5"') +
      L([[110, 28], [116, 22], [126, 23], [128, 30], [120, 34]], hr.l, 1.1, 'opacity="0.5"') +
      L([[110, 18], [120, 14.5], [128, 16]], hr.h, 3, 'opacity="0.55"') +
      P(smooth([[106, 44, 1], [134, 44, 1], [132, 49], [120, 51], [108, 49]], true), hr.s, hr.l, 1.2);
  }
  function curlMarks(k, pts, s) {
    return pts.map(function (p, i) {
      var r = (s || 4) + (i % 3) * 0.6, dir = (i % 2) ? 1 : -1;
      return P('M' + f(p[0] - r) + ' ' + f(p[1]) + 'Q' + f(p[0]) + ' ' + f(p[1] - r * 1.3 * dir) + ' ' + f(p[0] + r) + ' ' + f(p[1]) +
               'Q' + f(p[0] + r * 0.4) + ' ' + f(p[1] + r * 0.7 * dir) + ' ' + f(p[0] - r * 0.1) + ' ' + f(p[1] + r * 0.2 * dir), 'none', k.hr.l, 1.05, 'opacity="0.5"');
    }).join('');
  }
  function curlyFrontD(H) {
    // one clockwise outline: outer edge, right lock end, inner right edge, fringe, inner left, left lock end
    var path = bumpy(H.outer, 3.4, false);
    var rest = [H.lockR, H.innerR, H.fringe, H.innerL, H.lockL];
    rest.forEach(function (seg) { path += bumpy(seg, 2.6, false).replace(/^M[^Q]*/, ''); });
    return path + 'Z';
  }
  function hairFrontD(H) { return H.curly ? curlyFrontD(H) : smooth(H.front, true); }
  function hairShadowOnFace(k, style) {
    var H = hairSet(style), d = hairFrontD(H), id = k.id('face');
    k.defs.push('<clipPath id="' + id + '"><path d="' + FACE_D + '"/></clipPath>');
    return '<g clip-path="url(#' + id + ')"><path d="' + d + '" transform="translate(0 3.4)" fill="' + k.sk.s + '"/></g>';
  }
  function hairFrontLayer(k, style) {
    var H = hairSet(style), hr = k.hr, o = '';
    if (H.curly) {
      o += P(curlyFrontD(H), hr.f, hr.l, 1.45);
      o += curlMarks(k, H.curls);
      o += sheen(k, [[[98, 37], [118, 31], [140, 35]], [[50, 112], [49, 126]], [[190, 112], [191, 126]]], 3.4, 0.5);
      return o;
    }
    if (H.tail) {
      // low ponytail drawn forward over the shoulder, in front of the clothes, with a soft scrunchie
      o += shape(k, smooth(H.tail, true), hr.f, hr.l, 1.45, P(smooth(H.tailShade, true), hr.s, null, null, 'opacity="0.75"'));
      o += strands(k, H.tailLines, 1.05, 0.5);
      o += sheen(k, [[[168, 190], [176, 210], [180, 232]], [[178, 252], [180, 266]]], 4, 0.55);
      o += P(smooth([[133, 153], [139, 146.6], [147, 145], [153.6, 149.4], [153, 157.6], [146, 162.6], [138.6, 162.4], [133.4, 159]], true), '#F4B4C2', '#D97F97', 1.2);
      o += L([[139.4, 147.6], [137.6, 154], [139.6, 161.2]], '#D97F97', 0.9) + L([[147.2, 146], [145.6, 153.6], [147.2, 161.6]], '#D97F97', 0.9);
    }
    o += P(smooth(H.front, true), hr.f, hr.l, 1.45);
    o += strands(k, H.lines);
    o += sheen(k, H.shine);
    if (H.wisps) {
      o += P(smooth([[82, 92, 1], [79.6, 104], [80.6, 118], [78.4, 130], [80.4, 122], [82.6, 108], [84, 96]], true), hr.f, hr.l, 1);
      o += P(smooth([[158, 92, 1], [160.4, 104], [159.4, 118], [161.6, 130], [159.6, 122], [157.4, 108], [156, 96]], true), hr.f, hr.l, 1);
    }
    return o;
  }
  function hairBackViewLayer(k, style) {
    var H = hairSet(style), hr = k.hr, o = '';
    if (H.curly) {
      o += P(bumpy(H.backOuter, 3.4, true), hr.f, hr.l, 1.45);
      o += curlMarks(k, [[96, 50], [120, 44], [144, 50], [80, 76], [106, 72], [134, 72], [160, 76], [64, 104], [92, 100], [120, 98], [148, 100], [176, 104], [58, 132], [86, 130], [114, 128], [142, 130], [182, 132], [70, 160], [100, 158], [128, 160], [158, 158], [186, 162], [62, 188], [90, 186], [120, 188], [150, 186], [178, 190]]);
      o += sheen(k, [[[98, 37], [118, 31], [140, 35]]], 3.4, 0.5);
      return o;
    }
    if (H.bun) o += bun(k);
    if (H.backTail) {
      o += P(smooth(H.backView, true), hr.f, hr.l, 1.45);
      o += strands(k, H.backLines);
      o += sheen(k, H.backShine);
      o += P(smooth(H.backTail, true), hr.f, hr.l, 1.4);
      o += L([[116, 136], [106, 156], [90, 176], [76, 190]], hr.l, 1.05, 'opacity="0.5"');
      o += P(smooth([[111, 122], [128, 120], [131, 128], [114, 131]], true), darken(hr.f, 0.5), darken(hr.f, 0.62), 1);
      return o;
    }
    o += P(smooth(H.backView, true), hr.f, hr.l, 1.45);
    o += strands(k, H.backLines);
    o += sheen(k, H.backShine);
    return o;
  }

  /* ------------------------------------------------------------------ accessories */

  function glassesLayer(k) {
    var g = k.app.glasses;
    if (g === 'none' || k.back) return '';
    var frame = g === 'round' ? '#7A5240' : '#6E3B3B', o = '';
    var lens = 'fill="#FFFFFF" fill-opacity="0.18"';
    if (g === 'round') {
      o += circ(101, 108, 12.6, '#FFFFFF', frame, 1.6, 'fill-opacity="0.16"') + circ(139, 108, 12.6, '#FFFFFF', frame, 1.6, 'fill-opacity="0.16"');
      o += L([[113.6, 106.6], [120, 103.6], [126.4, 106.6]], frame, 1.5);
      o += both(L([[88.4, 106], [81, 103.6]], frame, 1.5));
      o += both(L([[94, 101.5], [98, 98.6]], '#FFFFFF', 1.4, 'opacity="0.7"'));
    } else {
      var lensL = smooth([[84.4, 96.4, 1], [94, 99.2], [104, 99.6], [113.4, 101.2], [113, 109.6], [107, 117.2], [97, 117.8], [90.4, 112.4], [87.6, 104]], true);
      o += both(P(lensL, '#FFFFFF', frame, 1.5, 'fill-opacity="0.16"'));
      o += both(P(smooth([[83.4, 95.2, 1], [94, 97.8], [104, 98.2], [113.8, 99.8, 1], [113.4, 102.6, 1], [104, 101], [94, 100.6], [87.8, 101.4, 1]], true), frame, frame, 0.8));
      o += L([[113.4, 102], [120, 100.4], [126.6, 102]], frame, 1.6);
      o += both(L([[85.6, 101], [80.6, 102]], frame, 1.6));
      o += both(L([[94.4, 103], [98.6, 100.6]], '#FFFFFF', 1.4, 'opacity="0.7"'));
    }
    return o;
  }
  function earringsLayer(k) {
    var e = k.app.earrings;
    if (e === 'none') return '';
    var gold = '#E3B652', goldL = '#B98632', goldH = '#F7DE9A';
    if (e === 'hoops') {
      return both(circ(76, 127.8, 5.3, 'none', goldL, 3.4) + circ(76, 127.8, 5.3, 'none', gold, 2) +
        P('M72.2 125.6A4.4 4.4 0 0 1 75.2 123.2', 'none', goldH, 1, 'stroke-linecap="round"'));
    }
    return both(circ(76.4, 121.6, 2.6, '#FFF7EA', '#D9C6A5', 1) + circ(75.7, 120.9, 0.8, '#FFFFFF'));
  }

  /* ------------------------------------------------------------------ garment helpers */

  function sideStrip(e, y0, y1, w) {
    var a = [], b = [];
    for (var y = y0; y <= y1 + 0.1; y += 10) { a.push([sideX(y) - e - 4, y]); b.push([sideX(y) - e + w, y]); }
    return smooth(a.concat(b.reverse()), true);
  }
  // Left half of a top or layer panel: neckline (centre to neck side), shoulder, armhole, side, then hem.
  function panelL(e, spEx, neck, sideTo, hem, lift) {
    var sp = shoulderPt(spEx), pts = neck.slice();
    var up = lift == null ? e * 0.35 : lift;
    pts.push([90, 180.4 - up], [74, 186.6 - up], [sp[0] + 3.4, sp[1] + 1.4 - up * 0.3, 1]);
    pts.push([sp[0] + 5, 213], [sp[0] + 9.4, 229.6], [sideX(244) - e, 244]);
    for (var y = 268; y < sideTo - 6; y += 24) pts.push([sideX(y) - e, y]);
    return pts.concat(hem);
  }
  var NECK_CREW = [[120, 184], [113, 182.8], [107.8, 178.8], [104.6, 172, 1]];
  var NECK_BACK = [[120, 177.4], [110, 176.4], [104.4, 172.4, 1]];

  function sleeves(k, c, sp) {
    var ex = exFn(sp.ex), t0 = sp.t0 || 0, o = '';
    if (sp.cuff) {
      var cf = sp.cuff, cex = exFn(cf.ex);
      var cd = smooth(sleevePts(cf.t0, cf.t1, cex, cf.bulge == null ? 1.2 : cf.bulge), true);
      var cin = P(armBand(cf.t0, cf.t1, function (t) { return -armHalf(t, cex) - 2; }, function (t) { return -armHalf(t, cex) + 3.2; }), c.s);
      if (cf.rib) {
        var n = cf.rib;
        for (var j = 1; j < n; j++) {
          var fr = -1 + 2 * j / n;
          cin += L([armPt(cf.t0, armHalf(cf.t0, cex) * fr), armPt(cf.t1 - 0.03, armHalf(cf.t1, cex) * fr)], c.d, 0.9, 'opacity="0.8"');
        }
      }
      o += shape(k, cd, c.f, c.l, 1.35, cin);
    }
    var d = smooth(sleevePts(t0, sp.t1, ex, sp.end, sp.cap), true);
    var inner = P(armBand(t0 + 0.3, sp.t1, function (t) { return -armHalf(t, ex) - 2; }, function (t) { return -armHalf(t, ex) + (sp.shadeW || 5.2); }), c.s);
    if (sp.texture) inner += sp.texture;
    var det = '';
    if (sp.folds) {
      sp.folds.forEach(function (t) {
        var w = armHalf(t, ex);
        det += L([armPt(t, w - 0.8), armPt(t + 0.14, w * 0.3), armPt(t + 0.32, -w * 0.15)], c.s === c.f ? c.l : (lum(c.f) < 0.3 ? c.h : c.d), 1.05, 'opacity="0.75"');
      });
    }
    if (sp.gathers) {
      for (var g = -2; g <= 2; g++) {
        var tt = sp.t1, ww = armHalf(tt, ex) * g / 3;
        det += L([armPt(tt - 0.05, ww), armPt(tt - 0.34, ww * 1.05)], c.d, 0.9, 'opacity="0.7"');
      }
    }
    if (sp.band) det += L(armAcross(sp.t1 - sp.band, ex, (sp.end == null ? 1.6 : sp.end) * 0.8), lum(c.f) < 0.3 ? c.d : c.l, 1, 'opacity="0.8"');
    if (sp.extra) det += sp.extra;
    o += shape(k, d, c.f, c.l, 1.45, inner) + det;
    return both(o);
  }
  function lineCol(c) { return lum(c.f) < 0.3 ? c.d : c.l; }

  /* ------------------------------------------------------------------ tops */

  function topBlouse(k, c) {
    var e = 3, o = '';
    var sl = sleeves(k, c, { cap: capPt(e),
      t1: 5.42, ex: function (t) { return 3 + Math.min(t, 5) * 0.5; }, end: 2.6, folds: [3.0, 4.3], gathers: true,
      cuff: { t0: 5.25, t1: 5.95, ex: 2.3 }
    });
    var neck = k.back ? NECK_BACK : NECK_CREW;
    var pts = panelL(e, 3, neck, 300, [[68.6, 306], [71.4, 318], [79.4, 331, 1], [100, 334], [120, 334.4]]);
    var d = smooth(sym(pts), true);
    var inner = both(P(sideStrip(e, 236, 330, 7), c.s));
    o += shape(k, d, c.f, c.l, 1.45, inner);
    o += sl;
    var det = '';
    det += both(L([[76, 252], [83, 264], [88, 282]], c.s, 1.1) + L([[80, 304], [85, 313], [92, 319.4]], c.d, 1, 'opacity="0.7"') + L([[100, 308], [103, 318.4]], c.d, 1, 'opacity="0.6"') + L([[110.6, 312], [112, 319.6]], c.d, 0.95, 'opacity="0.5"'));
    if (!k.back) {
      det += L(symLine([[104.8, 176], [108, 182.4], [113.4, 186.8], [120, 188]]), c.d, 1.05);
      det += L([[117.4, 188], [118.2, 194.4]], c.d, 0.95) + L([[122.6, 188], [121.8, 194.4]], c.d, 0.95);
      det += circ(120, 189.8, 1.3, c.h, c.d, 0.8);
    } else {
      det += L([[120, 178], [120, 330]], c.s, 1, 'opacity="0.8"');
    }
    return o + det;
  }

  function ribTicks(x0, x1, y0, y1, step, col, op) {
    var s = '';
    for (var x = x0; x <= x1; x += step) s += '<line x1="' + f(x) + '" y1="' + f(y0) + '" x2="' + f(x) + '" y2="' + f(y1) + '" stroke="' + col + '" stroke-width="0.9" stroke-linecap="round" opacity="' + (op || 0.8) + '"/>';
    return s;
  }

  function topSweater(k, c) {
    var e = 5, o = '';
    var sl = sleeves(k, c, { cap: capPt(e), t1: 5.4, ex: function (t) { return 4.4 + Math.min(t, 4) * 0.3; }, end: 1.4, folds: [3.1], cuff: { t0: 5.2, t1: 5.95, ex: 3, rib: 5 } });
    var neck = k.back ? NECK_BACK : NECK_CREW;
    var pts = panelL(e, 4.4, neck, 372, [[sideX(372) - e - 0.5, 374], [64, 381, 1], [65.4, 397, 1], [92, 398.6], [120, 399.2]]);
    var d = smooth(sym(pts), true);
    var inner = both(P(sideStrip(e, 236, 400, 7.5), c.s));
    inner += ribTicks(67, 173, 382.6, 397.4, 4.2, c.d);
    if (!k.back) {
      [[104, 1], [136, -1]].forEach(function (cv) {
        var x = cv[0], s = '';
        for (var y = 196; y < 372; y += 14) s += P('M' + f(x - 3.6) + ' ' + f(y) + 'C' + f(x - 3.6) + ' ' + f(y + 6) + ' ' + f(x + 3.6) + ' ' + f(y + 7) + ' ' + f(x + 3.6) + ' ' + f(y + 14) + 'M' + f(x + 3.6) + ' ' + f(y) + 'C' + f(x + 3.6) + ' ' + f(y + 4) + ' ' + f(x + 1.4) + ' ' + f(y + 5.6) + ' ' + f(x + 0.6) + ' ' + f(y + 6.4) + 'M' + f(x - 0.6) + ' ' + f(y + 7.6) + 'C' + f(x - 1.4) + ' ' + f(y + 8.4) + ' ' + f(x - 3.6) + ' ' + f(y + 10) + ' ' + f(x - 3.6) + ' ' + f(y + 14), 'none', c.d, 1);
        inner += s + L([[x - 7.5, 196], [x - 7.5, 374]], c.d, 0.9, 'stroke-dasharray="0.1 3.4" opacity="0.9"') + L([[x + 7.5, 196], [x + 7.5, 374]], c.d, 0.9, 'stroke-dasharray="0.1 3.4" opacity="0.9"');
      });
      inner += L([[120, 194], [120, 374]], c.d, 0.9, 'stroke-dasharray="0.1 3.4" opacity="0.9"');
    }
    o += shape(k, d, c.f, c.l, 1.45, inner);
    o += sl;
    var det = L(symLine([[64.4, 381.2], [92, 382.8], [120, 383.4]]), c.l, 1.1);
    if (!k.back) {
      var band = smooth(sym([[120, 184], [113, 182.8], [107.8, 178.8], [104.6, 172, 1], [101, 175], [104, 183.6], [111.4, 189.2], [120, 190.4]]), true);
      det += P(band, c.f, c.l, 1.3) + ribTicks(106, 134, 186, 191, 3, c.d, 0.0);
      for (var i = 0; i <= 8; i++) {
        var u = i / 8, a = Math.PI * (0.06 + 0.88 * u);
        var cx = 120 - Math.cos(a) * 15.6, cy = 176.6 + Math.sin(a) * 9.6, ox = 120 - Math.cos(a) * 19.4, oy = 176.6 + Math.sin(a) * 13.6;
        det += L([[cx, cy], [ox, oy]], c.d, 0.85, 'opacity="0.8"');
      }
    } else {
      det += L(symLine([[103, 175.4], [110, 179.6], [120, 180.4]]), c.l, 1.1);
    }
    return o + det;
  }

  function lacePattern(c, x0, x1, y0, y1) {
    var s = '', row = 0;
    for (var y = y0; y <= y1; y += 9, row++) {
      for (var x = x0 + (row % 2) * 5; x <= x1; x += 10) {
        s += circ(x, y, 2, 'none', c.p, 0.8) + circ(x, y, 0.7, c.p);
      }
    }
    return s;
  }
  function topLace(k, c) {
    var e = 2.6, o = '';
    var sl = sleeves(k, c, { cap: capPt(e), t1: 2.85, ex: function (t) { return 3.6 + t * 0.3; }, end: { scallop: 4, amp: 2.6 }, texture: lacePattern(c, 20, 100, 190, 330), folds: [1.4] });
    var neck = k.back ? NECK_BACK : NECK_CREW;
    var pts = panelL(e, 3.6, neck, 300, [[69.4, 306], [72.4, 318], [79.4, 331, 1], [100, 334], [120, 334.4]]);
    var d = smooth(sym(pts), true);
    var inner = lacePattern(c, 50, 190, 198, 336) + both(P(sideStrip(e, 236, 330, 6), c.s, null, null, 'opacity="0.8"'));
    o += shape(k, d, c.f, c.l, 1.45, inner);
    o += sl;
    var det = both(L([[76, 252], [83, 264], [88, 282]], c.d, 1.05));
    if (!k.back) {
      // scalloped lace collar along the neckline
      var trim = [[104.6, 172], [107.8, 178.8], [113, 182.8], [120, 184], [127, 182.8], [132.2, 178.8], [135.4, 172]];
      var under = [[138.2, 175.4], [136, 183.4], [130, 189.4], [120, 191.2], [110, 189.4], [104, 183.4], [101.8, 175.4]];
      var dd = smooth(trim, false) + bumpy([[135.4, 172]].concat(under, [[104.6, 172]]), 1.5, false).replace(/^M[^Q]*/, '') + 'Z';
      det += P(dd, c.f, c.l, 1.2);
      det += L(symLine([[106, 177], [109.6, 182.6], [114.6, 186], [120, 187]]), c.d, 0.9, 'stroke-dasharray="0.1 2.6"');
    }
    return o + det;
  }

  function topBrick(k, c) {
    var e = 3.6, o = '';
    var rib = '';
    for (var x = 30; x < 210; x += 5.2) rib += '<line x1="' + f(x) + '" y1="160" x2="' + f(x) + '" y2="400" stroke="' + c.d + '" stroke-width="0.9" opacity="0.35"/>';
    var sl = sleeves(k, c, { cap: capPt(e), t1: 5.4, ex: function (t) { return 3.8 + Math.min(t, 4) * 0.25; }, end: 1.4, folds: [3.1], cuff: { t0: 5.2, t1: 5.95, ex: 2.6, rib: 5 } });
    var neck = k.back ? NECK_BACK : [[120, 214, 1], [113, 198], [107.4, 184], [104.4, 173.2, 1]];
    var pts = panelL(e, 3.8, neck, 366, [[sideX(366) - e, 368], [65.4, 375, 1], [66.4, 390, 1], [92, 391.4], [120, 392]]);
    var d = smooth(sym(pts), true);
    var inner = rib + both(P(sideStrip(e, 236, 392, 7), c.s)) + ribTicks(68, 172, 376.6, 390, 3.4, c.s, 1);
    o += shape(k, d, c.f, c.l, 1.45, inner);
    o += sl;
    var det = L(symLine([[65.6, 375.4], [92, 376.8], [120, 377.4]]), c.l, 1.1);
    if (!k.back) {
      var vb = smooth([[104.4, 173.2, 1], [107.4, 184], [113, 198], [120, 214, 1], [127, 198], [132.6, 184], [135.6, 173.2, 1], [139, 175.4], [135.6, 188], [128.4, 206], [120, 222, 1], [111.6, 206], [104.4, 188], [101, 175.4]], true);
      det += P(vb, c.f, c.l, 1.25);
      det += L([[120, 214], [120, 222]], c.l, 1);
      for (var i = 0; i < 7; i++) {
        var u = (i + 0.5) / 7;
        det += L([[104.4 + (120 - 104.4) * u, 173.2 + (214 - 173.2) * u + (u < 0.3 ? 0 : 0)], [101 + (120 - 101) * u, 175.4 + (222 - 175.4) * u]], c.d, 0.85, 'opacity="0.9"');
        det += L([[135.6 - (135.6 - 120) * u, 173.2 + (214 - 173.2) * u], [139 - (139 - 120) * u, 175.4 + (222 - 175.4) * u]], c.d, 0.85, 'opacity="0.9"');
      }
    } else {
      det += L(symLine([[103, 175.4], [110, 179.6], [120, 180.4]]), c.l, 1.1);
    }
    return o + det;
  }

  function topTee(k, c) {
    var e = 2.6, o = '';
    var sl = sleeves(k, c, { cap: capPt(e), t1: 1.4, ex: function (t) { return 4.6 + t * 0.6; }, end: 1.2, band: 0.2, folds: [0.55] });
    var neck = k.back ? NECK_BACK : NECK_CREW;
    var pts = panelL(e, 4.6, neck, 300, [[69.4, 306], [72.4, 318], [79.4, 331, 1], [100, 334], [120, 334.4]]);
    var d = smooth(sym(pts), true);
    var inner = both(P(sideStrip(e, 236, 330, 7), c.s));
    o += shape(k, d, c.f, c.l, 1.45, inner);
    o += sl;
    var det = both(L([[76, 252], [83, 264], [88, 282]], c.h, 1.05, 'opacity="0.8"') + L([[86, 306], [90, 314], [96, 318.6]], c.h, 1, 'opacity="0.7"'));
    if (!k.back) {
      var band = smooth(sym([[120, 184], [113, 182.8], [107.8, 178.8], [104.6, 172, 1], [101.4, 174.6], [104.6, 182.6], [111.6, 187.8], [120, 189]]), true);
      det += P(band, c.f, c.l, 1.25) + L(symLine([[103, 174.2], [106.4, 181.6], [112.4, 186.2], [120, 187.4]]), c.d, 0.8, 'stroke-dasharray="0.1 2.2"');
    } else {
      det += L(symLine([[103, 175.4], [110, 179.6], [120, 180.4]]), c.d, 1.1);
    }
    return o + det;
  }

  /* ------------------------------------------------------------------ dress */

  var FLOWERS = [[96, 214], [140, 206], [112, 240], [84, 262], [150, 252], [128, 276], [98, 296], [146, 300], [86, 344], [118, 352], [154, 340],
                 [72, 392], [102, 386], [136, 384], [166, 396], [86, 428], [120, 420], [152, 432], [64, 470], [98, 462], [132, 458], [176, 470],
                 [80, 504], [114, 498], [148, 506], [58, 542], [94, 538], [130, 544], [166, 540], [74, 578], [108, 574], [142, 580], [180, 576],
                 [38, 230], [52, 262], [202, 230], [188, 262]];
  function flowers(c, list) {
    return list.map(function (p, i) {
      var x = p[0], y = p[1], col = (i % 3 === 1) ? c.fp : c.fl, s = '';
      s += '<ellipse cx="' + f(x + 4.4) + '" cy="' + f(y + 2.6) + '" rx="2.6" ry="1.2" fill="' + c.lf + '" transform="rotate(' + ((i * 47) % 90 - 30) + ' ' + f(x + 4.4) + ' ' + f(y + 2.6) + ')"/>';
      for (var j = 0; j < 5; j++) {
        var a = j * 72 * Math.PI / 180 + i;
        s += circ(x + Math.cos(a) * 2.1, y + Math.sin(a) * 2.1, 1.55, col);
      }
      return s + circ(x, y, 1.1, c.fc);
    }).join('');
  }
  function dressBlue(k, c) {
    var o = '', e = 2.6;
    var sleeveFl = flowers(c, [[38, 214], [52, 236], [44, 252], [200, 214], [188, 236], [196, 252]]);
    var sl = sleeves(k, c, { cap: capPt(e), t1: 1.35, ex: function (t) { return 5 + Math.sin(Math.min(t, 1.35) / 1.35 * Math.PI) * 2.2; }, end: 1.6, band: 0.22, texture: sleeveFl });
    var neck = k.back ? NECK_BACK : [[120, 214, 1], [113, 199], [107.6, 185], [104.4, 173.2, 1]];
    var pts = panelL(e, 5, neck, 300, [[sideX(316) - 2.4, 316], [76.4, 326], [70, 346], [62, 382], [56, 440], [50, 520], [43, 592, 1],
                                         [54.6, 597.4], [70, 595], [86, 600], [104, 597], [120, 600.6]]);
    var d = smooth(sym(pts), true);
    var inner = flowers(c, FLOWERS) + both(P(sideStrip(2.6, 236, 322, 6.4), c.s, null, null, 'opacity="0.9"'));
    inner += both(P(smooth([[70, 346], [62, 382], [56, 440], [50, 520], [43, 600], [56, 600], [62, 520], [68, 440], [73, 382], [78, 346]], true), c.s, null, null, 'opacity="0.8"'));
    inner += both(P(smooth([[96, 352], [94, 450], [88, 600], [100, 600], [101, 450], [100, 352]], true), c.s, null, null, 'opacity="0.55"'));
    o += shape(k, d, c.f, c.l, 1.45, inner);
    o += sl;
    var det = '';
    det += both(L([[90, 344], [86, 420], [78, 520], [72, 594]], c.d, 1.05, 'opacity="0.8"') + L([[108, 348], [107, 450], [106, 596]], c.d, 1, 'opacity="0.6"'));
    det += P(smooth([[76.6, 318.6], [120, 320.6], [163.4, 318.6], [163.6, 327.2], [120, 329.2], [76.4, 327.2]], true), c.h, c.l, 1.2);
    if (!k.back) {
      det += P(smooth([[120, 324.6], [113.6, 320.4], [111, 324.8], [113.6, 329.2]], true), c.h, c.l, 1.1) + P(smooth([[120, 324.6], [126.4, 320.4], [129, 324.8], [126.4, 329.2]], true), c.h, c.l, 1.1);
      det += L([[118.4, 327], [115.4, 340]], c.l, 1.1) + L([[121.6, 327], [125, 338]], c.l, 1.1) + circ(120, 324.8, 2, c.h, c.l, 1.1);
      det += L(symLine([[106.8, 178], [110.6, 188], [115.6, 200], [120, 210]]), c.d, 1, 'opacity="0.9"');
    } else {
      det += L([[120, 178], [120, 318]], c.d, 1, 'opacity="0.8"') + L(symLine([[103, 175.4], [110, 179.6], [120, 180.4]]), c.d, 1.05);
    }
    return o + det;
  }

  /* ------------------------------------------------------------------ bottoms */

  function waistband(k, b) {
    var c = b.c, id = b.id, o = '';
    var d = smooth([[77, 322.6, 1], [120, 324], [163, 322.6, 1], [163.6, 338.8, 1], [120, 340.4], [76.4, 338.8, 1]], true);
    o += P(d, c.f, c.l, 1.4);
    o += L([[78, 325], [120, 326.6], [162, 325]], lum(c.f) < 0.3 ? c.h : c.s, 1, 'opacity="0.7"');
    if (id === 'g-black-skirt') {
      o += L([[k.back ? 120 : 156, 323.6], [k.back ? 120 : 156, 341]], c.d, 1, 'opacity="0.8"');
      return o;
    }
    var loops = [87, 105, 135, 153];
    loops.forEach(function (x) { o += P('M' + f(x - 1.3) + ' 322h2.6v17.2h-2.6Z', lum(c.f) < 0.3 ? c.h : c.f, c.l, 0.9); });
    if (id === 'g-wide-jeans') o += L([[78, 336.6], [120, 338.2], [162.2, 336.6]], c.t, 0.9, 'stroke-dasharray="1.6 1.8"') + L([[78, 325.4], [120, 327], [162, 325.4]], c.t, 0.9, 'stroke-dasharray="1.6 1.8"');
    if (!k.back) {
      var btn = c.b || c.d;
      o += circ(120, 331.6, 2.5, btn, c.l, 1) + circ(119.3, 330.9, 0.8, lighten(btn, 0.5));
    }
    return o;
  }
  function trouserPts(spec) {
    return [[120, 337, 1], [77.6, 337, 1], [71, 358], [62.6, 390]].concat(spec.out, spec.hem, spec.inn, [[120, spec.crotch, 1]]);
  }
  function bottomTrousers(k, b) {
    var c = b.c, id = b.id, o = '', det = '', inner = '';
    var spec;
    if (id === 'g-wide-jeans') {
      spec = { out: [[57, 430], [53, 560], [49.4, 700], [45.6, 836, 1]], hem: [[82, 838.4]], inn: [[117.4, 836, 1], [118.6, 700], [119.6, 540]], crotch: 472 };
    } else if (id === 'g-olive-trousers') {
      spec = { out: [[59, 440], [60.6, 540], [64.6, 640], [69.6, 740], [72.4, 812, 1]], hem: [[88, 813.6]], inn: [[103.6, 812, 1], [105.6, 740], [109, 640], [113.6, 540], [118.4, 482]], crotch: 468 };
    } else {
      spec = { out: [[58, 430], [56, 520], [54, 640], [52.6, 760], [51.2, 834, 1]], hem: [[84, 836.2]], inn: [[115.6, 834, 1], [116.6, 700], [118, 560], [119.4, 482]], crotch: 470 };
    }
    var pts = trouserPts(spec), d = smooth(sym(pts), true);
    var hemY = spec.out[spec.out.length - 1][1], innX = spec.inn[0][0], outX = spec.out[spec.out.length - 1][0];
    // shading: inside of each leg and the outer side
    var ci = spec.inn[spec.inn.length - 1];
    inner += both(P(smooth([[ci[0] + 1, spec.crotch + 6, 1], [ci[0] + 1, 540], [innX + 1, hemY + 4, 1], [innX - 7.4, hemY + 4, 1], [ci[0] - 5.6, 560], [ci[0] - 1.6, 500]], true), c.s));
    inner += both(P(smooth([[60, 380], [spec.out[0][0] - 2, spec.out[0][1]], [outX - 2, hemY + 4], [outX + 5.4, hemY + 4], [spec.out[0][0] + 6, spec.out[0][1]], [68, 384]], true), c.s, null, null, 'opacity="0.8"'));
    var mid = (outX + innX) / 2;
    if (!k.back) {
      if (id === 'g-wide-jeans') {
        inner += both(L([[75.6, 344], [86, 350], [96, 352.4]], c.t, 0.9, 'stroke-dasharray="1.6 1.8"') + L([[74.6, 343.4], [86, 348.4], [97.4, 350]], c.l, 1.1));
        inner += both(L([[mid + 2, 380], [mid, 600], [mid - 1.6, 830]], c.h, 1.1, 'opacity="0.55"'));
        inner += both(L([[outX + 2.6, hemY - 6], [innX - 2.6, hemY - 6]], c.t, 0.9, 'stroke-dasharray="1.6 1.8"'));
        inner += L([[125.6, 341], [125.6, 380], [121.6, 390]], c.t, 0.9, 'stroke-dasharray="1.6 1.8"') + L([[120, 341], [120, 392]], c.l, 1.05);
        inner += both(circ(97, 351.6, 1.1, c.b, c.l, 0.6) + circ(75.6, 343.8, 1.1, c.b, c.l, 0.6));
        inner += P('M139 344h9.6l-0.4 8.4q-4.4 1.6-8.8 0Z', 'none', c.t, 0.9, 'stroke-dasharray="1.4 1.6"');
      } else {
        inner += both(L([[78.6, 341.4], [80.6, 356], [86.6, 372]], c.l, 1.1));
        inner += both(L([[100, 342], [99.4, 372]], lineCol(c), 1.05) + L([[mid + 1, 352], [mid, 600], [mid - 0.6, hemY - 2]], c.h, 1.05, 'opacity="0.75"'));
        inner += L([[124.6, 342], [124.6, 382], [120.6, 391]], lineCol(c), 1.05) + L([[120, 341], [120, 392]], c.l, 1.05);
      }
    } else {
      inner += L([[120, 341], [120, spec.crotch]], c.l, 1.1);
      if (id === 'g-wide-jeans') {
        inner += both(P('M84 356l20 -1.2 0.4 22q-10 6 -20.4 0.8Z', 'none', c.t, 0.9, 'stroke-dasharray="1.6 1.8"') + P('M83 354l22.4 -1.4 0.4 24q-11.2 6.6 -22.6 0.8Z', 'none', c.l, 1.1));
        inner += both(L([[outX + 2.6, hemY - 6], [innX - 2.6, hemY - 6]], c.t, 0.9, 'stroke-dasharray="1.6 1.8"'));
      } else {
        inner += both(L([[88, 356], [104, 355.4]], lineCol(c), 1.1) + L([[mid, 380], [mid - 0.6, hemY - 2]], c.h, 1, 'opacity="0.6"'));
      }
    }
    o += shape(k, d, c.f, c.l, 1.45, inner);
    if (id === 'g-olive-trousers') {
      var cuff = smooth([[71.4, 798, 1], [88, 799.6], [104.8, 798, 1], [104, 815.6, 1], [88, 817.2], [72.6, 815.6, 1]], true);
      det += both(P(cuff, c.f, c.l, 1.3) + L([[72.2, 806.6], [88, 808], [104.4, 806.6]], c.s, 1));
    }
    return o + det;
  }
  function bottomSkirt(k, b) {
    var c = b.c, o = '';
    var pts = [[120, 337, 1], [77.6, 337, 1], [70.4, 360], [61.4, 398], [54.4, 456], [47.6, 540], [42.6, 620], [39.6, 684, 1],
               [50.6, 690.4], [62, 686.6], [76, 692.6], [92, 688.6], [106, 693.6], [120, 690.4]];
    var d = smooth(sym(pts), true);
    var inner = '';
    inner += both(P(smooth([[62, 520], [60, 600], [56, 694], [70, 694], [68, 600], [66, 520]], true), c.s));
    inner += both(P(smooth([[92, 470], [90, 600], [86, 694], [100, 694], [98, 600], [94, 470]], true), c.s));
    inner += P(smooth([[118, 500], [118, 600], [114, 696], [126, 696], [122, 600], [122, 500]], true), c.s);
    inner += both(L([[84, 380], [78, 500], [70, 600], [64, 688]], c.h, 1.05, 'opacity="0.8"') + L([[104, 400], [102, 520], [99, 690]], c.h, 1, 'opacity="0.65"'));
    if (k.back) inner += L([[120, 341], [120, 440]], c.d, 1, 'opacity="0.8"');
    o += shape(k, d, c.f, c.l, 1.45, inner);
    return o;
  }
  function bottomLayer(k, b) {
    if (!b) return '';
    var body = b.id === 'g-black-skirt' ? bottomSkirt(k, b) : bottomTrousers(k, b);
    return body + waistband(k, b);
  }

  /* ------------------------------------------------------------------ shoes */
  // Left foot; the right foot mirrors. The foot points slightly outward, toe at the lower left.

  function shoeLayer(k, s) {
    return both('<g transform="' + FOOT_T + '">' + shoeLeft(k, s) + '</g>');
  }
  function shoeLeft(k, s) {
    var c = s.c, id = s.id, o = '', back = k.back;
    if (id === 'g-white-sneakers') {
      var body = smooth([[79, 838.6, 1], [75.4, 845.6], [69.6, 851.6], [64.8, 856.2], [63.2, 861.2], [65.8, 865.4, 1], [96.8, 865.4, 1], [99.4, 862], [99.4, 853], [97.6, 845], [95, 838.2, 1], [90.6, 840], [86, 840.8], [81.6, 840]], true);
      var sole = smooth([[63.8, 858.6, 1], [99.4, 858.6, 1], [99.4, 862], [96.8, 865.4, 1], [65.8, 865.4, 1], [63.2, 861.2]], true);
      o += shape(k, body, c.f, c.l, 1.4, P(sole, c.sole) + L([[63.8, 858.6], [99.4, 858.6]], c.l, 1) + P(smooth([[90, 838], [99.6, 838], [99.6, 852], [93, 852]], true), c.s, null, null, 'opacity="0.8"'));
      o += L([[64.8, 862.2], [98, 862.2]], c.d, 0.8, 'stroke-dasharray="1.2 1.6"');
      if (!back) {
        o += L([[64.6, 856], [69.4, 852.6], [74.6, 854.4], [76.2, 858.4]], c.d, 1);
        o += P(smooth([[81.6, 840.2], [90.6, 840.2], [90.2, 847], [82, 846.2]], true), c.h, c.d, 0.9);
        [[0, 0], [3.6, 3.2], [7.2, 6.4]].forEach(function (q) {
          o += L([[79.4 - q[0], 843.4 + q[1]], [90.4 - q[0] * 0.7, 845.2 + q[1]]], c.d, 1.1);
          o += circ(79 - q[0], 843.6 + q[1], 0.8, c.l) + circ(90.6 - q[0] * 0.7, 845.4 + q[1], 0.8, c.l);
        });
        o += P(smooth([[96.2, 836.2, 1], [99.6, 836.6], [99.6, 844], [96.6, 843.4]], true), c.tab, darken(c.tab, 0.3), 0.9);
      } else {
        o += P(smooth([[83, 836.4, 1], [91, 836.4, 1], [90.4, 846], [83.6, 846]], true), c.tab, darken(c.tab, 0.3), 0.9);
        o += L([[81, 848], [87, 849.4], [93, 848]], c.d, 1);
      }
      return o;
    }
    if (id === 'g-tan-loafers') {
      var lb = smooth([[80, 846, 1], [74.6, 849.8], [69, 854.4], [65.2, 858.8], [65.4, 863], [69, 865.2, 1], [95.6, 865.2, 1], [98.6, 862], [98.2, 855], [95.8, 848.6], [93.2, 845.8, 1], [89, 848.6], [84.4, 849.2]], true);
      var ls = smooth([[65.4, 862.4, 1], [98.4, 861.4, 1], [98.2, 865.6, 1], [69, 865.6, 1], [65.2, 864]], true);
      o += shape(k, lb, c.f, c.l, 1.4, P(ls, c.sole) + P(smooth([[88, 846], [99, 846], [99, 862], [93, 862]], true), c.s, null, null, 'opacity="0.8"'));
      if (!back) {
        o += L([[70.2, 855.6], [66.8, 859.4], [69.2, 861.8], [74.4, 860.6], [78.6, 857.4]], c.d, 1);
        o += P(smooth([[73.2, 851.8, 1], [80.4, 849.4], [88.6, 850.8], [93.6, 850.6, 1], [94, 854.6, 1], [88.4, 855], [80.8, 853.6], [74.6, 855.8, 1]], true), c.s, c.l, 1.1);
        o += P(smooth([[80.8, 851.6, 1], [86.6, 852], [86.4, 853.4, 1], [80.6, 853]], true), c.l);
      } else {
        o += P(smooth([[81, 856, 1], [94, 856, 1], [94, 865.4, 1], [81, 865.4, 1]], true), c.sole, c.l, 1);
      }
      return o;
    }
    if (id === 'g-black-heels') {
      var heel = smooth([[91.6, 855, 1], [98.8, 855, 1], [98.4, 865.4, 1], [92.6, 865.4, 1]], true);
      o += P(heel, c.s, c.l, 1.3) + L([[92.6, 862.4], [98.6, 862.4]], c.d, 0.9);
      var hb = smooth([[79.8, 849.4, 1], [74.6, 852.4], [69.4, 856], [64.8, 860.4], [63.6, 864, 1], [86, 864.4], [93.6, 861], [97.8, 857.6], [97.2, 852.4], [95.2, 849.2, 1], [90.6, 853.2], [85, 854.4]], true);
      o += shape(k, hb, c.f, c.l, 1.4, P(smooth([[90, 848], [99, 848], [99, 860], [92, 860]], true), c.s));
      if (!back) {
        o += L([[67.6, 859.4], [72.4, 856.2], [76.6, 855]], c.h, 1.4, 'opacity="0.8"');
        o += L([[79.8, 850.8], [85, 855.6], [90.6, 854.6], [95, 850.6]], c.d, 0.9, 'opacity="0.8"');
      } else {
        o += P(smooth([[81, 850, 1], [93.6, 850, 1], [92, 858], [83, 858]], true), c.s, c.l, 1);
      }
      return o;
    }
    // nude pointed flats (default)
    var fb = smooth([[79.2, 850.4, 1], [74, 853.2], [68.6, 856.6], [64.6, 860.4], [65.6, 864.4], [69.8, 865.2, 1], [95.2, 865.2, 1], [98.4, 862.2], [97.8, 856.4], [95.6, 851.6, 1], [91, 855.4], [85.4, 856.4]], true);
    o += shape(k, fb, c.f, c.l, 1.4, P(smooth([[66, 862.6, 1], [98.6, 862.6, 1], [98.6, 866, 1], [66, 866, 1]], true), c.s) + P(smooth([[90, 850], [99, 850], [99, 862], [93, 862]], true), c.s, null, null, 'opacity="0.7"'));
    o += L([[67.2, 862.6], [97.8, 862.6]], c.d, 0.9);
    if (!back) {
      o += P('M84.6 856.8C81.4 853.6 79.2 855.4 80.8 857.8C81.8 859.2 83.6 857.8 84.6 856.8Z', c.h, c.d, 0.9);
      o += P('M84.6 856.8C87.8 853.6 90 855.4 88.4 857.8C87.4 859.2 85.6 857.8 84.6 856.8Z', c.h, c.d, 0.9);
      o += L([[84, 857.4], [82.6, 860.4]], c.d, 0.8) + L([[85.2, 857.4], [86.8, 860.2]], c.d, 0.8) + circ(84.6, 857, 1.2, c.f, c.d, 0.8);
    } else {
      o += L([[81, 856.6], [87, 858], [93, 856.6]], c.d, 0.9);
    }
    return o;
  }

  /* ------------------------------------------------------------------ layers */

  function layerBlazer(k, l) {
    var c = l.c, o = '', e = 6.4, ex = function (t) { return 5.4 + Math.min(t, 4) * 0.12; };
    var cuffBtns = '';
    [5.2, 5.38].forEach(function (t) { var p = armPt(t, armHalf(t, ex) - 3.2); cuffBtns += circ(p[0], p[1], 1.1, c.b, c.bl, 0.6); });
    var sl = sleeves(k, c, { cap: [67.4, 185.4], t1: 5.62, ex: ex, end: 1.4, folds: [3.1], band: 0.5, extra: cuffBtns });
    var sp = shoulderPt(5.4);
    var side = [];
    for (var y = 268; y <= 410; y += 24) side.push([sideX(y) - e, y]);
    var common = [[103, 168.6, 1], [88, 176.6], [68, 185], [sp[0] + 3.4, sp[1] + 0.4, 1], [sp[0] + 5, 212], [sp[0] + 9.4, 230], [sideX(244) - e, 244]].concat(side, [[54.6, 428, 1], [78, 431.8], [100, 432.6]]);
    var inner = P(sideStrip(e, 236, 432, 7.5), c.s);
    if (k.back) {
      var bd = smooth(sym([[120, 170, 1], [112, 169.6], [103, 168.6, 1]].concat(common.slice(1), [[120, 433]])), true);
      o += shape(k, bd, c.f, c.l, 1.45, both(inner) + L([[120, 172], [120, 433]], c.d, 1.05));
      o += sl;
      o += L([[120, 400], [120, 433]], c.l, 1.1);
      o += P(smooth(sym([[120, 166.6], [110, 165.8], [103.6, 163.6, 1], [101.6, 169.4], [106, 175.4], [120, 176.6]]), true), c.f, c.l, 1.2);
      return o;
    }
    // two front panels: the viewer-left panel laps over at the buttons
    var front = [[106, 432], [114.6, 418], [119.6, 398], [122.4, 372], [122.6, 336, 1], [118.6, 300], [112.4, 258], [106.6, 214], [104, 186]];
    var pL = smooth(common.concat(front), true);
    var pR = smooth(mir(common.concat(front.map(function (p) { return [p[0] - 5, p[1], p[2]]; }))), true);
    o += shape(k, pR, c.f, c.l, 1.45, MIR(inner));
    o += shape(k, pL, c.f, c.l, 1.45, inner);
    o += sl;
    // collar and lapels
    var collar = [[87.4, 204, 1], [84.4, 195], [88.8, 183], [99, 172.6], [106.8, 165, 1], [107.2, 173.6], [101.6, 181.6], [95.6, 192.6], [93.4, 205.6, 1]];
    var lapel = [[103.6, 170.4, 1], [99.6, 178], [92.6, 191.6, 1], [85.4, 205.6, 1], [93, 209.6, 1], [101, 236], [110, 282], [121.6, 334, 1], [117.6, 300], [111.4, 258], [105.8, 214], [103.4, 186]];
    var lapR = mir(lapel.map(function (p) { return [p[0] + (p[1] > 300 ? 3.6 : 0), p[1], p[2]]; }));
    o += P(smooth(mir(collar), true), c.f, c.l, 1.25) + shape(k, smooth(lapR, true), c.f, c.l, 1.3, P(smooth(mir([[94, 209.6], [101.4, 236], [110.4, 282], [118, 322], [113.6, 290], [107, 250], [99.4, 214]]), true), c.s));
    o += P(smooth(collar, true), c.f, c.l, 1.25) + shape(k, smooth(lapel, true), c.f, c.l, 1.3, P(smooth([[94, 209.6], [101.4, 236], [110.4, 282], [118, 322], [113.6, 290], [107, 250], [99.4, 214]], true), c.s));
    // buttons, pockets, welt
    o += circ(119.4, 340, 2.6, c.b, c.bl, 1) + circ(118.8, 339.4, 0.8, lighten(c.b, 0.4));
    o += circ(119.4, 374, 2.6, c.b, c.bl, 1) + circ(118.8, 373.4, 0.8, lighten(c.b, 0.4));
    o += P('M66.4 386.6L92.4 384.2L92.8 392.4L67.4 394.8Z', c.f, c.l, 1.15) + P('M147.6 384.2L173.6 386.6L172.6 394.8L147.2 392.4Z', c.f, c.l, 1.15);
    o += P('M132 266.4L149 264.6L149.4 269.4L132.4 271.2Z', c.f, c.l, 1.05);
    o += L([[86, 248], [84.6, 300], [88, 336]], c.d, 1, 'opacity="0.7"') + L([[154, 248], [155.4, 300], [152, 336]], c.d, 1, 'opacity="0.7"');
    return o;
  }

  function layerCardigan(k, l) {
    var c = l.c, o = '', e = 5.6, ex = function (t) { return 5 + Math.min(t, 4) * 0.2; };
    var sl = sleeves(k, c, { cap: [67.4, 187.8], t1: 5.4, ex: ex, end: 1.2, folds: [3.1], cuff: { t0: 5.2, t1: 5.96, ex: 3.4, rib: 5 } });
    var sp = shoulderPt(5);
    var side = [];
    for (var y = 268; y <= 392; y += 24) side.push([sideX(y) - e, y]);
    var common = [[104, 171.4, 1], [90, 178.6], [73, 185.6], [sp[0] + 3.4, sp[1] + 0.6, 1], [sp[0] + 5, 212.6], [sp[0] + 9.4, 229.6], [sideX(244) - e, 244]].concat(side, [[sideX(398) - e, 398], [57.4, 400, 1], [58.4, 415, 1], [80, 416.2], [99.6, 416.4, 1]]);
    var inner = P(sideStrip(e, 236, 416, 7.5), c.s) + ribTicks(60, 99, 402, 414.6, 3.4, c.d, 0.85);
    if (k.back) {
      var bd = smooth(sym([[120, 174, 1], [112, 173.4], [104, 171.4, 1]].concat(common.slice(1, -1), [[120, 416.6]])), true);
      var bi = both(inner) + ribTicks(60, 180, 402, 414.6, 3.4, c.d, 0.85);
      o += shape(k, bd, c.f, c.l, 1.45, bi);
      o += sl;
      o += L(symLine([[57.6, 401], [90, 402.4], [120, 402.6]]), c.l, 1.1);
      o += P(smooth(sym([[120, 170], [110, 169.2], [103.6, 166.6, 1], [101, 172.4], [106, 178.6], [120, 179.6]]), true), c.f, c.l, 1.2);
      return o;
    }
    var front = [[100, 330], [101.6, 260], [103.6, 200]];
    var pts = common.concat(front);
    var band = smooth([[99.6, 416.4, 1], [93.6, 416.4, 1], [94, 330], [95.6, 260], [97.8, 200], [98.8, 172.6, 1], [104, 171.4, 1], [103.6, 200], [101.6, 260], [100, 330]], true);
    var panel = shape(k, smooth(pts, true), c.f, c.l, 1.45, inner) + P(band, c.f, c.l, 1.2) + L([[96.8, 416], [97.2, 330], [98.8, 260], [100.8, 200], [101.4, 174]], c.d, 0.9, 'opacity="0.8"');
    panel += L([[57.6, 401], [80, 402.2], [99.4, 402.4]], c.l, 1.1);
    panel += P('M70 356h22l-0.4 26.6q-10.6 2.4 -21.2 0Z', c.f, c.l, 1.15) + P('M70 356h22v5.4h-22Z', c.f, c.l, 1) + ribTicks(72.4, 90, 357.2, 360.4, 2.8, c.d, 0.8);
    o += panel + MIR(panel);
    o += sl;
    [222, 262, 302, 342, 382].forEach(function (y) {
      var x = y < 260 ? 99.6 : 97.6;
      o += circ(x - 0.6, y, 2.2, c.b, c.bl, 0.9) + circ(x - 1.2, y - 0.6, 0.6, lighten(c.b, 0.5));
      o += L([[240 - x - 1.6, y], [240 - x + 1.6, y]], c.d, 1);
    });
    return o;
  }

  function layerTrench(k, l) {
    var c = l.c, o = '', e = 7.6, ex = function (t) { return 5.8 + Math.min(t, 4) * 0.15; };
    var strap = '';
    var sa = armPt(5.0, armHalf(5.0, ex)), sb = armPt(5.0, -armHalf(5.0, ex)), sc = armPt(5.24, -armHalf(5.24, ex)), sd = armPt(5.24, armHalf(5.24, ex));
    strap += P(smooth([[sa[0], sa[1], 1], [sb[0], sb[1], 1], [sc[0], sc[1], 1], [sd[0], sd[1], 1]], true), c.f, c.l, 1.1);
    var bk = armPt(5.12, -armHalf(5.12, ex) + 4);
    strap += P('M' + f(bk[0] - 2.6) + ' ' + f(bk[1] - 2.4) + 'h5.2v4.8h-5.2Z', 'none', c.b, 1.1);
    var sl = sleeves(k, c, { cap: [67.4, 185.4], t1: 5.7, ex: ex, end: 1.4, folds: [3.1], extra: strap });
    var sp = shoulderPt(5.8);
    var sideTop = [[sideX(244) - e, 244], [sideX(268) - e, 268], [sideX(292) - e, 292], [sideX(316) - e, 316]];
    var skirt = [[sideX(340) - e + 1, 340], [62.4, 370], [57.4, 410], [52.4, 470], [47.4, 540], [43, 614, 1], [80, 617.6], [120, 618.6]];
    var top = [[104, 169, 1], [88, 176.6], [69, 184.6], [sp[0] + 3.4, sp[1] + 0.4, 1], [sp[0] + 5, 212], [sp[0] + 9.4, 230]];
    var inner = P(smooth([[sideX(240) - e - 4, 240], [sideX(300) - e - 4, 300], [sideX(330) - e - 4, 330], [58, 400], [48, 540], [40, 620], [52, 620], [58, 540], [66, 400], [sideX(330) - e + 6, 330], [sideX(300) - e + 7, 300], [sideX(240) - e + 7, 240]], true), c.s);
    inner += L([[84, 344], [76, 450], [66, 612]], c.d, 1.05, 'opacity="0.75"') + L([[100, 346], [98, 470], [94, 614]], c.d, 1, 'opacity="0.6"');
    if (k.back) {
      var bd = smooth(sym([[120, 172, 1], [112, 171.4], [104, 169, 1]].concat(top.slice(1), sideTop, skirt)), true);
      o += shape(k, bd, c.f, c.l, 1.45, both(inner));
      o += sl;
      var yoke = smooth(sym([[120, 250], [96, 248], [75, 241], [70.4, 226], [68, 206], [67.4, 185.4, 1], [69, 184.6], [88, 176.6], [104, 169, 1], [112, 171.4], [120, 172]]), true);
      o += P(yoke, c.f, c.l, 1.2);
      o += L([[120, 336], [120, 560]], c.l, 1.1) + L([[120, 560], [120, 618]], c.l, 1.3);
      o += belt(k, c, true);
      o += P(smooth(sym([[120, 166], [110, 165], [103.4, 162.4, 1], [100.6, 169], [106, 176], [120, 177.4]]), true), c.f, c.l, 1.2);
      return o;
    }
    var vneck = [[120, 238, 1], [112.6, 214], [107, 190]];
    var d = smooth(sym(vneck.concat(top, sideTop, skirt)), true);
    o += shape(k, d, c.f, c.l, 1.45, both(inner));
    o += sl;
    // storm flap, front edge, buttons
    o += P(smooth([[67.6, 186.4, 1], [69, 206], [71.6, 226], [76, 244], [80, 252, 1], [97, 253, 1], [104, 226], [100, 206], [92, 192, 1], [80, 182]], true), c.f, c.l, 1.2);
    o += L([[134.8, 238], [134.8, 336]], c.l, 1.15) + L([[134.8, 336], [133.4, 470], [132.6, 617]], c.l, 1.2);
    [[108.6, 262], [131.4, 262], [108.6, 296], [131.4, 296], [108.6, 368], [131.4, 368], [108.6, 404], [131.4, 404]].forEach(function (b) {
      o += circ(b[0], b[1], 2.5, c.b, c.bl, 0.9) + circ(b[0] - 0.6, b[1] - 0.6, 0.7, lighten(c.b, 0.4));
    });
    // pockets
    o += P('M70 382L82 378L86.6 412L83 413.6Z', c.f, c.l, 1.1) + P('M170 382L158 378L153.4 412L157 413.6Z', c.f, c.l, 1.1);
    // collar and lapels
    var collar = [[80.6, 205.6, 1], [78.6, 193], [84.6, 181], [97, 170], [106.6, 162.6, 1], [107, 172], [99.6, 180], [91.6, 192.6], [88, 205, 1]];
    var lapel = [[104, 169.4, 1], [97.6, 177.6], [89.6, 192.6, 1], [80.6, 207.6, 1], [89.4, 213.6, 1], [102.6, 226.6], [120, 238, 1], [112.6, 214], [107, 190]];
    o += both(P(smooth(collar, true), c.f, c.l, 1.25) + shape(k, smooth(lapel, true), c.f, c.l, 1.3, P(smooth([[90, 213.6], [103, 226.6], [118, 236.6], [108, 218], [98, 210]], true), c.s)));
    // epaulettes
    o += both(P(smooth([[51.6, 190.4, 1], [80, 180.8, 1], [81.4, 186.4, 1], [53.4, 197, 1]], true), c.f, c.l, 1.1) + circ(78, 184.8, 1.5, c.b, c.bl, 0.7));
    o += belt(k, c, false);
    return o;
  }
  function belt(k, c, back) {
    var o = '', e = 7.6;
    var bd = smooth([[sideX(318) - e - 0.6, 317.6, 1], [120, 319.6], [240 - sideX(318) + e + 0.6, 317.6, 1], [240 - sideX(334) + e + 0.8, 333.6, 1], [120, 335.6], [sideX(334) - e - 0.8, 333.6, 1]], true);
    o += P(bd, c.f, c.l, 1.3) + L([[sideX(321) - e, 321], [120, 323], [240 - sideX(321) + e, 321]], c.d, 0.9, 'stroke-dasharray="1.4 1.6"');
    o += both(P('M66.4 315.4h4.2v21.6h-4.2Z', c.f, c.l, 1));
    if (back) return o;
    o += P('M140 319.6h10v12.8h-10Z', 'none', c.b, 1.8) + L([[145, 320.6], [145, 331.4]], c.b, 1.4);
    o += P(smooth([[150.6, 321.6, 1], [160, 323], [161.6, 330.6], [158.6, 352], [152.4, 352.8, 1], [154.4, 332.4], [150.6, 333, 1]], true), c.f, c.l, 1.2);
    return o;
  }

  /* ------------------------------------------------------------------ compose */

  var DRAW_TOP = { 'g-pink-blouse': topBlouse, 'g-cream-sweater': topSweater, 'g-lace-top': topLace, 'g-brick-top': topBrick, 'g-black-tee': topTee };
  var DRAW_LAYER = { 'g-gray-blazer': layerBlazer, 'g-navy-cardigan': layerCardigan, 'g-camel-trench': layerTrench };

  function figure(k, outfit) {
    var app = k.app, o = '';
    o += '<ellipse cx="120" cy="865" rx="66" ry="6.4" fill="' + darken('#F6DDD2', 0.3) + '" opacity="0.12"/>';
    var HEAD = '<g transform="translate(0 3)">';
    if (!k.back) o += HEAD + hairBackLayer(k, app.hairStyle) + '</g>';
    o += bodyLayer(k);
    if (outfit.dress) {
      o += shoeLayer(k, outfit.shoes);
      o += dressBlue(k, outfit.dress.c || GT['g-blue-dress']);
    } else {
      o += bottomLayer(k, outfit.bottom);
      o += shoeLayer(k, outfit.shoes);
      o += (DRAW_TOP[outfit.top.id] || topBlouse)(k, outfit.top.c);
      if (TUCKED[outfit.top.id]) o += waistband(k, outfit.bottom);
    }
    if (outfit.layer) o += (DRAW_LAYER[outfit.layer.id] || layerCardigan)(k, outfit.layer);
    if (k.back) return o + HEAD + headLayer(k) + hairBackViewLayer(k, app.hairStyle) + '</g>';
    o += HEAD + headLayer(k) + faceLayer(k) + hairShadowOnFace(k, app.hairStyle) + hairFrontLayer(k, app.hairStyle) + glassesLayer(k) + earringsLayer(k) + '</g>';
    return o;
  }

  function svg(appearance, outfit, opts) {
    var view = (opts && opts.view) || 'full';
    if (view !== 'bust' && view !== 'back') view = 'full';
    var app = normalize(assign({}, current(), appearance || {}));
    var fit;
    try { fit = resolveOutfit(assign({}, DEFAULT_OUTFIT, outfit || {})); }
    catch (e) { fit = resolveOutfit(DEFAULT_OUTFIT); }
    var k = makeCtx(app, view === 'back' ? 'back' : 'front');
    var body = figure(k, fit);
    var vb = view === 'bust' ? '0 0 240 260' : '0 0 240 880';
    if (view === 'bust') body = '<g transform="translate(-18 -9.2) scale(1.15)">' + body + '</g>';
    var label = view === 'back' ? 'Avatar seen from behind' : 'Avatar';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + vb + '" width="100%" height="100%" preserveAspectRatio="xMidYMax meet" role="img" aria-label="' + label + '">' +
      '<defs>' + k.defs.join('') + '</defs>' + body + '</svg>';
  }

  /* ------------------------------------------------------------------ state and sync */

  function load() {
    try {
      var raw = global.localStorage && global.localStorage.getItem(KEY);
      if (raw) return normalize(JSON.parse(raw));
    } catch (e) { /* storage unavailable */ }
    return assign({}, DEFAULTS);
  }
  var state = load();
  function current() { return state; }
  function save() {
    try { if (global.localStorage) global.localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* ignore */ }
  }
  var listeners = [];
  function notify() {
    listeners.slice().forEach(function (fn) { try { fn(assign({}, state)); } catch (e) { /* ignore */ } });
  }
  var channel = null;
  try { if (typeof BroadcastChannel !== 'undefined') channel = new BroadcastChannel(CHANNEL); } catch (e) { channel = null; }
  function broadcast() {
    try { if (channel) channel.postMessage({ type: 'avatar', appearance: state }); } catch (e) { /* ignore */ }
  }
  function apply(next, fromRemote) {
    state = normalize(next);
    if (!fromRemote) { save(); broadcast(); }
    rerender();
    notify();
  }
  if (channel) {
    channel.onmessage = function (ev) {
      var d = ev && ev.data;
      if (d && d.type === 'avatar' && d.appearance) apply(d.appearance, true);
    };
  }
  try {
    global.addEventListener('storage', function (ev) {
      if (ev.key === KEY || ev.key === null) apply(load(), true);
    });
  } catch (e) { /* ignore */ }

  /* ------------------------------------------------------------------ mounting */

  var APP_ATTR = { skin: 'skin', hairStyle: 'hairStyle', hairColor: 'hairColor', eyes: 'eyes', glasses: 'glasses', earrings: 'earrings', lips: 'lips' };
  function renderEl(el) {
    try {
      var ds = el.dataset || {}, app = {}, outfit = {};
      for (var key in APP_ATTR) if (ds[APP_ATTR[key]]) app[key] = ds[APP_ATTR[key]];
      ['top', 'layer', 'bottom', 'dress', 'shoes'].forEach(function (s) { if (ds[s] != null && ds[s] !== '') outfit[s] = ds[s]; });
      el.innerHTML = svg(app, outfit, { view: ds.view || 'full' });
    } catch (e) {
      try { el.innerHTML = svg({}, {}, { view: 'full' }); } catch (e2) { /* give up quietly */ }
    }
  }
  function mountAll(root) {
    root = root || (typeof document !== 'undefined' ? document : null);
    if (!root || !root.querySelectorAll) return;
    var list = [];
    if (root.matches && root.matches('[data-avatar]')) list.push(root);
    Array.prototype.forEach.call(root.querySelectorAll('[data-avatar]'), function (el) { list.push(el); });
    list.forEach(renderEl);
  }
  function rerender() { if (typeof document !== 'undefined') mountAll(document); }

  var Avatar = {
    OPTIONS: OPTIONS,
    DEFAULTS: DEFAULTS,
    DEFAULT_OUTFIT: DEFAULT_OUTFIT,
    get: function () { return assign({}, state); },
    set: function (patch) {
      var next = assign({}, state);
      for (var key in (patch || {})) if (optById(key, patch[key])) next[key] = patch[key]; // ignore unknown values
      apply(next, false);
    },
    reset: function () { apply(assign({}, DEFAULTS), false); },
    onChange: function (fn) {
      if (typeof fn !== 'function') return function () {};
      listeners.push(fn);
      return function () { var i = listeners.indexOf(fn); if (i >= 0) listeners.splice(i, 1); };
    },
    svg: svg,
    mountAll: mountAll
  };
  global.Avatar = Avatar;

  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
    else mountAll(document);
  }
})(typeof window !== 'undefined' ? window : this);
