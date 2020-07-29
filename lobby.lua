lobby = {}
local lg = love.graphics
local lk = love.keyboard
local base64 = require("base64")
local md5 = require("md5")
  
local address, port = "springfightclub.com", 8200


---- Courtesy of https://springrts.com/phpbb/viewtopic.php?t&t=32643 ----
function lobby.writeScript()
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

function lobby.declareColors()
  lobby.color = {}
  lobby.color.bg = {28/255, 28/255, 28/255}
  lobby.color.bb = {33/255, 33/255, 33/255}
  lobby.color.bt = {112/255, 112/255, 112/255}
  lobby.color.bargreen = {28/255, 252/255, 139/255}
end
lobby.declareColors()

lobby.MOTD = {}
function lobby.enter()
  lg.setBackgroundColor(lobby.color.bg)
  lobby.fixturePoint = {
    {x = 0, y = 2*lobby.height/3},
    {x = 660, y = 2*lobby.height/3}
  }  
  lobby.optionsButton = Button:new():setPosition(0, 0):setDimensions(36,36):onClick(function() lobby.optionsExpanded = not lobby.optionsExpanded end)
  function lobby.optionsButton:draw()
    if lobby.optionsExpanded then
      lg.draw(img["MenuExpanded"], self.x, self.y)
    else
      lg.draw(img["Menu"], self.x, self.y)
    end
  end
  lobby.clickables[lobby.optionsButton] = true
  
  lobby.resize( lobby.width, lobby.height )
  lobby.timeSinceLastPong = 0
  cursor[1] = love.mouse.getCursor( )
  
  Channel.textbox:setPosition(1, lobby.height - 21):setDimensions(lobby.fixturePoint[2].x - 2, 20)
  
  Channel:refreshTabs()
  
  lobby.serverChannel = Channel.s["server"]

  --Channel.active = lobby.serverChannel
  
  state = STATE_LOBBY
end

function lobby.mousepressed(x,y,b)
  if not b == 1 then return end
  if math.abs(x - lobby.fixturePoint[1].x) < 10 then
    --lobby.dragLeftX = true
  end
  if math.abs(x - lobby.fixturePoint[2].x) < 10 then
    lobby.dragRightX = true
  end
  if math.abs(y - lobby.fixturePoint[1].y) < 10 and x > lobby.fixturePoint[1].x and x < lobby.fixturePoint[2].x  then
    lobby.dragY = true
  end
  for i, k in pairs(BattleTab.s) do
    if x > k.x and x < k.x + k.w and y > k.y and y < k.y + k.h then
      lobby.clickedBattleID = i
    end
  end
  
end

function lobby.pickCursor(x,y)
  if math.abs(x - lobby.fixturePoint[2].x) < 10 then
    love.mouse.setCursor(cursor[3])
    return
  else
    love.mouse.setCursor(cursor[1])
  end
  if math.abs(y - lobby.fixturePoint[1].y) < 10 and x > lobby.fixturePoint[1].x and x < lobby.fixturePoint[2].x then
    love.mouse.setCursor(cursor[2])
  else
    love.mouse.setCursor(cursor[1])
  end
end

function lobby.mousemoved( x, y, dx, dy, istouch )
  lobby.pickCursor(x, y)
  if not lobby.dragLeftX and not lobby.dragRightX and not lobby.dragY then return end
  local leftMin = 20
  local leftMax = lobby.fixturePoint[2].x - 500
  local rightMin = lobby.state == "landing" and 260 or 260
  local rightMax = lobby.width - 140
  local Ymin = 90*3 + 70 + 40
  local Ymax = lobby.height - 100
  if lobby.dragLeftX then
    lobby.fixturePoint[1].x = math.min(leftMax, math.max(leftMin, x))
    for _, chantab in pairs(ChannelTab.s) do
      chantab.x = chantab.x + dx
    end
  end
  if lobby.dragRightX then
    lobby.fixturePoint[2].x = math.min(rightMax, math.max(rightMin, x))
    if Battle:getActive() then
      for _, button in pairs(Battle:getActive().buttons) do
        button.x = button.x + dx
      end
    end
  end
  if lobby.dragY then
    lobby.fixturePoint[1].y = math.min(Ymax, math.max(Ymin, y))
    lobby.fixturePoint[2].y = lobby.fixturePoint[1].y
    for _, chantab in pairs(ChannelTab.s) do
      chantab.y = chantab.y + dy
    end 
    if Battle:getActive() then
      for _, button in pairs(Battle:getActive().buttons) do
        button.y = button.y + dy
      end
    end
  end
  lobby.refreshUserButtons()
  lobby.refreshBattleTabs()
