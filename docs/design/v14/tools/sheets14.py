from inner14 import *
import nav13 as _n
def evolution():
    set_pet('dragon'); B=K9(W=1640,H=1060,world=2); W=B.W
    B.text((40,50),'Ruu ring & scene components · evolution across the 5 worlds',26,TXT,'disp',anchor='lm')
    B.text((40,84),'Charcoal chrome stays fixed; only the accent, the motif, the ring track and Ruu’s portrait change per world. Level B: one motif per component.',14,MUT,'g',600,'lm'); B.preview(y=34,x=W-170)
    rows=['Ruu orb','Ring track','Scene pin + hero','Habit node (lit)','Panel + pill']
    for i,r_ in enumerate(rows): B.text((40,230+i*170),T_(r_),12,DIMN,'mono',800,'lm',sp=1)
    for w in range(1,6):
        x=330+(w-1)*262; B.text((x,140),wname(w),18,TXT,'disp',anchor='mm'); B.text((x,166),f'Lv {LVW[w]} · {form(LVW[w])}',12,ACC2[w],'g',700,'mm')
        rgba_rect(B,(x-40,178,x-4,188),ACC[w],255,4); rgba_rect(B,(x+4,178,x+40,188),ACC2[w],255,4)
        orb2(B,w,x,256,36,hint=False)
        cy=470; R=86; track(B,w,x,cy,R); motif(B,w,x,cy-R-4,1.1,ACC2[w])
        for j in range(5):
            a=math.radians(198+j*36); nx,ny=x+R*math.cos(a),cy+R*math.sin(a); s_=j==2
            B.d.ellipse(B.R([nx-15,ny-15,nx+15,ny+15]),fill=hexc(ACC2[w] if s_ else SURF)); B.d.ellipse(B.R([nx-15,ny-15,nx+15,ny+15]),outline=hexc(ACC[w]),width=B.S)
            B.icon(SECTS[j+1][0],nx,ny,8,BASE if s_ else TXT)
        pin(B,w,x-50,570,'check',4/8,None,None,focus=True); hero(B,w,x-26,570,'Hold · Write')
        nx,ny=x,740; B.glow(nx,ny,24,ACC[w],80); B.d.ellipse(B.R([nx-20,ny-20,nx+20,ny+20]),fill=hexc(RAISED)); B.d.ellipse(B.R([nx-20,ny-20,nx+20,ny+20]),outline=hexc(ACC[w]),width=2*B.S); motif(B,w,nx,ny,1.4,ACC2[w])
        panelw(B,w,(x-110,860,x+110,940),16); B.text((x-96,884),T_('Next'),12,ACC2[w],'mono',800,'lm',sp=0.8); B.text((x-96,912),'Write 25 min',15,TXT,'disp',anchor='lm'); motif(B,w,x+92,884,0.9)
        pillw(B,w,x,966,'4 / 8 lit')
    B.text((40,1030),'Fixed in every world: charcoal surfaces #16181A / #1F2225, hairline #2A2E32, warm off-white text, jade primary button, lavender prayer, amber streak. Never red.',13,MUT,'g',600,'lm')
    B.out(OUT14+'80-ring-evolution-sheet.png')
def sitemap():
    _n.OUT13=OUT14
    N={'home':(800,170,'Home · living scene','home','5 worlds · Ruu orb at thumb centre'),
       'hab':(110,330,'Habits orbit','sec','stones / candles / rope'),'q':(310,330,'Quests board','sec','leaf post / ema / banners'),'g':(510,330,'Goal climb','sec','lanterns / islands'),
       'p':(1010,330,'Prayer sky','sec','moon chip · not scored'),'c':(1200,330,'Campfire chat','sec','tap Ruu’s bubble'),'j':(1380,330,'Journey','sec','tap chapter title'),'s':(1530,330,'Settings','sec','tap Lv ring'),
       'ring':(800,520,'Ruu ring','home','hold or tap the orb'),
       'm':(260,700,'Money blocks','sub','This month · Add spend · Categories'),'hq':(620,700,'Habits & Quests','sub','Habits · Quests · Planner'),'b':(980,700,'Books','sub','Shelf · Reading · Add'),'mv':(1300,700,'Movies','sub','Tickets · Watchlist · Add'),
       'pl':(620,830,'Planner dial','sub','from H&Q switch'),'rel':(1380,460,'Relics · Season','sub','chips in Journey'),'me':(110,520,'Morning / Evening','sub','7:00 · 21:00 or bubble')}
    E=[('home','hab','1 tap'),('home','q','1 tap'),('home','g','1 tap'),('home','p','1 tap'),('home','c','1 tap'),('home','j','1 tap'),('home','s','1 tap'),('home','ring','hold'),
       ('ring','m','slide'),('ring','hq','slide'),('ring','b','slide'),('ring','mv','slide'),('hq','pl',''),('j','rel',''),('hab','me','')]
    flow('92-sitemap-flow.png','v14 sitemap · Living scene + Ruu ring','Everything is 1 tap from Home (scene object) or 1 hold-slide / 2 taps through the ring. Sub-pages are at most 2 steps. No tab bar.',N,E,
         ['Every scene object = a pin with a 44 px target; labels show on focus, on first run, or with the Labels chip (fixes W3/W5 crowding).',
          'Ring: hold + slide + release (expert) · tap orb then tap node (novice) · slide past a node to its outer arc for sub-pages (Money → This month / Add spend / Categories).',
          'Every inner screen keeps a mini orb at the bottom centre: tap = Home, hold = ring. System back always works.',
          'List mode (Settings → Navigation, or screen reader) shows the same places as a plain list. Reduced motion: ring appears without the fan; no particles.',
          'Pets: Dragon / Panda / Cat share this exact map; only art, names, accents and the motif swap.'],W=1600,H=1060)
if __name__=='__main__':
    evolution(); sitemap()
