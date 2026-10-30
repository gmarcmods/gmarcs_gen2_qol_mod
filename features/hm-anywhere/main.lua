-- HM Anywhere v1.1.0 for Gen 2 (Gold/Silver/Crystal)
--
-- Owning an HM or field-use TM is enough to use its native field action.
-- All 7 field HMs: CUT, FLY, SURF, STRENGTH, FLASH, WATERFALL, WHIRLPOOL.
--
-- Based on hm_anywhere v1.2.0 for Gen 1 by the same author.

local Strings=require('src.core.Strings')
local function label(source)return Strings(source,'hm_anywhere_gen2')end

local PATCH_KEY = "__hm_anywhere_gen2_dispatch"

-- Gen 2 badge names for each field HM (FieldMoves.BADGE equivalent)
local HM_BADGES = {
  CUT       = "HIVE",
  FLY       = "STORM",
  SURF      = "FOG",
  STRENGTH  = "PLAIN",
  FLASH     = "ZEPHYR",
  WATERFALL = "RISING",
  WHIRLPOOL = "GLACIER",
}

local FIELD_HMS = {
  CUT = true, FLY = true, SURF = true, STRENGTH = true,
  FLASH = true, WATERFALL = true, WHIRLPOOL = true,
}

local FIELD_TMS = {ROCK_SMASH=true, HEADBUTT=true, DIG=true, SWEET_SCENT=true}
local FIELD_ACTIONS = {}
for id in pairs(FIELD_HMS) do FIELD_ACTIONS[id]=true end
for id in pairs(FIELD_TMS) do FIELD_ACTIONS[id]=true end
FIELD_ACTIONS.TELEPORT=true -- learned move; no Teleport TM in native Gen 2

local FIELD_ORDER = { "CUT", "FLY", "SURF", "STRENGTH", "FLASH", "WATERFALL", "WHIRLPOOL", "ROCK_SMASH", "HEADBUTT", "DIG", "SWEET_SCENT", "TELEPORT" }

local FIELD_LABEL = {
  CUT = "CUT", FLY = "FLY", SURF = "SURF", STRENGTH = "STR",
  FLASH = "FLSH", WATERFALL = "WFALL", WHIRLPOOL = "WHIRL",
}

-- ---------------------------------------------------------------- helpers

local function hasCount(value)
  if type(value) == "number" then return value > 0 end
  return value == true
end

--- Read native teaches fields or machine metadata; only field-use TMs qualify.
local function ownedMachine(game, moveId)
  local inventory = game and game.save and game.save.inventory or {}
  local items = game and game.data and game.data.items or {}
  for itemId, count in pairs(inventory) do
    if hasCount(count) then
      local def = items[itemId]
      local machine = def and def.machine
      local id=tostring(def and def.id or itemId)
      local nativeMachine=def and def.teaches==moveId
        and (id:match("^HM_") or FIELD_TMS[moveId] and id:match("^TM_"))
      if nativeMachine or (machine and (machine.kind == "HM" or machine.kind == "TM" and FIELD_TMS[moveId]) and machine.move == moveId) then
        return itemId, def
      end
    end
  end
  return nil
end

local function availableFieldMove(game,moveId)
  if ownedMachine(game,moveId) then return true end
  for _,mon in ipairs(game and game.save and game.save.party or {}) do
    if not mon.isEgg then
      for _,move in ipairs(mon.moves or {}) do
        if move.id==moveId then return true end
      end
    end
  end
  return false
end

local function hasAnyFieldMove(game)
  for _, moveId in ipairs(FIELD_ORDER) do
    if availableFieldMove(game, moveId) then return true end
  end
  return false
end

--- Gen 2 badge check: save.player.badges[badgeName] (named or indexed).
--- FieldMoves.hasBadge is the engine's own check; we replicate its logic
--- here to stay love-free.
local function hasBadge(game, moveId)
  local badge = HM_BADGES[moveId]
  if not badge then return true end
  local save = game and game.save
  local owned = save and save.player and save.player.badges
  if type(owned) ~= "table" then return false end
  if owned[badge] then return true end
  -- Indexed fallback: Johto badges 1-8 in earn order
  local JOHTO = { "ZEPHYR", "HIVE", "PLAIN", "FOG", "MINERAL", "STORM", "GLACIER", "RISING" }
  for index, name in ipairs(JOHTO) do
    if name == badge and owned[index] == true then return true end
  end
  return false
