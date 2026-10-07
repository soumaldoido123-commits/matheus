import sys,subprocess,json,numpy as np
f=sys.argv[1]
info=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=r_frame_rate','-of','json',f]))
num,den=info['streams'][0]['r_frame_rate'].split('/'); fps=float(num)/float(den)
w,h=160,90
raw=subprocess.check_output(['ffmpeg','-v','error','-i',f,'-vf','scale=%d:%d'%(w,h),'-f','rawvideo','-pix_fmt','gray','-'])
q=np.frombuffer(raw,np.uint8).reshape(-1,h,w).astype(float)
d=np.abs(np.diff(q,axis=0)).mean(axis=(1,2))
same=d<1.0
runs=[];r=1
for s in same:
    if s: r+=1
    else: runs.append(r); r=1
runs.append(r)
nd=0;cur=0
for x in d:
    cur=cur+1 if x<1.5 else 0; nd=max(nd,cur)
win=max(1,int(round(fps/2)))
e=[float(d[i:i+win].sum()) for i in range(0,len(d),win)]
m=max(e) or 1
print(json.dumps({'fps':fps,'frames':len(q),'drawings':len(runs),'hold_hist':{str(k):runs.count(k) for k in sorted(set(runs))},'first_runs':runs[:40],'longest_identical_s':round(max(runs)/fps,2),'longest_near_dead_s':round(nd/fps,2),'energy_per_half_second_normalized':[round(x/m,2) for x in e],'energy_floor':round(min(e)/m,2)}))
