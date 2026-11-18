from ring14 import *
from core14 import _motif0
def seg3(k,w,y,items,sel):
    x=k.W-16
    for i in range(len(items)-1,-1,-1):
        t=items[i]; s_=i==sel; tw=k.tw(t,13,'g',800)+24; x-=tw
        rgba_rect(k,(x,y-14,x+tw,y+14),JADE if s_ else BASE,255 if s_ else 210,14,outline=None if s_ else ACC[w],ow=1,oalpha=110)
        k.text((x+tw/2,y),t,13,BASE if s_ else TXT,'g',800,'mm'); x-=6
def fin(k,w,fname,pv=(240,40),orb=True):
    if orb: miniorb(k,w)
    homebar(k); preview(k,k.W-142,k.H-58); k.out(OUT14+fname); return k
# ---------- Habits orbit ----------
def habits(pet='dragon',w=2,fname=None):
    set_pet(pet); k=K(w); W=k.W
    p=RAW12+'habits-shrine.jpg' if (pet=='dragon' and w==2) else None
    art(k,w,blur=6,dim=185,path=p); k.status(TXT)
    header(k,w,'Habits',f'Orbit · 4 of 8 lit · Thu 19 Nov'); seg3(k,w,124,['Habits','Quests','Planner'],0)
    cx,cy=W/2,360; R=132
    k.d.ellipse(k.R([cx-R,cy-R,cx+R,cy+R]),outline=hexc(LINE),width=int(1.5*k.S))
    for i in range(7):
        a=math.radians(-90+i*360/7); r=84; x=cx+r*math.cos(a); y=cy+r*math.sin(a)
        col=ACC[w] if i<3 else (ACC2[w] if i==3 else LINE); k.d.ellipse(k.R([x-4,y-4,x+4,y+4]),fill=hexc(col))
    k.d.ellipse(k.R([cx-62,cy-62,cx+62,cy+62]),fill=hexc(BASE)); por(k,w,cx,cy,56,ring=ACC[w]); ringp(k,cx,cy,64,4/8,ACC2[w],4)
    for i,(n,on,s) in enumerate(HAB):
        a=math.radians(-90+i*45); x=cx+R*math.cos(a); y=cy+R*math.sin(a)
        if on is None: m_next(k,w,x,y,0.35,22)
        elif on: k.glow(x,y,24,ACC[w],80); k.d.ellipse(k.R([x-20,y-20,x+20,y+20]),fill=hexc(RAISED)); k.d.ellipse(k.R([x-20,y-20,x+20,y+20]),outline=hexc(ACC[w]),width=2*k.S); motif(k,w,x,y,1.4,ACC2[w])
        else: k.d.ellipse(k.R([x-20,y-20,x+20,y+20]),fill=hexc(BASE)); k.d.ellipse(k.R([x-20,y-20,x+20,y+20]),outline=hexc(DIMN),width=int(1.4*k.S))
        lx=cx+(R+42)*math.cos(a); ly=cy+(R+38)*math.sin(a); tw=k.tw(s,12,'g',800)+16; lx=min(max(lx,tw/2+6),W-tw/2-6)
        rgba_rect(k,(lx-tw/2,ly-11,lx+tw/2,ly+11),BASE,215,11); k.text((lx,ly),s,12,ACC2[w] if on is None else (TXT if on else MUT),'g',800,'mm')
    y=588; panelw(k,w,(8,y,W-8,y+128),20)
    k.text((24,y+24),T_('Next · Write 25 min'),12,ACC2[w],'mono',800,'lm',sp=0.8); k.text((24,y+50),'5-day run · +8 XP',18,TXT,'disp',anchor='lm')
    k.text((24,y+74),'Hold the glowing node 0.6 s, or tap Light it.',13,MUT,'g',600,'lm')
    btn(k,24,y+86,150,36,'Light it'); btn(k,184,y+86,90,36,'Skip','ghost'); btn(k,282,y+86,84,36,'Undo','secondary')
    return fin(k,w,fname or f'{pet}-w{w}-habits-orbit.png',(240,96))