end

lobby.clickables = {}
function lobby.mousereleased(x,y,b) 
  if lobby.dragLeftX or lobby.dragRightX or lobby.dragY then
    lobby.dragLeftX, lobby.dragRightX, lobby.dragY = false, false, false
    Channel.refresh()
    lobby.refreshBattleTabs()
    return
  end
  if not lobby.loginInfoEnd then return end
  if b == 1 then
    for v in pairs(lobby.clickables) do
      if v:click(x,y) then break end
    end
    if y < lobby.fixturePoint[1].y or lobby.state == "battleWithList" then
      for i, k in pairs(BattleTab.s) do
        if lobby.clickedBattleID == i then
          k:click(x, y)
        end
      end
    end
    Channel:getTextbox():click(x, y)
    lobby.clickedBattleID = 0
  elseif b == 2 then

  end
  for button in pairs(UserButton.s) do
    button:click(x, y, b)
  end
  lobby.clickedBattleID = 0
  lobby.render()
end

lobby.battleTabOffset = 0
lobby.userListOffset = 0
lobby.userListOffsetMax = 0
function lobby.wheelmoved(x, y)
  local msx, msy = love.mouse.getPosition()
  --if lobby.state == "landing" then
  if msx < lobby.fixturePoint[2].x and msy < lobby.fixturePoint[1].y then
    if y < 0 then
      lobby.battleTabOffset = math.min((lobby.exr) * 90, lobby.battleTabOffset + 30)
    elseif y > 0 then
      lobby.battleTabOffset = math.max(0, lobby.battleTabOffset - 30)
    end
    lobby.refreshBattleTabs()
  end
  --end
  if msx > lobby.fixturePoint[2].x and msy < lobby.fixturePoint[2].y then
    if y < 0 then
      lobby.userListOffset = math.min(lobby.userListOffsetMax, lobby.userListOffset + 20)
    elseif y > 0 then
      lobby.userListOffset = math.max(0, lobby.userListOffset - 20)
    end
    lobby.refreshUserButtons()
  end
  if Channel.active then
    if msx > lobby.fixturePoint[1].x and msy > lobby.fixturePoint[1].y then
      if y > 0 then
        Channel.active.offset = math.min(#Channel.active.lines, Channel.active.offset + 1)
      elseif y < 0 then
        Channel.active.offset = math.max(0, Channel.active.offset - 1)
      end
    end
  end
  lobby.render()
end
  
lobby.reeltimer = 0
lobby.timer = 0
local responses = require("response")
function lobby.update( dt )
  if not lobby.connected then
    return
  end
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
  if login.downloading then
    login.updateDownload(dt)
  end
  if login.unpacking then
    login.updateUnpack(dt)
  end
  if lobby.loginInfoEnd and not love.window.hasFocus() then
    love.timer.sleep(0.2)
  end
  Channel:getTextbox():update(dt)
  lobby.timer = lobby.timer + dt
  lobby.reeltimer = lobby.reeltimer + dt

  --receive data from server
  lobby.receiveData(dt)
  
  --for Map downloading
  local battle = Battle:getActiveBattle()
  if battle then battle:update(dt) end
end

function lobby.receiveData(dt)
  if lobby.timer > 30 then
    lobby.send("PING" .. "\n")
    lobby.timer = 0
  end
  lobby.timeSinceLastPong = lobby.timeSinceLastPong + dt
  if lobby.timeSinceLastPong > 120 then
    lobby.connected = false
    local txt = "Disconnected from server, last PONG over two minutes ago."
    table.insert(lobby.serverChannel.lines, {time = os.date("%X"), msg = txt})
    Channel:broadcast(txt)
  end
  local data = tcp:receive()
  if data then
    table.insert(lobby.serverChannel.lines, {time = os.date("%X"), from = true, msg = data})
    love.filesystem.append( "log.txt", data .. "\n" )
    local cmd = string.match(data, "^%u+")
    local words = {}
    local sentances = {}
    for sentance in string.gmatch(data, "[^\t]+") do
      table.insert(sentances, sentance)
    end
    local i = 0
    for word in string.gmatch(sentances[1], "%S+") do
      if i > 0 then 
        table.insert(words, word)
      end
      i = i + 1
    end
    if responses[cmd] then
      responses[cmd].respond(words, sentances, data)
    end
    lobby.render()
  end
end

--[[lobby.width = 800
lobby.height = 600
lobby.fixturePoint = {
  {x = 250, y = 2*lobby.height/3},
  {x = 650, y = 2*lobby.height/3}
}]]

function lobby.resize( w, h )
  lobby.battleTabOffset = 0
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
      x = math.max(260, math.min(lobby.width - 140, lobby.fixturePoint[2].x * lobby.width/lobby.oldwidth)),
      y = lobby.fixturePoint[2].y * lobby.height/lobby.oldheight
    }
  }
  lobby.canvas = lg.newCanvas(lobby.width, lobby.height)
  if lobby.state == "battleWithList" then lobby.fixturePoint[1].x = 260 
  elseif lobby.state == "battle" then lobby.fixturePoint[1].x = 0 end
  if Battle:getActiveBattle() then
    Battle:getActiveBattle().buttons.spectate:setPosition(lobby.fixturePoint[2].x - 100, lobby.fixturePoint[2].y - 50)
    Battle:getActiveBattle().buttons.ready:setPosition(lobby.fixturePoint[2].x - 200, lobby.fixturePoint[2].y - 50)
    Battle:getActiveBattle().buttons.exit:setPosition(lobby.fixturePoint[2].x - 300, lobby.fixturePoint[2].y - 50)
  end
  Channel.refresh()
  lobby.refreshBattleTabs()
  lobby.refreshUserButtons()
