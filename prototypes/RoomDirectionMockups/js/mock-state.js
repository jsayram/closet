/* Local interaction state for the mockups (saved looks, laundry marks, chosen source, toggles...).
   Kept in sessionStorage so it survives navigating between screens, resizing and rotating,
   but resets when the review tab closes. Every access is wrapped so the pages still work
   when storage is blocked. Nothing here is a real service.
     MockState.get('laundry.tracking', true)
     MockState.set('laundry.tracking', false)
     MockState.update('saved.ids', function (ids) { return (ids || []).concat('o-new'); })
     MockState.reset()            // clear everything (used by Demo controls)
     MockState.on(fn)             // called with (key, value) after set/update in this tab */
(function () {
  var PREFIX = 'mps.mock.';
  var mem = {};
  var listeners = [];
  function read(key) {
    try {
      var raw = sessionStorage.getItem(PREFIX + key);
      if (raw !== null) return JSON.parse(raw);
    } catch (e) {}
    return Object.prototype.hasOwnProperty.call(mem, key) ? mem[key] : undefined;
  }
  function write(key, value) {
    mem[key] = value;
    try { sessionStorage.setItem(PREFIX + key, JSON.stringify(value)); } catch (e) {}
    listeners.forEach(function (fn) { try { fn(key, value); } catch (e) {} });
  }
  window.MockState = {
    get: function (key, fallback) { var v = read(key); return v === undefined ? fallback : v; },
    set: write,
    update: function (key, fn) { write(key, fn(read(key))); return read(key); },
    reset: function () {
      mem = {};
      try {
        Object.keys(sessionStorage).forEach(function (k) { if (k.indexOf(PREFIX) === 0) sessionStorage.removeItem(k); });
      } catch (e) {}
    },
    on: function (fn) { listeners.push(fn); }
  };
})();
