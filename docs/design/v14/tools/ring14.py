from homes14 import *
def ringscreen(pet,w,sel,sub=False,fname=None):
    set_pet(pet); k=K(w); W=k.W; art(k,w,blur=3,dim=170); k.status(TXT)
    k.text((16,62),f'{pname()} ring',24,TXT,'disp',anchor='lm'); k.text((W-16,64),f'{wname(w)} · {pform(w)}',12,ACC2[w],'g',700,'rm')
    peek(k,w,SECTS[sel][1]); ring(k,w,sel,sub)
    preview(k,W-150,226); k.out(OUT14+(fname or f'{pet}-w{w}-ring.png')); return k
if __name__=='__main__':
    ringscreen('dragon',1,3); ringscreen('dragon',3,1); ringscreen('dragon',5,4); ringscreen('dragon',2,2,True,'dragon-w2-ring-sub-money.png')
    home('dragon',3,labels=True,fname='dragon-w3-home-labels.png'); home('dragon',5,labels=True,fname='dragon-w5-home-labels.png')
