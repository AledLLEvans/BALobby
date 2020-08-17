local lg = love.graphics
local lk = love.keyboard
local base64 = require("lib/base64")
local md5 = require("lib/md5")
  
local address, port = "springfightclub.com", 8200

lobby.MOTD = {}
lobby.canvas = {}
lobby.render = {}
local draggable = require "Draggable"
lobby.options = require "gui/options"
lobby.userlist = require "gui/userlist"
lobby.battlelist = require "gui/battlelist"
function lobby.initialize()
  login.video = nil
  love.window.updateMode( lobby.width, lobby.height, {minwidth = 800, minheight = 600, borderless = true})
  lobby.width = 800
  lobby.height = 600
  state = STATE_LOBBY
  sound.intro:play()
  lg.setBackgroundColor(colors.bg)
  lobby.launchOnGameStart = true
  lobby.fixturePoint = {
    {x = 0, y = 2*lobby.height/3},
    {x = 3*lobby.width/4, y = 2*lobby.height/3}
  } 

  lobby.backbutton = Button:new()
  :setPosition(0, 0)
  :setDimensions(36,36)
  :setText("<-")
  :onClick(function()
      sound.tab:play()
      lobby.enter()
  end)

  lobby.close = Button:new()
  :setPosition(lobby.width-30, 0)
  :setDimensions(30,30)
  :setFunction(function() love.event.quit() end)
  lobby.maximize = Button:new()
  :setPosition(lobby.width-60, 0)
  :setDimensions(30,30)
  :setFunction(function()
      if love.window.isMaximized() then
        lobby.resize(800, 600)
        love.window.updateMode(800, 600)
      else 
        love.window.maximize()
        local _, _, flags = love.window.getMode() 
        lobby.resize(love.window.getDesktopDimensions( flags.display )) 
      end
    end)
  lobby.minimize = Button:new()
  :setPosition(lobby.width-90, 0)
  :setDimensions(30,30)
  :setFunction(function()
      if love.window.isMinimized() then
        love.window.restore( )
      else 
        love.window.minimize()
      end
    end)
  
  function lobby.close:draw()
    lg.setColor(colors.bargreen)
    lg.rectangle("fill", self.x, self.y, self.w, self.y)
    lg.setColor(colors.text)
    lg.setFont(fonts.latoboldbig)
    lg.print("X", self.x + self.w/4, self.y + self.h/4)
  end
  function lobby.maximize:draw()
    lg.setColor(colors.bt)
    lg.rectangle("fill", self.x, self.y, self.w, self.y)
    lg.setColor(colors.text)
    lg.setFont(fonts.latoboldbig)
    lg.print("| |", self.x + self.w/4, self.y + self.h/4)
  end
  function lobby.minimize:draw()
    lg.setColor(colors.bt)
    lg.rectangle("fill", self.x, self.y, self.w, self.y)
    lg.setColor(colors.text)
    lg.setFont(fonts.latoboldbig)
    lg.print("__", self.x + self.w/4, self.y + self.h/4)
  end
  
  lobby.clickables[lobby.close] = true
  lobby.clickables[lobby.maximize] = true
  lobby.clickables[lobby.minimize] = true
  
  lobby.userlist.initialize()
  lobby.battlelist.initialize()
  lobby.options.initialize()
  
  lobby.resize( lobby.width, lobby.height )
  lobby.timeSinceLastPong = 0
  cursor[1] = love.mouse.getCursor( )
  
  --Channel.textbox:setPosition(1, lobby.height - 21):setDimensions(lobby.fixturePoint[2].x - 2, 20)
  Battle.initialize()
end

lobby.battleMiniWindow = {}

function lobby.battleMiniWindow:initialize(direction)
  sound.dwoosh:stop()
  sound.dwoosh:play()
  if direction == "minimize" then
    self.state = "minimizing"
    self.x, self.y = 0, 0
    self.w, self.h = lobby.width, lobby.height
    self.dx, self.dy = 2*lobby.width/3, lobby.fixturePoint[2].y + 35
    self.sw, self.sh = self.dx/12, self.dy/12
    lobby.scrollBars[Battle.mapScrollBar] = false
    lobby.scrollBars[Battle.spectatorsScrollBar] = false
    lobby.scrollBars[Battle.modoptionsScrollBar] = false
  elseif direction == "maximize" then
    lobby.clickables[self] = nil
    self.state = "maximizing"
    self.x, self.y = 2*lobby.width/3, lobby.fixturePoint[2].y + 35
    self.w, self.h = lobby.width - 2*lobby.width/3 , lobby.height - lobby.fixturePoint[2].y + 35
    self.dx, self.dy = 0, 0
    self.sw, self.sh = (-self.x)/10, (-self.y)/10
  end
  lobby.events[self] = true
