userlist = {}

local lg = love.graphics

function userlist:initialize()
  userlist.bar = Button:new()
  userlist.bar.state = "shut"
  userlist.bar.openw = img["playerslistBlue"]:getWidth()
  userlist.bar.shutw = img["playerslist_closedBlue"]:getWidth()
  userlist.bar.openh = img["playerslistBlue"]:getHeight()
  userlist.bar.shuth = img["playerslist_closedBlue"]:getHeight()
  
  userlist.bar.openx = function() return lobby.width - lobby.fixturePoint[2].x end
  userlist.bar.shutx = function() return lobby.width - userlist.bar.shutw end
  
  userlist.bar.shutfunc = function() userlist.bar:open() end
  userlist.bar.openfunc = function() userlist.bar:shut() end
  
  userlist.bar.openspeed = function() return lobby.width/32 end
  userlist.bar.shutspeed = function() return lobby.width/25 end

  userlist.bar:setPosition(userlist.bar.shutx(), 32)
  
  userlist.scrollBar = ScrollBar:new()
  :setPosition(lobby.width - 5, 54)
  :setLength(lobby.fixturePoint[2].y - 54)
  :setScrollBarLength(30)
  :setRenderFunction(function() lobby.render.userlist() end)
  userlist.scrollBar:getZone()
  :setPosition(lobby.fixturePoint[2].x, 32)
  :setDimensions(lobby.width - lobby.fixturePoint[2].x, lobby.fixturePoint[2].y - 32)
  
  lobby.scrollBars[userlist.scrollBar] = true
    
  function userlist.bar:shut()
    if self.state ~= "open" then return end
    sound.userlist:play()
    self.w = userlist.bar.shutw
    self.h = userlist.bar.shuth
    lobby.fixturePoint[2].x = lobby.width - userlist.bar.shutw
    if lobby.state == "battle" then Battle:getActive():resetButtons() end
    self.func = self.shutfunc
    self.state = "shutting"
    lobby.clickables[userlist] = nil
    lobby.events[self] = true
    lobby.scrollBars[userlist.scrollBar] = nil
  end
  
  function userlist.bar:open()
    if self.state ~= "shut" then return end
    sound.userlist:play()
    self.w = userlist.bar.openw
    self.h = userlist.bar.openh
    lobby.fixturePoint[2].x = 3*lobby.width/4
    if lobby.state == "battle" then Battle:getActive():resetButtons() end
    self.func = self.openfunc
    self.state = "opening"
    lobby.clickables[userlist] = true
    lobby.events[self] = true
    lobby.scrollBars[userlist.scrollBar] = true
  end
  
  function userlist.bar:update(dt)
    if self.state == "shutting" then
      self.x = self.x + self.shutspeed()
      if self.x > self.shutx() then
        self.x = self.shutx()
        self.state = "shut"
        lobby.events[self] = nil
      end
    elseif self.state == "opening" then
      self.x = self.x - self.openspeed()
      if self.x < lobby.fixturePoint[2].x then
        self.x = lobby.fixturePoint[2].x
        self.state = "open"
        lobby.events[self] = nil
      end
    end
    return true
  end
  
  function userlist.bar:drawChannelList()
    lg.printf("Channel List", self.x + 30, self.y, self.w, "left")
    local fontHeight = fonts.latobold:getHeight()
    local x = self.x
    lg.setFont(fonts.latobold)
    local m = 36 - userlist.scrollBar:getOffset()
    for channel_name, users in pairs(lobby.channels) do
      m = m + fontHeight
      if m > lobby.width - 36 then return end
      lg.setColor(colors.text)
      lg.printf("#" .. channel_name, x + 60, 10 + m, lobby.width - lobby.fixturePoint[2].x - 20)
      lg.printf(users, x + 40, 10 + m, lobby.width - lobby.fixturePoint[2].x - 20)
      if m > lobby.fixturePoint[2].y - fontHeight then break end
    end
  end
  
  local drawBackRect = {
    [true] = function(x,y,w,fh) lg.setColor(colors.bbb) lg.rectangle("fill", x, y, w, fh) end,
    [false] = function() end
  }

  function userlist.bar:draw()
    lg.setColor(1,1,1)
    if self.state == "shut" then
      if lobby.darkMode then lg.draw(img["playerslist_closedBlue"], self.x, self.y, 0, 1, (lobby.fixturePoint[2].y-30)/userlist.bar.shuth)
      else lg.draw(img["playerslist_closed_light"], self.x, self.y, 0, 1, lobby.fixturePoint[2].y/userlist.bar.shuth) end
      return
    end
    if lobby.darkMode then lg.draw(img["playerslistBlue"], self.x, self.y) else lg.draw(img["playerslist_light"], self.x, self.y) end
    if self.state == "open" then
      lg.setColor(1,1,1)
      local list = User.s
      local channel = Channel:getActive()
      lg.setFont(fonts.latoboldbig)
      lg.setColor(colors.bt)
      lg.setColor(colors.bbb)
      local fontHeight = fonts.latobold:getHeight()
      local headtext = "Users online " .. User.count
      if channel then 
        if channel.isServer then
          list = User.s
        elseif channel.isBattle then
          headtext = "Users in Battle"
          if Battle:getActive() then
            list = Battle:getActive():getUsers()
          end
        elseif channel.isChannel then
          headtext = "Users in #" .. channel.title
          list = channel.users
        else
          headtext = "Private"
          list = channel.users
        end
      else
        self:drawChannelList()
        return
      end
      lg.printf(headtext, self.x + 30, self.y, self.w, "left")
      local w = lobby.width - lobby.fixturePoint[2].x - 20
      local x = self.x
      lg.setFont(fonts.latobold)
      local m = 36 - userlist.scrollBar:getOffset()
      local t = 0
      local c = 0
      local msx, msy = love.mouse.getPosition()
      for username, user in pairs(list) do
        m = m + fontHeight
        t = t + 1
        if m < lobby.fixturePoint[2].y - fontHeight and m > 36 then
          drawBackRect[c % 2 == 1](x, m+12, w, fontHeight)
          if msy > m + fontHeight and msy < m + 2*fontHeight and msx > lobby.fixturePoint[2].x + 60 and msx < lobby.fixturePoint[2].x + 60 + fonts.latobold:getWidth(username) then
            lg.setColor(colors.bt) lg.rectangle("fill", x+60, m+12, fonts.latobold:getWidth(username), fontHeight)
          end
          c = c + 1
          lg.setColor(1,1,1)
          lg.draw(user.flag, x + 6, 12 + m)
          lg.draw(user.insignia, x + 25, 10 + m, 0, 1/2)
          if user.icon then lg.draw(img[user.icon], x + 40, 10 + m, 0, 1/2) end
          lg.setColor(colors.text)
          lg.printf(username, x + 60, 10 + m, w)
        end
      end
      userlist.scrollBar:setScrollSpeed(fontHeight):setOffsetMax(math.max(0, t - c) * fontHeight):draw()
    end
  end

  userlist.bar:open()
  lobby.clickables[userlist.bar] = true
  
  local button = {
    [2] = function(username, x, y)
      lobby.dropDown = Dropdown:new():setPosition(x,y)
      lobby.dropDown:addButton(Button:new():setText("Message"):onClick(function() User.s[username]:openChannel() end))
      if User.s[username].ignoring then
        lobby.dropDown:addButton(Button:new():setText("UnIgnore"):onClick(function() User.s[username].ignoring = false end), 2)
      else
        lobby.dropDown:addButton(Button:new():setText("Ignore"):onClick(function() User.s[username].ignoring = true end), 2)
      end
      lobby.render.foreground()
    end,
    [1] = function(username)
      User.s[username]:openChannel()
    end}
  
  function userlist:click(x, y, b)
    if b < 1 or b > 2 then return end
    if x < lobby.fixturePoint[2].x then return false end
    local list = User.s
    local channel = Channel:getActive()
    if channel then 
      if channel.isServer then
        list = User.s
      elseif channel.isBattle then
        if Battle:getActive() then
          list = Battle:getActive():getUsers()
        end
      else
        list = channel.users
      end
    else
      return self:channel_click(x, y)
    end
    local fontHeight = fonts.latobold:getHeight()
    local m = 36 - userlist.scrollBar:getOffset()
    for username, user in pairs(list) do
      m = m + fontHeight
      if y > m + fontHeight and y < m + 2*fontHeight and x > lobby.fixturePoint[2].x + 60 and x < lobby.fixturePoint[2].x + 60 + fonts.latobold:getWidth(username) then
        button[b](username, x, y)
        return true
      end
      if m > lobby.width - 36 - fontHeight then return false end
    end
    return false
  end
  
  function userlist:channel_click(x, y)
    local fontHeight = fonts.latobold:getHeight()
    local m = 36 - userlist.scrollBar:getOffset()
    for channel_name in pairs(lobby.channels) do
      m = m + fontHeight
      if y > m + fontHeight and y < m + 2*fontHeight and x > lobby.fixturePoint[2].x + 60 and x < lobby.fixturePoint[2].x + 70 + fonts.latobold:getWidth(channel_name)  then
        if Channel.s[channel_name] then
          Channel.s[channel_name]:open()
          Channel:refreshTabs()
        else
          lobby.send("JOIN " .. channel_name)
        end
        return true
      end
      if m > lobby.width - 36 - fontHeight then return false end
    end
    return false
  end
  
  lobby.clickables[userlist] = true
end

function userlist:isOver(x,y)
  if x < lobby.fixturePoint[2].x then return false end
  if y < 36 then return false end
  if y > lobby.fixturePoint[2].y then return false end
  return true
end

function userlist.resize()
  if userlist.bar.state == "shut" then
    lobby.fixturePoint[2].x = lobby.width - userlist.bar.shutw
    userlist.bar:setPosition(lobby.fixturePoint[2].x, 32)
  else
    
    lobby.fixturePoint[2].x = 3*lobby.width/4
    userlist.bar:setPosition(3*lobby.width/4, 32)
    --lobby.fixturePoint[2].x = 3*lobby.width/4
    --userlist.bar:setPosition(userlist.bar.shutx(), 32)
    --userlist.bar.state = "shut"
    --userlist.bar:open()
  end
  lobby.render.userlist()
end

return userlist