const PZ={idle:{t:3,h:0,lu:-12,lf:15,ru:10,rf:20,lt:6,ls:-6,rt:-6,rs:-4,hy:0},
lookUp:{t:-8,h:-35,lu:-10,lf:10,ru:8,rf:15,lt:6,ls:-6,rt:-6,rs:-4,hy:0},
brace:{t:-10,h:15,lu:110,lf:110,ru:120,rf:100,lt:22,ls:-25,rt:-22,rs:-12,hy:-.08},
guard:{t:12,h:-5,lu:30,lf:80,ru:50,rf:60,lt:25,ls:-30,rt:-20,rs:-22,hy:-.1},
runA:{t:22,h:-5,lu:50,lf:85,ru:-45,rf:80,lt:55,ls:-60,rt:-35,rs:-85,hy:-.04},
runB:{t:22,h:-5,lu:-45,lf:80,ru:50,rf:85,lt:-35,ls:-85,rt:55,rs:-60,hy:-.04},
walkA:{t:5,h:0,lu:22,lf:20,ru:-22,rf:15,lt:24,ls:-12,rt:-20,rs:-28,hy:-.02},
walkB:{t:5,h:0,lu:-22,lf:15,ru:22,rf:20,lt:-20,ls:-28,rt:24,rs:-12,hy:-.02},
slashUp:{t:-6,h:-10,lu:40,lf:60,ru:170,rf:20,lt:30,ls:-40,rt:-25,rs:-10,hy:-.1},
slashDown:{t:32,h:12,lu:-25,lf:40,ru:75,rf:0,lt:52,ls:-62,rt:-42,rs:-10,hy:-.26},
thrust:{t:26,h:0,lu:-45,lf:30,ru:92,rf:0,lt:56,ls:-42,rt:-46,rs:0,hy:-.2},
block:{t:0,h:-5,lu:115,lf:45,ru:130,rf:40,lt:22,ls:-30,rt:-22,rs:-20,hy:-.15},
dodge:{t:-35,h:-10,lu:-60,lf:20,ru:40,rf:60,lt:30,ls:-60,rt:-30,rs:-20,hy:-.15},
spin:{t:16,h:0,lu:-60,lf:20,ru:92,rf:0,lt:42,ls:-50,rt:-36,rs:-10,hy:-.2},
hit:{t:-32,h:-25,lu:45,lf:40,ru:-30,rf:30,lt:32,ls:-22,rt:20,rs:-30,hy:0},
fly:{t:-40,h:-30,lu:100,lf:30,ru:125,rf:20,lt:42,ls:-60,rt:62,rs:-40,hy:0},
crash:{t:-40,h:-30,lu:150,lf:20,ru:130,rf:30,lt:30,ls:-30,rt:10,rs:-30,hy:0},
jump:{t:12,h:-5,lu:-45,lf:60,ru:125,rf:30,lt:80,ls:-110,rt:40,rs:-100,hy:0},
tuck:{t:32,h:10,lu:80,lf:60,ru:80,rf:60,lt:112,ls:-140,rt:100,rs:-130,hy:0},
land:{t:45,h:-30,lu:-70,lf:10,ru:-18,rf:10,lt:92,ls:-122,rt:-32,rs:-108,hy:-.5},
kneel:{t:18,h:22,lu:60,lf:40,ru:22,rf:30,lt:90,ls:-90,rt:-12,rs:-100,hy:-.45},
kneelLow:{t:32,h:40,lu:30,lf:10,ru:10,rf:10,lt:90,ls:-92,rt:-12,rs:-100,hy:-.48},
kneelUp:{t:4,h:-32,lu:55,lf:40,ru:22,rf:30,lt:90,ls:-90,rt:-12,rs:-100,hy:-.45},
power:{t:-5,h:-12,lu:28,lf:5,ru:-28,rf:5,lt:16,ls:-2,rt:-16,rs:-2,hy:-.05},
charge:{t:32,h:-8,lu:62,lf:40,ru:-120,rf:20,lt:62,ls:-72,rt:-52,rs:-10,hy:-.3},
offer:{t:25,h:22,lu:-5,lf:15,ru:72,rf:5,lt:15,ls:-15,rt:-10,rs:-10,hy:-.03},
pull:{t:-15,h:0,lu:-10,lf:20,ru:60,rf:40,lt:25,ls:-20,rt:-25,rs:-10,hy:-.1},
lie:{t:0,h:12,lu:32,lf:20,ru:-20,rf:10,lt:10,ls:-5,rt:5,rs:0,hy:-.84},
sit:{t:-6,h:10,lu:-25,lf:10,ru:-20,rf:15,lt:88,ls:0,rt:84,rs:-10,hy:-.82},
sitReach:{t:12,h:-18,lu:-25,lf:10,ru:82,rf:10,lt:88,ls:0,rt:84,rs:-10,hy:-.82}};
function blendP(a,b,x){const o={};for(const k in a)o[k]=lerp(a[k],b[k],x);return o}
const dir=a=>[sin(a*R2),-cos(a*R2)],up=a=>[sin(a*R2),cos(a*R2)],a2=(p,v,k)=>[p[0]+v[0]*k,p[1]+v[1]*k];
function joints(st){const p=st.pose,hip=[0,.95+p.hy],nk=a2(hip,up(p.t),.58),hd=a2(nk,up(p.t+p.h),.21);
 const arm=(u,f)=>{const e=a2(nk,dir(u),.3);return[nk,e,a2(e,dir(u+f),.28)]},leg=(u,s)=>{const k=a2(hip,dir(u),.46),f=a2(k,dir(u+s),.46);return[hip,k,f,a2(f,dir(u+s+90),.11)]};
 const L={hip,nk,hd,la:arm(p.lu,p.lf),ra:arm(p.ru,p.rf),ll:leg(p.lt,p.ls),rl:leg(p.rt,p.rs)},r=(st.roll||0)*R2,yw=st.yaw*R2,F=[cos(yw),0,sin(yw)],S=[-sin(yw),0,cos(yw)];
 const w=(q,s=0)=>{const f=q[0],u=q[1]-hip[1],f2=f*cos(r)+u*sin(r),u2=-f*sin(r)+u*cos(r)+hip[1];return[st.x+f2*F[0]+s*S[0],(st.y||0)+u2,st.z+f2*F[2]+s*S[2]]};
 return{F,S,hip:w(hip),nk:w(nk),hd:w(hd),la:L.la.map(q=>w(q,-.1)),ra:L.ra.map(q=>w(q,.1)),ll:L.ll.map(q=>w(q,-.08)),rl:L.rl.map(q=>w(q,.08)),up:V.norm(V.sub(w(hd),w(nk)))}}
