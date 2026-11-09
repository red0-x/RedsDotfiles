// Disable Claude Desktop's command-line debug-switch guard in a user-owned
// app.asar copy. The system package refuses --remote-debugging-port, which the
// rice glass injector needs. Same-length replacement keeps asar offsets intact.
import { readFileSync, writeFileSync } from 'node:fs';

const file = process.argv[2] ||
  `${process.env.HOME}/.local/share/claude-desktop/resources/app.asar`;
const buf = readFileSync(file);
const old = Buffer.from('e6(process.argv)&&!l6()', 'utf8');
const replacement = Buffer.from('false&&false&&false    ', 'utf8');
if (old.length !== replacement.length) throw new Error('guard patch length changed');

let count = 0;
let at = 0;
while ((at = buf.indexOf(old, at)) !== -1) {
  count += 1;
  at += old.length;
}
if (count !== 1) {
  console.error(`expected 1 guard occurrence, found ${count}; refusing to patch`);
  process.exit(1);
}
at = buf.indexOf(old);
replacement.copy(buf, at);
writeFileSync(file, buf);
console.log(`patched ${file} at byte ${at}`);
