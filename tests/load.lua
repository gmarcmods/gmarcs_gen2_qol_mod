-- Loads the assembled pack against the real engine modules and checks that
-- every feature installs through the proxy.  Run it from an engine checkout
-- that has this pack inside its mods directory:
--   luajit mods/gmarcs_gen2_qol_mod/tests/load.lua

package.path = './?.lua;./?/init.lua;' .. package.path
love = require('tests.love_stub')
require('src.core.GameVersion').set('gold')

-- Resolve the pack from this file's own path, so any checkout location works.
local script = (arg and arg[0]) or ''
local root = script:match('^(.*)/tests/[^/]+$')
assert(root and root ~= '', 'run this test from the pack directory')
local optionKeys, hookNames, warnings, errors = {}, {}, {}, {}

local function readFile(path)
  local handle = assert(io.open(path, 'rb'), 'cannot read ' .. path)
  local text = handle:read('*a')
  handle:close()
  return text
end

local mod = {
  id = 'gmarcs_gen2_qol_mod',
  path = root,
  exports = {},
  content = setmetatable({}, { __index = function(self, key)    local items = {}
    local registry = {}
    setmetatable(registry, { __index = function(t, method)
      local fn = function(_, id, value)
        if method == 'get' then return items[id] end
        if method == 'register' or method == 'override' or method == 'add' then
          items[id] = value
        end
        return true
      end
      t[method] = fn
      return fn
    end })
    self[key] = registry
    return registry
  end }),
  options = {
    define = function(_, schema)
      assert(type(schema) == 'table', 'schema must be a table')
      for _, row in ipairs(schema) do
        assert(type(row.key) == 'string' and row.key ~= '', 'row needs a key')
        optionKeys[#optionKeys + 1] = row.key
      end
    end,
    get = function() return nil end,
  },
  hooks = {
    wrap = function(_, name)
      assert(type(name) == 'string', 'hook name must be a string')
      hookNames[#hookNames + 1] = name
    end,
  },
  assets = setmetatable({
    path = function(_, relative) return root .. '/' .. relative end,
    list = function() return {} end,
    info = function() return nil end,
    image = function(_, relative) return { path = relative } end,
  }, { __index = function() return function() return true end end }),
  save = setmetatable({}, { __index = function(self, method)
    local store = {}
    local fn = function(_, key, value)
      if method == 'get' then return store[key] end
      store[key] = value
      return true
    end
    self[method] = fn
    return fn
  end }),
  events = setmetatable({}, { __index = function(self, method)
    local fn = function() return true end
    self[method] = fn
    return fn
  end }),
  log = {
    info = function() end,
    warn = function(_, fmt, ...) warnings[#warnings + 1] = fmt end,
    error = function(_, fmt, ...) errors[#errors + 1] = fmt end,
  },
}
function mod:read(relative)
  return readFile(self.path .. '/' .. relative)
end

local chunk = assert(loadfile(root .. '/main.lua'))
local install = chunk()
assert(type(install) == 'function', 'main.lua must return an install function')
install(mod)

-- Every feature reaches the merged exports table.
assert(type(mod.exports) == 'table', 'exports must stay a table')

-- Expectations come from the generated SOURCES.json, so adding or dropping a
-- feature never needs a matching edit here.
local sources = assert(io.open(root .. '/SOURCES.json')):read('*a')
local featureList = assert(sources:match('"features":%s*(.*)$'), 'SOURCES.json has no features')
local expected = {}
for name in featureList:gmatch('"name":%s*"([^"]+)"') do
  expected[#expected + 1] = name
end
assert(#expected > 0, 'SOURCES.json lists no features')
for _, name in ipairs(expected) do
  local handle = io.open(root .. '/features/' .. name .. '/main.lua', 'rb')
  assert(handle, 'feature directory missing: ' .. name)
  handle:close()
end

assert(#optionKeys > 0, 'no options were registered')
for _, key in ipairs(optionKeys) do
  local prefix = key:match('^([%w%-_]+)%.')
  assert(prefix, 'option key is not namespaced: ' .. key)
end

assert(#hookNames > 0, 'no hooks were registered')
assert(#errors == 0, 'features reported errors: ' .. table.concat(errors, ', '))

-- Options from different features never share a key.
local seen = {}
for _, key in ipairs(optionKeys) do
  assert(not seen[key], 'duplicate option key: ' .. key)
  seen[key] = true
end

-- Gen 3 Box carries the Gen 2 catch-overflow fix: with BOX 1-12 full a caught
-- mon must still land in 13, not report that every box is full.
local storage = require('src.pokemon.Boxes')
local save = { boxes = {}, currentBox = 1 }
for index = 1, 14 do save.boxes[index] = {} end
for index = 1, 12 do
  for slot = 1, 20 do save.boxes[index][slot] = { species = slot } end
end
assert(storage.deposit(save, { species = 25 }) == 13,
  'Gen 2 catch overflow must continue into box 13')

io.write(('features: %d, options: %d, hooks: %d, warnings: %d\n'):format(
  #expected, #optionKeys, #hookNames, #warnings))
io.write('hooks: ' .. table.concat(hookNames, ', ') .. '\n')
io.write('QoL product load PASS\n')
