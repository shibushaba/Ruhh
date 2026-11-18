# v14 core: neutral charcoal chrome + pets + living-scene navigation helpers
import sys
sys.path.insert(0,'/workspace/ruhh/anime/v13/tools'); sys.path.insert(0,'/workspace/ruhh/anime/v12/tools')
import nav13
from nav13 import *
import kit11, kit12, screens12, homes12, nb, soft, k9, story
OUT14='/workspace/ruhh/anime/v14/screens/'; RAW14='/workspace/ruhh/anime/v14/raw/'
# ---------- 1. neutral charcoal chrome (art untouched) ----------
BASE='#0E0F10'; SURF='#16181A'; RAISED='#1F2225'; LINE='#2A2E32'; TXT='#F4EEDC'; MUT='#B3B0A9'; DIMN='#8F9194'
REMAP={'#0B1A17':BASE,'#0E1D19':'#121315','#112622':SURF,'#0E2420':SURF,'#16130E':SURF,'#1A1512':SURF,'#0E1F2C':SURF,'#0D1426':SURF,
 '#17332D':RAISED,'#163A31':RAISED,'#1B3B33':'#26292C','#24463E':LINE,'#3B6E5E':'#3A3F44','#4E5F59':'#4A4E52','#9FB5AC':DIMN,'#B5C4BB':MUT,
 '#13221E':BASE,'#21362F':'#141618','#1B2E28':SURF,'#24403A':RAISED,'#05100D':'#050506','#1F5E46':'#1F5E46','#7F9A96':'#7E8286','#1F2D29':RAISED}
_hexc0=kit11.hexc; _hx0=nb.hx
def hexc_n(c): return _hexc0(REMAP.get(c.upper(),c) if isinstance(c,str) else c)
def hx_n(h): return _hx0(REMAP.get(('#'+h.lstrip('#')).upper(),h))
for m in list(sys.modules.values()):
    if m is None: continue
    if getattr(m,'hexc',None) is _hexc0: m.hexc=hexc_n
    if getattr(m,'hx',None) is _hx0: m.hx=hx_n
hexc=hexc_n
for mod in (kit11,kit12,screens12,homes12,nav13):
    for nm,v in (('INK',BASE),('MUTED',MUT),('DIMC',DIMN)):
        if hasattr(mod,nm): setattr(mod,nm,v)
INK=BASE; MUTED=MUT; DIMC=DIMN
for w in TINT: TINT[w]=SURF
# ---------- 2. pets ----------
DACC=dict(ACC); DACC2=dict(ACC2)
PETS={
 'dragon':dict(name='Ruu',kind='Dragon',worlds=dict(CHN),acc=DACC,acc2=DACC2,
     forms=['Ember Egg → Hearthling','Mossback · Ledgewalker','Bellwing · Lanternheart','Windrider · Stormhorn','Starbreath → Lanternsky'],
     art={w:RAW10+f'hub-w{w}.jpg' for w in range(1,6)},por={w:POR[w] for w in range(1,6)}),
 'panda':dict(name='Sumi',kind='Panda',worlds={1:'Bamboo Hollow',2:'Mist Terraces',3:'River Gorge',4:'Plum Cloud',5:'Moon Peak'},
     acc={1:'#D9C08A',2:'#A8D5A2',3:'#8FC9C2',4:'#E3A9C4',5:'#E8E2C8'},acc2={1:'#F2E2B8',2:'#D6EFD1',3:'#C9EAE5',4:'#F5D5E4',5:'#F7F3E3'},
     forms=['Cub','Bamboo Scout','Mist Walker','Plum Guardian','Moon Sage'],
     art={1:RAW14+'panda-w1.jpg',5:RAW14+'panda-w5.jpg'},por={1:(270,365,480,575),5:(300,315,430,445)}),
 'cat':dict(name='Kage',kind='Cat',worlds={1:'Lantern Alley',2:'Rooftop Gardens',3:'Old Library',4:'Harbor Lights',5:'Starlit Rooftops'},
     acc={1:'#F2B35E',2:'#9CCB86',3:'#C9A27A',4:'#7FB6D9',5:'#A9B9F2'},acc2={1:'#FFD9A0',2:'#D3EBC6',3:'#EBD5BC',4:'#C6E2F3',5:'#D9E0FB'},
     forms=['Kitten','Alley Shade','Roof Runner','Harbor Watcher','Star Warden'],
     art={1:RAW14+'cat-w1.jpg',5:RAW14+'cat-w5.jpg'},por={1:(262,385,392,515),5:(318,480,432,594)})}
CUR={'pet':'dragon'}
_motif0=kit12.motif; _por0=kit12.por
def set_pet(p):
    CUR['pet']=p; ACC.update(PETS[p]['acc']); ACC2.update(PETS[p]['acc2'])
