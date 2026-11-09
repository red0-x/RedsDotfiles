// Keeps ~/.config/slack-glass/slack-glass.css injected into Slack via the
// local DevTools port. Re-applies after reloads and when the CSS file changes.
import { readFileSync } from 'node:fs';
const CSS = process.env.HOME + '/.config/slack-glass/slack-glass.css';
const PORT = 9229;
const sleep = ms => new Promise(r => setTimeout(r, ms));
const js = css => `(()=>{let s=document.getElementById('rice-glass');if(!s){s=document.createElement('style');s.id='rice-glass';document.head.appendChild(s)}if(s.textContent!==${JSON.stringify(css)})s.textContent=${JSON.stringify(css)}})()`;
async function tick() {
  const pages = (await (await fetch(`http://127.0.0.1:${PORT}/json`)).json()).filter(t => t.type === 'page');
  const css = readFileSync(CSS, 'utf8');
  for (const p of pages) await new Promise(res => {
    const ws = new WebSocket(p.webSocketDebuggerUrl);
    ws.onopen = () => ws.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: js(css) } }));
    ws.onmessage = () => { ws.close(); res(); };
    ws.onerror = () => res();
  });
}
let misses = 0;
while (true) {
  try { await tick(); misses = 0; } catch { if (++misses > 60) process.exit(0); } // Slack gone for ~2 min: stop
  await sleep(2000);
}
