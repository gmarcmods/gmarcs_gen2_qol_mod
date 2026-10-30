-- Native Gold/Silver/Crystal bag enhancements. Item actions remain PackMenu's.
local Bag = require('src.inventory.Bag')
local Pack = require('src.ui.gen2.PackMenu')
local Version = require('src.core.GameVersion')
local Strings = require('src.core.Strings')
local Types = require('src.battle.TypeChart')
local CAP = 999
local function gen2() return Version.generation() == 2 end
local function busy(menu)
  return menu.tutorial or menu.submenu or menu.qtyState or menu.confirm
    or menu.message or menu.switching or menu.repeatSfx
end

-- Reuse the active edition's native pack art, pocket plaque and palettes.
local function drawArtwork(gfx,pocket,x,y,height)
  if not (gfx and gfx:available())then return false end
  local G=love.graphics
  G.push('all');G.translate(x,y)
  local def=gfx.gfx
  for ty=1,math.min(11,math.floor(height/8)-1) do for tx=0,4 do
    gfx:menuTile(def.backgroundTile or 0x24,tx,ty)
  end end
  local picture=gfx:image('pack')
  local first=def.pocketPicture and def.pocketPicture[pocket]
  if picture and first then
    local wide=def.packTilesWide or 5
    for i=0,wide*(def.packTilesHigh or 3)-1 do
      gfx:blit(picture,wide,first+i,i%wide,3+math.floor(i/wide))
    end
  end
  for index,id in ipairs(def.pocketOrder or{})do if id==pocket then
    for i,tile in ipairs((def.pocketName or{})[index]or{})do
      gfx:menuTile(tile,(i-1)%5,7+math.floor((i-1)/5))
    end
  end end
  G.pop()
  return true
end

