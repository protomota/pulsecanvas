// Real 1.2 simulator captures, approved mobile marketing templates.
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const { chromium } = await import(process.env.PLAYWRIGHT ?? 'playwright');
const here=dirname(fileURLToPath(import.meta.url));
const captures=resolve(process.argv[2]);const output=resolve(process.argv[3]);
const release=join(output,'release/en-US');mkdirSync(release,{recursive:true});
const url=new URL(pathToFileURL(join(here,'layouts.html')));
url.searchParams.set('sources',pathToFileURL(captures).href);
url.searchParams.set('icon',pathToFileURL(resolve(here,'../../../mobile/Assets.xcassets/AppIcon.appiconset/AppIcon.png')).href);
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
const browser=await chromium.launch();const errors=[];const slides=[];const sources=[];
for(const [device,[width,height]] of Object.entries({iphone:[1320,2868],ipad:[2752,2064]})){
 const page=await browser.newPage({viewport:{width,height},deviceScaleFactor:1});
 page.on('pageerror',e=>errors.push(String(e)));url.searchParams.set('device',device);
 for(const [i,name] of ['music','studio','style','radio','export','free'].entries()){
  url.searchParams.set('slide',i+1);url.searchParams.delete('review');
  await page.goto(url.href);await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));await page.evaluate(()=>document.fonts.ready);
  const file=`${device}-${String(i+1).padStart(2,'0')}-${name}.png`;const path=join(release,file);
  await page.screenshot({path,clip:{x:0,y:0,width,height},omitBackground:false});
  slides.push({file,width,height,bytes:readFileSync(path).length,sha256:hash(path)});console.log(file);
 }
 url.searchParams.delete('slide');url.searchParams.set('review','1');await page.setViewportSize({width:2400,height:1800});await page.goto(url.href);
 await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));await page.locator('#overview').screenshot({path:join(output,device+'-contact-sheet.png')});
 for(const name of ['studio','fullscreen','style','radio','library','export']){const file=device+'-'+name+'.png';sources.push({file,sha256:hash(join(captures,file))});}
 await page.close();
}
await browser.close();if(errors.length)throw Error(errors.join('\n'));
writeFileSync(join(output,'manifest.json'),JSON.stringify({appVersion:'1.2',appBuild:'8',renderedAt:new Date().toISOString(),sources,slides},null,2)+'\n');
