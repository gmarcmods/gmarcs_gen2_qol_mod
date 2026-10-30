-- Reusable Machines for Gen 2 (Gold/Silver/Crystal)
-- 1) TMs are not consumed when a move is taught.
-- 2) HM moves may be forgotten like ordinary moves.
-- 3) Bag rows display the move next to every TM/HM identifier.
--
-- Based on Reusable Machines v1.0.1 for Gen 1 by the same author.

local PATCH_KEY = "__reusable_machines_gen2_dispatch"
local unpack_ = table.unpack or unpack

-- Gen 2 has 7 field HMs
local CANONICAL_HM_MOVES = {
  CUT = true, FLY = true, SURF = true, STRENGTH = true,
  FLASH = true, WATERFALL = true, WHIRLPOOL = true,
}

local function pack(...)
  return { n = select("#", ...), ... }
end

local function upper(value)
  return tostring(value or ""):upper()
end

local function machineMove(def)
  return type(def)=="table" and (def.teaches or (def.machine and def.machine.move))
end
local function machineKind(def, itemId)
  if type(def)=="table" and def.machine then return upper(def.machine.kind) end
  if not machineMove(def) then return nil end
  local id=upper((def and def.id) or itemId)
  return id:match('^(TM)_') or id:match('^(HM)_')
end
local function isTM(def, itemId)
  return machineKind(def,itemId)=='TM'
end
local function isMachine(def)
  return machineMove(def)~=nil
end

local function isHMMove(game, moveId)
  if not moveId then return false end
  if CANONICAL_HM_MOVES[moveId] then return true end
  for _, def in pairs(game and game.data and game.data.items or {}) do
    if machineKind(def) == "HM" and machineMove(def) == moveId then return true end
  end
  return false
end

local function fit(text, maximum)
  text = tostring(text or "")
  if #text <= maximum then return text end
  if maximum <= 1 then return text:sub(1, maximum) end
  return text:sub(1, maximum - 1) .. "."
end

local function machineLabel(game, itemId, fallback)
  local items = game and game.data and game.data.items or {}
  local moves = game and game.data and game.data.moves or {}
  local def = items[itemId]
  if not isMachine(def) then return fallback end

  local move = moves[machineMove(def)]
  local moveName = (move and move.name) or tostring(machineMove(def))
  local itemName = (def and def.name) or fallback or itemId

  return fit(tostring(itemName) .. " " .. tostring(moveName), 18)
end

local function findMachineItem(game, moveId, kind)
  local inventory = game.save and game.save.inventory or {}
  local fallback
  for itemId, def in pairs(game.data.items or {}) do
    if isMachine(def) and machineMove(def) == moveId
       and (not kind or machineKind(def) == upper(kind)) then
      fallback = fallback or itemId
      if (tonumber(inventory[itemId]) or 0) > 0 then return itemId end
    end
  end
  return fallback
end

local function orderContains(order, itemId)
  for _, value in ipairs(order or {}) do
    if value == itemId then return true end
  end
  return false
end

