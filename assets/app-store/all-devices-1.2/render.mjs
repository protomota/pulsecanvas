// Render marketing artwork from real app captures; no app UI is recreated.
import {fileURLToPath,pathToFileURL} from 'node:url';
import {dirname,resolve,join} from 'node:path';
import {mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const {chromium}=await import(process.env.PLAYWRIGHT??'playwright');
const here=dirname(fileURLToPath(import.meta.url)),sources=resolve(process.argv[2]),out=resolve(process.argv[3]);
mkdirSync(out,{recursive:true});const url=new URL(pathToFileURL(join(here,'layout.html')));
url.searchParams.set('sources',pathToFileURL(sources).href);url.searchParams.set('icon',pathToFileURL(resolve(here,'../../../mobile/Assets.xcassets/AppIcon.appiconset/AppIcon.png')).href);
const browser=await chromium.launch(),slides=[];const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
for(const [kind,[width,height]] of Object.entries({iphone:[1320,2868],ipad:[2752,2064],duo:[2853,2007],mac:[2880,1800],vision:[3840,2160]})){
 const page=await browser.newPage({viewport:{width,height},deviceScaleFactor:1});url.searchParams.set('kind',kind);await page.goto(url.href);
 await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));await page.evaluate(()=>document.fonts.ready);
 await page.evaluate(()=>{for(const e of document.querySelectorAll('.copy,.tile,.name')){const r=e.getBoundingClientRect();if(r.left<0||r.top<0||r.right>innerWidth||r.bottom>innerHeight||e.scrollWidth>e.clientWidth+1)throw Error('Artwork overflow');}if(document.querySelector('.copy').getBoundingClientRect().bottom>document.querySelector('.devices').getBoundingClientRect().top-20)throw Error('Copy overlaps devices');});
 const file=`${kind}-all-devices.png`,path=join(out,file);await page.screenshot({path,omitBackground:false});slides.push({file,width,height,sha256:hash(path)});await page.close();console.log(file);
}
await browser.close();const captures=['iphone-studio.png','ipad-studio.png','mac-studio.png','vision-studio.png','duo-closed-studio.png'].map(file=>({file,sha256:hash(join(sources,file))}));
writeFileSync(join(out,'manifest.json'),JSON.stringify({renderedAt:new Date().toISOString(),captures,slides},null,2)+'\n');
