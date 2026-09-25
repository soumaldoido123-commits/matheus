const C=document.getElementById('c'),X=C.getContext('2d'),W=1280,H=720;
const B=document.createElement('canvas');B.width=640;B.height=360;const BX=B.getContext('2d');
const {sin,cos,PI,abs,min,max,hypot,atan2,sqrt,floor,exp,tan}=Math,R2=PI/180;
const cl=(x,a=0,b=1)=>min(b,max(a,x)),lerp=(a,b,x)=>a+(b-a)*x,ss=x=>x*x*(3-2*x),sm=(a,b,t)=>ss(cl((t-a)/(b-a)));
const hs=n=>{const x=sin(n*127.1+311.7)*43758.5453;return x-floor(x)};
const hx=c=>[1,3,5].map(i=>parseInt(c.slice(i,i+2),16));
const mixc=(a,b,x)=>'#'+hx(a).map((v,j)=>Math.round(v+(hx(b)[j]-v)*x).toString(16).padStart(2,'0')).join('');
const rgba=(c,a)=>`rgba(${hx(c).join(',')},${cl(a)})`;
function key(t,K){if(t<=K[0][0])return K[0][1];for(let i=1;i<K.length;i++)if(t<=K[i][0]){const[a,va]=K[i-1],[b,vb]=K[i],x=ss(cl((t-a)/(b-a)));return typeof va=='string'?mixc(va,vb,x):va+(vb-va)*x}return K[K.length-1][1]}
const V={add:(a,b)=>[a[0]+b[0],a[1]+b[1],a[2]+b[2]],sub:(a,b)=>[a[0]-b[0],a[1]-b[1],a[2]-b[2]],mul:(a,k)=>[a[0]*k,a[1]*k,a[2]*k],lerp:(a,b,x)=>[lerp(a[0],b[0],x),lerp(a[1],b[1],x),lerp(a[2],b[2],x)],len:a=>hypot(a[0],a[1],a[2])};
V.norm=a=>V.mul(a,1/(V.len(a)||1));
const CAM={p:[0,1,-5],yaw:0,pitch:0,f:1000,sh:[0,0]};
function look(p,tg,f){CAM.p=p;const d=V.sub(tg,p);CAM.yaw=atan2(d[0],d[2]);CAM.pitch=atan2(d[1],hypot(d[0],d[2]));CAM.f=f||1000}
function cs(p){const dx=p[0]-CAM.p[0],dy=p[1]-CAM.p[1],dz=p[2]-CAM.p[2],cy=cos(CAM.yaw),sy=sin(CAM.yaw),x1=dx*cy-dz*sy,z1=dx*sy+dz*cy,cp=cos(CAM.pitch),sp=sin(CAM.pitch);return[x1,dy*cp-z1*sp,dy*sp+z1*cp]}
const ps=c=>[W/2+CAM.f*c[0]/c[2]+CAM.sh[0],H/2-CAM.f*c[1]/c[2]+CAM.sh[1],CAM.f/c[2],c[2]];
function pr(p){const c=cs(p);return c[2]<.08?null:ps(c)}
function clipPoly(P){const o=[],N=.1;for(let i=0;i<P.length;i++){const a=P[i],b=P[(i+1)%P.length];if(a[2]>=N)o.push(a);if((a[2]>=N)!=(b[2]>=N)){const k=(N-a[2])/(b[2]-a[2]);o.push([lerp(a[0],b[0],k),lerp(a[1],b[1],k),N])}}return o.map(ps)}
function polyW(pts,fill){const q=clipPoly(pts.map(cs));if(q.length<3)return;X.beginPath();q.forEach((p,i)=>i?X.lineTo(p[0],p[1]):X.moveTo(p[0],p[1]));X.closePath();X.fillStyle=fill;X.fill()}
function lineW(a,b,col,w){let A=cs(a),Bc=cs(b);if(A[2]<.1&&Bc[2]<.1)return;if(A[2]<.1||Bc[2]<.1){const k=(.1-A[2])/(Bc[2]-A[2]),M=[lerp(A[0],Bc[0],k),lerp(A[1],Bc[1],k),.1];if(A[2]<.1)A=M;else Bc=M}const p=ps(A),q=ps(Bc);X.strokeStyle=col;X.lineWidth=w;X.beginPath();X.moveTo(p[0],p[1]);X.lineTo(q[0],q[1]);X.stroke()}
const circ=(c,r,y,n=64)=>[...Array(n)].map((_,i)=>[c[0]+r*cos(i/n*2*PI),y,c[2]+r*sin(i/n*2*PI)]);
const SKY_T=[[0,'#2B1B4F'],[22,'#3A1F5C'],[26,'#161528'],[40,'#161528'],[42.5,'#3B5BA0'],[52,'#6FA8DC'],[60,'#7FB8E6']];
const SKY_M=[[0,'#B8457A'],[22,'#C4466E'],[26,'#35283F'],[40,'#35283F'],[42.5,'#E68FA0'],[52,'#F7C6A5'],[60,'#FFE1BC']];
const SKY_H=[[0,'#FFB060'],[22,'#FF8A3D'],[26,'#58394C'],[40,'#58394C'],[42.5,'#FFD08A'],[60,'#FFF1C9']];
const SEA=[[0,'#7A4A7A'],[22,'#8A4A6A'],[26,'#2A2438'],[40,'#2A2438'],[42.5,'#E8B8C0'],[60,'#F4E4E0']];
const STONE=[[0,'#6B4E5E'],[22,'#7A5260'],[26,'#3A3444'],[40,'#3A3444'],[42.5,'#B79C9C'],[60,'#C9B2A6']];
function sky(t){const hy=H/2+CAM.f*tan(CAM.pitch)+CAM.sh[1],g=X.createLinearGradient(0,hy-900,0,hy);g.addColorStop(0,key(t,SKY_T));g.addColorStop(.6,key(t,SKY_M));g.addColorStop(1,key(t,SKY_H));X.fillStyle=g;X.fillRect(0,0,W,H);
 const sy=key(t,[[0,24],[26,5],[39,-14],[42,-6],[60,42]]),sa=1-.85*sm(24,27,t)*(1-sm(40,42,t)),sp=pr(V.add(CAM.p,[0,sy,400]));
 if(sp){const sc=key(t,[[0,'#FFD27A'],[26,'#FF6A3D'],[42,'#FFE7A8'],[60,'#FFFBE8']]),g2=X.createRadialGradient(sp[0],sp[1],0,sp[0],sp[1],420);g2.addColorStop(0,rgba(sc,.9*sa));g2.addColorStop(.12,rgba(sc,.45*sa));g2.addColorStop(1,rgba(sc,0));X.fillStyle=g2;X.fillRect(0,0,W,H);X.fillStyle=rgba('#FFFDF0',sa);X.beginPath();X.arc(sp[0],sp[1],30,0,7);X.fill()}
 for(let k=0;k<14;k++){const a=k/14*2*PI+hs(k),p=pr(V.add(CAM.p,[300*sin(a),60+40*hs(k+3),300*cos(a)]));if(!p)continue;const w=p[2]*(60+50*hs(k+5)),g3=X.createRadialGradient(p[0],p[1],0,p[0],p[1],w);const cc=key(t,SKY_M);g3.addColorStop(0,rgba(mixc(cc,'#ffffff',.35),.5));g3.addColorStop(1,rgba(cc,0));X.save();X.translate(p[0],p[1]);X.scale(1,.28);X.translate(-p[0],-p[1]);X.fillStyle=g3;X.fillRect(p[0]-w,p[1]-w,2*w,2*w);X.restore()}
 const mc=mixc(key(t,SEA),key(t,SKY_T),.45);for(let k=0;k<20;k++){const a=k/20*2*PI+hs(k+40)*.2,r=170+70*hs(k+41),hh=22+34*hs(k+42),A=[r*sin(a-.09),-12,r*cos(a-.09)],P=[r*sin(a),-12+hh,r*cos(a)],Bp=[r*sin(a+.1),-12,r*cos(a+.1)];polyW([A,P,Bp],mc);const q=clipPoly([P,V.lerp(P,A,.25),V.lerp(P,Bp,.22)].map(cs));if(q.length>2){X.beginPath();q.forEach((p,i)=>i?X.lineTo(p[0],p[1]):X.moveTo(p[0],p[1]));X.fillStyle=rgba(key(t,SKY_H),.35);X.fill()}}
 const g4=X.createLinearGradient(0,hy,0,H+200);g4.addColorStop(0,rgba(key(t,SEA),.95));g4.addColorStop(1,mixc(key(t,SEA),'#000000',.5));X.fillStyle=g4;X.fillRect(0,hy,W,H-hy+400);
 const pu=[];for(let k=0;k<110;k++){const a=hs(k+60)*2*PI,r=14+260*hs(k+61)**1.6,p=pr([r*sin(a),-4-3*hs(k+62),r*cos(a)]);if(p)pu.push([p,k])}pu.sort((a,b)=>b[0][3]-a[0][3]);
 const top=mixc(key(t,SEA),key(t,SKY_H),.5);for(const[p,k]of pu){const w=p[2]*(3+6*hs(k+63));if(w<2)continue;const g5=X.createRadialGradient(p[0],p[1]-w*.3,0,p[0],p[1],w);g5.addColorStop(0,rgba(top,.9));g5.addColorStop(.7,rgba(key(t,SEA),.7));g5.addColorStop(1,rgba(key(t,SEA),0));X.fillStyle=g5;X.beginPath();X.ellipse(p[0],p[1],w,w*.45,0,0,7);X.fill()}}
