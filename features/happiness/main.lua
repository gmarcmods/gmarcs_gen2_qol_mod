return function(mod)
  -- Reading the public registry also works on older apps where requiring
  -- Strings was still classified as an engine-internals permission.
  local function text(source)
    local value=mod.content.strings:get('HAPPINESS_GEN2|'..source)
      or mod.content.strings:get(source)
    return type(value)=='string' and value or source
  end
  mod.hooks:wrap('ui.pc.items', function(next, game, entries)
    entries = next(game, entries)
    if type(entries) ~= 'table' then return entries end
    -- ItemPcMenu shares this hook but does not dispatch custom onSelect rows.
    local storage = false
    for _, entry in ipairs(entries) do
      if entry.id == 'happiness_gen2' then return entries end
      if entry.id == 'changebox' then storage = true end
    end
    if not storage then return entries end
    entries[#entries + 1] = {
      id = 'happiness_gen2',
      label = text('HAPPINESS'),
      onSelect = function(menu, activeGame)
        local save = menu.save or activeGame.save
        local mon = save and save.party and save.party[1]
        local message
        if not mon then
          message = text('No POKéMON in\nyour party.')
        elseif mon.isEgg then
          message = text('An EGG has no\nhappiness.')
        else
          mon.happiness = 255
          message = text('First POKéMON:\nmaximum happiness!')
        end
        menu:notice({message})
      end,
    }
    return entries
  end)
end
