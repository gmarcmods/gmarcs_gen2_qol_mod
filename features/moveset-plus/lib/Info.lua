local Mon=require('src.battle.gen2.Mon')
local Types=require('src.battle.TypeChart')
local Strings=require('src.core.Strings')
local I={}
function I.label(game,key)
 return Strings(key,'MOVESET_PLUS_GEN2')
end
function I.clean(text)
 return tostring(text or''):gsub('<NEXT>',' '):gsub('{NEXT}',' '):gsub('{DONE}',''):gsub('{PROMPT}',''):gsub('%s+',' '):match('^%s*(.-)%s*$')
end
function I.move(game,entry)
 local data=game and game.data or{}
 local id=type(entry)=='table'and entry.id or entry
 local def=(data.moves or{})[id]or{}
 local maximum=type(entry)=='table'and Mon.maxPpOf(entry,data)or(def.pp or 0)
 local current=type(entry)=='table'and entry.pp or maximum
 local power=tonumber(def.power)or 0
 local accuracy=tonumber(def.accuracy)
 if accuracy==nil and tonumber(def.accuracyRaw)then accuracy=math.floor(def.accuracyRaw*100/255+.5)end
 return {id=id,name=def.name or id or'---',type=def.type and Types.displayName(def.type,data)or'---',
 pp=(current or maximum)..'/'..maximum,power=power>=2 and tostring(power)or'---',
 accuracy=accuracy and (tostring(accuracy)..'/100')or'---',description=I.clean(def.description)}
end
return I
