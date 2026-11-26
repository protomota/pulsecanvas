// Renders layouts.html to App Store PNGs and contact sheets.
// Usage: PLAYWRIGHT=/path/to/node_modules/playwright/index.mjs node render.mjs
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdirSync } from 'node:fs';

const { chromium } = await import(process.env.PLAYWRIGHT ?? 'playwright');
const here = dirname(fileURLToPath(import.meta.url));
const page_url = pathToFileURL(join(here, 'layouts.html')).href;
const devices = { iphone: [1320, 2868], ipad: [2752, 2064] };
const names = ['music', 'studio', 'style', 'radio', 'export', 'free'];
const out = join(here, 'release', 'en-US');
mkdirSync(out, { recursive: true });

const browser = await chromium.launch();
for (const [device, [width, height]] of Object.entries(devices)) {
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  for (const [index, name] of names.entries()) {
    await page.goto(`${page_url}?device=${device}&slide=${index + 1}`);
    await page.evaluate(() => Promise.all([...document.images].map(i => i.decode())));
    const file = join(out, `${device}-${String(index + 1).padStart(2, '0')}-${name}.png`);
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width, height }, omitBackground: false });
    console.log(file);
  }
  await page.setViewportSize({ width: 2400, height: 1800 });
  await page.goto(`${page_url}?device=${device}&review=1`);
  await page.evaluate(() => Promise.all([...document.images].map(i => i.decode())));
  await page.locator('#overview').screenshot({ path: join(here, `${device}-contact-sheet.png`) });
  await page.close();
}
await browser.close();
