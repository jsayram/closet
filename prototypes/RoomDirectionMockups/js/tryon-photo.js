/* Mock photo selection only: no picker permissions, personal image or upload. */
(function () {
  'use strict';
  var params = new URLSearchParams(location.search), sheet = document.getElementById('tryon-photo-sheet');
  var opener = document.getElementById('tryon-photo-open'), state = params.get('photo') === 'added' || MockState.get('tryon.referencePresent', false);
  var background = [], view = 'main';
  function paint(nextView) {
    view = nextView || 'main';
    ['main','picker','remove'].forEach(function (name) { document.getElementById('photo-'+name).hidden = name !== view; });
    document.getElementById('photo-current').hidden = !state;
    document.getElementById('photo-empty').hidden = state;
    document.getElementById('photo-choose').textContent = state ? 'Change example photo' : 'Choose example photo';
    document.getElementById('photo-remove-open').hidden = !state;
    document.getElementById('photo-status').textContent = state ? 'Added' : 'Not added';
    if (sheet.classList.contains('open')) focusFirst();
  }
  function buttons() { return Array.from(sheet.querySelectorAll('button')).filter(function (b) { return !b.classList.contains('scrim') && b.getClientRects().length && !b.disabled; }); }
  function focusFirst() { var items = buttons(); if (items[0]) items[0].focus({preventScroll:true}); }
  function open() {
    paint('main'); Sheet.open('tryon-photo-sheet');
    background = Array.from(document.querySelector('.screen').children).filter(function (n) { return n !== sheet && n.tagName !== 'SCRIPT'; }).map(function (n) { var old = n.inert; n.inert = true; return {node:n,inert:old}; });
    focusFirst();
  }
  function close() {
    background.forEach(function (item) { item.node.inert=item.inert; }); background=[];
    Sheet.close(sheet); opener.focus({preventScroll:true});
  }
  opener.addEventListener('click',open);
  sheet.querySelectorAll('[data-photo-close]').forEach(function (b) { b.addEventListener('click',close); });
  document.getElementById('photo-choose').addEventListener('click',function () { paint('picker'); });
  document.getElementById('photo-use').addEventListener('click',function () { state=true; MockState.set('tryon.referencePresent',true); paint('main'); });
  document.getElementById('photo-picker-cancel').addEventListener('click',function () { paint('main'); });
  document.getElementById('photo-remove-open').addEventListener('click',function () { paint('remove'); });
  document.getElementById('photo-remove-cancel').addEventListener('click',function () { paint('main'); });
  document.getElementById('photo-remove-confirm').addEventListener('click',function () { state=false; MockState.set('tryon.referencePresent',false); paint('main'); });
  // Capture Escape before the shared sheet handler, so background state is restored too.
  document.addEventListener('keydown',function (e) {
    if (!sheet.classList.contains('open')) return;
    if (e.key==='Escape') { e.preventDefault(); e.stopImmediatePropagation(); close(); }
    if (e.key==='Tab') {
      var items=buttons(), at=items.indexOf(document.activeElement);
      if (items.length) { e.preventDefault(); items[(at+(e.shiftKey?-1:1)+items.length)%items.length].focus(); }
    }
  },true);
  paint('main');
  if (params.get('sheet')==='tryon-photo') { open(); if(params.get('view')==='picker') paint('picker'); }
})();
