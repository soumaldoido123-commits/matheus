function TR(K){let l=null;return K.sort((a,b)=>a[0]-b[0]).map(k=>{const o=[...k];if(l)for(let j=2;j<7;j++)if(o[j]===undefined)o[j]=l[j];return l=o})}
const mk=(a,b,x)=>({pose:blendP(PZ[a[1]],PZ[b[1]],x),x:lerp(a[2],b[2],x),z:lerp(a[3],b[3],x),yaw:lerp(a[4],b[4],x),y:lerp(a[5],b[5],x),roll:lerp(a[6],b[6],x)});
function stAt(T,t){if(t<=T[0][0])return mk(T[0],T[0],0);for(let i=1;i<T.length;i++)if(t<=T[i][0]){const a=T[i-1],b=T[i];return mk(a,b,ss(cl((t-a[0])/(b[0]-a[0]))))}const l=T[T.length-1];return mk(l,l,0)}
const FH=['block','slashUp','slashDown','block','thrust','block','slashDown'],FR=['slashDown','block','block','slashUp','dodge','slashDown','block'];
const HT=TR([[0,'idle',-2,0,0,0,0],[4.6,'idle'],[5.4,'lookUp'],[6.9,'lookUp'],[7.15,'brace'],[8.2,'brace'],[9,'idle'],[11.2,'idle'],[12,'guard'],[13,'guard'],
[13.3,'runA',-1.6],[13.6,'runB',-1.15],[13.9,'runA',-.85],[14.25,'slashUp',-.7],[14.5,'slashDown',-.62],[15,'guard',-.7],[15.3,'block',-.75],[15.75,'guard',-.7],[16.05,'thrust',-.35],
[16.45,'jump',-.2,0,0,.2,0],[16.9,'tuck',.8,0,60,2.1,-150],[17.35,'tuck',1.9,0,140,1.6,-300],[17.8,'land',2.7,0,180,0,-360],[18.4,'guard',2.6,0,180,0,-360],[18.4001,'guard',2.6,0,180,0,0],[18.9,'slashDown',2.1],
...FH.map((p,k)=>[19.35+.45*k,p,2.2+k/6]),[22.35,'guard',3.2],[22.7,'hit',3.35],[23,'fly',4.1,0,180,.9,-25],[23.8,'fly',5.7,0,180,1.3,-50],[24.2,'crash',6.55,0,180,1,-70],[24.8,'hit',6.4,0,180,.3,-20],[25.4,'kneelLow',6.3,0,180,0,0],
[27.5,'kneelLow'],[29.3,'kneel'],[30.6,'kneelUp'],[31.8,'kneelUp'],[32.6,'power',6.2],[34.6,'power'],[35.2,'charge',6],[36.2,'charge',6],[36.45,'runA',5.4],[36.7,'runB',4.7],[36.95,'runA',4.1],[37.2,'slashDown',3.6],[39.6,'slashDown',3.55],
[39.95,'slashDown',3.55],[40,'idle',3.5,0,180,0,0],[42,'idle'],...[...Array(8)].map((_,k)=>[42.5+k*.5,k%2?'walkB':'walkA',3.25-k*.25]),[46.4,'idle',1.5],[47,'offer',1.45],[48.8,'offer'],[49.4,'pull',1.55],[50.4,'idle',1.55],[51,'idle'],[52.2,'idle',1.55,0,90],[60,'idle']]);
const RT=TR([[7,'land',2.2,0,180,0,0],[8.3,'land'],[9.3,'idle'],[11.4,'idle'],[12.3,'guard'],[13,'guard',2.1],[13.3,'runB',1.65],[13.6,'runA',1.15],[13.9,'runB',.85],[14.5,'block',.62],
[15,'slashUp',.72],[15.3,'slashDown',.78],[15.75,'guard',.8],[16.05,'dodge',1.2],[16.6,'spin',1,0,360],[17.1,'spin',1,0,540],[17.9,'guard',1,0,540],[18.5,'guard',1.1,0,720],[18.9,'block',1.2,0,720],
...FR.map((p,k)=>[19.35+.45*k,p,1.3+k/6]),[22.35,'charge',2.3],[22.7,'thrust',2.75],[23.6,'thrust',2.75],[24.6,'idle',2.8],[25.4,'idle'],...[...Array(8)].map((_,k)=>[25.85+k*.45,k%2?'walkB':'walkA',3.02+k*.225]),[29.3,'idle',4.6],
[32.2,'idle'],[32.7,'brace',4.4],[33.2,'brace',4.3],[33.6,'tuck',2.6,0,720,1.4,0],[34.1,'land',1,0,720,0,0],[34.8,'guard',1],[35.2,'charge',1],[36.2,'charge',1],[36.45,'runB',1.5],[36.7,'runA',2.1],[36.95,'runB',2.6],[37.2,'slashDown',2.85],[39.6,'slashDown',2.9],
[39.95,'slashDown',2.9],[40,'lie',.5,0,720,0,-85],[46.6,'lie'],[47.6,'sit',.5,0,720,0,0],[48.3,'sitReach'],[49.2,'sitReach'],[50.3,'idle',.7],[51,'idle'],[52.2,'idle',.7,0,810],[60,'idle']]);
const HS0={glow:'#27B8FF',rim:'#9FE8FF',eyec:'#6FF2FF',horns:0},RS0={glow:'#FF3B4E',rim:'#FFB0A0',eyec:'#FF4D5E',horns:1};
const hSw=t=>t<24.2?key(t,[[11.6,0],[12.1,1.15]]):t<33.3?0:key(t,[[33.3,0],[33.7,1.45],[39.7,1.45],[39.9,0]]),rSw=t=>key(t,[[11.9,0],[12.4,1.15],[39.7,1.15],[39.9,0]]);
function hero(t,trail){const s=stAt(HT,t),d=stAt(HT,t-.06),vx=(s.x-d.x)/.06,fl=t>29.4&&t<30.4?(hs(floor(t*24))>.45?1:.15):1;
 return{...HS0,...s,t,sw:hSw(t),swc:t>33?'#BFF7FF':'#39C6FF',eye:key(t,[[0,1],[24.5,1],[25.5,.45],[29.4,.25],[30.4,2.4],[36,2],[39.5,2.3],[41,1]])*fl,aura:key(t,[[29.6,0],[30.6,.9],[32.6,1.7],[37,1.3],[39.8,1.5],[40.5,0]]),
 scarf:[-vx*.35,key(t,[[29.5,0],[31,1.2],[36,1.2],[40,0]])+.2*sin(t*3),0],trail:trail?trl(HT,hSw,t):null}}
