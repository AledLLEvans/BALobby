local battlezoom = {}

function battlezoom:initialize(direction)
  sound.dwoosh:stop()
  sound.dwoosh:play()
  if direction == "minimize" then
    self.state = "minimizing"
    self.x, self.y = 0, 0
    self.w, self.h = lobby.width, lobby.height
    self.dx, self.dy = 2*lobby.width/3, lobby.fixturePoint[2].y
    self.dw, self.dh = self.w - lobby.width/3, self.h - 35
    self:setText()
    lobby.scrollBars[Battle.mapScrollBar] = false
    lobby.scrollBars[Battle.spectatorsScrollBar] = false
    lobby.scrollBars[Battle.modoptionsScrollBar] = false
  elseif direction == "maximize" then
    self.x = 0
    self.y = 0
    self.w = lobby.width
    self.h = lobby.height
    self.state = "maximized"
    lobby.state = "battle"
    lobby.events[self] = nil
    lobby.resize(lobby.width, lobby.height)
  end
  lobby.events[self] = true
end

function battlezoom:update(dt)
  self.x = self.x + self.dx/12
  self.y = self.y + self.dy/12
  self.w = self.w - self.dw/12
  self.h = self.h - self.dh/12
  if self.state == "minimizing" and (self.x > self.dx or self.y > self.dy) then
    self.x = self.dx
    self.y = self.dy
    self.w = lobby.width - self.x
    self.h = 35
    self.state = "minimized" 
    lobby.events[self] = nil
    lobby.clickables[self] = true
  elseif self.state == "maximizing" and (self.x < 0 or self.y < 0) then
    --[[self.x = 0
    self.y = 0
    self.w = lobby.width
    self.h = lobby.height
    self.state = "maximized" 
    lobby.state = "battle"
    lobby.events[self] = nil
    lobby.resize(lobby.width, lobby.height)]]
  end
end

function battlezoom:setText()
  self.text = "Click here to return to battle: " .. Battle:getActive().title
  local b = false
  while fonts.latoitalicmedium:getWidth(self.text) > lobby.width - lobby.fixturePoint[2].x - 10 do
    self.text = self.text:sub(0, -2)
    b = true
  end
  if b then self.text = self.text .. ".." end
end
  
function battlezoom:click(x, y, b)
  if b ~= 1 then return false end
  if x > self.x and y > self.y then
    Battle.enter()
    return true
  end
  return false
end

function battlezoom:resize(w, h)
  if Battle:getActive() and self.state == "minimized" then
    self.x, self.y = 2*lobby.width/3, lobby.fixturePoint[2].y
    self.w, self.h = lobby.width/3, 35
    self:setText()
  end
end

return battlezoom
