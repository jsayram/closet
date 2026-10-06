/* garments.js: drawings of the fictional closet, in the room style.
   Contract: STYLE.md, "js/garments.js".
   Every garment uses viewBox 0 0 120 170. With a hanger, the hook's outer top is at (60, 4)
   and the hook loop is centred near (60, 11); a rail whose centreline is at y = 11 sits in the hook.
   Tops, layers and the dress hang from a wood hanger whose shoulders show at the neckline (bar peak y 19.6,
   garment shoulders from y 25.5). Bottoms hang full length from a clip hanger (bar y 20..31, clips at the
   waistband, y 23.5..36). Shoes and the bag ignore the hanger option. Without a hanger the piece is centred
   in the box and scaled up by at most 14 percent for a tile.
   Markup: <span data-garment="g-pink-blouse" data-hanger></span>
           optional data-detail="low" | "high" (default: picks "low" by itself when the drawing is
           rendered narrower than 64 px, so pieces still read when they are small in the wardrobe).
   API:    window.Garments = { LIST, svg(id, {hanger, small}), mountAll(root) }
   An unknown id falls back to a default of its guessed category and never throws.
   Plain script, no dependencies, no network, no text inside the art. */
(function (global) {
  'use strict';

  var LIST = [
    { id: 'g-pink-blouse',    name: 'Cute pink shirt',        category: 'top',       color: '#F4B4C2' },
    { id: 'g-cream-sweater',  name: 'Cream knit sweater',     category: 'top',       color: '#FFF3E0' },
    { id: 'g-lace-top',       name: 'White lace top',         category: 'top',       color: '#FFFDF8' },
    { id: 'g-brick-top',      name: 'Brick knit top',         category: 'top',       color: '#B5533C' },
    { id: 'g-black-tee',      name: 'Black tee',              category: 'top',       color: '#2E2A30' },
    { id: 'g-cream-crop',     name: 'Cream lace crop top',    category: 'top',       color: '#F8ECD8' },
    { id: 'g-navy-cardigan',  name: 'Navy cardigan',          category: 'layer',     color: '#27335F' },
    { id: 'g-gray-blazer',    name: 'Gray blazer',            category: 'layer',     color: '#A9ABB3' },
    { id: 'g-brown-jacket',   name: 'Brown leather jacket',   category: 'layer',     color: '#7A4B2E' },
    { id: 'g-camel-trench',   name: 'Camel trench coat',      category: 'layer',     color: '#C9A06A' },
    { id: 'g-navy-trousers',  name: 'Navy dress pants',       category: 'bottom',    color: '#27335F' },
    { id: 'g-olive-trousers', name: 'Olive trousers',         category: 'bottom',    color: '#7C8450' },
    { id: 'g-wide-jeans',     name: 'Wide-leg jeans',         category: 'bottom',    color: '#6F93C4' },
    { id: 'g-black-skirt',    name: 'Black midi skirt',       category: 'bottom',    color: '#2E2A30' },
    { id: 'g-gray-leggings',  name: 'Old gray leggings',      category: 'bottom',    color: '#8E9098' },
    { id: 'g-blue-dress',     name: 'Blue floral dress',      category: 'dress',     color: '#8FB3E3' },
    { id: 'g-nude-flats',     name: 'Nude pointed flats',     category: 'shoes',     color: '#F1DCC6' },
    { id: 'g-black-heels',    name: 'Black block heels',      category: 'shoes',     color: '#2E2A30' },
    { id: 'g-white-sneakers', name: 'White sneakers',         category: 'shoes',     color: '#FAFAFA' },
    { id: 'g-tan-loafers',    name: 'Tan loafers',            category: 'shoes',     color: '#B98552' },
    { id: 'g-burgundy-bag',   name: 'Burgundy crossbody bag', category: 'accessory', color: '#7B2338' }
  ];
  var BY_ID = {};
  LIST.forEach(function (g) { BY_ID[g.id] = g; });

  // Tones per garment: f fill, s shade, h highlight, l outline, d detail lines (lighter on dark cloth),
  // i inside / lining, plus a few extras.
  var T = {
    'g-pink-blouse':    { f: '#F4B4C2', s: '#EC9DB0', h: '#FBD0D9', l: '#D97F97', d: '#D97F97', i: '#E08EA4' },
    'g-cream-sweater':  { f: '#FFF3E0', s: '#F1DEBF', h: '#FFFCF6', l: '#C9A676', d: '#DDBE92', i: '#E8D0A8' },
    'g-lace-top':       { f: '#FFFDF8', s: '#F0E7D6', h: '#FFFFFF', l: '#C6AA80', d: '#D6C09C', i: '#E6D7BD', p: '#D9C5A1' },
    'g-brick-top':      { f: '#B5533C', s: '#9E4531', h: '#CC6E56', l: '#772E1F', d: '#8E3C2A', i: '#88392A' },
    'g-black-tee':      { f: '#2E2A30', s: '#221F24', h: '#4E4853', l: '#131115', d: '#5A535F', i: '#1C191E' },
    'g-cream-crop':     { f: '#F8ECD8', s: '#EAD9BC', h: '#FFF8EC', l: '#BDA070', d: '#CDB38B', i: '#DEC9A6', p: '#CBB187' },
    'g-navy-cardigan':  { f: '#27335F', s: '#1D2749', h: '#374780', l: '#121A33', d: '#5B6CA3', i: '#182040' },
    'g-gray-blazer':    { f: '#A9ABB3', s: '#93959F', h: '#C4C6CD', l: '#6A6C78', d: '#7C7E8A', i: '#F0DCDF', il: '#CDA7B0' },
    'g-brown-jacket':   { f: '#7A4B2E', s: '#633A21', h: '#9C6A44', l: '#3F2210', d: '#4F2D18', i: '#55301A', z: '#E6E0D6', zl: '#9A9086' },
    'g-camel-trench':   { f: '#C9A06A', s: '#B88C54', h: '#DEBC8C', l: '#906C3B', d: '#A07A45', i: '#A87E48', b: '#6B4728' },
    'g-navy-trousers':  { f: '#27335F', s: '#1D2749', h: '#334277', l: '#121A33', d: '#4A5A96' },
    'g-olive-trousers': { f: '#7C8450', s: '#69713F', h: '#959D68', l: '#4B522B', d: '#5C6436' },
    'g-wide-jeans':     { f: '#6F93C4', s: '#5B80B3', h: '#8BACD8', l: '#3D6097', d: '#4C6FA8', t: '#F0D28E' },
    'g-black-skirt':    { f: '#2E2A30', s: '#221F24', h: '#443E49', l: '#131115', d: '#5A535F' },
    'g-gray-leggings':  { f: '#8E9098', s: '#7B7D86', h: '#A4A6AE', l: '#565862', d: '#6C6E78' },
    'g-blue-dress':     { f: '#8FB3E3', s: '#789FD5', h: '#AAC8EF', l: '#4E77B2', d: '#5F87C0', i: '#6B92CC',
                          fl: '#FFF7EA', fc: '#F3D97C', fp: '#F4B4C2', lf: '#5C9670' },
    'g-nude-flats':     { f: '#F1DCC6', s: '#E2C8AC', h: '#F9ECDD', l: '#B48F68', d: '#C4A07A', i: '#C9A684', in: '#F6E6D2', sole: '#C8A27C' },
    'g-black-heels':    { f: '#2E2A30', s: '#1F1C21', h: '#4E4853', l: '#111013', d: '#5A535F', i: '#D6B898', in: '#EBD6BE', sole: '#B8926C' },
    'g-white-sneakers': { f: '#FAFAFA', s: '#E9E4DE', h: '#FFFFFF', l: '#B3A79B', d: '#C7BCB1', i: '#DCD4CB', in: '#EFEAE4', sole: '#E2CBA6', tab: '#F4B4C2' },
    'g-tan-loafers':    { f: '#B98552', s: '#A2713F', h: '#CB9B6B', l: '#7A532A', d: '#8E6234', i: '#8A5B30', in: '#D8B68C', sole: '#5E3E22' },
    'g-burgundy-bag':   { f: '#7B2338', s: '#671B2E', h: '#953A50', l: '#4A1120', d: '#A24D62' }
  };
  var WOOD = { f: '#E7BC6E', s: '#D9A650', h: '#F6DB9E', l: '#B98632' };
  var GOLD = { f: '#EBC777', h: '#FBE7B1', l: '#B98632' };
  var CREAM = '#FFF7EA';

  var seq = 0;
  function r(n) { return Math.round(n * 100) / 100; }

  // Small drawing kit. Every stroke here inherits round caps and joins from the root svg.
  function Kit(small) {
    this.small = !!small;
    this.sw = small ? 3 : 1.5;        // outline width
    this.id = 'gmt' + (++seq);
    this.n = 0;
  }
  Kit.prototype = {
    // filled shape with its outline
    o: function (d, fill, line, w) {
      return '<path d="' + d + '" fill="' + fill + '" stroke="' + line + '" stroke-width="' + (w || this.sw) + '"/>';
    },
    // plain fill
    f: function (d, fill, op) {
      return '<path d="' + d + '" fill="' + fill + '"' + (op != null ? ' opacity="' + op + '"' : '') + '/>';
    },
    // line in outline weight (or w)
    l: function (d, c, w, op) {
      return '<path d="' + d + '" fill="none" stroke="' + c + '" stroke-width="' + (w || this.sw) + '"' +
        (op != null ? ' opacity="' + op + '"' : '') + '/>';
    },
    // detail line: dropped in small mode
    d: function (d, c, w, op) { return this.small ? '' : this.l(d, c, w || 1, op); },
    // stitching: dropped in small mode
    st: function (d, c, w, da) {
      return this.small ? '' : '<path d="' + d + '" fill="none" stroke="' + c + '" stroke-width="' + (w || 0.9) +
        '" stroke-dasharray="' + (da || '2 1.7') + '" stroke-linecap="butt"/>';
    },
    // filled shape, inner art clipped to it, then its outline on top
    c: function (d, fill, line, inner, w) {
      var id = this.id + 'c' + (++this.n);
      return '<clipPath id="' + id + '"><path d="' + d + '"/></clipPath>' +
        '<path d="' + d + '" fill="' + fill + '"/>' +
        '<g clip-path="url(#' + id + ')">' + (inner || '') + '</g>' +
        '<path d="' + d + '" fill="none" stroke="' + line + '" stroke-width="' + (w || this.sw) + '"/>';
    },
    dot: function (x, y, rad, fill, line, w) {
      return '<circle cx="' + r(x) + '" cy="' + r(y) + '" r="' + rad + '" fill="' + fill + '"' +
        (line ? ' stroke="' + line + '" stroke-width="' + (w || 1) + '"' : '') + '/>';
    },
    // a button: disc, outline, and a small highlight
    btn: function (x, y, rad, fill, line) {
      return this.dot(x, y, rad, fill, line, this.small ? 1.6 : 1) +
        (this.small ? '' : this.dot(x - rad * 0.3, y - rad * 0.3, rad * 0.28, '#FFFFFF', null, 0, 0.7));
    },
    // mirror a string, or call a builder twice (needed when the builder makes clip ids)
    m: function (s) { return '<g transform="matrix(-1 0 0 1 120 0)">' + s + '</g>'; },
    b: function (fn) {
      var a = typeof fn === 'function' ? fn.call(this) : fn, c = typeof fn === 'function' ? fn.call(this) : fn;
      return a + this.m(c);
    }
  };

  // ----- geometry helpers --------------------------------------------------------------------------

  // evaluate a cubic bezier [x0,y0,x1,y1,x2,y2,x3,y3]
  function bz(p, t) {
    var u = 1 - t;
    return [u * u * u * p[0] + 3 * u * u * t * p[2] + 3 * u * t * t * p[4] + t * t * t * p[6],
            u * u * u * p[1] + 3 * u * u * t * p[3] + 3 * u * t * t * p[5] + t * t * t * p[7]];
  }
  // rib ticks between two cubic edges
  function bticks(p, q, n, t0, t1) {
    var s = '';
    for (var i = 0; i < n; i++) {
      var t = t0 + (t1 - t0) * i / (n - 1), a = bz(p, t), b = bz(q, t);
      s += 'M' + r(a[0]) + ' ' + r(a[1]) + 'L' + r(b[0]) + ' ' + r(b[1]);
    }
    return s;
  }
  // rib ticks between a top edge A->B and a bottom edge C->D, both optionally sagging by `sag`
  function ticks(ax, ay, bx, by, cx, cy, dx, dy, n, sag) {
    var s = '';
    for (var i = 1; i <= n; i++) {
      var t = i / (n + 1), g = (sag || 0) * 4 * t * (1 - t);
      s += 'M' + r(ax + (bx - ax) * t) + ' ' + r(ay + (by - ay) * t + g) +
           'L' + r(cx + (dx - cx) * t) + ' ' + r(cy + (dy - cy) * t + g);
    }
    return s;
  }
  // n scallop arcs, each advancing (dx, dy); they bulge to the right of the direction of travel
  function scallops(n, dx, dy) {
    var rad = r(Math.sqrt(dx * dx + dy * dy) / 2 * 1.04), s = '';
    for (var i = 0; i < n; i++) s += 'a' + rad + ' ' + rad + ' 0 0 0 ' + r(dx) + ' ' + r(dy);
    return s;
  }
  // five-petal flower mark
  function flower(x, y, pet, ctr, sc) {
    sc = sc || 1;
    var d = 1.9 * sc, pr = r(1.3 * sc), s = '<g fill="' + pet + '">';
    for (var i = 0; i < 5; i++) {
      var a = -Math.PI / 2 + i * Math.PI * 2 / 5;
      s += '<circle cx="' + r(x + Math.cos(a) * d) + '" cy="' + r(y + Math.sin(a) * d) + '" r="' + pr + '"/>';
    }
    return s + '</g><circle cx="' + r(x) + '" cy="' + r(y) + '" r="' + r(0.95 * sc) + '" fill="' + ctr + '"/>';
  }
  // lace texture: eyelet rings and dots, as a pattern
  function lacePattern(k, c) {
    var id = k.id + 'p';
    return '<pattern id="' + id + '" width="7.2" height="7.2" patternUnits="userSpaceOnUse">' +
      '<circle cx="3.6" cy="3.6" r="1.25" fill="none" stroke="' + c + '" stroke-width=".7"/>' +
      '<circle cx="0" cy="0" r=".6" fill="' + c + '"/><circle cx="7.2" cy="0" r=".6" fill="' + c + '"/>' +
      '<circle cx="0" cy="7.2" r=".6" fill="' + c + '"/><circle cx="7.2" cy="7.2" r=".6" fill="' + c + '"/>' +
      '</pattern><rect x="0" y="0" width="120" height="170" fill="url(#' + id + ')"/>';
  }

  // ----- hangers -----------------------------------------------------------------------------------

  function hook(k) {
    // loop top at y 6.3 with a 4.6 stroke puts the hook's outer tip exactly at (60, 4); the loop is centred near (60, 11)
    var d = 'M60 21.5 V17.6 C60 14.2 66 14.4 66 10.8 C66 7.8 63.4 6.3 60 6.3 C56.6 6.3 54.2 8.4 54.2 11.2';
    return k.l(d, WOOD.l, k.small ? 5.4 : 4.6) + k.l(d, WOOD.f, k.small ? 2.6 : 2.2) +
      k.d('M60 17 C60.4 14.6 64.4 14.6 64.6 10.8 C64.6 8.8 62.6 7.7 60.4 7.6', WOOD.h, 0.8);
  }
  // Hanger bar (an inverted V) for tops. `reach` is the x of the left arm end (hidden under the garment).
  function hangTop(k, reach) {
    var x = reach || 43, y = r(21.6 + (57.2 - x) * 0.697);
    var d = 'M' + x + ' ' + y + ' L57.2 21.6 Q60 19.6 62.8 21.6 L' + (120 - x) + ' ' + y;
    return hook(k) + k.l(d, WOOD.l, k.small ? 7.6 : 6.4) + k.l(d, WOOD.f, k.small ? 3.8 : 3.6) +
      k.d('M' + (x + 3) + ' ' + r(y - 2.1 - 2.1) + ' L57.3 20.5 Q59.4 19.1 61 19.5', WOOD.h, 0.9);
  }
  // Clip hanger for bottoms: bar at y 25..31, clips grip the waistband at x = cx and 120 - cx.
  function hangClipBack(k) {
    var d = 'M33 28 L56.8 20.9 Q60 19.7 63.2 20.9 L87 28 Z';
    return hook(k) + k.l(d, WOOD.l, k.small ? 7.2 : 6) + k.l(d, WOOD.f, k.small ? 3.4 : 3.2) +
      k.d('M36 26.1 L56.8 19.9 Q59.4 19.1 61 19.5', WOOD.h, 0.9) + k.d('M36 29.3 H84', WOOD.h, 0.9);
  }
  function hangClipFront(k, cx) {
    function clip(x) {
      var d = 'M' + r(x - 3.3) + ' 25 q0 -1.5 1.5 -1.5 h3.6 q1.5 0 1.5 1.5 v9.4 q0 1.5 -1.5 1.5 h-3.6 q-1.5 0 -1.5 -1.5 Z';
      return k.o(d, WOOD.s, WOOD.l) + k.d('M' + r(x - 1.5) + ' 25.2 V33.2', WOOD.h, 0.8) +
        (k.small ? '' : k.dot(x + 0.3, 27.4, 0.75, WOOD.l));
    }
    return clip(cx) + clip(120 - cx);
  }

  // ----- shared top pieces -------------------------------------------------------------------------

  var NECK = {
    crew:  'C71.5 36.8 48.5 36.8 46.5 25.5',
    scoop: 'C72.5 41 47.5 41 46.5 25.5',
    v:     'L60 46 L46.5 25.5'
  };
  var BACK = 'M46.5 25.5 Q60 20.6 73.5 25.5';

  // the inside of the back, seen through the neck opening, with the back of the neckband and a label
  function backNeck(k, c, neck, bandFill) {
    return k.o(BACK + ' ' + neck + ' Z', c.i, c.l) +
      k.o('M46.5 25.5 Q60 20.6 73.5 25.5 L70.6 27.6 Q60 23.8 49.4 27.6 Z', bandFill || c.f, c.l, k.small ? 2 : 1.1) +
      (k.small ? '' : '<rect x="56.8" y="28.6" width="6.4" height="3.4" rx=".7" fill="' + CREAM + '" stroke="' + c.l + '" stroke-width=".7"/>');
  }
  // standard body with its neckline; hx = side x at the hem, hy = hem y, sag = hem curve
  function bodyD(neck, hx, hy, sag) {
    return 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 58 L' + hx + ' ' + hy + ' Q60 ' + r(hy + sag) + ' ' + (120 - hx) + ' ' + hy +
      ' L87.5 58 C88 50 90 42 93 34.5 L73.5 25.5 ' + neck + ' Z';
  }
  // ribbed hem band of height hb ending at hy
  function hemBand(k, c, hx, hy, sag, hb, lineC) {
    var yt = hy - hb, d = 'M' + hx + ' ' + yt + ' Q60 ' + r(yt + sag) + ' ' + (120 - hx) + ' ' + yt +
      ' L' + (120 - hx) + ' ' + hy + ' Q60 ' + r(hy + sag) + ' ' + hx + ' ' + hy + ' Z';
    return k.o(d, c.f, c.l) + k.d(ticks(hx, yt, 120 - hx, yt, hx, hy, 120 - hx, hy, 14, sag / 2), lineC || c.d, 0.9, 0.8);
  }
  // long sleeve (left side), bottom at yb; xo/xi give the outer and inner edge x at a given y
  function xo(y) { return r(19.2 - (y - 51) * 0.048); }
  function xi(y) { return r(34.5 - (y - 58) * 0.049); }
  function sleeveD(yb) {
    return 'M27 34.5 C21.8 36.4 19.6 42.5 19.2 51 L' + xo(yb) + ' ' + yb + ' L' + xi(yb + 1.6) + ' ' + r(yb + 1.6) +
      ' L34.5 58 C33.6 49.5 31 41.5 27 34.5 Z';
  }
  function cuffD(yt, h) {
    var yb = yt + h;
    return 'M' + xo(yt) + ' ' + yt + ' L' + r(xo(yb) + 0.1) + ' ' + r(yb - 1.2) + ' Q' + xo(yb) + ' ' + yb + ' ' + r(xo(yb) + 1.3) + ' ' + r(yb + 0.15) +
      ' L' + r(xi(yb) - 1.2) + ' ' + r(yb + 1.5) + ' Q' + xi(yb) + ' ' + r(yb + 1.6) + ' ' + r(xi(yb) + 0.05) + ' ' + r(yb + 0.4) +
      ' L' + xi(yt + 1.6) + ' ' + r(yt + 1.6) + ' Z';
  }
  function cuffTicks(k, c, yt, h, col) {
    var yb = yt + h;
    return k.d(ticks(xo(yt) * 1 + 0.8, yt + 0.4, xi(yt + 1.6) * 1 - 0.8, yt + 1.9, xo(yb) * 1 + 0.9, yb - 0.4, xi(yb) * 1 - 0.9, yb + 1.1, 5, 0), col || c.d, 0.9, 0.8);
  }
  // left sleeve gets a highlight streak, right (mirrored) sleeve a shade strip
  var SL_HI = 'M22 50 C21 70 19.2 94 17.6 118';
  var SL_SH = 'M8 30 L24 40 C22.6 70 20.5 100 19 140 L8 140 Z';
  function sleeves(k, c, d, extraL, extraR) {
    return k.c(d, c.f, c.l, k.l(SL_HI, c.h, 2.6, 0.9) + (extraL || '')) +
      k.m(k.c(d, c.f, c.l, k.f(SL_SH, c.s) + (extraR || '')));
  }
  // body shading used by most tops
  var BODY_SH = 'M78 30 C81 70 80.5 100 76.5 140 L98 140 L98 30 Z';
  var BODY_HI = 'M38.6 58 C38 78 37.6 96 37 114';
  function bodyShade(k, c) { return k.f(BODY_SH, c.s) + k.l(BODY_HI, c.h, 2.6, 0.9); }

  // ----- the garments ------------------------------------------------------------------------------
  // Each builder returns {art, hang:'top'|'clip'|false, box:[x0,y0,x1,y1], scale}. `H` draws the hanger at
  // the right depth (between the inside of the back and the front of the garment).
  var DRAW = {};

  DRAW['g-pink-blouse'] = function (k, c, H) {
    var neck = NECK.crew;
    var body = 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 58 L30.5 120 C40 129.5 80 129.5 89.5 120 L87.5 58 C88 50 90 42 93 34.5 L73.5 25.5 ' + neck + ' Z';
    var sl = 'M27 34.5 C21.8 36.4 19.6 42.5 19.2 51 C18.4 70 14.8 94 13 110 C12.4 115 13.6 117.6 16.4 118 L29.4 119.6 C32.2 119.9 33.4 117.6 33.5 114 C33.8 95 34.3 77 34.5 58 C33.6 49.5 31 41.5 27 34.5 Z';
    var cuff = 'M16.6 117.4 L15.9 123.6 Q15.8 125.2 17.4 125.4 L28 126.7 Q29.7 126.9 29.8 125.2 L30.2 119.2 Z';
    var gath = 'M18.6 116.6 L17.8 110.5 M22.2 117.2 L21.9 110.4 M25.8 117.7 L26 110.8 M29.2 118.2 L29.9 112.6';
    var s = backNeck(k, c, neck, c.h) + H();
    s += k.c(body, c.f, c.l, bodyShade(k, c));
    // neck binding, keyhole, gathers
    s += k.o('M46.5 25.5 C48.5 36.8 71.5 36.8 73.5 25.5 L71.2 24.9 C69.4 34.2 50.6 34.2 48.8 24.9 Z', c.h, c.l, k.small ? 2 : 1.1);
    s += k.d('M54.4 36.3 L53.4 42.8 M51 34.2 L49.4 39.8 M65.6 36.3 L66.6 42.8 M69 34.2 L70.6 39.8', c.l, 1, 0.75);
    if (!k.small) {
      s += k.o('M60 35.4 C58.2 38.4 57.6 40.8 60 43 C62.4 40.8 61.8 38.4 60 35.4 Z', c.i, c.l, 1);
      s += k.btn(60, 35.6, 1.4, CREAM, c.l);
    }
    // sleeves with gathered cuffs
    s += sleeves(k, c, sl);
    s += k.b(k.o(cuff, c.f, c.l) + k.d(gath, c.l, 1, 0.7) + (k.small ? '' : k.btn(27.2, 122.9, 1.1, CREAM, c.l)));
    return { art: s, hang: 'top', box: [13, 20.6, 107, 129.5], scale: 1.12 };
  };

  DRAW['g-cream-sweater'] = function (k, c, H) {
    var neck = 'C71.5 37.2 48.5 37.2 46.5 25.5', hx = 30.5, hy = 121, sag = 3.5;
    var body = bodyD(neck, hx, hy, sag);
    var s = backNeck(k, c, neck) + H();
    // cables down the front, in the shade tone
    var cable = '';
    if (!k.small) {
      [49, 71].forEach(function (x) {
        var a = 'M' + x + ' 42', b = 'M' + x + ' 42';
        for (var y = 42; y < 112; y += 8) { a += ' c3.3 2.3 3.3 5.7 0 8'; b += ' c-3.3 2.3 -3.3 5.7 0 8'; }
        cable += k.l(a, c.d, 1.3) + k.l(b, c.d, 1.3) + k.l('M' + (x - 5.6) + ' 40 V112 M' + (x + 5.6) + ' 40 V112', c.d, 1, 0.7);
      });
    }
    s += k.c(body, c.f, c.l, bodyShade(k, c) + cable);
    s += hemBand(k, c, hx, hy, sag, 7.5);
    // thick ribbed neckband
    var P = [46.5, 25.5, 48.5, 37.2, 71.5, 37.2, 73.5, 25.5], Q = [49.6, 24.6, 51.2, 32.4, 68.8, 32.4, 70.4, 24.6];
    s += k.o('M46.5 25.5 C48.5 37.2 71.5 37.2 73.5 25.5 L70.4 24.6 C68.8 32.4 51.2 32.4 49.6 24.6 Z', c.f, c.l);
    s += k.d(bticks(P, Q, 10, 0.07, 0.93), c.d, 0.9, 0.85);
    s += sleeves(k, c, sleeveD(119.5));
    s += k.b(k.o(cuffD(119.5, 8.5), c.f, c.l) + cuffTicks(k, c, 119.5, 8.5));
    return { art: s, hang: 'top', box: [15, 20.6, 105, 129.6], scale: 1.12 };
  };

  DRAW['g-lace-top'] = function (k, c, H) {
    var neck = NECK.scoop;
    var hemS = scallops(8, 6.8, 0);
    var body = 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 58 L32.8 122 ' + hemS + ' L87.5 58 C88 50 90 42 93 34.5 L73.5 25.5 ' + neck + ' Z';
    var sl = 'M27 34.5 C21.8 36.4 19.6 42.5 19.2 51 L17.4 93 ' + scallops(2, 7, 0.75) + ' L34.5 58 C33.6 49.5 31 41.5 27 34.5 Z';
    var lace = k.small ? '' : lacePattern(k, c.p);
    var s = backNeck(k, c, neck, c.h) + H();
    s += k.c(body, c.f, c.l, bodyShade(k, c) + lace + k.d('M34.5 116 ' + scallops(7, 7.3, 0), c.d, 0.9, 0.9));
    // scoop neck trim
    s += k.o('M46.5 25.5 C47.5 41 72.5 41 73.5 25.5 L71.3 24.9 C70.2 38 49.8 38 48.7 24.9 Z', c.h, c.l, k.small ? 2 : 1.1);
    s += k.d('M52 36.2 ' + scallops(4, 4, 0), c.d, 0.8, 0.9);
    s += k.c(sl, c.f, c.l, k.l(SL_HI, c.h, 2.6, 0.9) + lace + k.d('M18.6 88 ' + scallops(2, 7, 0.75), c.d, 0.9, 0.9)) +
         k.m(k.c(sl, c.f, c.l, k.f(SL_SH, c.s) + lace + k.d('M18.6 88 ' + scallops(2, 7, 0.75), c.d, 0.9, 0.9)));
    return { art: s, hang: 'top', box: [16, 20.6, 104, 126], scale: 1.14 };
  };

  DRAW['g-brick-top'] = function (k, c, H) {
    var neck = NECK.v, hx = 32, hy = 119, sag = 3.5;
    var body = bodyD(neck, hx, hy, sag);
    var ribs = '';
    if (!k.small) { var rd = ''; for (var x = 36; x <= 84; x += 4.8) rd += 'M' + x + ' 30 V130 '; ribs = k.l(rd, c.s, 1, 0.9); }
    var s = backNeck(k, c, neck) + H();
    s += k.c(body, c.f, c.l, bodyShade(k, c) + ribs);
    s += hemBand(k, c, hx, hy, sag, 7, c.l);
    // V neckband
    s += k.o('M46.5 25.5 L60 46 L73.5 25.5 L70 24.8 L60 40.2 L50 24.8 Z', c.f, c.l);
    s += k.d(ticks(46.9, 26.1, 59.4, 45.1, 50.2, 25.3, 59.6, 39.8, 6, 0) + ticks(73.1, 26.1, 60.6, 45.1, 69.8, 25.3, 60.4, 39.8, 6, 0), c.l, 0.9, 0.8);
    var slRib = k.d('M24.6 44 L20.6 118 M30.2 54 L26.2 118', c.s, 1, 0.9);
    s += sleeves(k, c, sleeveD(120), slRib, slRib);
    s += k.b(k.o(cuffD(120, 7.5), c.f, c.l) + cuffTicks(k, c, 120, 7.5, c.l));
    return { art: s, hang: 'top', box: [15, 20.6, 105, 129.1], scale: 1.12 };
  };

  DRAW['g-black-tee'] = function (k, c, H) {
    var neck = NECK.crew, hy = 122, sag = 4;
    var body = 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 57 L31 ' + hy + ' Q60 ' + (hy + sag) + ' 89 ' + hy + ' L87.5 57 C88 50 90 42 93 34.5 L73.5 25.5 ' + neck + ' Z';
    var sl = 'M27 34.5 C22.5 37 17.5 45.5 13.6 56.2 L29 64 C30.5 61 32 58.4 34 55.5 C33.2 48 31 41 27 34.5 Z';
    var s = backNeck(k, c, neck) + H();
    var pocket = k.d('M66.5 46 H78.4 V55.6 Q72.45 59.2 66.5 55.6 Z', c.d, 1, 0.9);
    var folds = k.d('M35.5 64 C37.5 76 37.6 90 36 104 M84.5 70 C83 84 83 98 84.4 112', c.d, 1, 0.45);
    s += k.c(body, c.f, c.l, bodyShade(k, c) + pocket + folds + k.d('M31.6 118.2 Q60 122 88.4 118.2', c.d, 0.9, 0.9));
    // neckband
    s += k.o('M46.5 25.5 C48.5 36.8 71.5 36.8 73.5 25.5 L70.8 24.9 C69.2 34.4 50.8 34.4 49.2 24.9 Z', c.f, c.l);
    s += k.d(bticks([46.5, 25.5, 48.5, 36.8, 71.5, 36.8, 73.5, 25.5], [49.2, 24.9, 50.8, 34.4, 69.2, 34.4, 70.8, 24.9], 9, 0.08, 0.92), c.d, 0.8, 0.8);
    var hem = k.d('M15.6 53.6 L30.2 61', c.d, 0.9, 0.9);
    s += k.c(sl, c.f, c.l, k.l('M22.2 42 C19.5 46 17.4 50.5 16 54', c.h, 2.4, 0.9) + hem) +
         k.m(k.c(sl, c.f, c.l, k.f('M8 30 L26 38 L16 60 L8 60 Z', c.s) + hem));
    return { art: s, hang: 'top', box: [13, 20.6, 107, 126], scale: 1.14 };
  };

  DRAW['g-cream-crop'] = function (k, c, H) {
    var neck = NECK.scoop;
    var body = 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 57 L32.8 86 ' + scallops(8, 6.8, 0) + ' L87.5 57 C88 50 90 42 93 34.5 L73.5 25.5 ' + neck + ' Z';
    var sl = 'M27 34.5 C22.5 37 18.5 43.5 15.2 52.5 ' + scallops(2, 7.3, 3.5) + ' C31.5 58 33 56.5 34 55 C33.2 48 31 41 27 34.5 Z';
    var lace = k.small ? '' : lacePattern(k, c.p);
    var s = backNeck(k, c, neck, c.h) + H();
    s += k.c(body, c.f, c.l, bodyShade(k, c) + lace + k.d('M34.6 80.5 ' + scallops(7, 7.3, 0), c.d, 0.9, 0.9) + k.d('M60 44 V84', c.d, 0.9, 0.7));
    s += k.o('M46.5 25.5 C47.5 41 72.5 41 73.5 25.5 L71.3 24.9 C70.2 38 49.8 38 48.7 24.9 Z', c.h, c.l, k.small ? 2 : 1.1);
    if (!k.small) s += k.btn(60, 48, 1.5, CREAM, c.l) + k.btn(60, 59, 1.5, CREAM, c.l) + k.btn(60, 70, 1.5, CREAM, c.l);
    var sEdge = k.d('M17.6 48.8 ' + scallops(2, 7.3, 3.5), c.d, 0.9, 0.9);
    s += k.c(sl, c.f, c.l, k.l('M22.2 42 C19.8 45.5 18 49 17 52', c.h, 2.4, 0.9) + lace + sEdge) +
         k.m(k.c(sl, c.f, c.l, k.f('M8 30 L26 38 L18 60 L8 60 Z', c.s) + lace + sEdge));
    return { art: s, hang: 'top', box: [14, 20.6, 106, 90], scale: 1.14 };
  };

  DRAW['g-navy-cardigan'] = function (k, c, H) {
    var hx = 30.5, hy = 121, sag = 3.5;
    var body = 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 58 L' + hx + ' ' + hy + ' Q60 ' + (hy + sag) + ' ' + (120 - hx) + ' ' + hy +
      ' L87.5 58 C88 50 90 42 93 34.5 L73.5 25.5 L60 58 Z';
    var silhouette = 'M46.5 25.5 L27 34.5 C30 42 32 50 32.5 58 L' + hx + ' ' + hy + ' Q60 ' + (hy + sag) + ' ' + (120 - hx) + ' ' + hy +
      ' L87.5 58 C88 50 90 42 93 34.5 L73.5 25.5 Z';
    var s = k.o(BACK + ' L60 60 Z', c.i, c.l) +
      k.o('M46.5 25.5 Q60 20.6 73.5 25.5 L70.6 27.6 Q60 23.8 49.4 27.6 Z', c.f, c.l, k.small ? 2 : 1.1) +
      (k.small ? '' : '<rect x="56.8" y="28.8" width="6.4" height="3.4" rx=".7" fill="' + CREAM + '" stroke="' + c.l + '" stroke-width=".7"/>');
    s += H();
    var pocket = function (x) {
      return k.d('M' + x + ' 96 H' + (x + 13.5) + ' V110 Q' + (x + 13.5) + ' 111.5 ' + (x + 12) + ' 111.5 H' + (x + 1.5) + ' Q' + x + ' 111.5 ' + x + ' 110 Z', c.d, 1, 0.9) +
        k.d('M' + (x + 0.5) + ' 99.6 H' + (x + 13), c.d, 0.9, 0.9);
    };
    s += k.c(body, c.f, c.l, bodyShade(k, c) + pocket(36.5) + pocket(70));
    s += hemBand(k, c, hx, hy, sag, 7.5);
    // button band: the V and the front stem, clipped to the silhouette
    var band = 'M43.5 22 L60 63 L76.5 22 M60 63 V127';
    s += k.c(silhouette, 'none', 'none', k.l(band, c.l, k.small ? 11 : 9.6) + k.l(band, c.f, k.small ? 7 : 6.6), 0.01);
    if (!k.small) for (var y = 68; y <= 116; y += 12) s += k.btn(60, y, 1.9, GOLD.f, GOLD.l);
    else for (var y2 = 70; y2 <= 116; y2 += 15) s += k.dot(60, y2, 2.4, GOLD.f, GOLD.l, 1.4);
    s += sleeves(k, c, sleeveD(119.5));
    s += k.b(k.o(cuffD(119.5, 8.5), c.f, c.l) + cuffTicks(k, c, 119.5, 8.5));
    return { art: s, hang: 'top', box: [15, 20.6, 105, 129.6], scale: 1.12 };
  };

  // jacket sleeve: wider, longer, ends at yb
  function jSleeveD(yb) {
    return 'M25.5 33.8 C20.3 35.8 18.4 42 18 50.5 L' + r(15.2 - (yb - 118) * 0.05) + ' ' + yb + ' Q' + r(15.1 - (yb - 118) * 0.05) + ' ' + (yb + 1.8) + ' ' + r(16.9 - (yb - 118) * 0.05) + ' ' + (yb + 2) +
      ' L30 ' + (yb + 3.7) + ' Q31.8 ' + (yb + 3.9) + ' 31.9 ' + (yb + 2.1) + ' L34.5 60 C33.8 50.5 30.8 41.5 25.5 33.8 Z';
  }
  var J_HI = 'M20.6 50 C19.6 72 18.2 96 17 118';

  DRAW['g-gray-blazer'] = function (k, c, H) {
    var frontL = 'M47 25.5 L25.5 33.8 C29 42 31.5 50 32.5 60 L30.8 132 Q30.7 136.2 35 137 L52 140.6 Q61.2 142.2 61.8 132 L61.8 84 C57 68 51 45 47 25.5 Z';
    var collar = 'M47 25.5 L43.4 27 C40.5 33 39.2 39 38.8 45.4 L44.8 48.4 L50.8 41.5 C49.6 36 48.4 30.6 47 25.5 Z';
    var lapel = 'M50.8 41.5 L44.8 48.4 L37.6 54.6 C43 64.5 52 76 61.8 84 C57.6 69 53.6 54.5 50.8 41.5 Z';
    var s = k.o('M47 25.5 Q60 21 73 25.5 L62 86 L58 86 Z', c.i, c.il) +
      k.d('M60 31 V82', c.il, 0.9, 0.8) +
      (k.small ? '' : '<rect x="56.6" y="30.2" width="6.8" height="3.6" rx=".7" fill="' + CREAM + '" stroke="' + c.il + '" stroke-width=".7"/>') +
      k.o('M47 25.5 Q60 20.6 73 25.5 L70.2 28.4 Q60 24.6 49.8 28.4 Z', c.f, c.l, k.small ? 2 : 1.1);
    s += H();
    var pocketL = 'M35.6 110.5 L50.6 112.5 L50.4 118.3 Q50.3 119.4 49.2 119.3 L36.4 117.6 Q35.3 117.4 35.4 116.3 Z';
    var welt = 'M68.6 66.6 L80.6 65 L80.9 67.8 L68.9 69.4 Z';
    // right front (under), then left front on top
    s += k.m(k.c(frontL, c.f, c.l, k.f('M8 30 L34 30 C33.4 60 33.6 100 36 140 L8 140 Z', c.s) +
      k.o(pocketL, c.f, c.l, 1) + k.d('M42.5 72 C42 84 42.4 98 43.2 110.5', c.d, 1, 0.6)));
    s += k.c(frontL, c.f, c.l, k.l('M39 62 C38.4 80 38.2 100 38.6 122', c.h, 2.6, 0.9) +
      k.f('M44 50 C50 62 56 72 64 82 L64 86 L54 86 C50 76 44 66 40 56 Z', c.s, 0.6) +
      k.o(pocketL, c.f, c.l, 1) + k.d('M42.5 72 C42 84 42.4 98 43.2 110.5', c.d, 1, 0.6) +
      k.d('M61.8 90 V130', c.d, 1, 0.5));
    s += k.m(k.o(welt, c.s, c.l, 1));
    // lapels and collar (right under left)
    s += k.m(k.o(lapel, c.f, c.l) + k.o(collar, c.f, c.l));
    s += k.c(lapel, c.f, c.l, k.l('M42 56 C47 64 52 72 58 79', c.h, 2.2, 0.8)) + k.o(collar, c.f, c.l);
    if (!k.small) s += k.btn(58.2, 92, 2.1, c.s, c.l) + k.btn(58.2, 106, 2.1, c.s, c.l);
    else s += k.dot(58, 92, 2.6, c.s, c.l, 1.5) + k.dot(58, 106, 2.6, c.s, c.l, 1.5);
    var sl = jSleeveD(134);
    var cuffBtns = k.small ? '' : k.btn(19.4, 128.6, 1.1, c.s, c.l) + k.btn(19.6, 124.2, 1.1, c.s, c.l) + k.d('M22.4 135.4 L22.9 121', c.d, 0.9, 0.7);
    s += k.c(sl, c.f, c.l, k.l(J_HI, c.h, 2.6, 0.9) + cuffBtns) + k.m(k.c(sl, c.f, c.l, k.f(SL_SH, c.s) + cuffBtns));
    return { art: s, hang: 'top', box: [14, 20.6, 106, 142], scale: 1.08 };
  };

  DRAW['g-brown-jacket'] = function (k, c, H) {
    var body = 'M47 25.5 L25.5 33.8 C29 42 31.5 50 32.5 60 L32.6 103 L33 111 Q33 112.8 34.8 112.9 Q60 114.8 85.2 112.9 Q87 112.8 87 111 L87.4 103 L87.5 60 C88.5 50 91 42 94.5 33.8 L73 25.5 L60 72 Z';
    var collar = 'M47 25.5 L42.6 27.3 C39.5 33.5 38 39.5 37.4 46 L44.4 50 L51.4 42.6 C50 37 48.5 31 47 25.5 Z';
    var lapel = 'M51.4 42.6 L44.4 50 L35.5 57 C41 64 51 70 60.5 73 C57 63 54 52.5 51.4 42.6 Z';
    var s = k.o('M47 25.5 Q60 21 73 25.5 L60 74 Z', c.i, c.l) +
      k.o('M47 25.5 Q60 20.6 73 25.5 L70.2 28.4 Q60 24.6 49.8 28.4 Z', c.f, c.l, k.small ? 2 : 1.1);
    s += H();
    var zipL = function (d) { return k.l(d, c.l, k.small ? 4 : 3.2) + k.l(d, c.z, k.small ? 2 : 1.4) + k.st(d, c.zl, 0.6, '0.9 0.9'); };
    s += k.c(body, c.f, c.l, k.f('M76 30 C80 70 79.5 100 77 140 L98 140 L98 30 Z', c.s) +
      k.l('M38 64 C37.4 78 37.4 90 38 102', c.h, 2.6, 0.9) +
      k.d('M32.6 103.8 Q60 106 87.4 103.8', c.l, 1) +
      k.d('M41 62 C39.6 76 39.4 90 40.6 103.4 M79 62 C80.4 76 80.6 90 79.4 103.4', c.d, 1, 0.9) +
      zipL('M37.4 94.4 L47.4 81.6') + zipL('M82.6 94.4 L72.6 81.6') +
      k.d('M38.6 104.6 h3.2 v7.6 h-3.2 Z M78.2 104.6 h3.2 v7.6 h-3.2 Z', c.d, 0.9, 0.9));
    // front zip
    s += zipL('M62.6 71.5 L62.6 113');
    if (!k.small) s += k.o('M61.4 74 h2.4 l.8 5.2 q0 1.4 -2 1.4 q-2 0 -2 -1.4 Z', c.z, c.zl, 0.7);
    // lapels and collar, snaps on the points
    s += k.m(k.o(lapel, c.f, c.l) + k.o(collar, c.f, c.l));
    s += k.c(lapel, c.f, c.l, k.l('M41 58 C47 65 52 69 57 71.6', c.h, 2.2, 0.8)) + k.o(collar, c.f, c.l);
    if (!k.small) s += k.dot(38.4, 56.4, 1.2, c.z, c.zl, 0.7) + k.dot(81.6, 56.4, 1.2, c.z, c.zl, 0.7) +
      k.dot(40.2, 44.6, 1.1, c.z, c.zl, 0.7) + k.dot(79.8, 44.6, 1.1, c.z, c.zl, 0.7);
    // epaulettes
    var ep = 'M29 34.4 L41.6 29 L42.9 32 L31 37.5 Z';
    s += k.b(k.o(ep, c.f, c.l, 1) + (k.small ? '' : k.dot(40.2, 30.8, 1, c.z, c.zl, 0.6)));
    var sl = jSleeveD(118);
    var cz = zipL('M20 118.6 L20.8 106.4');
    s += k.c(sl, c.f, c.l, k.l(J_HI, c.h, 2.6, 0.9) + cz) + k.m(k.c(sl, c.f, c.l, k.f(SL_SH, c.s) + k.l('M24.6 48 C23.6 70 22.4 94 21.4 114', c.h, 1.6, 0.6) + cz));
    return { art: s, hang: 'top', box: [14, 20.6, 106, 123], scale: 1.12 };
  };

  DRAW['g-camel-trench'] = function (k, c, H) {
    var frontL = 'M47 25.5 L25.5 33.8 C29 42 31.5 50 32.5 60 L30.4 90 L25.6 160 Q25.5 162.2 27.6 162.4 L70 165.4 L72 165.5 L72 70 C64 56 53 40 47 25.5 Z';
    var frontR = 'M73 25.5 L94.5 33.8 C91 42 88.5 50 87.5 60 L89.6 90 L94.4 160 Q94.5 162.2 92.4 162.4 L60 165.4 L60 60 Z';
    var collar = 'M47 25.5 L42.4 27.4 C38.8 34 37 41 36.4 48.5 L44 52.2 L51.6 44 C50 38 48.5 31.5 47 25.5 Z';
    var lapel = 'M51.6 44 L44 52.2 L36 57.5 C45 66 59 70.5 72 70 C63 63 56 54 51.6 44 Z';
    var s = k.o('M47 25.5 Q60 21 73 25.5 L66 64 L54 64 Z', c.i, c.l) +
      k.o('M47 25.5 Q60 20.6 73 25.5 L70.2 28.4 Q60 24.6 49.8 28.4 Z', c.f, c.l, k.small ? 2 : 1.1);
    s += H();
    var pocketL = 'M35.2 106 L38.4 105.3 L44.6 121.6 L41.4 122.3 Z';
    s += k.c(frontR, c.f, c.l, k.f('M78 30 C83 90 83 130 80 170 L98 170 L98 30 Z', c.s) + k.m(k.o(pocketL, c.f, c.l, 1)));
    s += k.c(frontL, c.f, c.l, k.l('M38 70 C37 100 35 130 33.5 156', c.h, 2.6, 0.9) +
      k.f('M44 52 C52 62 60 68 72 72 L72 80 L60 80 C52 72 44 64 38 56 Z', c.s, 0.55) +
      k.o(pocketL, c.f, c.l, 1) + k.d('M32 52 C35 58 39 61.5 44 63.5', c.d, 1, 0.8));
    // lapels and collar
    s += k.m(k.o(lapel, c.f, c.l) + k.o(collar, c.f, c.l));
    s += k.c(lapel, c.f, c.l, k.l('M42 59 C50 65 58 68 66 69', c.h, 2.2, 0.8)) + k.o(collar, c.f, c.l);
    // belt with buckle, loops and a hanging end
    s += k.o('M56 94 L53.4 113 Q53.3 114.4 54.7 114.5 L59.6 115 Q61 115.1 61.1 113.7 L62.6 94 Z', c.f, c.l) + k.d('M55.4 97.5 L54.1 111.4', c.d, 0.9, 0.6);
    s += k.o('M30.6 88 Q60 90.6 89.4 88 L89.8 95.4 Q60 98 30.2 95.4 Z', c.f, c.l);
    s += k.b(k.o('M38 86.4 h3.4 v10.8 h-3.4 Z', c.f, c.l, 1));
    if (!k.small) {
      s += '<rect x="64" y="86.6" width="10.4" height="9.6" rx="2" fill="none" stroke="' + c.b + '" stroke-width="1.6"/>' + k.l('M64.2 91.4 H70.2', c.b, 1.4);
    } else s += '<rect x="63.6" y="86.2" width="11" height="10.4" rx="2" fill="none" stroke="' + c.b + '" stroke-width="2.4"/>';
    // buttons: two columns, three rows
    var rows = [76, 106, 122];
    rows.forEach(function (y) { s += k.small ? k.dot(54, y, 2.4, c.b, c.l, 1.2) + k.dot(66, y, 2.4, c.b, c.l, 1.2) : k.btn(54, y, 2, c.b, c.l) + k.btn(66, y, 2, c.b, c.l); });
    // epaulettes
    var ep = 'M29 34.4 L41.6 29 L42.9 32 L31 37.5 Z';
    s += k.b(k.o(ep, c.f, c.l, 1) + (k.small ? '' : k.btn(40.2, 30.8, 1, c.b, c.l)));
    // sleeves with cuff straps
    var sl = jSleeveD(128);
    var strap = k.o('M14.8 118.2 L31.8 120.2 L31.6 124.6 L14.6 122.6 Z', c.f, c.l, 1) +
      (k.small ? '' : '<rect x="19.6" y="117.6" width="5" height="6" rx="1" fill="none" stroke="' + c.b + '" stroke-width="1.1"/>');
    s += k.c(sl, c.f, c.l, k.l(J_HI, c.h, 2.6, 0.9) + strap) + k.m(k.c(sl, c.f, c.l, k.f(SL_SH, c.s) + strap));
    return { art: s, hang: 'top', box: [13, 20.6, 107, 166], scale: 1.06 };
  };

  // ----- bottoms -----------------------------------------------------------------------------------

  function waistband(k, c, x0, x1, y0, y1) {
    return k.o('M' + (x0 + 1.4) + ' ' + y0 + ' H' + (x1 - 1.4) + ' Q' + x1 + ' ' + y0 + ' ' + x1 + ' ' + (y0 + 1.4) + ' V' + y1 + ' H' + x0 + ' V' + (y0 + 1.4) + ' Q' + x0 + ' ' + y0 + ' ' + (x0 + 1.4) + ' ' + y0 + ' Z', c.f, c.l);
  }
  function beltLoops(k, c, xs, y0, y1) {
    var s = '';
    xs.forEach(function (x) { s += k.o('M' + x + ' ' + y0 + ' h2.6 v' + (y1 - y0) + ' h-2.6 Z', c.f, c.l, k.small ? 1.6 : 1); });
    return s;
  }

  DRAW['g-navy-trousers'] = function (k, c, H) {
    var legs = 'M33.4 37 C32.4 62 29.6 120 28 164.6 L57.6 166.2 C58.4 140 59.5 106 60 80 C60.5 106 61.6 140 62.4 166.2 L92 164.6 C90.4 120 87.6 62 86.6 37 Z';
    var s = H('back');
    s += k.c(legs, c.f, c.l,
      k.f('M60 80 C59.4 106 58.4 140 57.6 166.2 L51.6 166 C53.6 135 56 100 56.4 76 L60 70 L63.6 76 C64 100 66.4 135 68.4 166 L62.4 166.2 C61.6 140 60.5 106 60 80 Z', c.s) +
      k.l('M40.5 48 C38.8 85 36.6 125 35 158', c.h, 2.6, 0.8) +
      k.d('M46.6 44 C46 85 44.6 125 43.6 162 M73.4 44 C74 85 75.4 125 76.4 162', c.l, 1, 0.9) +
      k.d('M60 37 V79.5', c.l, 1) + k.d('M64.6 37 V57 Q64.6 63.5 60.4 65.5', c.l, 1, 0.8) +
      k.d('M42.6 37 C42 46 38.6 52 33.2 55 M77.4 37 C78 46 81.4 52 86.8 55', c.l, 1) +
      k.d('M28.4 160.6 L57.8 162.2 M91.6 160.6 L62.2 162.2', c.l, 1, 0.8));
    s += waistband(k, c, 33.2, 86.8, 30.5, 37.4);
    s += beltLoops(k, c, [47, 70.4], 29.8, 38.2);
    s += k.small ? '' : k.btn(63.4, 34, 1.6, c.h, c.l);
    s += H('front', 41);
    return { art: s, hang: 'clip', box: [28, 29.8, 92, 166.5], scale: 1.1 };
  };

  DRAW['g-olive-trousers'] = function (k, c, H) {
    var legs = 'M33.4 37 C31.8 50 32.4 64 34 82 C35.4 106 36.8 134 37.6 157.5 L57 158.3 C58 132 59.4 104 60 78 C60.6 104 62 132 63 158.3 L82.4 157.5 C83.2 134 84.6 106 86 82 C87.6 64 88.2 50 86.6 37 Z';
    var cuff = 'M36.6 157 L57.8 157.9 L57.6 165.4 Q57.5 166.6 56.3 166.5 L38 165.8 Q36.8 165.7 36.8 164.5 Z';
    var s = H('back');
    s += k.c(legs, c.f, c.l,
      k.f('M60 78 C59.4 104 58 132 57 158.3 L52.4 158 C54.2 130 56 100 56.4 76 L60 70 L63.6 76 C64 100 65.8 130 67.6 158 L63 158.3 C62 132 60.6 104 60 78 Z', c.s) +
      k.l('M41 48 C40.4 85 41 125 42 154', c.h, 2.6, 0.8) +
      k.d('M46.6 37 C46.4 45 45.8 52 45 59 M51.4 37 C51.4 43 51 48 50.6 53 M73.4 37 C73.6 45 74.2 52 75 59 M68.6 37 C68.6 43 69 48 69.4 53', c.l, 1, 0.9) +
      k.d('M45 59 C45.4 90 46.4 125 47.2 156 M75 59 C74.6 90 73.6 125 72.8 156', c.l, 1, 0.6) +
      k.d('M60 37 V77.5', c.l, 1) + k.d('M64.4 37 V56 Q64.4 62 60.4 64', c.l, 1, 0.8) +
      k.d('M41.6 37 C41 46 38 51.5 33.6 54 M78.4 37 C79 46 82 51.5 86.4 54', c.l, 1));
    s += k.b(k.o(cuff, c.f, c.l) + k.d('M37.6 160.2 L57.4 161', c.d, 0.9, 0.7));
    s += waistband(k, c, 33.2, 86.8, 30.5, 37.4);
    s += beltLoops(k, c, [46, 71.4], 29.8, 38.2);
    s += k.small ? '' : k.btn(63.2, 34, 1.6, c.h, c.l);
    s += H('front', 40);
    return { art: s, hang: 'clip', box: [33, 29.8, 87, 166.6], scale: 1.1 };
  };

  DRAW['g-wide-jeans'] = function (k, c, H) {
    var legs = 'M33.4 37 C31.6 62 24.5 120 20 164.2 L58.2 166.4 C58.8 138 59.6 106 60 82 C60.4 106 61.2 138 61.8 166.4 L100 164.2 C95.5 120 88.4 62 86.6 37 Z';
    var s = H('back');
    s += k.c(legs, c.f, c.l,
      k.f('M60 82 C59.6 106 58.8 138 58.2 166.4 L52 166 C54 135 56 100 56.4 78 L60 72 L63.6 78 C64 100 66 135 68 166 L61.8 166.4 C61.2 138 60.4 106 60 82 Z', c.s) +
      k.f('M44 50 C40 82 36 124 33.5 158 C38 159.4 43 159.4 46.5 158.6 C47.6 124 48.6 86 48 50 Z', c.h, 0.55) +
      k.f('M76 50 C80 82 84 124 86.5 158 C82 159.4 77 159.4 73.5 158.6 C72.4 124 71.4 86 72 50 Z', c.h, 0.35) +
      k.d('M43.6 37 C43.2 46.5 39.8 51.8 33.2 53.8 M76.4 37 C76.8 46.5 80.2 51.8 86.8 53.8', c.l, 1) +
      k.st('M45.4 37.4 C45 47.6 40.8 53.6 33.6 55.8 M74.6 37.4 C75 47.6 79.2 53.6 86.4 55.8', c.t) +
      k.d('M60 37 V81', c.l, 1) + k.st('M64.8 38 V58 Q64.8 64.5 60.4 66.5', c.t) +
      k.st('M31.4 56 C29.2 85 24.6 125 22.2 162 M88.6 56 C90.8 85 95.4 125 97.8 162', c.t) +
      k.st('M20.6 160.8 L58 162.8 M99.4 160.8 L62 162.8', c.t) +
      k.d('M77 45.6 Q80.6 47.6 85 47.2', c.l, 1, 0.8) +
      (k.small ? '' : k.dot(43.4, 39.2, 0.9, GOLD.f, GOLD.l, 0.5) + k.dot(33.9, 53.2, 0.9, GOLD.f, GOLD.l, 0.5) +
        k.dot(76.6, 39.2, 0.9, GOLD.f, GOLD.l, 0.5) + k.dot(86.1, 53.2, 0.9, GOLD.f, GOLD.l, 0.5)));
    s += waistband(k, c, 33.2, 86.8, 30.5, 37.4);
    s += k.st('M34.4 32 H85.6 M34.2 35.8 H85.8', c.t);
    s += beltLoops(k, c, [46, 71.4], 29.8, 38.2);
    s += k.small ? '' : k.btn(63.4, 34, 1.7, GOLD.f, GOLD.l);
    s += H('front', 41);
    return { art: s, hang: 'clip', box: [20, 29.8, 100, 166.6], scale: 1.1 };
  };

  DRAW['g-black-skirt'] = function (k, c, H) {
    var body = 'M41 37 C36 70 26 110 19 140 C24 144.5 28 146 33.5 144.6 C38 143.5 41 147.5 47 146.6 C52 145.9 54.5 148.6 60 148 ' +
      'C65.5 148.6 68 145.9 73 146.6 C79 147.5 82 143.5 86.5 144.6 C92 146 96 144.5 101 140 C94 110 84 70 79 37 Z';
    var s = H('back');
    s += k.c(body, c.f, c.l,
      k.f('M52 42 C50 80 47.5 115 47 146.6 C52 145.9 54.5 148.6 60 148 C58.5 115 56.5 80 56 42 Z', c.s) +
      k.f('M72 42 C76 80 82 115 86.5 144.6 C92 146 96 144.5 101 140 C94 110 84 70 79 37 Z', c.s) +
      k.l('M38 50 C35.5 80 31 115 28 140', c.h, 2.6, 0.7) +
      k.d('M45 40 C42 80 37 115 33.5 144.6 M66 40 C68 80 71 115 73 146.6', c.d, 1, 0.6));
    s += waistband(k, c, 40.4, 79.6, 30.5, 37.2);
    s += k.d('M79.6 31.5 V37', c.d, 0.9, 0.7);
    s += H('front', 46);
    return { art: s, hang: 'clip', box: [19, 29.8, 101, 148.5], scale: 1.1 };
  };

  DRAW['g-gray-leggings'] = function (k, c, H) {
    var legs = 'M37.2 40 C35.4 56 37 80 39.6 104 C41.6 124 43.6 146 44.8 164.2 L56 165.2 C57.4 135 59.4 104 60 76 C60.6 104 62.6 135 64 165.2 L75.2 164.2 C76.4 146 78.4 124 80.4 104 C83 80 84.6 56 82.8 40 Z';
    var s = H('back');
    s += k.c(legs, c.f, c.l,
      k.f('M60 76 C59.4 104 57.4 135 56 165.2 L51.6 165 C53 135 55.4 104 56.2 74 L60 68 L63.8 74 C64.6 104 67 135 68.4 165 L64 165.2 C62.6 135 60.6 104 60 76 Z', c.s) +
      k.l('M43 50 C41.6 80 42.6 115 45 150', c.h, 2.4, 0.7) +
      // worn, shiny knees: a soft lighter patch and a couple of faint stretch lines, no hard marks
      '<ellipse cx="48.4" cy="111" rx="4.8" ry="9" fill="' + c.h + '" opacity=".5"/>' +
      '<ellipse cx="71.6" cy="111" rx="4.8" ry="9" fill="' + c.h + '" opacity=".35"/>' +
      k.d('M60 40 V75', c.l, 1) +
      k.d('M44.2 108 q4.2 1.4 8.4 0 M44.6 114 q4 1.3 8 0 M67.4 108 q4.2 1.4 8.4 0 M67.4 114 q4 1.3 8 0', c.h, 0.9, 0.5) +
      k.d('M45 160.4 L56.2 161.4 M75 160.4 L63.8 161.4', c.d, 0.9, 0.8) +
      k.d('M40.6 46 C40 60 40.6 80 42 100 M79.4 46 C80 60 79.4 80 78 100', c.d, 1, 0.45));
    s += waistband(k, c, 37.2, 82.8, 30.5, 40);
    s += k.d('M38 33.6 H82 M38 36.8 H82', c.d, 0.9, 0.7);
    s += H('front', 44);
    return { art: s, hang: 'clip', box: [37, 29.8, 83, 165.5], scale: 1.1 };
  };

  DRAW['g-blue-dress'] = function (k, c, H) {
    var neck = 'L60 47 L47 25.5';
    var bodice = 'M47 25.5 L31 32.8 C33.5 39 35 46 35.5 53 C36.5 60 38 67 39.5 74 L80.5 74 C82 67 83.5 60 84.5 53 C85 46 86.5 39 89 32.8 L73 25.5 ' + neck + ' Z';
    var sl = 'M31 32.8 C25.5 35.5 21 43 18.4 53.5 C21 55.8 23.4 54.6 25 56.4 C27 58.6 29.8 57 31.4 59.2 C33 58 35 56 36 53.6 C35.4 46 33.8 39 31 32.8 Z';
    var skirt = 'M39.5 74 C33 100 23 135 16.5 157.5 C22 161.5 27.5 158.6 33 161.6 C38.5 164.4 43.5 160.6 49 163 C54 165.2 57 162.2 60 163.6 ' +
      'C63 162.2 66 165.2 71 163 C76.5 160.6 81.5 164.4 87 161.6 C92.5 158.6 98 161.5 103.5 157.5 C97 135 87 100 80.5 74 Z';
    var s = k.o('M47 25.5 Q60 20.6 73 25.5 ' + neck + ' Z', c.i, c.l) +
      k.o('M47 25.5 Q60 20.6 73 25.5 L70.2 27.6 Q60 23.8 49.8 27.6 Z', c.h, c.l, k.small ? 2 : 1.1);
    s += H('top', 44);
    // flowers
    var fl = '';
    var spots = [[44, 42], [68, 38], [57, 56], [78, 60], [43, 64], [60, 44],
      [34, 88], [50, 84], [66, 90], [84, 84], [96, 104], [28, 108], [44, 106], [60, 102], [76, 110], [92, 124], [38, 128], [54, 124], [70, 130], [86, 146], [24, 144], [46, 148], [62, 152], [78, 150], [102, 146], [32, 152], [26, 70], [94, 70]];
    if (k.small) spots.forEach(function (p, i) { if (i % 2 === 0) fl += k.dot(p[0], p[1], 2.1, c.fl); });
    else spots.forEach(function (p, i) { fl += flower(p[0], p[1], i % 3 === 2 ? c.fp : c.fl, c.fc, 1) + k.l('M' + (p[0] + 3.4) + ' ' + (p[1] + 2.6) + ' q2.4 -.6 3.4 1.6', c.lf, 1); });
    // sleeves, skirt, bodice
    var sEdge = k.d('M20.2 50.4 C22.6 52.4 24.8 51.4 26.4 53.2 C28.2 55 30.6 53.6 32.4 55.4', c.d, 0.9, 0.8);
    s += k.c(sl, c.f, c.l, k.l('M26 40 C24 44 22 49 21 52', c.h, 2.4, 0.9) + fl + sEdge) +
         k.m(k.c(sl, c.f, c.l, k.f('M8 30 L28 36 L22 60 L8 60 Z', c.s) + fl + sEdge));
    s += k.c(skirt, c.f, c.l,
      k.f('M52 76 C51 105 50 140 49 163 C54 165.2 57 162.2 60 163.6 C58.5 140 57 105 56.5 76 Z', c.s) +
      k.f('M74 76 C80 105 92 140 103.5 157.5 C98 161.5 92.5 158.6 87 161.6 C84 135 80 105 78 76 Z', c.s, 0.8) +
      k.l('M38 90 C34 115 29 140 26 156', c.h, 2.6, 0.8) +
      k.d('M45 78 C42 105 37 135 33 161.6 M68 78 C70 105 72 135 71 163', c.d, 1, 0.55) + fl);
    s += k.c(bodice, c.f, c.l, k.f('M76 28 C80 50 82 60 84 76 L96 76 L96 28 Z', c.s) + k.l('M39 44 C38.5 52 39 62 40 70', c.h, 2.4, 0.8) + fl +
      k.d('M60 47 V72', c.d, 1, 0.5));
    s += k.o('M47 25.5 L60 47 L73 25.5 L70.4 24.8 L60 42.4 L49.6 24.8 Z', c.h, c.l, k.small ? 2 : 1.1);
    // waist seam with a small bow
    s += k.o('M39.2 72.4 Q60 75.6 80.8 72.4 L81.3 76.6 Q60 79.8 38.7 76.6 Z', c.s, c.l);
    if (!k.small) {
      s += k.o('M60 76.4 c-3.2 -4.4 -8.6 -4.2 -8.6 -1.2 c0 3.4 5.2 3.6 8.6 1.2 Z', c.h, c.l, 0.9) +
           k.o('M60 76.4 c3.2 -4.4 8.6 -4.2 8.6 -1.2 c0 3.4 -5.2 3.6 -8.6 1.2 Z', c.h, c.l, 0.9) +
           k.o('M59 77 l-2.6 7.4 l2.2 .6 l1.8 -7.6 Z M61 77 l2.6 7.4 l-2.2 .6 l-1.8 -7.6 Z', c.h, c.l, 0.9) +
           k.dot(60, 76.4, 1.5, c.h, c.l, 0.9);
    }
    return { art: s, hang: 'top', box: [16, 20.6, 104, 165], scale: 1.06 };
  };

  // ----- shoes and bag -----------------------------------------------------------------------------
  // Each shoe is drawn once in local coordinates (toe to the left, ground near y = 36..50), then placed twice.

  function shadow(k, x, y, rx, ry) {
    return '<ellipse cx="' + x + '" cy="' + y + '" rx="' + rx + '" ry="' + ry + '" fill="#5A2A3C" opacity=".10"/>';
  }
  function placePair(k, one, back, front) {
    return '<g transform="translate(' + back[0] + ' ' + back[1] + ')">' + one() + '</g>' +
      '<g transform="translate(' + front[0] + ' ' + front[1] + ')">' + one() + '</g>';
  }

  DRAW['g-nude-flats'] = function (k, c) {
    function one() {
      var opening = 'M38 17.2 C46 10 68 4.5 84 5.8 C88 6.1 91 7.4 92.4 9.8 C90.6 8.6 88.2 10.4 86.5 13.2 C80 21.2 68 25.8 56 25.8 C46.5 25.8 40 22.4 38 17.2 Z';
      var upper = 'M1.6 31.6 C3 27 12 22.6 22 19.6 C28 17.8 33 17 38 17.2 C40 22.4 46.5 25.8 56 25.8 C68 25.8 80 21.2 86.5 13.2 C88.2 10.4 90.6 8.6 92.4 9.8 C94.6 11.6 95.2 16 95.2 20 L94.8 31 C94.8 33.2 93.2 34.2 90.6 34.2 L8 34.2 C4 34.2 1 33.6 1.6 31.6 Z';
      var sole = 'M2.4 33.6 H94.6 V35.4 Q94.6 36.8 93 36.8 H7 C4 36.8 2 35.8 2.4 33.6 Z';
      var s = k.o(sole, c.sole, c.l);
      s += k.c(opening, c.i, c.l, k.f('M44 22 C56 13.5 76 10.5 90 12.5 L90 30 L44 30 Z', c['in']));
      s += k.c(upper, c.f, c.l, k.f('M0 28 L100 28 L100 40 L0 40 Z', c.s) + k.l('M9 28.2 C14 24.6 20 22 26 20.6', c.h, 2.2, 0.9) +
        k.d('M16 31 C40 29.5 70 29 92 29.8', c.d, 0.9, 0.6));
      // bow at the throat
      var bx = 31.5, by = 19.6;
      s += k.o('M' + bx + ' ' + by + ' c-3 -5.5 -9.5 -5.5 -9.5 -1 c0 4 6 4 9.5 1 Z', c.h, c.l, 1) +
        k.o('M' + bx + ' ' + by + ' c3 -5.5 9.5 -5.5 9.5 -1 c0 4 -6 4 -9.5 1 Z', c.h, c.l, 1) +
        k.o('M' + (bx - 1) + ' ' + (by + 1) + ' l-3.4 5.6 l2.6 .8 l2 -5.4 Z M' + (bx + 1) + ' ' + (by + 1) + ' l3.4 5.6 l-2.6 .8 l-2 -5.4 Z', c.h, c.l, 1) +
        k.dot(bx, by, 1.8, c.f, c.l, 1);
      return s;
    }
    var s = shadow(k, 66, 86, 46, 5) + shadow(k, 52, 123, 48, 5) + placePair(k, one, [18, 48], [4, 86]);
    return { art: s, hang: false, box: [4, 48, 114, 128], scale: 1 };
  };

  DRAW['g-black-heels'] = function (k, c) {
    function one() {
      var opening = 'M36.5 31.5 C46 22 66 9.6 82 6.6 C85.6 6 88 7.2 88.8 9.2 C86.4 7.6 83.4 9 82 11.6 C76 22 66 32.4 55 36 C47 38.6 40 36.6 36.5 31.5 Z';
      var upper = 'M1.5 46 C3.5 41.5 13 36.5 24 33 C29 31.6 33 31 36.5 31.5 C40 36.6 47 38.6 55 36 C66 32.4 76 22 82 11.6 C83.4 9 86.4 7.6 88.8 9.2 C91.6 11.8 92.6 17 92.6 22 L92.4 26 L75 28.5 C67 34 55 43 44.5 47.2 C39 49 31 49.2 22 49.2 L7 49.2 C3 49.2 0.8 48.4 1.5 46 Z';
      var heel = 'M75.6 28 L92.5 25.6 L91.4 49 Q91.3 50.4 89.9 50.4 L80.2 50.4 Q78.9 50.4 78.6 49.1 Z';
      var s = k.o(heel, c.s, c.l) + k.d('M78.4 31 L80.4 47.6', c.h, 1, 0.8);
      s += k.o('M3 47.2 H42 C52 44 62 37 72 29.6 L73.6 31.4 C64 39 54 46 43 49.4 Q40 50.4 36 50.4 H6 C3 50.4 2 49.2 3 47.2 Z', c.sole, c.l, 1);
      s += k.c(opening, c.i, c.l, k.f('M42 34.5 C55 30 70 18 80 9 L92 12 L60 40 Z', c['in']));
      s += k.c(upper, c.f, c.l, k.l('M8 42 C14 38.5 20 36 26 34.4', c.h, 2.2, 0.9) + k.l('M58 36 C66 31 73 24 79 16', c.h, 1.4, 0.6) +
        k.f('M0 44 L44 44 C34 50 10 51 0 51 Z', c.s, 0.9));
      return s;
    }
    var s = shadow(k, 66, 88, 46, 5) + shadow(k, 52, 124, 48, 5) + placePair(k, one, [18, 38], [4, 74]);
    return { art: s, hang: false, box: [4, 38, 114, 128], scale: 1 };
  };

  DRAW['g-white-sneakers'] = function (k, c) {
    function one() {
      var midsole = 'M3 33.6 C1.8 38 3.4 42.6 8 42.8 L90 42.8 C94.6 42.8 95.8 38 94.8 33.2 L3 33.6 Z';
      var upper = 'M3.2 34.2 C2.4 28.5 7.5 24.6 14.5 22.8 C21.5 21 27.5 18.5 33 14.5 L45 5.5 C47 4 50.5 3.6 52.5 5.6 L55.5 9.2 C61 13.8 71 14.2 78.5 10.5 C82.5 8.5 85.5 6.2 88.6 6 C91.6 5.8 93.4 8.5 94 12 C95 18 95 27 94.6 34 Z';
      var opening = 'M55.5 9.2 C63 5.6 76 3.8 88.6 6 C91.6 6.4 93 8 93.4 10.4 C92.2 8.4 90.4 7.4 88.6 8 C84 9.6 79 13.2 72 14.8 C65 16.2 59 14 55.5 9.2 Z';
      var s = k.o(midsole, '#FFFFFF', c.l) + k.o('M4.4 40.4 H93.4 Q94.4 40.4 94.2 41.4 Q94 42.8 92.4 42.8 H8 C5 42.8 4 41.6 4.4 40.4 Z', c.sole, c.l, 1) +
        k.d('M5.6 38.4 H92.6', c.d, 0.9, 0.8);
      s += k.c(opening, c.i, c.l, k.f('M60 12 C70 8 82 7 92 10 L92 20 L58 20 Z', c['in']));
      s += k.c(upper, c.f, c.l,
        k.f('M0 29 L100 29 L100 40 L0 40 Z', c.s, 0.8) +
        k.d('M14.8 22.9 C19 25.5 21 30 20.6 34', c.d, 1) +
        k.d('M62 34 C63 26 70 19 80 16', c.d, 1, 0.9) +
        k.d('M27.6 26.8 C37 24.4 48 19 57.4 13.4', c.d, 1) +
        k.d('M8.6 29.6 h.01 M11.6 27.6 h.01 M14.6 25.9 h.01 M10.4 32.4 h.01 M13.6 30.4 h.01', c.d, 1.4) +
        k.o('M84.2 8.4 C86.6 6.8 89.2 6 91.2 6.8 C93.2 8.2 94.2 11.2 94.5 15.2 L87 15.6 C87 12.4 86 10.2 84.2 8.4 Z', c.tab, '#D97F97', 1) +
        k.l('M10 31 C18 26 26 23 32 19', c.h, 2.2, 0.9));
      // laces: short bars across the throat, a bow at the top
      var lace = 'M27.6 20 L32 24.6 M32.4 16.4 L36.8 21 M37.2 12.8 L41.6 17.4 M42 9.2 L46.4 13.8';
      s += k.l(lace, c.l, 3.2) + k.l(lace, '#FFFFFF', 1.6);
      if (!k.small) {
        s += k.o('M50 10.4 c-4.4 -1.6 -7.6 .4 -6.6 2.8 c1 2.2 4.6 1 6.6 -2.8 Z', '#FFFFFF', c.l, 0.9) +
          k.o('M50 10.4 c4 -3.2 7.6 -2.4 7 .2 c-.6 2.4 -4.2 1.6 -7 -.2 Z', '#FFFFFF', c.l, 0.9) +
          k.o('M49.4 11.4 l-2 6.8 l2.2 .4 l1 -6.8 Z', '#FFFFFF', c.l, 0.9) + k.dot(50, 10.6, 1.3, '#FFFFFF', c.l, 0.9);
        s += '<rect x="46.6" y="5.2" width="4.2" height="2.6" rx=".7" transform="rotate(-36 48.7 6.5)" fill="' + c.tab + '" stroke="#D97F97" stroke-width=".7"/>';
      }
      return s;
    }
    var s = shadow(k, 66, 88, 46, 5) + shadow(k, 52, 128, 48, 5) + placePair(k, one, [18, 44], [4, 84]);
    return { art: s, hang: false, box: [4, 44, 114, 130], scale: 1 };
  };

  DRAW['g-tan-loafers'] = function (k, c) {
    function one() {
      var opening = 'M42 12.6 C52 7.4 72 3.4 86 5.6 C89.4 6.2 91.6 8 92.2 10.4 C90.6 9 88.4 10 87 12.4 C81 21.6 69 25.2 58 24 C50 23.2 44.6 18.8 42 12.6 Z';
      var upper = 'M1.8 32.6 C3 28 9 24.4 17 21.6 C25 18.8 31 16.2 36.5 14 C38.6 13.2 40.4 12.6 42 12.6 C44.6 18.8 50 23.2 58 24 C69 25.2 81 21.6 87 12.4 C88.4 10 90.6 9 92.2 10.4 C94 12.2 94.8 16 94.8 20 L94.6 32 C94.6 34 93.2 35 91 35 L8 35 C4.6 35 1.2 34.6 1.8 32.6 Z';
      var sole = 'M2.4 34.4 H94.6 V36.4 Q94.6 37.6 93.2 37.6 H7 C4.4 37.6 2 36.6 2.4 34.4 Z';
      var heelB = 'M70 37.6 H94.2 L93.8 40.6 Q93.7 41.6 92.6 41.6 H71.4 Q70.2 41.6 70.1 40.6 Z';
      var s = k.o(heelB, c.sole, c.l, 1) + k.o(sole, c.sole, c.l, 1);
      s += k.c(opening, c.i, c.l, k.f('M46 18 C58 12 76 9 90 11 L90 28 L46 28 Z', c['in']));
      s += k.c(upper, c.f, c.l,
        k.f('M0 29 L100 29 L100 40 L0 40 Z', c.s) +
        k.l('M8 29 C13 25.6 19 23.2 25 21.4', c.h, 2.2, 0.9) +
        k.d('M8.6 29.6 C14 25.6 24 22.4 38 20.6', c.l, 1) + k.st('M9.6 31.2 C15 27.2 25 24 38.6 22.2', c.d, 0.8, '1.6 1.4') +
        k.d('M64 34 C64.4 27.4 70 20.6 80 17.6', c.d, 1, 0.8));
      // penny strap across the vamp
      s += k.o('M37.6 15.2 L46.4 13.2 L50.6 24.6 L48.6 33.8 L39.6 33.8 L41 24 Z', c.f, c.l, 1);
      s += k.d('M40.2 24.4 L49.6 24.6', c.l, 1, 0.8) + k.o('M42.2 18.6 l4.6 -.9 l.5 2 l-4.6 .9 Z', c.i, c.l, 0.8);
      return s;
    }
    var s = shadow(k, 66, 84, 46, 5) + shadow(k, 52, 124, 48, 5) + placePair(k, one, [18, 44], [4, 84]);
    return { art: s, hang: false, box: [4, 44, 114, 128], scale: 1 };
  };

  DRAW['g-burgundy-bag'] = function (k, c) {
    var body = 'M30 100 H90 Q94 100 94.5 104 L97 142 Q97.5 150 89.5 150 H30.5 Q22.5 150 23 142 L25.5 104 Q26 100 30 100 Z';
    var flap = 'M25.6 103 Q26 100 30 100 H90 Q94 100 94.4 103 L95.6 120 C88 131 72 134 60 134 C48 134 32 131 24.4 120 Z';
    var strap = 'M33 98 C22 60 34 16 60 14 C86 16 98 60 87 98';
    // strap: outline, fill, a highlight that follows the centreline near the top (centreline passes (46.2,19.9) and (52.6,15.8))
    var s = k.l(strap, c.l, k.small ? 5.6 : 4.8) + k.l(strap, c.f, k.small ? 3 : 2.4) + k.d('M44.6 21.4 C49.4 17.2 54.4 14.4 59.6 13.6', c.h, 0.9, 0.85);
    // strap adjuster, sitting on the right half of the strap (centreline point (87.4,42.5), tangent 73 degrees)
    if (!k.small) s += '<g transform="rotate(-16.9 87.4 42.5)"><rect x="84.3" y="38.6" width="6.2" height="7.8" rx="1.4" fill="' + GOLD.f + '" stroke="' + GOLD.l + '" stroke-width=".9"/>' +
      '<path d="M84.6 42.5 H90.2" fill="none" stroke="' + GOLD.l + '" stroke-width=".9"/></g>';
    s += k.o('M30.6 94.6 h4.8 v6 h-4.8 Z M84.6 94.6 h4.8 v6 h-4.8 Z', c.f, c.l, 1);
    s += k.dot(33, 96.2, 2.6, 'none', GOLD.l, k.small ? 2.6 : 2) + k.dot(87, 96.2, 2.6, 'none', GOLD.l, k.small ? 2.6 : 2) +
      k.dot(33, 96.2, 2.6, 'none', GOLD.f, k.small ? 1.2 : 0.9) + k.dot(87, 96.2, 2.6, 'none', GOLD.f, k.small ? 1.2 : 0.9);
    s += k.c(body, c.f, c.l, k.f('M20 100 H100 V136 H20 Z', c.s) + k.d('M24.6 144.4 H95.4', c.d, 0.9, 0.5));
    s += k.c(flap, c.f, c.l, k.l('M30 106 C40 104 50 103.6 58 104', c.h, 2.4, 0.9) + k.f('M78 100 L100 100 L100 134 L86 134 C88 122 86 110 78 100 Z', c.s, 0.55) +
      k.st('M28.4 104 L28.4 118 C36 128 48 131 60 131 C72 131 84 128 91.6 118 L91.6 104', c.d, 0.8, '2 1.6'));
    s += '<rect x="55" y="127" width="10" height="7.6" rx="2" fill="' + GOLD.f + '" stroke="' + GOLD.l + '" stroke-width="' + (k.small ? 1.6 : 1) + '"/>' +
      (k.small ? '' : '<ellipse cx="60" cy="130.8" rx="2.2" ry="1.4" fill="' + GOLD.l + '"/>');
    return { art: s, hang: false, box: [22, 12, 98, 151], scale: 1 };
  };

  // ----- assembly ----------------------------------------------------------------------------------

  var FALLBACK = { top: 'g-pink-blouse', layer: 'g-navy-cardigan', bottom: 'g-navy-trousers', dress: 'g-blue-dress', shoes: 'g-nude-flats', accessory: 'g-burgundy-bag' };

  function svg(id, opts) {
    opts = opts || {};
    var g = BY_ID[id];
    if (!g) {
      var cat = (opts && opts.category) || (id && /skirt|trouser|jean|legging|pant/.test(id) ? 'bottom' : /shoe|flat|heel|sneaker|loafer|boot/.test(id || '') ? 'shoes' : /dress/.test(id || '') ? 'dress' : /bag/.test(id || '') ? 'accessory' : 'top');
      g = BY_ID[FALLBACK[cat] || FALLBACK.top];
    }
    var k = new Kit(opts.small), c = T[g.id], res = null;
    var wantH = opts.hanger !== false && opts.hanger != null ? !!opts.hanger : false;
    var H = function (which, cx) {
      if (!wantH) return '';
      if (which === 'back') return hangClipBack(k);
      if (which === 'front') return hangClipFront(k, cx || 41);
      return hangTop(k, cx);
    };
    res = DRAW[g.id](k, c, H);
    var inner = res.art;
    var hung = wantH && res.hang;
    if (!hung && res.box) {
      var cx0 = (res.box[0] + res.box[2]) / 2, cy0 = (res.box[1] + res.box[3]) / 2, sc = res.scale || 1;
      if (sc !== 1 || cx0 !== 60 || cy0 !== 85) {
        inner = '<g transform="translate(60 85) scale(' + sc + ') translate(' + r(-cx0) + ' ' + r(-cy0) + ')">' + inner + '</g>';
      }
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 170" width="100%" role="img" aria-label="' + g.name + '" ' +
      'stroke-linecap="round" stroke-linejoin="round" data-garment-id="' + g.id + '" style="display:block;overflow:visible">' + inner + '</svg>';
  }

  function mountOne(el) {
    var id = el.getAttribute('data-garment') || '';
    var hanger = el.hasAttribute('data-hanger');
    var detail = el.getAttribute('data-detail') || '';
    var key = id + '|' + (hanger ? 'h' : '') + '|' + detail;
    if (el.getAttribute('data-garment-mounted') === key) return;
    el.innerHTML = svg(id, { hanger: hanger, small: detail === 'low' });
    if (!detail) {
      // auto: a drawing narrower than 64 px gets the bolder small-size version
      var w = 0;
      try { w = el.firstChild.getBoundingClientRect().width; } catch (e) { w = 0; }
      if (w > 0 && w < 64) el.innerHTML = svg(id, { hanger: hanger, small: true });
    }
    el.setAttribute('data-garment-mounted', key);
  }
  function mountAll(root) {
    root = root || document;
    if (root.nodeType === 1 && root.hasAttribute && root.hasAttribute('data-garment')) mountOne(root);
    var list = root.querySelectorAll ? root.querySelectorAll('[data-garment]') : [];
    for (var i = 0; i < list.length; i++) mountOne(list[i]);
  }

  global.Garments = { LIST: LIST, svg: svg, mountAll: mountAll };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
  } else {
    mountAll(document);
  }
})(window);
