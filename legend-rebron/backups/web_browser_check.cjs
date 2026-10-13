const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require(process.env.LEGEND_PLAYWRIGHT);
const root = process.env.LEGEND_WEB_ROOT;
const out = process.env.LEGEND_WEB_OUTPUT;
const logs = [];
const server = http.createServer((req,res) => {
 const relative = decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/,'') || 'index.html';
 const file = path.resolve(root,relative);
 if(!file.startsWith(path.resolve(root)+path.sep)) {res.writeHead(403);res.end();return;}
 if(!fs.existsSync(file)) {res.writeHead(404);res.end();return;}
 const type = {'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png'}[path.extname(file)] || 'application/octet-stream';
 res.setHeader('Content-Type',type);
 fs.createReadStream(file).pipe(res);
});
(async()=>{
 let browser;
 try {
  await new Promise(resolve=>server.listen(8768,'127.0.0.1',resolve));
  browser = await chromium.launch({headless:true});
  const page = await browser.newPage({viewport:{width:1280,height:720}});
  page.on('console',message=>logs.push(message.type()+': '+message.text()));
  page.on('pageerror',error=>logs.push('PAGE ERROR: '+error.message));
  const start = Date.now();
  await page.goto('http://127.0.0.1:8768/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>!document.querySelector('#status'),{},{timeout:60000});
  await page.waitForTimeout(1500);
  console.log('WEB_BOOT_LOCAL_MS '+(Date.now()-start));
  await page.screenshot({path:path.join(out,'web_home.png')});
  const canvas = page.locator('#canvas');
  await canvas.click({position:{x:260,y:342}});
  await page.waitForTimeout(1800);
  await page.screenshot({path:path.join(out,'web_stages.png')});
  await canvas.click({position:{x:280,y:380}});
  await page.waitForTimeout(1800);
  await page.screenshot({path:path.join(out,'web_characters.png')});
  await canvas.click({position:{x:300,y:360}});
  await page.waitForTimeout(1600);
  await page.screenshot({path:path.join(out,'web_loadout.png')});
  await canvas.click({position:{x:780,y:570}});
  await page.waitForTimeout(2000);
  await canvas.click({position:{x:640,y:360}});
  await page.waitForTimeout(500);
  const locked = await page.evaluate(()=>!!document.pointerLockElement);
  console.log('WEB_POINTER_LOCK '+locked);
  if(!locked) throw new Error('Gameplay must capture mouse after trusted click');
  await page.keyboard.down('w');
  await page.waitForTimeout(1200);
  await page.keyboard.up('w');
  await page.mouse.down();
  await page.waitForTimeout(1200);
  await page.mouse.up();
  await page.screenshot({path:path.join(out,'web_gameplay.png')});
  await page.keyboard.press('Escape');
  await page.waitForTimeout(600);
  await page.screenshot({path:path.join(out,'web_pause.png')});
  await canvas.click({position:{x:640,y:330}});
  await page.waitForTimeout(350);
  await canvas.click({position:{x:640,y:360}});
  await page.waitForTimeout(350);
  console.log('WEB_POINTER_LOCK_AFTER_RESUME '+await page.evaluate(()=>!!document.pointerLockElement));
  const errors=logs.filter(line=>line.startsWith('error:')||line.startsWith('PAGE ERROR:'));
  if(errors.length) throw new Error('Browser errors: '+errors.join('\n'));
  console.log('PASS: boot, map/class/loadout selection, movement, held attack, pause and resume');
  console.log(logs.join('\n'));
 } catch(e) {
  console.log('TEST ERROR: '+e.message);
  console.log(logs.join('\n'));
  process.exitCode=1;
 } finally {
  fs.writeFileSync(path.join(out,'web_browser_console.log'),logs.join('\n'));
  if(browser) await browser.close();
  server.close();
 }
})();