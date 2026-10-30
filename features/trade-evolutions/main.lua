-- Trade evolutions for Gold/Silver/Crystal, using the Gen 2 evolution registry.
return function(mod)
  mod.options:define({
    {
      key = 'trade_level', type = 'choice', label = 'TRADE EVO LEVEL',
      choices = {{'LEVEL 30','30'}, {'LEVEL 37','37'}, {'LEVEL 40','40'},
        {'LEVEL 45','45'}, {'LEVEL 50','50'}},
      default = '37',
      help = 'Kadabra, Machoke, Graveler and Haunter evolve when levelling up at or above this level.',
    },
    {
      key = 'item_level', type = 'choice', label = 'HELD ITEM EVO LEVEL',
      choices = {{'ANY LEVEL','1'}, {'LEVEL 20','20'}, {'LEVEL 30','30'},
        {'LEVEL 37','37'}, {'LEVEL 40','40'}},
      default = '1',
      help = 'Level up holding the required trade-evolution item. The item is consumed only when evolution succeeds.',
    },
  })

  local function threshold(key, fallback)
    local value = tonumber(mod.options:get(key)) or fallback
    return math.max(1, math.min(100, math.floor(value)))
  end

  mod.content.evolution_methods:patch('EVOLVE_TRADE', {
    check = function(entry, mon, ctx)
      ctx = ctx or {}
      -- The engine retains requiresLink on this registry record, which calls
      -- this predicate before its generic link/stone gates. Apply both gates
      -- explicitly: these replacements run on level-up, never on a trade or
      -- unrelated item use. The battle's evolvable flags and Rare Candy path
      -- already restrict ordinary checks to monsters that gained a level.
      if ctx.link then return false, 'not a level-up' end
      if ctx.force then return false, 'item use' end
      if not mon or mon.item == 'EVERSTONE' then return false, 'everstone' end
      local level = mon.level or 1
      if entry.item then
        if mon.item ~= entry.item then return false, 'wrong item' end
        if level < threshold('item_level', 1) then return false, 'level' end
        -- Retain EVOLVE_TRADE and its required item on the original row:
        -- Evolution.apply consumes it only after a successful animation.
        return true, nil, true
      end
      if level < threshold('trade_level', 37) then return false, 'level' end
      return true
    end,
  })

  mod.hooks:wrap('evolution.check', function(next_, data, mon, entry, ctx)
    ctx = ctx or {}
    -- Slowpoke's LEVEL row precedes its trade-item row in the ROM. Holding
    -- King's Rock explicitly selects Slowking, including above level 37;
    -- otherwise the vanilla scan would evolve it into Slowbro first. Apply
    -- this to any matching held-item trade branch rather than hardcoding
    -- species or replacing the species' complete evolution list.
    if mon and mon.item and entry.method ~= 'EVOLVE_TRADE'
        and not ctx.link and not ctx.force then
      local def = data and data.pokemon and data.pokemon[mon.species]
      for _, candidate in ipairs((def and def.evolutions) or {}) do
        if candidate.method == 'EVOLVE_TRADE' and candidate.item
            and candidate.item == mon.item then
          return false
        end
      end
    end
    return next_(data, mon, entry, ctx)
  end)
end
