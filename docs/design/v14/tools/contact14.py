from PIL import Image, ImageDraw, ImageFont
F='/workspace/ruhh/anime/v11/fonts/'
T=ImageFont.truetype(F+'MochiyPopOne-Regular.ttf',40); L=ImageFont.truetype(F+'ZenMaruGothic-Bold.ttf',17); S=ImageFont.truetype(F+'ZenMaruGothic-Bold.ttf',19)
def sheet(out,title,sub,items,cols=7,tw=260):
    th=int(tw*844/390); rows=(len(items)+cols-1)//cols; W=40+cols*(tw+20)+20; H=130+rows*(th+50)+10
    o=Image.new('RGB',(W,H),'#0E0F10'); d=ImageDraw.Draw(o)
    d.text((40,34),title,font=T,fill='#F4EEDC'); d.text((40,88),sub,font=S,fill='#B3B0A9')
    for i,(f,lab) in enumerate(items):
        x=40+(i%cols)*(tw+20); y=130+(i//cols)*(th+50)
        im=Image.open(f).convert('RGB').resize((tw,th)); o.paste(im,(x,y)); d.rounded_rectangle([x-1,y-1,x+tw,y+th],8,outline='#2A2E32',width=2)
        d.text((x,y+th+8),lab,font=L,fill='#C9F2A0')
    o.save(out); print(out,o.size)
D=[('dragon-w1-home.png','W1 Ember Nest · home'),('dragon-w2-home.png','W2 Moss Ledge · home'),('dragon-w3-home.png','W3 Cliff Shrine · home'),('dragon-w4-home.png','W4 Wind Temple · home'),('dragon-w5-home.png','W5 Star Summit · home'),('dragon-w3-home-labels.png','W3 · Labels on'),('dragon-w5-home-labels.png','W5 · Labels on'),
   ('dragon-w1-ring.png','Ring · W1'),('dragon-w3-ring.png','Ring · W3'),('dragon-w5-ring.png','Ring · W5'),('dragon-w2-ring-sub-money.png','Sub-ring · Money'),('dragon-w2-first-run-demo.png','First-run demo'),('dragon-w2-list-mode.png','List mode (a11y)'),('dragon-w2-habits-orbit.png','Habits orbit'),
   ('dragon-w2-quests-board.png','Quests board'),('dragon-w2-goal-climb.png','Goal climb'),('dragon-w2-money-blocks.png','Money blocks'),('dragon-w2-planner-dial.png','Planner dial'),('dragon-w2-journey.png','Journey'),('dragon-w2-prayer-sky.png','Prayer sky'),('dragon-w2-books-movies.png','Books & Movies'),
   ('dragon-w2-chat.png','Campfire chat'),('dragon-w2-settings.png','Settings bento'),('dragon-w2-level-up.png','Level up'),('dragon-w2-morning.png','Morning'),('dragon-w2-evening.png','Evening'),('dragon-w5-habits-orbit.png','Habits orbit · W5'),('dragon-w3-goal-climb.png','Goal climb · W3')]
sheet('90-contact-dragon.png','RUHH v14 · Dragon (Ruu) · living scene + Ruu ring','DESIGN PREVIEW · charcoal chrome, art unchanged · level B · font pairing 2 · no tab bar, no stacked card lists',D)
P=[('pet-1-picker.png','Pet picker'),('pet-2-try-panda.png','Try · Panda'),('pet-2-try-cat.png','Try · Cat'),('pet-3-confirm-panda.png','Permanent confirm'),('panda-w1-home.png','Panda W1 · Bamboo Hollow'),('panda-w5-home.png','Panda W5 · Moon Peak'),('panda-w5-ring.png','Panda ring · W5'),
   ('panda-w1-habits-orbit.png','Panda · Habits orbit'),('cat-w1-home.png','Cat W1 · Lantern Alley'),('cat-w5-home.png','Cat W5 · Starlit Rooftops'),('cat-w5-ring.png','Cat sub-ring · W5'),('cat-w5-goal-climb.png','Cat · Goal climb')]
sheet('91-contact-pets.png','RUHH v14 · Pets · Dragon / Panda / Cat','DESIGN PREVIEW · same map and components; art, names, accents and motif swap with the pet · choice is permanent',P,cols=6)
