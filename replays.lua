Replay = {}

local lg = love.graphics
local lfs = love.filesystem
local ld = love.data
  
local replayMirror = "http://replays.springfightclub.com/"

local nfs = require "lib/nativefs"

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

function Replay.initialize()
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
end

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

ReplayTab = Button:new()
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
  
  new.func = function()
    --new:startDownload()
    local exec = "\"" .. lobby.exeFilePath .. " " .. lobby.replayFolder .. filename .. "\""
    print(exec)
    if not lobby.springThread then
      lobby.springThread = love.thread.newThread( launchCode )
    end
    love.window.minimize( )
    lobby.springThread:start( exec )
  end
 
  self.s[id] = new
  lobby.clickables[new] = true
  return new
end


function ReplayTab:parse(path)
  local info = nfs.getInfo(path)
  local gzip, size = nfs.read(path)
  if size == 0 then self.empty = true return end
  local decomp = ld.decompress( "string", "gzip", gzip )
    
  --[[if not info then return end
  if not ((info.type == "file") and (info.size > 0)) then return end
  local fd = nfs.newFileData(path)]]
  
  local magic,
  version,
  headerSize,
  versionString,
  gameID,
  unixTime,
  scriptSize,
  demoStreamSize,
  gameTime,
  wallclockTime,
  numPlayers,
  playerStatSize,
  playerStatElemSize,
  numTeams,
  teamStatSize,
  teamStatElemSize,
  teamStatPeriod,
  winningAllyTeamsSize,
  _ =
  love.data.unpack("c16 i i c256 c16 c8 i i i i i i i i i i i", decomp)
  local scriptStr = love.data.unpack("c" .. scriptSize, decomp, headerSize)
  --local stats = love.data.unpack("c" .. playerStatSize, decomp, headerSize + scriptSize + demoStreamSize)
  --local demo = love.data.unpack("c" .. demoStreamSize, decomp, headerSize + scriptSize)
  local script = {["game"] = {}}
  --local open = false
  local tbl
  for line in string.gmatch(scriptStr,'[^\r\n]+') do
    local key = line:match("^%[(.+)%]$")
    if key then
      script[key] = {}
      tbl = script[key]
    end
    if line:find('}') then
      tbl = script["game"]
    end
    local k, v = line:match("(.+)=(.+);")
    print(key,k,v)
    if tbl and k and v then
      tbl[k] = v
    end
  end
  
  self.script = script
  
  local mapName = self.script["game"].mapname
  print(mapName)
  if mapName then
    self:getMinimap(mapName)
  end
  
  self.header = {
    {name = "magic", val = magic},
    {name = "version", val = version},
    {name = "headerSize", val = headerSize},
    {name = "versionString", val = versionString},
    --{name = "gameID", val = gameID},
    --{name = "unixTime", val = unixTime},
    {name = "scriptSize", val = scriptSize},
    {name = "demoStreamSize", val = demoStreamSize},
    {name = "gameTime", val = gameTime},
    {name = "wallclockTime", val = wallclockTime},
    {name = "numPlayers", val = numPlayers},
    {name = "playerStatSize", val = playerStatSize},
    {name = "playerStatElemSize", val = playerStatElemSize},
    {name = "numTeams", val = numTeams},
    {name = "teamStatSize", val = teamStatSize},
    {name = "teamStatElemSize", val = teamStatElemSize},
    {name = "teamStatPeriod", val = teamStatPeriod},
    {name = "winningAllyTeamsSize", val = winningAllyTeamsSize}
  }
--[[    ["magic"] = magic,
    ["version"] = version,
    ["headerSize"] = headerSize,
    ["versionString"] = versionString,
    ["gameID"] = gameID,
    ["unixTime"] = unixTime,
    ["scriptSize"] = scriptSize,
    ["demoStreamSize"] = demoStreamSize,
    ["gameTime"] = gameTime,
    ["wallclockTime"] = wallclockTime,
    ["numPlayers"] = numPlayers,
    ["playerStatSize"] = playerStatSize,
    ["playerStatElemSize"] = playerStatElemSize,
    ["numTeams"] = numTeams,
    ["teamStatSize"] = teamStatSize,
    ["teamStatElemSize"] = teamStatElemSize,
    ["teamStatPeriod"] = teamStatPeriod,
    ["winningAllyTeamsSize"] = winningAllyTeamsSize
  }]]

  --[[print("magic", magic)
  print("version", version)
  print("headerSize", headerSize)
  print("versionString", versionString)
  print("gameID", gameID)
  print("unixTime", unixTime)  
  print("scriptSize", scriptSize)
  print("demoStreamSize", demoStreamSize)
  print("gameTime", gameTime)
  print("wallclockTime", wallclockTime)
  print("numPlayers", numPlayers)
  print("playerStatSize", playerStatSize)
  print("playerStatElemSize", playerStatElemSize)
  print("numTeams", numTeams)
  print("teamStatSize", teamStatSize)
  print("teamStatElemSize", teamStatElemSize)
  print("teamStatPeriod", teamStatPeriod)
  print("winningAllyTeamsSize", winningAllyTeamsSize)]]

