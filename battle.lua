Battle = {}
Battle.mt =  {__index = Battle}
local lg = love.graphics
local lfs = love.filesystem
local nfs = require("nativefs")

Battle.s = {}

function Battle:new(battle)
  setmetatable(battle, Battle.mt)
  battle.playersByTeam = {}
  self.s[battle.id] = battle
end

function Battle:getChannel()
  return self.channel
end

function Battle:getActiveBattle()
  return self.active
end

function Battle:getPlayers()
  return self.players
end

function Battle:getUsers()
  return self.users
end

function Battle:setUp(x, y, w, h)
  self.channel:setUp(x, y, w, h)
end

local progress_channel = love.thread.getChannel("progress")
local requests_channel = love.thread.getChannel("requests")
function Battle:update(dt)
  local progress_update = progress_channel:pop()
  while progress_update do
    if progress_update.finished then
      self.dl_status.finished = true
      self.dl_status.downloading = false
      self:getMinimap()
      User.s[lobby.username].synced = true
      lobby.refreshBattleList()
    end
    if progress_update.file_size then
      self.dl_status.file_size = progress_update.file_size
    end
    if progress_update.chunk then
      self.dl_status.downloaded = self.dl_status.downloaded + progress_update.chunk
    end
    if progress_update.error then
      print(self.mirrors[self.mirrorID], self.dl_status.filename, progress_update.error)
      self.mirrorID = self.mirrorID + 1
      if self.mirrorID > #self.mirrors then
        self.dl_status = nil
        self.download_thread = nil
        return
      end
      self:pushDownloadRequest(self.mirrorID)
    end
    progress_update = progress_channel:pop()
  end
end

function Battle:draw()
  self.buttons.spectate:draw()
  self.buttons.ready:draw()
  lg.setFont(fonts.roboto)
  local fontHeight = fonts.roboto:getHeight()
  lg.print(self.title, lobby.fixturePoint[1].x + 10, 10)
  lg.printf(self.mapName, lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + fontHeight, 1024/8, "left")
  if self.minimap then
    lg.draw(self.minimap, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + fontHeight, 0, 1/8, 1/8)
  elseif self.dl_status and not self.dl_status.finished then
    lg.print(self.dl_status.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + fontHeight)
    lg.print(tostring(math.ceil(100*self.dl_status.downloaded/self.dl_status.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight)
  else
    lg.draw(img["nomap"], lobby.fixturePoint[2].x - 10 - 1024/8, 20 + fontHeight, 0, 1024/(8*50))
  end
  local y = 50 + self.userListScrollOffset
  fontHeight = fonts.robotosmall:getHeight()
  lg.setFont(fonts.robotosmall)
  lg.translate(lobby.fixturePoint[1].x + 25, 0 )
  local teamNo = 1
  for i, user in pairs(self.playersByTeam) do
    local username = user.name
    if user.allyTeamNo > teamNo then
      teamNo = user.teamNo
      y = y + fontHeight/2
    end
    if user.battleStatus then
      local indicator = user.ready and "indicator_green" or "indicator_red"
      lg.draw(img[indicator], -16, 43 + y, 0, 1/4)
      if user.icon then
        lg.draw(img[user.icon], 5, 40 + y, 0, 1/4)
      end
      lg.draw(user.flag, 23, 43 + y)
      lg.draw(user.insignia, 41, 40 + y, 0, 1/4)
      lg.setColor(0,0,0)
      lg.rectangle("line", 60, 40 + y, 120, fontHeight)
      lg.setColor(user.teamColorUnpacked[1]/255, user.teamColorUnpacked[2]/255, user.teamColorUnpacked[3]/255, 0.4)
      lg.rectangle("fill", 60, 40 + y, 120, fontHeight, 5, 5)
      lg.setColor(1,1,1)
      lg.print(username, 64, 40 + y)
      lg.print(user.allyTeamNo, 200, 40 + y)
      y = y + fontHeight
      if y > lobby.fixturePoint[1].y then
        lg.origin()
        return
      end
    end
  end
  y = math.max(8*fontHeight, y + fontHeight)
  lg.print("Spectators", 60, 40 + y)
  y = y + 3*fontHeight/2
  local specy = y
  for username, user in pairs(self.users) do
    if user.isSpectator and user.battleStatus then
      if user.icon then
        lg.draw(img[user.icon], 5, 40 + y, 0, 1/4)
      end
      lg.draw(user.flag, 23, 43 + y)
      lg.draw(user.insignia, 41, 40 + y, 0, 1/4)
      local w = fonts.robotosmall:getWidth(username)
      lg.print(username, 60, 40 + y)
      y = y + fontHeight
      if y > lobby.fixturePoint[1].y then
        lg.translate(120, 0)
        y = specy
        if lg.inverseTransformPoint( 120, 0 ) > lobby.fixturePoint[2].x - lobby.fixturePoint[1].x then
          lg.origin()
          return
        end
      end
    end
  end
  lg.origin()
end

local function hasMap(map)
  map = string.gsub(map, "%-", "%%%-")
  for i, k in pairs(nfs.getDirectoryItems(lobby.mapFolder)) do
    if string.find(k, map) then return k end
  end
  return false
end

function Battle:mapHandler()
  local mapName = string.gsub(self.mapName:lower(), " ", "_")
  if hasMap(mapName) then 
    lobby.setSynced(true)
    return
  end
  if self.dl_status then return end
  self.mirrors = {}
  self.mirrors[1] = "https://api.springfiles.com/files/maps/" .. mapName .. ".sd7"
  self.mirrors[2] = "https://api.springfiles.com/files/maps/" .. mapName .. ".sdz"
  self.mirrors[3] = "https://springfightclub.com/data/maps/" .. mapName .. ".sd7"
  self.mirrors[4] = "https://springfightclub.com/data/maps/" .. mapName .. ".sdz"
  self.mirrorID = 1
  self.download_thread = love.thread.newThread("downloader.lua")
  self.download_thread:start()
  self:pushDownloadRequest(self.mirrorID)
end

function Battle:pushDownloadRequest(mirror)
  self.dl_status = {
    downloading = true,
    finished = false,
    downloaded = 0,
    file_size = 0,
    filename = string.match(self.mirrors[mirror], ".*/(.*)")
  }
  return requests_channel:push({
    url = self.mirrors[mirror],
    filename = self.dl_status.filename,
    filepath = lobby.mapFolder
  })
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

function Battle:getMinimap()
  local mapName = string.gsub(self.mapName:lower(), " ", "_")
  local mapArchive = hasMap(mapName)
  if not mapArchive or not nfs.mount(lobby.mapFolder .. mapArchive, "map") then self.minimap = nil return end
  local mapData = lfs.read(getSMF("map"))
  if not mapData then self.minimap = nil return end
  nfs.unmount(lobby.mapFolder .. mapArchive, "map")
  
  local v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,mapOffset,i = love.data.unpack("c16i4I4i4i4i4i4i4ffi4i4i4i4", mapData)

  local minimapData = love.data.unpack("c699048", mapData, mapOffset + 1)
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