function stroke3(pts,wd,st){const P=pts.map(pr);if(P.some(q=>!q))return;const s=P[0][2],w=max(1.5,s*wd);
 X.lineCap=X.lineJoin='round';const path=()=>{X.beginPath();P.forEach((q,i)=>i?X.lineTo(q[0],q[1]):X.moveTo(q[0],q[1]))};
 X.save();X.shadowColor=rgba(st.glow,.9);X.shadowBlur=10+18*st.aura;path();X.strokeStyle=rgba(st.glow,.35+.4*st.aura);X.lineWidth=w*1.9;X.stroke();X.restore();
 path();X.strokeStyle='#0B0A12';X.lineWidth=w;X.stroke();X.save();X.translate(-w*.12,-w*.14);path();X.strokeStyle=rgba(st.rim,.3);X.lineWidth=w*.22;X.stroke();X.restore()}
function sword(J,st,len,col,trail){if(len<=.01)return;const h=J.ra[2],d=V.norm(V.sub(h,J.ra[1])),tip=V.add(h,V.mul(d,len)),hb=pr(V.add(h,V.mul(d,-.1))),hp=pr(h);
 X.save();X.globalCompositeOperation='lighter';if(trail&&trail.length){X.beginPath();const T=[[h,tip],...trail].map(([a,b])=>[pr(a),pr(b)]);if(T.every(q=>q[0]&&q[1])){for(let i=0;i<T.length-1;i++){const a=T[i],b=T[i+1];X.beginPath();X.moveTo(a[0][0],a[0][1]);X.lineTo(a[1][0],a[1][1]);X.lineTo(b[1][0],b[1][1]);X.lineTo(b[0][0],b[0][1]);X.fillStyle=rgba(col,.32*(1-i/T.length));X.fill()}}}
 const b=pr(h),e=pr(tip);if(b&&e){X.lineCap='round';X.shadowColor=col;X.shadowBlur=30;X.strokeStyle=rgba(col,.55);X.lineWidth=b[2]*.07;X.beginPath();X.moveTo(b[0],b[1]);X.lineTo(e[0],e[1]);X.stroke();X.shadowBlur=8;X.strokeStyle='#FFFFFF';X.lineWidth=b[2]*.022;X.stroke()}X.restore();
 if(hb&&hp){X.strokeStyle='#1a1822';X.lineWidth=hp[2]*.05;X.beginPath();X.moveTo(hb[0],hb[1]);X.lineTo(hp[0],hp[1]);X.stroke()}}
