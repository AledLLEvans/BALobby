Replay = {}

local spring = require "spring"

local lg = love.graphics
local lfs = love.filesystem
local ld = love.data
  
local replayMirror = "http://replays.springfightclub.com/"

local nfs = require "lib/nativefs"

local initialized = false

local display = false

function Replay.enter()
  if not initialized then Replay.initialize() end
  if display then return Replay.exit() end --Map.exit() end
  lobby.scrollBars[lobby.battlelist.scrollbar] = false
  lobby.scrollBars[Replay.scrollbar] = true
  lobby.events[Replay] = true
  lobby.clickables[Replay] = true
  canvas:clean()
  canvas:push(Replay.canvas)
  canvas:push(lobby.canvas.background)
  canvas:push(lobby.canvas.foreground)
  canvas:push(lobby.canvas.userlist)
  display = true
  lobby.state = "replays"
  --Replay.fetchLocalReplays()
end

function Replay.exit()
  display = false
  lobby.scrollBars[lobby.battlelist.scrollbar] = true
  lobby.scrollBars[Replay.scrollbar] = nil
  lobby.events[Replay] = nil
  lobby.clickables[Replay] = nil
  canvas:clean()
  canvas:push(lobby.canvas.battlelist)
  canvas:push(lobby.canvas.background)
  canvas:push(lobby.canvas.foreground)
  canvas:push(lobby.canvas.userlist)
end

local canvas
local xmin
local ymin
local xmax
local ymax
local padding = 2
local h = 20
function Replay.initialize()
  initialized = true
  love.thread.newThread("thread/replays.lua"):start(lobby.replayFolder)
  xmin = 20
  ymin = 42 + padding
  xmax = lobby.fixturePoint[2].x
  ymax = lobby.fixturePoint[2].y
  Replay.scrollbar = ScrollBar:new()
  :setPosition(xmax - 5, ymin + 10)
  :setLength(ymax - ymin - 20)
  :setScrollBarLength(20)
  :setScrollSpeed(12)
  :setRenderFunction(function() Replay.render() end)
  Replay.scrollbar:getZone()
  :setPosition(xmin, ymin)
  :setDimensions(xmax-xmin, ymax-ymin)
  Replay.canvas = lg.newCanvas(lobby.width, lobby.height)
end

