from sheets14 import *
def pcrop(pet,w,box_w,box_h,cx=None,cy=None):
    pass
def petcard(k,pet,x,y,wd,h,sel):
    P=PETS[pet]; set_pet(pet); w=1
    k.art(P['art'][1],x,y,wd,h,crop=(60,180,660,1100),r=22)
    k.scrim(x,y+h*0.55,wd,h*0.45,BASE,215 if sel else 190,0)
    rgba_rect(k,(x,y,x+wd,y+h),None,0,22,outline=ACC2[w] if sel else LINE,ow=2 if sel else 1,oalpha=255)
    if not sel: k.scrim(x,y,wd,h,BASE,120,22)
    k.text((x+16,y+h-96),T_(P['kind']),12,ACC2[w],'mono',800,'lm',sp=1); k.text((x+16,y+h-70),P['name'] if sel else P['kind'],22 if sel else 17,TXT,'disp',anchor='lm')
    if sel:
        k.text((x+16,y+h-44),f"{P['worlds'][1]} → {P['worlds'][5]}",12,MUT,'g',700,'lm'); motif(k,1,x+wd-24,y+h-96,1.2,ACC2[1])
        k.text((x+16,y+h-22),'Own worlds, forms and ring',12,MUT,'g',600,'lm')
def picker():
    k=K9(world=1); W=k.W; k.status(TXT)
    k.text((16,62),T_('Step 2 of 5 · your companion'),12,ACC2[1],'mono',800,'lm',sp=0.8); segs(k,16,80,120,5,2,6,4,col=JADE)
    k.text((16,118),'Who walks with you?',24,TXT,'disp',anchor='lm'); k.text((16,146),'Try each one first. You keep the one you choose.',14,MUT,'g',600,'lm')
    petcard(k,'dragon',-150,190,170,380,False); petcard(k,'cat',W-20,190,170,380,False)
    petcard(k,'panda',40,172,W-80,420,True)
    for i,p in enumerate(['dragon','panda','cat']):
        x=W/2-24+i*24; k.d.ellipse(k.R([x-4,612,x+4,620]),fill=hexc(ACC2[1] if p=='panda' else '#4A4E52'))
    k.text((W/2,642),'Swipe the cards · or tap a side card',12,MUT,'g',700,'mm')
    set_pet('panda'); btn(k,8,676,(W-24)/2,48,'Try Panda','secondary'); btn(k,W/2+4,676,(W-24)/2,48,'Choose Panda')
    k.text((W/2,748),'Choosing is permanent · you’ll confirm on the next step',12,DIMN,'g',600,'mm')
    homebar(k); preview(k,W-150,40); k.out(OUT14+'pet-1-picker.png'); return k
def trypet(pet):
    k=home(pet,1,demo=True,say=True); W=k.W; P=PETS[pet]
    rgba_rect(k,(8,112,W-8,152),BASE,240,20,outline=ACC2[1],ow=1.2,oalpha=200)
    k.icon('spark',30,132,8,ACC2[1]); k.text((48,132),f"Trying {P['kind']} · nothing is saved",14,TXT,'g',800,'lm'); k.text((W-22,132),'0:45',13,MUT,'g',700,'rm')
    # replace bottom row with try actions
    k.scrim(0,738,W,106,BASE,245,0)
    btn(k,8,752,(W-24)/2,46,'Back to pets','ghost'); btn(k,W/2+4,752,(W-24)/2,46,f"Choose {P['kind']}")
    homebar(k); k.out(OUT14+f'pet-2-try-{pet}.png'); return k
def confirm(pet='panda'):
    set_pet(pet); P=PETS[pet]; k=K(1); W=k.W; k.art(P['art'][1],0,0,W,k.H,r=0,fade=[('bottom',0.72)],fade_amt=0.92); k.scrim(0,0,W,k.H,BASE,90,0); k.scrim(0,310,W,80,BASE,120,0); k.status(TXT)
    k.text((16,62),T_('Step 3 of 5 · confirm'),12,ACC2[1],'mono',800,'lm',sp=0.8); segs(k,16,80,120,5,3,6,4,col=JADE)
    k.d.ellipse(k.R([W/2-58,182,W/2+58,298]),fill=hexc(BASE)); por(k,1,W/2,240,54,ring=ACC2[1])
    k.text((W/2,336),f"{P['kind']}, for good.",26,TXT,'disp',anchor='mm')
    k.text((W/2,368),'This is the one choice in RUHH you can’t change later.',14,MUT,'g',600,'mm')
    panelw(k,1,(16,396,W-16,560),18)
    for i,t in enumerate([f"Your worlds become {P['worlds'][1]} → {P['worlds'][5]}.",f"{P['kind']} grows through 5 forms with you.",'Habits, quests, money and goals work the same.','You can rename it any time; not swap it.']):
        y=424+i*34; k.icon('tick',36,y,6,ACC2[1],2.4); k.text((54,y),t,13,TXT,'g',700,'lm')
    y=592; rgba_rect(k,(16,y,W-16,y+48),SURF,240,14,outline=ACC2[1],ow=1.2,oalpha=180)
    k.d.rounded_rectangle(k.R([30,y+13,52,y+35]),5*k.S,fill=hexc(JADE)); k.icon('tick',41,y+24,6,BASE,2.6)
    k.text((64,y+24),'I understand this is permanent',14,TXT,'g',800,'lm')
    btn(k,8,668,(W-24)/2*0.8,48,'Go back','ghost'); x2=8+(W-24)/2*0.8+8; btn(k,x2,668,W-8-x2,48,f"Choose {P['kind']} for good")
    k.text((W/2,740),'Saved on this device in your profile',12,DIMN,'g',600,'mm')
    homebar(k); preview(k,W-150,104); k.out(OUT14+f'pet-3-confirm-{pet}.png'); return k
def forms(pet):
    set_pet(pet); P=PETS[pet]; B=K9(W=1400,H=1000,world=1); W=B.W
    B.text((40,50),f"{P['kind']} · forms across the five worlds",26,TXT,'disp',anchor='lm'); B.text((40,84),f"Default name {P['name']} (user renames) · original character · serious-cool, never chibi",14,MUT,'g',600,'lm'); B.preview(y=34,x=W-170)
    B.art(RAW14+f'{pet}-forms.jpg',20,110,W-40,(W-40)*720/1280,r=20)
    y=110+(W-40)*720/1280+14; lv=['Lv 1–24','Lv 25–44','Lv 45–64','Lv 65–84','Lv 85–100']
    for i in range(5):
        x=20+(W-40)*(i+0.5)/5; w=i+1; c=P['acc'][w]
        B.text((x,y+20),P['forms'][i],17,TXT,'disp',anchor='mm'); B.text((x,y+44),f"{P['worlds'][w]} · {lv[i]}",12,c,'g',700,'mm')
        ACC[1]=c; pmotif(B,1,x,y+66,1.2,c)
    B.out(OUT14+f'pet-{pet}-forms.png'); set_pet(pet)
def petinner():
    habits('panda',1,'panda-w1-habits-orbit.png'); climb('cat',5,'cat-w5-goal-climb.png')
if __name__=='__main__':
    import sys as _s
    picker(); trypet('panda'); trypet('cat'); confirm('panda')
    for p in ['panda','cat']:
        home(p,1); home(p,5); ringscreen(p,5,3 if p=='panda' else 2, p=='cat'); forms(p)
    petinner()