# ---------- Quests board ----------
def quests():
    w=2; set_pet('dragon'); k=K(w); W=k.W; art(k,w,blur=5,dim=180,path=RAW12+'quest-board.jpg'); k.status(TXT)
    header(k,w,'Quests','Leaf post · 4 pinned · size = reward'); seg3(k,w,124,['Habits','Quests','Planner'],1)
    k.d.line(k.R([W/2,150,W/2,520]),fill=hexc('#3A3F44'),width=3*k.S)   # the post
    qcard(k,w,W/2,212,250,78,'Ship landing page','Main quest · Fri · +20 XP',-1)
    k.d.ellipse(k.R([W/2-5,170,W/2+5,180]),fill=hexc(ACC2[w]))
    for (cx,cy,wd,a,i) in [(104,330,170,-4,1),(290,352,160,3,2),(130,448,160,2,3)]:
        ti,sub,xp=QUESTS[i]; qcard(k,w,cx,cy,wd,58,ti,f'{sub} · {xp}',a); k.d.ellipse(k.R([cx-4,cy-34,cx+4,cy-26]),fill=hexc(ACC2[w]))
    k.glow(104,330,90,ACC2[w],40); pillw(k,w,104,392,'Due today',col=AMBER)
    pillw(k,w,300,470,'Pin a quest',anchor='m')
    y=560; panelw(k,w,(8,y,W-8,y+150),20)
    k.text((24,y+24),T_('Selected · Call the bank'),12,ACC2[w],'mono',800,'lm',sp=0.8); k.text((24,y+52),'Due today · +6 XP',18,TXT,'disp',anchor='lm')
    k.text((24,y+78),'Pluck the note up to finish, or tap Done.',13,MUT,'g',600,'lm')
    btn(k,24,y+98,140,40,'Done'); btn(k,172,y+98,100,40,'Snooze','ghost'); btn(k,280,y+98,86,40,'Undo','secondary')
    return fin(k,w,'dragon-w2-quests-board.png',(240,96))
# ---------- Goal climb ----------
def climb(pet='dragon',w=2,fname=None):
    set_pet(pet); k=K(w); W=k.W; H=k.H
    if pet=='dragon' and w==2: k.art(RAW10+'journey-map.jpg',0,0,W,H,r=0); k.scrim(0,0,W,H,BASE,90,0)
    else: art(k,w,dim=110)
    topscrim(k,150,230); k.status(TXT)
    header(k,w,'Goal climb','Run a 10K · 3 of 5 · each step is a milestone')
    nm,d,t,ms=GOALS[0]
    P={2:[(196,690),(120,590),(230,500),(150,390),(250,280)],3:[(110,690),(170,615),(225,545),(262,478),(300,405)],5:[(196,690),(110,600),(240,520),(130,430),(250,330)],1:[(196,690),(110,600),(240,520),(130,430),(250,330)]}[w]
    for i in range(4): k.d.line(k.R([*P[i],*P[i+1]]),fill=hexc(ACC[w] if i<d-1 else '#3A3F44'),width=3*k.S)
    for i,((x,y),m) in enumerate(zip(P,ms)):
        if i<d: m_lit(k,w,x,y,14)
        elif i==d: m_next(k,w,x,y,0.0,20)
        else: m_off(k,w,x,y,12)
        tw=k.tw(m,13,'g',800)+24; right=x+26+tw<W-6
        x0=x+26 if right else max(6,x-26-tw)
        rgba_rect(k,(x0,y-16,x0+tw,y+16),RAISED if i==d else BASE,240 if i==d else 215,16,outline=ACC2[w] if i==d else ACC[w],ow=1,oalpha=200 if i==d else 90)
        k.text((x0+12,y),m,13,ACC2[w] if i==d else (TXT if i<d else MUT),'g',800,'lm')
    x,y=P[d]; hero(k,w,x,y-36,'Hold to log · or tap','m')
    for (x,y,n,dd,tt) in [(44,190,'Japanese',4,5),(346,190,'Software biz',2,6)]:
        k.d.ellipse(k.R([x-20,y-20,x+20,y+20]),fill=hexc(BASE)); ringp(k,x,y,18,dd/tt,ACC[w]); k.text((x,y),f'{dd}/{tt}',12,TXT,'mono',800,'mm')
        tw=k.tw(n,12,'g',800)+16; xx=min(max(x,tw/2+6),W-tw/2-6); rgba_rect(k,(xx-tw/2,y+22,xx+tw/2,y+44),BASE,215,11); k.text((xx,y+33),n,12,TXT,'g',800,'mm')
    k.text((W/2,744),'Side trails = your other goals · tap one to switch climbs',12,MUT,'g',700,'mm')
    return fin(k,w,fname or f'{pet}-w{w}-goal-climb.png',(240,104))
