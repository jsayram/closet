/* Review-only copies: always replay on load, without changing first-use preferences. */
var screenTourKey = document.currentScript.getAttribute('data-screen-tour');
function startScreenTour() {
  'use strict';
  var key = screenTourKey;
  var steps = window.ScreenTours[key], params = new URLSearchParams(location.search);
  if (!steps || params.get('tour') === 'off') return;
  var requested = Number(params.get('tip'));
  var current = Number.isInteger(requested) && requested >= 1 && requested <= steps.length ? requested - 1 : 0;
  var layer = document.createElement('div'); layer.className = 'screen-tour-layer';
  layer.innerHTML = '<div class="tour-blocker" aria-hidden="true"></div><div class="tour-spotlight" aria-hidden="true"></div>' +
    '<section class="tour-card" role="dialog" aria-modal="true" aria-describedby="tour-body">' +
    '<div class="tour-kicker"><i data-icon="sparkles"></i><span id="tour-count"></span></div>' +
    '<h2 id="tour-title"></h2><p class="tour-body" id="tour-body"></p>' +
    '<div class="tour-row"><div class="tour-dots" aria-hidden="true"></div><div class="tour-actions">' +
    '<button class="tour-skip" type="button">Skip</button><button class="tour-next" type="button"><span></span><i data-icon="chevron-right"></i></button></div></div></section>';
  var previousFocus = document.activeElement, background = [], originalScroll = window.scrollY;
  var viewport = document.createElement('div'); viewport.className = 'screen-tour-background';
  document.body.appendChild(viewport);
  Array.from(document.body.children).forEach(function (node) {
    if (node.tagName === 'SCRIPT' || node === viewport) return;
    background.push({ node: node, inert: node.inert }); node.inert = true; viewport.appendChild(node);
  });
  document.body.classList.add('screen-tour-open'); document.body.appendChild(layer); viewport.scrollTop = originalScroll; window.scrollTo(0,0);
  var card = layer.querySelector('.tour-card'), spot = layer.querySelector('.tour-spotlight');
  var next = layer.querySelector('.tour-next'), skip = layer.querySelector('.tour-skip'), target;
  function findTarget() {
    return Array.from(document.querySelectorAll(steps[current].target)).find(function (node) {
      var r = node.getBoundingClientRect(); return r.width > 0 && r.height > 0 && getComputedStyle(node).visibility !== 'hidden';
    });
  }
  function place() {
    if (!target || !layer.isConnected) return;
    var r = target.getBoundingClientRect(), w = innerWidth, h = innerHeight, pad = 5, gap = 22, margin = 16;
    var left = Math.max(5, r.left - pad), top = Math.max(5, r.top - pad);
    var right = Math.min(w - 5, r.right + pad), bottom = Math.min(h - 5, r.bottom + pad);
    spot.style.cssText = 'left:' + left + 'px;top:' + top + 'px;width:' + (right-left) + 'px;height:' + (bottom-top) + 'px';
    var cw = card.offsetWidth, ch = card.offsetHeight, cx = (left + right)/2, cy = (top + bottom)/2;
    var x = Math.max(margin, Math.min(w-cw-margin, cx-cw/2)), y, edge;
    if (h-bottom-margin >= ch+gap) { y=bottom+gap; edge='top'; }
    else if (top-margin >= ch+gap) { y=top-ch-gap; edge='bottom'; }
    else if (w-right-margin >= cw+gap) { x=right+gap; y=Math.max(margin,Math.min(h-ch-margin,cy-ch/2)); edge='left'; }
    else if (left-margin >= cw+gap) { x=left-cw-gap; y=Math.max(margin,Math.min(h-ch-margin,cy-ch/2)); edge='right'; }
    else {
      // Small frames: bring the control into the top area to leave room underneath.
      target.scrollIntoView({ block: 'start', inline: 'nearest', behavior: 'instant' });
      r = target.getBoundingClientRect(); top=Math.max(5,r.top-pad); bottom=Math.min(h-5,r.bottom+pad);
      spot.style.top=top+'px'; spot.style.height=(bottom-top)+'px'; cy=(top+bottom)/2;
      y=Math.min(h-ch-margin,bottom+gap); edge='top';
    }
    card.className='tour-card tail-'+edge;
    card.style.left=x+'px'; card.style.top=y+'px';
    var tail = edge === 'top' || edge === 'bottom' ? cx-x-11 : cy-y-11;
    var limit = edge === 'top' || edge === 'bottom' ? cw : ch;
    card.style.setProperty('--tour-tail', Math.max(18,Math.min(limit-40,tail))+'px');
    card.dataset.tip=String(current+1); card.dataset.target=steps[current].target;
  }
  function show() {
    target = findTarget();
    if (!target) { console.error('Missing tour target: '+key+' '+steps[current].target); close(); return; }
    card.setAttribute('aria-label','Quick tour, step '+(current+1)+' of '+steps.length);
    card.querySelector('#tour-count').textContent='Quick tour · '+(current+1)+' of '+steps.length;
    card.querySelector('#tour-title').textContent=steps[current].title;
    card.querySelector('#tour-body').textContent=steps[current].body;
    next.querySelector('span').textContent=current===steps.length-1 ? 'Got it' : 'Next';
    next.querySelector('i').hidden=current===steps.length-1;
    var dots=card.querySelector('.tour-dots'); dots.replaceChildren();
    steps.forEach(function (_,i) { var dot=document.createElement('span'); dot.className='tour-dot'+(i===current?' active':''); dots.appendChild(dot); });
    Icons.mountAll(card);
    var r=target.getBoundingClientRect();
    if (r.top < 16 || r.bottom > innerHeight-112) target.scrollIntoView({block:'center',inline:'nearest',behavior:'instant'});
    place(); requestAnimationFrame(place);
    if (!matchMedia('(prefers-reduced-motion: reduce)').matches && params.get('motion')!=='reduce' && card.animate) {
      card.animate([{opacity:0,transform:'translateY(4px)'},{opacity:1,transform:'translateY(0)'}],{duration:200,easing:'ease-out'});
    }
    next.focus({preventScroll:true});
  }
  function close() {
    var finalScroll = viewport.scrollTop;
    layer.remove(); document.body.classList.remove('screen-tour-open');
    background.forEach(function (item) { document.body.insertBefore(item.node,viewport); item.node.inert=item.inert; });
    viewport.remove(); window.scrollTo(0,finalScroll);
    document.removeEventListener('tablet-layout-change',place); document.removeEventListener('keydown',onKey); window.removeEventListener('resize',place); window.removeEventListener('scroll',place,true);
    var focus = target && target.matches('a,button,input,textarea,select,[tabindex]') ? target : previousFocus;
    if (focus && focus.focus) focus.focus({preventScroll:true});
  }
  function onKey(e) {
    if (e.key==='Escape') { e.preventDefault(); close(); }
    else if (e.key==='Tab') { e.preventDefault(); (document.activeElement===next ? skip : next).focus({preventScroll:true}); }
  }
  skip.addEventListener('click',close);
  next.addEventListener('click',function () { if(current===steps.length-1) close(); else { current++; show(); } });
  document.addEventListener('tablet-layout-change',place); document.addEventListener('keydown',onKey); window.addEventListener('resize',place); window.addEventListener('scroll',place,true);
  show();
}
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', startScreenTour); else startScreenTour();