end

--- A living party member to act as the "user" when the engine needs one.
local function fieldHelper(game)
  local party = game and game.save and game.save.party or {}
  for _, mon in ipairs(party) do
    if (mon.hp or 0) > 0 then return mon end
  end
  return party[1]
end

--- Dummy mon that satisfies World:useFieldMove without a real move user.
local function dummyMon(game)
  return fieldHelper(game)
       or { species = "MISSINGNO", nickname = "HM", moves = {}, hp = 1, maxHp = 1 }
end

-- ---------------------------------------------------------------- text

local function pushText(game, text, onDone)
  local TextBox = require("src.render.TextBox")
  game.stack:push(TextBox.new(game, label(text), onDone))
end

local function textOr(game, key, fallback)
  local text = game and game.data and game.data.text
  return (text and text[key]) or fallback
end

local function badgeRequired(game)
  return textOr(game, "_NewBadgeRequiredText",
    "Sorry! A new BADGE\nis required.")
end

local function fieldUnavailable(game, moveId, reopen)
  local name=((game.data.moves or {})[moveId]or{}).name or moveId:gsub('_',' ')
  pushText(game, Strings.translate("%s can't be\nused right now.",'hm_anywhere_gen2',name)or("%s can't be\nused right now."):format(name), reopen)
end

-- ---------------------------------------------------------------- contextual

local function contextualEnabled(mod)
  return mod.save:get("contextualActions", true) ~= false
end

local function setContextual(mod, enabled)
  mod.save:set("contextualActions", enabled and true or false)
end

--- Walk the field move OW arm through the engine's own dispatch.
--- Gen 2's World already owns tryCutOW / trySurfOW /
--- tryWaterfallOW / tryWhirlpoolOW, so we only need to check ownership
--- then delegate target and badge checks to the native dispatcher.
local function contextualFieldMove(game, ow, moveId)
  if not ownedMachine(game, moveId) then return false end
  -- Gen 2's World already has the try*OW methods; call through useFieldMove
  -- which builds its own fieldContext and does the full check.
  local world = game.world
  if not world or not world.map or not world.player then return false end

  -- For moves that have dedicated OW arms, call them directly.
  if moveId == "CUT" and world.tryCutOW then
    return world:tryCutOW()
  elseif moveId == "SURF" and world.trySurfOW then
    return world:trySurfOW()
  elseif moveId == "WATERFALL" and world.tryWaterfallOW then
    return world:tryWaterfallOW()
  elseif moveId == "WHIRLPOOL" and world.tryWhirlpoolOW then
    return world:tryWhirlpoolOW()
  end
  return false
end

local function contextualInteract(game, mod, baseInteract, ow, ...)
  if not (ow and ow.player and ow.map) then return baseInteract(ow, ...) end

  -- CTX OFF: pure vanilla interaction.
  if not contextualEnabled(mod) then
    return baseInteract(ow, ...)
  end

  -- NPC directly ahead wins over all contextual field actions.
  local fx, fy = ow.player:facingCell()
  local npcAtCell = ow.npcAtCell
  local npc = npcAtCell and npcAtCell(ow, fx, fy)
  if npc then
    return baseInteract(ow, ...)
  end

  -- Strength is dispatched by the boulder NPC above. Its native prompt
  -- deliberately has no target test and must never be polled on empty tiles.
  if contextualFieldMove(game, ow, "CUT") then return end
  if contextualFieldMove(game, ow, "SURF") then return end
  if contextualFieldMove(game, ow, "WATERFALL") then return end
  if contextualFieldMove(game, ow, "WHIRLPOOL") then return end

  return baseInteract(ow, ...)
end

-- ---------------------------------------------------------------- menu actions

-- Native useFieldMove queues work until the world owns input again.
-- Leaving Start underneath the HM menu stalls every successful non-Fly HM.
local function finishMenuFieldMove(game, result)
  if not (result and result.ok) then return false end
  local world = game.world
  if world.exitMenusFade then world:exitMenusFade() end
  game.stack:clear()
  return true
