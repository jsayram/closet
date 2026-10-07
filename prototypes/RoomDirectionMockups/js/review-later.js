/* Personal return list, saved in this browser; independent of shared review notes. */
(function () {
  'use strict';
  var R = window.MockRegistry, key = 'mps.review-later.v1', params = new URLSearchParams(location.search);
  var current = R.screens.find(function (s) { return s.id === params.get('s'); });
  var variant = current && (current.variants.find(function (v) { return v.key === params.get('v'); }) || current.variants[0]);
  var host = document.createElement('section'); host.className = 'later-box'; host.id = 'come-back-later';
  host.setAttribute('aria-label', 'Come back later');
  var heading = document.createElement('h2'); heading.textContent = 'Come back later'; host.appendChild(heading);
  var hint = document.createElement('p'); hint.className = 'small'; hint.textContent = 'Your list stays saved in this browser. Tap a screen to return to it.'; host.appendChild(hint);
  var message = document.createElement('p'); message.className = 'small'; message.setAttribute('role','status'); host.appendChild(message);
  var list = document.createElement('ul'); list.className = 'later-list'; host.appendChild(list);
  var action;
  function read() {
    try { var saved = JSON.parse(localStorage.getItem(key) || '[]'); return Array.isArray(saved) ? saved.filter(function (item) { return item && R.screens.some(function (s) { return s.id === item.screen && s.variants.some(function (v) { return v.key === item.variant; }); }); }) : []; }
    catch (e) { return []; }
  }
  function same(item) { return current && item.screen === current.id && item.variant === variant.key; }
  function write(items) {
    try { localStorage.setItem(key, JSON.stringify(items)); return true; }
    catch (e) { message.textContent = "Couldn't save your list in this browser. Please try again."; return false; }
  }
  function draw() {
    var items = read(); list.replaceChildren();
    heading.textContent = 'Come back later' + (items.length ? ' · ' + items.length : '');
    message.textContent = items.length ? 'When you’re finished with one, tap Done with this.' : 'No screens saved for later yet.';
    items.forEach(function (item) {
      var screen = R.screens.find(function (s) { return s.id === item.screen; });
      var view = screen.variants.find(function (v) { return v.key === item.variant; });
      var row = document.createElement('li'), link = document.createElement('a'), done = document.createElement('button');
      link.href = 'review.html?s=' + encodeURIComponent(screen.id) + '&v=' + encodeURIComponent(view.key);
      link.textContent = screen.title + (view !== screen.variants[0] ? ' · ' + view.label : '');
      done.type = 'button'; done.className = 'btn ghost'; done.textContent = 'Done with this';
      done.setAttribute('aria-label', 'Done with ' + screen.title + ', ' + view.label);
      done.addEventListener('click', function () { if (write(read().filter(function (x) { return x.screen !== item.screen || x.variant !== item.variant; }))) draw(); });
      row.append(link, done); list.appendChild(row);
    });
    if (action) action.textContent = items.some(same) ? 'Saved for later — next screen →' : 'Come back later →';
  }
  var groups = document.getElementById('groups');
  if (groups) groups.before(host);
  else if (current) {
    var nav = document.querySelector('.navrow'), controls = document.createElement('div'); controls.className = 'later-controls';
    action = document.createElement('button'); action.type = 'button'; action.className = 'btn ghost';
    action.addEventListener('click', function () {
      var items = read(); if (!items.some(same)) items.push({screen:current.id,variant:variant.key});
      if (!write(items)) return;
      var next = R.screens[R.screens.indexOf(current)+1];
      location.href = next ? 'review.html?s=' + encodeURIComponent(next.id) + '&v=' + encodeURIComponent(next.variants[0].key) : 'index.html#come-back-later';
    });
    var shortcut = document.createElement('a'); shortcut.href = '#come-back-later'; shortcut.textContent = 'See my later list';
    controls.append(action, shortcut); nav.after(controls);
    var notes = document.querySelector('.notes-box'); notes.after(host);
  } else return;
  draw(); window.addEventListener('storage', function (event) { if (event.key === key) draw(); });
})();
