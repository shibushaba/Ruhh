from core14 import *
# hotspots in screen coords (cover-fit art). kind: icon, label, frac, count, dest
# (x,y,icon,label,frac,count,side)
HS={
 ('dragon',1):dict(pins=[(88,152,'target','Lantern · Goals',3/5,'3/5','r'),(56,322,'check','Candle ledge · Habits',4/8,None,'r'),(250,178,'flag','Quest wall',None,'4','l')],
     hero=(78,352,'Hold · Write'),say="Embers are low, Shabas. Four candles lit; Write lights the fifth.",pv=(200,118)),
 ('dragon',2):dict(pins=[(42,418,'target','Bridge lanterns · Goals',3/5,'3/5','r'),(300,330,'flag','Leaf post · Quests',None,'4','l'),(110,520,'check','Stones · Habits',4/8,None,'r')],
     hero=(140,560,'Hold · Write'),say="Four stones lit, Shabas. Step on Write when you're done.",pv=(240,118),stones=True),
 ('dragon',3):dict(pins=[(150,282,'check','Bell rope · Habits',4/8,None,'r'),(36,262,'bell','Big bell · Wrap-up',None,None,'r'),(206,352,'target','Stone lanterns · Goals',3/5,'3/5','r'),(36,452,'flag','Ema rack · Quests',None,'4','r')],
     hero=(172,312,'Hold · Write'),say="The rope's half rung, Shabas. Write rings the fifth bell.",pv=(240,118)),
 ('dragon',4):dict(pins=[(44,142,'check','Chimes · Habits',4/8,None,'r'),(40,300,'target','Islands · Goals',3/5,'3/5','r'),(36,468,'flag','Banners · Quests',None,'4','r')],
     hero=(66,172,'Hold · Write'),say="Wind's up, Shabas. Four chimes singing; Write is next.",pv=(240,118)),
 ('dragon',5):dict(pins=[(34,150,'check','Constellation · Habits',4/8,None,'r'),(36,372,'flag','Waiting lanterns · Quests',None,'4','r'),(334,452,'target','Sky lanterns · Goals',3/5,'3/5','l')],
     hero=(56,180,'Trace · Write'),say="Four stars tonight, Shabas. Trace Write to draw the fifth.",pv=(240,118)),
 ('panda',1):dict(pins=[(84,186,'target','Lantern · Goals',3/5,'3/5','r'),(66,360,'check','Stone lamps · Habits',4/8,None,'r'),(346,262,'flag','Bamboo post · Quests',None,'4','l')],
     hero=(88,390,'Hold · Write'),say="Mist is lifting, Shabas. Four lamps lit; Write is next.",pv=(240,118)),
 ('panda',5):dict(pins=[(112,204,'check','Constellation · Habits',4/8,None,'r'),(40,420,'flag','Lanterns · Quests',None,'4','r'),(334,452,'target','Sky lanterns · Goals',3/5,'3/5','l')],
     hero=(134,234,'Trace · Write'),say="The moon's full, Shabas. Four stars held; trace Write.",pv=(240,118)),
 ('cat',1):dict(pins=[(40,196,'target','Lantern · Goals',3/5,'3/5','r'),(70,352,'check','Window candles · Habits',4/8,None,'r'),(342,306,'flag','Notice board · Quests',None,'4','l')],
     hero=(92,382,'Hold · Write'),say="Rain's stopped, Shabas. Four candles lit; Write is next.",pv=(240,118)),
 ('cat',5):dict(pins=[(300,190,'check','Constellation · Habits',4/8,None,'l'),(58,436,'flag','Lanterns · Quests',None,'4','r'),(342,350,'target','Sky lanterns · Goals',3/5,'3/5','l')],
     hero=(278,220,'Trace · Write','r'),say="Clear sky, Shabas. Four stars held; trace Write.",pv=(240,118)),
}
def home(pet='dragon',w=2,labels=False,fname=None,demo=False,say=True):
    set_pet(pet); k=K(w); W=k.W; H=k.H; art(k,w); k.particles(0,90,W,520,ACC2[w],20,w+3,1.8,180)
    topscrim(k,110,170); k.status(TXT if not (pet=='dragon' and w==4) else BASE)
    k.scrim(0,H-230,W,230,BASE,150,0) if False else None
    topbar(k,w); prayerchip(k,w)
    h=HS[(pet,w)]
    if h.get('stones'):
        for i,((rx,ry),(n,on,s_)) in enumerate(zip(STONES,HAB)):
            sx,sy=MC(rx,ry); (m_lit(k,w,sx,sy,7) if on else m_next(k,w,sx,sy,0.35,10) if on is None else m_off(k,w,sx,sy,6))
    for (x,y,ic,lab,fr,cnt,side) in h['pins']:
        pin(k,w,x,y,ic,fr,cnt,lab if labels else None,side,focus=(ic=='check'))
    hx_,hy_,ht=h['hero'][:3]; anc=h['hero'][3] if len(h['hero'])>3 else 'l'
    if not labels: hero(k,w,hx_,hy_,ht,anc)
    if say: say_d(k,w,h['say'],y=None)
    streakchip(k,w); labelschip(k,w,on=labels); orb2(k,w,W/2,H-72); homebar(k)
    preview(k,*h['pv'])
    fn=fname or f'{pet}-w{w}-home.png'
    if not demo: k.out(OUT14+fn)
    return k
if __name__=='__main__':
    import sys as _s
    for a in _s.argv[1:]:
        pet,w=a.split(':')[:2]; lab=a.endswith(':labels')
        home(pet,int(w),labels=lab,fname=(f'{pet}-w{w}-home-labels.png' if lab else None))