end

function lobby.battleMiniWindow:update(dt)
  self.x = self.x + self.sw
  self.y = self.y + self.sh
  self.w = self.w - self.sw
  self.h = self.h - self.sh
  if self.state == "minimizing" and (self.x > self.dx or self.y > self.dy) then
    self.x = self.dx
    self.y = self.dy 
    self.w = lobby.width - self.x
    self.h = lobby.height - self.y
    lobby.events[self] = nil
    lobby.clickables[self] = true
  elseif self.state == "maximizing" and (self.x < 0 or self.y < 0) then
    self.x = 0
    self.y = 0
    self.w = lobby.width
    self.h = lobby.height
    lobby.state = "battle"
    lobby.events[self] = nil
    lobby.resize(lobby.width, lobby.height)
  end
end

function lobby.battleMiniWindow:click(x, y, b)
  if b ~= 1 then return false end
  if x > self.dx and y > self.dy then
    Battle.enter()
    return true
  end
  return false
end

function lobby.enter()
  if lobby.state == "battle" then
    lobby.battleMiniWindow:initialize("minimize")
  end
  lobby.clickables[lobby.backbutton] = false
  lobby.clickables[lobby.options.button] = true
  lobby.battlelist.scrollbar:setOffset(0)
  lobby.events[lobby.battlelist] = true
  lobby.state = "landing"
end

function lobby.refreshBattleTabs()
  lobby.battlelist.refresh()
end

local resize = {
  ["landing"] = function()
              lobby.battlelist.scrollbar:getZone()
              :setPosition(0, 90)
              :setDimensions(lobby.fixturePoint[2].x, lobby.fixturePoint[2].y - 90)
  end,
  ["battle"] = function()
              lobby.fixturePoint[1].x = 0
              for _, b in pairs(Battle:getActive().buttons) do
                b:resetPosition()
              end
              lobby.battlelist.scrollbar:getZone()
              :setPosition(0, 0)
              :setDimensions(0, 0)
  end,
  ["replays"] = function()
              Replay.initialize()
              lobby.fixturePoint[1].x = 0
  end
}

function lobby.resize( w, h )
  lobby.oldwidth = lobby.width
  lobby.oldheight = lobby.height
  lobby.width = w
  lobby.height = h
  lobby.fixturePoint = {
    {
      x = lobby.fixturePoint[1].x * lobby.width/lobby.oldwidth,
      y = lobby.fixturePoint[1].y * lobby.height/lobby.oldheight
    },
    {
      x = math.max(lobby.width - 200, math.min(lobby.width - 140, lobby.fixturePoint[2].x * lobby.width/lobby.oldwidth)),
      y = lobby.fixturePoint[2].y * lobby.height/lobby.oldheight
    }
  }
  
  lobby.close:setPosition(lobby.width-30, 0)
  lobby.maximize:setPosition(lobby.width-60, 0)
  lobby.minimize:setPosition(lobby.width-90, 0)
  
  lobby.canvas.battlemini = lg.newCanvas(lobby.width, lobby.height)
  lobby.canvas.battlelist = lg.newCanvas(lobby.width, lobby.height)
  lobby.canvas.background = lg.newCanvas(lobby.width, lobby.height)
  lobby.canvas.foreground = lg.newCanvas(lobby.width, lobby.height)
  lobby.canvas.userlist = lg.newCanvas(lobby.width, lobby.height)
  
  resize[lobby.state]()

  Channel.refresh()
  
  lobby.userlist.resize()
  lobby.battlelist.resize()
  lobby.render.background()
  lobby.render.foreground()
end

function lobby.pickCursor(x,y)
  if math.abs(y - lobby.fixturePoint[1].y) < 10 and x > lobby.fixturePoint[1].x and x < lobby.fixturePoint[2].x then
    love.mouse.setCursor(cursor[2])
  else
    love.mouse.setCursor(cursor[1])
  end
end

function lobby.mousemoved( x, y, dx, dy, istouch )
  draggable.move(dx, dy)
  lobby.pickCursor(x, y)
  local Ymin = 90*3 + 70 + 40
  local Ymax = lobby.height - 100
  if lobby.dragY then
    lobby.fixturePoint[1].y = math.min(Ymax, math.max(Ymin, y))
    lobby.fixturePoint[2].y = lobby.fixturePoint[1].y
    for _, chantab in pairs(ChannelTab.s) do
      chantab.y = chantab.y + dy
    end 
    if lobby.state == "battle" then
      for _, button in pairs(Battle:getActive().buttons) do
        button.y = button.y + dy
      end
    end
  end
  lobby.battlelist.refresh()
  local bool = false
  for _, bt in pairs(BattleTab.s) do
    bool = bt:isOver(x, y) or bool or false
  end
  if not bool then
    lobby.battleTabHover = nil
    lobby.battleTabHoverWindow = nil
  end
  --lobby.refreshUserButtons()
  if Channel:getActive() then
    Channel:getActive():render()
  end
  lobby.render.background()
  lobby.render.foreground()
