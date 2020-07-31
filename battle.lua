Battle = {}
Battle.mt =  {__index = Battle}
local lg = love.graphics
local lfs = love.filesystem
local nfs = require("nativefs")

Battle.s = {}

Battle.count = 0


---- Courtesy of https://springrts.com/phpbb/viewtopic.php?t&t=32643 ----
local function writeScript()
  local battle = Battle:getActiveBattle()
  script = {
    --player0 = {name = lobby.username},
    --gametype = battle.gameName,
    HostIP = battle.ip,
    HostPort = battle.hostport or battle.port,
    --MapName = battle.mapName,
    MyPlayerName = lobby.username,
    IsHost=0,
    --SourcePort=0,
    MyPasswd=battle.myScriptPassword
  }
  
  local txt = io.open('script.txt', 'w+')

	txt:write('[GAME]\n{\n\n')
	-- First write Tables
	for key, value in pairs(script) do
		if type(value) == 'table' then
			txt:write('\t['..key..']\n\t{\n')
			for key, value in pairs(value) do
				txt:write('\t\t'..key..' = '..value..';\n')
			end
			txt:write('\t}\n\n')
		end
	end
	-- Then the rest (purely for aesthetics)
	for key, value in pairs(script) do
		if type(value) ~= 'table' then
			txt:write('\t'..key..' = '..value..';\n')
		end
	end
	txt:write('}')

	txt:close()
end

local launchCode = [[
  local exec = ...
  os.execute(exec)
  love.window.restore( )
]]

function Battle:joined(id)
  if self:mapHandler() and self:modHandler() then
    lobby.setSynced(true)
  end
  self.buttons = {
    ["exit"] = BattleButton:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 380, lobby.fixturePoint[2].y - 50 end)
    :setDimensions(90, 40)
    :setText("Exit")
    :onClick(function() Battle.exit() end),
    ["spectate"] = BattleButton:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 200, lobby.fixturePoint[2].y - 50 end)
    :setDimensions(90, 40)
    :setText("Spectate")
    :onClick(function() lobby.setSpectator(not User.s[lobby.username].spectator) end),
    ["ready"] = BattleButton:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 290, lobby.fixturePoint[2].y - 50 end)
    :setDimensions(90, 40)
    :setText("Ready")
    :onClick(function() if not User.s[lobby.username].spectator then lobby.setReady(not User.s[lobby.username].ready) end end),
    ["start"] = BattleButton:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 110, lobby.fixturePoint[2].y - 50 end)
    :setDimensions(90, 40)
    :setText("Start")
    :onClick(function()
                writeScript()
                local exec = "\"" .. lobby.exeFilePath .. "\"" .. " script.txt"
                if not lobby.springThread then
                  lobby.springThread = love.thread.newThread( launchCode )
                end
                love.window.minimize( )
                lobby.springThread:start( exec ) end)
  }
  Channel.active = Channel.s["Battle_" .. id]
  self.display = true
end

function Battle.exit()
  Channel.active = Channel.s[next(Channel.s, Battle:getActive():getChannel().title)]
  Battle:getActive().display = false
  Battle:getActive():getChannel().display = false
  lobby.send("LEAVEBATTLE" .. "\n")
  lobby.state = "landing"
  Battle.modoptionsScrollBar = nil
  lobby.clickables[Battle.sideButton] = nil
  Battle.sideButton = nil
  Battle.modoptionsScrollBar = nil
  lobby.resize(lobby.width, lobby.height)
end

function Battle.enter()
  lobby.state = "battle"
  lobby.fixturePoint[1].x = 0
  Battle.modoptionsScrollBar = ScrollBar:new()
  :setPosition(lobby.fixturePoint[2].x - 5, (lobby.height-lobby.fixturePoint[2].y)/2 - 20)
  :setLength(40)
  :setScrollBarLength(10)
  :setOffset(0)
  :setScrollSpeed(15)
  Battle.sideButton = Button:new():setPosition(1, lobby.height/2 - 20):setDimensions(20-2, 40):onClick(function() Battle.enterWithList() end)
  function Battle.sideButton:draw()
    lg.rectangle("line", self.x, self.y, self.w, self.h)
    lg.polygon("line",
              5, self.y + self.h/2 - 8,
              5, self.y + self.h/2 + 8,
              15, self.y + self.h/2)
  end
  lobby.clickables[Battle.sideButton] = true
  lobby.resize(lobby.width, lobby.height)
