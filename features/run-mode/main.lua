-- Run Mode for Gen 2 (Gold/Silver/Crystal)
-- Hold (or toggle) B to walk at bike speed while on foot.
-- Scripted NPC walks match that step length so escorts do not leave
-- you waiting on a 16-frame walk cycle.
--
-- Based on Run Mode v1.2.0 for Gen 1 by masterwebx.
-- Gen 2 adaptation: game.world replaces game.overworld.

local mod = ...

local MOD_ID = "RUN_MODE_GEN2"
local Strings=require("src.core.Strings")
local function label(source)return Strings(source,MOD_ID)end

-- ------- options
local function readOpt(key, default)
  local ok, got = pcall(mod.options.get, mod.options, key)
  if ok and got ~= nil then return got end
  return default
end

local function persist(key, value, game)
  local opts = game and game.save and game.save.options
  if opts then
    opts.modOptions = opts.modOptions or {}
    opts.modOptions[MOD_ID] = opts.modOptions[MOD_ID] or {}
    opts.modOptions[MOD_ID][key] = value
  end
  local loader = game and game.mods
  if loader then
    loader.modOptions = loader.modOptions or {}
    loader.modOptions[MOD_ID] = loader.modOptions[MOD_ID] or {}
    loader.modOptions[MOD_ID][key] = value
  end
  if game and game.writeOptions then pcall(game.writeOptions, game) end
end

local cache = {}

local function optBool(key, default)
  if cache[key] ~= nil then return cache[key] end
  cache[key] = readOpt(key, default) and true or false
  return cache[key]
end

local function optChoice(key, default, allowed)
  if cache[key] ~= nil then return cache[key] end
  local v = readOpt(key, default)
  if not allowed[v] then v = default end
  cache[key] = v
  return v
end

mod.options:define({
  {
    key = "enabled", type = "toggle", label = "RUN",
    default = true,
    help = "Master switch for overworld running.",
  },
  {
    key = "mode", type = "choice", label = "RUN MODE",
    choices = { { "HOLD B", "hold" }, { "TOGGLE B", "toggle" } },
    default = "hold",
    help = "HOLD B: run while B is held. TOGGLE B: press B to lock run on/off.",
  },
  {
    key = "speed", type = "choice", label = "RUN SPEED",
    choices = {
      { "FAST", "fast" },       -- bike speed (8 frames)
      { "FASTER", "faster" },   -- between bike and sprint (6 frames)
      { "FASTEST", "fastest" }, -- sprint (4 frames)
    },
    default = "fast",
    help = "How fast running is. FAST matches the bicycle; FASTER/FASTEST go beyond it.",
  },
})

-- Toggle latch (in-memory; also mirrored to mod.save so it survives soft reloads)
local toggleOn = mod.save:get("toggleOn", false) and true or false

local SPEED_FRAMES = {
  fast = 8,    -- same as bikeStepFrames
  faster = 6,
  fastest = 4,
}

local function bDown(input)
  if not input then return false end
  if input.isDown then return input:isDown("b") and true or false end
  if input.down then return input.down.b and true or false end
  return false
end

local function bPressed(input)
  if not input then return false end
  if input.wasPressed then return input:wasPressed("b") and true or false end
  return false
end

-- Gen 2 world accessor: game.world (World.lua) instead of game.overworld
local function getWorld(game)
  return game and game.world
end

-- Toggle must be polled every frame. Edge-detecting inside movement.speed
-- only runs when a step STARTS, so short B taps (especially at FASTER /
-- FASTEST) are missed and you cannot turn run off.
local function pollToggle(game)
  if not optBool("enabled", true) then return end
  local mode = optChoice("mode", "hold", { hold = true, toggle = true })
  if mode ~= "toggle" then return end
  local ow = getWorld(game)
  if not ow or not ow.player then return end
  if game.save and game.save.onBike then return end
  if ow.player.surfing then return end
  -- Same lockout as overworld input: do not flip mid-menu / cutscene.
  if ow.transitioning or ow.engaging or ow.emote or ow.teleportOut then return end
  if ow.runner and ow.runner.isRunning and ow.runner:isRunning() then return end
  if ow.scriptMoves and #ow.scriptMoves > 0 then return end
  local top = game.stack and game.stack:top()
  if top and top ~= ow then return end
  if bPressed(game.input) then
    toggleOn = not toggleOn
    mod.save:set("toggleOn", toggleOn)
  end