end

lobby.clickables = {}

local function mrexit( )
  lobby.clickedBattleID = 0
  lobby.render.background()
end

function lobby.mousepressed(x,y,b)
  if draggable.start(x, y) then return end
  if math.abs(y - lobby.fixturePoint[1].y) < 10 and x > lobby.fixturePoint[1].x and x < lobby.fixturePoint[2].x  then
    lobby.dragY = true
  end
  for i, k in pairs(BattleTab.s) do
    if x > k.x and x < k.x + k.w and y > k.y and y < k.y + k.h then
      lobby.clickedBattleID = i
    end
  end
  local bool
  for sb in pairs(lobby.scrollBars) do
    bool = sb:mousepressed(x,y) or bool
  end
  if bool then lobby.renderOnUpdate = true end
end

function lobby.mousereleased(x,y,b)
  if draggable.stop() then return end
  if lobby.dropDown then
    lobby.dropDown:click(x,y)
    lobby.dropDown = nil
    lobby.renderOnUpdate = false
    return mrexit()
  end
  if lobby.dragY then
    lobby.dragY = false
    local battle = Battle:getActive()
    if battle then
      for _, button in pairs(battle.buttons) do
        button:resetPosition()
      end
    end
    Channel.refresh()
    lobby.battlelist.refresh()
    return
  end
  for sb in pairs(lobby.scrollBars) do
    sb.held = false
  end
  if not lobby.loginInfoEnd then return end
  for v, bool in pairs(lobby.clickables) do
    if bool then if v:click(x, y, b) then return mrexit() end end
  end
  if lobby.state == "landing" and y > 40 and y < lobby.fixturePoint[1].y then
    for id, bt in pairs(BattleTab.s) do
      if lobby.clickedBattleID == id then
        bt:click(x, y)
      end
    end
  end
  lobby.clickedBattleID = 0
  if y > lobby.fixturePoint[1].y then
    Channel:getTextbox().active = true
  else
    Channel:getTextbox().active = false
  end
  return mrexit()
end

lobby.scrollBars = {}
function lobby.wheelmoved(x, y)
  local msx, msy = love.mouse.getPosition()
  for sb, on in pairs(lobby.scrollBars) do
    if on and sb:getZone():isOver(msx, msy) then
      sb:scroll(y)
      sb:doRender(y)
    end
  end
  if Channel.active then
    if msx > Channel.x and msx < Channel.x + Channel.w and msy > Channel.y and msy < Channel.y + Channel.h then
      local sb = Channel.active.scrollBar
      if Channel.active.isBattle and msx > Channel.x + Channel.w*(2/3) then sb = Channel.active.infoBoxScrollBar end
      if y > 0 then
        sb:scrollUp()
      elseif y < 0 then
        sb:scrollDown()
      end
    end
  end
  lobby.render.background()
end

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
  io.popen(exec)
  love.window.restore( )
]]

function lobby.launchSpring()
  lobby.setReady(false)
  writeScript()
  local exec = "\"" .. lobby.exeFilePath .. "\" script.txt"
  if not lobby.springThread then
    lobby.springThread = love.thread.newThread( launchCode )
  end
  love.window.minimize( )
  lobby.springThread:start( exec )
end

lobby.events = {}
lobby.reeltimer = 0
lobby.timer = 0
local responses = require("response")
function lobby.update( dt )
  if not lobby.connected then
    return
  end
  -- Manual Garbage Collection
  local time_budget = 1/1000
  local safetynet_megabytes = 64
  local max_steps = 1000
	local steps = 0
	local start_time = love.timer.getTime()
	while
		love.timer.getTime() - start_time < time_budget and
		steps < max_steps
	do
		collectgarbage("step", 1)
		steps = steps + 1
	end
	if collectgarbage("count") / 1024 > safetynet_megabytes then
		collectgarbage("collect")
	end
  --
  
  -- Sleep if initialized and minimized 
  if lobby.loginInfoEnd and not love.window.hasFocus() then
    love.timer.sleep(0.2)
  end
  --
  
  local bool = false
  for event in pairs(lobby.events) do
    bool = event:update(dt) or bool
  end
  if bool then
    lobby.render.userlist()
    lobby.battlelist.refresh()
  end
  
  --scrollbars
  if lobby.renderOnUpdate then
    local _, y = love.mouse.getPosition()
    for sb in pairs(lobby.scrollBars) do
      if sb.held then
        sb:mousemoved(y)
      end
    end
    lobby.render.background()
  end
  
  Channel:getTextbox():update(dt)
  lobby.timer = lobby.timer + dt
  lobby.reeltimer = lobby.reeltimer + dt

  --receive data from server
  lobby.receiveData(dt)
  
  --for Map downloading
  local battle = Battle:getActive()
  if battle then battle:update(dt) end

