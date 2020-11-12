local Map = {}
local lg = love.graphics
local display = false
local spring = require "spring"
local nfs = require "lib/nativefs"
local lfs = love.filesystem

function Map.isOpen()
  return display
end

function Map.exit()
  display = false
  lobby.events[Map] = nil
  canvas:clean()
  canvas:push(Battle.canvas)
  canvas:push(lobby.canvas.background)
  canvas:push(lobby.canvas.userlist)
  canvas:push(lobby.canvas.foreground)
end

local initialized = false
function Map.enter()
  if not initialized then Map.initialize() end
  if display then return end --Map.exit() end
  lobby.userlist.bar:shut()
  lobby.events[Map] = true
  canvas:clean()
  canvas:push(Map.canvas)
  canvas:push(lobby.canvas.background)
  canvas:push(lobby.canvas.userlist)
  canvas:push(lobby.canvas.foreground)
  display = true
end

local minimaps = {}
local mapnames = {}
local widths = {}
local heights = {}
local channel = love.thread.getChannel("minimap")

local mapsizemin = 30
local mapsizemax = 180
local xminmin
local yminmin
local xmaxmax
local ymaxmax
local xmin
local ymin
local xmax
local ymax
local mapsize = 80
local padding = 5

function Map.initialize()
  --[[local i = 0
  all_map_names = {}
  for i, map_file in pairs(nfs.getDirectoryItems(lobby.mapFolder)) do
    i = i + 1
    local mapName, _ = map_file:match("(.+)%.(.+)")
    table.insert(all_map_names, mapName)
  end]]
  --Map.load_images()
  Map.map_count = 0
  Map.map_count_sqrt = 0
  initialized = true
  love.thread.newThread("thread/minimap.lua"):start(lobby.mapFolder)
  xmin = padding
  xminmin = xmin
  ymin = 42
  yminmin = ymin
  xmax = lobby.width
  xmaxmax = xmax
  ymax = lobby.fixturePoint[2].y
  ymaxmax = ymax
  Map.canvas = lg.newCanvas(lobby.width, lobby.height)
end

function Map:update()
  local data = channel:pop()
  while data do
    spring.parseMinimapInfo( data )
    local minimap, width, height = spring.getMinimapOnly( data )
    table.insert(minimaps, minimap)
    table.insert(mapnames, data)
    table.insert(widths, width)
    table.insert(heights, height)
    data = channel:pop()
    Map.map_count = Map.map_count + 1
    Map.map_count_sqrt = math.ceil(math.sqrt(Map.map_count))
    Map.render()
  end
end

local x_offset = 0
local y_offset = 0
local dragging = false
local dragged = false
Map.dragger = {}
function Map.dragger:start()
  dragging = true
end
function Map.dragger:stop(x, y, b)
  dragging = false
  if b == 2 then Map.exit() return true end
  if y > lobby.fixturePoint[2].y or y < 32 then return false end
  if not dragged then Map:click(x, y) end
  dragged = false
  return true
end
function Map.dragger:mousemoved(x, y, dx, dy)
  if not dragging then return end
  dragged = true
  xmin = math.min(xminmin, math.max( xmin + dx, xmaxmax-(mapsize+padding)*(Map.map_count_sqrt  ) ) )
  ymin = math.min(yminmin, math.max( ymin + dy, xmaxmax-(mapsize+padding)*(Map.map_count_sqrt+6) ) )
  Map.render()
end

function Map:wheelmoved(x, y)
  local msx, msy = love.mouse.getPosition()
  local xm = ( mapsize * msx ) / ( 2 * lobby.width )
  local ym = ( mapsize * msy ) / ( 2 * lobby.height )
  if not display then return end
  if y > 0 then
    mapsize = math.max(math.min(mapsizemax, mapsize + 5), mapsizemin)
    xmin = math.min(xminmin, math.max( xmin - xm, xmaxmax-(mapsize+padding)*(Map.map_count_sqrt  ) ) )
    ymin = math.min(yminmin, math.max( ymin - ym, xmaxmax-(mapsize+padding)*(Map.map_count_sqrt+6) ) )
  elseif y < 0 then
    mapsize = math.min(math.max(mapsizemin, mapsize - 5), mapsizemax)
    xmin = math.min(xminmin, math.max( xmin + xm, xmaxmax-(mapsize+padding)*(Map.map_count_sqrt  ) ) )
    ymin = math.min(yminmin, math.max( ymin + ym, xmaxmax-(mapsize+padding)*(Map.map_count_sqrt+6) ) )
  end
  --Map.load_images()
  Map.render()
end

--[[function Map.load_images()
  for k in pairs(MINIMAPS) do
    MINIMAPS[k] = nil
  end
  for i = 1, 12 do
    if lfs.getInfo( "mini/maps/" .. all_map_names[i] ) then
      MINIMAPS[i] = lg.newImage( "mini/maps/" .. all_map_names[i] )
    else
      MINIMAPS[i] = false
    end
    widths[i] = 1024
    heights[i] = 1024
  end
end]]

function Map.render()
  lg.setCanvas(Map.canvas)
  lg.clear()
  local x = xmin
  local y = ymin
  local c = 0
  for i = 1, Map.map_count do
    c = c + 1
    local modx = 1
    local mody = 1
    if widths[i] and heights[i] then
      modx = math.min(1, widths[i]/heights[i])
      mody = math.min(1, heights[i]/widths[i])
    end
    if y + y_offset >= ymin and y + y_offset < ymax and x + x_offset >= xmin and x + x_offset < xmax then
      if minimaps[i] then
        lg.draw(minimaps[i], x - (modx-1)*mapsize/2, y - (mody-1)*mapsize/2, 0,
          modx*mapsize/1024, mody*mapsize/1024)
      else
        lg.rectangle("fill", x - (modx-1)*mapsize/2, y - (mody-1)*mapsize/2, mapsize, mapsize)
      end
    end
    y = y + mapsize + padding
    if c > Map.map_count_sqrt then
      c = c - Map.map_count_sqrt
      x = x + mapsize + padding
      y = ymin
    end
  end
  lg.setCanvas()
end

function Map.resize()
  if not display then return end
  xmin = 0
  ymin = 42
  xmax = lobby.fixturePoint[2].x
  ymax = lobby.fixturePoint[2].y
  Map.render()
end

function Map:click()
  local msx, msy = love.mouse.getPosition()
  local x = xmin
  local y = ymin
  local c = 0
  for i = 1, Map.map_count do
    c = c + 1
    if msx > x and msy > y and msx < x + mapsize and msy < y + mapsize then
      local battle = Battle:getActive()
      if not battle then Map.exit() return end
      if battle.single then
        battle.mapName = mapnames[i]
        battle:getMinimap()
      elseif battle.founder.isBot then
        lobby.send("SAYBATTLE !cv map " .. mapnames[i])
      else -- hosting
        
      end
      Map.exit()
      return true
    end
    y = y + mapsize + padding
    if c > Map.map_count_sqrt then
      c = c - Map.map_count_sqrt
      x = x + mapsize + padding
      y = ymin
    end
  end
  return false
end

return Map