/* Keep the same controls and state when a regular screen is opened on a tablet. */
(function () {
  'use strict';
  var name=location.pathname.split('/').pop().replace(/-tour\.html$|\.html$/g,''), media=matchMedia('(min-width:768px)');
  document.body.dataset.tabletScreen=name;
  var moved=[], containers=[];
  function split(parent,leftSelectors,rightSelectors) {
    if(!parent)return;
    var children=Array.from(parent.children), left=children.filter(function(n){return n.matches(leftSelectors);}),right=children.filter(function(n){return n.matches(rightSelectors);});
    if(!left.length||!right.length)return;
    var panes=document.createElement('div');panes.className='tablet-panes';
    var a=document.createElement('div'),b=document.createElement('div');a.className='tablet-pane tablet-visual';b.className='tablet-pane tablet-details';panes.append(a,b);
    parent.insertBefore(panes,left[0]);containers.push(panes);
    [[left,a],[right,b]].forEach(function(pair){pair[0].forEach(function(n){var marker=document.createComment('tablet original position');n.before(marker);moved.push({node:n,marker:marker});pair[1].appendChild(n);});});
  }
  function restore(){moved.forEach(function(x){x.marker.replaceWith(x.node);});moved=[];containers.forEach(function(n){n.remove();});containers=[];}
  function layout(){
    restore();if(!media.matches)return;
    var col=document.querySelector('.col'),wrap=document.querySelector('.wrap');
    if(['suitcases','suitcase','laundry','laundry-off'].indexOf(name)>=0) split(col,'.scene,.head','.body');
    else if(name==='styleme')split(document.querySelector('.page'),'.sec-h,.reqs','.opts,.go');
    else if(name==='garment')split(wrap,'.stage','.actions,.facts');
    else if(name==='look')split(col,'.stage','.picrow,.acts,h2,.pieces,.note');
    else if(name==='picture')split(col,'.hang','.acts,.gone,.hint,.note');
    else if(name==='editor')split(col,'.stage','.hist,.rows,.saverow,.name');
    else if(name==='swap')split(col,'.slots,.stage','.railhead,.rail,.aside,.acts');
    else if(name==='purchase')split(col,'.hero','.title,.store,.price,h2,.soft,.btns,.nobuy');
    else if(name==='chat')split(document.querySelector('.sheet'),'.strip','.convo');
    else if(name==='export') {
      var kids=Array.from(col.children), pivot=kids.findIndex(function(n){return n.matches('h2')&&n.textContent.indexOf('Prompt')>=0;});
      kids.forEach(function(n,i){if(i>=pivot&&pivot>=0)n.classList.add('tablet-export-right');});
      split(col,'.paper','.tablet-export-right');
    }
    else if(name==='findone') {
      split(document.getElementById('opt-a'),'.stage','.gap,.gaprow,.gapcap,.lookrow,.pager,.why,.grid4,.fine,.next');
      split(document.getElementById('opt-b'),'.minibundle,.minicap','.alts,.btns,.next,.swaph,.swapsub');
    }
    else if(name==='handoff')split(col,'.scene,.dest,.left','.back-card');
    else if(name==='results')split(document.getElementById('looks'),'.stage','.head,.why,.hintrow,.grid4,.fine,.state');
    else if(name==='garment-edit') {
      split(document.getElementById('s-choose'),'.rail','.opts');
      split(document.getElementById('s-processing'),'.ph','.meter-wrap,.caption,.acts');
      split(document.getElementById('s-review'),'.pair','.caption,.acts');
      split(document.getElementById('s-details'),'.thumbrow','.field,.cats,.acts,.hint');
    }
  }
  function centerPanes() {
    var changed=false;
    containers.forEach(function(panes){
      var top=panes.getBoundingClientRect().top+window.scrollY;
      var available=Math.max(0,window.innerHeight-top-110);
      var height=Math.max.apply(null,Array.from(panes.children).map(function(n){return n.getBoundingClientRect().height;}));
      var fits=height<=available;
      var nextHeight=fits?available+'px':'';
      if(panes.classList.contains('tablet-centered')!==fits||panes.style.minHeight!==nextHeight)changed=true;
      panes.classList.toggle('tablet-centered',fits);
      panes.style.minHeight=nextHeight;
    });
    var screen=document.querySelector('.screen'),scene=screen&&screen.querySelector(':scope > .scene'),details=screen&&screen.querySelector(':scope > .col');
    if(media.matches&&scene&&details){
      var css=getComputedStyle(screen),space=innerHeight-parseFloat(css.paddingTop)-parseFloat(css.paddingBottom);
      var fits=Math.max(scene.getBoundingClientRect().height,details.getBoundingClientRect().height)<=space;
      if(screen.classList.contains('tablet-direct-centered')!==fits)changed=true;
      screen.classList.toggle('tablet-direct-centered',fits);
    }else if(screen)screen.classList.remove('tablet-direct-centered');
    if(changed)document.dispatchEvent(new Event('tablet-layout-change'));
  }
  var observer=new ResizeObserver(centerPanes);
  function update(){layout();containers.forEach(function(p){Array.from(p.children).forEach(function(n){observer.observe(n);});});var screen=document.querySelector('.screen');if(screen)Array.from(screen.children).forEach(function(n){observer.observe(n);});centerPanes();}
  update();media.addEventListener('change',function(){observer.disconnect();update();});
  window.addEventListener('resize',centerPanes);
})();