# ---------- Money blocks ----------
def money():
    w=2; set_pet('dragon'); k=K(w); W=k.W
    k.art(RAW13+'ledger-nook.jpg',0,0,W,330,crop=(0,0,720,900),r=0,fade=[('bottom',0.45)],fade_amt=1.0); topscrim(k); k.status(TXT)
    header(k,w,'Money','November · INR · never earns XP')
    y=232; panelw(k,w,(8,y,W-8,y+150),20)
    cx,cy=82,y+75; r=52
    k.d.ellipse(k.R([cx-r,cy-r,cx+r,cy+r]),outline=hexc(LINE),width=12*k.S)
    cols=['#7BD389','#F2A93B','#8F9194','#6CC3E8']; start=-90
    for (n,v),c in zip(MONEY[2],cols):
        ext=360*v/30000; k.d.arc(k.R([cx-r,cy-r,cx+r,cy+r]),start,start+ext-2,fill=hexc(c),width=12*k.S); start+=ext
    k.text((cx,cy-6),'62%',18,TXT,'disp',anchor='mm'); k.text((cx,cy+14),'spent',12,MUT,'g',600,'mm')
    k.text((160,y+40),T_('Spent'),12,ACC2[w],'mono',800,'lm',sp=0.8); k.text((160,y+68),'₹18,450',26,TXT,'disp',anchor='lm'); k.text((160,y+96),'of ₹30,000 · ₹11,550 left',13,MUT,'g',600,'lm')
    k.text((160,y+122),'11 days to go · ₹1,050 a day',12,MUT,'g',600,'lm')
    y=392; Hh=196
    tm=[('Bills',7900,'#7BD389',(8,y,8+200,y+Hh)),('Food',6200,'#F2A93B',(214,y,W-8,y+116)),('Other',2250,'#8F9194',(214,y+122,300,y+Hh)),('Travel',2100,'#6CC3E8',(306,y+122,W-8,y+Hh))]
    for n,v,c,(a,b,cc,d) in tm:
        rgba_rect(k,(a,b,cc,d),SURF,235,16,outline=c,ow=1.2,oalpha=180); k.d.rounded_rectangle(k.R([a+10,b+10,a+14,b+30]),2*k.S,fill=hexc(c))
        k.text((a+22,b+20),n,14,TXT,'g',800,'lm'); k.text((a+22,b+42),f'₹{v:,}',15 if v>3000 else 13,TXT,'disp',anchor='lm')
    k.text((16,y+Hh+18),'Block size = share of spend · tap a block for its entries',12,MUT,'g',600,'lm')
    k.text((16,630),T_('Recent'),12,ACC2[w],'mono',800,'lm',sp=0.8); xx=16
    for t in ['Chai ₹40','Auto ₹120','Groceries ₹860']:
        tw=k.tw(t,13,'g',800)+26; rgba_rect(k,(xx,644,xx+tw,676),SURF,235,16,outline=ACC[w],ow=1,oalpha=100); k.text((xx+tw/2,660),t,13,TXT,'g',800,'mm'); xx+=tw+8
    btn(k,8,694,W-120,46,'Add spend',icon='plus'); btn(k,W-104,694,96,46,'Undo','secondary')
    return fin(k,w,'dragon-w2-money-blocks.png',(240,96))
# ---------- Planner day dial ----------
def planner():
    w=2; set_pet('dragon'); k=K(w); W=k.W; art(k,w,blur=6,dim=190,path=RAW10+'planner-route.jpg'); k.status(TXT)
    header(k,w,'Planner','Thu 19 Nov · day dial · drag a stop or tap it'); seg3(k,w,124,['Habits','Quests','Planner'],2)
    days=['M','T','W','T','F','S','S']; dw=(W-32)/7
    for i,dd in enumerate(days):
        cx=16+dw*(i+0.5); cur=i==3
        if cur: rgba_rect(k,(cx-18,150,cx+18,186),JADE,255,12)
        k.text((cx,160),dd,12,BASE if cur else MUT,'g',800,'mm'); k.text((cx,176),str(16+i),13,BASE if cur else TXT,'g',800,'mm')
    cx,cy,R=W/2,400,120
    k.d.ellipse(k.R([cx-R,cy-R,cx+R,cy+R]),outline=hexc(LINE),width=10*k.S)
    def ang(h): return -90+(h-6)/18*360   # 6:00 at top, wraps to 24:00
    k.d.arc(k.R([cx-R,cy-R,cx+R,cy+R]),ang(6),ang(9.5),fill=hexc(ACC[w]),width=10*k.S)
    k.d.arc(k.R([cx-R,cy-R,cx+R,cy+R]),ang(9.5),ang(11.5),fill=hexc(ACC2[w]),width=10*k.S)
    stops=[(7.0,'7:00','Walk 20 min',True),(9.5,'9:30','Ship landing page',None),(13.0,'13:00','Call the bank',False),(17.5,'17:30','Write 25 min',False),(21.0,'21:00','Wrap-up with Ruu',False)]
    for h_,tm,ti,st in stops:
        a=math.radians(ang(h_)); x=cx+R*math.cos(a); y=cy+R*math.sin(a)
        (m_lit(k,w,x,y,11) if st else m_next(k,w,x,y,0.4,15) if st is None else m_off(k,w,x,y,10))
        lx=cx+(R+30)*math.cos(a); ly=cy+(R+30)*math.sin(a); right=math.cos(a)>=0
        tw=max(k.tw(ti,13,'g',800),k.tw(tm,12,'mono',800))+20
        x0=min(lx,W-8-tw) if right else max(8,lx-tw)
        rgba_rect(k,(x0,ly-22,x0+tw,ly+22),RAISED if st is None else BASE,240,12,outline=ACC2[w] if st is None else ACC[w],ow=1,oalpha=180 if st is None else 80)
        k.text((x0+10,ly-8),tm,12,ACC2[w] if st is None else MOSS,'mono',800,'lm'); k.text((x0+10,ly+9),ti,13,TXT,'g',800,'lm')
    k.d.ellipse(k.R([cx-70,cy-70,cx+70,cy+70]),fill=hexc(BASE))
    k.text((cx,cy-22),T_('Now'),12,ACC2[w],'mono',800,'mm',sp=1); k.text((cx,cy+2),'9:30',22,TXT,'disp',anchor='mm'); k.text((cx,cy+26),'Ship page · 2 h',12,MUT,'g',700,'mm')
    y=600; panelw(k,w,(8,y,W-8,y+112),20)
    k.text((24,y+24),T_('Now · Ship landing page'),12,ACC2[w],'mono',800,'lm',sp=0.8); k.text((24,y+50),'Main quest · 2 h block',17,TXT,'disp',anchor='lm')
    btn(k,24,y+66,150,38,'Start'); btn(k,182,y+66,100,38,'Move','ghost'); btn(k,290,y+66,76,38,'Undo','secondary')
    return fin(k,w,'dragon-w2-planner-dial.png',(240,96))
