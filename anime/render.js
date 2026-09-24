const {chromium}=require('playwright');(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:640,height:360}});await p.goto('file://'+__dirname+'/anime.html');
for(let i=0;i<96;i++){await p.evaluate(t=>R(t),i/12);await p.screenshot({path:`${__dirname}/fr/${String(i).padStart(3,'0')}.png`})}await b.close()})()
