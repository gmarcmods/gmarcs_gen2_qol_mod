-- Gen 2 catches that overflow the party.
--
-- BattleState:storeCaughtMon deposits a caught mon through
-- src.pokemon.Boxes.deposit, and that module is Gen 1 storage: twelve boxes of
-- twenty. A Gold/Silver/Crystal save has fourteen boxes of twenty
-- (src/core/gen2/Save.lua:92-93), so on Gen 2 a catch made while BOX 1-12 are
-- full used to stop at "But every BOX is full!" with boxes 13 and 14 empty.
--
-- This wraps that one entry point, and only while a Gen 2 game is running:
-- Gen 1 keeps the original function byte for byte, Gen 3 never reaches it.
-- The replacement keeps the engine's own rule -- start at the save's current
-- box, take the first box with room, wrapping once -- so the "transferred to
-- someone's PC" text still names the box the mon actually went to.
--
-- Nothing else changes: a full box is skipped, never evicted or reordered, and
-- the mon is appended exactly as the Gen 1 module appended it.

local Gen2Deposit = {}

local function generation()
  local ok, version = pcall(function()
    return require("src.core.GameVersion").generation()
  end)
  if ok then return version end
  return nil
end

-- Pure and screen-free: deposit `mon` into the first box with room, starting
-- at save.currentBox and wrapping once through `count` boxes. Returns the box
-- number used, or nil when every box is full.
function Gen2Deposit.deposit(save, mon, count, capacity)
  if type(save) ~= "table" or mon == nil then return nil end
  count = math.max(1, math.floor(tonumber(count) or 14))
  capacity = math.max(1, math.floor(tonumber(capacity) or 20))
  save.boxes = save.boxes or {}
  local start = math.floor(tonumber(save.currentBox) or 1)
  if start < 1 or start > count then start = 1 end
  for offset = 0, count - 1 do
    local index = ((start - 1 + offset) % count) + 1
    local box = save.boxes[index]
    if box == nil then
      box = {}
      save.boxes[index] = box
    end
    if #box < capacity then
      box[#box + 1] = mon
      return index
    end
  end
  return nil
end

local function limits()
  local ok, module = pcall(require, "src.core.gen2.Boxes")
  if ok and type(module) == "table" then
    return module.NUM_BOXES, module.MONS_PER_BOX
  end
  return 14, 20
end

-- Replaces Boxes.deposit once. Safe to call again: the second call is a no-op
-- so a reload never stacks two wrappers.
function Gen2Deposit.install(Boxes)
  if type(Boxes) ~= "table" or Boxes.__gen3BoxGen2Deposit then return false end
  local original = Boxes.deposit
  Boxes.__gen3BoxGen2Deposit = true
  Boxes.deposit = function(save, mon, ...)
    if generation() ~= 2 then
      if original then return original(save, mon, ...) end
      return nil
    end
    local count, capacity = limits()
    return Gen2Deposit.deposit(save, mon, count, capacity)
  end
  return true
end

return Gen2Deposit
