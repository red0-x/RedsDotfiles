// Rice glass CSS injector for Electron apps (Slack, GitHub Desktop).
// Usage: node inject.mjs <port> <css-file> [stars]
// Keeps <css-file> injected into every page on the app's localhost-only
// DevTools port, re-applying after reloads and whenever the file changes
// (matugen rewrites it on wallpaper change). With "stars", also runs the
// shared white shooting-star overlay (~/.config/rice-stars/stars.js).
import { readFileSync, existsSync } from 'node:fs';
const [, , PORT = '9229', CSS, STARS] = process.argv;
const STAR_JS = process.env.HOME + '/.config/rice-stars/stars.js';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const js = (css, stars) => `(()=>{
  let s=document.getElementById('rice-glass');
  if(!s){s=document.createElement('style');s.id='rice-glass';document.head.appendChild(s)}
  if(s.textContent!==${JSON.stringify(css)})s.textContent=${JSON.stringify(css)};
  ${stars ? stars : ''}
})()`;
async function tick() {
  const pages = (await (await fetch(`http://127.0.0.1:${PORT}/json`)).json()).filter(t => t.type === 'page');
  const css = readFileSync(CSS, 'utf8');
  const stars = STARS && existsSync(STAR_JS) ? readFileSync(STAR_JS, 'utf8') : '';
  for (const p of pages) await new Promise(res => {
    const ws = new WebSocket(p.webSocketDebuggerUrl);
    const to = setTimeout(() => { try { ws.close(); } catch {} res(); }, 3000);
    ws.onopen = () => ws.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: js(css, stars) } }));
    ws.onmessage = () => { clearTimeout(to); ws.close(); res(); };
    ws.onerror = () => { clearTimeout(to); res(); };
  });
}
while (true) {
  try { await tick(); } catch {}
  await sleep(2000);
}