def pmotif(k,w,x,y,s=1.0,col=None):
    p=CUR['pet']; c=col or ACC[w]
    if p=='dragon': return _motif0(k,w,x,y,s,col)
    if p=='panda':   # ensō: open brush circle
        r=5.5*s; k.d.arc(k.R([x-r,y-r,x+r,y+r]),-60,250,fill=hexc(c),width=max(1,int(1.8*s*k.S)))
    else:            # cat: slit eye
        pts=[(x-6*s,y),(x,y-4*s),(x+6*s,y),(x,y+4*s)]
        k.d.polygon([(a*k.S,b*k.S) for a,b in pts],fill=hexc(c)); k.d.line(k.R([x,y-3.2*s,x,y+3.2*s]),fill=hexc(BASE),width=max(1,int(1.2*s*k.S)))
def ppor(k,w,cx,cy,r,ring=None):
    P=PETS[CUR['pet']]; path=P['art'][w]; box=P['por'][w]
    im=Image.open(path).convert('RGB').crop(box).resize((int(2*r*k.S),int(2*r*k.S)),Image.LANCZOS)
    m=Image.new('L',im.size,0); ImageDraw.Draw(m).ellipse([0,0,im.width-1,im.height-1],fill=255)
    k.d.ellipse(k.R([cx-r-2,cy-r-2,cx+r+2,cy+r+2]),fill=hexc(ring or JADE)); k.im.paste(im,(int((cx-r)*k.S),int((cy-r)*k.S)),m)
for mod in (kit12,screens12,homes12,nav13):
    if hasattr(mod,'motif'): mod.motif=pmotif
    if hasattr(mod,'por'): mod.por=ppor
motif=pmotif; por=ppor
def pname(): return PETS[CUR['pet']]['name']
def wname(w): return PETS[CUR['pet']]['worlds'][w]
def pform(w):
    if CUR['pet']=='dragon': return form(LVW[w])
    return PETS[CUR['pet']]['forms'][w-1]
def chap(w):
    if CUR['pet']=='dragon': return f'Chapter {w} · '+scene_name(w,info_for(w))
    return f'Chapter {w}'
# ---------- 3. components ----------
def K(w=2): return K9(world=w)
def art(k,w,blur=0,dim=0,path=None):
    scene(k,path or PETS[CUR['pet']]['art'][w],blur=blur,dim=dim)
def topbar(k,w):
    lvring(k,w,40,72)
    tw=max(k.tw(T_(chap(w)),12,'mono',800)+12,k.tw(wname(w),18,'disp'))+24
    rgba_rect(k,(76,44,84+tw,100),BASE,200,14)
    k.text((86,62),T_(chap(w)),12,ACC[w],'mono',800,'lm',sp=0.6); k.text((86,84),wname(w),18,TXT,'disp',anchor='lm')
def prayerchip(k,w,y=72):
    t='3 of 5'; tw=k.tw(t,13,'g',800)+46; x1=k.W-10
    rgba_rect(k,(x1-tw,y-17,x1,y+17),BASE,215,17,outline=ASK,ow=1,oalpha=120)
    cx=x1-tw+18; k.d.ellipse(k.R([cx-7,y-7,cx+7,y+7]),fill=hexc('#E6DEFF')); k.d.ellipse(k.R([cx-3,y-10,cx+9,y+4]),fill=hexc(BASE))
    k.text((x1-12,y),t,13,ASK,'g',800,'rm')
def pin(k,w,x,y,ic,frac=None,count=None,label=None,side='r',focus=False):
    r=17
    if focus: k.glow(x,y,r+12,ACC2[w],90)
    k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),fill=hexc(BASE)); k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),outline=hexc(ACC[w]),width=int(1.2*k.S))
    if frac is not None:
        k.d.arc(k.R([x-r-1,y-r-1,x+r+1,y+r+1]),-90,-90+360*frac,fill=hexc(ACC2[w]),width=int(3*k.S))
    k.icon(ic,x,y,12,TXT)
    if count:
        tw=k.tw(count,12,'g',800)+10; rgba_rect(k,(x+r-8,y-r-8,x+r-8+tw,y-r+8),ACC2[w],250,8); k.text((x+r-8+tw/2,y-r),count,12,BASE,'g',800,'mm')
    if label:
        tw=k.tw(label,12,'g',800)+18
        x0=x+r+6 if side=='r' else x-r-6-tw
        rgba_rect(k,(x0,y-12,x0+tw,y+12),BASE,225,12,outline=ACC[w],ow=1,oalpha=90); k.text((x0+tw/2,y),label,12,TXT,'g',800,'mm')
