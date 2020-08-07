Battle = {}
Battle.mt =  {__index = Battle}
local lg = love.graphics
local lfs = love.filesystem
local nfs = require("nativefs")

Battle.s = {}

Battle.count = 0

function Battle:joined(id)
  if self:mapHandler() and self:modHandler() then
    lobby.setSynced(true)
  end
  self.buttons = {
    ["autolaunch"] = Checkbox:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 160, lobby.fixturePoint[2].y - 40 end)
    :setDimensions(20,20)
    :setText("Auto-launch")
    :setToggleVariable(function() return lobby.launchOnGameStart end)
    :onClick(function() lobby.launchOnGameStart = not lobby.launchOnGameStart end),
    ["exit"] = BattleButton:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 370, lobby.fixturePoint[2].y - 50 end)
    :setDimensions(40, 40)
    :setText("Exit")
    :onClick(function() Battle.exit() end),
    ["ready"] = Checkbox:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 230 , lobby.fixturePoint[2].y - 40 end)
    :setDimensions(20, 20)
    :setText("Ready")
    :setToggleVariable(function() return User.s[lobby.username].ready end)
    :onClick(function() if not User.s[lobby.username].spectator then lobby.setReady(not User.s[lobby.username].ready) end end),
    ["spectate"] = Checkbox:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 315, lobby.fixturePoint[2].y - 40 end)
    :setDimensions(20, 20)
    :setText("Spectate")
    :setToggleVariable(function() return User.s[lobby.username].spectator end)
    :onClick(function() lobby.setSpectator(not User.s[lobby.username].spectator) end),
    ["launch"] = BattleButton:new()
    :resetPosition(function() return lobby.fixturePoint[2].x - 55, lobby.fixturePoint[2].y - 50 end)
    :setDimensions(60, 40)
    :setText("Launch")
    :onClick(function()
      if Battle:getActive().founder.ingame then
        lobby.launchSpring()
      else
        love.window.showMessageBox("For your information", "Game has not yet started.", "info")
      end
    end)
  }
  
  Channel.active = Channel.s["Battle_" .. id]
  self.display = true
  
  self.showMapScroll = 1
  Battle.mapScrollBar = ScrollBar:new():setOffset(0)
  :setRenderFunction(function(y)
        if y > 0 then
          self.showMapScroll = math.min(2, self.showMapScroll + 1)
        elseif y < 0 then
          self.showMapScroll = math.max(0, self.showMapScroll - 1)
        end
      end)
  
  Battle.spectatorsScrollBar = ScrollBar:new()
  :setLength(40)
  :setScrollBarLength(10)
  :setOffset(0)
  :setScrollSpeed(fonts.latosmall:getHeight() + 2)
  
  Battle.modoptionsScrollBar = ScrollBar:new()
  :setPosition(lobby.fixturePoint[2].x - 5, (lobby.height-lobby.fixturePoint[2].y)/2 - 20)
  :setLength(40)
  :setScrollBarLength(10)
  :setOffset(0)
  :setScrollSpeed(fonts.latosmall:getHeight())
  
  Battle.showMap = "minimap"
  
  self:getChannel().infoBoxScrollBar:setOffset(0)
end

function Battle.exit()
  Channel.active = Channel.s[next(Channel.s, Battle:getActive():getChannel().title)]
  Battle:getActive().display = false
  Battle:getActive():getChannel().display = false
  lobby.send("LEAVEBATTLE" .. "\n")
  lobby.state = "landing"
  Battle.modoptionsScrollBar = nil
  --lobby.clickables[Battle.sideButton] = nil
  --Battle.sideButton = nil
  Battle.modoptionsScrollBar = nil
  Battle.spectatorsScrollBar = nil
  Battle.mapScrollBar = nil
  lobby.resize(lobby.width, lobby.height)
end

function Battle.enter()
  lobby.state = "battle"
  lobby.fixturePoint[1].x = 0
  
  --Battle.sideButton = Button:new():setPosition(1, lobby.height/2 - 20):setDimensions(20-2, 40):onClick(function() Battle.enterWithList() end)
  
  --[[function Battle.sideButton:draw()
    lg.rectangle("line", self.x, self.y, self.w, self.h)
    lg.polygon("line",
              5, self.y + self.h/2 - 8,
              5, self.y + self.h/2 + 8,
              15, self.y + self.h/2)
  end]]
  --lobby.clickables[Battle.sideButton] = true
  lobby.resize(lobby.width, lobby.height)