function rival(t,trail){const s=stAt(RT,t);return{...RS0,...s,t,sw:rSw(t),swc:'#FF3B4E',eyec:t>47?mixc('#FF4D5E','#FFB36B',sm(47,49,t)):'#FF4D5E',eye:key(t,[[7,.2],[9.3,.2],[9.7,2.5],[10.6,1.3],[39,1.4],[40.5,.3],[47.4,.3],[48.4,.9]]),aura:key(t,[[34.5,0],[35.5,.7],[39.8,.8],[40.5,0]]),trail:trail?trl(RT,rSw,t):null}}
function trl(T,swf,t){const o=[];for(let k=1;k<8;k++){const tt=t-.014*k,L=swf(tt);if(L<.05)break;const J=joints({...stAt(T,tt)}),h=J.ra[2],d=V.norm(V.sub(h,J.ra[1]));o.push([h,V.add(h,V.mul(d,L))])}return o}
const hand=(T,t)=>joints(stAt(T,t)).ra[2],CPt=t=>V.add(V.lerp(hand(HT,t),hand(RT,t),.5),[0,.3,0]);
const EV=[{t:7,ty:'impact',p:[2.2,0,0],c:'#FF3B4E',s:1.4,sh:22},{t:12.1,ty:'spark',p:hand(HT,12.1),c:'#39C6FF',s:.4,sh:0},{t:12.4,ty:'spark',p:hand(RT,12.4),c:'#FF3B4E',s:.4,sh:0},
 ...[14.5,15.3,18.9,...FH.map((_,k)=>19.35+.45*k)].map(t=>({t,ty:'clash',p:CPt(t),c:'#FFE3A8',s:1,sh:9})),{t:17.8,ty:'dust',p:[2.7,0,0],s:.6,sh:4},
 {t:22.7,ty:'hit',p:joints(stAt(HT,22.7)).nk,c:'#FF3B4E',s:1.6,sh:20},{t:24.2,ty:'crash',p:[6.8,1,0],c:'#FFD6A0',s:1.5,sh:26},{t:34.1,ty:'dust',p:[1,0,0],s:.8,sh:6},
 {t:32.6,ty:'aura',p:[6.2,0,0],c:'#5FE3FF',s:1.8,sh:18},{t:33.6,ty:'spark',p:hand(HT,33.6),c:'#BFF7FF',s:.8,sh:6},{t:37.2,ty:'final',p:CPt(37.2),c:'#FFFFFF',s:2.2,sh:30},
 ...[...Array(22)].map((_,k)=>({t:37.3+k*.1,ty:'clash',p:CPt(37.2),c:k%2?'#BFF7FF':'#FF8A8A',s:.9,sh:5})),...[38,38.6,39.2].map(t=>({t,ty:'ring',p:[CPt(37.2)[0],0,0],c:'#FFFFFF',s:1.4,sh:12}))];