# ---------- Journey ----------
def journey():
    w=2; set_pet('dragon'); k=K(w); W=k.W
    k.art(RAW10+'world-map-clean.jpg',0,0,W,844,r=0); k.scrim(0,0,W,844,BASE,60,0); topscrim(k,150,240); k.status(TXT)
    header(k,w,'Journey','Five worlds · one climb · Lv 33 of 100')
    P=[(5,'Star Summit','Lv 85–100',300,170,False),(4,'Wind Temple','Lv 65–84',290,268,False),(3,'Cliff Shrine','Lv 45–64',100,362,False),(2,'Moss Ledge','Lv 25–44 · you are here',270,470,True),(1,'Ember Nest','Lv 1–24 · complete',110,560,'done')]
    for n,nm,rng,x,y,st in P:
        if st is True:
            tw=max(k.tw(nm,17,'disp'),k.tw(rng,12,'g',700))+44; x=min(x,W-8-tw/2)
            k.glow(x,y,tw/2,ACC2[2],60); rgba_rect(k,(x-tw/2,y-26,x+tw/2,y+26),RAISED,245,16,outline=ACC2[2],ow=1.4,oalpha=230)
            _motif0(k,n,x-tw/2+16,y-8,1.0,ACC2[2]); k.text((x-tw/2+28,y-8),nm,17,TXT,'disp',anchor='lm'); k.text((x-tw/2+28,y+13),rng,12,MOSS,'g',700,'lm')
        else:
            tw=max(k.tw(nm,15,'disp'),k.tw(rng,12,'g',600))+42; a=st=='done'
            rgba_rect(k,(x-tw/2,y-24,x+tw/2,y+24),BASE,215,14,outline=DACC[n] if a else '#4A4E52',ow=1,oalpha=140)
            _motif0(k,n,x-tw/2+15,y-8,0.9,DACC[n] if a else '#4A4E52'); k.text((x-tw/2+27,y-8),nm,15,TXT if a else MUT,'disp',anchor='lm'); k.text((x-tw/2+27,y+12),rng,12,MUT,'g',600,'lm')
            if not a: k.icon('lock',x+tw/2-14,y-8,6,'#4A4E52')
    y=612; panelw(k,w,(8,y,W-8,y+86),18); info=info_for(2)
    k.text((24,y+22),T_('Lv 33 · Ledgewalker'),12,MOSS,'mono',800,'lm',sp=0.8); k.text((24,y+48),f"{info['to']} XP to Lv 34",19,TXT,'disp',anchor='lm'); bar(k,24,y+66,W-48,info['frac'],8)
    k.text((W-24,y+48),'Glider at Lv 35',12,MUT,'g',600,'rm')
    x=8
    for t in ['Relic room · 12','Season · 3 of 4','Chapters']: x+=chip(k,w,x,724,t)+6
    return fin(k,w,'dragon-w2-journey.png',(240,104))
