(() => {
  const stage   = document.getElementById('stage');
  const viewport= document.getElementById('viewport');
  const slides  = [...document.querySelectorAll('.slide')];
  const hint    = document.getElementById('hint');
  const progress= createProgress();

  function createProgress(){
    const p = document.createElement('div'); p.id='progress'; stage.appendChild(p); return p;
  }

  let i = 0;

  /* Reveal choreography. The stagger index feeding --i in deck.css is derived
     from document order within each slide, so adding or reordering an element
     renumbers everything after it automatically. Mark an element
     data-reveal="with-prev" to land it in sync with the one before it rather
     than a beat later — that is how a .sc-head badge rides in with its title. */
  function choreograph(){
    slides.forEach(slide => {
      let step = -1;
      slide.querySelectorAll('[data-reveal]').forEach((el, idx) => {
        if (idx === 0 || el.dataset.reveal !== 'with-prev') step++;
        el.style.setProperty('--i', step);
      });
    });
  }

  function fit(){
    const scale = Math.min(window.innerWidth / stage.offsetWidth, window.innerHeight / stage.offsetHeight);
    stage.style.transform = `scale(${scale})`;
  }

  function show(n){
    i = Math.max(0, Math.min(slides.length - 1, n));
    slides.forEach((s, idx) => idx === i ? s.setAttribute('data-active','') : s.removeAttribute('data-active'));
    progress.style.width = (i / (slides.length - 1) * 100) + '%';
    location.hash = 'slide-' + (i + 1);
  }

  const next = () => show(i + 1);
  const prev = () => show(i - 1);

  addEventListener('keydown', e => {
    switch(e.key){
      case 'ArrowRight': case ' ': case 'PageDown': case 'l': case 'L': next(); e.preventDefault(); break;
      case 'ArrowLeft':  case 'PageUp':  case 'h': case 'H': prev(); e.preventDefault(); break;
      case 'Home': show(0); break;
      case 'End':  show(slides.length - 1); break;
      case 'f': case 'F':
        if (!document.fullscreenElement) document.documentElement.requestFullscreen?.();
        else document.exitFullscreen?.();
        break;
      case '?': if (hint) hint.style.opacity = hint.style.opacity === '1' ? '0' : '1'; break;
    }
  });

  viewport.addEventListener('click', e => {
    if (e.target.closest('a')) return;
    (e.clientX < window.innerWidth * 0.18) ? prev() : next();
  });

  const fromHash = parseInt((location.hash.match(/slide-(\d+)/) || [])[1], 10);
  addEventListener('resize', fit);
  choreograph();
  fit();
  show(Number.isFinite(fromHash) ? fromHash - 1 : 0);

  if (hint) {
    hint.style.opacity = '1';
    setTimeout(() => { hint.style.opacity = '0'; }, 4200);
  }
})();