function arena(t){const st=key(t,STONE);polyW(circ([0,0,0],7.7,-1.6),mixc(st,'#000000',.55));
 for(let k=0;k<32;k++){const a=k/32*2*PI,b=(k+1)/32*2*PI;polyW([[8*cos(a),0,8*sin(a)],[8*cos(b),0,8*sin(b)],[7.7*cos(b),-1.6,7.7*sin(b)],[7.7*cos(a),-1.6,7.7*sin(a)]],mixc(st,'#000000',.35+.15*sin(a*3)))}
 polyW(circ([0,0,0],8,0),st);X.lineCap='round';
 for(const r of[2,4,6])lineRing(r,rgba('#000000',.18),1.5);for(let k=0;k<12;k++){const a=k/12*2*PI;lineW([2*cos(a),0,2*sin(a)],[8*cos(a),0,8*sin(a)],rgba('#000000',.14),1.2)}
 X.save();X.globalCompositeOperation='lighter';lineRing(1.2,rgba('#5FE3FF',.25+.1*sin(t*2)),2);X.restore()}
function lineRing(r,col,w){const P=circ([0,0,0],r,.005,48);for(let i=0;i<48;i++)lineW(P[i],P[(i+1)%48],col,w)}
const PIL=[0,45,95,140,185,230,275,320].map((a,k)=>({x:7.1*cos(a*R2),z:7.1*sin(a*R2),h:[4,2.2,4,1.3,4,3,1.8,4][k],k}));
function pillars(t){const st=key(t,STONE);return PIL.filter(P=>cs([P.x,1,P.z])[2]>2.2).map(P=>({z:(cs([P.x,1,P.z])[2]),draw(){const b=pr([P.x,0,P.z]),tp=pr([P.x,P.h,P.z]);if(!b||!tp)return;const w=b[2]*.36;const g=X.createLinearGradient(b[0]-w,0,b[0]+w,0);g.addColorStop(0,mixc(st,'#ffffff',.25));g.addColorStop(.35,st);g.addColorStop(1,mixc(st,'#000000',.55));X.fillStyle=g;X.beginPath();X.moveTo(b[0]-w,b[1]);X.lineTo(tp[0]-tp[2]*.34,tp[1]);X.lineTo(tp[0]+tp[2]*.34,tp[1]);X.lineTo(b[0]+w,b[1]);X.fill();
 X.fillStyle=mixc(st,'#ffffff',.15);X.beginPath();X.ellipse(tp[0],tp[1],tp[2]*.36,tp[2]*.1,0,0,7);X.fill();X.fillStyle=mixc(st,'#000000',.2);X.fillRect(b[0]-w*1.15,b[1]-b[2]*.25,w*2.3,b[2]*.25);
 if(P.k==0&&t>24.2){X.strokeStyle='#0d0b14';X.lineWidth=b[2]*.03;X.beginPath();const c=pr([P.x-.35,1.1,P.z]);if(c){X.moveTo(c[0],c[1]);X.lineTo(c[0]+c[2]*.12,c[1]-c[2]*.3);X.lineTo(c[0]+c[2]*.05,c[1]-c[2]*.55);X.moveTo(c[0]+c[2]*.12,c[1]-c[2]*.3);X.lineTo(c[0]+c[2]*.25,c[1]-c[2]*.2);X.stroke()}}}}))}
function post(t,bloom){BX.filter='blur(10px) brightness(1.15)';BX.clearRect(0,0,640,360);BX.drawImage(C,0,0,640,360);X.save();X.globalCompositeOperation='screen';X.globalAlpha=bloom;X.drawImage(B,0,0,W,H);X.restore();
 const gv=X.createRadialGradient(W/2,H/2,H*.35,W/2,H/2,H*.95);gv.addColorStop(0,'rgba(0,0,0,0)');gv.addColorStop(1,'rgba(8,4,16,.6)');X.fillStyle=gv;X.fillRect(0,0,W,H);
 X.fillStyle='#000';X.fillRect(0,0,W,62);X.fillRect(0,H-62,W,62)}
