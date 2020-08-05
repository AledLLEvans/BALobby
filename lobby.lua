lobby = {}
local lg = love.graphics
local lk = love.keyboard
local base64 = require("base64")
local md5 = require("md5")
  
local address, port = "springfightclub.com", 8200

lobby.MOTD = {}
function lobby.enter()
  state = STATE_LOBBY
  Channel.textbox = Textbox:new()
  lg.setBackgroundColor(colors.bg)
  lobby.fixturePoint = {
    {x = 0, y = 2*lobby.height/3},
    {x = 660, y = 2*lobby.height/3}
  } 
  lobby.optionsButton = Button:new()
  :setPosition(0, 0)
  :setDimensions(36,36)
  :onClick(function()
    lobby.optionsExpanded = not lobby.optionsExpanded
    lobby.clickables[lobby.optionsPanel] = not lobby.clickables[lobby.optionsPanel]
  end)
  
  lobby.optionsPanel = Dropdown:new()
  :setPosition(0, 36)
  :setDimensions(163,174)
  
  lobby.optionsExpanded = false
  lobby.clickables[lobby.optionsPanel] = false
  
  lobby.optionsPanel:addButton(Button:new():setText("Switch Mode")
    :setFunction(function()
          if lobby.darkMode then
            setLightMode()
            lobby.darkMode = false
            lobby.lightMode = true
            settings.add({mode = "light"})
            Channel.textbox.colors.background = colors.bg
            Channel.textbox.colors.text = colors.text
            local battle = Battle:getActive()
            if battle then
              for i, k in pairs(battle.buttons) do
                k.colors.background = colors.bb
                k.colors.text = colors.text
              end
            end
          else
            setDarkMode()
            lobby.darkMode = true
            lobby.lightMode = false
            settings.add({mode = "dark"})
            Channel.textbox.colors.background = colors.bg
            Channel.textbox.colors.text = colors.text
            local battle = Battle:getActive()
            if battle then
              for i, k in pairs(battle.buttons) do
                k.colors.background = colors.bb
                k.colors.text = colors.text
              end
            end
          end
          lobby.render()
        end))
    
    lobby.optionsPanel:addButton(Button:new():setText("Open Spring Directory")
    :setFunction(function()
          love.system.openURL(lobby.springFilePath)
        end))
    
    lobby.optionsPanel:addButton(Button:new():setText("Options")
    :setFunction(function()
            
          lobby.render()
        end))
  
  lobby.clickables[lobby.optionsButton] = true
    
  function lobby.optionsButton:draw()
    if lobby.darkMode then
      lg.draw(img["MenuButtonDark"], self.x, self.y)
    else
      lg.draw(img["MenuButtonLight"], self.x, self.y)
    end
  end
  
  lobby.battleTabScrollBar = ScrollBar:new()
  :setScrollSpeed(25)
  :setRenderFunction(function() lobby.refreshBattleTabs() end)
  lobby.battleTabScrollBar:getZone()
  :setPosition(0, 90)
  :setDimensions(lobby.fixturePoint[2].x, lobby.fixturePoint[2].y - 90)
  
  lobby.userListScrollBar = ScrollBar:new()
  :setScrollSpeed(15)
  :setRenderFunction(function() lobby.refreshUserButtons() end)
  lobby.userListScrollBar:getZone()
  :setPosition(lobby.fixturePoint[2].x, 0)
  :setDimensions(lobby.width - lobby.fixturePoint[2].x, lobby.height)
  
  lobby.serverChannel = Channel.s["server"]

  Channel.active = lobby.serverChannel
  
  lobby.resize( lobby.width, lobby.height )
  lobby.timeSinceLastPong = 0
  cursor[1] = love.mouse.getCursor( )
  
  --Channel.textbox:setPosition(1, lobby.height - 21):setDimensions(lobby.fixturePoint[2].x - 2, 20)
  
end

function lobby.mousepressed(x,y,b)
  if math.abs(y - lobby.fixturePoint[1].y) < 10 and x > lobby.fixturePoint[1].x and x < lobby.fixturePoint[2].x  then
    lobby.dragY = true
  end
  for i, k in pairs(BattleTab.s) do
    if x > k.x and x < k.x + k.w and y > k.y and y < k.y + k.h then
      lobby.clickedBattleID = i
    end
  end
  for sb in pairs(lobby.scrollBars) do
    sb:mousepressed(x,y)
  end
  lobby.renderOnUpdate = true
end

function lobby.pickCursor(x,y)
  if math.abs(y - lobby.fixturePoint[1].y) < 10 and x > lobby.fixturePoint[1].x and x < lobby.fixturePoint[2].x then
    love.mouse.setCursor(cursor[2])
  else
    love.mouse.setCursor(cursor[1])
  end