end

function Battle.enterWithList()
  lobby.state = "battleWithList"
  lobby.fixturePoint[1].x = 260
  Battle.sideButton = Button:new():setPosition(261, lobby.height/2 - 20):setDimensions(20-2, 40):onClick(function() Battle.enter() end)
  function Battle.sideButton:draw()
    lg.rectangle("line", self.x, self.y, self.w, self.h)
    lg.polygon("line",
              self.x + 15, self.y + self.h/2 - 8,
              self.x + 15, self.y + self.h/2 + 8,
              self.x + 5, self.y + self.h/2)
  end
  lobby.clickables[Battle.sideButton] = true
  lobby.resize(lobby.width, lobby.height)
end

function Battle:new(battle)
  setmetatable(battle, Battle.mt)
  
  battle.playersByTeam = {}
  
  battle.spectatorCount = 0
  battle.locked = false
  battle.users = {}
  battle.userCount = 0
  
  battle.noOfTeams = 0
  battle.userListScrollOffset = 0
  
  battle.game = {}
  battle.game.modoptions = {}
  
  self.s[battle.id] = battle
  self.count = self.count + 1
end

function Battle:getChannel()
  return self.channel
end

-- lol
function Battle:getActiveBattle()
  return self.active
end
function Battle:getActive()
  return self.active
end
function Battle.getActive()
  return Battle.active
end
--

function Battle:getPlayers()
  return self.players
end

function Battle:getUsers()
  return self.users
end

function lobby.setSynced(b)
  if User.s[lobby.username].syncStatus then return end
  User.s[lobby.username].synced = b
  lobby.sendMyBattleStatus()
end

function lobby.setSpectator(b)
  User.s[lobby.username].spectator = b
  User.s[lobby.username].ready = false
  lobby.sendMyBattleStatus()
end

function lobby.setReady(b)
  User.s[lobby.username].ready = b
  lobby.sendMyBattleStatus()
end

function lobby.setColor(r, g, b, a) --needs completing
  if type(r) == "table" then r = r[1] g = r[2] b = r[3] a = r[4] end
  --User.s[lobby.username].color = r * 255
  lobby.sendMyBattleStatus()
end

function lobby.sendMyBattleStatus()
  local user = User.s[lobby.username]
  --local status = user.battleStatus
  local b = {
    user.ready and 1 or 0,
    user.spectator and 0 or 1,
    user.synced and 1 or 0
  }
  local newstatus = b[1] * 2 + b[2] * 2 ^ 10 + 2 ^ (23 - b[3])
  local color = user.color
  lobby.send("MYBATTLESTATUS " .. newstatus .. " " .. color .. "\n")
end

function Battle:update(dt)
  --Mod
  if self.modDownload then
    self.modDownload:update(dt)
    if self.modDownload.finished then
      if (not self.mapDownload) or self.mapDownload.finished then lobby.setSynced(true) end
      self.modDownload.thread:release()
      self.modDownload = nil
      return
    end
    if self.modDownload.error then
      self.modMirrorID = self.modMirrorID + 1
      if self.modMirrorID > #self.modMirrors then
        love.window.showMessageBox("Error auto-downloading game", "\n" .. self.modDownload.error .. "\nTry installing manually", "error" )
        self.modDownload:release()
        self.modDownload = nil
        return
      end
      local filename = string.match(self.modMirrors[self.modMirrorID], ".*/(.*)")
      self.modDownload:push(self.modMirrors[self.modMirrorID], filename, lobby.modFolder)
    end
  end
  --Map
  if self.mapDownload then
    self.mapDownload:update(dt)
    if self.mapDownload.finished then
      self:getMinimap()
      --self.mapDownload:release()
      self.mapDownload = nil
      if (not self.modDownload) or self.modDownload.finished then lobby.setSynced(true) end
      lobby.refreshBattleTabs()
      return
    end
    if self.mapDownload.error then
      self.mapMirrorID = self.mapMirrorID + 1
      if self.mapMirrorID > #self.mapMirrors then
        love.window.showMessageBox("Error auto-downloading map", "\nFailed to find URL\nTry installing manually", "error" )
        self.mapDownload:release()
        self.mapDownload = nil
        return
      end
      local filename = string.match(self.mapMirrors[self.mapMirrorID], ".*/(.*)")
      self.mapDownload:push(self.mapMirrors[self.mapMirrorID], filename, lobby.mapFolder)
    end
  end
