// Same approved HTML/Playwright rendering method as the iPhone/iPad set.
// Captures and rendered assets stay outside Git on the Music volume.
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const { chromium } = await import(process.env.PLAYWRIGHT ?? 'playwright');
const here = dirname(fileURLToPath(import.meta.url));
const captures = resolve(process.argv[2] ?? '/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/raw');
const output = resolve(process.argv[3] ?? '/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/duo');
const icon = resolve(here, '../../../mobile/Assets.xcassets/AppIcon.appiconset/AppIcon.png');
const release = join(output, 'release/en-US');
mkdirSync(release, {recursive:true});
const url = new URL(pathToFileURL(join(here, 'layouts.html')));
url.searchParams.set('sources', pathToFileURL(captures).href);
url.searchParams.set('icon', pathToFileURL(icon).href);
const browser = await chromium.launch();
const page = await browser.newPage({viewport:{width:2853,height:2007},deviceScaleFactor:1});
const errors=[];page.on('pageerror', e=>errors.push(String(e)));
const names=['music','studio','style','radio','export','free'];
const manifest=[];
for(const [index,name] of names.entries()){
 url.searchParams.set('slide',index+1);
 await page.goto(url.href);
 await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
 await page.evaluate(()=>document.fonts.ready);
 const layout=await page.evaluate(()=>{
  const copy=document.querySelector('.copy');const r=copy.getBoundingClientRect();
  if(r.bottom>595)throw Error('Marketing copy overlaps devices: '+r.bottom);
  if(copy.scrollWidth>copy.clientWidth)throw Error('Copy overflows');
  return {copyBottom:r.bottom,title:document.querySelector('h1').textContent};
 });
 const file=`duo-${String(index+1).padStart(2,'0')}-${name}.png`;
 await page.screenshot({path:join(release,file),clip:{x:0,y:0,width:2853,height:2007},omitBackground:false});
 manifest.push({file,width:2853,height:2007,bytes:readFileSync(join(release,file)).length,sha256:createHash('sha256').update(readFileSync(join(release,file))).digest('hex'),...layout});
 console.log(file);
}
url.searchParams.delete('slide');url.searchParams.set('review','1');
await page.setViewportSize({width:2300,height:1500});await page.goto(url.href);
await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
await page.locator('#overview').screenshot({path:join(output,'duo-contact-sheet.png')});
const sourceNames=['inner-fullscreen','inner-studio','inner-style','inner-radio','inner-export','inner-library'];
const sources=sourceNames.map(n=>{const file='duo-'+n+'.png';return {file,sha256:createHash('sha256').update(readFileSync(join(captures,file))).digest('hex')};});
if(errors.length)throw Error(errors.join('\n'));
writeFileSync(join(output,'manifest.json'),JSON.stringify({appVersion:'1.2',appBuild:'8',renderedAt:new Date().toISOString(),renderer:'Playwright Chromium, real simulator captures',sources,slides:manifest},null,2)+'\n');
await browser.close();
