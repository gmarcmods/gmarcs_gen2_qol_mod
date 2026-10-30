local I=...
local Chrome=require('src.ui.gen2.Chrome')
local Font=require('src.render.Font')
local P={}
-- Wrap by actual font advances, including mod/translation UTF-8 glyphs.
local lastText,lastWidth,lastLines
function P.descriptionPages(text,columns,rows)
 text=I.clean(text);rows=math.max(1,rows)
 if lastText~=text or lastWidth~=columns then
  lastText,lastWidth=text,columns
  lastLines={};local line=''
  for word in text:gmatch('%S+')do
   local candidate=line==''and word or(line..' '..word)
   if line~=''and Font.width(candidate)>columns*8 then lastLines[#lastLines+1]=line;line=''end
   if Font.width(word)>columns*8 then
    for _,span in ipairs(Font.split(word))do
     local glyph=word:sub(span.from,span.to)
     if Font.width(line..glyph)>columns*8 and line~=''then lastLines[#lastLines+1]=line;line=''end
     line=line..glyph
    end
   else line=line==''and word or(line..' '..word)end
  end
  if line~=''then lastLines[#lastLines+1]=line end
 end
 local pages={{}}
 for _,line in ipairs(lastLines)do
  local page=pages[#pages]
  if #page>=rows then page={};pages[#pages+1]=page end
  page[#page+1]=line
 end
 return pages
end
function P.layout(w,h)
 w=math.floor(w/8)*8;h=math.floor(h/8)*8
 if w>=360 and h>=240 then
  local left=math.floor(w*.55/8)*8
  return {mode='split',w=w,h=h,cards={x=0,y=24,w=left,h=200},detail={x=left+8,y=24,w=w-left-8,h=h-48}}
 elseif w>=240 and h>=400 then
  return {mode='stack',w=w,h=h,cards={x=0,y=24,w=w,h=200},detail={x=0,y=232,w=w,h=h-256}}
 end
 return {mode='compact',w=w,h=h}
end
local function print(text,x,y)Chrome.printThrough(text,x/8,y/8,Chrome.DEFAULT_BOX_PALETTE)end
local function box(x,y,w,h)Chrome.box(x/8,y/8,w/8,h/8)end
local function fit(text,width)
 if Font.width(text)<=width then return text end
 local out=''
 for _,span in ipairs(Font.split(text))do
  local next_=out..text:sub(span.from,span.to)
  if Font.width(next_..'...')>width then break end
  out=next_
 end
 return out..'...'
end
function P.draw(game,moves,focus,state,w,h)
 local L=P.layout(w,h);w,h=L.w,L.h
 Chrome.paletteFill(0,0,w,h)
 box(0,0,w,h)
 local title=I.label(game,'MOVES')
 if L.mode=='compact'then title=title..' '..I.label(game,'NEW')..#moves end
 print(title,8,8)
 local selected=I.move(game,moves[focus])
 local dx,dy,dw,dh
 if L.mode=='compact'then
  for index,entry in ipairs(moves)do
   local name=I.move(game,entry).name
   local prefix=index..' '
   if index==focus then Chrome.cursorThrough(1,(16+(index-1)*8)/8,Chrome.DEFAULT_BOX_PALETTE)end
   print(fit(prefix..name,w-32),24,16+(index-1)*8)
  end
  print(I.label(game,'TYPE')..' '..selected.type,8,64)
  print('PP '..selected.pp,8,72)
  print(I.label(game,'PWR')..' '..selected.power,8,80)
  print(I.label(game,'ACC')..' '..selected.accuracy,8,88)
  dx,dy,dw,dh=8,104,w-16,h-120
 else
  local c=L.cards
  for index,entry in ipairs(moves)do
   local info=I.move(game,entry);local top=c.y+(index-1)*40
   box(c.x,top,c.w,40)
   if index==focus then Chrome.cursorThrough((c.x+8)/8,(top+8)/8,Chrome.DEFAULT_BOX_PALETTE)end
   local prefix=index==#moves and(I.label(game,'NEW')..' ')or(index..' ')
   print(fit(prefix..info.name,c.w-32),c.x+24,top+8)
   print(fit('PP '..info.pp..'  '..info.type,c.w-16),c.x+8,top+16)
   print(fit(I.label(game,'PWR')..info.power..' '..I.label(game,'ACC')..info.accuracy,c.w-16),c.x+8,top+24)
  end
  local d=L.detail;box(d.x,d.y,d.w,d.h)
  print(fit(selected.name,d.w-16),d.x+8,d.y+8)
  print(I.label(game,'TYPE')..' '..selected.type,d.x+8,d.y+24)
  print('PP '..selected.pp,d.x+8,d.y+40)
  print(I.label(game,'PWR')..' '..selected.power,d.x+8,d.y+56)
  print(I.label(game,'ACC')..' '..selected.accuracy,d.x+8,d.y+72)
  print(fit(I.label(game,'DESCRIPTION'),d.w-16),d.x+8,d.y+88)
  dx,dy,dw,dh=d.x+8,d.y+104,d.w-16,d.h-112
 end
 local pages=P.descriptionPages(selected.description,math.max(1,math.floor(dw/8)),math.max(1,math.floor(dh/8)))
 state.movesetPlusPage=math.max(1,math.min(state.movesetPlusPage or 1,#pages))
 state.movesetPlusPageCount=#pages
 for n,line in ipairs(pages[state.movesetPlusPage])do print(line,dx,dy+(n-1)*8)end
 local footer=I.label(game,focus==#moves and 'A: DECLINE  B: BACK'or'A: REPLACE  B: BACK')
 if #pages>1 then footer='L/R '..I.label(game,'INFO')..' '..state.movesetPlusPage..'/'..#pages..'  B: '..I.label(game,'BACK')end
 print(fit(footer,w-16),8,h-16)
end
function P.wide(game,moves,focus,state,w,h)
 local x,y,pw,ph=Chrome.playfieldRect(w,h)
 local scale=math.max(1,math.floor(math.min(pw/240,ph/220)))
 local G=love.graphics
 G.push('all');G.translate(x,y);G.scale(scale,scale)
 Chrome.paletteFill(0,0,pw/scale,ph/scale)
 P.draw(game,moves,focus,state,pw/scale,ph/scale)
 G.pop()
end
return P
