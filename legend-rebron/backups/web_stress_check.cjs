const http=require('http'),fs=require('fs'),path=require('path');
const {chromium}=require(process.env.LEGEND_PLAYWRIGHT);
const root=process.env.LEGEND_WEB_ROOT,out=process.env.LEGEND_WEB_OUTPUT,logs=[];
const server=http.createServer((req,res)=>{
 const name=decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/,'')||'index.html';
 const file=path.resolve(root,name);
 if(name==='favicon.ico'){res.writeHead(204);res.end();return;}
 if(!file.startsWith(path.resolve(root)+path.sep)||!fs.existsSync(file)){res.writeHead(404);res.end();return;}
 res.setHeader('Content-Type',{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png'}[path.extname(file)]||'application/octet-stream');
 if(name==='index.html'){res.end(fs.readFileSync(file,'utf8'));return;}
 fs.createReadStream(file).pipe(res);
});
(async()=>{
 let browser;
 try{
  await new Promise(resolve=>server.listen(8769,'127.0.0.1',resolve));
  browser=await chromium.launch({headless:true,channel:"chromium",args:["--enable-gpu","--use-angle=d3d11","--ignore-gpu-blocklist"]});
  const cdp=await browser.newBrowserCDPSession(); const system=await cdp.send('SystemInfo.getInfo'); console.log('WEB_GPU '+JSON.stringify(system.gpu.auxAttributes));
  const page=await browser.newPage({viewport:{width:1280,height:720}});
  const done=new Promise((resolve,reject)=>{
   const timer=setTimeout(()=>reject(new Error('Stress test timeout')),90000);
   page.on('console',message=>{
    const text=message.type()+': '+message.text();logs.push(text); if(text.includes('WEB_VALIDATION') || message.type()==='error') console.log(text);
    if(text.includes('WEB_VALIDATION_DONE')){clearTimeout(timer);resolve(text);}
   });
   page.on('pageerror',error=>logs.push('PAGE ERROR: '+error.message));
  });
  await page.goto('http://127.0.0.1:8769/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>!document.querySelector('#status'),{},{timeout:30000});
  await page.mouse.click(640,360);
  console.log(await done);
  await page.screenshot({path:path.join(out,'web_stress_160.png')});
  const errors=logs.filter(line=>line.startsWith('error:')||line.startsWith('PAGE ERROR:'));
  if(errors.length) throw new Error(errors.join('\n'));
  console.log('PASS: 160 mixed enemies, 4 sustained tornadoes, repeated LV5 fireballs and Explosion on Chromium WebGL2');
 }catch(e){console.log('TEST ERROR: '+e.message);process.exitCode=1;}
 finally{fs.writeFileSync(path.join(out,'web_stress_console.log'),logs.join('\n'));if(browser)await browser.close();server.close();}
})();