const orb=(c,r,a,h)=>[c[0]+r*sin(a*R2),c[1]+h,c[2]-r*cos(a*R2)];
function cam(t){const u=(a,b)=>sm(a,b,t),mid=()=>(stAt(HT,t).x+stAt(RT,t).x)/2,hx=()=>stAt(HT,t).x;
 if(t<4.6)return[V.lerp([0,7,-17],[-1.2,2.6,-9.5],u(0,4.6)),[0,1,0],900];
 if(t<7)return[V.lerp([-3.9,1.1,-2.6],[-3.6,.9,-2.2],u(4.6,7)),V.lerp([-1,2.4,0],[1.5,4.2,1.2],u(4.6,7)),950];
 if(t<8.2)return[[0,1.7,-7.8],[.8,1,0],950];
 if(t<11.2)return[orb([0,1.1,0],6.8,lerp(-100,-25,u(8.2,11.2)),.5),[0,1.1,0],1000];
 if(t<13)return[V.lerp([0,.45,-2.7],[0,.55,-2.3],u(11.2,13)),[0,1.45,0],820];
 if(t<16.45){const m=mid();return[[m,1.3,-5.4],[m,1.2,0],1000]}
 if(t<18.4)return[orb([1.2,1.3,0],5.2,lerp(-95,15,u(16.45,18.4)),.4),[1.2,1.3,0],1000];
 if(t<22.5){const m=mid();return[[m-.8+.3*sin(t*3),1.5,-3.7],[m,1.3,0],1000]}
 if(t<24.9){const x=hx();return[[x-2.2,1.6,-4.6],[x+.3,1.2,0],1000]}
 if(t<28.5)return[V.lerp([1.5,3.6,-7.5],[2.2,3,-6.6],u(24.9,28.5)),[4.8,.8,0],950];
 if(t<32.3){const h=joints(stAt(HT,t)).hd,d=lerp(1.9,1.05,u(28.5,32.3));return[[h[0]-d,h[1]-.35,h[2]-.55*d],h,1000]}
 if(t<35.2)return[orb([6.2,1.1,0],4,lerp(25,-30,u(32.3,35.2)),-.4),[6.2,1.3,0],950];
 if(t<36.3)return[[3.6,2.4,-9.5],[3.6,1,0],900];
 if(t<37.2){const m=mid();return[[m,.6,-3.2],[m,1.2,0],820]}
 if(t<40){const c=CPt(37.2),x=(t-37.2)/2.8;return[orb(c,lerp(2.6,3.6,x),lerp(-90,200,ss(x)),-.1),c,900]}
 if(t<42)return[[2,2.2,-8.2],[2,.6,0],950];
 if(t<46.4){const x=hx();return[[x-.8,1.3,-4.6],[x-.9,.8,0],1000]}
 if(t<49.4)return[V.lerp([1,1.15,-3.4],[1,1.05,-2.9],u(46.4,49.4)),[.98,.8,0],1050];
 if(t<52.2)return[[1.1,1.3,-4.6],[1.1,1.05,0],1000];
 return[V.lerp([1.1,1.6,-3.6],[1.1,7,-14],u(52.2,59)),V.lerp([1.1,1.4,20],[1.1,3,60],u(52.2,59)),900]}