function drawFig(st){const J=joints(st),dp=q=>cs(q)[2],far=dp(J.la[2])>dp(J.ra[2]),farL=dp(J.ll[2])>dp(J.rl[2]);
 const sh=pr([J.hip[0],.01,J.hip[2]]);if(sh){X.fillStyle=`rgba(0,0,0,${.35*cl(1-(st.y||0)/2)})`;X.beginPath();X.ellipse(sh[0],sh[1],sh[2]*.45,sh[2]*.08,0,0,7);X.fill()}
 if(st.scarf){const n=J.nk,w=st.scarf,P=[];for(let k=0;k<10;k++)P.push(pr(V.add(n,[-J.F[0]*.11*k+w[0]*.02*k*k,-.035*k+.025*k*sin(st.t*7-k*.7)+w[1]*.03*k*k,-J.F[2]*.11*k+.03*k*sin(st.t*5-k)+w[2]*.02*k*k])));
  if(P.every(q=>q)){const Lp=[],Rp=[];for(let k=0;k<10;k++){const a=P[max(0,k-1)],b=P[min(9,k+1)],dx=b[0]-a[0],dy=b[1]-a[1],l=hypot(dx,dy)||1,wd=P[0][2]*.05*(1-k/10.5);Lp.push([P[k][0]-dy/l*wd,P[k][1]+dx/l*wd]);Rp.push([P[k][0]+dy/l*wd,P[k][1]-dx/l*wd])}
   X.save();X.shadowColor='#39E6D2';X.shadowBlur=14+14*st.aura;X.beginPath();[...Lp,...Rp.reverse()].forEach((q,i)=>i?X.lineTo(q[0],q[1]):X.moveTo(q[0],q[1]));X.closePath();X.fillStyle='#0F3B44';X.fill();X.strokeStyle=rgba('#39E6D2',.6);X.lineWidth=1.5;X.stroke();X.restore()}}
 const limbs=[[far?J.la:J.ra,far?'a':'b'],[farL?J.ll:J.rl],[farL?J.rl:J.ll],[far?J.ra:J.la]];
 const W0=.075;stroke3(limbs[0][0],W0,st);if(!far)sword(J,st,st.sw,st.swc,st.trail);stroke3(limbs[1][0],W0,st);stroke3([J.hip,J.nk],W0*1.25,st);stroke3(limbs[2][0],W0,st);
 const hp=pr(J.hd);if(hp){const r=hp[2]*.15;X.save();X.shadowColor=rgba(st.glow,.9);X.shadowBlur=14+20*st.aura;X.fillStyle=rgba(st.glow,.5);X.beginPath();X.arc(hp[0],hp[1],r*1.12,0,7);X.fill();X.restore();X.fillStyle='#0B0A12';X.beginPath();X.arc(hp[0],hp[1],r,0,7);X.fill();X.strokeStyle=rgba(st.rim,.5);X.lineWidth=r*.12;X.beginPath();X.arc(hp[0]-r*.1,hp[1]-r*.1,r*.9,PI*1.05,PI*1.6);X.stroke();
  if(st.horns)for(const s of[-1,1]){const a=pr(V.add(J.hd,V.add(V.mul(J.up,.12),V.add(V.mul(J.S,.08*s),V.mul(J.F,-.03))))),b=pr(V.add(J.hd,V.add(V.mul(J.up,.3),V.add(V.mul(J.S,.13*s),V.mul(J.F,-.14)))));if(a&&b){X.strokeStyle='#0B0A12';X.lineWidth=r*.28;X.beginPath();X.moveTo(a[0],a[1]);X.lineTo(b[0],b[1]);X.stroke()}}
  const eF=V.add(V.mul(J.F,.13),V.mul(J.up,.025));for(const s of[-1,1]){const ep=V.add(J.hd,V.add(eF,V.mul(J.S,.06*s)));if(dp(ep)>dp(J.hd)+.02)continue;const e=pr(ep);if(!e)continue;
   X.save();X.globalCompositeOperation='lighter';X.shadowColor=st.eyec;X.shadowBlur=12+22*st.eye;X.fillStyle=rgba(st.eyec,min(1,.5+st.eye*.5));X.beginPath();X.ellipse(e[0],e[1],r*.3*(1+.25*st.eye),r*.13,0,0,7);X.fill();X.fillStyle='#FFFFFF';X.beginPath();X.ellipse(e[0],e[1],r*.16,r*.06,0,0,7);X.fill();
   if(st.eye>1.3){const g=X.createRadialGradient(e[0],e[1],0,e[0],e[1],min(r*2.2*st.eye,90));g.addColorStop(0,rgba(st.eyec,.45));g.addColorStop(1,rgba(st.eyec,0));X.fillStyle=g;X.fillRect(e[0]-r*5,e[1]-r*5,r*10,r*10)}X.restore()}}
 stroke3(limbs[3][0],W0,st);if(far)sword(J,st,st.sw,st.swc,st.trail);return J}
