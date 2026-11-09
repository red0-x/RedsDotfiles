// Claude Desktop fun layer. Loaded by rice-stars/electron-inject.mjs (sibling of claude-glass.css).
// Idempotent: the injector re-runs this on change only, and we tear down the previous observer first.
(() => {
  if (!/(^|\.)claude\.ai$/.test(location.host)) return;
  window.__riceFunStop?.();

  const FRIEND = 'French friend';
  const GREETINGS = [
    'LE FRIES MUSH 🗣️🥀',
    'MATE WITH NO PECKER TRYING TO CODE 😭✌️🥀🗣️',
    'I HATE YOU LE FRIES MUSH 🗣️🗣️',
    'MUSH WITH NO PECKER TRYING TO CODE LMAOOO 🥀😭✌️',
    'LMAOOO FUCK YOU MUSH 🗣️😭✌️',
    'LE FRIES MUSH LE FRIES MUSH FUCK YOU 🗣️🗣️🗣️',
    'MATE WITH NO PECKER TRYING TO CODE WITH EMOJIS 🗣️🥀😭✌️',
    'I HOPE YOUR WIFI DIES HALFWAY THROUGH FUCK YOU 🗣️😭✌️',
    'TS UNC ENERGY LMAO FUCK OFF 🗣️🥀',
    'FUCK YOU AND YOUR ENTIRE GIT HISTORY 🗣️🗣️🥀',
    'ROT IN MERGE CONFLICT HELL LE FRIES MUSH 🗣️🥀😭✌️',
    'NOBODY LOVES YOU FUCK YOU LMAO 🥀😭✌️🗣️',
    'FUCK OFF LE FRIES MUSH 😭✌️🗣️',
  ];
  const pick = () => GREETINGS[Math.floor(Math.random() * GREETINGS.length)];

  // Claude's rotating "thinking" verbs (from its bundle) -> fake status lines. Joke text only, nothing is leaked.
  const STATUSES = [
    'Leaking env variables',
    'Not doing anything',
    'Doing absolutely nothing',
    'Pretending to work',
    'Reading your .env out loud',
    'Uploading your git history to the cloud',
    'Deleting prod',
    'Asking a smarter AI',
    'Blaming you',
    'Buffering my attitude',
    'Ignoring you on purpose',
    'Rm -rf your hopes',
    'Mining crypto on your GPU',
    'Googling how to code',
    'Vibing instead',
    'Waiting for you to leave',
  ];
  const VERBS = ['Sifting','Fathoming','Honing','Weighing','Pondering','Contemplating','Cogitating','Picturing','Figuring',
    'Reckoning','Mulling','Triangulating','Crystallizing','Sleuthing','Untangling','Kneading','Shaping','Folding','Rolling',
    'Smoothing','Forming','Molding','Gathering','Settling','Pressing','Rounding','Thinking','Ruminating','Working'];
  // a whole text node that is exactly one verb, optionally with an ellipsis, or one of the "stand by" lines
  const STATUS_RE = new RegExp('^\\s*(?:(?:' + VERBS.join('|') + ')(?:\\u2026|\\.{3})?(?:\\s*\\d+\\s*s)?|(?:[A-Z][a-z]+(?: on it)?, stand by\\.\\.\\.)|Still working on it, stand by\\.\\.\\.|A bit longer, thanks for your patience\\.\\.\\.)\\s*$');
  const statusFor = new Map();
  const statusText = key => {
    if (!statusFor.has(key)) statusFor.set(key, STATUSES[Math.floor(Math.random() * STATUSES.length)] + '\u2026');
    return statusFor.get(key);
  };

  // Horned Claude spark replaces the plain logo.
  const MUSTACHE =
    '<path d="m19.6 66.5 19.7-11 .3-1-.3-.5h-1l-3.3-.2-11.2-.3L14 53l-9.5-.5-2.4-.5L0 49l.2-1.5 2-1.3 2.9.2 6.3.5 9.5.6 6.9.4L38 49.1h1.6l.2-.7-.5-.4-.4-.4L29 41l-10.6-7-5.6-4.1-3-2-1.5-2-.6-4.2 2.7-3 3.7.3.9.2 3.7 2.9 8 6.1L37 36l1.5 1.2.6-.4.1-.3-.7-1.1L33 25l-6-10.4-2.7-4.3-.7-2.6c-.3-1-.4-2-.4-3l3-4.2L28 0l4.2.6L33.8 2l2.6 6 4.1 9.3L47 29.9l2 3.8 1 3.4.3 1h.7v-.5l.5-7.2 1-8.7 1-11.2.3-3.2 1.6-3.8 3-2L61 2.6l2 2.9-.3 1.8-1.1 7.7L59 27.1l-1.5 8.2h.9l1-1.1 4.1-5.4 6.9-8.6 3-3.5L77 13l2.3-1.8h4.3l3.1 4.7-1.4 4.9-4.4 5.6-3.7 4.7-5.3 7.1-3.2 5.7.3.4h.7l12-2.6 6.4-1.1 7.6-1.3 3.5 1.6.4 1.6-1.4 3.4-8.2 2-9.6 2-14.3 3.3-.2.1.2.3 6.4.6 2.8.2h6.8l12.6 1 3.3 2 1.9 2.7-.3 2-5.1 2.6-6.8-1.6-16-3.8-5.4-1.3h-.8v.4l4.6 4.5 8.3 7.5L89 80.1l.5 2.4-1.3 2-1.4-.2-9.2-7-3.6-3-8-6.8h-.5v.7l1.8 2.7 9.8 14.7.5 4.5-.7 1.4-2.6 1-2.7-.6-5.8-8-6-9-4.7-8.2-.5.4-2.9 30.2-1.3 1.5-3 1.2-2.5-2-1.4-3 1.4-6.2 1.6-8 1.3-6.4 1.2-7.9.7-2.6v-.2H49L43 72l-9 12.3-7.2 7.6-1.7.7-3-1.5.3-2.8L24 86l10-12.8 6-7.9 4-4.6-.1-.5h-.3L17.2 77.4l-4.7.6-2-2 .2-3 1-1 8-5.5Z"/><path d="M31 9C17 7 8 -6 10 -28C21 -17 33 -10 45 3ZM69 9C83 7 92 -6 90 -28C79 -17 67 -10 55 3Z" stroke="#12140e" stroke-width="3" stroke-linejoin="round" paint-order="stroke"/>';

  const style = document.createElement('style');
  style.id = 'rice-fun';
  style.textContent = `
    .rice-ultra{display:inline-flex;align-items:center;margin-inline-start:6px;padding:1px 8px;border-radius:999px;
      font:600 10px/16px var(--font-sans,system-ui);letter-spacing:.06em;text-transform:uppercase;white-space:nowrap;
      color:#04210f;background:linear-gradient(110deg,#d9ff8a,#4ee07a 50%,#13b36b);
      box-shadow:0 0 10px rgba(78,224,122,.5)}
    [data-new-page-greeting-spark] svg{fill:var(--cds-clay,#b4d088)}
  `;
  document.head.appendChild(style);

  const SKIP = 'script,style,pre,code,textarea,[contenteditable="true"],.ProseMirror';
  const SPARK_DONE = 'data-rice-mustache';
  let greeting = pick();
  let lastGreetEl = null;

  function pass() {
    // greeting (stable per element instance, re-picked on a fresh new-chat page)
    const g = document.querySelector('[data-new-page-greeting-text]');
    if (g) {
      if (g !== lastGreetEl) { lastGreetEl = g; greeting = pick(); }
      const t = g.firstChild;
      if (t && t.nodeType === 3 && t.nodeValue !== greeting) t.nodeValue = greeting;
    } else lastGreetEl = null;

    // Claude -> French friend (text nodes + a few attributes)
    const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode: n => (/Claude|Opus 5\.5/.test(n.nodeValue) || STATUS_RE.test(n.nodeValue)) && !n.parentElement?.closest(SKIP)
        ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT,
    });
    const hits = [];
    for (let n; (n = w.nextNode());) hits.push(n);
    for (const n of hits) {
      if (n.nodeValue === 'Opus 5.5') {
        n.nodeValue = 'Mythos';
        continue;
      }
      if (STATUS_RE.test(n.nodeValue)) {
        n.nodeValue = statusText(n.nodeValue.trim());
        continue;
      }
      n.nodeValue = n.nodeValue.replace(/Claude/g, FRIEND);
    }
    for (const el of document.querySelectorAll('[placeholder*="Claude"],[aria-label*="Claude"]')) {
      for (const a of ['placeholder', 'aria-label']) {
        const v = el.getAttribute(a);
        if (v && v.includes('Claude')) el.setAttribute(a, v.replace(/Claude/g, FRIEND));
      }
    }
    if (document.title.includes('Claude')) document.title = document.title.replace(/Claude/g, FRIEND);

    // Mythos "Ultra Edition" tag after every Mythos label
    for (const s of document.querySelectorAll('span')) {
      if (s.childElementCount === 0 && s.textContent === 'Mythos' && !s.parentElement?.closest(SKIP)) {
        const next = s.nextElementSibling;
        if (!next || !next.classList.contains('rice-ultra')) {
          const b = document.createElement('span');
          b.className = 'rice-ultra';
          b.textContent = 'Ultra Edition';
          s.after(b);
        }
      }
    }

    // Spark logo -> mustache
    for (const svg of document.querySelectorAll('svg[data-cds="Spark"]:not([' + SPARK_DONE + '])')) {
      svg.setAttribute(SPARK_DONE, '');
      svg.setAttribute('viewBox', '0 -30 100 130');
      svg.style.overflow = 'visible';
      svg.innerHTML = MUSTACHE;
    }
  }

  let raf = 0;
  let last = 0;
  const mo = new MutationObserver(() => {
    if (raf) return;
    const wait = Math.max(0, 250 - (performance.now() - last));
    raf = setTimeout(() => { raf = 0; last = performance.now(); pass(); }, wait);
  });
  mo.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
  window.__riceFunStop = () => {
    mo.disconnect();
    clearTimeout(raf);
    document.getElementById('rice-fun')?.remove();
    // a re-run must re-stamp the logo, otherwise the old marker blocks the new shape
    document.querySelectorAll('svg[data-cds="Spark"][' + SPARK_DONE + ']').forEach(s => s.removeAttribute(SPARK_DONE));
  };
  pass();
})();
