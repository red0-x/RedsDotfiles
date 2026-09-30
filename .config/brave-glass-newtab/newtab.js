const t = document.getElementById('time'), d = document.getElementById('date');
const tick = () => {
  const n = new Date();
  t.textContent = n.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  d.textContent = n.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' });
};
tick(); setInterval(tick, 1000);
