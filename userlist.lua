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
  
  userlist.bar.openspeed = function() return lobby.width/20 end
  userlist.bar.shutspeed = function() return lobby.width/15 end

  userlist.bar:setPosition(userlist.bar.shutx(), 2)

  function userlist.bar:shut()
    if self.state ~= "open" then return end
    self.w = userlist.bar.shutw
    self.h = userlist.bar.shuth
    lobby.fixturePoint[2].x = lobby.width - userlist.bar.shutw
    self.func = self.shutfunc
    self.state = "shutting"
    lobby.events[self] = true
  end
  
  function userlist.bar:open()
    if self.state ~= "shut" then return end
    self.w = userlist.bar.openw
    self.h = userlist.bar.openh
    lobby.fixturePoint[2].x = 3*lobby.width/4
    self.func = self.openfunc
    self.state = "opening"
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
      lg.draw(img["playerslist_closed"], self.x, self.y)
      return
    end
    lg.draw(img["playerslist"], self.x, self.y)
    if self.state == "open" then
      lg.setFont(fonts.latobolditalic)
      lg.setColor(colors.bt)
      lg.printf("Players: ", self.x + 30, self.y, self.w, "left")
      lg.setColor(1,1,1)
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
      local x = self.x
      lg.setFont(fonts.latosmall)
      local m = 36
      for username, user in pairs(list) do
        m = m + fontHeight
        if m > lobby.width - 36 then return end
        lg.setColor(1,1,1)
        lg.draw(user.flag, x + 6, 12 + m)
        lg.draw(user.insignia, x + 25, 10 + m, 0, 1/5, 1/4)
        lg.setColor(colors.text)
        if user.icon then lg.draw(img[user.icon], x + 40, 10 + m, 0, 1/4) end
        lg.printf(username, x + 60, 10 + m, lobby.width - lobby.fixturePoint[2].x - 20)
      end
    end
  end
  
  userlist.bar:open()
  lobby.clickables[userlist.bar] = true
end

function userlist.resize()
  if userlist.bar.state == "open" then
    lobby.fixturePoint[2].x = 3*lobby.width/4
    userlist.bar:setPosition(userlist.bar.shutx(), 2)
    userlist.bar.state = "shut"
    userlist.bar:open()
  elseif userlist.bar.state == "shut" then
    lobby.fixturePoint[2].x = lobby.width - userlist.bar.shutw
    userlist.bar:setPosition(userlist.bar.shutx(), 2)
  end
  lobby.render.userlist()
end

local function something()
  lobby.useristScrollBar = ScrollBar:new()
  :setScrollSpeed(15)
  :setRenderFunction(function() lobby.refreshUserButtons() end)
  lobby.userListScrollBar:getZone()
  :setPosition(lobby.fixturePoint[2].x, 0)
  :setDimensions(lobby.width - lobby.fixturePoint[2].x, lobby.height)

end

return userlist