/* A separate, replayable design mockup. No first-launch tracking or real services. */
(function () {
  'use strict';
  var params = new URLSearchParams(location.search);
  if (params.get('tour') === 'off') return;
  var stage = document.querySelector('.stage');
  var steps = [
    { title: 'Style Me', body: "Tap the laptop and I'll pull together a look from your closet for today's weather and plans.",
      spot: [218, 372, 108, 80], card: [24, 158], tail: 236, edge: 'bottom', target: '.styleme' },
    { title: 'Your closet', body: 'Open the wardrobe to add clothes and see everything you own.',
      spot: [0, 118, 172, 436], card: [24, 572], tail: 51, edge: 'top', target: '.wardrobe' },
    { title: 'Packing from', body: "Style Me only picks from what's in this suitcase. Tap it to switch suitcases or use your whole closet.",
      spot: [-2, 424, 124, 202], card: [24, 210], tail: 24, edge: 'bottom', target: '.suit' },
    { title: "That's you", body: 'Your profile lives here. You can replay this tour from it any time.',
      spot: [283, 239, 113, 72], card: [66, 330], tail: 262.5, edge: 'top', target: '.sign' }
  ];
  var requested = Number(params.get('step'));
  var current = Number.isInteger(requested) && requested >= 1 && requested <= 4 ? requested - 1 : 0;
  var background = [];
  // Hide background controls from focus/accessibility while the modal tour is open.
  function makeInert(node) {
    background.push({ node: node, inert: node.inert }); node.inert = true;
  }
  Array.from(document.querySelector('.screen').children).forEach(function (node) {
    if (node === stage) Array.from(stage.children).forEach(makeInert);
    else makeInert(node);
  });
  var blocker = document.createElement('div'); blocker.className = 'tour-blocker'; blocker.setAttribute('aria-hidden', 'true');
  var spot = document.createElement('div'); spot.className = 'tour-spotlight'; spot.setAttribute('aria-hidden', 'true');
  var card = document.createElement('section'); card.className = 'tour-card';
  card.setAttribute('role', 'dialog'); card.setAttribute('aria-modal', 'true'); card.setAttribute('aria-describedby', 'tour-body');
  card.innerHTML = '<div class="tour-kicker"><i data-icon="sparkles"></i><span id="tour-count"></span></div>' +
    '<h2 id="tour-title"></h2><p class="tour-body" id="tour-body"></p>' +
    '<div class="tour-row"><div class="tour-dots" aria-hidden="true"></div><div class="tour-actions">' +
    '<button class="tour-skip" type="button">Skip</button><button class="tour-next" type="button"><span></span><i data-icon="chevron-right"></i></button></div></div>';
  stage.append(blocker, spot, card);
  var next = card.querySelector('.tour-next'), skip = card.querySelector('.tour-skip');
  function show() {
    var step = steps[current];
    spot.style.left = step.spot[0] + 'px'; spot.style.top = step.spot[1] + 'px';
    spot.style.width = step.spot[2] + 'px'; spot.style.height = step.spot[3] + 'px';
    card.style.left = step.card[0] + 'px'; card.style.top = step.card[1] + 'px';
    card.style.setProperty('--tour-tail', step.tail + 'px');
    card.className = 'tour-card tail-' + step.edge;
    card.setAttribute('aria-label', 'Quick tour, step ' + (current + 1) + ' of 4');
    card.querySelector('#tour-count').textContent = 'Quick tour · ' + (current + 1) + ' of 4';
    card.querySelector('#tour-title').textContent = step.title;
    card.querySelector('#tour-body').textContent = step.body;
    next.querySelector('span').textContent = current === 3 ? 'Start styling' : 'Next';
    next.querySelector('i').hidden = current === 3;
    var dots = card.querySelector('.tour-dots'); dots.replaceChildren();
    steps.forEach(function (_, i) { var dot = document.createElement('span'); dot.className = 'tour-dot' + (i === current ? ' active' : ''); dots.appendChild(dot); });
    Icons.mountAll(card);
    if (matchMedia('(min-width:900px) and (orientation:landscape)').matches) {
      var bounds=stage.getBoundingClientRect(), target=stage.querySelector(step.target).getBoundingClientRect(), scale=bounds.width/stage.offsetWidth;
      bounds={left:bounds.left,top:bounds.top,width:stage.offsetWidth,height:stage.offsetHeight};
      var left=(target.left-bounds.left)/scale-8, top=(target.top-bounds.top)/scale-8, width=target.width/scale+16, height=target.height/scale+16;
      spot.style.left=left+'px'; spot.style.top=top+'px'; spot.style.width=width+'px'; spot.style.height=height+'px';
      var x=Math.max(24,Math.min(bounds.width-324,left+width/2-150)), ch=card.offsetHeight;
      var below=top+height+20+ch < bounds.height-96, y=below ? top+height+20 : top-ch-20;
      card.style.left=x+'px'; card.style.top=y+'px'; card.className='tour-card tail-'+(below?'top':'bottom');
      if (y<24) {
        x=left+width+24; y=Math.max(24,top+height/2-ch/2);
        card.style.left=x+'px'; card.style.top=y+'px'; card.className='tour-card tail-left';
        card.style.setProperty('--tour-tail',Math.max(18,Math.min(ch-40,top+height/2-y-11))+'px');
      } else card.style.setProperty('--tour-tail',Math.max(18,Math.min(260,left+width/2-x-11))+'px');
    }
    if (!matchMedia('(prefers-reduced-motion: reduce)').matches && params.get('motion') !== 'reduce' && card.animate) {
      card.animate([{ opacity: 0, transform: 'translateY(4px)' }, { opacity: 1, transform: 'translateY(0)' }], { duration: 200, easing: 'ease-out' });
    }
    next.focus({ preventScroll: true });
  }
  function close() {
    blocker.remove(); spot.remove(); card.remove();
    background.forEach(function (item) { item.node.inert = item.inert; });
    document.removeEventListener('keydown', onKey); window.removeEventListener('resize',show);
    var target = stage.querySelector(steps[current].target);
    if (target) target.focus({ preventScroll: true });
  }
  function onKey(e) {
    if (e.key === 'Escape') { e.preventDefault(); close(); }
    if (e.key === 'Tab') {
      e.preventDefault(); (document.activeElement === next ? skip : next).focus({ preventScroll: true });
    }
  }
  skip.addEventListener('click', close);
  next.addEventListener('click', function () { if (current === 3) close(); else { current++; show(); } });
  document.addEventListener('keydown', onKey); window.addEventListener('resize',show);
  show();
})();
