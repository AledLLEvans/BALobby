Battle = {}
Battle.mt =  {__index = Battle}
local lg = love.graphics
local lfs = love.filesystem
local nfs = require("lib/nativefs")
local spring = require "spring"
local lm = love.mouse

Battle.s = {}

Battle.count = 0

local shader = lg.newShader[[
  vec4 effect(vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord)
{
  vec4 texcolor = Texel(tex, texcoord);
  texcolor.rgb = texcolor.grb;
  return texcolor * vcolor;
}
]]

local Map = require "maps"

function Battle.initialize()
  Battle.canvas = lg.newCanvas(lobby.width, lobby.height)
  Battle.buttons = {
      ["map"] = ImageButton:new()
        :resetPosition(function() return lobby.fixturePoint[2].x - 45, 60 end)
        :setDimensions(40, 35)
        :setImage(img.map):setHighlightColor(colors.textblue)
        :onClick(function() Battle.pickmap() end),
      ["addbot"] = ImageButton:new()
        :resetPosition(function() return lobby.fixturePoint[2].x - 45, 100 end)
        :setDimensions(40, 35)
        :setImage(img.bot):setHighlightColor(colors.textblue)
        :onClick(function() Battle.addbot() end),
      ["info"] = ImageButton:new()
        :resetPosition(function() return lobby.fixturePoint[2].x - 45, 140 end)
        :setDimensions(40, 35)
        :setImage(img.gear):setHighlightColor(colors.textblue)
        :onClick(function() Battle.info() end),
      ["ally"] = BattleButton:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 10, lobby.fixturePoint[2].y - 75 end)
        :setDimensions(45, 25)
        :setText("Ally"):setFont(fonts.latobold12)
        :onPreClick(function() Battle.ally:on() end)
        :setRoundedCorners(10),
      ["team"] = BattleButton:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 80, lobby.fixturePoint[2].y - 75 end)
        :setDimensions(50, 25)
        :setText("Team"):setFont(fonts.latobold12)
        :onClick(function() Battle.team() end)
        :setRoundedCorners(10),
      ["faction"] = BattleButton:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 150, lobby.fixturePoint[2].y - 75 end)
        :setDimensions(70, 25)
        :setText("Faction"):setFont(fonts.latobold12)
        :onClick(function() Battle.faction() end)
        :setRoundedCorners(6),
      ["colour"] = BattleButton:new()
        :resetPosition(function() return  lobby.fixturePoint[1].x + 230, lobby.fixturePoint[2].y - 72 end)
        :setDimensions(60, 20)
        :setText("Colour"):setFont(fonts.latobold12)
        :onClick(function() Battle.faction() end),
      --[[["exit"] = BattleButton:new()
        :resetPosition(function() return 3*lobby.width/4 - 255, lobby.fixturePoint[2].y - 35 end)
        :setDimensions(100, 35)
        :setText("Exit Battle")
        :onClick(function() Battle:getActive():leave() end),]]
      ["spectate"] = Checkbox:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 10, lobby.fixturePoint[2].y - 35 end)
        :setDimensions(20, 20)
        :setText("Spectate"):setFont(fonts.latoboldmedium)
        :setToggleVariable(function() return User.s[lobby.username].spectator end)
        :onClick(function() lobby.setSpectator(not User.s[lobby.username].spectator) end),
      ["ready"] = Checkbox:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 90, lobby.fixturePoint[2].y - 35 end)
        :setDimensions(20, 20)
        :setText("Ready"):setFont(fonts.latoboldmedium)
        :setToggleVariable(function() return User.s[lobby.username].ready end)
        :onClick(function() if not User.s[lobby.username].spectator then lobby.setReady(not User.s[lobby.username].ready) end end),
      ["autolaunch"] = Checkbox:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 155, lobby.fixturePoint[2].y - 35 end)
        :setDimensions(20,20)
        :setText("Auto-start"):setFont(fonts.latoboldmedium)
        :setToggleVariable(function() return lobby.launchOnGameStart end)
        :onClick(function() if User.s[lobby.username].spectator then lobby.launchOnGameStart = not lobby.launchOnGameStart end end),
      ["launch"] = BattleButton:new()
        :resetPosition(function() return lobby.fixturePoint[1].x + 250, lobby.fixturePoint[2].y - 38 end)
        :setDimensions(45, 25):setBackgroundHighlightColor(colors.readygreen):setBackgroundColor(colors.startgreen):setTextColor(colors.bbb)
        :setText("Start"):setRoundedCorners(12)
        :onClick(function()
          local battle = Battle:getActive()
          if battle.isMyBattle or battle.founder.ingame then
            lobby.launchSpring()
          else
            lobby.send("SAYBATTLE !start")
            --love.window.showMessageBox("For your information", "Game has not yet started.", "info")
          end
        end)
  }
  
  for _, button in pairs(Battle.buttons) do
    lobby.clickables[button] = false
  end
  Battle.pickMap = Button:new():onClick(function() end)--Map.enter() end)
  
  Battle.showMapScroll = 1
  
  Battle.mapScrollBar = ScrollBar:new():setOffset(0)
  :setRenderFunction(function(y)
      if y then
        if y > 0 then
          Battle.showMapScroll = math.min(2, Battle.showMapScroll + 1)
        elseif y < 0 then
          Battle.showMapScroll = math.max(0, Battle.showMapScroll - 1)
        end
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
  :setScrollSpeed(fonts.freesansbold12:getHeight())
  
  Battle.showMap = "minimap"
end

function Battle.pickmap()
  
end

function Battle.addbot()
  
end

local showModOptions = false
function Battle.info()
  sound.check:play()
  showModOptions = not showModOptions
  Battle.buttons["info"].highlight = not Battle.buttons["info"].highlight
  Battle.render()
end


Battle.ally = {}
function Battle.ally:on()
  --lm.setVisible( false )
  self.cd = 0
  self.x = Battle.buttons["ally"].x + Battle.buttons["ally"].w/2
  self.value = Battle:getActive().users[lobby.username].allyTeamNo
  self.newvalue = self.value
  lobby.events[self] = true
end

function Battle.ally:update(dt)
  local msx, msy = lm.getPosition()
  if self.cd > 0 then self.cd = self.cd - dt return end
  if msx > self.x + 5 then
    self.newvalue = math.min(15, self.newvalue + 1)
    self.cd = 0.05
  elseif msx < self.x - 5 then
    self.newvalue = math.max(0, self.newvalue - 1)
    self.cd = 0.05
  end
  lm.setPosition(math.max(math.min(msx, self.x+10), self.x-10), msy)
  if not lm.isDown( 1 ) then self:off() end
  Battle.render()
end

function Battle.ally:off()
  --lm.setVisible( true )
  lobby.events[self] = nil
  if self.newvalue == self.value then return end
  User.s[lobby.username].newAllyTeamNo = self.value
  lobby.sendMyBattleStatus()
end


function Battle.team()
  
end

function Battle.faction()
  
end

function Battle.colour()
  
end

function Battle:joined(id)
  if self:mapHandler() and self:modHandler() then
    lobby.user.synced = true
  end
  if id then
    Channel.active = Channel.s["Battle_" .. id]
  else
    Channel.active = Channel.s["Battle"]
  end
  self.display = true
  --self:getChannel().infoBoxScrollBar:setOffset(0)
end

function Battle:resetButtons()
  for _, button in pairs(self.buttons) do
    button:resetPosition()
  end
end

function Battle:leave(kicked)
  for _, button in pairs(Battle.buttons) do
    lobby.clickables[button] = false
  end
  if self:getChannel() then
    Channel.active = Channel.s[next(Channel.s, self:getChannel().title)]
    self:getChannel().display = false
  end
  self.display = false
  lobby.enter()
  --Battle.modoptionsScrollBar = nil
  --lobby.clickables[Battle.sideButton] = nil
  --Battle.sideButton = nil
  --[[Battle.modoptionsScrollBar = nil
  Battle.spectatorsScrollBar = nil
  Battle.mapScrollBar = nil]]
  if not kicked then lobby.send("LEAVEBATTLE") end
  Battle.active = nil
  lobby.resize(lobby.width, lobby.height)
  canvas:pop(Battle.canvas)
end

function Battle.host()
  lobby.send("OPENBATTLE 0 0 * 8452 16 ".. spring.getArchiveChecksum(lobby.gameFolder .. "Balanced_Annihilation-V11.0.2.sdz") .." 0 ".. spring.getArchiveChecksum(lobby.mapFolder .. "DeltaSiegeDry_v8.sd7") .." Spring\t103\tDeltaSiegeDry v8\t" .. lobby.username .. "'s battle\t" .. lobby.modname )
end

function Battle.enter(fromJoined)
  --lobby.clickables[lobby.backbutton] = true
  --lobby.clickables[lobby.options.button] = false
  lobby.events[lobby.battlelist] = nil
  if fromJoined then
    lobby.state = "battle"
    lobby.resize(lobby.width, lobby.height)
  else
    lobby.battlezoom:initialize("maximize")
  end
  canvas:push(Battle.canvas)
  for _, button in pairs(Battle.buttons) do
    lobby.clickables[button] = true
  end
  lobby.clickables[Battle.pickMap] = true
  lobby.scrollBars[Battle.mapScrollBar] = true
  lobby.scrollBars[Battle.spectatorsScrollBar] = true
  lobby.scrollBars[Battle.modoptionsScrollBar] = true
  --Battle.sideButton = Button:new():setPosition(1, lobby.height/2 - 20):setDimensions(20-2, 40):onClick(function() Battle.enterWithList() end)
  
  --[[function Battle.sideButton:draw()
    lg.rectangle("line", self.x, self.y, self.w, self.h)
    lg.polygon("line",
              5, self.y + self.h/2 - 8,
              5, self.y + self.h/2 + 8,
              15, self.y + self.h/2)
  end]]
  --lobby.clickables[Battle.sideButton] = true
  lobby.userlist.bar:shut()
end

function Battle.enterSingle()
  if not Battle.singlePlayerBattle then
    local battle = {}
    battle.single = true
    battle.id = 0
    battle.founder = "Me"
    battle.gameName = ""
    battle.mapName = "DeltaSiegeDry_v8"
    battle.maxPlayers = 1
    battle.title = "Single Player"
    Battle.singlePlayerBattle = Battle:new(battle)
  end
  Battle.active = Battle.singlePlayerBattle
  --Battle.active:joined()
  Battle.enter(true)
end

function Battle:new(battle)
  setmetatable(battle, Battle.mt)
  
  battle.playersByTeam = {}
  
  battle.spectatorCount = 0
  battle.locked = false
  battle.users = {}
  battle.userCount = 0
  
  battle.teamCount = 0
  battle.userListScrollOffset = 0
  
  battle.game = {}
  battle.game.modoptions = {}
  battle.game.players = {}
  battle.startrect = {}
  
  --battle.ffa = false
  
  if battle.founder == lobby.username then battle.isMyBattle = true end
  
  return battle
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
  --[[local battle = Battle:getActive()
  if battle.max then
  end]]
  User.s[lobby.username].spectator = b
  User.s[lobby.username].ready = false
  lobby.launchOnGameStart = lobby.launchOnGameStart or not b
  lobby.sendMyBattleStatus()
end

function lobby.setReady(b)
  if User.s[lobby.username].spectator then return end
  User.s[lobby.username].ready = settings.autoready or b
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
  --user.ready and 1 or 0
  --user.spectator and 0 or 1
  --user.synced and 1 or 0
  local newstatus = (user.ready and 1 or 0) * 2 +
  (user.newAllyTeamNo % 2) * 2 ^ 6 + math.floor((user.newAllyTeamNo % 4)/2) * 2 ^ 7 + (math.floor((user.newAllyTeamNo % 8)/4)) * 2 ^ 8 + math.floor(user.newAllyTeamNo/8) * 2 ^ 9 + 
  (user.spectator and 0 or 1) * 2 ^ 10 +
  2 ^ (23 - (user.synced and 1 or 0))
  
  local color = user.color
  lobby.send("MYBATTLESTATUS " .. newstatus .. " " .. color)
end

function Battle:update(dt)
  --Mod
  if self.modDownload then
    local err = self.modDownload.error
    local finished = self.modDownload.finished
    if finished then
      self.hasMod = true
      if self.hasMap then lobby.events[self] = nil lobby.setSynced(true) end
      self.modDownload = nil
      lobby.refreshBattleTabs()
      return
    elseif err then
      self.modMirrorID = self.modMirrorID + 1
      if self.modMirrorID > #self.modMirrors then
        --table.insert(self:getChannel().lines, {time = os.date("%X"), msg = "Error auto-downloading game\n" .. self.modDownload.error .. "\nYou Could try installing manually"})
        self.modDownload:release()
        self.modDownload = nil
        if self.hasMap or (not self.mapDownload) then lobby.events[self] = nil end
        return
      end
      local filename = string.match(self.modMirrors[self.modMirrorID], ".*/(.*)")
      self.modDownload:push(self.modMirrors[self.modMirrorID], filename, lobby.modFolder)
    end
  end
  -- Map
  if self.mapDownload then
    local err = self.mapDownload.error
    local finished = self.mapDownload.finished
    if finished then
      self.hasMap = true
      self:getMinimap()
      self.mapDownload = nil
      if self.hasMod then lobby.events[self] = nil lobby.setSynced(true) end
      lobby.refreshBattleTabs()
      return
    elseif err then
      self.mapMirrorID = self.mapMirrorID + 1
      if self.mapMirrorID > #self.mapMirrors then
        --table.insert(self:getChannel().lines, {time = os.date("%X"), msg = "Failed to find URL for map " .. self.mapName .. "\n".. self.mapDownload.error .. "\nTry downloading manually\n(Type !maplink, click on the hyperlink and place the file in your spring/maps/ directory)"})
        --love.window.showMessageBox("Auto Map Downloader", "\nFailed to find URL for map\nTry installing manually\n(Type !maplink, click on the hyperlink and place the file in your spring/maps/ directory)", "error" )
        self.mapDownload:release()
        self.mapDownload = nil
        if self.hasMod or (not self.modDownload) then lobby.events[self] = nil end
        return
      end
      local filename = string.match(self.mapMirrors[self.mapMirrorID], ".*/(.*)")
      self.mapDownload:push(self.mapMirrors[self.mapMirrorID], filename, lobby.mapFolder)
    end
  end
end

local draw = {
  readyButton = {
    [true] = function(x, y) --[[lg.setColor(0,0,0) lg.circle("line", x, y, 6)]] lg.setColor(colors.readygreen) lg.circle("fill", x, y, 6) end,
    [false] = function(x, y) --[[lg.setColor(0,0,0) lg.circle("line", x, y, 6)]] lg.setColor(colors.readyred) lg.circle("fill", x, y, 6) end
  },
  specButton = function(x, y) lg.setColor(colors.bt) lg.circle("fill", x, y, 2) end
}

local rectColors = {
  {0, 200/255, 0, 0.2},
  {200/255, 0, 0, 0.2}
}
    
function Battle.render()
  lg.setCanvas(Battle.canvas)
  lg.clear()
  if Battle:getActive() then Battle:getActive():draw() else lobby.state = "landing" end
  lg.setCanvas()
end
    
function Battle:draw()
  self.midpoint = math.max(280, lobby.width * 0.45)
  --lg.line(lobby.fixturePoint[1].x, 0, lobby.fixturePoint[1].x, lobby.height)
  --lg.line(self.midpoint, 0, self.midpoint, lobby.height)
  --lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.height)
  
  --Buttons
  local me = self.users[lobby.username]
  if me and me.battleStatus then
    if me.isSpectator then
      Battle.buttons.ally:setText("Ally")
      Battle.buttons.team:setText("Team")
      Battle.buttons.faction:setText("Faction")
    else
      Battle.buttons.ally:setText("Ally " .. me.newAllyTeamNo + 1)
      Battle.buttons.team:setText("Team " .. me.newTeamNo)
      Battle.buttons.faction:setText("Faction " .. me.newSide)
    end
  end
  
  for k, button in pairs(Battle.buttons) do
    button:draw()
  end
  
  --Room Name, Title
  lg.setFont(fonts.roboto)
  lg.setColor(colors.textblue)
  local i = 0
  local text = self.title
  repeat
    text = text:sub(1, #text - i)
    local width = fonts.roboto:getWidth(text)
    i = i + 1
  until width < lobby.fixturePoint[2].x - 25 or text == ""
  if i > 1 then text = text:sub(1, #text - 2) .. ".." end
  lg.print(text, 25, 32)
  local fontHeight = fonts.roboto:getHeight()
  
  --Game Name, subtitle
  lg.setFont(fonts.latoboldbig)
  lg.setColor(colors.text)
  lg.print(self.gameName, 25, 32 + fontHeight)
  
    --[[if self.modDownload then
    lg.printf(self.modDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + 3*fontHeight, 1024/8, "left")
    lg.printf(tostring(math.ceil(100*self.modDownload.downloaded/self.modDownload.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8 + 20 + 4*fontHeight, 1024/8, "left")
  end]]
  
  local h = self:drawMap(32 + fontHeight)
  self:drawModOptions(h)
  local y = self:drawPlayers()
  self:drawSpectators(y)

  lg.origin()
  --Battle.sideButton:draw()
  --if Map.isOpen() then
  --  Map.render()
  --end
  lg.setCanvas()
end

function Battle:drawMap(height)
  local fontHeight = fonts.roboto:getHeight()
  local x, w, h
  local xmin = lobby.fixturePoint[1].x + 10
  local xmax = lobby.fixturePoint[2].x - 50
  local ymin = 30 + 2*fontHeight
  local ymax = lobby.fixturePoint[2].y - 60 - (math.floor(lobby.height/100))*fonts.latoitalic:getHeight() - 10
  if not showModOptions then ymax = lobby.fixturePoint[2].y - 80 end
  lg.setFont(fonts.freesansbold16)
  lg.setColor(colors.textblue)
  if not self.single then if (self.teamCount < 3) then lg.print("Duel", xmax, 32) elseif self.ffa then lg.print("FFA", xmax, 32) else lg.print("Teams", xmax - 10, 32) end end
  lg.setColor(1,1,1)
  -- couldnt find a better way to do this
  local aw, ah = xmax - xmin, ymax - ymin
  if self.minimap then
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
    x = xmin + aw/2 - w/2
    --local y = ymin + ah/2 - h/2
    if self.showMapScroll == 0 then
      lg.setColor(1,1,1)
      lg.draw(self.heightmap,
      x, -- (modx-1)*w,
      ymin, -- (mody-1)*h,
      0, w/self.mapW, h/self.mapH)
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
      lg.setColor(1,1,1,0.7)
      lg.setShader(shader)
      lg.draw(self.metalmap,
      x, -- (modx-1)*w,
      ymin, -- (mody-1)*h,
      0, 2*w/self.mapW, 2*h/self.mapH)
      lg.setShader( )
    end
    lg.setColor(colors.text)
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
      lg.setFont(fonts.krone)
      lg.setColor(0,0,0)
      lg.print(ally, x + w*(box[1] + box[3])/2 - fonts.krone:getWidth(ally)/2, ymin + h*(box[2] + box[4])/2 - fonts.krone:getHeight()/2 )
      lg.setFont(fonts.krones)
      lg.setColor(1,1,1)
      lg.print(ally, x + w*(box[1] + box[3])/2 - fonts.krones:getWidth(ally)/2, ymin + h*(box[2] + box[4])/2 - fonts.krones:getHeight()/2 )
    end
  elseif self.mapDownload and self.mapDownload.error then
    lg.setColor(colors.text)
    lg.print(self.mapDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight)
    lg.print("Error downloading Map", lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 3*fontHeight)
  elseif self.mapDownload and not self.mapDownload.finished then
    lg.setColor(colors.text)
    lg.print(self.mapDownload.filename, lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight)
    lg.print(tostring(math.ceil(100*self.mapDownload.downloaded/self.mapDownload.file_size)) .. "%", lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 3*fontHeight)
  else
    --lg.draw(img["nomap"], lobby.fixturePoint[2].x - 10 - 1024/8, 20 + 2*fontHeight, 0, 1024/(8*50))
    x, w, h = lobby.fixturePoint[2].x - 10 - 1024/8, 1024/8, 1024/8
  end
  lg.setColor(colors.text)
  lg.setFont(fonts.latoboldbig)
  lg.printf(self.mapName, lobby.fixturePoint[1].x, height, aw, "center")
  Battle.pickMap:setPosition(x, ymin):setDimensions(w, h)
  return h
end

function Battle:drawModOptions(h)
  if not showModOptions then return end
  local fontHeight = fonts.roboto:getHeight()
  local x = lobby.fixturePoint[1].x + 10
  local ymin = 10 + 3*fontHeight + (h or 1024/8)
  local ymax = lobby.fixturePoint[2].y - fontHeight - 70
  local y = ymin - self.modoptionsScrollBar:getOffset()
  local font = fonts.freesansbold12
  if love.graphics:getWidth() > 1200 then
    font = fonts.freesansbold14
  elseif love.graphics:getWidth() > 800 then
    font = fonts.freesansbold16
  end
  lg.setFont(font)
  fontHeight = font:getHeight()
  self.modoptionsScrollBar:getZone():setPosition(x, ymin)
  self.modoptionsScrollBar:setPosition(lobby.fixturePoint[2].x - 5, ymin):setLength(ymax - ymin + 10):setScrollBarLength((ymax - ymin + 10 )/ 10):setScrollSpeed(fontHeight)
  lg.setColor(colors.mo)
  local c = 0
  local t = 0
  for k, v in pairs(self.game.modoptions) do
    if y < ymax and y >= ymin then
      local _, wt = font:getWrap(k, lobby.fixturePoint[2].x - x - font:getWidth(v .. "  "))
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
      lg.print(v, lobby.fixturePoint[2].x - font:getWidth(v) - 10, y)
      c = c + 1
    end
    y = y + fontHeight
    t = t + 1
  end
  self.modoptionsScrollBar:getZone():setDimensions(lobby.fixturePoint[2].x - x, ymax - ymin)
  self.modoptionsScrollBar:setOffsetMax(math.max(0, t - c) * fontHeight):draw()
end

function Battle:drawPlayers()
  local y = 42 --+ self.userListScrollOffset
  lg.translate(25, 40)
  local xmax = lobby.fixturePoint[1].x
  local teamNo = 0
  local drawBackRect = true
  local cy = y
  local myAllyTeam = 0
  local teamBool = (self.teamCount > 2) and not self.ffa
  local font = fonts.freesansbold12
  if lg:getWidth() > 1200 then
    font = fonts.freesansbold16
  elseif lg:getWidth() > 800 then
    font = fonts.freesansbold14
  end
  local fontHeight = font:getHeight()
  for _, user in pairs(self.playersByTeam) do
    local username = user.name
    if username == lobby.username then
      myAllyTeam = user.allyTeamNo
    end
    local increment = math.ceil(fontHeight/4)
    if user.allyTeamNo > teamNo then
      if teamNo > 0 then
        if self.ffa then
          lg.line(0, y, xmax - 40, y)
        else 
          lg.line(0, y + increment, xmax - 40, y + increment)
          y = y + increment + increment
        end
      end
      lg.setFont(fonts.latobold19) lg.setColor(colors.text)
      teamNo = user.allyTeamNo
      if teamBool then lg.print(teamNo, -14, y -4) end
      cy = y
    end
    if user.battleStatus then
      if drawBackRect then
        lg.setColor(colors.brb)
        lg.rectangle("fill", 0, y, xmax - 40, fontHeight)
      end
      drawBackRect = not drawBackRect
      draw.readyButton[user.ready](xmax - 50, y + 8)
      lg.setColor(1,1,1)
      if user.syncStatus ~= 1 then lg.draw(img.exclamation, xmax - 50, y + 8, 0, 1/2, 1/2, 16, 16) end
      lg.draw(user.flag, 43, 3 + y)
      lg.draw(user.insignia, 61, y, 0, 1/2)
      lg.setColor(user.teamColorUnpacked[1]/255, user.teamColorUnpacked[2]/255, user.teamColorUnpacked[3]/255, 0.4)
      lg.rectangle("fill", 24, y+2, 12, 12, 4, 4)
      lg.setColor(0,0,0)
      lg.setLineWidth(2)
      lg.rectangle("line", 24, y+2, 12, 12, 4, 4)
      lg.setLineWidth(1)
      lg.setColor(colors.text)
      if user.icon then
        lg.draw(img[user.icon], 5, y, 0, 1/2)
      end
      lg.setFont(font)
      lg.print(username, 84, y)
      if self.game.players[username:lower()] and self.game.players[username:lower()].skill then
        lg.print(string.match(self.game.players[username:lower()].skill, "%d+"), xmax - 80, y)
      end
      y = y + fontHeight
    end
  end
  return y
end

function Battle:drawSpectators(y)
  local xmax = lobby.fixturePoint[1].x
  local font = fonts.freesansbold12
  if love.graphics:getWidth() > 1200 then
    font = fonts.freesansbold16
  elseif love.graphics:getWidth() > 800 then
    font = fonts.freesansbold14
  end
  local fontHeight = font:getHeight()
  local drawBackRect = true
  self.spectatorsScrollBar:getZone():setPosition(25, y)
  self.spectatorsScrollBar:getZone():setDimensions(lobby.fixturePoint[1].x + 25, lobby.fixturePoint[2].y - y)
  local ymin = math.max(8*fontHeight, y + 6)
  self.spectatorsScrollBar:setPosition(xmax - 30, ymin + 3*fontHeight/2)
  local ymax = lobby.fixturePoint[1].y
  y = ymin - self.spectatorsScrollBar:getOffset()
  y = y + 3*fontHeight/2
  drawBackRect = true
  local c = 0
  local t = 0
  for username, user in pairs(self.users) do
    if user.isSpectator and user.battleStatus then
      t = t + 1
      if y >= ymin + fontHeight and y <= ymax - 60 then
        c = c + 1
        if drawBackRect then
          lg.setColor(colors.brb)
          lg.rectangle("fill", 0, y, xmax - 40, fontHeight)
        end
        drawBackRect = not drawBackRect
        --draw.specButton(xmax - 50, 7 + y)
        lg.setColor(1,1,1)
        if user.syncStatus ~= 1 then lg.draw(img.exclamation, xmax - 50, y + 8, 0, 1/2, 1/2, 16, 16) end
        lg.draw(user.flag, 23, 3 + y)
        lg.draw(user.insignia, 41, y, 0, 1/2)
        --local w = fonts.latosmall:getWidth(username)
        lg.setColor(colors.text)
        if user.icon then
          lg.draw(img[user.icon], 5, y, 0, 1/2)
        end
        lg.setFont(font)
        lg.print(username, 60, y)
      end
      y = y + fontHeight
    end
  end
  if c > 0 then
    lg.setColor(colors.text)
    lg.setFont(fonts.latobold14)
    if not self.single then lg.print("Spectators", 0, ymin) end
    self.spectatorsScrollBar:setLength(ymax - ymin - 70):setOffsetMax(math.max(0, t - c) * fontHeight):setScrollSpeed(fontHeight):draw()
  end
end

function Battle:modHandler()
  local gameName = string.gsub(self.gameName:lower(), " ", "_", 1)
  gameName = string.gsub(gameName, " ", "-", 1)
  gameName = string.gsub(gameName, " ", "_")
  if spring.hasMod(gameName) then self.hasMod = true return true end
  self.modMirrors = {
    --"https://www.springfightclub.com/data/" .. gameName .. ".sdz",
    "https://files.balancedannihilation.com/data/" .. gameName .. ".sdz"
  }
  self.modMirrorID = 1
  self.modDownload = Download:new()
  local filename = string.match(self.modMirrors[self.modMirrorID], ".*/(.*)")
  self.modDownload:push(self.modMirrors[self.modMirrorID], filename, lobby.gameFolder)
  lobby.events[self] = true
  return false
end

function Battle:mapHandler()
  local mapName = string.gsub(self.mapName:lower(), " ", "_")
  if spring.hasMap(mapName) then self.hasMap = true return true end
  self.mapMirrors = {
    "https://api.springfiles.com/files/maps/" .. mapName .. ".sd7",
    "https://api.springfiles.com/files/maps/" .. mapName .. ".sdz",
    --"https://www.springfightclub.com/data/maps/" .. mapName .. ".sd7",
    --"https://www.springfightclub.com/data/maps/" .. mapName .. ".sdz"
    "http://files.balancedannihilation.com/data/maps/" .. mapName .. ".sdz",
    "http://files.balancedannihilation.com/data/maps/" .. mapName .. ".sd7"
  }
  self.mapDownload = Download:new()
  self.mapMirrorID = 1
  local filename = string.match(self.mapMirrors[self.mapMirrorID], ".*/(.*)")
  self.mapDownload:push(self.mapMirrors[self.mapMirrorID], filename, lobby.mapFolder)
  lobby.events[self] = true
  return false
end

function Battle:getMinimap()
  local data = spring.getMapData(self.mapName)
  if data then
    self.minimap = data.minimap
    self.metalmap = data.metalmap
    self.heightmap = data.heightmap
    self.mapWidthHeightRatio = data.widthHeightRatio
    self.mapW = data.mapwidth
    self.mapH = data.mapheight
  end
end
  