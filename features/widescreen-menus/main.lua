-- Responsive framing of native screens; menu logic, artwork and callbacks
-- stay native. Useful Bag and Moveset Plus retain their specialized layouts.
local Chrome=require('src.ui.gen2.Chrome')
local Font=require('src.render.Font')
return function(mod)
 local function own(name)return assert(loadstring(assert(mod:read('lib/'..name..'.lua'))))()end
 local Layout,Details=own('Layout'),own('Details')
 mod.options:define({{key='enabled',label='WIDESCREEN MENUS',type='toggle',default=true}})
 local function active(game)
  return mod.options:get('enabled')~=false and game and game.mods and game.mods.exports.gmarcs_gen2_qol_mod~=nil
 end
 local Connected=own('ConnectedMaps').new(mod,active)
 Connected.install(require('src.ui.gen2.Pokegear'))
 local function text(value,x,y)Chrome.printThrough(tostring(value),x/8,y/8,Chrome.DEFAULT_BOX_PALETTE)end
 local function lines(value,width)
  local out,line={},''
  for word in tostring(value):gmatch('%S+')do
   if line~=''and Font.width(line..' '..word)>width then out[#out+1]=line;line=''end
   for _,span in ipairs(Font.split(word))do
    local glyph=word:sub(span.from,span.to)
    if Font.width(line..glyph)>width and line~=''then out[#out+1]=line;line=''end
    line=line..glyph
   end
   line=line..' '
  end
  if line~=''then out[#out+1]=line end
  return out
 end
 local classes={PartyMenu='PARTY',SummaryMenu='SUMMARY',PokedexMenu='POKéDEX',BoxMenu='PC',
  PcMenu='PC',ItemPcMenu='PACK',PackMenu='PACK',OptionsMenu='OPTIONS',TrainerCard='TRAINER CARD',
  Pokegear='POKéGEAR',MailRead='MAIL',MailCompose='MAIL',MoveTutor='MOVE TUTOR'}
 local function enhance(Class,kind)
  local originalWide,originalDraw=Class.drawWidescreen,Class.draw
  if type(Class.drawPanel)~='function'then return end
  if type(originalWide)~='function'then
   originalWide=function(self,w,h)
    local G=love.graphics;local scale=Chrome.fitScale(w,h)
    G.push('all');G.translate(Chrome.fitOrigin(w,h,scale));G.scale(scale,scale);self:drawPanel();G.pop()
   end
   if not Class.drawsWidescreen then Class.drawsWidescreen=function(self)return active(self.game)and self.isOpaque or false end end
  end
  Class.drawWidescreen=function(self,w,h)
   self.widescreenMenuFrame=nil
   if not active(self.game)or not self.isOpaque or self.usefulBag or self.movesetPlusIncoming then return originalWide(self,w,h)end
   if kind=='POKéGEAR'then
    if Connected.draw(self,w,h)then return end
    -- These cards already contain their own information. An empty second
    -- panel wastes most of a portrait screen and shrinks the Fly map.
    self.widescreenMenuFrame={mode='native'}
    return originalWide(self,w,h)
   end
   local x,y,pw,ph=Chrome.playfieldRect(w,h)
   local field=require('src.render.Playfield')
   local dpi=type(field.pixelScale)=='function' and field.ratio() or 1
   local p=Layout.plan(pw*dpi,ph*dpi)
   if p.mode=='compact'then return originalWide(self,w,h)end
   self.widescreenMenuFrame=p
   local G=love.graphics
   G.push('all');G.translate(x,y);G.scale(p.scale/dpi,p.scale/dpi)
   Chrome.paletteFill(0,0,p.w,p.h)
   G.push();G.translate(p.native.x,p.native.y);self:drawPanel();G.pop()
   local d=p.detail
   Chrome.box(d.x/8,d.y/8,d.w/8,d.h/8,Chrome.DEFAULT_BOX_PALETTE)
   text(Details.label(self.game,kind),d.x+8,d.y+8)
   local ty=d.y+28
   for _,value in ipairs(Details.lines(self,kind))do
    for _,line in ipairs(lines(value,d.w-16))do
     if ty+8<=d.y+d.h-12 then text(line,d.x+8,ty)end
     ty=ty+10
    end
    ty=ty+6
   end
   G.pop()
  end
  Class.draw=function(self,...)
   local stack=self.game and self.game.stack
   if self.isOpaque and self.widescreenMenuFrame and active(self.game)and stack and stack:top()~=self then return end
   if originalDraw then return originalDraw(self,...)end
  end
 end
 for name,kind in pairs(classes)do enhance(require('src.ui.gen2.'..name),kind)end
 mod.exports={layout=Layout,details=Details,wrap=lines,supported=classes,connectedMaps=Connected}
end