local function install(game, mod)
  local dispatch = rawget(_G, PATCH_KEY)
  if not dispatch then
    dispatch = {
      sessions = setmetatable({}, { __mode = "k" }),
      bySave = setmetatable({}, { __mode = "k" }),
      stackPatched = setmetatable({}, { __mode = "k" }),
    }
    rawset(_G, PATCH_KEY, dispatch)
  end
  dispatch.game = game
  dispatch.mod = mod

  local okBag, Bag = pcall(require, "src.inventory.Bag")
  -- Gen 2 PartyMenu lives under src.ui.gen2.PartyMenu
  local okParty, PartyMenu = pcall(require, "src.ui.gen2.PartyMenu")
  local okLearn, MoveLearnMenu = pcall(require, "src.ui.MoveLearnMenu")
  local okField, FieldDefaults = pcall(require, "src.world.FieldDefaults")

  local function sessionForGame(currentGame)
    return dispatch.sessions[currentGame]
  end

  local function restoreSession(currentGame)
    local session = sessionForGame(currentGame)
    if not session then return false end
    local save = currentGame.save
    local inventory = save and save.inventory
    if not inventory then return false end

    local current = math.max(0, math.floor(tonumber(inventory[session.itemId]) or 0))
    if current >= session.count then return false end
    local missing = session.count - current

    if okBag and type(Bag.add) == "function" then
      pcall(Bag.add, save, session.itemId, missing)
    end
    current = math.max(0, math.floor(tonumber(inventory[session.itemId]) or 0))
    if current < session.count then inventory[session.itemId] = session.count end

    if okBag and type(Bag.order) == "function" then
      local success, order = pcall(Bag.order, save)
      if success and type(order) == "table" and not orderContains(order, session.itemId) then
        order[#order + 1] = session.itemId
      end
    end
    return true
  end

  local function clearSession(currentGame)
    local session = sessionForGame(currentGame)
    if session then dispatch.bySave[currentGame.save] = nil end
    dispatch.sessions[currentGame] = nil
  end

  local function startSession(currentGame, opts)
    local tmhm = opts and opts.tmhm
    if type(tmhm) ~= "table" then return nil end
    local kind = upper(tmhm.kind)
    local moveId = tmhm.move or tmhm.moveId or tmhm.id
    -- Only legacy menus need Bag session restoration. Native PackMenu uses
    -- consumeItem; tracking its kind-less chooser would also undo a later toss.
    if kind ~= "TM" or not moveId then return nil end

    local itemId = findMachineItem(currentGame, moveId, "TM")
    local count = itemId and tonumber(currentGame.save.inventory[itemId]) or 0
    if not itemId or not count or count <= 0 then return nil end

    local session = {
      itemId = itemId,
      moveId = moveId,
      count = math.max(1, math.floor(count)),
    }
    dispatch.sessions[currentGame] = session
    dispatch.bySave[currentGame.save] = session
    return session
  end

  -- Modern Gen 2 teaches through Game2:consumeItem, not Bag.remove.
  -- This only guards actual TM consumption; explicit tossing and scripted
  -- removal retain their normal Bag/VM paths.
  local consume=game.consumeItem
  if type(consume)=='function' and not game.reusableMachinesConsume then
    game.reusableMachinesConsume=consume
    function game:consumeItem(itemId,...)
      if isTM(self.data and self.data.items and self.data.items[itemId],itemId) then return end
      return consume(self,itemId,...)
    end
  end

  -- Clear the HM forget restriction
  game.data.constants = game.data.constants or {}
  game.data.constants.hmMoves = {}

  if okField and type(FieldDefaults.constant) == "function" then
    if not dispatch.baseFieldConstant then
      dispatch.baseFieldConstant = FieldDefaults.constant
      FieldDefaults.constant = function(data, key, ...)
        if key == "hmMoves" then return {} end
        return dispatch.baseFieldConstant(data, key, ...)
      end
    end
  else
    mod.log:warn("Reusable Machines (Gen 2) could not patch FieldDefaults")
  end

  -- Mark the TM-teaching flow via PartyMenu.new
  if okParty and type(PartyMenu.new) == "function" then
    if not dispatch.basePartyNew then
      dispatch.basePartyNew = PartyMenu.new
      PartyMenu.new = function(currentGame, opts, ...)
        local session = startSession(currentGame, opts)
        local state = dispatch.basePartyNew(currentGame, opts, ...)
        if session and type(state) == "table" then
          state.__reusableMachineFlow = true
        end
        return state
      end
    end
  else
    mod.log:warn("Reusable Machines (Gen 2) could not find PartyMenu")
  end

  -- Modern native learning (PackMenu -> Game2 -> MoveDeleter) does not use
  -- the legacy MoveLearnMenu above. Its private HM table needs the same
  -- scoped identity adapter at confirmation, after any Moveset Plus UI.
  local okNative, NativeDeleter = pcall(require, "src.ui.gen2.MoveDeleter")
  if okNative and type(NativeDeleter.new) == "function" and not dispatch.baseNativeDeleterNew then
    dispatch.baseNativeDeleterNew = NativeDeleter.new
    NativeDeleter.new = function(currentGame, opts, ...)
      local state = dispatch.baseNativeDeleterNew(currentGame, opts, ...)
      if not (state and state.forget) then return state end
      local baseUpdate = state.update
      function state:update(...)
        local exports = currentGame.mods and currentGame.mods.exports
        local input = currentGame.input
        local slot = self.movesetPlusFocus or self.row
        local selected = self.mon and self.mon.moves and self.mon.moves[slot]
        local originalId = selected and selected.id
        if not (exports and exports.reusable_machines_gen2 and input
          and input:wasPressed("a") and isHMMove(currentGame, originalId)) then
          return baseUpdate(self, ...)
        end
        local definitions = currentGame.data.moves
        local tempId = "MOD_REUSABLE_FORGET_" .. originalId
        local previous = definitions[tempId]
        definitions[tempId] = definitions[originalId]
        selected.id = tempId
        local result = pack(pcall(baseUpdate, self, ...))
        if selected.id == tempId then selected.id = originalId end
        definitions[tempId] = previous
        if not result[1] then error(result[2], 0) end
        return unpack_(result, 2, result.n)
      end
      return state
    end
  end

  -- Allow HM moves to be forgotten in MoveLearnMenu
  if okLearn and type(MoveLearnMenu.new) == "function" then
    local function decorateMoveLearn(state, currentGame)
      if type(state) ~= "table" or state.__reusableHMForget then return state end
      local baseUpdate = state.update
      if type(baseUpdate) ~= "function" then return state end
      state.__reusableHMForget = true

      function state:update(...)
        local moves = self.mon and self.mon.moves
        local selected = self.selecting and moves and self.index
          and self.index <= #moves and moves[self.index] or nil
        local originalId = selected and selected.id
        if not isHMMove(currentGame, originalId) then
          return baseUpdate(self, ...)
        end

        local tempId = "MOD_REUSABLE_FORGET_" .. tostring(originalId)
        local moveDefs = currentGame.data and currentGame.data.moves or {}
        local previousTempDef = moveDefs[tempId]
        moveDefs[tempId] = moveDefs[originalId]
        selected.id = tempId

        local result = pack(pcall(baseUpdate, self, ...))

        if selected.id == tempId then selected.id = originalId end
        moveDefs[tempId] = previousTempDef

        if not result[1] then error(result[2], 0) end
        return unpack_(result, 2, result.n)
      end
      return state
    end

    if not dispatch.baseLearnNew then
      dispatch.baseLearnNew = MoveLearnMenu.new
      MoveLearnMenu.new = function(currentGame, ...)
        local state = dispatch.baseLearnNew(currentGame, ...)
        if sessionForGame(currentGame) and type(state) == "table" then
          state.__reusableMachineFlow = true
        end
        return decorateMoveLearn(state, currentGame)
      end
    end
  else
    mod.log:warn("Reusable Machines (Gen 2) could not find MoveLearnMenu")
  end

  -- Guard bag removal to prevent TM consumption during the teaching flow
  if okBag and type(Bag) == "table" then
    dispatch.baseBagFns = dispatch.baseBagFns or {}
    local function patchRemoval(name, negativeOnly)
      local base = Bag[name]
      if type(base) ~= "function" or dispatch.baseBagFns[name] then return end
      dispatch.baseBagFns[name] = base
      Bag[name] = function(...)
        local args = { ... }
        local save = args[1]
        local session = save and dispatch.bySave[save]
        if session then
          local matched = false
          for _, value in ipairs(args) do
            if value == session.itemId then matched = true break end
          end
          if matched then
            if negativeOnly then
              for _, value in ipairs(args) do
                if type(value) == "number" and value < 0 then return true end
              end
            else
              return true
            end
          end
        end
        return base(...)
      end
    end
    patchRemoval("remove", false)
    patchRemoval("take", false)
    patchRemoval("consume", false)
    patchRemoval("add", true)
  end

  -- Restore after stack transitions
  local stack = game.stack
  if stack and not dispatch.stackPatched[stack] then
    dispatch.stackPatched[stack] = true
    for _, name in ipairs({ "push", "pop" }) do
      local base = stack[name]
      if type(base) == "function" then
        stack[name] = function(self, ...)
          local result = pack(base(self, ...))
          restoreSession(game)
          return unpack_(result, 1, result.n)
        end
      end
    end
  end

  -- Relabel bag rows with move names
  local function relabelBag(list)
    for _, row in ipairs(list.items or {}) do
      local itemId = row.value or row.id
      local def = itemId and game.data.items[itemId]
      if isMachine(def) then
        row.label = machineLabel(game, itemId, row.label)
        row.machineMoveName = game.data.moves[machineMove(def)]
          and game.data.moves[machineMove(def)].name or machineMove(def)
      end
    end
  end

  local function otherMachineStateAlive(list)
    local states = game.stack and game.stack.states or {}
    for _, state in ipairs(states) do
      if state ~= list and state.__reusableMachineFlow then return true end
    end
    return false
  end

  local function decorateBag(list)
    if type(list) ~= "table" or list.__reusableMachines then return list end
    local baseUpdate = list.update
    if type(baseUpdate) ~= "function" then return list end
    list.__reusableMachines = true

    function list:update(dt)
      relabelBag(self)
      baseUpdate(self, dt)
      restoreSession(game)
      relabelBag(self)

      local top = game.stack and game.stack.top and game.stack:top()
      if top == self and sessionForGame(game) and not otherMachineStateAlive(self) then
        clearSession(game)
      end
    end

    relabelBag(list)
    return list
  end

  -- Gen 2 BagMenu: check both gen2-specific and shared paths
  local okBagMenu, BagMenu = pcall(require, "src.ui.gen2.BagMenu")
  if not okBagMenu or not BagMenu then
    okBagMenu, BagMenu = pcall(require, "src.ui.BagMenu")
  end
  if okBagMenu and type(BagMenu.new) == "function" then
    if not dispatch.baseBagMenuNew then
      dispatch.baseBagMenuNew = BagMenu.new
      BagMenu.new = function(currentGame, opts, ...)
        local list = dispatch.baseBagMenuNew(currentGame, opts, ...)
        if currentGame == game then return decorateBag(list) end
        return list
      end
    else
      dispatch.game = game
    end
  else
    mod.log:warn("Reusable Machines (Gen 2) could not find BagMenu")
  end

  -- world.stepped cleanup
  mod.events:on("world.stepped", function()
    restoreSession(game)
    clearSession(game)
  end)

  mod.exports.machineLabel = function(itemId, fallback)
    return machineLabel(game, itemId, fallback)
  end
  mod.exports.isMachine = function(itemId)
    return isMachine(game.data.items[itemId])
  end
  mod.exports.restorePendingTM = function()
    return restoreSession(game)
  end

  mod.log:info("Reusable Machines (Gen 2) installed: reusable TMs, forgettable HMs and named machine rows")
end

return function(mod)
  mod.events:on("game.ready", function(event)
    local game = event and event.game
    if not game then
      mod.log:warn("Reusable Machines (Gen 2) could not install: game.ready had no game object")
      return
    end
    install(game, mod)
  end)
end