def hero(k,w,x,y,text,anchor='l'): pillw(k,w,x,y,text,anchor=anchor,hero=True)
def say_d(k,w,text,y=None,x0=28,x1=None):
    """Ruu speaks from the orb: bubble in the thumb band, tail points down at the orb."""
    x1=x1 or k.W-28; lines=wrap(k,text,14,x1-x0-28,'dlg',600); h=18+len(lines)*20; y=y or 700-h
    rgba_rect(k,(x0,y,x1,y+h),BASE,232,16,outline=ACC[w],ow=1,oalpha=120)
    cx=k.W/2; k.d.polygon([(a*k.S,b*k.S) for a,b in [(cx-8,y+h-1),(cx,y+h+10),(cx+8,y+h-1)]],fill=hexc('#121315'))
    for i,l in enumerate(lines): k.text((x0+14,y+19+i*20),l,14,TXT,'dlg',600,'lm')
    k.icon('chat',x1-16,y+14,6,ACC2[w]); return y
def orb2(k,w,x,y,r=32,open_=False,hint=True):
    k.glow(x,y,r+14,ACC[w],70); k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),fill=hexc(BASE)); k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),outline=hexc(ACC[w]),width=2*k.S)
    por(k,w,x,y,r-5,ring=ACC[w])
    if not open_:
        for i in range(5):
            a=math.radians(214+i*28); k.d.ellipse(k.R([x+(r+8)*math.cos(a)-2.5,y+(r+8)*math.sin(a)-2.5,x+(r+8)*math.cos(a)+2.5,y+(r+8)*math.sin(a)+2.5]),fill=hexc(ACC2[w]))
    if hint and not open_: k.text((x,y+r+18),f'Hold {pname()} · or tap',12,MUT,'g',700,'mm')
def streakchip(k,w,y=772):
    t='33 d'; tw=k.tw(t,13,'g',800)+40; rgba_rect(k,(12,y-18,12+tw,y+18),BASE,215,18,outline=AMBER,ow=1,oalpha=110)
    motif_fire(k,30,y); k.text((44,y),t,13,AMBER,'g',800,'lm')
def motif_fire(k,x,y): _motif0(k,1,x,y,1.1,AMBER)
def labelschip(k,w,y=772,on=False):
    t='Labels'; tw=k.tw(t,13,'g',800)+40; x1=k.W-12
    rgba_rect(k,(x1-tw,y-18,x1,y+18),ACC2[w] if on else BASE,240 if on else 215,18,outline=ACC[w],ow=1,oalpha=110)
    k.icon('menu',x1-tw+17,y,6,BASE if on else TXT); k.text((x1-12,y),t,13,BASE if on else TXT,'g',800,'rm')
def homebar(k): k.tile(k.W/2-60,k.H-8,120,4,DIMN,r=2)
def miniorb(k,w,y=None):
    y=y or k.H-46; orb2(k,w,k.W/2,y,24,hint=False)
def header(k,w,title_,sub=None,y=62):
    rgba_rect(k,(8,y-18,44,y+18),BASE,210,18,outline=ACC[w],ow=1,oalpha=90); k.icon('back',26,y,8,TXT)
    k.text((56,y-2 if sub else y),title_,24,TXT,'disp',anchor='lm')
    if sub: k.text((56,y+22),sub,13,ACC2[w],'g',700,'lm')
SECTS=[('home','Home'),('moon','Prayer'),('wallet','Money'),('check','Habits & Quests'),('book','Books'),('clap','Movies')]
SUBS={'Money':['This month','Add spend','Categories'],'Habits & Quests':['Habits','Quests','Planner'],'Prayer':['Today','Mark next','Week'],'Books':['Shelf','Reading','Add book'],'Movies':['Tickets','Watchlist','Add film'],'Home':['Journey','Chat','Settings']}
def track(k,w,cx,cy,R):
    box=k.R([cx-R,cy-R,cx+R,cy+R])
    if w==1: k.d.arc(box,180,360,fill=hexc(ACC[w]),width=int(2.2*k.S))
    elif w==2:
        for a in range(180,360,6): k.d.arc(box,a,a+3,fill=hexc(ACC[w]),width=int(2.2*k.S))
    elif w==3:
        k.d.arc(box,180,360,fill=hexc(ACC[w]),width=int(2*k.S)); b2=k.R([cx-R-5,cy-R-5,cx+R+5,cy+R+5]); k.d.arc(b2,180,360,fill=hexc(LINE),width=int(1*k.S))
    elif w==4:
        for a in range(180,360,18): k.d.arc(box,a,a+12,fill=hexc(ACC[w]),width=int(2.4*k.S))
    else:
        k.d.arc(box,180,360,fill=hexc(LINE),width=int(1*k.S))
        for a in range(186,360,12):
            t=math.radians(a); k.d.ellipse(k.R([cx+R*math.cos(t)-1.6,cy+R*math.sin(t)-1.6,cx+R*math.cos(t)+1.6,cy+R*math.sin(t)+1.6]),fill=hexc(ACC2[w]))