end

local function wantRun(ctx)
  if not optBool("enabled", true) then return false end
  if ctx.onBike or ctx.surfing then return false end
  local mode = optChoice("mode", "hold", { hold = true, toggle = true })
  if mode == "toggle" then return toggleOn end
  return bDown(ctx.input)
end

local function runTargetFrames()
  local speed = optChoice("speed", "fast", {
    fast = true, faster = true, fastest = true,
  })
  return SPEED_FRAMES[speed] or 8
end

mod.hooks:wrap("movement.speed", function(next, frames, ctx)
  frames = next(frames, ctx)
  ctx = ctx or {}
  if not wantRun(ctx) then return frames end
  local target = runTargetFrames()
  -- Never slow the player down (e.g. already on bike at 8).
  if type(frames) == "number" and frames <= target then return frames end
  return target
end)

-- ------- scripted NPC pace match
--
-- updateScriptMoves starts tiles without going through movement.speed.
-- NPCs default to 16 frames/tile while the player may still be at run
-- speed (or a parallel scriptMove inherits stepFramesCur), so escorts
-- stall on the NPC. Mirror the player's effective step length onto every
-- entity about to take a scripted step; restore NPC overrides when they
-- leave the script queue (Pikachu's own stepFrames is left alone unless
-- we tagged it).

local function effectiveStepFrames(game)
  local ow = getWorld(game)
  local player = ow and ow.player
  local walk = (player and player.stepFrames) or 16
  if game and game.save and game.save.onBike then
    return (player and player.bikeStepFrames) or 8
  end
  if player and player.surfing then return walk end
  -- Scripts often lock input, so B-hold is unreliable here. While RUN is
  -- on, scripted steps use the configured run speed so NPCs keep pace.
  if not optBool("enabled", true) then return walk end
  return runTargetFrames()
end

local function entityStillScripted(ow, entity)
  for _, mv in ipairs(ow.scriptMoves or {}) do
    if mv.entity == entity then return true end
  end
  return false
end

do
  local OverworldState = require("src.world.OverworldController")
  if not OverworldState._runModeTogglePoll then
    OverworldState._runModeTogglePoll = true
    local baseUpdate = OverworldState.update
    function OverworldState:update(dt)
      local Game = require("src.core.Game")
      pollToggle(Game)
      return baseUpdate(self, dt)
    end
  end
  if not OverworldState._runModeScriptSync then
    OverworldState._runModeScriptSync = true
    local base = OverworldState.updateScriptMoves
    OverworldState._runModeScriptBase = base
    function OverworldState:updateScriptMoves()
      local Game = require("src.core.Game")
      local frames = effectiveStepFrames(Game)
      local player = self.player
      for _, mv in ipairs(self.scriptMoves or {}) do
        local e = mv.entity
        if e and not e.moving and mv.remaining and mv.remaining > 0 then
          if e == player then
            e.stepFramesCur = frames
          else
            if not e._runModeStepOwned then
              e._runModeStepSaved = e.stepFrames
              e._runModeStepOwned = true
            end
            e.stepFrames = frames
          end
        end
      end
      base(self)
      for _, e in ipairs(self.entities or {}) do
        if e ~= player and e._runModeStepOwned
           and not entityStillScripted(self, e) then
          e.stepFrames = e._runModeStepSaved
          e._runModeStepOwned = nil
          e._runModeStepSaved = nil
        end
      end
    end
  end
end