# ---------- Prayer sky dial ----------
def prayer():
    w=2; set_pet('dragon'); k=K(w); W=k.W; art(k,w,blur=6,dim=200,path=RAW12+'evening.jpg'); k.status(TXT)
    header(k,w,'Prayer','Tracked, never scored · no XP · no streak')
    cx,cy,R=W/2,470,150
    k.d.arc(k.R([cx-R,cy-R,cx+R,cy+R]),180,360,fill=hexc('#4A4E52'),width=int(1.5*k.S))
    names=[('Dawn','5:12'),('Midday','12:24'),('Afternoon','15:41'),('Sunset','17:58'),('Night','19:15')]
    for i,(n,t) in enumerate(names):
        a=math.radians(180+i*45); x=cx+R*math.cos(a); y=cy+R*math.sin(a); done=i<3; nxt=i==3
        if nxt: k.glow(x,y,26,ASK,90)
        k.d.ellipse(k.R([x-20,y-20,x+20,y+20]),fill=hexc(ASK) if done else hexc(BASE),outline=hexc(ASK),width=int(1.6*k.S))
        if done: k.icon('tick',x,y,8,BASE,2.6)
        else: k.d.ellipse(k.R([x-7,y-7,x+7,y+7]),fill=hexc('#E6DEFF') if nxt else None,outline=hexc(ASK),width=k.S)
        ly=y-36 if i in (1,2,3) else y+36; lx=min(max(x,40),W-40)
        k.text((lx,ly-7),n,13,TXT if (done or nxt) else MUT,'g',800,'mm'); k.text((lx,ly+9),t,12,MUT,'g',600,'mm')
    k.text((cx,cy-40),'3 of 5',30,ASK,'disp',anchor='mm'); k.text((cx,cy-8),'today',13,MUT,'g',600,'mm')
    for i in range(7):
        x=W/2-90+i*30; f=[5,5,4,5,3,5,3][i]/5; ringp(k,x,cy+70,10,f,ASK,3)
        k.text((x,cy+94),'MTWTFSS'[i],12,MUT,'g',700,'mm')
    k.text((cx,cy+118),'This week · shown, never ranked',12,DIMN,'g',600,'mm')
    y=620; panelw(k,w,(8,y,W-8,y+94),20,ol=ASK)
    k.text((24,y+24),T_('Next · Sunset · 17:58'),12,ASK,'mono',800,'lm',sp=0.8)
    btn(k,24,y+44,170,40,'Mark Sunset'); btn(k,202,y+44,80,40,'Later','ghost'); btn(k,290,y+44,76,40,'Undo','secondary')
    return fin(k,w,'dragon-w2-prayer-sky.png',(240,96))
# ---------- Books & Movies shelf ----------
def shelf():
    w=2; set_pet('dragon'); k=K(w); W=k.W; art(k,w,blur=6,dim=200,path=RAW12+'relic-room.jpg'); k.status(TXT)
    header(k,w,'Night nook','Books & Movies · for you, never XP'); seg3(k,w,124,['Books','Movies'],0)
    y0=170; k.text((16,y0),T_('Books · 3 of 12 this year'),12,ACC2[w],'mono',800,'lm',sp=0.8)
    base=330; rgba_rect(k,(8,base,W-8,base+10),'#3A3F44',255,3)
    cols=['#8B5A2B','#2F6E54','#6B4F8A','#4A4E52','#4A4E52','#3A3F44','#3A3F44','#3A3F44','#3A3F44','#3A3F44','#3A3F44','#3A3F44']
    hs=[120,134,112,126,104,118,130,110,124,116,108,128]; x=18
    for i in range(12):
        wd=24 if i!=3 else 34; h=hs[i]; done=i<3; cur=i==3
        if cur: k.glow(x+wd/2,base-h/2,40,ACC2[w],60)
        rgba_rect(k,(x,base-h,x+wd,base),cols[i] if (done or cur) else BASE,255 if (done or cur) else 160,3,outline=None if (done or cur) else '#4A4E52',ow=1,oalpha=200)
        if done: k.icon('tick',x+wd/2,base-14,5,TXT,2)
        if cur: k.d.rounded_rectangle(k.R([x+4,base-h+6,x+wd-4,base-h+6+((h-12)*0.62)]),2*k.S,fill=hexc(ACC2[w]))
        x+=wd+4
    pillw(k,w,40+3*28+17,base-150,'Reading · 62%',hero=True)
    k.text((16,base+28),'The Left Hand of Darkness · p. 186 of 300',13,TXT,'g',700,'lm')
    y1=410; k.text((16,y1),T_('Movies · 2 in November'),12,ACC2[w],'mono',800,'lm',sp=0.8)
    for i,(t,s_,a,x,y) in enumerate([('Perfect Days','Nov 3 · home',-6,110,500),('Past Lives','Nov 14 · cinema',4,270,510)]):
        c=K9(W=170,H=96,world=2); c.im=Image.new('RGBA',(340,192),(0,0,0,0)); c.d=ImageDraw.Draw(c.im)
        rgba_rect(c,(2,2,168,94),'#E8E0CC',250,8); c.d.line(c.R([120,8,120,88]),fill=hexc('#9A927E'),width=2)
        c.text((12,30),t,14,'#1A1A1A','g',800,'lm'); c.text((12,52),s_,12,'#4A4E52','g',600,'lm'); c.icon('clap',145,48,7,'#4A4E52')
        im=c.im.rotate(a,resample=Image.BICUBIC,expand=True); k.im.paste(im,(int(x*k.S-im.width/2),int(y*k.S-im.height/2)),im)
    pillw(k,w,W/2,590,'Watchlist · 5 waiting')
    btn(k,8,690,(W-24)/2,46,'Log a page',icon='book'); btn(k,W/2+4,690,(W-24)/2,46,'Add a film','secondary')
    return fin(k,w,'dragon-w2-books-movies.png',(240,96))