function fx(t){X.save();X.globalCompositeOperation='lighter';X.lineCap='round';
 for(const e of EV){const d=t-e.t;if(d<0||d>1.6)continue;
  if(['clash','spark','hit','impact','final','crash'].includes(e.ty)&&d<.7){const n=e.ty=='final'?90:e.ty=='spark'?16:46;for(let k=0;k<n;k++){const a=hs(k+e.t*7)*2*PI,b=(hs(k*3+e.t)-.3)*PI,sp=(3+6*hs(k+e.t*3))*e.s,v=[cos(a)*cos(b)*sp,sin(b)*sp,sin(a)*cos(b)*sp],p=V.add(e.p,[v[0]*d,v[1]*d-4*d*d,v[2]*d]),q=V.sub(p,V.mul(v,.025)),A=pr(p),Bq=pr(q);if(!A||!Bq)continue;
   X.strokeStyle=rgba(mixc('#FFFFFF',e.c||'#FFD27A',hs(k)),1-d/.7);X.lineWidth=max(1,A[2]*.012);X.beginPath();X.moveTo(A[0],A[1]);X.lineTo(Bq[0],Bq[1]);X.stroke()}
   const c=pr(e.p);if(c&&d<.35){const r=c[2]*.9*e.s*(1-d/.35)+10,g=X.createRadialGradient(c[0],c[1],0,c[0],c[1],r);g.addColorStop(0,rgba('#FFFFFF',1-d/.35));g.addColorStop(.3,rgba(e.c||'#FFD27A',.6*(1-d/.35)));g.addColorStop(1,rgba(e.c||'#FFD27A',0));X.fillStyle=g;X.fillRect(c[0]-r,c[1]-r,2*r,2*r)}}
  if(['impact','aura','ring','final'].includes(e.ty)&&d<.9){const P=circ([e.p[0],0,e.p[2]],d*9*e.s,.03,40).map(pr);if(P.every(q=>q)){X.strokeStyle=rgba(e.c,.8*(1-d/.9));X.lineWidth=6*(1-d/.9)+1;X.beginPath();P.forEach((q,i)=>i?X.lineTo(q[0],q[1]):X.moveTo(q[0],q[1]));X.closePath();X.stroke()}}}
 X.restore();for(const e of EV){const d=t-e.t;if(d<0||d>1.6||!['impact','crash','dust'].includes(e.ty))continue;for(let k=0;k<26;k++){const a=hs(k+e.t)*2*PI,r=(1-exp(-d*3))*2.4*e.s*(.4+hs(k+2)),p=pr([e.p[0]+r*cos(a),.15+hs(k+5)*.5*e.s*d+(e.ty=='crash'?e.p[1]*(1-d/1.6)*hs(k+9):0),e.p[2]+r*sin(a)]);if(!p)continue;const w=p[2]*(.1+.22*d)*e.s*(.5+hs(k+7));X.fillStyle=rgba(t>40?'#E8D8C8':'#8A7A88',.3*(1-d/1.6));X.beginPath();X.arc(p[0],p[1],w,0,7);X.fill()}
  if(e.ty!='dust')for(let k=0;k<14;k++){const a=hs(k+e.t*2)*2*PI,sp=2+3*hs(k+4),p=pr([e.p[0]+cos(a)*sp*d,max(0,e.p[1]+ (2+2*hs(k))*d-5*d*d),e.p[2]+sin(a)*sp*d]);if(p){X.fillStyle='#1a1620';X.fillRect(p[0],p[1],p[2]*.06,p[2]*.06)}}}}