end

local function cutFromMenu(game, reopen)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "CUT", reopen) return
  end
  if not hasBadge(game, "CUT") then
    pushText(game, badgeRequired(game), reopen) return
  end
  local result = world:useFieldMove("CUT", dummyMon(game))
  if finishMenuFieldMove(game, result) or world.textbox then return end
  pushText(game, textOr(game, "_NothingToCutText",
    "There's nothing to\nCUT here."), reopen)
end

local function surfFromMenu(game, reopen)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "SURF", reopen) return
  end
  if not hasBadge(game, "SURF") then
    pushText(game, badgeRequired(game), reopen) return
  end
  local result = world:useFieldMove("SURF", dummyMon(game))
  if finishMenuFieldMove(game, result) or world.textbox then return end
  local reason = result and result.text or ""
  local text = tostring(reason)
  if text:find("already") then
    pushText(game, "You're already\nSURFING.", reopen)
  elseif text:find("can't") or text:find("here") then
    pushText(game, textOr(game, "_NoSurfingHereText",
      "No SURFing here!"), reopen)
  else
    pushText(game, textOr(game, "_NoSurfingHereText",
      "No SURFing here!"), reopen)
  end
end

local function strengthFromMenu(game, reopen)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "STR", reopen) return
  end
  if not hasBadge(game, "STRENGTH") then
    pushText(game, badgeRequired(game), reopen) return
  end
  if world.strengthActive then
    pushText(game, "STRENGTH is already\nbeing used.", reopen) return
  end
  local result = world:useFieldMove("STRENGTH", dummyMon(game))
  if finishMenuFieldMove(game, result) or world.textbox then return end
  pushText(game, "Can't use that\nhere.", reopen)
end

local function flashFromMenu(game, reopen)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "FLASH", reopen) return
  end
  if not hasBadge(game, "FLASH") then
    pushText(game, badgeRequired(game), reopen) return
  end
  local context = world.fieldContext and world:fieldContext(dummyMon(game))
  if not (context and context.dark) then
    pushText(game, "It is already\nbright here.", reopen) return
  end
  local result = world:useFieldMove("FLASH", dummyMon(game))
  if finishMenuFieldMove(game, result) or world.textbox then return end
  pushText(game, "Can't use that\nhere.", reopen)
end

local function waterfallFromMenu(game, reopen)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "WFALL", reopen) return
  end
  if not hasBadge(game, "WATERFALL") then
    pushText(game, badgeRequired(game), reopen) return
  end
  local result = world:useFieldMove("WATERFALL", dummyMon(game))
  if finishMenuFieldMove(game, result) or world.textbox then return end
  pushText(game, "Can't use that\nhere.", reopen)
end

local function whirlpoolFromMenu(game, reopen)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "WHIRL", reopen) return
  end
  if not hasBadge(game, "WHIRLPOOL") then
    pushText(game, badgeRequired(game), reopen) return
  end
  local result = world:useFieldMove("WHIRLPOOL", dummyMon(game))
  if finishMenuFieldMove(game, result) or world.textbox then return end
  pushText(game, "Can't use that\nhere.", reopen)
end

local function flyFromMenu(game, mod)
  local world = game.world
  if not (world and world.map and world.player) then
    fieldUnavailable(game, "FLY") return
  end
  if not hasBadge(game, "FLY") then
    pushText(game, badgeRequired(game)) return
  end
  -- Gen 2's FLY opens the Pokegear fly map, not a text box.
  -- World:openFlyMap(mon) needs a real mon for the bird sprite, so we
  -- pass a living party member (which is what the engine would pick
  -- anyway).
  local mon = dummyMon(game)
  world:openFlyMap(mon, {
    onChosen = function(spawnId)
      -- Match the native party-menu flow: the world processes the queued
      -- flight only after the start/HM menus have released input ownership.
      world.queuedFieldMove = {ok=true, action="fly", flySpawn=spawnId, mon=mon}
      if world.exitMenusFadeForFly then world:exitMenusFadeForFly()
      elseif world.exitMenusFade then world:exitMenusFade() end
      game.stack:clear()
    end,
    onCancel = function() end,
  })
