/**
 * @name RiceStars
 * @description White shooting stars drawn above the whole Discord UI (click-through). Same effect as Slack/Steam/Spotify/GitHub Desktop.
 * @version 1.1.0
 * @author red
 */
module.exports = class RiceStars {
  start() {
    // Rice shooting stars: white meteors on a click-through canvas above everything.
    // Shared by the Discord plugin and the Slack/Steam/Spotify injectors.
    (() => {
      if (window.__riceStars) return;
      const c = document.createElement('canvas');
      c.id = 'rice-stars';
      Object.assign(c.style, { position: 'fixed', inset: '0', width: '100vw', height: '100vh',
        pointerEvents: 'none', zIndex: '2147483647' });
      document.documentElement.appendChild(c);
      const x = c.getContext('2d');
      let W, H, dpr;
      const size = () => { dpr = devicePixelRatio || 1; W = innerWidth; H = innerHeight;
        c.width = W * dpr; c.height = H * dpr; x.setTransform(dpr, 0, 0, dpr, 0, 0); };
      size(); addEventListener('resize', size);
      const stars = [];
      const spawn = () => {
        const ang = (200 + Math.random() * 25) * Math.PI / 180;   // down-left
        stars.push({ x: W * (0.3 + Math.random() * 0.8), y: -20 + Math.random() * H * 0.45,
          vx: Math.cos(ang), vy: -Math.sin(ang), sp: 9 + Math.random() * 7,
          len: 110 + Math.random() * 120, life: 0, max: 55 + Math.random() * 35 });
      };
      let next = performance.now() + 1500, raf;
      const loop = t => {
        raf = requestAnimationFrame(loop);
        if (document.hidden) return;
        if (t > next) { spawn(); next = t + 2500 + Math.random() * 5500; }
        x.clearRect(0, 0, W, H);
        for (let i = stars.length - 1; i >= 0; i--) {
          const s = stars[i]; s.life++; s.x += s.vx * s.sp; s.y += s.vy * s.sp;
          const a = Math.sin(Math.PI * Math.min(1, s.life / s.max));
          const tx = s.x - s.vx * s.len, ty = s.y - s.vy * s.len;
          const g = x.createLinearGradient(s.x, s.y, tx, ty);
          g.addColorStop(0, `rgba(255,255,255,${a})`); g.addColorStop(1, 'rgba(255,255,255,0)');
          x.strokeStyle = g; x.lineWidth = 1.6; x.lineCap = 'round';
          x.shadowColor = `rgba(255,255,255,${a})`; x.shadowBlur = 6;
          x.beginPath(); x.moveTo(s.x, s.y); x.lineTo(tx, ty); x.stroke();
          x.fillStyle = `rgba(255,255,255,${a})`; x.beginPath(); x.arc(s.x, s.y, 1.3, 0, 7); x.fill();
          if (s.life >= s.max) stars.splice(i, 1);
        }
      };
      raf = requestAnimationFrame(loop);
      window.__riceStars = { stop() { cancelAnimationFrame(raf); c.remove(); delete window.__riceStars; } };
    })();
  }
  stop() { window.__riceStars?.stop(); }
};
