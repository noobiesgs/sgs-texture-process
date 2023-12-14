# -*- coding: utf-8 -*-
import os
import sys
import os.path
import shutil
from PIL import Image
 
fileName = input('输入要解析的文件名:')
 
if fileName.find('.png') != -1:
    fileName = fileName[:-4]
 
pngName = fileName + '.png'
atlasName = fileName + '.atlas'
 
print(pngName,atlasName)
 
big_image = Image.open(pngName)
atlas = open(atlasName, encoding="utf8");
 
#big_image.show()#调用系统看图器
 
curPath = os.getcwd()# 当前路径
aim_path = os.path.join(curPath, 'images')
print (aim_path)
if os.path.isdir(aim_path):
    shutil.rmtree(aim_path,True)#如果有该目录,删除
os.makedirs(aim_path)
 
#读取文件中与解包无关的前几行字符串
_line = atlas.readline();
_line = atlas.readline();
_line = atlas.readline();
_line = atlas.readline();
_line = atlas.readline();
_line = atlas.readline();
 
while True:
    line1 = atlas.readline() # name
    if len(line1) == 0:
        break
    else:
        line2 = atlas.readline() # rotate
        line3 = atlas.readline() # xy
        line4 = atlas.readline() # size
        line5 = atlas.readline() # orig
        line6 = atlas.readline() # offset
        line7 = atlas.readline() # index
 
        print("文件名:"+line1,end="")
        print("是否旋转:"+line2,end="")
        print("坐标:"+line3,end="")
        print("大小:"+line4,end="")
        print("原点:"+line5,end="")
        print("阻挡:"+line6,end="")
        print("索引:"+line7,end="")
        
        name = line1.replace("\n","") + ".png";
        
        args = line4.split(":")[1].split(",");
        width = int(args[0])
        height= int(args[1])
            
        args = line3.split(":")[1].split(",");
        ltx = int(args[0])
        lty = int(args[1])
        
        if (line2=='  rotate: true\n'):
            rbx = ltx+height
            rby = lty+width
        else:
            rbx = ltx+width
            rby = lty+height
        
        print ("文件名："+name+" 宽度："+str(width)+" 高度："+str(height)+" 起始横坐标："+str(ltx)+" 起始纵坐标："+str(lty)+" 结束横坐标："+str(rbx)+" 结束纵坐标："+str(rby)+"\n")
        if (line2=='  rotate: true\n'):
            result_image = Image.new("RGBA", (height,width), (0,0,0,0))
            rect_on_big = big_image.crop((ltx,lty,rbx,rby))
            result_image.paste(rect_on_big, (0,0,height,width))
        else:
            result_image = Image.new("RGBA", (width,height), (0,0,0,0))
            rect_on_big = big_image.crop((ltx,lty,rbx,rby))
            result_image.paste(rect_on_big, (0,0,width,height))
        
        folder_path = aim_path
        
        if '/' in name:
            folders, name_f = name.rsplit('/', 1)
            folders = folders.rsplit('/')
            for folder in folders:
                folder_path = os.path.join(folder_path, folder)
                if not os.path.exists(folder_path):
                    os.mkdir(folder_path)
            name_t=os.path.join(folder_path, name_f)
        else :
            name_t=os.path.join(folder_path, name)
 
        if (line2=='  rotate: true\n'):
            result_image = result_image.transpose(Image.ROTATE_270)
        result_image.save(name_t)
atlas.close()
del big_image