end

local function otherFieldMoveFromMenu(game, move, reopen)
  local world=game.world
  if not(world and world.map and world.player)then return fieldUnavailable(game,move,reopen)end
  local result=world:useFieldMove(move,dummyMon(game))
  if result and result.ok and result.action=='rocksmash'then
    -- Rock Smash is a native map script, not World:runFieldMove's queue.
    local Field=require('src.world.gen2.FieldMoves')
    local script=Field.rockSmashFromMenuScript(world.stdScripts,world.vm and world.vm.scripts,
      function(name)return world:specialIdNamed(name)end)
    world.queuedFieldMove=nil
    if not script then return fieldUnavailable(game,move,reopen)end
    if world.vm then world.vm.lastTalked=result.lastTalked end
    world.queuedScript=script
  end
  if finishMenuFieldMove(game,result)then return end
  -- Native useFieldMove already opens its localized refusal text.
  if not world.textbox then fieldUnavailable(game,move,reopen)end
end

-- ---------------------------------------------------------------- HM menu

local function openHMMenu(game, mod)
  local Menu = require("src.ui.Menu")
  local Screens = require("src.ui.Screens")

  local function reopen() openHMMenu(game, mod) end

  local actions = {
    CUT       = function() cutFromMenu(game, reopen) end,
    FLY       = function() flyFromMenu(game, mod) end,
    SURF      = function() surfFromMenu(game, reopen) end,
    STRENGTH  = function() strengthFromMenu(game, reopen) end,
    FLASH     = function() flashFromMenu(game, reopen) end,
    WATERFALL = function() waterfallFromMenu(game, reopen) end,
    WHIRLPOOL = function() whirlpoolFromMenu(game, reopen) end,
  }

  for _,move in ipairs({'ROCK_SMASH','HEADBUTT','DIG','SWEET_SCENT','TELEPORT'})do
    local id=move
    actions[id]=function()otherFieldMoveFromMenu(game,id,reopen)end
  end
  local items = {}
  for _, moveId in ipairs(FIELD_ORDER) do
    if availableFieldMove(game, moveId) then
      items[#items + 1] = {
        label = ((game.data.moves or {})[moveId] or {}).name or FIELD_LABEL[moveId] or moveId:gsub("_"," "),
        onSelect = actions[moveId],
      }
    end
  end

  if #items == 0 then
    pushText(game, "No field move is\nin the BAG.", function()
      game.stack:pop()
    end)
    return
  end

  -- CTX toggle at the bottom of the HM menu
  local contextItem
  contextItem = {
    label = label(contextualEnabled(mod) and "CTX ON" or "CTX OFF"),
    keepOpen = true,
    onSelect = function()
      local enabled = not contextualEnabled(mod)
      setContextual(mod, enabled)
      contextItem.label = label(enabled and "CTX ON" or "CTX OFF")
      mod.log:info("HM Anywhere (Gen 2) contextual actions: %s",
        enabled and "ON" or "OFF")
    end,
  }
  items[#items + 1] = contextItem

  local width=10
  for _,row in ipairs(items)do
    local count=0;for _ in row.label:gmatch('[^\128-\191]')do count=count+1 end
    width=math.min(20,math.max(width,count+3))
  end
  game.stack:push(Menu.new(game, items, {
    tx = 20-width, ty = 0, tw = width, maxVisible = 8,
    onCancel = function()
      -- Pop the HM menu; the Gen2StartMenu underneath resumes.
      game.stack:pop()
    end,
  }))
end

-- ---------------------------------------------------------------- install

return function(mod)
  -- Store the game reference once so hooks can reach it without the context
  -- carrying one (Gen 2's fieldmove.eligibility ctx has save/data/party/moveId
  -- but no game).
  local gameRef = nil
  local installed = false

  mod.events:on("game.ready", function(event)
    local game = event and event.game
    if not game then return end
    gameRef = game

    -- ---------------------------------------------------------------
    -- 1) Hook fieldmove.eligibility: own an HM -> "party knows it".
    --    The engine calls this hook before its own party scan; returning
    --    a mon here short-circuits the check.  The vanilla chain still
    --    runs first, so a party that really knows the move wins.
    -- ---------------------------------------------------------------
    mod.hooks:wrap("fieldmove.eligibility", function(next_, moveId, ctx)
      local mon = next_(moveId, ctx)
      if mon then return mon end
      if gameRef and FIELD_ACTIONS[moveId] and ownedMachine(gameRef, moveId) then
        return fieldHelper(gameRef)
      end
      return nil
    end)

    -- ---------------------------------------------------------------
    -- 2) Wrap World:interact for contextual A-button actions. `game.ready`
    --    fires before Game2:startWorld creates its World instance, so patch
    --    the Gen 2 World module method here instead of looking for game.world.
    -- ---------------------------------------------------------------
    local World = require("src.world.gen2.World")
    local dispatch = rawget(_G, PATCH_KEY)
    if not dispatch then
      dispatch = { baseInteract = World.interact }
      rawset(_G, PATCH_KEY, dispatch)
      World.interact = function(self, ...)
        local handler = dispatch.interact
        if handler then return handler(self, ...) end
        return dispatch.baseInteract(self, ...)
      end
    end
    dispatch.interact = function(ow, ...)
      return contextualInteract(game, mod, dispatch.baseInteract, ow, ...)
    end
    installed = true

    mod.log:info(
      "HM Anywhere (Gen 2) installed: contextual CUT/SURF/STR/WFALL/WHIRL is %s",
      contextualEnabled(mod) and "ON" or "OFF")
  end)

  -- ---------------------------------------------------------------
  -- 3) Start -> HM: inject an HM row before SAVE.
  --    Gen 2 start menu items have { label, value, desc }.
  --    Mod rows without a `value` land on onSelect (StartMenu:choose).
  -- ---------------------------------------------------------------
  mod.hooks:wrap("ui.start_menu.items", function(next_, game, items)
    local out = next_(game, items)
    if type(out) ~= "table" then return out end
    if not hasAnyFieldMove(game) then return out end
    -- Already present?  Do not double-inject.
    for _, item in ipairs(out) do
      local label = tostring(item.label or ""):upper()
      if item.id == "hm_anywhere_gen2" or label == "HM" then return out end
    end
    -- Insert before SAVE (the engine's save row).
    local saveIdx
    for i, item in ipairs(out) do
      local id = item.id or ""
      if id == "save" or tostring(item.value or ""):upper() == "SAVE" then
        saveIdx = i; break
      end
    end
    local entry = {
      id = "hm_anywhere_gen2",
      label = label("HM"),
      onSelect = function() openHMMenu(game, mod) end,
    }
    if saveIdx then
      table.insert(out, saveIdx, entry)
    else
      out[#out + 1] = entry
    end
    return out
  end)

  -- ---------------------------------------------------------------
  -- 4) Strip per-mon field-move rows from the party submenu.
  --    They are redundant: Start -> HM covers everything.
  --    Keep them in battle submenus.
  -- ---------------------------------------------------------------
  mod.hooks:wrap("ui.party.submenu", function(next_, game, items, mon, ctx)
    local out = next_(game, items, mon, ctx)
    if type(out) ~= "table" or (ctx and ctx.battle) then return out end
    local cleaned = {}
    for _, item in ipairs(out) do
      local label = tostring(item.id or item.value or item.label or ""):upper()
      if not FIELD_ACTIONS[label] then
        cleaned[#cleaned + 1] = item
      end
    end
    return cleaned
  end)

  -- ---------------------------------------------------------------
  -- Exports for companion mods.
  -- ---------------------------------------------------------------
  mod.exports.ownedHM = function(game, moveId)
    return FIELD_HMS[moveId]==true and ownedMachine(game, moveId) ~= nil
  end
  mod.exports.ownedMachine=function(game,moveId)return ownedMachine(game,moveId)~=nil end
  mod.exports.installed = function() return installed end
  mod.exports.hasBadge = hasBadge
  mod.exports.contextualEnabled = function() return contextualEnabled(mod) end
  mod.exports.setContextual = function(enabled) setContextual(mod, enabled) end
end
