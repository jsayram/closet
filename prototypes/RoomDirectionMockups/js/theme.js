/* Shared appearance switches for every mockup screen. Load it in <head>, before the page's own styles:
     <script src="../js/theme.js"></script>
   URL parameters (combine freely):
     ?theme=dark   dark appearance (adds html.theme-dark and loads ../css/dark.css)
     ?text=xl      largest accessibility text size (adds html.text-xl; pages reflow their own layout)
     ?motion=reduce  treat as prefers-reduced-motion (adds html.reduce-motion)
   The same values can also be set by a parent gallery frame through the same URL. */
(function () {
  var params = new URLSearchParams(location.search);
  var root = document.documentElement;
  // Follow the explicit parameter only, so every reviewer sees the same thing.
  var theme = params.get('theme');
  if (theme === 'dark') {
    root.classList.add('theme-dark');
    var here = document.currentScript && document.currentScript.src;
    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = here ? here.replace(/js\/theme\.js.*$/, 'css/dark.css') : '../css/dark.css';
    document.head.appendChild(link);
  }
  if (params.get('text') === 'xl') root.classList.add('text-xl');
  var reduce = params.get('motion') === 'reduce' ||
    (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
  if (reduce) root.classList.add('reduce-motion');
  window.MockTheme = {
    dark: theme === 'dark',
    xl: params.get('text') === 'xl',
    reduceMotion: !!reduce,
    /* Keep theme/text/motion when linking to another screen. */
    carry: function (href) {
      var keep = ['theme', 'text', 'motion'].filter(function (k) { return params.get(k); });
      if (!keep.length || /^(https?:|#|mailto:)/.test(href)) return href;
      var u = new URL(href, location.href);
      keep.forEach(function (k) { if (!u.searchParams.get(k)) u.searchParams.set(k, params.get(k)); });
      return u.pathname.split('/').pop() + u.search + u.hash;
    }
  };
  document.addEventListener('DOMContentLoaded', function () {
    if (!window.MockTheme.dark && !window.MockTheme.xl && params.get('motion') !== 'reduce') return;
    document.querySelectorAll('a[href]').forEach(function (a) {
      var h = a.getAttribute('href');
      if (h && /\.html/.test(h)) a.setAttribute('href', window.MockTheme.carry(h));
    });
  });
})();
