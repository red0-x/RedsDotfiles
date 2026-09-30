// Steam rice recolor. Steam hardcodes its colors, so instead of a static theme
// this rewrites the client's live stylesheets: Steam's dark navy surfaces become
// the matugen surface tone, and Steam blue becomes the matugen primary.
// Talks to Steam's localhost-only CEF debug port (enabled by the file
// ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/.cef-enable-remote-debugging).
// Re-reads ~/.config/steam-glass/palette.json (written by matugen) every tick.
import { readFileSync } from 'node:fs';
const PAL = process.env.HOME + '/.config/steam-glass/palette.json';
const PORT = 8080;
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Runs inside each Steam page. P = palette. Idempotent: keeps original values
// on each rule so palette changes recolor from the source, not from last pass.
const PAGE_FN = function (P) {
  const key = 'v2:' + JSON.stringify(P); // bump version when mapping logic changes
  const hsl = ([r, g, b]) => {
    r /= 255; g /= 255; b /= 255;
    const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn;
    if (!d) return [0, 0, l];
    const s = d / (1 - Math.abs(2 * l - 1));
    let h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
    return [(h * 60 + 360) % 360, s, l];
  };
  const rgb = (h, s, l) => {
    const c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2;
    const [r, g, b] = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
    return [r + m, g + m, b + m].map(v => Math.round(v * 255));
  };
  const [sh, ss] = hsl(P.surface);
  const [ph, ps, pl] = hsl(P.primary);
  // Dark surfaces become see-through tinted glass. Alpha scales with how
  // light the original was, so Steam's layering (darker = further back) survives.
  const glassA = (l, a) => {
    const base = Math.max(0.12, Math.min(0.5, 0.14 + l * 1.4));
    return +(base * (a == null ? 1 : +a)).toFixed(3);
  };
  const map = (r, g, b, a, prop) => {
    const [h, s, l] = hsl([r, g, b]);
    let out = null;
    const isBg = /background|box-shadow/.test(prop || '');
    if (h >= 190 && h <= 235 && s >= 0.55 && l >= 0.3 && l <= 0.75) {
      out = rgb(ph, ps, Math.min(0.85, pl + (l - 0.55) * 0.5));        // Steam blue -> primary
    } else if (l < 0.3 && ((h >= 180 && h <= 250 && s < 0.6 && s > 0.05) || (isBg && s <= 0.05))) {
      out = rgb(sh, Math.min(ss, 0.35), l);                            // navy/black surfaces -> surface tint
      if (isBg) return `rgba(${out.join(', ')}, ${glassA(l, a)})`;     // ...as glass
    }
    if (!out) return null;
    return a == null ? `rgb(${out.join(', ')})` : `rgba(${out.join(', ')}, ${a})`;
  };
  const RE = /rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)(?:[,\s/]+([\d.]+))?\s*\)|#([0-9a-fA-F]{6})\b/g;
  const recolor = (v, prop) => v.replace(RE, (m, r, g, b, a, hex) => {
    if (hex) { r = parseInt(hex.slice(0, 2), 16); g = parseInt(hex.slice(2, 4), 16); b = parseInt(hex.slice(4), 16); }
    return map(+r, +g, +b, a, prop) || m;
  });
  const walk = rules => {
    for (const r of rules) {
      if (r.cssRules && !r.style) { walk(r.cssRules); continue; }
      if (!r.style) continue;
      if (!r.__rice) {
        const orig = [];
        for (let i = 0; i < r.style.length; i++) {
          const p = r.style[i], v = r.style.getPropertyValue(p);
          if (/rgb|#[0-9a-fA-F]{6}/.test(v)) orig.push([p, v, r.style.getPropertyPriority(p)]);
        }
        r.__rice = { orig, key: null };
      }
      if (r.__rice.key === key) continue;
      for (const [p, v, pr] of r.__rice.orig) {
        const nv = recolor(v, p);
        if (nv !== v || r.__rice.key) r.style.setProperty(p, nv, pr);
      }
      r.__rice.key = key;
    }
  };
  for (const ss of document.styleSheets) { try { walk(ss.cssRules); } catch {} }

  // Discord Translucence-style glass layer, on top of the recolor.
  const [pr_, pg_, pb_] = P.primary, [or_, og_, ob_] = P.on_primary, [sr, sg, sb] = P.surface;
  const css = `
  :root {
    --rice-accent: rgb(${pr_}, ${pg_}, ${pb_});
    --rice-on-accent: rgb(${or_}, ${og_}, ${ob_});
    --rice-frame: rgba(${sr}, ${sg}, ${sb}, 0.34);
    --rice-card: hsl(0 0% 100% / 0.07);
    --rice-card-hover: hsl(0 0% 100% / 0.12);
    --lx: calc(cos(40deg) * -1.414); --ly: calc(sin(40deg) * -1.414);
    --liquid-glass-shadow:
      inset 0 0 0 1px color-mix(in srgb, #fff 3%, transparent),
      inset calc(1.8px * var(--lx)) calc(3px * var(--ly)) 0px -2px color-mix(in srgb, #fff 27%, transparent),
      inset calc(-2px * var(--lx)) calc(-2px * var(--ly)) 0px -2px color-mix(in srgb, #fff 24%, transparent),
      inset calc(-0.3px * var(--lx)) calc(-1px * var(--ly)) 4px 0px color-mix(in srgb, #000 24%, transparent),
      inset calc(-1.5px * var(--lx)) calc(2.5px * var(--ly)) 0px -2px color-mix(in srgb, #000 40%, transparent);
    --popout-shadow-border: inset 0 1px 1px hsl(0 100% 100% / 0.35), inset 0 -1px 2px hsl(0 0% 0% / 0.25), inset 0 0 0 1px hsl(0 100% 100% / 0.04);
  }
  html, body, #root, body > div:first-child { background: transparent !important; }
  /* outer frame: one glass sheet */
  [class*="TitleBar"], .DesktopUI > div:first-child { background: transparent !important; }
  /* popouts / menus / modals: Discord popout glass */
  .ModalOverlayContent, [class*="contextmenu"], [class*="ContextMenu"], [class*="menu_"] {
    background: hsl(0 0% 0% / 0.46) !important;
    backdrop-filter: blur(6px) saturate(150%) brightness(1.1) !important;
    border-radius: 18px !important;
    box-shadow: var(--popout-shadow-border), 0 20px 40px hsl(0 0% 0% / 0.44) !important;
  }
  /* buttons: glass pills, primary uses the accent */
  .DialogButton { border-radius: 16px !important; box-shadow: var(--liquid-glass-shadow) !important; }
  .DialogButton:not(.Primary) { background: var(--rice-card) !important; }
  .DialogButton:not(.Primary):hover { background: var(--rice-card-hover) !important; }
  .DialogButton.Primary { background: var(--rice-accent) !important; color: var(--rice-on-accent) !important; }
  /* inputs: pill + liquid glass like Discord's textarea */
  .DialogInput, .DialogTextInputBase, input[type="text"], .DialogDropDown {
    background: hsl(0 0% 100% / 0.08) !important;
    border: none !important;
    border-radius: 14px !important;
    box-shadow: var(--liquid-glass-shadow) !important;
  }
  /* scrollbars: thin accent */
  ::-webkit-scrollbar-thumb { background: color-mix(in srgb, var(--rice-accent) 45%, transparent) !important; border-radius: 8px !important; }
  ::-webkit-scrollbar-track { background: transparent !important; }
  `;
  let st = document.getElementById('rice-glass');
  if (!st) { st = document.createElement('style'); st.id = 'rice-glass'; document.head.appendChild(st); }
  if (st.textContent !== css) st.textContent = css;
  return true;
};

async function tick() {
  const P = JSON.parse(readFileSync(PAL, 'utf8'));
  const targets = (await (await fetch(`http://127.0.0.1:${PORT}/json`)).json())
    .filter(t => t.type === 'page' && t.webSocketDebuggerUrl);
  const expr = `(${PAGE_FN.toString()})(${JSON.stringify(P)})`;
  // white shooting stars on the main Steam window only (not menus/popups)
  let stars = '';
  try { stars = readFileSync(process.env.HOME + '/.config/rice-stars/stars.js', 'utf8'); } catch {}
  await Promise.all(targets.map(t => new Promise(res => {
    const ws = new WebSocket(t.webSocketDebuggerUrl);
    const done = () => { try { ws.close(); } catch {} res(); };
    const to = setTimeout(done, 3000);
    ws.onopen = () => ws.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: t.title === 'Steam' && stars ? expr + ';' + stars : expr } }));
    ws.onmessage = () => { clearTimeout(to); done(); };
    ws.onerror = () => { clearTimeout(to); res(); };
  })));
}

let misses = 0;
while (true) {
  try { await tick(); misses = 0; } catch { if (++misses > 150) process.exit(0); } // Steam gone ~5 min: stop
  await sleep(2000);
}
