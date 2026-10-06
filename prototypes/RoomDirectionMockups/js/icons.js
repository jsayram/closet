/* icons.js — line icons for the room-direction mockups.
   Contract: STYLE.md, "js/icons.js".

   24 x 24 grid, stroke currentColor, width 1.8, round caps and joins,
   no fill unless the name ends in "-fill".
   Markup: <i data-icon="rain"></i>  ->  inline <svg> sized 1em.
   API:    window.Icons = { NAMES, svg(name), mountAll(root) }
   Plain script, no dependencies, nothing is fetched.

   Drawing notes
   - Shapes live inside x 2..22, y 2..22 so a 1.8 stroke with round caps
     never clips, and each one is nudged so its visual mass sits on (12, 12).
   - A dot is a zero-length stroke ("h.01") with round caps, so no fill is
     needed; DOT() widens it to 2.6 where a keyhole or knob should read.
   - Four-point stars use quadratic curves with the star's centre as the
     control point, which gives the classic concave sparkle silhouette.
     The big sparkle is a little taller than wide, as in the reference.
   - Small sparkle stars (sparkles, sparkle-wand) are drawn solid, as the
     reference draws them. They are slim straight-sided stars (plus4) that
     the normal 1.8 stroke fills in completely, so they come out as solid
     tapered pluses with round tips and crisp inner corners, without a fill
     attribute. Measured against ref/tabbar.png and the laptop button.
     sparkle-wand uses the same solid stars, a slightly fuller one at the tip,
     because an open star that small closes up to a pinhole. */
