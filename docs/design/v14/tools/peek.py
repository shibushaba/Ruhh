import sys
from PIL import Image
out=sys.argv[1]; fs=sys.argv[2:]; n=len(fs); cols=min(n,5); rows=(n+cols-1)//cols
o=Image.new('RGB',(cols*390,rows*844),'white')
for i,f in enumerate(fs):
    im=Image.open(f).convert('RGB'); im=im.resize((390,int(844*im.height/im.width*390/390*im.width/im.width*1))) if False else im.resize((390,int(390*im.height/im.width)))
    o.paste(im,((i%cols)*390,(i//cols)*844))
o.save(out,quality=88)