# ---------- Chat ----------
def chat():
    w=2; set_pet('dragon'); k=K(w); W=k.W
    k.art(RAW12+'campfire.jpg',0,0,W,300,crop=(0,40,720,640),r=0,fade=[('bottom',0.45)],fade_amt=1.0); topscrim(k); k.status(TXT)
    header(k,w,'Campfire','Talk with Ruu · on-device, not AI')
    y=286; h=bubble(k,w,8,y,200,"what's left today?",me=True); y+=h+10
    por(k,w,30,y+18,16); h=bubble(k,w,54,y,300,"Four wicks still dark, Shabas. The bank call is due today."); y+=h+10
    # inline orbit summary instead of a list
    cx,cy=150,y+62; panelw(k,w,(54,y,W-36,y+124),16)
    for i,(n,on,s) in enumerate(HAB):
        a=math.radians(-90+i*45); x=cx-60+34*math.cos(a)+0; yy=cy+34*math.sin(a)
        (m_lit(k,w,x+0,yy,6) if on else m_next(k,w,x,yy,0.35,8) if on is None else m_off(k,w,x,yy,5))
    k.text((cx-60,cy),'4/8',12,TXT,'mono',800,'mm')
    k.text((160,y+30),'Write 25 min · hold to light',13,ACC2[w],'g',800,'lm'); k.text((160,y+56),'Call the bank · today',13,TXT,'g',700,'lm'); k.text((160,y+82),'Ship page · Fri · +20 XP',13,MUT,'g',600,'lm')
    y+=134; h=bubble(k,w,8,y,190,'log write 25 min',me=True); y+=h+10
    por(k,w,30,y+18,16); h=bubble(k,w,54,y,300,"Write 25 min, today, +8 XP. Light it?"); y+=h+8
    btn(k,54,y,120,40,'Light it'); btn(k,182,y,104,40,'Not now','ghost')
    # quick replies on an arc above the composer
    for i,t in enumerate(['Streaks','Next quest','Goal 10K','Prayer']):
        x=[60,150,246,336][i]; yy=692-[6,14,14,6][i]; tw=k.tw(t,13,'g',700)+24
        rgba_rect(k,(x-tw/2,yy-15,x+tw/2,yy+15),BASE,215,15,outline=ACC[w],ow=1,oalpha=110); k.text((x,yy),t,13,TXT,'g',700,'mm')
    rgba_rect(k,(8,714,W-60,756),SURF,240,21,outline=ACC[w],ow=1,oalpha=100); k.text((26,735),'Ask Ruu about your day…',14,MUT,'g',600,'lm')
    k.d.ellipse(k.R([W-52,714,W-10,756]),fill=hexc(JADE)); k.icon('chev',W-31,735,8,BASE)
    homebar(k); preview(k,240,40); k.out(OUT14+'dragon-w2-chat.png'); return k
# ---------- Settings bento ----------
def settings():
    w=2; set_pet('dragon'); k=K(w); W=k.W; k.status(TXT)
    header(k,w,'Settings','Ruu’s den · grouped by what you change')
    y=100; panelw(k,w,(8,y,W-8,y+84),18); por(k,w,48,y+42,28)
    k.text((90,y+28),'Ruu · Ledgewalker',17,TXT,'disp',anchor='lm'); k.text((90,y+52),'Dragon · chosen at start · calls you Shabas',12,MUT,'g',600,'lm')
    k.icon('lock',W-28,y+42,7,DIMN)
    # bento: navigation (tall) | motion | theme ; rhythm (wide) ; language | data
    def tile_(box,title_,lines,tog=None):
        panelw(k,w,box,18); x0,y0,x1,y1=box
        k.text((x0+14,y0+20),T_(title_),12,ACC2[w],'mono',800,'lm',sp=0.6)
        for i,(a,b,t) in enumerate(lines):
            yy=y0+50+i*52; k.text((x0+14,yy),a,14,TXT,'g',800,'lm'); 
            if b=='__ml':
                k.text((x0+14,yy+20),'Latin · ',12,MUT,'g',600,'lm'); x2=x0+14+k.tw('Latin · ',12,'g',600); fb_text(k,x2,yy+20,'മലയാളം','ml',12,MUT); fb_text(k,x2+56,yy+20,'العربية','ar',13,MUT)
            else: k.text((x0+14,yy+20),b,12,MUT,'g',600,'lm')
            if t is not None: toggle(k,x1-60,yy+2,t)
    tile_((8,196,196,404),'Navigation',[('List mode','Plain labelled list',False),('Left-hand orb','Mirror the ring',False),('Labels','On first run',True)])
    tile_((202,196,W-8,300),'Motion',[('Reduced motion','No fan, no particles',True)])
    tile_((202,306,W-8,404),'Theme',[('Charcoal','Dark · default',None)])
    tile_((8,410,W-8,520),'Rhythm',[('Morning 7:00 · Wrap-up 21:00','Prayer tracking · never scored',True)])
    tile_((8,526,196,640),'Language',[('Scripts','__ml',None)])
    tile_((202,526,W-8,640),'Data',[('Export','JSON · local',None)])
    return fin(k,w,'dragon-w2-settings.png',(240,48))