(function (global) {
  'use strict';

  function n(v) { return String(Math.round(v * 100) / 100); }

  // Concave four-point star centred on (cx, cy), tips rx across and ry up.
  function star4(cx, cy, rx, ry) {
    if (ry == null) ry = rx;
    var c = n(cx) + ' ' + n(cy) + ' ';
    return 'M' + n(cx) + ' ' + n(cy - ry) +
      'Q' + c + n(cx + rx) + ' ' + n(cy) +
      'Q' + c + n(cx) + ' ' + n(cy + ry) +
      'Q' + c + n(cx - rx) + ' ' + n(cy) +
      'Q' + c + n(cx) + ' ' + n(cy - ry) + 'Z';
  }

  // Slim star with straight sides meeting at (±h, ±h). Its inside is
  // narrower than the stroke, so the stroke paints it solid: a small
  // sparkle that reads as a tapered plus with round tips.
  function plus4(cx, cy, rx, ry, h) {
    h = h == null ? 0.3 : h;
    return 'M' + n(cx) + ' ' + n(cy - ry) + 'L' + n(cx + h) + ' ' + n(cy - h) +
      'L' + n(cx + rx) + ' ' + n(cy) + 'L' + n(cx + h) + ' ' + n(cy + h) +
      'L' + n(cx) + ' ' + n(cy + ry) + 'L' + n(cx - h) + ' ' + n(cy + h) +
      'L' + n(cx - rx) + ' ' + n(cy) + 'L' + n(cx - h) + ' ' + n(cy - h) + 'Z';
  }

  // A round dot of the given diameter (default 2.6) at (x, y).
  function DOT(x, y, w) {
    return '<path stroke-width="' + (w || 2.6) + '" d="M' + x + ' ' + y + 'h.01"/>';
  }

  // Gear outline: n teeth, tips on radius ro, valleys on radius ri.
  function gear(n, ro, ri) {
    var d = '', step = Math.PI * 2 / n, tip = step * 0.22, valley = step * 0.20;
    for (var i = 0; i < n; i++) {
      var a = i * step - Math.PI / 2;
      var pts = [
        [a - tip, ro], [a + tip, ro],
        [a + step / 2 - valley, ri], [a + step / 2 + valley, ri]
      ];
      for (var j = 0; j < pts.length; j++) {
        var x = 12 + Math.cos(pts[j][0]) * pts[j][1];
        var y = 12 + Math.sin(pts[j][0]) * pts[j][1];
        d += (d ? 'L' : 'M') + x.toFixed(2) + ' ' + y.toFixed(2);
      }
    }
    return d + 'Z';
  }

  var SHAPES = {
    // Cloud with an open underside and four falling drops, like SF
    // cloud.drizzle and the header in ref/home.png: the right column hangs
    // lower than the left, and the lower drops are longer pills.
    'rain':
      '<path d="M7.4 15.7H6.4A3.5 3.5 0 0 1 5.9 8.75A5.8 5.8 0 0 1 17.2 8A3.85 3.85 0 0 1 17.2 15.7H16.6"/>' +
      '<path d="M10.4 12.1v1.2M13.6 14.1v1.2M10.4 16.6v1.9M13.6 18.4v1.9"/>',

    'sun':
      '<circle cx="12" cy="12" r="3.8"/>' +
      '<path d="M12 3.2v2.3M12 18.5v2.3M3.2 12h2.3M18.5 12h2.3M5.8 5.8l1.6 1.6M16.6 16.6l1.6 1.6M5.8 18.2l1.6-1.6M16.6 7.4l1.6-1.6"/>',

    'cloud':
      '<path d="M7.2 18.1A3.7 3.7 0 0 1 6.7 10.75A5.6 5.6 0 0 1 17.6 9.9A4.15 4.15 0 0 1 16.6 18.1Z"/>',

    'moon':
      '<path d="M20.3 13.6A8.5 8.5 0 1 1 10.4 3.7a6.9 6.9 0 0 0 9.9 9.9Z"/>',

    // Rolling case: tall body, narrow pull handle, two straps, two wheels.
    'suitcase':
      '<rect x="6.4" y="6.3" width="11.2" height="12.6" rx="2.4"/>' +
      '<path d="M9.8 6.3V5.5A1.6 1.6 0 0 1 11.4 3.9h1.2A1.6 1.6 0 0 1 14.2 5.5v.8M6.4 10h11.2M6.4 15h11.2M9.2 18.9v1.4M14.8 18.9v1.4"/>',

    'lock':
      '<rect x="5.8" y="10.6" width="12.4" height="9.8" rx="2.4"/>' +
      '<path d="M8.6 10.6V7.4a3.4 3.4 0 0 1 6.8 0v3.2"/>' +
      DOT(12, 15.5),

    'bookmark':
      '<path d="M6.8 5.2A2.2 2.2 0 0 1 9 3h6a2.2 2.2 0 0 1 2.2 2.2v15.6L12 16.4l-5.2 4.4Z"/>',

    'bookmark-fill':
      '<path fill="currentColor" d="M6.8 5.2A2.2 2.2 0 0 1 9 3h6a2.2 2.2 0 0 1 2.2 2.2v15.6L12 16.4l-5.2 4.4Z"/>',

    'calendar':
      '<rect x="3.8" y="5.5" width="16.4" height="15.2" rx="2.8"/>' +
      '<path d="M3.8 10.1h16.4M8.4 3.3v4M15.6 3.3v4"/>',

    // One open four-point star and two small solid ones to its right, the
    // same size, as on the reference Style Me button and tab.
    'sparkles':
      '<path d="' + star4(9.25, 12.6, 6.1, 6.6) + '"/>' +
      '<path d="' + plus4(18.55, 5.8, 2.3, 2.45) + '"/>' +
      '<path d="' + plus4(18.55, 18.1, 2.3, 2.45) + '"/>',

    // Coat hanger traced from the reference tab: an open crook whose stem
    // drops from the left of the loop and runs on into the right shoulder;
    // the left shoulder meets it at the neck. Rounded triangle, no inner bar.
    'hanger':
      '<path d="M14.43 6.23A2.2 2.2 0 0 0 10.1 6.8C10.1 8.3 10.97 10.13 12 10.75L19.81 15.44A2.05 2.05 0 0 1 18.75 19.25H5.25A2.05 2.05 0 0 1 4.19 15.44L12 10.75"/>',

    // Handle at the lower left, as SF magnifyingglass and the reference.
    'search':
      '<circle cx="13.4" cy="10.4" r="6.6"/>' +
      '<path d="M8.7 15.1 4 19.8"/>',

    'chevron-right': '<path d="M9.3 5.6 15.7 12l-6.4 6.4"/>',
    'chevron-left':  '<path d="M14.7 5.6 8.3 12l6.4 6.4"/>',
    'chevron-down':  '<path d="M5.6 9.3 12 15.7l6.4-6.4"/>',
    'chevron-up':    '<path d="M5.6 14.7 12 8.3l6.4 6.4"/>',
    'chevron-updown': '<path d="M7.6 9.2 12 4.8l4.4 4.4M7.6 14.8 12 19.2l4.4-4.4"/>',

    'check': '<path d="M5 12.6l4.6 4.6L19 7.2"/>',

    // Shoulders are an arc whose ends land on the ring, like person.crop.circle.
    'person-circle':
      '<circle cx="12" cy="12" r="9.2"/>' +
      '<circle cx="12" cy="9.2" r="2.8"/>' +
      '<path d="M5.6 18.6A7.2 7.2 0 0 1 18.4 18.6"/>',

    'pencil':
      '<path d="M4 20l1-4.2L16.2 4.6a1.9 1.9 0 0 1 2.7 0l.5.5a1.9 1.9 0 0 1 0 2.7L8.2 19Z"/>' +
      '<path d="M14 6.8l3.2 3.2"/>',

    'heart':
      '<path d="M12 19.9C7.2 16.6 3.8 13.3 3.8 9.3A4.5 4.5 0 0 1 12 6.8a4.5 4.5 0 0 1 8.2 2.5c0 4-3.4 7.3-8.2 10.6Z"/>',

    'heart-fill':
      '<path fill="currentColor" d="M12 19.9C7.2 16.6 3.8 13.3 3.8 9.3A4.5 4.5 0 0 1 12 6.8a4.5 4.5 0 0 1 8.2 2.5c0 4-3.4 7.3-8.2 10.6Z"/>',

    'swap':
      '<path d="M4 8.3h15.6M15.9 4.6l3.7 3.7-3.7 3.7M20 15.7H4.4M8.1 12l-3.7 3.7 3.7 3.7"/>',

    'plus':  '<path d="M12 4.8v14.4M4.8 12h14.4"/>',
    'minus': '<path d="M4.8 12h14.4"/>',
    'close': '<path d="M6.3 6.3l11.4 11.4M17.7 6.3 6.3 17.7"/>',

    'basket':
      '<path d="M3.4 10h17.2l-1.5 8.3a2.1 2.1 0 0 1-2.1 1.7H7a2.1 2.1 0 0 1-2.1-1.7Z"/>' +
      '<path d="M8.3 10l2.7-5.4M15.7 10 13 4.6M8.9 13.2v3.6M12 13.2v3.6M15.1 13.2v3.6"/>',

    'gear':
      '<path d="' + gear(8, 9.3, 7.5) + '"/>' +
      '<circle cx="12" cy="12" r="3"/>',

    'shirt':
      '<path d="M9.2 3.8 3.4 6.8l1.6 4 2.6-1.2v10.6h8.8V9.6l2.6 1.2 1.6-4-5.8-3a3.3 3.3 0 0 1-5.6 0Z"/>',

    'trousers':
      '<path d="M7 3.8h10l2 16.6h-4.8L12 10.6l-2.2 9.8H5Z"/>' +
      '<path d="M6.7 7.2h10.6"/>',

    // Sneaker: rounded heel, a soft dip at the collar, rounded tongue, sole band.
    'shoe':
      '<path d="M3 18.2V10.2C3 8.1 3.9 6.6 5.3 6.6C6.4 6.6 6.9 7.9 8.1 7.9C8.9 7.9 9.2 7.1 9.5 6.5A.85 .85 0 0 1 10.8 6.1L14.3 11.1C15.2 12.3 16.5 12.9 18 13.1L18.3 13.15A3 3 0 0 1 21 16.1V17.2A1 1 0 0 1 20 18.2Z"/>' +
      '<path d="M3 15.3H20.9"/>',

    'bag':
      '<path d="M5.1 9h13.8l1.1 9.7a2.1 2.1 0 0 1-2.1 2.3H6.1A2.1 2.1 0 0 1 4 18.7Z"/>' +
      '<path d="M8.6 11.7V7.4a3.4 3.4 0 0 1 6.8 0v4.3"/>',

    'camera':
      '<path d="M3.2 9.3a2.2 2.2 0 0 1 2.2-2.2h1.8a1 1 0 0 0 .85-.47l.95-1.5a1 1 0 0 1 .85-.47h4.3a1 1 0 0 1 .85.47l.95 1.5a1 1 0 0 0 .85.47h1.8a2.2 2.2 0 0 1 2.2 2.2v8.2a2.2 2.2 0 0 1-2.2 2.2H5.4a2.2 2.2 0 0 1-2.2-2.2Z"/>' +
      '<circle cx="12" cy="13.2" r="3.4"/>',

    'photo':
      '<rect x="3.2" y="4.6" width="17.6" height="14.8" rx="2.5"/>' +
      '<path d="M20.8 15.4l-4.4-4.4a1.3 1.3 0 0 0-1.8 0L7 18.6"/>' +
      '<circle cx="8.4" cy="9.4" r="1.6"/>',

    'info':
      '<circle cx="12" cy="12" r="9.2"/>' +
      '<path d="M12 11.3v5.3"/>' +
      DOT(12, 7.9, 2.2),

    'mirror':
      '<path d="M6.2 17.2V8.8a5.8 5.8 0 0 1 11.6 0v8.4Z"/>' +
      '<path d="M12 17.2v3.6M8.2 20.8h7.6M9.2 11.8l3.8-3.8"/>',

    'palette':
      '<path d="M12 3.4a8.6 8.6 0 1 0 0 17.2c1.3 0 2-.9 2-1.9 0-.5-.2-.9-.5-1.3-.3-.4-.5-.8-.5-1.3 0-1.1.9-1.9 2-1.9h1.9a3.7 3.7 0 0 0 3.7-3.7c0-3.9-3.9-7.1-8.6-7.1Z"/>' +
      DOT(7.7, 12, 2.3) + DOT(9.6, 8.1, 2.3) + DOT(14.2, 7.6, 2.3) + DOT(17.3, 10.5, 2.3),

    'undo':
      '<path d="M8.6 5 4.4 9.2l4.2 4.2M4.9 9.2h9.3a5.2 5.2 0 0 1 0 10.4H9.4"/>',

    'trash':
      '<path d="M4.2 6.6h15.6M9.2 6.6V5.2a1.6 1.6 0 0 1 1.6-1.6h2.4a1.6 1.6 0 0 1 1.6 1.6v1.4"/>' +
      '<path d="M6.2 6.6l.9 12.1a2 2 0 0 0 2 1.9h5.8a2 2 0 0 0 2-1.9l.9-12.1"/>' +
      '<path d="M10.2 10.6v6M13.8 10.6v6"/>',

    'star':
      '<path d="M12 3.3l2.53 5.92 6.41.58-4.85 4.23 1.44 6.27L12 17l-5.53 3.3 1.44-6.27L3.06 9.8l6.41-.58Z"/>',

    'home':
      '<path d="M3.6 11.2 12 3.8l8.4 7.4M5.6 9.6v9a1.6 1.6 0 0 0 1.6 1.6h9.6a1.6 1.6 0 0 0 1.6-1.6v-9M9.8 20.2v-5.4h4.4v5.4"/>',

    'door':
      '<path d="M6.2 20.6V4.9a1.5 1.5 0 0 1 1.5-1.5h8.6a1.5 1.5 0 0 1 1.5 1.5v15.7M3.6 20.6h16.8"/>' +
      DOT(14.4, 12.5, 2.4),

    'washer':
      '<rect x="4.4" y="3" width="15.2" height="18" rx="2.5"/>' +
      '<path d="M4.4 7.6h15.2"/>' +
      DOT(7.4, 5.3, 1.8) + DOT(10.2, 5.3, 1.8) +
      '<circle cx="12" cy="14.2" r="4.2"/>' +
      '<path d="M9.2 14.6c.9-.7 1.9-.7 2.8 0s1.9.7 2.8 0"/>',

    'creditcard':
      '<rect x="2.8" y="5.4" width="18.4" height="13.2" rx="2.5"/>' +
      '<path d="M2.8 9.8h18.4M6.4 14.8h3.4"/>',

    'chat':
      '<path d="M12 4.2c-4.9 0-8.8 3.3-8.8 7.4 0 2 .9 3.8 2.5 5.1-.1 1.2-.6 2.4-1.5 3.3 1.8-.1 3.5-.7 4.8-1.6 1 .3 2 .5 3 .5 4.9 0 8.8-3.3 8.8-7.4S16.9 4.2 12 4.2Z"/>',

    'send':
      '<path d="M20.6 3.4 3.4 10.2l6.8 3.6 3.6 6.8Z"/>' +
      '<path d="M10.2 13.8l4.6-4.6"/>',

    'sliders':
      '<path d="M3.6 6.5h3.3M11.1 6.5h9.3M3.6 12h9.5M17.6 12h2.8M3.6 17.5h2.1M9.9 17.5h10.5"/>' +
      '<circle cx="9.2" cy="6.5" r="2.1"/><circle cx="15.5" cy="12" r="2.1"/><circle cx="7.8" cy="17.5" r="2.1"/>',

    'eye':
      '<path d="M2.6 12s3.4-6.4 9.4-6.4 9.4 6.4 9.4 6.4-3.4 6.4-9.4 6.4S2.6 12 2.6 12Z"/>' +
      '<circle cx="12" cy="12" r="2.9"/>',

    // The arcs are masked around the slash so it reads as a cut, as SF does.
    'wifi-off':
      '<mask id="__MASK__"><rect width="24" height="24" fill="#fff"/><path d="M3.6 3.4l17 17" stroke="#000" stroke-width="4.8"/></mask>' +
      '<g mask="url(#__MASK__)"><path d="M8.6 15.5a4.9 4.9 0 0 1 6.8 0M5.4 12.3a9.4 9.4 0 0 1 13.2 0M2.3 9.1a13.8 13.8 0 0 1 19.4 0"/></g>' +
      DOT(12, 19.1, 2.2) + '<path d="M3.6 3.4l17 17"/>',

    'clock':
      '<circle cx="12" cy="12" r="9.2"/>' +
      '<path d="M12 6.8V12l3.5 2.3"/>',

    'tag':
      '<path d="M3.6 5.4a1.8 1.8 0 0 1 1.8-1.8h6.1a2 2 0 0 1 1.4.6l7 7a2 2 0 0 1 0 2.8l-5.9 5.9a2 2 0 0 1-2.8 0l-7-7a2 2 0 0 1-.6-1.4Z"/>' +
      DOT(8, 8, 2.4),

    'sparkle-wand':
      '<path d="M12.9 9.1l2 2-9.5 9.5-2-2Z"/>' +
      '<path d="M10.9 11.1l2 2"/>' +
      '<path d="' + plus4(17.5, 6.4, 2.9, 3.3, 0.5) + '"/>' +
      '<path d="' + plus4(8.1, 5, 1.6, 1.7) + '"/>' +
      '<path d="' + plus4(19.6, 15.7, 1.45, 1.55) + '"/>'
  };

  // A small dotted ring, shown for a name that does not exist so a typo is
  // visible on the page instead of an empty gap.
  var MISSING = '<circle cx="12" cy="12" r="8" stroke-dasharray="0 3.2"/>';

  var NAMES = Object.keys(SHAPES);
  var uid = 0;

  function svg(name) {
    var body = SHAPES[name];
    if (!body) {
      if (global.console && console.warn) console.warn('Icons: unknown icon "' + name + '"');
      body = MISSING;
    }
    if (body.indexOf('__MASK__') !== -1) {
      body = body.split('__MASK__').join('ic-mask-' + (++uid));
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="1em" height="1em" ' +
      'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" ' +
      'aria-hidden="true" focusable="false" data-icon-name="' + name + '">' + body + '</svg>';
  }

  function mountOne(el) {
    var name = el.getAttribute('data-icon') || '';
    if (el.getAttribute('data-icon-mounted') === name) return;
    el.innerHTML = svg(name);
    el.setAttribute('data-icon-mounted', name);
    if (!el.hasAttribute('aria-label') && !el.hasAttribute('role')) el.setAttribute('aria-hidden', 'true');
  }

  function mountAll(root) {
    root = root || document;
    if (root.nodeType === 1 && root.hasAttribute && root.hasAttribute('data-icon')) mountOne(root);
    var list = root.querySelectorAll ? root.querySelectorAll('[data-icon]') : [];
    for (var i = 0; i < list.length; i++) mountOne(list[i]);
  }

  global.Icons = { NAMES: NAMES, svg: svg, mountAll: mountAll };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mountAll(document); });
  } else {
    mountAll(document);
  }
})(window);