end

function lobby.receiveData(dt)
  if lobby.timer > 30 then
    lobby.send("PING")
    lobby.timer = 0
  end
  lobby.timeSinceLastPong = lobby.timeSinceLastPong + dt
  if lobby.timeSinceLastPong > 120 then
    lobby.connected = false
    local txt = "Disconnected from server, last PONG over two minutes ago."
    table.insert(lobby.serverChannel.lines, {time = os.date("%X"), msg = txt})
    Channel:broadcast(txt)
    love.event.quit("restart")
  end
  local data = tcp:receive()
  if data then
    table.insert(lobby.serverChannel.lines, {time = os.date("%X"), from = true, msg = data})
    love.filesystem.append( "log.txt", data .. "\n" )
    local cmd = string.match(data, "^%u+")
    local words = {}
    local sentences = {}
    for sentance in string.gmatch(data, "[^\t]+") do
      table.insert(sentences, sentance)
    end
    local i = 0
    for word in string.gmatch(sentences[1], "%S+") do
      if i > 0 then 
        table.insert(words, word)
      end
      i = i + 1
    end
    if responses[cmd] then
      responses[cmd](words, sentences, data)
    end
  end
end

function lobby.textinput (text)
  if Channel:getTextbox():isActive() then
    Channel:getTextbox():addText(text)
  end
end

local keypress = require("keypress")
function lobby.keypressed(k, uni)
  if keypress[k] then keypress[k]() end
  lobby.render.background()
end

--[[function lobby.refreshUserButtons()
  local m = 30 -- lobby.userListScrollBar:getOffset()
  local y = 30
  local ymax = lobby.state == "landing" and lobby.height or lobby.fixturePoint[2].y
  local x = lobby.fixturePoint[2].x
  local fontHeight = fonts.latosmall:getHeight()
  local list = User.s
  local channel = Channel:getActive()
  if channel then 
    if channel.title == "server" then
      list = User.s
    elseif string.find(channel.title, "Battle_%d+") then
      list = Battle:getActiveBattle():getUsers()
    else
      list = channel.users
    end
  end
  UserButton.s = {}
  local c = 0
  local w = lobby.width - x
  for username, user in pairs(list) do
    if not user.isBot then
      m = m + fontHeight
      if m > ymax - y then return end
      if m > y then
        local UB = UserButton:new(username)
        UB:setPosition(x, m)
        UB:setDimensions(w, fontHeight)
        UB.flag = user.flag
        UB.icon = user.icon
        UB.insignia = user.insignia
        UserButton.s[UB] = true
      end
      c = c + 1
    end
  end
  if lobby.state == "landing" then
    --lobby.userListScrollBar:setPosition(lobby.width - 5, 50):setLength(lobby.height - 100)
  else
    --lobby.userListScrollBar:setPosition(lobby.width - 5, 50):setLength(lobby.fixturePoint[2].y - 100)
  end
  --lobby.userListScrollBar
  --:setPosition(lobby.width - 5, 90)
  --:setLength(lobby.height - 180)
  --:setScrollBarLength(50)
  --lobby.userListScrollBar:setOffsetMax(math.max(0, c - math.floor((ymax - y)/fontHeight)) * fontHeight)
  lobby.render.background()
end]]

lobby.state = "landing"