# ---------- Level up ----------
def levelup():
    w=2; set_pet('dragon'); k=K(w); W=k.W
    k.art(RAW12+'levelup.jpg',0,0,W,560,crop=(0,0,720,1030),r=0,fade=[('bottom',0.35)],fade_amt=1.0); k.status(TXT)
    k.particles(0,60,W,420,ACC2[w],24,4,2.2,220)
    cx,cy=W/2,560
    k.text((cx,470),T_('Level up'),13,ACC2[w],'mono',800,'mm',sp=2.0)
    k.text((cx-18,530),'Lv',26,MOSS,'disp',anchor='rs'); k.text((cx-10,540),'34',72,TXT,'disp',anchor='ls')
    k.text((cx,568),'Ruu is still a Ledgewalker · Glider at Lv 35',13,MUT,'g',600,'mm')
    for (t,x,y) in [('Write 25 min · +8',80,612),('Bank · +6',W/2,628),('Walk 34 d · +6',W-80,612)]:
        tw=k.tw(t,12,'g',800)+20; rgba_rect(k,(x-tw/2,y-13,x+tw/2,y+13),BASE,225,13,outline=ACC[w],ow=1,oalpha=120); k.text((x,y),t,12,ACC2[w],'g',800,'mm')
    say_d(k,w,"Thirty-four. The ledge holds, Shabas.",y=652)
    btn(k,8,724,W-16,46,'Continue')
    homebar(k); preview(k,240,40); k.out(OUT14+'dragon-w2-level-up.png'); return k
# ---------- Morning / evening ----------
def morning():
    w=2; set_pet('dragon'); k=K(w); W=k.W
    k.art(RAW12+'morning.jpg',0,0,W,844,r=0,fade=[('bottom',0.62)],fade_amt=0.8); topscrim(k,150,210); k.status(TXT)
    k.text((16,62),T_('Thu 19 Nov · 7:02 AM'),12,ACC2[w],'mono',800,'lm',sp=0.8); k.text((16,90),'Morning briefing',26,TXT,'disp',anchor='lm')
    # today as a constellation of tokens around the day's first step
    toks=[(110,330,44,'check','8 habits','Walk first',MOSS),(282,320,36,'flag','2 quests','Bank today',TXT),(296,452,34,'target','10K · 3/5','8 km next',AMBER),(96,470,30,'moon','Prayer · 5','never scored',ASK)]
    for i in range(len(toks)-1):
        pass
    cx,cy=W/2,400; k.d.ellipse(k.R([cx-36,cy-36,cx+36,cy+36]),fill=hexc(BASE)); por(k,w,cx,cy,32)
    for (x,y,r,ic,a,b,c) in toks:
        k.d.line(k.R([cx,cy,x,y]),fill=hexc('#3A3F44'),width=k.S)
    for (x,y,r,ic,a,b,c) in toks:
        k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),fill=hexc(BASE)); k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),outline=hexc(c),width=int(1.5*k.S)); k.icon(ic,x,y,13,c)
        tw=max(k.tw(a,13,'g',800),k.tw(b,12,'g',600))+18; rgba_rect(k,(x-tw/2,y+r+2,x+tw/2,y+r+38),BASE,215,10)
        k.text((x,y+r+12),a,13,TXT,'g',800,'mm'); k.text((x,y+r+28),b,12,MUT,'g',600,'mm')
    say_d(k,w,"Morning, Shabas. Four wicks wait from yesterday's rhythm, and the bank is due today.",y=580)
    btn(k,8,690,W-120,46,'Start the day'); btn(k,W-104,690,96,46,'Later','ghost')
    return fin(k,w,'dragon-w2-morning.png',(240,124))
def evening():
    w=2; set_pet('dragon'); k=K(w); W=k.W
    k.art(RAW12+'evening.jpg',0,0,W,844,r=0,fade=[('bottom',0.65)],fade_amt=0.85); topscrim(k,150,210); k.status(TXT)
    k.text((16,62),T_('Thu 19 Nov · 9:00 PM'),12,ACC2[w],'mono',800,'lm',sp=0.8); k.text((16,90),'Evening wrap-up',26,TXT,'disp',anchor='lm')
    # lantern string: tonight's chronicle hung across the scene
    pts=[(40,250),(115,286),(195,298),(275,286),(350,250)]
    k.d.line([(x*k.S,y*k.S) for x,y in [(0,230)]+pts+[(390,230)]],fill=hexc('#6B6F74'),width=k.S,joint='curve')
    items=[('tick','Walk','34 d',MOSS),('tick','Write','6:40 PM',MOSS),('flag','Bank','+6 XP',TXT),('moon','Prayer','5 of 5',ASK),('leaf','Floss','rested',DIMN)]
    for (x,y),(ic,a,b,c) in zip(pts,items):
        k.d.line(k.R([x,y,x,y+14]),fill=hexc('#6B6F74'),width=k.S)
        rgba_rect(k,(x-22,y+14,x+22,y+62),BASE,230,12,outline=c,ow=1,oalpha=150)
        (k.icon(ic,x,y+38,11,c) if ic!='leaf' else _motif0(k,2,x,y+38,1.4,c))
        tw=max(k.tw(a,13,'g',800),k.tw(b,12,'g',600))+16; rgba_rect(k,(x-tw/2,y+66,x+tw/2,y+104),BASE,225,10)
        k.text((x,y+78),a,13,TXT,'g',800,'mm'); k.text((x,y+94),b,12,MUT,'g',600,'mm')
    y=420; gw=(W-28)/3
    for i,(a,b,c) in enumerate([('6 / 8','habits lit',MOSS),('1','quest done',TXT),('+38','XP today',AMBER)]):
        x=8+i*(gw+6); panelw(k,w,(x,y,x+gw,y+66),16); k.text((x+gw/2,y+26),a,22,c,'disp',anchor='mm'); k.text((x+gw/2,y+50),b,12,MUT,'g',600,'mm')
    say_d(k,w,"Six of eight tonight, Shabas. Floss and Meditate rest; tomorrow's a fresh wick.",y=510)
    rgba_rect(k,(8,612,W-8,656),SURF,235,14,outline=ACC[w],ow=1,oalpha=90); k.text((22,634),'One line for the journal…',14,MUT,'dlg',600,'lm')
    btn(k,8,668,W-16,46,'Close the day')
    return fin(k,w,'dragon-w2-evening.png',(240,124))
