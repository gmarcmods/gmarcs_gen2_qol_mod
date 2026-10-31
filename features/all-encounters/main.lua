-- Routes carry every species Gold, Silver or Crystal puts there.
--
-- Each game ships its own wild table per route, so a Pokémon that only Silver
-- has on ROUTE_29 cannot appear there in Gold. This mod replaces the species a
-- route rolls with one drawn from the chosen games' own lists for that route,
-- terrain and time of day: the union keeps each edition's rarity (the slot
-- order is the cart's 30/30/20/10/5/4/1 for grass and 60/30/10 for water, and
-- the weight of a species is its best slot across the chosen games).
--
-- Vanilla still rolls first, so the level, the rate, repels, swarms, roamers
-- and every other rule stay the running game's. Only the species is swapped,
-- and only for ordinary wild encounters: scripted encounters and the Bug
-- Catching Contest keep their own tables.
--
-- data/routes.lua is generated from the player's own three imports by
-- tools/gen_encounters.lua; it holds species ids and slot order only.

local GAMES = { "gold", "silver", "crystal" }

-- The cart's slot weights: seven grass slots, three water slots.
local WEIGHTS = {
  [7] = { 30, 30, 20, 10, 5, 4, 1 },
  [3] = { 60, 30, 10 },
}

local function weightsFor(count)
  local fixed = WEIGHTS[count]
  if fixed then return fixed end
  local even = {}
  for index = 1, count do even[index] = 100 end
  return even
end

return function(mod)
  local routes = assert(loadstring(assert(mod:read("data/routes.lua")),
    "@AllEncounters/routes"))()

  mod.options:define({
    { key = "source", type = "choice", label = "ENCOUNTERS FROM",
      choices = { { "ALL", "all" }, { "GOLD", "gold" },
        { "SILVER", "silver" }, { "CRYSTAL", "crystal" } },
      default = "all",
      help = "Which games' wild lists the routes use. ALL merges the three." },
  })

  local pools = {}

  local function slotsFor(game, kind, mapId, tod)
    local edition = routes[game]
    if not edition then return nil end
    local maps = edition[kind]
    if not maps then return nil end
    local row = maps[mapId]
    if not row then return nil end
    if kind == "water" then return row end
    return row[tod] or row.DAY
  end

  -- species -> best slot weight across the chosen games, in a stable order.
  local function pool(kind, mapId, tod, source)
    local key = table.concat({ source, kind, mapId, tod or "" }, "|")
    local cached = pools[key]
    if cached ~= nil then return cached or nil end
    local games = (source == "all") and GAMES or { source }
    local merged, total = {}, 0
    for _, game in ipairs(games) do
      local list = slotsFor(game, kind, mapId, tod)
      if list then
        local weights = weightsFor(#list)
        for index, species in ipairs(list) do
          local weight = weights[index] or 1
          if not merged[species] or merged[species] < weight then
            merged[species] = weight
          end
        end
      end
    end
    local out = {}
    for species, weight in pairs(merged) do
      out[#out + 1] = { species = species, weight = weight }
      total = total + weight
    end
    table.sort(out, function(a, b) return a.species < b.species end)
    out.total = total
    pools[key] = (#out > 0) and out or false
    if #out == 0 then return nil end
    return out
  end

  local function pick(list, rng)
    if not list or #list == 0 then return nil end
    local roll = rng(list.total)
    local seen = 0
    for _, entry in ipairs(list) do
      seen = seen + entry.weight
      if roll <= seen then return entry.species end
    end
    return list[#list].species
  end

  -- Read-only view of what a route can roll, for other mods and for tests.
  mod.exports.pool = pool
  mod.exports.pick = pick

  mod.hooks:wrap("encounter.species", function(next_, enc, ctx)
    if not (enc and enc.species and ctx) or ctx.kind ~= "wild" then
      return next_(enc, ctx)
    end
    local kind = (ctx.terrain == "water") and "water" or "grass"
    local source = mod.options:get("source") or "all"
    local list = pool(kind, ctx.mapId, ctx.daytime, source)
    if not list then return next_(enc, ctx) end
    local species = pick(list, ctx.rng or math.random)
    if species then enc.species = species end
    return next_(enc, ctx)
  end)
end