lobby.renderFunction = {
  ["landing"] = function()
    lg.setColor(colors.bb)
    lg.rectangle("fill",
                0,
                0,
                lobby.fixturePoint[2].x,
                40)
              
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.width,
                lobby.height - lobby.fixturePoint[1].y)
              
    lg.setColor(colors.bg)
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.width,
                38)
    lg.setColor(colors.bt)

    lg.setFont(fonts.latosmall)
    lg.print(lobby.battleTabSubText, 50, 25)
    lg.setColor(1,1,1)
  end,
  
  ["battle"] = function() 
    lg.setColor(colors.bb)
    lg.rectangle("fill",
                lobby.fixturePoint[1].x,
                lobby.fixturePoint[1].y,
                lobby.width - lobby.fixturePoint[1].x,
                lobby.height - lobby.fixturePoint[1].y)
    lg.setColor(colors.bg)
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.width,
                38)
    lg.setColor(colors.bt)
    lg.setColor(1,1,1)
    Battle:getActive():draw()
  end,
    
  ["replays"] = function()
    lg.setColor(colors.bb)
    lg.rectangle("fill",
                0,
                0,
                lobby.fixturePoint[2].x,
                40)
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.fixturePoint[2].x,
                lobby.height - lobby.fixturePoint[1].y)
    lg.setColor(colors.bg)
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.fixturePoint[2].x,
                38)
              
    lg.setColor(colors.bt)
    lg.setFont(fonts.latoboldbig)
    lg.print("Your Demos", 50, 15)
    
    for _, tab in pairs(ReplayTab.s) do
      tab:draw()
    end
  
    lg.setColor(1,1,1)
  end,
  
  
  ["options"] = function() end
}


function lobby.render.background()
  lg.setCanvas(lobby.canvas.background)
  lg.clear()
  
  lobby.renderFunction[lobby.state]()
  if Battle:getActive() and lobby.state ~= "battle" then
    lg.setCanvas(lobby.canvas.battlemini)
    lg.clear()
    --[[lg.setColor(colors.bd)
    lg.rectangle("fill", lobby.fixturePoint[2].x, lobby.fixturePoint[2].y, lobby.width - lobby.fixturePoint[2].x, lobby.height - lobby.fixturePoint[2].y)
    lg.setColor(colors.text)
    lg.rectangle("line", lobby.fixturePoint[2].x, lobby.fixturePoint[2].y, lobby.width - lobby.fixturePoint[2].x, lobby.height - lobby.fixturePoint[2].y)]]
    lobby.renderFunction["battle"]()
    if Channel:getActive() then
      Channel:getActive():render()
    end
    lobby.userlist.bar:draw()
    lg.setCanvas(lobby.canvas.background)
  end
  
  lobby.close:draw()
  lobby.minimize:draw()
  lobby.maximize:draw()
  
  if Channel:getActive() then
    Channel:getActive():render()
  end

  if lobby.state == "landing" then
    lobby.options.button:draw()
    if lobby.options.expanded then
      lobby.options.panel:draw()
    end
  else
    lobby.backbutton:draw()
  end
  
  if lobby.battleTabHoverWindow then lobby.battleTabHoverWindow:draw() end
  lg.setColor(1,1,1)
  lg.setCanvas()
end

function lobby.render.battlelist()
  lg.setCanvas(lobby.canvas.battlelist)
  lg.clear()
  for _, bt in pairs(BattleTab.s) do
    if bt.visible then bt:draw() end
  end
  lobby.battlelist.scrollbar:draw()
  lg.setCanvas()
end

function lobby.render.userlist()
  lg.setCanvas(lobby.canvas.userlist)
  lg.clear()
  lobby.userlist.bar:draw()
  lg.setCanvas()
end

function lobby.render.foreground()
  lg.setCanvas(lobby.canvas.foreground)
  lg.clear()
  for _, channel in pairs(Channel.s) do
    if channel.display then channel.tab:draw() end
  end
 Channel.addButton:draw() 
  
  --[[Hyperlink.s = {}
  for h in pairs(Hyperlink.s) do
    h:draw()
  end]]
  
  Channel.textbox:draw()
  
  if lobby.dropDown then lobby.dropDown:draw() end
  lg.setCanvas()
end

function lobby.draw()
  if not love.window.isVisible() then return end
  if lobby.state == "landing" then
    lg.draw(lobby.canvas.battlelist)
  end
  lg.draw(lobby.canvas.background)
  lg.draw(lobby.canvas.userlist)
  lg.draw(lobby.canvas.foreground)
  if lobby.state ~= "battle" and Battle:getActive() then
    lg.setFont(fonts.latoitalicmedium)
    lg.printf("Battle", 2*lobby.width/3 + 20, lobby.fixturePoint[2].y + 10, lobby.width - lobby.fixturePoint[2].y, "left")
    lg.draw(lobby.canvas.battlemini, lobby.battleMiniWindow.x, lobby.battleMiniWindow.y, 0, lobby.battleMiniWindow.w/lobby.width, lobby.battleMiniWindow.h/lobby.height)
    lg.draw(lobby.canvas.foreground, lobby.battleMiniWindow.x, lobby.battleMiniWindow.y, 0, lobby.battleMiniWindow.w/lobby.width, lobby.battleMiniWindow.h/lobby.height)
  end
  Channel.textbox:renderText()
end