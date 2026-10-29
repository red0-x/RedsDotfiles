const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function load() {
  let now = 0, nextId = 1, clears = 0;
  const timers = new Map(), frames = new Map();
  const canvas = {
    style: {},
    getContext: () => ({
      setTransform() {}, clearRect() { clears++; },
      createLinearGradient: () => ({ addColorStop() {} }),
      beginPath() {}, moveTo() {}, lineTo() {}, stroke() {}, arc() {}, fill() {}
    }),
    remove() { this.removed = true; }
  };
  const context = {
    document: { hidden: false, createElement: () => canvas, documentElement: { appendChild() {} } },
    innerWidth: 800, innerHeight: 600, devicePixelRatio: 1,
    addEventListener() {},
    performance: { now: () => now },
    setTimeout(fn, delay) { const id = nextId++; timers.set(id, { fn, delay }); return id; },
    clearTimeout(id) { timers.delete(id); },
    requestAnimationFrame(fn) { const id = nextId++; frames.set(id, fn); return id; },
    cancelAnimationFrame(id) { frames.delete(id); }
  };
  context.window = context;
  vm.runInNewContext(fs.readFileSync(__dirname + '/stars.js', 'utf8'), context);
  function fireTimer() {
    const [id, timer] = timers.entries().next().value;
    timers.delete(id); now += timer.delay + 1; timer.fn();
  }
  function fireFrame() {
    const [id, frame] = frames.entries().next().value;
    frames.delete(id); now += 16; frame(now);
  }
  return { context, canvas, timers, frames, fireTimer, fireFrame, clears: () => clears };
}

const app = load();
assert.equal(app.frames.size, 0, 'idle overlay must not request animation frames');
assert.equal(app.timers.size, 1, 'idle overlay sleeps until the next meteor');
assert.equal(app.clears(), 0, 'idle overlay must not clear the canvas');
app.fireTimer();
app.fireFrame();
assert.equal(app.clears(), 1, 'visible meteor draws');
assert.equal(app.frames.size, 1, 'visible meteor animates');
for (let i = 0; i < 100 && app.frames.size; i++) app.fireFrame();
assert.equal(app.frames.size, 0, 'animation stops when the meteor ends');
assert.equal(app.timers.size, 1, 'idle overlay returns to sleep');
app.context.__riceStars.stop();
assert.equal(app.timers.size, 0, 'stop clears the idle timer');
assert.equal(app.canvas.removed, true, 'stop removes the canvas');
console.log('star scheduler self-check passed');