# ---------- First-run demo + list mode ----------
def demo():
    k=home('dragon',2,demo=True,say=False); W=k.W; H=k.H; w=2
    k.scrim(0,0,W,H,BASE,215,0)
    cx,cy=W/2,H-72
    k.glow(cx,cy,70,ACC2[w],90); orb2(k,w,cx,cy,hint=False)
    k.finger(cx+6,cy+4,press=True); ringp(k,cx,cy,42,0.6,ACC2[w],4)
    k.text((W/2,170),T_('First run · 1 of 3'),12,ACC2[w],'mono',800,'mm',sp=1)
    k.text((W/2,212),'This is Ruu.',28,TXT,'disp',anchor='mm')
    k.text((W/2,250),'Everything else lives in Ruu’s ring.',15,MUT,'g',700,'mm')
    for i,(n,t) in enumerate([('1','Hold Ruu · the ring fans open'),('2','Slide to a place · release to go'),('3','Or just tap Ruu, then tap a place')]):
        y=320+i*58; rgba_rect(k,(40,y-22,W-40,y+22),SURF,240,22,outline=ACC[w],ow=1,oalpha=100)
        k.d.ellipse(k.R([52,y-14,80,y+14]),fill=hexc(ACC2[w])); k.text((66,y),n,13,BASE,'g',800,'mm'); k.text((92,y),t,14,TXT,'g',700,'lm')
    k.text((W/2,520),'Objects in the scene open things too: stones, lanterns, the leaf post.',12,MUT,'g',600,'mm')
    say_d(k,w,"Hold me, Shabas. Or tap. Either works.",y=600)
    btn(k,12,680-6,110,40,'Skip','ghost'); btn(k,W-150,674,138,40,'Try it')
    k.text((cx,H-18),'Hold Ruu · or tap',13,ACC2[w],'g',800,'mm')
    homebar(k); k.out(OUT14+'dragon-w2-first-run-demo.png'); return k
def listmode():
    w=2; set_pet('dragon'); k=K(w); W=k.W; k.status(TXT)
    header(k,w,'Places','List mode · on · for screen readers and anyone')
    groups=[('Sections',[('home','Home','Moss Ledge · Lv 33'),('check','Habits & Quests','4 of 8 lit · 4 quests'),('wallet','Money','₹18,450 of ₹30,000'),('moon','Prayer','3 of 5 · not scored'),('book','Books','3 of 12 · no XP'),('clap','Movies','2 in Nov · no XP')]),
            ('More',[('target','Goals','Run a 10K · 3 of 5'),('pin','Planner · Journey','Today · Chapter 2'),('chat','Chat with Ruu','On-device'),('gear','Settings','List mode on')])]
    y=110
    for g,rows in groups:
        k.text((16,y),T_(g),12,ACC2[w],'mono',800,'lm',sp=1); y+=14
        for ic,a,b in rows:
            rgba_rect(k,(8,y,W-8,y+52),SURF,255,12,outline=LINE,ow=1,oalpha=255); k.icon(ic,32,y+26,9,TXT)
            k.text((56,y+18),a,15,TXT,'g',800,'lm'); k.text((56,y+36),b,12,MUT,'g',600,'lm'); k.icon('chev',W-28,y+26,7,MUT); y+=56
        y+=14
    k.text((16,y+4),'Same places as the ring · 56 px rows · reading order = priority',12,MUT,'g',600,'lm')
    homebar(k); preview(k,240,48); k.out(OUT14+'dragon-w2-list-mode.png'); return k
ALL=['habits','quests','climb','money','planner','journey','prayer','shelf','chat','settings','levelup','morning','evening','demo','listmode']
if __name__=='__main__':
    import sys as _s
    for f in (_s.argv[1:] or ALL): globals()[f]()