end

function ReplayTab:clean()
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
  if self.script then
    local str = "Duel"
    if self.script["game"].numallyteams then
      if tonumber(self.script["game"].numallyteams) > 2 then
        if self.script["modoptions"].mo_ffa then
          str = "FFA"
        else
          str = "Teamfight"
        end
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

local function hasMap(mapName)
  for i, k in pairs(nfs.getDirectoryItems(lobby.mapFolder)) do
    if k == mapName .. ".sdz" or k == mapName .. ".sd7" then return k end
  end
  return false
end

local function getSMF(dir)
  for i, k in pairs(lfs.getDirectoryItems( dir )) do
    local path = dir .. "/" .. k
    if lfs.getInfo(path).type == "directory" then
      local smf = getSMF(path)
      if smf then return smf end
    elseif string.find(k, ".smf") then
      return path
    end
  end
  return false
end

function ReplayTab:getMinimap(mapName)
  mapName = string.gsub(mapName:lower(), " ", "_")
  local mapArchive = hasMap(mapName)
  if not mapArchive or not nfs.mount(lobby.mapFolder .. mapArchive, "map") then self.minimap = nil self.metalmap = nil return end
  local mapData = lfs.read(getSMF("map"))
  if not mapData then self.minimap = nil self.metalmap = nil return end
  nfs.unmount(lobby.mapFolder .. mapArchive, "map")
  
  local  _, _, _, mapWidth, mapHeight, _, _, _, _, _, heightmapOffset, tm, ti, minimapOffset, metalmapOffset, _ = 
  love.data.unpack("c16 i4 I4 i4 i4 i4 i4 i4 f f i4 i4 i4 i4 i4 i4", mapData)

  self.mapW = mapWidth
  self.mapH = mapHeight
  self.mapWidthHeightRatio = mapWidth/mapHeight
  
  --Mini Map
  local minimapData = love.data.unpack("c699048", mapData, minimapOffset + 1)
  minimapData = Battle.DDSheader .. minimapData
  local bytedata = love.data.newByteData( minimapData )
  local compdata = love.image.newCompressedData(bytedata)
  self.minimap = lg.newImage(compdata)
end

  local header = {}
  header[1] = 'DDS ' -- magic... technically not part of the header
  header[2] = love.data.pack('string', 'I4', 124) -- headersize
  header[3] = love.data.pack('string', 'I4', 8+4096+4194304) --1+2+4+0x1000+0x20000) -- flags
  header[4] = love.data.pack('string', 'I4', 1024) -- height
  header[5] = love.data.pack('string', 'I4', 1024) -- width
  header[6] = love.data.pack('string', 'I4', 8*0x10000) -- pitch
  header[7] = love.data.pack('string', 'I4', 0) -- depth
  header[8] = love.data.pack('string', 'I4', 8) -- mipmapcount
  for i=1,11 do
    header[8+i] = love.data.pack('string', 'I4', 0) -- reserved
  end
  -- pixelformat here
  header[20] = love.data.pack('string', 'I4', 32) -- structure size
  header[21] = love.data.pack('string', 'I4', 4) -- flags
  header[22] = love.data.pack('string', 'c4', 'DXT1') -- format... technically DWORD but easier to convert from string
  header[23] = love.data.pack('string', 'I4', 0) -- bits in uncompressed, unused
  header[24] = love.data.pack('string', 'I4', 0) -- 4 masks, unused
  header[25] = love.data.pack('string', 'I4', 0) --
  header[26] = love.data.pack('string', 'I4', 0) --
  header[27] = love.data.pack('string', 'I4', 0) --
  -- pixelformat structure end
  header[28] = love.data.pack('string', 'I4', 0x401008) -- surface is texture
  header[29] = love.data.pack('string', 'I4', 0) -- 4 unused from here
  header[30] = love.data.pack('string', 'I4', 0) --
  header[31] = love.data.pack('string', 'I4', 0) --
  header[32] = love.data.pack('string', 'I4', 0) --
  Battle.DDSheader = table.concat(header)
