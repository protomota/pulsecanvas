// Renders the search-results image and the looping header animation.
// Usage: PLAYWRIGHT=/path/to/playwright/index.mjs node render-header.mjs [stills|video] [header|header-dark]
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdirSync, rmSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const { chromium } = await import(process.env.PLAYWRIGHT ?? 'playwright');
const here = dirname(fileURLToPath(import.meta.url));
const mode = process.argv[2] ?? 'stills';
const variant = process.argv[3] ?? 'header'; // header (light) or header-dark
const suffix = variant === 'header' ? '' : '-' + variant.replace('header-', '');
const fps = 30, loop = 12;
const out = join(here, 'release', 'en-US');
mkdirSync(out, { recursive: true });
const browser = await chromium.launch();

const search = await browser.newPage({ viewport: { width: 3840, height: 2560 } });
await search.goto(pathToFileURL(join(here, 'search.html')).href);
await search.evaluate(() => Promise.all([...document.images].map(i => i.decode())));
await search.screenshot({ path: join(out, 'search-results-3840x2560.png') });

const page = await browser.newPage({ viewport: { width: 3840, height: 1646 } });
await page.goto(pathToFileURL(join(here, variant + '.html')).href + `?loop=${loop}`);
await page.evaluate(() => Promise.all([...document.images].map(i => i.decode())));
if (mode === 'stills') {
  for (const t of [0, 4, 8]) { await page.evaluate(t => render(t), t); await page.screenshot({ path: join(here, `${variant}-t${t}.png`) }); }
} else {
  const frames = join(here, '.header-frames');
  rmSync(frames, { recursive: true, force: true }); mkdirSync(frames, { recursive: true });
  for (let i = 0; i < fps * loop; i++) {
    await page.evaluate(t => render(t), i / fps);
    await page.screenshot({ path: join(frames, String(i).padStart(4, '0') + '.png') });
  }
  execFileSync('ffmpeg', ['-v', 'error', '-y', '-framerate', String(fps), '-i', join(frames, '%04d.png'), '-c:v', 'libx264', '-profile:v', 'high', '-crf', '14', '-preset', 'slow', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an', join(out, `header-animated${suffix}-3840x1646.mp4`)]);
  rmSync(frames, { recursive: true, force: true });
}
await browser.close();