def ring(k,w,sel=2,sub=False,R=160):
    W=k.W; cx,cy=W/2,k.H-74
    track(k,w,cx,cy,R); motif(k,w,cx,cy-R-4,1.1,ACC2[w])
    nodes=[]
    for j,(ic,nm) in enumerate(SECTS):
        a=math.radians(195+j*30); nodes.append((cx+R*math.cos(a),cy+R*math.sin(a),ic,nm,a))
    for j,(x,y,ic,nm,a) in enumerate(nodes):
        r=30 if j==sel else 26
        if j==sel: k.glow(x,y,r+14,ACC2[w],110); k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),fill=hexc(ACC2[w])); k.icon(ic,x,y,12,BASE)
        else: k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),fill=hexc(SURF)); k.d.ellipse(k.R([x-r,y-r,x+r,y+r]),outline=hexc(ACC[w]),width=k.S); k.icon(ic,x,y,12,TXT)
        tw=k.tw(nm,12,'g',800)+16; lx=min(max(x,tw/2+4),W-tw/2-4); ly=y-r-14
        rgba_rect(k,(lx-tw/2,ly-11,lx+tw/2,ly+11),BASE,230,11); k.text((lx,ly),nm,12,ACC2[w] if j==sel else TXT,'g',800,'mm')
    if sub:
        x,y,_,nm,a=nodes[sel]
        for j,sname in enumerate(SUBS[nm]):
            aa=a+math.radians(-24+j*24); R2=R+130; sx=cx+R2*math.cos(aa); sy=cy+R2*math.sin(aa)
            tw=k.tw(sname,13,'g',800)+26; sx=min(max(sx,tw/2+6),W-tw/2-6)
            k.d.line(k.R([x+34*math.cos(aa),y+34*math.sin(aa),sx,sy+16]),fill=hexc('#3A3F44'),width=k.S)
            rgba_rect(k,(sx-tw/2,sy-16,sx+tw/2,sy+16),RAISED,245,16,outline=ACC2[w],ow=1,oalpha=170 if j==1 else 90); k.text((sx,sy),sname,13,TXT,'g',800,'mm')
    orb2(k,w,cx,cy,open_=True)
    k.text((W/2,k.H-22),'Slide and release · or tap a node · tap outside to close',12,MUT,'g',700,'mm')
def peek(k,w,kind):
    W=k.W; panelw(k,w,(8,96,W-8,214),18)
    if kind=='Money':
        k.text((24,120),T_('Money · this month · INR'),12,ACC2[w],'mono',800,'lm',sp=0.8)
        k.text((24,152),'₹18,450 of ₹30,000',22,TXT,'disp',anchor='lm'); bar(k,24,174,W-48,18450/30000,8,col=ACC[w])
        k.text((24,198),'₹11,550 left · ₹1,050 a day · never earns XP',12,MUT,'g',600,'lm')
    elif kind=='Habits & Quests':
        k.text((24,120),T_('Habits & Quests · today'),12,ACC2[w],'mono',800,'lm',sp=0.8)
        k.text((24,152),'4 of 8 lit · 4 quests',22,TXT,'disp',anchor='lm'); segs(k,24,170,W-48,8,4,8,4,col=ACC[w])
        k.text((24,198),'Next: Write 25 min · Call the bank due today',12,MUT,'g',600,'lm')
    elif kind=='Prayer':
        k.text((24,120),T_('Prayer · today'),12,ASK,'mono',800,'lm',sp=0.8)
        k.text((24,152),'3 of 5',22,TXT,'disp',anchor='lm')
        for i in range(5): x=130+i*22; k.d.ellipse(k.R([x-7,145,x+7,159]),fill=hexc(ASK) if i<3 else None,outline=hexc(ASK),width=k.S)
        k.text((24,198),'Tracked, never scored · no XP',12,MUT,'g',600,'lm')
    elif kind=='Books':
        k.text((24,120),T_('Books · this year'),12,ACC2[w],'mono',800,'lm',sp=0.8)
        k.text((24,152),'3 of 12 read',22,TXT,'disp',anchor='lm'); segs(k,24,170,W-48,8,12,3,3,col=ACC[w])
        k.text((24,198),'Reading: 62% · no XP',12,MUT,'g',600,'lm')
