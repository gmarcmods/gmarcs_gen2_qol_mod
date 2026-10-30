-- Preserve both original region maps and native navigation/flight callbacks.
local Chrome=require('src.ui.gen2.Chrome')
local Field=require('src.world.gen2.FieldMoves')
local Strings=require('src.core.Strings')
local M={}
function M.new(mod,active)
 local C={}
 function C.unlocked(game)
  if not game or not game.save then return false end
  if mod.save and mod.save:get('kantoVisited',false)then return true end
  local w=game.world
  local visited=w and w.region and w:region()=='kanto' or (game.save.flags or{}).HALL_OF_FAME==true
  if not visited then
   for i=Field.KANTO_FLYPOINT,#Field.FLYPOINTS do
    if Field.hasVisitedSpawn(game.save,Field.FLYPOINTS[i].spawn)then visited=true;break end
   end
  end
  if visited and mod.save then mod.save:set('kantoVisited',true)end
  return visited or false
 end
 function C.flyPoints(save,landmarks)
  local rows={};local landmarks=landmarks and landmarks.landmarks or{}
  for i,row in ipairs(Field.FLYPOINTS)do
   if Field.hasVisitedSpawn(save,row.spawn)then
    local entry=landmarks[row.landmark]
    rows[#rows+1]={landmark=row.landmark,spawn=row.spawn,index=entry and entry.index,
     name=entry and entry.name or row.landmark,region=i<Field.KANTO_FLYPOINT and'johto'or'kanto'}
   end
  end
  return rows
 end
 function C.plan(w,h)
  local gap,footer=8,16
  local wide=math.floor(math.min(w/328,(h-footer)/144))
  local tall=math.floor(math.min(w/160,(h-footer)/296))
  if math.max(wide,tall)<1 then return nil end
  local horizontal=wide>=tall;local s=horizontal and wide or tall
  return{mode=horizontal and'wide'or'portrait',scale=s,
   x=(w-(horizontal and 328 or 160)*s)/2,y=(h-(horizontal and 144 or 296)*s-footer)/2,
   dx=horizontal and(160+gap)or 0,dy=horizontal and 0 or(144+gap),footer=footer}
 end
 local function enabled(self)return active(self.game)and C.unlocked(self.game)end
 local function region(self,record)
  local n=record and record.index or self:mapCursorIndex()
  return n>=self:landmarkIndex('PALLET_TOWN',46)and n<self:landmarkIndex('FAST_SHIP',94)and'kanto'or'johto'
 end
 function C.install(Class)
  local new,limits,nativeMap=Class.new,Class.cursorLimits,Class.drawMap
  Class.new=function(game,...)
   local self=new(game,...)
   if self.fly and enabled(self)then
    local selected=self:flyRow();local spawn=selected and selected.spawn
    self.fly=C.flyPoints(self.save,self.landmarks);self.flyIndex=1
    for i,row in ipairs(self.fly)do if row.spawn==spawn then self.flyIndex=i;break end end
   end
   return self
  end
  Class.cursorLimits=function(self,...)
   if enabled(self)then return self:landmarkIndex('ROUTE_28',93),self:landmarkIndex('NEW_BARK_TOWN',1)end
   return limits(self,...)
  end
  -- Render the native panel in a chosen region without changing the player's
  -- landmark (radio availability and the real player marker depend on it).
  local function pane(self,which)
   local old={flyRow=rawget(self,'flyRow'),region=rawget(self,'region'),mapLandmark=rawget(self,'mapLandmark'),playerLandmark=rawget(self,'playerLandmark'),flyRegion=self.flyRegion}
   local current,player,fly=self:mapLandmark(),self:playerLandmark(),self:flyRow()
   self.flyRow=function()return region(self,current)==which and fly or{name=which:upper()}end
   self.region=function()return which end
   self.flyRegion=which
   self.mapLandmark=function()return region(self,current)==which and current or{name=which:upper()}end
   self.playerLandmark=function()return player and region(self,player)==which and player or nil end
   local ok,err=pcall(nativeMap,self)
   self.flyRow=old.flyRow
   self.region,self.mapLandmark,self.playerLandmark,self.flyRegion=old.region,old.mapLandmark,old.playerLandmark,old.flyRegion
   if not ok then error(err,0)end
  end
  Class.drawMap=function(self,...)
   if enabled(self)then return pane(self,region(self,self:mapLandmark()))end
   return nativeMap(self,...)
  end
  function C.draw(self,w,h)
   if not self:styled()or not enabled(self)or not self:card()or self:card().id~='map'then return false end
   local x,y,pw,ph=Chrome.playfieldRect(w,h)
   local field=require('src.render.Playfield')
   local dpi=type(field.pixelScale)=='function' and field.ratio() or 1
   x,y,pw,ph=x*dpi,y*dpi,pw*dpi,ph*dpi
   local p=C.plan(pw,ph)
   if not p then return false end
   local G=love.graphics;G.push('all');G.scale(1/dpi,1/dpi);G.translate(x,y)
   Chrome.paletteFill(0,0,pw,ph)
   G.translate(p.x,p.y);G.scale(p.scale,p.scale)
   pane(self,'johto');G.translate(p.dx,p.dy);pane(self,'kanto');G.pop()
   local hint=Strings(self.fly and'UP/DOWN: DESTINATION   A: FLY   B: BACK'or'UP/DOWN: LOCATION   B: BACK','WIDESCREEN_MENUS_GEN2')
   local Font=require('src.render.Font')
   local scale=math.max(1,math.floor(math.min(pw/Font.width(hint),p.scale)))
   G.push('all');G.scale(1/dpi,1/dpi);G.translate(x+(pw-Font.width(hint)*scale)/2,y+ph-12*scale);G.scale(scale)
   Chrome.printThrough(hint,0,0,Chrome.DEFAULT_BOX_PALETTE);G.pop()
   self.widescreenMenuFrame=p
   return true
  end
 end
 if mod.events then
  for _,name in ipairs({'map.entered','game.ready','save.loaded'})do
   mod.events:on(name,function()C.unlocked(mod.game)end)
  end
 end
 return C
end
return M