end

function lobby.mousemoved( x, y, dx, dy, istouch )
  lobby.pickCursor(x, y)
  local Ymin = 90*3 + 70 + 40
  local Ymax = lobby.height - 100
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
  if Channel:getActive() then
    Channel:getActive():render()
  end
  lobby.render()
end

lobby.clickables = {}
function lobby.mousereleased(x,y,b)
  lobby.renderOnUpdate = false
  for sb in pairs(lobby.scrollBars) do
    sb.held = false
  end
  if lobby.dragY then
    lobby.dragY = false
    if Battle:getActiveBattle() then
      Battle:getActiveBattle().buttons.spectate:resetPosition()
      Battle:getActiveBattle().buttons.ready:resetPosition()
      Battle:getActiveBattle().buttons.exit:resetPosition()
      Battle:getActiveBattle().buttons.start:resetPosition()
    end
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
    for h in pairs(Hyperlink.s) do
      h:click(x,y)
    end
  elseif b == 2 then

  end
  for button in pairs(UserButton.s) do
    button:click(x, y, b)
  end
  lobby.clickedBattleID = 0
  lobby.render()
end

lobby.scrollBars = {}
function lobby.wheelmoved(x, y)
  local msx, msy = love.mouse.getPosition()
  for sb in pairs(lobby.scrollBars) do
    if sb:getZone():isIn(msx, msy) then
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
  local battle = Battle:getActive()
  if battle then battle:update(dt) end
  if lobby.renderOnUpdate then
    local _, y = love.mouse.getPosition()
    for sb in pairs(lobby.scrollBars) do
      if sb.held then
        sb:mousemoved(y)
      end
    end
    lobby.render()
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
      responses[cmd].respond(words, sentences, data)
    end
    lobby.render()
  end
end