end

function lobby.textinput (text)
  if Channel:getTextbox():isActive() then
    Channel:getTextbox():addText(text)
  end
  lobby.render()
end

local launchCode = [[
  local exec = ...
  os.execute(exec)
  love.window.restore( )
]]

local keypress = {
  ["c"] = function()
    if (lk.isDown("lctrl") or lk.isDown("rctrl")) and Channel:getTextbox():isActive() then
      love.system.setClipboardText( Channel:getTextbox():getText() )
    end
  end,
  ["v"] = function()
    if (lk.isDown("lctrl") or lk.isDown("rctrl")) and Channel:getTextbox():isActive() then
      Channel:getTextbox():addText(love.system.getClipboardText( ))
    end
  end,
  ["0"] = function()
    lobby.writeScript()
    local exec = "\"" .. lobby.exeFilePath .. "\"" .. " script.txt"
    if not lobby.springThread then
      lobby.springThread = love.thread.newThread( launchCode )
    end
    love.window.minimize( )
    lobby.springThread:start( exec )
  end,
  ["up"] = function()
    if lobby.channelMessageHistoryID then
      lobby.channelMessageHistoryID = math.max(1, lobby.channelMessageHistoryID - 1)
    else
      table.insert(Channel:getActive().sents, Channel:getActive():getText())
      lobby.channelMessageHistoryID = #Channel:getActive().sents
    end
    if Channel:getActive().sents[lobby.channelMessageHistoryID] then
      Channel:getActive():getTextbox():setText(Channel:getActive().sents[lobby.channelMessageHistoryID])
      Channel:getActive():getTextbox():toEnd()
    end
  end,
  ["down"] = function()
    if not lobby.channelMessageHistoryID then return end
    lobby.channelMessageHistoryID = math.min(lobby.channelMessageHistoryID + 1, #Channel:getActive().sents)
    if Channel:getActive().sents[lobby.channelMessageHistoryID] then
      Channel:getActive():getTextbox():setText(Channel:getActive().sents[lobby.channelMessageHistoryID])
      Channel:getActive():getTextbox():toEnd()
    end
  end,
  ["delete"] = function()
    Channel:getTextbox():delete()
  end,
  ["backspace"] = function()
    Channel:getTextbox():backspace()
  end,
  ["return"] = function()
    if Channel:getTextbox():isActive() then
      if Channel:getTextbox():getText() == "" then return end
      if Channel:getActive():getName() == "server" then
        lobby.send(Channel:getActive():getText() .. "\n")
        return
      end
      local cmd = "SAY"
      local to = " " .. Channel:getActive():getName() .. " "
      if string.find(Channel:getActive():getName(), "Battle") then
        cmd = cmd .. "BATTLE"
        to = " "
      elseif Channel:getActive():isUser() then
        cmd = cmd .. "PRIVATE"
      end
      local text, sub = string.gsub(Channel:getActive():getText(), "^/me ", "", 1)
      if sub == 1 then cmd = cmd .. "EX" end
      lobby.send(cmd .. to .. text .. "\n")
      lobby.channelMessageHistoryID = false
      table.insert(Channel:getActive().sents, Channel:getTextbox():getText())
      Channel:getTextbox():clearText()
    end
  end,
  ["tab"] = function() 
  end,
  ["escape"] = function()
    Battle.exit()
  end,
  ["left"] = function()
    if Channel:getActive() and Channel:getActive():getTextbox():isActive() then
      Channel:getActive():getTextbox():moveLeft()
    end
  end,
  ["right"] = function()
    if Channel:getActive() and Channel:getActive():getTextbox():isActive() then
      Channel:getActive():getTextbox():moveRight()
    end
  end
}

function lobby.keypressed(k, uni)
  if keypress[k] then keypress[k]() end
  lobby.render()
end

function lobby.refreshUserButtons()
  local m = 30 - lobby.userListOffset
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
  for username, user in pairs(list) do
    local w, wt = fonts.latosmall:getWrap(username, lobby.width - lobby.fixturePoint[2].x)
    m = m + #wt*fontHeight
    if m > ymax + 4*fontHeight then return end
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
  lobby.userListOffsetMax = math.max(0, c * fontHeight - (ymax - y))
  lobby.render()
end

function lobby.sortBattleIDsByPlayerCount()
  local battleIDs = {}
  local battleIDsByPlayerCount = {}
  for i in pairs(Battle.s) do
    table.insert(battleIDs, i)
  end
  while #battleIDs > 0 do
    local highestIndex
    local highestPlayerCount = -1
    local highestBattleID
    for index, battleid in pairs(battleIDs) do
      local playerCount = Battle.s[battleid].userCount
      if playerCount > highestPlayerCount then
        highestPlayerCount = playerCount
        highestIndex = index
        highestBattleID = battleid
      end
    end
    table.insert(battleIDsByPlayerCount, highestBattleID)
    table.remove(battleIDs, highestIndex)
  end
  return battleIDsByPlayerCount
end

function lobby.refreshBattleTabs()
  local BattleIDsByPlayerCount = lobby.sortBattleIDsByPlayerCount()
  for rank = 1, #BattleIDsByPlayerCount do
    Battle.s[BattleIDsByPlayerCount[rank]].rankByPlayerCount = rank
  end
  BattleTab.s = {}
  lobby.createBattleTabs(BattleIDsByPlayerCount)
end

lobby.battleTabDisplayRows = 1
lobby.battleTabDisplayCols = 1
lobby.exr = 1
lobby.battleTabSubText = ""
lobby.battleTabHeadText = "OPEN BATTLEROOMS"
local headTexts = {"OPEN BATTLEROOMS", "BATTLEROOMS", "OPEN BATTLES", "BATTLES", ""}
function lobby.createBattleTabs(BattleIDsByPlayerCount)
  local i = 1
  local y = 90-lobby.battleTabOffset
  local x = 0
  local xmin = 0
  local ymin = 10
  local ymax = lobby.height - y
  local xmax = lobby.fixturePoint[1].x
  if lobby.state == "landing" then
    ymax = lobby.fixturePoint[1].y
    xmax = lobby.fixturePoint[2].x
  end
  while y < ymax and x + 250 < xmax and i <= #BattleIDsByPlayerCount do
    if y >= ymin then
      local BattleTab = BattleTab:new(BattleIDsByPlayerCount[i])
      BattleTab:setPosition(x+5, y+5)
      BattleTab:setDimensions(240, 80)
    end 
    i = i + 1
    x = x + 250
    if x + 250 > xmax then
      x = xmin
      y = y + 90
    end
  end
  do
    local i = 0
    repeat
      i = i + 1
      lobby.battleTabHeadText = headTexts[i]
    until i == #headTexts or lobby.fixturePoint[2].x - 50 > fonts.notable:getWidth(headTexts[i])
  end
  lobby.battleTabSubText = "Showing " .. #BattleIDsByPlayerCount .. " battles."
  if not lobby.loginInfoEnd then
    lobby.battleTabSubText = lobby.battleTabSubText .. "(Loading .. )"
  end
  lobby.battleTabDisplayCols = math.floor((xmax-xmin)/250)
  lobby.battleTabDisplayRows = math.floor((ymax-ymin)/90) - 1
  lobby.exr = math.max(0, math.ceil(#BattleIDsByPlayerCount/lobby.battleTabDisplayCols) - lobby.battleTabDisplayRows)
  lobby.render()
end

lobby.state = "landing"

lobby.renderFunction = {
  ["landing"] = function()
    lg.setColor(1,1,1)
    lg.setFont(fonts.latosmall)
    for i, k in pairs(BattleTab.s) do
      k:draw()
    end
    lg.setColor(lobby.color.bb)
    lg.rectangle("fill",
                0,
                0,
                lobby.fixturePoint[2].x,
                90)
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.fixturePoint[2].x,
                lobby.height - lobby.fixturePoint[1].y)
    lg.setColor(lobby.color.bt)
    lg.line(0, 90, lobby.fixturePoint[2].x, 90)
    lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.height)
    lg.line(0, lobby.fixturePoint[1].y, lobby.fixturePoint[2].x, lobby.fixturePoint[1].y)
    local offsetmax = (lobby.exr) * 90
    local barlength = (lobby.fixturePoint[2].y - 90 - 40)
    local length = barlength/lobby.exr
    local y = (barlength-length)*(lobby.battleTabOffset/offsetmax)
    lg.line(lobby.fixturePoint[2].x - 5, 110, lobby.fixturePoint[2].x - 5, 110 + barlength)
    lg.setColor(lobby.color.bargreen)
    lg.line(lobby.fixturePoint[2].x - 5,
            110 + y,
            lobby.fixturePoint[2].x - 5,
            110 + y + length)
    lg.setColor(1,1,1)
    lg.setFont(fonts.notable)
    lg.print(lobby.battleTabHeadText, 50, 10)
    local h = fonts.notable:getHeight()
    lg.setFont(fonts.latosmall)
    lg.print(lobby.battleTabSubText, 50, 10 + h)
  end,
  
  ["battle"] = function() 
    lg.setColor(lobby.color.bb)
    lg.rectangle("fill",
                lobby.fixturePoint[1].x,
                lobby.fixturePoint[1].y,
                lobby.width - lobby.fixturePoint[1].x,
                lobby.height - lobby.fixturePoint[1].y)
    lg.setColor(lobby.color.bt)
    lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.fixturePoint[2].y)
    lg.line(0, lobby.fixturePoint[1].y, lobby.width, lobby.fixturePoint[1].y)
    lg.setColor(1,1,1)
    Battle:getActiveBattle():draw()
  end,
  
    ["battleWithList"] = function() 
    for i, k in pairs(BattleTab.s) do
      k:draw()
    end
    lg.setColor(lobby.color.bb)
    lg.rectangle("fill",
                lobby.fixturePoint[1].x,
                lobby.fixturePoint[1].y,
                lobby.width - lobby.fixturePoint[1].x,
                lobby.height - lobby.fixturePoint[1].y)
    lg.rectangle("fill",
                0,
                0,
                lobby.fixturePoint[1].x,
                90)
    lg.setColor(lobby.color.bt)
    lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.fixturePoint[2].y)
    lg.line(lobby.fixturePoint[1].x, lobby.fixturePoint[1].y, lobby.width, lobby.fixturePoint[1].y)
    lg.setColor(1,1,1)
    lg.setFont(fonts.notable)
    lg.print("BATTLES", 10, 50)
    lg.setFont(fonts.latoitalic)
    Battle:getActiveBattle():draw()
  end,
  
  ["options"] = function() end
}

function lobby.render()
  lg.setCanvas(lobby.canvas)
  lg.clear()
  
  lobby.renderFunction[lobby.state]()

  if Channel:getActive() then
    Channel:getActive():draw()
  end
  
  for i, k in pairs(Channel:getTabs()) do
    k:draw()
  end
  
  if Channel:getActive() then
    lg.print("Users in channel #" .. Channel:getActive():getName(),
      lobby.fixturePoint[2].x + 10,
      10)
  end

  lobby.optionsButton:draw()
  
  for button in pairs(UserButton.s) do
    button:draw()
  end
  
  --[[if lobby.cursorDropdown then
    lobby.cursorDropdown:draw()
  end]]
  
  if login.dl_status or login.unpackerCount > 0 then
    if not settings.engine_downloaded or not settings.engine_unpacked then
      login.drawDownloadBars()
    end
  end
  lg.setCanvas()
end

function lobby.draw()
  if not love.window.isVisible() then return end
  lg.draw(lobby.canvas)
  Channel.textbox:draw()
end