return function(mod)
  mod.options:define({{key='fullscreen_menu',label='FULLSCREEN BAG MENUS',type='toggle',default=true}})
  local function fullscreenEnabled() return mod.options:get('fullscreen_menu') ~= false end
  -- Bag.capacity's built-in bagSize override only covers ITEM. Expand all
  -- native pockets at the shared admission point used by scripts, marts,
  -- held-item returns and PC withdrawals, without editing the save layout.
  local baseCapacity, baseAdd = Bag.capacity, Bag.add
  Bag.capacity = function(data, pocket)
    if gen2() then return CAP end
    return baseCapacity(data, pocket)
  end
  Bag.add = function(save, id, qty, data)
    if not gen2() or Bag.isBadge(id) then return baseAdd(save,id,qty,data) end
    if not save then return false end
    qty = qty == nil and 1 or qty
    if type(qty) ~= 'number' or qty < 1 or qty % 1 ~= 0 then return false end
    save.inventory = save.inventory or {}
    local old = tonumber(save.inventory[id]) or 0
    if old < 0 then old = 0 end
    local pocket = Bag.pocketOf(id,data)
    if old + qty > CAP or (old == 0 and Bag.slots(save,data,pocket) >= CAP) then return false end
    local order = Bag.order(save,data)
    save.inventory[id] = old + qty
    if old == 0 then order[#order+1] = id end
    return true
  end
  local function label(menu, english)
    return Strings(english,'useful_bag_gen2')
  end

  local function sortPocket(menu, mode)
    local function less(a,b)
      if mode == 'count' and a.count ~= b.count then return a.count > b.count end
      local an, bn = a.teaches or a.name, b.teaches or b.name
      if an ~= bn then return an < bn end
      return a.id < b.id
    end
    table.sort(menu.rows, less)
    -- Rewrite only this pocket's positions, retaining every other item and
    -- quantity. Native save order and PC/give choosers see the same order.
    local order = Bag.order(menu.save, menu.bagData)
    local n = 1
    for i,id in ipairs(order) do
      if menu:pocketOf(id) == menu:pocket().id then
        order[i] = menu.rows[n].id
        n = n + 1
      end
    end
    menu.index, menu.scroll = 1, 0
    menu:storeCursor()
  end

  local nativeNew = Pack.new
  Pack.new = function(game, opts)
    local menu = nativeNew(game, opts)
    if menu.tutorial then return menu end
    menu.usefulBag = true
    local nativeUpdate, nativeRebuild = menu.update, menu.rebuild
    local nativeWide, nativeDraw = menu.drawWidescreen, menu.draw
    -- Three digits need four glyphs including the quantity sign. The native
    -- two-digit fields otherwise overwrite their right-hand box borders.
    menu.drawQuantity = function(self)
      local Chrome=require('src.ui.gen2.Chrome')
      local digits=math.max(2,#tostring(self.qtyState.qty))
      local width=digits+3
      Chrome.box(20-width,9,width,3)
      Chrome.printThrough('×'..Chrome.number(self.qtyState.qty,digits,true),21-width,10,Chrome.DEFAULT_BOX_PALETTE)
    end
    menu.machineType = function(self,row)
      local id=row and self:moveOf(row.id)
      local def=id and self.game.data.moves[id]
      return def and def.type and Types.displayName(def.type,self.game.data)or nil
    end
    menu.machineStats = function(self,row)
      local id=row and self:moveOf(row.id)
      local def=id and self.game.data.moves[id]
      if not def then return nil end
      local power=tonumber(def.power)or 0
      local accuracy=tonumber(def.accuracy)
      if not accuracy and tonumber(def.accuracyRaw)then
        accuracy=math.floor(def.accuracyRaw*100/255+.5)
      end
      return {power=power>=2 and tostring(power)or '--',
        accuracy=accuracy and tostring(accuracy)or '--',pp=tostring(def.pp or 0)}
    end
    menu.machineStatsText = function(self,row)
      local info=self:machineStats(row)
      if not info then return nil end
      return label(self,'PWR')..info.power..' '..label(self,'ACC')..info.accuracy..' PP'..info.pp
    end
    local nativeDescription=menu.drawDescription
    menu.drawDescription = function(self,ty)
      if not self.message and not self.confirm and not self.usefulWideDescription then
        local stats=self:machineStatsText(self.rows[self.index])
        if stats then
          require('src.ui.gen2.Chrome').printThrough(stats,1,ty-1,
            require('src.ui.gen2.Chrome').DEFAULT_BOX_PALETTE)
        end
      end
      return nativeDescription(self,ty)
    end
    menu.drawList = function(self,listX,listY)
      local Chrome=require('src.ui.gen2.Chrome')
      local picked=not self.switching and (self.submenu or self.qtyState or self.confirm or self.message) and true or false
      for slot=1,5 do
        local index=self.scroll+slot
        local row=self.rows[index]
        local ty=listY+(slot-1)*2
        if row then
          if row.tmhmLabel then Chrome.printThrough(row.tmhmLabel,listX-3,ty,Chrome.DEFAULT_BOX_PALETTE)end
          if index==self.index then self:cursorAt(listX-1,ty,picked)
          elseif index==self.switching then self:cursorAt(listX-1,ty,true)end
          Chrome.printThrough((row.tmhmLabel and row.teaches)or row.name,listX,ty,Chrome.DEFAULT_BOX_PALETTE)
          local kind=self:machineType(row)
          if kind then Chrome.printThrough(kind,listX-3,ty+1,Chrome.DEFAULT_BOX_PALETTE)end
          if row.showCount then
            Chrome.printRightThrough('×'..Chrome.number(row.count,2),listX+12,ty+1,Chrome.DEFAULT_BOX_PALETTE)
          end
        elseif index==self:total()then
          if index==self.index then self:cursorAt(listX-1,ty,picked)end
          Chrome.printThrough(Strings('CANCEL'),listX,ty,Chrome.DEFAULT_BOX_PALETTE)
        end
      end
    end
    local modes = {}
    menu.usefulVisibleRows = 5
    menu.ensureVisible = function(self)
      local count = self.usefulVisibleRows
      if self.index <= self.scroll then self.scroll = self.index-1
      elseif self.index > self.scroll+count then self.scroll = self.index-count end
      self.scroll = math.max(0,math.min(self.scroll,math.max(0,self:total()-count)))
    end
    menu.rebuild = function(self)
      nativeRebuild(self)
      local mode = modes[self:pocket().id]
      if mode then
        local index, scroll = self.index, self.scroll
        sortPocket(self, mode)
        self.index, self.scroll = index, scroll
        self:ensureVisible()
      end
    end
    menu.update = function(self, dt)
      local input = self.game and self.game.input
      if not input then return nativeUpdate(self, dt) end
      if self.staleRows then self.staleRows=nil;self:rebuild() end
      if self.usefulSort then
        if input:wasPressed('up') or input:wasPressed('down') then
          self.usefulSort = self.usefulSort == 1 and 2 or 1
        elseif input:wasPressed('b') or input:wasPressed('start') then self.usefulSort = nil
        elseif input:wasPressed('a') then
          local mode = self.usefulSort == 1 and 'name' or 'count'
          modes[self:pocket().id] = mode
          sortPocket(self, mode)
          self.usefulSort = nil
        end
        return
      end
      if not busy(self) and input:wasPressed('start') then
        self.usefulSort = 1
        return
      end
      if input:wasPressed('select') and not busy(self) then modes[self:pocket().id] = nil end
      return nativeUpdate(self, dt)
    end
    local function drawSort(self)
      if not self.usefulSort then return end
      local Chrome = require('src.ui.gen2.Chrome')
      Chrome.box(0, 5, 20, 7)
      Chrome.printThrough(label(self,'SORT BY NAME'), 2, 7, Chrome.DEFAULT_BOX_PALETTE)
      Chrome.printThrough(label(self,'SORT BY COUNT'), 2, 9, Chrome.DEFAULT_BOX_PALETTE)
      Chrome.cursorThrough(1, self.usefulSort == 1 and 7 or 9, Chrome.DEFAULT_BOX_PALETTE)
    end
    menu.draw = function(self)
      -- Game2 paints the wide base, then draws the visible stack for dialogue
      -- overlays. Repainting this base in that second pass restores the old
      -- 160x144 pack on top of the fullscreen one.
      local stack=self.game and self.game.stack
      if self.usefulWideOverlay and stack and stack:top()~=self then return end
      nativeDraw(self);drawSort(self)
    end
    menu.drawWidescreen = function(self, w, h)
      self.usefulWideOverlay=false
      local G = love.graphics
      local Chrome = require('src.ui.gen2.Chrome')
      local _,_,availableW,availableH=Chrome.playfieldRect(w,h)
      if not fullscreenEnabled() or availableW<200 or availableH<180 then
        self.usefulVisibleRows=5;self:ensureVisible()
        nativeWide(self,w,h)
        if self.usefulSort then
          local scale=Chrome.fitScale(w,h)
          G.push('all');G.translate(Chrome.fitOrigin(w,h,scale));G.scale(scale,scale)
          drawSort(self);G.pop()
        end
        return
      end
      self.usefulWideOverlay=true
      local x,y,pw,ph=Chrome.playfieldRect(w,h)
      local scale=math.max(1,math.floor(math.min(pw/200,ph/180)))
      local vw,vh=math.floor(pw/scale),math.floor(ph/scale)
      G.push('all');G.translate(x,y);G.scale(scale,scale)
      Chrome.paletteFill(0,0,vw,vh)
      local function text(value,tx,ty) Chrome.printThrough(value,tx/8,ty/8,Chrome.DEFAULT_BOX_PALETTE) end
      local function rule(ty) G.setColor(.5,.5,.5,1);G.rectangle('fill',8,ty,vw-16,1) end
      local pocket=self:pocket()
      text(Strings(pocket.label),12,8)
      local slots=tostring(#self.rows)..' / '..CAP
      text(slots,vw-12-#slots*8,8)
      text(label(self,'LEFT/RIGHT')..'  '..self.pocketIndex..' / 4',12,24)
      rule(38)
      local hasArt=drawArtwork(self.gfx,pocket.id,8,38,vh-108)
      local itemX=hasArt and 64 or 24
      local Font=require('src.render.Font')
      local typeHeading=label(self,'TYPE')
      self.usefulVisibleRows=math.max(1,math.floor((vh-108)/18))
      self:ensureVisible()
      for slot=1,self.usefulVisibleRows do
        local index=self.scroll+slot
        if index<=self:total() then
          local row=self.rows[index]
          local ty=44+(slot-1)*18
          if index==self.index then Chrome.cursorThrough((itemX-16)/8,ty/8,Chrome.DEFAULT_BOX_PALETTE,false,self.submenu~=nil)
          elseif index==self.switching then Chrome.cursorThrough((itemX-16)/8,ty/8,Chrome.DEFAULT_BOX_PALETTE,false,true) end
          local label=row and (row.tmhmLabel and (row.name..' '..(row.teaches or '')) or row.name) or Strings('CANCEL')
          local right=row and row.showCount and ('x'..row.count) or ''
          local limit=vw-itemX-24-Font.width(right)
          -- Preserve complete UTF-8 glyphs when a portrait screen is narrow.
          if Font.width(label)>limit then
            local spans=Font.split(label)
            local n=math.max(0,math.floor(limit/8)-3)
            label=n>0 and label:sub(1,spans[math.min(n,#spans)].to)..'...' or ''
          end
          text(label,itemX,ty);text(right,vw-12-Font.width(right),ty)
          local kind=self:machineType(row)
          if kind then text(typeHeading..': '..kind,itemX,ty+8)end
        end
      end
      rule(vh-64)
      if not self.message and not self.confirm then
        local stats=self:machineStatsText(self.rows[self.index])
        if stats then text(stats,12,vh-59)end
      end
      self.usefulWideDescription=true
      G.push();G.translate(4,vh-40);self:drawDescription(0);G.pop()
      self.usefulWideDescription=nil
      rule(vh-15)
      text('START: '..label(self,'SORT'),12,vh-11)
      if self.submenu or self.qtyState or self.confirm or self.usefulSort then
        G.push();G.translate(math.floor((vw-160)/2),math.floor((vh-144)/2))
        self:drawOverlays();drawSort(self);G.pop()
      end
      G.pop()
    end
    return menu
  end
  mod.exports = {capacity=CAP,fullscreenEnabled=fullscreenEnabled,sortPocket=sortPocket,drawArtwork=drawArtwork}
end
