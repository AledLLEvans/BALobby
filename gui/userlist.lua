userlist = {}

local lg = love.graphics

function userlist:initialize()
  userlist.bar = Button:new()
  userlist.bar.state = "shut"
  userlist.bar.openw = img["playerslist"]:getWidth()
  userlist.bar.shutw = img["playerslist_closed"]:getWidth()
  userlist.bar.openh = img["playerslist"]:getHeight()
  userlist.bar.shuth = img["playerslist_closed"]:getHeight()
  
  userlist.bar.openx = function() return lobby.width - lobby.fixturePoint[2].x end
  userlist.bar.shutx = function() return lobby.width - userlist.bar.shutw end
  
  userlist.bar.shutfunc = function() userlist.bar:open() end
  userlist.bar.openfunc = function() userlist.bar:shut() end
  
  userlist.bar.openspeed = function() return lobby.width/32 end
  userlist.bar.shutspeed = function() return lobby.width/25 end

  userlist.bar:setPosition(userlist.bar.shutx(), 32)

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
  
  function userlist.bar:draw()
    if self.state == "shut" then
      if lobby.darkMode then lg.draw(img["playerslist_closed"], self.x, self.y, 0, 1, lobby.fixturePoint[2].y/userlist.bar.shuth)
      else lg.draw(img["playerslist_closed_light"], self.x, self.y, 0, 1, lobby.fixturePoint[2].y/userlist.bar.shuth) end
      return
    end
    if lobby.darkMode then lg.draw(img["playerslist"], self.x, self.y)
    else lg.draw(img["playerslist_light"], self.x, self.y) end
    if self.state == "open" then
      lg.setColor(1,1,1)
      local fontHeight = fonts.latosmall:getHeight()
      local list = User.s
      local channel = Channel:getActive()
      lg.setFont(fonts.latobolditalicmedium)
      lg.setColor(colors.bt)
      local headtext = "Users online " .. User.count
      if channel then 
        if channel.title == "server" then
          list = User.s
        elseif channel.isBattle then
          headtext = "Users in Battle"
          if Battle:getActive() then
            list = Battle:getActive():getUsers()
          end
        else
          headtext = "Users in #" .. channel.title
          list = channel.users
        end
      end
      lg.printf(headtext, self.x + 30, self.y, self.w, "left")
      local x = self.x
      lg.setFont(fonts.latosmall)
      local m = 36
      for username, user in pairs(list) do
        m = m + fontHeight
        if m > lobby.width - 36 then return end
        lg.setColor(1,1,1)
        lg.draw(user.flag, x + 6, 12 + m)
        lg.draw(user.insignia, x + 25, 10 + m, 0, 1/5, 1/4)
        if user.icon then lg.draw(img[user.icon], x + 40, 10 + m, 0, 1/4) end
        lg.setColor(colors.text)
        lg.printf(username, x + 60, 10 + m, lobby.width - lobby.fixturePoint[2].x - 20)
      end
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
      if channel.title == "server" then
        list = User.s
      elseif channel.isBattle then
        if Battle:getActive() then
          list = Battle:getActive():getUsers()
        end
      else
        list = channel.users
      end
    end
    local fontHeight = fonts.latosmall:getHeight()
    local m = 36
    for username, user in pairs(list) do
      m = m + fontHeight
      if y > m + fontHeight and y < m + 2*fontHeight and x > lobby.fixturePoint[2].x + 60 and x < lobby.fixturePoint[2].x + 60 + fonts.latosmall:getWidth(username) then
        button[b](username, x, y)
        return true
      end
      if m > lobby.width - 36 - fontHeight then return false end
    end
    return false
  end
  lobby.clickables[userlist] = true
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

local function something()
  useristScrollBar = ScrollBar:new()
  :setScrollSpeed(15)
  :setRenderFunction(function() lobby.refreshUserButtons() end)
  lobby.userListScrollBar:getZone()
  :setPosition(lobby.fixturePoint[2].x, 0)
  :setDimensions(lobby.width - lobby.fixturePoint[2].x, lobby.height)
end

return userlist