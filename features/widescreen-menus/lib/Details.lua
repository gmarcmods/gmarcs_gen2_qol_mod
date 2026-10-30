local Strings=require('src.core.Strings')
local Types=require('src.battle.TypeChart')
local Mon=require('src.battle.gen2.Mon')
local D={}
function D.label(game,key)
 return Strings(key,'WIDESCREEN_MENUS_GEN2')
end
local function clean(s)return (tostring(s or''):gsub('<NEXT>',' '):gsub('{NEXT}',' '):gsub('{DONE}',''):gsub('{PROMPT}',''):gsub('%s+',' '))end
function D.move(game,move)
 local def=game.data.moves[move.id]or{}
 local acc=tonumber(def.accuracy)
 if not acc and tonumber(def.accuracyRaw)then acc=math.floor(def.accuracyRaw*100/255+.5)end
 return {def.name or move.id,
  D.label(game,'TYPE')..': '..(def.type and Types.displayName(def.type,game.data)or'---'),
  'PP '..tostring(move.pp or def.pp or 0)..'/'..Mon.maxPpOf(move,game.data),
  D.label(game,'PWR')..' '..((tonumber(def.power)or 0)>=2 and tostring(def.power)or'---')..'  '..D.label(game,'ACC')..' '..(acc and tostring(acc)..'/100'or'---'),clean(def.description)}
end
function D.lines(screen,kind)
 local game=screen.game;local data=game.data
 local out={};local function add(s)out[#out+1]=tostring(s or'')end
 local mon=screen.mon or(screen.party and screen.party[screen.index or 1])
 if kind=='MOVE TUTOR'and screen.list then
  local list=screen.list;mon=list.party and list.party[list.index or 1]
 end
 if kind=='PC'and screen.selected then mon=screen:selected()end
 if kind=='POKéDEX'then
  local row=screen.current and screen:current()
  if not row or not row.seen then return {D.label(game,'NO SELECTION')}end
  add((data.pokemon[row.species]or{}).name or row.species)
  add(D.label(game,'SEEN')..': '..D.label(game,'YES'))
  add(D.label(game,'OWN')..': '..D.label(game,row.caught and 'YES'or'NO'))
  if row.caught then
   local def=screen.dex and screen.dex.entries[row.species]or{}
   add(def.kind);add(clean(def.text));add(clean(def.text2))
  end
  return out
 end
 if mon then
  if mon.isEgg then return {Strings('EGG')}end -- never reveal an egg's hidden identity/stats
  add(Mon.displayName(mon));add(D.label(game,'Lv.')..' '..tostring(mon.level or 1))
  add(D.label(game,'HP')..' '..tostring(mon.hp or 0)..'/'..tostring(mon.maxHp or 0))
  local def=data.pokemon[mon.species]or{}
  local types,seen={},{};for _,id in ipairs(mon.types or def.types or{})do if not seen[id]then seen[id]=true;types[#types+1]=Types.displayName(id,data)end end
  if #types>0 then add(D.label(game,'TYPE')..': '..table.concat(types,' / '))end
  if mon.item then add(D.label(game,'ITEM')..': '..((data.items[mon.item]or{}).name or mon.item))end
  if screen.moveDetail then
   local move=(screen.moveList and screen:moveList()or mon.moves or{})[screen.moveIndex or 1]
   if move then for _,line in ipairs(D.move(game,move))do add(line)end end
  else
   add(D.label(game,'MOVES'))
   for _,move in ipairs(mon.moves or{})do
    local m=data.moves[move.id]or{};add((m.name or move.id)..'  PP '..tostring(move.pp or 0)..'/'..Mon.maxPpOf(move,data))
   end
  end
  return out
 end
 if kind=='MAIL'then
  if screen.entry then add(screen.entry.author);add(clean(screen.entry.message))else add(clean(screen.text))end
  return out
 end
 if kind=='TRAINER CARD'then
  local player=(game.save or{}).player or{};add(player.name);add('ID '..tostring(player.id or player.trainerId or'---'))
  return out
 end
 if kind=='OPTIONS'and screen.visible then
  local row=screen:visible()[screen.index or 1]
  if row then add(D.label(game,row.label or''));if row.text then add(row.text(screen.options))end end
  return out
 end
 local row=(screen.rows or screen.entries or screen.items or{})[screen.listIndex or screen.index or 1]
 if type(row)=='table'then
  add(D.label(game,row.label or row.name or row.id or ''))
  local def=(data.items or{})[row.id]or{}
  add(clean(row.description or row.desc or def.description))
 end
 return out
end
return D