local resize = {
  ["landing"] = function()
              lobby.battleTabScrollBar:getZone()
              :setPosition(0, 90)
              :setDimensions(lobby.fixturePoint[2].x, lobby.fixturePoint[2].y - 90)
  end,
  ["battle"] = function()
              lobby.fixturePoint[1].x = 0
              for _, b in pairs(Battle:getActiveBattle().buttons) do
                b:resetPosition()
              end
              lobby.battleTabScrollBar:getZone()
              :setPosition(0, 0)
              :setDimensions(0, 0)
  end,
  ["battleWithList"] = function()
              lobby.fixturePoint[1].x = 260
              for _, b in pairs(Battle:getActiveBattle().buttons) do
                b:resetPosition()
              end
              lobby.battleTabScrollBar:getZone()
              :setPosition(0, 90)
              :setDimensions(lobby.fixturePoint[1].x, lobby.height)
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
  lobby.canvas = lg.newCanvas(lobby.width, lobby.height)
  
  resize[lobby.state]()

  Channel.refresh()
  lobby.refreshBattleTabs()
  lobby.refreshUserButtons()
end

function lobby.textinput (text)
  if Channel:getTextbox():isActive() then
    Channel:getTextbox():addText(text)
  end
end

local keypress = require("keypress")

function lobby.keypressed(k, uni)
  if keypress[k] then keypress[k]() end
  lobby.render()
end

function lobby.refreshUserButtons()
  local m = 30 - lobby.userListScrollBar:getOffset()
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
    lobby.userListScrollBar:setPosition(lobby.width - 5, 50):setLength(lobby.height - 100)
  else
    lobby.userListScrollBar:setPosition(lobby.width - 5, 50):setLength(lobby.fixturePoint[2].y - 100)
  end
  lobby.userListScrollBar
  :setPosition(lobby.width - 5, 90)
  :setLength(lobby.height - 180)
  :setScrollBarLength(50)
  lobby.userListScrollBar:setOffsetMax(math.max(0, c - math.floor((ymax - y)/fontHeight)) * fontHeight)
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
lobby.battleTabSubText = ""
lobby.battleTabHeadText = "OPEN BATTLEROOMS"
local headTexts = {"OPEN BATTLEROOMS", "BATTLEROOMS", "OPEN BATTLES", "BATTLES", ""}
function lobby.createBattleTabs(BattleIDsByPlayerCount)
  local i = 1
  local y = 90 - lobby.battleTabScrollBar:getOffset()
  local x = 0
  local xmin = 0
  local ymin = - 10
  local ymax = lobby.height - y
  local xmax = lobby.fixturePoint[1].x
  if lobby.state == "landing" then
    ymax = lobby.fixturePoint[1].y
    xmax = lobby.fixturePoint[2].x
  end
  lobby.battleTabDisplayCols = math.floor((xmax - xmin) / 610)
  local w = (xmax - xmin) / lobby.battleTabDisplayCols
  local c = 1
  while y < ymax and i <= #BattleIDsByPlayerCount do
    if y >= ymin then
      BattleTab:new(BattleIDsByPlayerCount[i])
      :setPosition(x+8, y+5)
      :setDimensions(w - 16, 100)
    end 
    i = i + 1
    x = x + w
    c = c + 1
    if c > lobby.battleTabDisplayCols then
      c = 1
      x = xmin
      y = y + 110
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
  lobby.battleTabDisplayRows = math.floor((ymax-ymin)/110) - 1
  local len = lobby.fixturePoint[2].y - 90
  local sblen = math.max(0, math.ceil(#BattleIDsByPlayerCount/lobby.battleTabDisplayCols) - lobby.battleTabDisplayRows)
  lobby.battleTabScrollBar
  :setPosition(lobby.fixturePoint[2].x - 3, 90)
  :setLength(len)
  :setScrollBarLength(len/sblen)
  :setOffsetMax(sblen * 110)
  
  lobby.render()
end

lobby.state = "landing"

lobby.renderFunction = {
  ["landing"] = function()
    for i, k in pairs(BattleTab.s) do
      k:draw()
    end
    --
    lg.setColor(colors.bb)
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
    lg.setColor(colors.bg)
    lg.rectangle("fill",
                0,
                lobby.fixturePoint[1].y,
                lobby.fixturePoint[2].x,
                23)
    lg.setColor(colors.bt)
    --lg.line(0, 90, lobby.fixturePoint[2].x, 90)
    --lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.height)
    --lg.line(0, lobby.fixturePoint[1].y, lobby.fixturePoint[2].x, lobby.fixturePoint[1].y)
    --
    lobby.battleTabScrollBar:draw()
    --
    lg.setColor(colors.bt)
    lg.setFont(fonts.notable)
    lg.print(lobby.battleTabHeadText, 50, 10)
    local h = fonts.notable:getHeight()
    lg.setFont(fonts.latosmall)
    lg.print(lobby.battleTabSubText, 50, 10 + h)
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
                23)
    lg.setColor(colors.bt)
    --lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.fixturePoint[2].y)
    --lg.line(0, lobby.fixturePoint[1].y, lobby.width, lobby.fixturePoint[1].y)
    lg.setColor(1,1,1)
    Battle:getActive():draw()
  end,
  
    ["battleWithList"] = function() 
    for i, k in pairs(BattleTab.s) do
      k:draw()
    end
    lg.setColor(colors.bb)
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
    lg.setColor(colors.bg)
    lg.rectangle("fill",
                lobby.fixturePoint[1].x,
                lobby.fixturePoint[1].y,
                lobby.width - lobby.fixturePoint[1].x,
                23)
    lg.setColor(colors.bt)
    --lg.line(lobby.fixturePoint[2].x, 0, lobby.fixturePoint[2].x, lobby.fixturePoint[2].y)
    --lg.line(lobby.fixturePoint[1].x, lobby.fixturePoint[1].y, lobby.width, lobby.fixturePoint[1].y)
    lg.setColor(colors.bt)
    lg.setFont(fonts.notable)
    lg.print("BATTLES", 10, 50)
    lg.setFont(fonts.latoitalic)
    lg.setColor(1,1,1)
    Battle:getActiveBattle():draw()
  end,
  
  ["options"] = function() end
}

function lobby.render()
  lg.setCanvas(lobby.canvas)
  lg.clear()
  
  Hyperlink.s = {}
  
  if Channel:getActive() then
    lg.setColor(colors.text)
    lg.setFont(fonts.latosmall)
    lg.print("Users in channel #" .. Channel:getActive():getName(),
            lobby.fixturePoint[2].x + 10, 10)
  end
  
  lobby.renderFunction[lobby.state]()
  
  Channel.textbox:draw()
  lg.setLineWidth(0.5)
  lobby.userListScrollBar:draw()
  
  if Channel:getActive() then
    Channel:getActive():render()
  end
  
  for i, k in pairs(Channel:getTabs()) do
    k:draw()
  end
  
  for h in pairs(Hyperlink.s) do
    h:draw()
  end

  lobby.optionsButton:draw()
  if lobby.optionsExpanded then
    lobby.optionsPanel:draw()
  end
  
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
  lg.setColor(1,1,1)
  lg.setCanvas()
end

function lobby.draw()
  if not love.window.isVisible() then return end
  lg.draw(lobby.canvas)
  Channel.textbox:renderText()
end