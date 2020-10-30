local Map = {}
local lg = love.graphics
local display = false
local minimaps = {}
local mapnames = {}
local widths = {}
local heights = {}
local spring = require "spring"

function Map.isOpen()
  return display
end

function Map.exit()
  display = false
  lobby.events[Map] = nil
  lobby.clickables[Map] = nil
  canvas:push(Battle.canvas)
  canvas:pop(Map.canvas)
end

local initialized = false
function Map.enter()
  if not initialized then Map.initialize() end
  if display then return end --Map.exit() end
  lobby.events[Map] = true
  lobby.clickables[Map] = true
  canvas:pop(Battle.canvas)
  canvas:push(Map.canvas)
  display = true
end

local channel = love.thread.getChannel("minimap")
function Map:update()
  local data = channel:pop()
  while data do
    table.insert(minimaps, love.graphics.newImage(data[1]))
    table.insert(mapnames, data[2])
    table.insert(widths, data[3])
    table.insert(heights, data[4])
    data = channel:pop()
    Map.render()
  end
end

local mapsizemin = 30
local mapsizemax = 180
local xmin
local ymin
local xmax
local ymax
local mapsize = 80
local padding = 5
function Map.initialize()
  initialized = true
  love.thread.newThread("thread/minimap.lua"):start(lobby.mapFolder)
  xmin = padding
  ymin = 42 + padding
  xmax = lobby.fixturePoint[2].x
  ymax = lobby.fixturePoint[2].y
  Map.canvas = lg.newCanvas(lobby.width, lobby.height)
end

local x_offset = 0
local y_offset = 0
function Map.render()
  lg.setCanvas(Map.canvas)
  lg.clear()
  local x = xmin
  local y = ymin
  for i = 1, #minimaps do
    local modx = math.min(1, widths[i]/heights[i])
    local mody = math.min(1, heights[i]/widths[i])
    lg.draw(minimaps[i], x - (modx-1)*mapsize/2, y - (mody-1)*mapsize/2, 0,
      modx*mapsize/1024, mody*mapsize/1024)
    y = y + mapsize + padding
    if y > ymax - mapsize - padding then
      x = x + mapsize + padding
      if x > xmax - mapsize - padding then
        lg.setCanvas()
        return
      end
      y = ymin
    end
  end
  lg.setCanvas()
end

--[[function Map.render()
  lg.setCanvas(Map.canvas)
  lg.clear()
  local x = xmin
  local y = ymin
  for i = 1, #minimaps do
    local modx = math.min(1, widths[i]/heights[i])
    local mody = math.min(1, heights[i]/widths[i])
    lg.draw(minimaps[i], x - (modx-1)*mapsize/2, y - (mody-1)*mapsize/2, 0,
      modx*mapsize/1024, mody*mapsize/1024)
    y = y + mapsize + padding
    if y > ymax - mapsize - padding then
      x = x + mapsize + padding
      if x > xmax - mapsize - padding then
        lg.setCanvas()
        return
      end
      y = ymin
    end
  end
  lg.setCanvas()
end]]

function Map.resize()
  xmin = 0
  ymin = 42
  xmax = lobby.fixturePoint[2].x
  ymax = lobby.fixturePoint[2].y
  Map.render()
end

function Map:click()
  local msx, msy = love.mouse.getPosition()
  local y = ymin
  local x = xmin
  for i = 1, #minimaps do
    if msx > x and msy > y and msx < x + mapsize + padding and msy < y + mapsize + padding then
      local battle = Battle:getActive()
      if not battle then Map.exit() return end
      if battle.single then
        battle.mapName = mapnames[i]
        battle:getMinimap()
      elseif battle.founder.isBot then
        lobby.send("SAYBATTLE !map " .. mapnames[i])
      else -- hosting
        
      end
      Map.exit()
      return
    end
    y = y + mapsize + padding
    if y > ymax - mapsize - padding then
      x = x + mapsize + padding
      if x > xmax - mapsize - padding then
        return
      end
      y = ymin
    end
  end
  return false
end

return Map