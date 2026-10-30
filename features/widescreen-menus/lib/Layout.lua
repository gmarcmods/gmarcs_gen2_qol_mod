local L={}
function L.plan(width,height)
 local wide=width>=height
 local scale=math.max(1,math.floor(math.min(width/(wide and 360 or 240),height/(wide and 200 or 360))))
 local w,h=math.floor(width/scale),math.floor(height/scale)
 local p={scale=scale,w=w,h=h}
 if w>=360 and h>=176 then
  p.mode='wide';p.native={x=8,y=math.floor((h-144)/2)}
  p.detail={x=184,y=8,w=math.floor((w-192)/8)*8,h=math.floor((h-16)/8)*8}
 elseif w>=192 and h>=328 then
  p.mode='portrait';p.native={x=math.floor((w-160)/2),y=8}
  p.detail={x=8,y=168,w=math.floor((w-16)/8)*8,h=math.floor((h-176)/8)*8}
 else
  scale=math.max(1,math.floor(math.min(width/160,height/144)))
  p={scale=scale,w=math.max(160,math.floor(width/scale)),h=math.max(144,math.floor(height/scale)),mode='compact'}
  p.native={x=math.floor((p.w-160)/2),y=math.floor((p.h-144)/2)}
 end
 return p
end
return L
