-- Native menu augmentation only: do not replace battle or learning rules.
local State=require('src.ui.gen2.BattleState')
local Summary=require('src.ui.gen2.SummaryMenu')
local Deleter=require('src.ui.gen2.MoveDeleter')
local Game=require('src.core.Game2')
local Mon=require('src.battle.gen2.Mon')
local Chrome=require('src.ui.gen2.Chrome')
return function(mod)
 -- Modules return values directly; Panel takes Info as its chunk argument.
 local I=assert(loadstring(assert(mod:read('lib/Info.lua')),'@MovesetPlus/Info'))()
 local P=assert(loadstring(assert(mod:read('lib/Panel.lua')),'@MovesetPlus/Panel'))(I)
 local function active(game)return game and game.mods and game.mods.exports.gmarcs_gen2_qol_mod~=nil end
 local pending=setmetatable({},{__mode='k'})
 local function learningMoves(old,id,data)
  local list={};for _,entry in ipairs(old or{})do list[#list+1]=entry end
  local def=data and data.moves and data.moves[id]or{}
  list[#list+1]=type(id)=='table'and id or{id=id,pp=def.pp or 0,maxPp=def.pp or 0}
  return list
 end
 local function navigate(screen,count)
  local input=screen.game and screen.game.input
  if not input then return false end
  local focus=screen.movesetPlusFocus or 1
  if input:wasPressed('up')then focus=(focus-2)%count+1
  elseif input:wasPressed('down')then focus=focus%count+1
  elseif input:wasPressed('left')or input:wasPressed('right')then
   local dir=input:wasPressed('left')and -1 or 1
   screen.movesetPlusPage=((screen.movesetPlusPage or 1)-1+dir)%math.max(1,screen.movesetPlusPageCount or 1)+1
   return true
  else return false end
  screen.movesetPlusFocus=focus;screen.movesetPlusPage=1
  return true
 end
 local originalInfo=State.drawMoveInfoBox
 State.drawMoveInfoBox=function(self,move)
  if not active(self.game)or not move then return originalInfo(self,move)end
  local info=I.move(self.game,move)
  local fighter=self.battle and self.battle.player
  local disabled=fighter and self.battle:moveDisabled(fighter,move.id)
  Chrome.box(0,6,11,7)
  Chrome.printThrough(disabled and require('src.core.Strings')('Disabled!')or I.label(self.game,'TYPE'),1,7,Chrome.DEFAULT_BOX_PALETTE)
  Chrome.printThrough(info.type,1,8,Chrome.DEFAULT_BOX_PALETTE)
  Chrome.printThrough(I.label(self.game,'PWR')..' '..info.power,1,9,Chrome.DEFAULT_BOX_PALETTE)
  Chrome.printThrough(I.label(self.game,'ACC'):sub(1,2)..info.accuracy,1,10,Chrome.DEFAULT_BOX_PALETTE)
  Chrome.printThrough('PP '..info.pp,1,11,Chrome.DEFAULT_BOX_PALETTE)
 end
 local originalDetail=Summary.drawMoveDetail
 Summary.drawMoveDetail=function(self,...)
  local result=originalDetail(self,...)
  if active(self.game)and not self.swapFrom then
   local move=self:moveList()[self.moveIndex or 1]
   if move then
    local info=I.move(self.game,move)
    Chrome.printThrough(I.label(self.game,'ACC')..' '..info.accuracy,1,13,Chrome.DEFAULT_BOX_PALETTE)
   end
  end
  return result
 end
 local function makeLearning(screen,id)
  if screen.movesetPlusIncoming then return screen end
  screen.movesetPlusIncoming=id;screen.movesetPlusFocus=1;screen.movesetPlusPage=1
  local originalUpdate=screen.update
  local function moves(self)return learningMoves(self.list,id,self.game.data)end
  screen.isOpaque=true
  screen.drawsWidescreen=function()return true end
  screen.draw=function(self)P.draw(self.game,moves(self),self.movesetPlusFocus,self,160,144)end
  screen.drawWidescreen=function(self,w,h)P.wide(self.game,moves(self),self.movesetPlusFocus,self,w,h)end
  screen.update=function(self,dt)
   if self.done then return end
   if navigate(self,#self.list+1)then self.row=math.min(self.movesetPlusFocus,#self.list);return end
   local input=self.game and self.game.input
   if input and input:wasPressed('a')and self.movesetPlusFocus>#self.list then return self:finish(nil)end
   self.row=math.min(self.movesetPlusFocus,#self.list)
   return originalUpdate(self,dt)
  end
  return screen
 end
 local originalLearn=Game.learnMoveOn
 Game.learnMoveOn=function(self,mon,id,onDone)
  if not active(self)then return originalLearn(self,mon,id,onDone)end
  local prior=pending[mon];local context={id=id};pending[mon]=context
  local function finish(...)
   if pending[mon]==context then pending[mon]=prior end
   if onDone then return onDone(...)end
  end
  local ok,result=pcall(originalLearn,self,mon,id,finish)
  if not ok then if pending[mon]==context then pending[mon]=prior end;error(result,0)end
  return result
 end
 local originalNew=Deleter.new
 Deleter.new=function(game,opts)
  local screen=originalNew(game,opts)
  local context=opts and opts.mon and pending[opts.mon]
  if active(game)and screen.forget and context then makeLearning(screen,context.id)end
  return screen
 end
 local function battleLearning(self)
  local learn=self.pendingLearn
  if not active(self.game)or self.phase~='choose-forget'or not learn or(self.messageTimer or 0)>0 then
   self.movesetPlusLearn=nil;return nil
  end
  if self.movesetPlusLearn~=learn then
   self.movesetPlusLearn=learn;self.movesetPlusFocus=self.forgetIndex or 1;self.movesetPlusPage=1
  end
  local mon=self.battle.party[learn.index]
  return learningMoves(Mon.partyMoves(mon),learn.move,self.game.data)
 end
 local originalUpdate,originalWide,originalPanel,originalBottom=State.update,State.drawWidescreen,State.drawPanel,State.drawBottom
 State.update=function(self,dt,...)
  local moves=battleLearning(self)
  if moves then
   -- This full learning panel replaces the native 'which move?' textbox.
   -- Do not let that hidden textbox's letter delay swallow confirm presses.
   self.typedText=self.message;self.typer=nil
   if navigate(self,#moves)then return end
   local input=self.game and self.game.input
   if input and input:wasPressed('a')and self.movesetPlusFocus==#moves then return self:askStopLearning()end
   self.forgetIndex=math.min(self.movesetPlusFocus,#moves-1)
  end
  local result=originalUpdate(self,dt,...)
  if moves and (self.messageTimer or 0)>0 then self.movesetPlusFocus=self.forgetIndex or 1 end
  return result
 end
 State.drawWidescreen=function(self,w,h)
  local moves=battleLearning(self)
  if moves then return P.wide(self.game,moves,self.movesetPlusFocus,self,w,h)end
  return originalWide(self,w,h)
 end
 State.drawPanel=function(self,...)
  local moves=battleLearning(self)
  if moves then return P.draw(self.game,moves,self.movesetPlusFocus,self,160,144)end
  return originalPanel(self,...)
 end
 State.drawBottom=function(self,...)
  local moves=battleLearning(self)
  if moves then return P.draw(self.game,moves,self.movesetPlusFocus,self,160,144)end
  return originalBottom(self,...)
 end
 mod.exports={info=I,panel=P,makeLearning=makeLearning,learningMoves=learningMoves}
end
