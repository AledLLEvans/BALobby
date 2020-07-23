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

function lobby.enter()
  lobby.timeSinceLastPong = 0
  cursor[1] = love.mouse.getCursor( )
  state = STATE_LOBBY
  
  lobby.fixturePoint = {
    {x = 250, y = 2*lobby.height/3},
    {x = 650, y = 2*lobby.height/3}
  }
  
  Channel.textbox:setPosition(lobby.fixturePoint[1].x, lobby.height - 20):setDimensions(lobby.fixturePoint[2].x - lobby.fixturePoint[1].x, 20)
  
  Channel:refreshTabs()
  
  lobby.serverChannel = Channel.s["server"]
end

function lobby.mousepressed(x,y,b)
  if not b == 1 then return end
  if math.abs(x - lobby.fixturePoint[1].x) < 10 then
    lobby.dragLeftX = true
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
    if math.abs(x - lobby.fixturePoint[1].x) < 10 or math.abs(x - lobby.fixturePoint[2].x) < 10 then
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
  lobby.pickCursor(x,y)
  local leftMin = 20
  local leftMax = lobby.fixturePoint[2].x - 500
  local rightMin = lobby.fixturePoint[1].x + 500
  local rightMax = lobby.width - 20
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
  end
  if lobby.dragY then
    lobby.fixturePoint[1].y = math.min(Ymax, math.max(Ymin, y))
    lobby.fixturePoint[2].y = lobby.fixturePoint[1].y
    for _, chantab in pairs(ChannelTab.s) do
      chantab.y = chantab.y + dy
    end
  end
end

function lobby.mousereleased(x,y,b)
  if lobby.dragLeftX or lobby.dragRightX or lobby.dragY then
    Channel:refreshTabs()
    Channel.textbox:setPosition(lobby.fixturePoint[1].x, lobby.height - 20):setDimensions(lobby.fixturePoint[2].x - lobby.fixturePoint[1].x, 20)
    lobby.refreshBattleList()
    lobby.dragLeftX, lobby.dragRightX, lobby.dragY = false, false, false
    return
  end
  if not b == 1 then return end
  Channel:getTextbox():click(x,y)
  for i, k in pairs(Channel.tabs) do
    k:click(x,y)
  end
  for i, k in pairs(BattleTab.s) do
    if lobby.clickedBattleID == i then
      k:click(x,y)
    end
  end
  lobby.clickedBattleID = 0
  if Battle:getActiveBattle() then
    Battle:getActiveBattle().buttons.spectate:click(x,y)
    Battle:getActiveBattle().buttons.ready:click(x,y)
  end
end
  
function lobby.wheelmoved(x, y)
  local msx, msy = love.mouse.getPosition()
  if msx > lobby.fixturePoint[1].x and msy > lobby.fixturePoint[1].y then
    if y > 0 then
      Channel.active.offset = math.min(#Channel.active.lines, Channel.active.offset + 1)
    elseif y < 0 then
      Channel.active.offset = math.max(0, Channel.active.offset - 1)
    end
  end
end
  
lobby.reeltimer = 0
lobby.timer = 0
local responses = require("response")
function lobby.update( dt )
  if not lobby.connected then
    return
  end
  --lobby.render()

  Channel:getTextbox():update(dt)
  lobby.timer = lobby.timer + dt
  lobby.reeltimer = lobby.reeltimer + dt

  --receive data from server
  lobby.receiveData(dt)
  
  --for Map downloading
  local battle = Battle:getActiveBattle()
  if battle then battle:update(dt) end
  if login.downloading then
    login.updateDownload(dt)
  end
  if login.unpacking then
    login.updateUnpack(dt)
  end
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
  end
end

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
      x = lobby.fixturePoint[2].x * lobby.width/lobby.oldwidth,
      y = lobby.fixturePoint[2].y * lobby.height/lobby.oldheight
    }
  }
  Channel:refreshTabs()
  Channel.textbox:setPosition(lobby.fixturePoint[1].x, lobby.height - 20):setDimensions(lobby.fixturePoint[2].x - lobby.fixturePoint[1].x, 20)
  lobby.refreshBattleList()
  if Battle:getActiveBattle() then
    Battle:getActiveBattle().buttons.spectate:setPosition(lobby.fixturePoint[2].x - 100, lobby.fixturePoint[2].y - 50)
    Battle:getActiveBattle().buttons.ready:setPosition(lobby.fixturePoint[2].x - 200, lobby.fixturePoint[2].y - 50)
  end
end

function lobby.textinput (text)
  if Channel:getTextbox():isActive() then
    Channel:getTextbox():addText(text)
  end
end