-- Short steps used progress % 16 for legs, so a 4-frame step never reached
-- the walk frame (slide).
--
-- Movement speed still follows the player (including FASTER's 6). Walk
-- *animation* always uses the clean FAST/bike 16-phase cycle mapped across
-- the step, so FASTER does not jitter. Pikachu never uses catch-up half-speed
-- while the player is running.
do
  local Collision = require("src.world.Collision")
  local NPC = require("src.world.NPC")
  if not NPC._runModeAnimClockV5 then
    NPC._runModeAnimClockV5 = true
    local baseUpdate = NPC.update

    -- Clean FAST-style legs: one 16-phase cycle stretched over the step.
    local function cleanWalkPhase(progress, stepLen)
      if not progress or progress < 1 or not stepLen or stepLen < 1 then
        return 0
      end
      local phase = math.floor((progress - 1) * 16 / stepLen) % 16
      return (phase >= 4 and phase < 12) and 1 or 0
    end

    function NPC:update(map, entities)
      -- Gen 2 Pikachu follower uses the same pikachuFollower flag (Follower.lua)
      if self.pikachuFollower then
        local Game = require("src.core.Game")
        local ow = getWorld(Game)
        local p = ow and ow.player
        local want = p and (p.stepFramesCur or p.stepFrames)
        if want and want < 16 and (not self.moving or (self.progress or 0) == 0) then
          self.stepFrames = want
        end
      end
      local wasMoving = self.moving
      baseUpdate(self, map, entities)
      -- Smooth pixel steps when length does not divide 16 (FASTER=6).
      if self.moving and not self.marching and self.stepFrames
         and (16 % self.stepFrames) ~= 0 then
        local d = Collision.DELTA[self.facing]
        if d then
          local span = self.hopStep and 2 or 1
          local moved = math.floor(
            self.progress * 16 * span / self.stepFrames + 0.5)
          if moved > 16 * span then moved = 16 * span end
          self.px = self.cellX * 16 + d[1] * moved
          self.py = self.cellY * 16 + d[2] * moved
        end
      end
      if self.moving then
        self.animClock = (self.animClock or 0) + 1
        self.stepLanded = false
      elseif wasMoving then
        self.stepLanded = not self.pikachuFollower
      else
        self.stepLanded = false
      end
    end

    function NPC:walkPhase()
      if not self.moving and not self.stepLanded then return 0 end
      local stepLen = self.stepFrames or 16
      if stepLen < 16 then
        return cleanWalkPhase(self.progress or self.animClock, stepLen)
      end
      local phase = (self.animClock or self.progress or 0) % 16
      return (phase >= 4 and phase < 12) and 1 or 0
    end
  end
end

-- OPTIONS submenu (QoL-style OPEN row)
local RUN_SCREEN = "RunModeOptionsGen2"

local function makeRunScreen(game)
  -- Reuse the engine's schema UI and localization instead of drawing Gen 1
  -- OptionRows from a Gen 2 mod. The ordinary options-change event keeps
  -- our running cache and toggle latch in sync with these rows.
  local Manager = require("src.mods.ManagerState")
  local screen = Manager.new(game)
  local schema = assert(game.mods.optionSchemas[MOD_ID], "Run Mode schema missing")
  screen.optionRows = screen:buildOptionRows({ id = MOD_ID }, schema)
  screen.screen, screen.cursor, screen.scroll = "options", 1, 0
  return screen
end

mod.content.screens:register(RUN_SCREEN, { new = makeRunScreen })

mod.events:once("mods.loaded", function()
  local ManagerState = require("src.mods.ManagerState")
  local routes = rawget(ManagerState, "__modOptionScreenRoutes")
  if not routes then
    routes = {}
    local openOptions = ManagerState.openOptions
    ManagerState.openOptions = function(self, manifest)
      local screenId = manifest and routes[manifest.id]
      if screenId then
        return require("src.ui.Screens").push(self.game, screenId)
      end
      return openOptions(self, manifest)
    end
    ManagerState.__modOptionScreenRoutes = routes
  end
  routes[MOD_ID] = RUN_SCREEN
end)

mod.hooks:wrap("ui.options.rows", function(next, game, rows)
  local out = next(game, rows)
  if type(out) ~= "table" then return out end
  local row = {
    id = MOD_ID .. ":open",
    label = label("RUN MODE"),
    value = function() return label("OPEN") end,
    activate = function(g)
      require("src.ui.Screens").push(g, RUN_SCREEN)
    end,
  }
  if mod.ui and type(mod.ui.insertBefore) == "function" then
    return mod.ui.insertBefore(out, "MODS", row)
  end
  out[#out + 1] = row
  return out
end)

mod.events:on("mod.options_changed", function(payload)
  if not payload or payload.mod ~= MOD_ID then return end
  cache[payload.key] = payload.value
  if payload.key == "enabled" and not payload.value then
    toggleOn = false
    mod.save:set("toggleOn", false)
  end
end)

mod.log:info("run mode gen2 ready (hold/toggle B; scripted NPCs match pace)")