function R(i){const t=i/24;let[p,tg,f]=cam(t);let sh=0;for(const e of EV){const d=t-e.t;if(d>0&&d<1.2)sh+=e.sh*exp(-d*7)}if(t>19&&t<22.5)sh+=2;if(t>37.2&&t<39.8)sh+=8;
 const hb=t>27.2&&t<30.3?exp(-((t-27.2)%.95)*9):0;look(p,tg,f*(1+.035*hb));CAM.sh=[sh*(hs(i*1.3)-.5)*2,sh*(hs(i*2.1)-.5)*2];
 sky(t);if(t>26&&t<40){for(const lt of[26.6,30.3,32.6]){const d=t-lt;if(d>0&&d<.35){X.strokeStyle=rgba('#DDE8FF',1-d/.35);X.lineWidth=3;X.shadowColor='#9FC0FF';X.shadowBlur=20;X.beginPath();let x=300+hs(lt)*700,y=0;X.moveTo(x,y);while(y<330){x+=(hs(x+y)-.5)*90;y+=30+hs(y)*30;X.lineTo(x,y)}X.stroke();X.shadowBlur=0}}}
 arena(t);const D=pillars(t),ht=t>12&&t<40,H0=hero(t,ht),RV=t>=7?rival(t,ht):null;
 D.push({z:cs([H0.x,1,H0.z])[2],draw(){if((t>13&&t<14.5)||(t>36.3&&t<37.2))for(let k=3;k>0;k--){X.globalAlpha=.22/k;drawFig(hero(t-.05*k));X.globalAlpha=1}drawFig(H0)}});
 if(RV)D.push({z:cs([RV.x,1,RV.z])[2],draw(){if((t>13&&t<14.5)||(t>36.3&&t<37.2))for(let k=3;k>0;k--){X.globalAlpha=.22/k;drawFig(rival(t-.05*k));X.globalAlpha=1}drawFig(RV)}});
 if(t>24.2&&t<33.3){const G=[5.3,.03,.5],h24=hand(HT,24.2),h33=hand(HT,33.3);let q=t<24.9?V.add(V.lerp(h24,G,(t-24.2)/.7),[0,1.2*sin(PI*(t-24.2)/.7),0]):t<32.9?G:V.lerp(G,h33,ss((t-32.9)/.4));D.push({z:cs(q)[2],draw(){const a=pr(q),b=pr(V.add(q,[.22,0,.06]));if(a&&b){X.save();X.shadowColor='#39C6FF';X.shadowBlur=6+8*max(0,sin(t*3));X.strokeStyle='#1a1822';X.lineWidth=a[2]*.05;X.beginPath();X.moveTo(a[0],a[1]);X.lineTo(b[0],b[1]);X.stroke();X.restore()}}})}
 D.sort((a,b)=>b.z-a.z).forEach(d=>d.draw());
 if(t>4.8&&t<7){const cp=u=>V.lerp([26,34,32],[2.2,0,0],u*u);X.save();X.globalCompositeOperation='lighter';for(let k=12;k>=0;k--){const u=cl((t-4.8)/2.2-k*.012),q=pr(cp(u));if(!q)continue;const r=(k?16-k:30)*max(.4,q[2]/300),g=X.createRadialGradient(q[0],q[1],0,q[0],q[1],r*3);g.addColorStop(0,rgba(k?'#FF3B4E':'#FFFFFF',k?.5:1));g.addColorStop(1,rgba('#FF3B4E',0));X.fillStyle=g;X.fillRect(q[0]-r*3,q[1]-r*3,r*6,r*6)}X.restore()}
 fx(t);X.save();X.globalCompositeOperation='lighter';
 if(H0.aura>0)for(let k=0;k<50;k++){const y=(hs(k)*2.4+t*1.4*(1+hs(k+1)))%2.4,a=k*2.4+t,q=pr([H0.x+.55*cos(a)*(1-y/3),y,H0.z+.55*sin(a)*(1-y/3)]);if(q){X.fillStyle=rgba('#7FF0FF',H0.aura*.5*(1-y/2.4));X.beginPath();X.arc(q[0],q[1],q[2]*.018+1,0,7);X.fill()}}
 const amb=t<40?[60,'#FF9A4D',.4,6]:[50,'#FFE9B0',.2,5];for(let k=0;k<amb[0];k++){const a=hs(k+200)*2*PI,r=1+hs(k+201)*9,y=(hs(k+202)*amb[3]+t*amb[2])%amb[3],q=pr([r*cos(a)+.4*sin(t+k),y,r*sin(a)]);if(q){X.fillStyle=rgba(amb[1],.6*sin(PI*y/amb[3]));X.beginPath();X.arc(q[0],q[1],q[2]*.012+.8,0,7);X.fill()}}
 if(t>37.2&&t<40.2){const c=pr(CPt(37.2)),g0=sm(37.2,39.5,t);if(c){for(let k=0;k<26;k++){const a=k/26*2*PI+t*.8+hs(k),L=900*(.6+.4*hs(k+3));X.fillStyle=rgba(k%2?'#BFF7FF':'#FFB0B0',.12*g0);X.beginPath();X.moveTo(c[0],c[1]);X.lineTo(c[0]+L*cos(a-.03),c[1]+L*sin(a-.03));X.lineTo(c[0]+L*cos(a+.03),c[1]+L*sin(a+.03));X.fill()}const r=70+380*g0,g=X.createRadialGradient(c[0],c[1],0,c[0],c[1],r);g.addColorStop(0,'rgba(255,255,255,.95)');g.addColorStop(.25,rgba('#CFF6FF',.5*g0+.2));g.addColorStop(1,'rgba(255,255,255,0)');X.fillStyle=g;X.fillRect(0,0,W,H)}}
 if((t>13&&t<14.5)||(t>36.3&&t<37.2))for(let k=0;k<46;k++){const a=hs(k+floor(t*12))*2*PI,r0=380+hs(k+5)*200;X.strokeStyle=rgba('#FFFFFF',.3);X.lineWidth=1+hs(k)*2;X.beginPath();X.moveTo(W/2+r0*cos(a),H/2+r0*sin(a));X.lineTo(W/2+(r0+300)*cos(a),H/2+(r0+300)*sin(a));X.stroke()}X.restore();
 const rn=sm(25.2,26,t)*(1-sm(33.8,34.6,t));if(rn>0){X.fillStyle=rgba('#0A1020',.25*rn);X.fillRect(0,0,W,H);X.strokeStyle=rgba('#C8D8FF',.35*rn);X.lineWidth=1.2;X.beginPath();for(let k=0;k<240;k++){const x=((hs(k)*1500-t*260)%1500+1500)%1500-100,y=(hs(k+9)*900+t*1600)%900-90;X.moveTo(x,y);X.lineTo(x-7,y+26)}X.stroke()}
 X.save();X.globalCompositeOperation='soft-light';X.fillStyle=t<40?mixc('#FF7A3D','#2A4A8A',sm(24,26,t)):'#FFD39A';X.globalAlpha=t<40?.35:.3;X.fillRect(0,0,W,H);X.restore();
 const ds=sm(25,26,t)*(1-sm(30.3,31.5,t));if(ds>0){X.save();X.globalCompositeOperation='saturation';X.fillStyle=`rgba(128,128,128,${.75*ds})`;X.fillRect(0,0,W,H);X.restore()}
 if(hb>0){const g=X.createRadialGradient(W/2,H/2,H*.3,W/2,H/2,H);g.addColorStop(0,'rgba(0,0,0,0)');g.addColorStop(1,rgba('#6A0010',.45*hb));X.fillStyle=g;X.fillRect(0,0,W,H)}
 for(const[a,dd,c,al]of[[7,.5,'#FF6070',.55],[22.7,.4,'#FF4050',.6],[26.6,.25,'#DDE8FF',.5],[30.3,.3,'#CFF6FF',.6],[32.6,.5,'#BFF7FF',.7],[24.2,.3,'#FFFFFF',.35]]){const d=t-a;if(d>0&&d<dd){X.fillStyle=rgba(c,al*(1-d/dd)**2);X.fillRect(0,0,W,H)}}
 post(t,t>36&&t<40?.6:.38);const wf=t<40?sm(38.9,39.7,t):1-sm(40.2,41.6,t);if(wf>0){X.fillStyle=`rgba(255,255,255,${wf})`;X.fillRect(0,0,W,H)}
 X.textAlign='center';const ti=sm(.8,2,t)*(1-sm(3.6,4.5,t));if(ti>0){X.save();X.globalAlpha=ti;X.shadowColor='#FFB36B';X.shadowBlur=30;X.fillStyle='#FFF4E0';X.font='700 72px Georgia,serif';X.fillText('Ú L T I M O   D U E L O',W/2,H/2-6);X.shadowBlur=8;X.font='italic 24px Georgia,serif';X.fillText('dois guerreiros · um destino',W/2,H/2+42);X.restore()}
 const fo=t<1.2?1-t/1.2:sm(57.3,58.3,t);if(fo>0){X.fillStyle=`rgba(0,0,0,${fo})`;X.fillRect(0,0,W,H)}if(t>58){X.save();X.globalAlpha=sm(58.2,59,t);X.shadowColor='#FFD39A';X.shadowBlur=24;X.fillStyle='#FFF4E0';X.font='700 60px Georgia,serif';X.fillText('F I M',W/2,H/2+20);X.restore()}}