local launchCode = [[
  local exec = ...
  os.execute(exec)
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
    end
  end,
  ["down"] = function()
    if not lobby.channelMessageHistoryID then return end
    lobby.channelMessageHistoryID = math.min(lobby.channelMessageHistoryID + 1, #Channel:getActive().sents)
    if Channel:getActive().sents[lobby.channelMessageHistoryID] then
      Channel:getActive():getTextbox():setText(Channel:getActive().sents[lobby.channelMessageHistoryID])
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
    Battle:getActiveBattle().display = false
    lobby.send("LEAVEBATTLE" .. "\n")
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
end

function lobby.sortBattleIDsByPlayerCount()
  local battleIDs = {}
  local battleIDsByPlayerCount = {}
  for i, _ in pairs(Battle.s) do
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

function lobby.refreshBattleList()
  local BattleIDsByPlayerCount = lobby.sortBattleIDsByPlayerCount()
  for rank = 1, #BattleIDsByPlayerCount do
    Battle.s[BattleIDsByPlayerCount[rank]].rankByPlayerCount = rank
  end
  BattleTab.s = {}
  lobby.createBattleTabs(BattleIDsByPlayerCount)
end

function lobby.setSynced(b)
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

function lobby.createBattleTabs(BattleIDsByPlayerCount)
  local i = 1
  local y = 0
  local x = 0
  while y < lobby.height and x + 170 < lobby.fixturePoint[1].x and i < #BattleIDsByPlayerCount do
    local BattleTab = BattleTab:new(BattleIDsByPlayerCount[i])
    BattleTab:setPosition(x + 10, y+70)
    BattleTab:setDimensions(160, 80)
    i = i + 1
    y = y + 90
    if y + 90 + 90 > lobby.height then
      y = 0
      x = x + 170
    end
  end
end

function lobby.refreshPlayerReel()
  local t = ""
  for i = 1, #lobby.userList do
    t = t .. "  " .. lobby.userList[i].name
  end
  lobby.playerReelString = t
end
 
function lobby.updatePlayerReel()
  local t = math.floor(4*lobby.reeltimer)
  lobby.playerReelStringDisplay = string.sub(lobby.playerReelString, t, t + 60)
end

lobby.playerReelString = ""
lobby.playerReelStringDisplay = ""
function lobby.drawPlayerReel()
  lg.setFont(fonts.roboto)
  lg.print(lobby.playerReelStringDisplay, 100, 20)
  --[[for i, k in ipairs(lobby.userList) do
    lg.print(k.name, 100 + x, 20)
    x = fonts.roboto:getWrap( k.name .. "  ", 100) + x
  end]]
end
lobby.screens = {}
lobby.window = {}

function lobby.window.chat()
  if Channel:getActive() then
    Channel:getActive():draw(lobby.fixturePoint[1].x + 1, lobby.fixturePoint[1].y + 1,lobby.width - lobby.fixturePoint[1].x - 1, lobby.height - lobby.fixturePoint[1].y - 1)
  end
  for i, k in pairs(Channel:getTabs()) do
    k:draw()
  end
end

function lobby.window.battleList()
  lg.setFont(fonts.notable)
  local w = fonts.notable:getWidth("BATTLES")
  if w + 10 < lobby.fixturePoint[1].x then lg.print("BATTLES", 10, 10) end
  lg.setFont(fonts.latosmall)
  for i, k in pairs(BattleTab.s) do
    k:draw()
  end
end

function lobby.window.users()
  local i = 0
  local m = 0
  local x = lobby.fixturePoint[2].x
  local fontHeight = fonts.latosmall:getHeight()
  local list = User.s
  local channel = Channel:getActive()
  
  if channel then 
    if channel.title == "server" then
      lg.print("Users on the Server", lobby.fixturePoint[2].x + 10, 10)
      list = User.s
    elseif string.find(channel.title, "Battle_%d+") then
      lg.print("Users in this battle", lobby.fixturePoint[2].x + 10, 10)
      list = Battle:getActiveBattle():getUsers()
    else
      lg.print("Users in channel " .. channel.title, lobby.fixturePoint[2].x + 10, 10)
      list = channel.users
    end
  else
    lg.print("Users on the Server", lobby.fixturePoint[2].x + 10, 10)
  end
  
  for username, user in pairs(list) do
    --[[if lobby.fixturePoint[1].y + m + fontHeight > lobby.height then
      if x > lobby.fixturePoint[1].x then return end
      x = x + 100
      m = 0
    end]]
    local _, wt = fonts.latosmall:getWrap(username, lobby.width - lobby.fixturePoint[2].x)
    m = m + #wt*fontHeight
    if m > lobby.height then return end
    lg.draw(user.flag, x + 6, 12 + m)
    lg.draw(user.insignia, x + 25, 10 + m, 0, 1/5, 1/4)
    if user.icon then lg.draw(img[user.icon], x + 40, 10 + m, 0, 1/4) end
    lg.printf(username, x + 60, 10 + m, lobby.width - lobby.fixturePoint[2].x - 20, "left")
    i = i + 1
  end
end

--lobby.canvas = lg.newCanvas()
--[[function lobby.render()
  lobby.canvas:clear()
  lobby.canvas:renderTo(]]
function lobby.draw()
  --lg.draw(img["balanced+annihilation+big+loadscreen-min"], 0, 0)
      
  lg.line(lobby.fixturePoint[1].x, 0, lobby.fixturePoint[1].x, lobby.height)
  lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.height)
  lg.line(lobby.fixturePoint[1].x, lobby.fixturePoint[1].y, lobby.fixturePoint[2].x, lobby.fixturePoint[1].y)
  --lg.rectangle("line", 1, 1, lobby.fixturePoint[1].x-1, lobby.fixturePoint[1].y-1)
  --lg.rectangle("line", 1, lobby.fixturePoint[1].y+1, lobby.fixturePoint[1].x-1, lobby.height-lobby.fixturePoint[1].y-1)
  --lg.rectangle("line", lobby.fixturePoint[1].x+1, 1, lobby.width-lobby.fixturePoint[1].x-1, lobby.fixturePoint[1].y-1)
  --lg.rectangle("line", lobby.fixturePoint[1].x+1, lobby.fixturePoint[1].y+1, lobby.width-lobby.fixturePoint[1].x-1, lobby.height-lobby.fixturePoint[1].y-1)
  
  if Battle:getActiveBattle() then Battle:getActiveBattle():draw() end
  lobby.window.chat()
  lobby.window.battleList()
  lobby.window.users()
  
  if login.dl_status or login.unpackerCount > 0 then
    if not settings.engine_downloaded or not settings.engine_unpacked then
      login.drawDownloadBars()
    end
  end
end