end

local draw = {
  readyButton = {
    [true] = function(x, y) lg.setColor(colors.bargreen) lg.circle("fill", x, y, 5) end,
    [false] = function(x, y) lg.setColor(colors.orange) lg.circle("fill", x, y, 5) end
  },
  specButton = function(x, y) lg.setColor(colors.bt) lg.circle("fill", x, y, 4) end,
  backRect = {
    [true] = function(x, y, fH) lg.setColor(colors.bb) lg.rectangle("fill", x, y, 260, fH) return false end,
    [false] = function() return true end
  }
}

function Battle:draw()
  --Buttons
  self.buttons.exit:draw()
  self.buttons.spectate:draw()
  self.buttons.ready:draw()
  self.buttons.start:draw()
  
  --Room Name, Title
  lg.setFont(fonts.roboto)
  lg.setColor(colors.bargreen)
  local i = 0
  local text = self.title
  repeat
    text = text:sub(1, #text - i)
    local width = fonts.roboto:getWidth(text)
    i = i + 1
  until width < lobby.fixturePoint[2].x - 50 - lobby.fixturePoint[1].x or text == ""
  if i > 1 then text = text:sub(1, #text - 2) .. ".." end
  lg.print(text, lobby.fixturePoint[1].x + 50, 10)
  local fontHeight = fonts.roboto:getHeight()
  
  --Game Name, subtitle
  lg.setFont(fonts.latoitalic)
  lg.setColor(colors.bt)
  lg.print(self.gameName, lobby.fixturePoint[1].x + 50, 10 + fontHeight)
  
  --map name and image
  lg.setFont(fonts.robotoitalic)
  lg.setColor(1,1,1)
  lg.print(self.mapName, lobby.fixturePoint[2].x - 10 - fonts.robotoitalic:getWidth(self.mapName), 10 + fontHeight)
  if self.minimap then
    lg.draw(self.minimap, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight, 0, 1/8, 1/8)
  elseif self.mapDownload and not self.mapDownload.finished then
    lg.print(self.mapDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight)
    lg.print(tostring(math.ceil(100*self.mapDownload.downloaded/self.mapDownload.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 3*fontHeight)
  else
    lg.draw(img["nomap"], lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight, 0, 1024/(8*50))
  end
  
  --modoptions
  local x = lobby.fixturePoint[2].x - 170
  local ymin = 20 + 3*fontHeight + 1024/8
  local ymax = lobby.fixturePoint[2].y - fontHeight - 60
  local y = ymin - self.modoptionsScrollBar:getOffset()
  lg.setFont(fonts.latoitalic)
  fontHeight = fonts.latoitalic:getHeight()
  self.modoptionsScrollBar:getZone():setPosition(x, ymin)
  self.modoptionsScrollBar:setPosition(lobby.fixturePoint[2].x - 5, ymin + 10):setLength(ymax - ymin)
  lg.setColor(colors.bt)
  local c = 0
  local t = 0
  for k, v in pairs(self.game.modoptions) do
    if y < ymax and y >= ymin then
      lg.print(v, lobby.fixturePoint[2].x - fonts.latoitalic:getWidth(v) - 15, y)
      lg.print(k, x, y)
      c = c + 1
    end
    y = y + fontHeight
    t = t + 1
  end
  self.modoptionsScrollBar:getZone():setDimensions(170, ymax - ymin + fontHeight)
  self.modoptionsScrollBar:setOffsetMax(math.max(0, t - c) * fontHeight):draw()
  
  --[[if self.modDownload then
    lg.printf(self.modDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + 3*fontHeight, 1024/8, "left")
    lg.printf(tostring(math.ceil(100*self.modDownload.downloaded/self.modDownload.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + 4*fontHeight, 1024/8, "left")
  end]]
  
  --userlist
  y = 50 + self.userListScrollOffset
  fontHeight = fonts.latosmall:getHeight()
  lg.setFont(fonts.latosmall)
  lg.translate(lobby.fixturePoint[1].x + 25, 40 )
  local teamNo = 1
  local drawBackRect = false
  for i, user in pairs(self.playersByTeam) do
    local username = user.name
    if user.allyTeamNo > teamNo then
      teamNo = user.teamNo
      lg.setColor(colors.bt)
      lg.line(0, y + fontHeight/4, 240, y + fontHeight/4)
      y = y + fontHeight/2
    end
    if user.battleStatus then
      drawBackRect = draw.backRect[drawBackRect](0, y, fontHeight)
      draw.readyButton[user.ready](240, y + 7)
      lg.setColor(1,1,1)
      if user.icon then
        lg.draw(img[user.icon], 5, y, 0, 1/4)
      end
      lg.draw(user.flag, 23, 3 + y)
      lg.draw(user.insignia, 41, y, 0, 1/4)
      lg.setColor(0,0,0)
      lg.rectangle("line", 60, y, 120, fontHeight)
      lg.setColor(user.teamColorUnpacked[1]/255, user.teamColorUnpacked[2]/255, user.teamColorUnpacked[3]/255, 0.4)
      lg.rectangle("fill", 60, y, 120, fontHeight, 5, 5)
      lg.setColor(1,1,1)
      lg.print(username, 64, y)
      lg.print(user.allyTeamNo, 200, y)
      --lg.print(self.game.players[username]., 240, y)
      y = y + fontHeight
      if y > lobby.fixturePoint[1].y then
        lg.origin()
        return
      end
    end
  end
  --spectator list
  y = math.max(8*fontHeight, y + fontHeight)
  lg.print("Spectators", 60, y)
  y = y + 3*fontHeight/2
  local specy = y
  drawBackRect = true
  for username, user in pairs(self.users) do
    if user.isSpectator and user.battleStatus then
      drawBackRect = draw.backRect[drawBackRect](0, y, fontHeight)
      draw.specButton(241, 7 + y)
      lg.setColor(1,1,1)
      if user.icon then
        lg.draw(img[user.icon], 5, y, 0, 1/4)
      end
      lg.draw(user.flag, 23, 3 + y)
      lg.draw(user.insignia, 41, y, 0, 1/4)
      local w = fonts.latosmall:getWidth(username)
      lg.print(username, 60, y)
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
  Battle.sideButton:draw()
end

local function hasMap(mapName)
  for i, k in pairs(nfs.getDirectoryItems(lobby.mapFolder)) do
    if k == mapName .. ".sdz" or k == mapName .. ".sd7" then return k end
  end
  return false
end

local function hasMod(gameName)
  for i, k in pairs(nfs.getDirectoryItems(lobby.gameFolder)) do
    if k == gameName .. ".sdz" or k == gameName .. ".sd7" then return k end
  end
  return false
end

function Battle:downloadHandler()
  if self:mapHandler() and self:modHandler() then
    return true
  end
end

function Battle:modHandler()
  local gameName = string.gsub(self.gameName:lower(), " ", "_", 1)
  gameName = string.gsub(gameName, " ", "-", 1)
  gameName = string.gsub(gameName, " ", "_")
  if hasMod(gameName) then return true end
  self.modMirrors = {
    "https://www.springfightclub.com/data/" .. gameName .. ".sdz"
  }
  self.modMirrorID = 1
  self.modDownload = Download:new()
  local filename = string.match(self.modMirrors[self.modMirrorID], ".*/(.*)")
  self.modDownload:push(self.modMirrors[self.modMirrorID], filename, lobby.gameFolder)
  return false
end

function Battle:mapHandler()
  local mapName = string.gsub(self.mapName:lower(), " ", "_")
  if hasMap(mapName) then return true end
  self.mapMirrors = {
    "https://api.springfiles.com/files/maps/" .. mapName .. ".sd7",
    "https://api.springfiles.com/files/maps/" .. mapName .. ".sdz",
    "https://springfightclub.com/data/maps/" .. mapName .. ".sd7",
    "https://springfightclub.com/data/maps/" .. mapName .. ".sdz"
  }
  self.mapDownload = Download:new()
  self.mapMirrorID = 1
  local filename = string.match(self.mapMirrors[self.mapMirrorID], ".*/(.*)")
  self.mapDownload:push(self.mapMirrors[self.mapMirrorID], filename, lobby.mapFolder)
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