Replay.s = {}
local channel = love.thread.getChannel("replays")
function Replay:update()
  local data = channel:pop()
  while data do
    table.insert(Replay.s, data)
    data = channel:pop()
    Replay.render()
    Replay.scrollbar:setOffsetMax((h+padding+1)*(#Replay.s+2))
  end
end

function Replay:click(msx, msy)
  local w = xmax - xmin - 20
  local i = #Replay.s
  local y = ymin - Replay.scrollbar:getOffset()
  local x = xmin

  while i > 0 do
    y = y + (h+2*padding)
    if y > ymin - h then
      if msx > x and msx < x + w and msy > y and msy < y + h then
        spring.launch("\"" .. lobby.exeFilePath .. " " .. Replay.s[i][5] .. "\"")
        return true
      end
    end
    i = i - 1
  end
  return false
end

function Replay.render()
  lg.setCanvas(Replay.canvas)
  lg.clear()
  
  lg.setFont(fonts.robotosmall)
  lg.setColor(colors.text)
  
  local w = xmax - xmin - 20
  local i = #Replay.s
  local y = ymin - Replay.scrollbar:getOffset()
  local x = xmin
  
  lg.print("Showing " .. #Replay.s .. " Replays", lobby.fixturePoint[2].x/2, 42)
    
  lg.print("Date & Time", x, y) --dateandtime
  lg.print("Map", x + 125, y) -- map
  --lg.print("engine", x + 390, y) --engine vers
  --lg.print("Players", x + 310, y) --numteams
  --lg.print("Spectators", x + 360, y) --numplayers
  
  while i > 0 do
    y = y + (h+2*padding)
    if y > ymin - h then
      lg.print(#Replay.s - i + 1, padding, y)
      lg.rectangle("line", x, y, w, h)
      lg.print(Replay.s[i][3], x + 2, y) --dateandtime
      lg.print(Replay.s[i][4], x + 125, y) -- map
      --lg.print(Replay.s[i][5], x + 390, y) --engine vers
      --lg.print(Replay.s[i][1][12].val, x + 310, y) --numteams
      lg.print(Replay.s[i][1][7].val, x + 300, y) 
      lg.print(Replay.s[i][1][8].val, x + 360, y) 
      --lg.print(Replay.s[i][1][9].val - Replay.s[i][1][12].val, x + 360, y) --numplayers
    end
    i = i - 1
  end
  

  
  Replay.scrollbar:draw()
  
  lg.setCanvas()
end


function Replay.fetchLocalReplays()
  Replay.local_demos = {
    filename = {},
    date = {},
    time = {},
    mapName = {},
    version = {},
    ext = {}
  }
  for i, file in pairs(nfs.getDirectoryItems(lobby.replayFolder)) do
    if file:find("103.sdfz") then
      local date, time, map, version, ext = file:match("(%d+)_(%d+)_(.+)_(%d+).(.+)")
      table.insert(Replay.local_demos.filename, file)
      table.insert(Replay.local_demos.date, date)
      table.insert(Replay.local_demos.time, time)
      table.insert(Replay.local_demos.mapName, map)
      table.insert(Replay.local_demos.version, version)
      table.insert(Replay.local_demos.ext, ext)
    end
  end
  print("local replays:", #Replay.local_demos.date)
  Replay.initialize()
end

--[[function Replay.initialize()
  ReplayTab:clean()
  local i = #Replay.local_demos.date
  local ymin = 40
  local ymax = lobby.fixturePoint[1].y - 35
  local y = ymin
  while y < ymax do
    ReplayTab:new(i,
    Replay.local_demos.filename[i],
    Replay.local_demos.date[i],
    Replay.local_demos.time[i],
    Replay.local_demos.mapName[i],
    Replay.local_demos.version[i])
    i = i - 1
    y = y + 35
  end
  Replay.refresh()
end]]

function Replay.refresh()
  local i = #Replay.local_demos.date
  local y = 40
  local x = 0
  local xmin = 0
  local ymin = - 10
  local ymax = lobby.fixturePoint[1].y
  local xmax = lobby.fixturePoint[2].x - 60
  local cols = math.floor((xmax - xmin) / 540)
  local w = (xmax - xmin) / cols
  local c = 1
  while y < ymax and ReplayTab.s[i] do
    ReplayTab.s[i]:setDimensions(w - 16, 25):setPosition(x+8, y+5)
    i = i - 1
    x = x + w
    c = c + 1
    if c > cols then
      c = 1
      x = xmin
      y = y + 35
    end
  end
end

function Replay.fetchOnlineReplays()
  Replay.uploaded_list = {
    link = {},
    name = {},
    map = {}
  }
  local http = require "socket.http"

  local data, err = http.request(replayMirror)
  
  print("fetchReplayList", err)
  
  for line in data:gmatch("[^\n]+") do
    local link, name = line:match("alt=\"%[   %]\"> <a href=\"(.+)\">(.+)</a>")
    if link and name then
      table.insert(Replay.uploaded_list.link, link)
      table.insert(Replay.uploaded_list.name, name)
      if map then
        table.insert(Replay.uploaded_list.map, map)
      else
        table.insert(Replay.uploaded_list.map, false)
      end
    end
  end
  print("replays:", #Replay.uploaded_list.link)
  Replay.init()
end

--[[function Replay.init()
  lobby.replayTabs = {}
  local i = 1
  local y = 90
  local x = 0
  local xmin = 0
  local ymin = - 10
  local ymax = lobby.fixturePoint[1].y
  local xmax = lobby.fixturePoint[2].x
  local cols = math.floor((xmax - xmin) / 610)
  local w = (xmax - xmin) / cols
  local c = 1
  while y < ymax do
    
  --lobby.replayTabs[ReplayTab:new(Replay.uploaded_list.link[i], Replay.uploaded_list.name[i], Replay.uploaded_list.map[i])
    ReplayTab:new(Replay.uploaded_list.name[i], Replay.uploaded_list.map[i])
    :setDimensions(w - 16, 100)
    :setPosition(x+8, y+5)
    i = i + 1
    x = x + w
    c = c + 1
    if c > cols then
      c = 1
      x = xmin
      y = y + 110
    end
   end
end]]

local month = {
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
}

local launchCode = [[
  local exec = ...
  io.popen(exec)
  love.window.restore( )
]]

local function launchReplay(filename)
  --new:startDownload()
  local exec = "\"" .. lobby.exeFilePath .. " " .. lobby.replayFolder .. filename .. "\""
  print(exec)
  if not lobby.springThread then
    lobby.springThread = love.thread.newThread( launchCode )
  end
  love.window.minimize( )
  lobby.springThread:start( exec )
end

--[[ReplayTab = Button:new()
ReplayTab.mt = {__index = ReplayTab}
ReplayTab.s = {}
function ReplayTab:new(id, filename, date, time, mapName, eversion)
  local new = Button:new()
  setmetatable(new, ReplayTab.mt)
  
  new.colors = {
    background = {
      default = colors.bb,
      highlight = colors.bd
    }   
  }

  new.id = id

  new.filename = filename
  
  new.date = date
  new.time = time
  new.mapName = mapName
  new.eversion = eversion
  
  new.year = date:match("(%d%d%d%d)%d%d%d%d")
  new.month = date:match("%d%d%d%d(%d%d)%d%d")
  new.day = date:match("%d%d%d%d%d%d(%d%d)")
  
  new.dateStr = new.day .. " " .. month[tonumber(new.month)] .. ", " .. new.year
  
  new:parse(lobby.replayFolder .. filename)
  
  new.highlighted = false
  
  new.func = launchReplay
 
  self.s[id] = new
  lobby.clickables[new] = true
  return new
end]]

--[[function ReplayTab:clean()
  for id, rt in pairs(self.s) do
    lobby.clickables[rt] = nil
    self.s[id] = nil
  end
end

function ReplayTab:isOver(x,y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    lobby.ReplayTabHover = self
    lobby.ReplayTabHoverTimer = 0.5
    self.highlighted = true
    return true
  end
  self.highlighted = false
  return false
end

function ReplayTab:draw()
  local y = self.y
  local x = self.x
  local w = self.w
  local h = self.h
  lg.setFont(fonts.latosmall) 
  local fontHeight = fonts.latosmall:getHeight()
  if self.highlighted then
    lg.setColor(self.colors.background.highlight)
  else
    lg.setColor(self.colors.background.default) 
  end
  lg.rectangle("fill", x, y, w, h)
  
  -- BATTLE TITLE
  lg.setColor(colors.text)
  local str = self.mapName
  if fonts.latosmall:getWidth(str) > 100 then
    str = self.mapName
    while fonts.latosmall:getWidth(str .. "..") > 100 do
      str = str:sub(0, #str - 1)
    end
    str = str .. ".."
  end
  lg.printf(str, x + h + 10, y+5, w, "left")
  local numallyteams = tonumber(self.script["game"].numallyteams)
  local mo_ffa = tonumber(self.script["modoptions"].mo_ffa)
  if self.script then
    local str = "Duel"
    if numallyteams and numallyteams > 2 then
      if mo_ffa and mo_ffa == 1 then
        str = "FFA"
      else
        str = "Teamfight"
      end
    end
    lg.printf(str, x + h + 150, y+5, w, "left")
  end
  if self.header then
    lg.printf(self.header[12], x + h + 10, y+5, w-80, "right")
  end
  lg.printf(self.dateStr, x + h + 10, y+5, w-40, "right")
  
  --for i, k in pairs(self.header) do
    --lg.printf(k.name, x + h + 190, y + 15 * i, w, "left")
   -- lg.printf((k.val) or "nil", x + h + 350, y + 15 * i, w, "left")
  --end
  
  -- IMAGES
  lg.setColor(colors.bd)
  lg.rectangle("fill", x, y, h, h)
  lg.setFont(fonts.latosmall)
  lg.setColor(1,1,1)
  if self.minimap then
    local modx = math.min(1, self.mapWidthHeightRatio)
    local mody = math.min(1, 1/self.mapWidthHeightRatio)
    lg.draw(self.minimap, x - (modx-1)*h/2, y - (mody-1)*h/2, 0,modx*h/(1024), mody*h/(1024))
  else
    lg.draw(img["nomap"], x, y, 0, 1/2, 1/2)
  end 
end

function ReplayTab:startDownload()
  if self.download then return end
  self.download = Download:new()
  self.download:push(replayMirror .. self.link, self.title, love.filesystem.getSaveDirectory() .. "/replays")
end

function ReplayTab:updateDownload(dt)
  local progress_update = self.progress_channel:pop()
  while progress_update do
    if progress_update.finished then
      
    end
    if progress_update.file_size then
      
      login.dl_status.file_size = progress_update.file_size
      
    end
    if progress_update.chunk then
      
      login.dl_status.downloaded = login.dl_status.downloaded + progress_update.chunk
      
    end
    if progress_update.error then
      
      login.dl_status.err = progress_update.error
      
    end
    progress_update = progress_channel:pop()
  end
end

function ReplayTab:getMinimap(mapName)
  if not minimaps[mapName] then
    local minimap, width, height = spring.getMinimap(mapName)
    if not minimap then return false end
    minimaps[mapName] = minimap
    widths[mapName] = width
    heights[mapName] = height
  end
  return minimaps[mapName]
end]]