end

function Battle.enterWithList()
  lobby.state = "battleWithList"
  lobby.fixturePoint[1].x = 260
  --Battle.sideButton = Button:new():setPosition(261, lobby.height/2 - 20):setDimensions(20-2, 40):onClick(function() Battle.enter() end)
  --[[function Battle.sideButton:draw()
    lg.rectangle("line", self.x, self.y, self.w, self.h)
    lg.polygon("line",
              self.x + 15, self.y + self.h/2 - 8,
              self.x + 15, self.y + self.h/2 + 8,
              self.x + 5, self.y + self.h/2)
  end]]
  --lobby.clickables[Battle.sideButton] = true
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
  battle.game.players = {}
  battle.startrect = {}
  
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
  specButton = function(x, y) lg.setColor(colors.bt) lg.circle("fill", x, y, 4) end
}

local rectColors = {
  {0, 200/255, 0, 0.2},
  {200/255, 0, 0, 0.2}
}
    
function Battle:draw()
  self.midpoint = math.max(lobby.fixturePoint[1].x + 280, lobby.width * 0.45)
  --Buttons
  
  for _, button in pairs(self.buttons) do
    button:draw()
  end
  
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
  
    --[[if self.modDownload then
    lg.printf(self.modDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + 3*fontHeight, 1024/8, "left")
    lg.printf(tostring(math.ceil(100*self.modDownload.downloaded/self.modDownload.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + 4*fontHeight, 1024/8, "left")
  end]]
  
  local h = self:drawMap()
  self:drawModOptions(h)
  local y = self:drawPlayers()
  self:drawSpectators(y)

  lg.origin()
  --Battle.sideButton:draw()
end

function Battle:drawMap()
  local fontHeight = fonts.roboto:getHeight()
  lg.setFont(fonts.robotoitalic)
  lg.setColor(colors.text)
  
  lg.printf(self.mapName, self.midpoint, 10 + fontHeight, lobby.width - self.midpoint, "center")
  lg.setColor(1,1,1)
  local w, h
  if self.minimap then
    local xmin = self.midpoint + 20
    local xmax = lobby.fixturePoint[2].x - 50
    local ymin = 20 + 2*fontHeight
    local ymax = lobby.fixturePoint[2].y - 60 - (math.floor(lobby.height/100))*fonts.latoitalic:getHeight() - 10
    -- couldnt find a better way to do this
    local aw, ah = xmax - xmin, ymax - ymin
    if self.mapW > self.mapH then
      w = aw
      h = w / self.mapWidthHeightRatio
      if ah < h then
        h = ah
        w = self.mapWidthHeightRatio * h
      end
    elseif self.mapW < self.mapH then
      h = ah
      w = self.mapWidthHeightRatio * h
      if aw < w then
        w = aw
        h = w / self.mapWidthHeightRatio
      end
    else
      h = math.min(aw, ah)
      w = h
    end
    local x = xmin + aw/2 - w/2
    --local y = ymin + ah/2 - h/2
    if self.showMapScroll == 0 then
      lg.draw(self.heightmap,
      x, -- (modx-1)*w,
      ymin, -- (mody-1)*h,
      0, 2*w/self.mapW, 2*h/self.mapH)
    elseif self.showMapScroll == 1 then
      lg.draw(self.minimap,
      x, -- (modx-1)*w,
      ymin, -- (mody-1)*h,
      0, w/1024, h/1024)
    elseif self.showMapScroll == 2 then
      lg.draw(self.minimap,
      x, -- (modx-1)*w,
      ymin, -- (mody-1)*h,
      0, w/1024, h/1024)
      lg.setColor(1,1,1,0.75)
      lg.draw(self.metalmap,
      x, -- (modx-1)*w,
      ymin, -- (mody-1)*h,
      0, 2*w/self.mapW, 2*h/self.mapH)
    end
    --
    self.mapScrollBar:getZone():setPosition(x, ymin):setDimensions(w, h)
    local myAllyTeam = 0
    for _, user in pairs(self.playersByTeam) do
      if user.name == lobby.username then
        myAllyTeam = user.allyTeamNo
      end
    end
    for ally, box in pairs(self.startrect) do
      if ally == myAllyTeam then
        lg.setColor(rectColors[1])
      else
        lg.setColor(rectColors[2])
      end
      lg.rectangle("fill",
                    x + w*box[1],
                    ymin + h*box[2],
                    w*(box[3] - box[1]),
                    h*(box[4] - box[2]))
      lg.setFont(fonts.roboto)
      lg.setColor(0,0,0)
      lg.print(ally, x + w*(box[1] + box[3])/2 - fonts.roboto:getWidth(ally)/2, ymin + h*(box[2] + box[4])/2 - fonts.roboto:getHeight()/2 )
    end
  elseif self.mapDownload and not self.mapDownload.finished then
    lg.setColor(colors.text)
    lg.print(self.mapDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight)
    lg.print(tostring(math.ceil(100*self.mapDownload.downloaded/self.mapDownload.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 3*fontHeight)
  else
    lg.draw(img["nomap"], lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight, 0, 1024/(8*50))
  end
  return h
end

function Battle:drawModOptions(h)
  local fontHeight = fonts.roboto:getHeight()
  local x = self.midpoint + 20
  local ymin = 20 + 3*fontHeight + (h or 1024/8)
  local ymax = lobby.fixturePoint[2].y - fontHeight - 60
  local y = ymin - self.modoptionsScrollBar:getOffset()
  lg.setFont(fonts.latosmall)
  fontHeight = fonts.latosmall:getHeight()
  self.modoptionsScrollBar:getZone():setPosition(x, ymin)
  self.modoptionsScrollBar:setPosition(lobby.fixturePoint[2].x - 5, ymin):setLength(ymax - ymin + 10):setScrollBarLength((ymax - ymin + 10 )/ 10)
  lg.setColor(colors.bt)
  local c = 0
  local t = 0
  for k, v in pairs(self.game.modoptions) do
    if y < ymax and y >= ymin then
      local _, wt = fonts.latoitalic:getWrap(k, lobby.fixturePoint[2].x - x - fonts.latosmall:getWidth(v .. "  "))
      if #wt > 1 then
        for _, l in ipairs(wt) do
          lg.print(l, x, y)
          y = y + fontHeight
          c = c + 1
          t = t + 1
        end
        y = y - fontHeight
      else
        lg.print(k, x, y)
      end
      lg.print(v, lobby.fixturePoint[2].x - fonts.latoitalic:getWidth(v) - 15, y)
      c = c + 1
    end
    y = y + fontHeight
    t = t + 1
  end
  self.modoptionsScrollBar:getZone():setDimensions(lobby.fixturePoint[2].x - x, ymax - ymin)
  self.modoptionsScrollBar:setOffsetMax(math.max(0, t - c) * fontHeight):draw()
end

function Battle:drawPlayers()
  local y = 20 --+ self.userListScrollOffset
  local fontHeight = fonts.latosmall:getHeight() + 2
  lg.setFont(fonts.latosmall)
  lg.translate(lobby.fixturePoint[1].x + 25, 40 )
  local xmax = self.midpoint - (lobby.fixturePoint[1].x + 25) - fonts.latomedium:getWidth("Team 00")
  local teamNo = 0
  local drawBackRect = true
  local cy = y
  local myAllyTeam = 0
  for _, user in pairs(self.playersByTeam) do
    local username = user.name
    if username == lobby.username then
      myAllyTeam = user.allyTeamNo
    end
    if user.allyTeamNo > teamNo then
      lg.setFont(fonts.latomedium)
      lg.setColor(colors.bt)
      if teamNo > 0 then
        lg.line(0, y + fontHeight/4, xmax - 40, y + fontHeight/4)
        y = y + fontHeight/2
      end
      teamNo = user.allyTeamNo
      lg.print("Team " .. teamNo, xmax, y)
      cy = y
      lg.setFont(fonts.latosmall)
    end
    if user.battleStatus then
      if drawBackRect then
        lg.setColor(colors.bb)
        lg.rectangle("fill", 0, y, xmax - 40, fontHeight)
      end
      drawBackRect = not drawBackRect
      draw.readyButton[user.ready](xmax - 50, y + 7)
      lg.setColor(1,1,1)
      lg.draw(user.flag, 23, 3 + y)
      lg.draw(user.insignia, 41, y, 0, 1/4)
      lg.setColor(user.teamColorUnpacked[1]/255, user.teamColorUnpacked[2]/255, user.teamColorUnpacked[3]/255, 0.4)
      lg.rectangle("fill", 60, y, 120, fontHeight, 5, 5)
      lg.setColor(colors.text)
      if user.icon then
        lg.draw(img[user.icon], 5, y, 0, 1/4)
      end
      lg.print(username, 64, y)
      if self.game.players[username:lower()] and self.game.players[username:lower()].skill then
        lg.print(string.match(self.game.players[username:lower()].skill, "%d+"), 190, y)
      end
      y = y + fontHeight
    end
  end
  return y
end

function Battle:drawSpectators(y)
  local xmax = self.midpoint - (lobby.fixturePoint[1].x + 25) - fonts.latomedium:getWidth("Team 00")
  local fontHeight = fonts.latosmall:getHeight() + 2
  local drawBackRect = true
  self.spectatorsScrollBar:getZone():setPosition(lobby.fixturePoint[1].x + 25, y)
  self.spectatorsScrollBar:getZone():setDimensions(self.midpoint - lobby.fixturePoint[1].x + 25, lobby.fixturePoint[2].y - y)
  local ymin = math.max(8*fontHeight, y + fontHeight)
  self.spectatorsScrollBar:setPosition(xmax - 20, ymin)
  local ymax = lobby.fixturePoint[1].y
  y = ymin - self.spectatorsScrollBar:getOffset()
  lg.setColor(colors.text)
  lg.print("Spectators", 60, ymin)
  y = y + 3*fontHeight/2
  drawBackRect = true
  local c = 0
  local t = 0
  for username, user in pairs(self.users) do
    if user.isSpectator and user.battleStatus then
      t = t + 1
      if y >= ymin + fontHeight and y <= ymax - 40 then
        c = c + 1
        if drawBackRect then
          lg.setColor(colors.bb)
          lg.rectangle("fill", 0, y, xmax - 40, fontHeight)
        end
        drawBackRect = not drawBackRect
        draw.specButton(xmax - 50, 7 + y)
        lg.setColor(1,1,1)
        lg.draw(user.flag, 23, 3 + y)
        lg.draw(user.insignia, 41, y, 0, 1/4)
        --local w = fonts.latosmall:getWidth(username)
        lg.setColor(colors.text)
        if user.icon then
          lg.draw(img[user.icon], 5, y, 0, 1/4)
        end
        lg.print(username, 60, y)
      end
      y = y + fontHeight
    end
  end
  self.spectatorsScrollBar:setLength(ymax - ymin - 70):setOffsetMax(math.max(0, t - c) * fontHeight):draw()
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
  
  --Metal Map
  local bytes = (mapWidth/2) * (mapHeight/2)
  local metalmapData = love.data.unpack("c"..tostring(bytes), mapData, metalmapOffset + 1)
  local imageData = love.image.newImageData( (mapWidth)/2, (mapHeight)/2, "r8", metalmapData )
  self.metalmap =  lg.newImage(imageData)
  
  --HeightMap
 --[[bytes = (mapWidth + 1) * (mapHeight + 1)
 local heightmapDataString = mapData:sub(heightmapOffset+1)
 local heightMap
  for i = 1, bytes, 2 do
    local a, b = heightmapDataString:byte(i, i+1)
    heightMap = a * 256
  end]]
  --local heightmapData = love.data.unpack("H", mapData, heightmapOffset+1)
  --local heightMap = love.data.newByteData(heightmapData)-- heightmapOffset + 1, bytes )
  --imageData = love.image.newImageData( 2, 2, "r8", heightMap)
  --metalmapData = Battle.DDSheader .. metalmapData
  --local mbytedata = love.data.newByteData( metalmapData )
  --local mcompdata = love.image.newCompressedData(mbytedata)
  self.heightmap = lg.newImage(imageData)
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