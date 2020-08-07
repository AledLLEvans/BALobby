local lg = love.graphics
local utf8 = require("utf8")
local base64 = require("base64")
local md5 = require("md5")

ScrollBar = {}
ScrollBar.mt = {__index = ScrollBar}

function ScrollBar:new()
  local new = {}
  setmetatable(new, ScrollBar.mt)
  
  new.x = 0
  new.y = 0
  
  new.length = 0
  new.innerLength = 0
  
  new.inverted = false
  
  new.held = false
  
  new.offset = 0
  new.offsetmax = 0
  
  new.sspeed = 1
  
  new.zone = Window:new()
  
  new.func = function() lobby.render() end
  
  new.vertical = true
  new.horizontal = not new.vertical
  
  new.colors = {
    main = {112/255, 112/255, 112/255},
    inner = {28/255, 252/255, 139/255}
  }
  
  lobby.scrollBars[new] = true
  
  return new
end

function ScrollBar:setRenderFunction(func)
  self.func = func
  return self
end

function ScrollBar:doRender(y)
  self.func(y)
  return self
end

function ScrollBar:getZone()
  return self.zone
end

function ScrollBar:setScrollBarLength(l)
  self.innerLength = l
  return self
end

function ScrollBar:setOffset(o)
  self.offset = o
  return self
end

function ScrollBar:setOffsetMax(o)
  self.offsetmax = o
  return self
end

function ScrollBar:mousemoved(y)
  print("offset", self.offset)
  print("length", self.length)
  self.offset = math.max(0, math.min(self.offsetmax, self.offsetmax * (y - self.y) / (self.length)))
end

function ScrollBar:mousepressed(x,y)
  self.held = false
  if x < self.x - 3 or x > self.x + 3 then
    return false
  end
  if self.inverted and y < self.y and y > self.y + self.length then
    self.held = true
    return true
  elseif y > self.y and y < self.y + self.length then
    self.held = true
    return true
  end
  return false
end

function ScrollBar:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
  return self
end

function ScrollBar:setLength(l)
  self.length = l
  if l > 0 then
    self.inverted = false
  else
    self.inverted = true
  end
  return self
end

function ScrollBar:getOffset()
  return self.offset
end

function ScrollBar:getOffsetMax()
  return self.offsetmax
end

function ScrollBar:setScrollSpeed(s)
  self.sspeed = s
  return self
end

function ScrollBar:getScrollSpeed()
  return self.sspeed
end

function ScrollBar:scroll(y)
  if y < 0 then
    for i = -1, y, -1 do
      self:scrollUp()
    end
  elseif y > 0 then
    for i = 1, y do 
      self:scrollDown()
    end
  end
  return self
end

function ScrollBar:scrollUp()
  self:setOffset(math.min(self:getOffsetMax(), self:getOffset() + self:getScrollSpeed()))
  return self
end

function ScrollBar:scrollDown()
  self:setOffset(math.max(0, self:getOffset() - self:getScrollSpeed()))
  return self
end

function ScrollBar:draw()
  local d = (self.length - self.innerLength)*(self.offset/(self.offsetmax))
  lg.setLineWidth(4)
  lg.setColor(self.colors.main)
  lg.line(self.x,
          self.y,
          self.x + (self.horizontal and self.length or 0),
          self.y + (self.vertical and self.length or 0))
  lg.setColor(self.colors.inner)
  lg.line(self.x + (self.horizontal and d or 0),
          self.y + (self.vertical and d or 0),
          self.x + (self.horizontal and d + self.innerLength or 0),
          self.y + (self.vertical and d + self.innerLength or 0))
  lg.setLineWidth(1)
  lg.setColor(1,1,1)
end

Window = {}
Window.mt = {__index = Window}

function Window:new(o)
  o = o or {}
  o.x = 0
  o.y = 0
  o.w = 10
  o.h = 10
  
  setmetatable(o, Window.mt)
  return o
end

function Window:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
  return self
end

function Window:getPosition()
  return self.x, self.y
end

function Window:setDimensions(w, h)
  self.w = w or self.w
  self.h = h or self.h
  return self
end

function Window:getDimensions()
  return self.w, self.h
end

function Window:isOver(x, y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    return true
  end
  return false
end

Button = Window:new()
Button.mt =  {__index = Button}

function Button:new()
  local o = {}
  setmetatable(o, Button.mt)
  
  o.font = fonts.latoitalic
  o.str = ""
  o.text = lg.newText( o.font )
  o.clickSound = "click"
  o.colors = {
    background = colors.bb,
    text = colors.text
  }
  
  o.func = function() end
  
  return o
end

function Button:setFont(font)
  self.text:setFont(font)
  return self
end

function Button:setText(str)
  self.str = str
  self.text:setf(str, self.w, "center")
  return self
end

function Button:setDimensions(w,h)
  self.w = w or self.w
  self.h = h or self.h
  self.text:setf(self.str, self.w, "center")
  return self
end

function Button:draw()
  lg.setColor(self.colors.background)
  lg.rectangle("fill", self.x, self.y, self.w, self.h)
  lg.setColor(self.colors.text)
  lg.setFont(self.font)
  lg.draw(self.text, self.x, self.y + self.h/2 - self.font:getHeight()/2)
end


function Button:click(x, y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    --sound[self.clickSound]:stop()
    --sound[self.clickSound]:play()
    self.func()
    return true
  end
  return false
end

function Button:setFunction(func)
  self.func = func
  return self
end

function Button:setBackgroundColor(c)
  self.colors.background = c
  return self
end

function Button:setTextColor(c)
  self.colors.text = c
  return self
end

function Button:onClick(func)
  self.func = func
  return self
end

Checkbox = Button:new()
Checkbox.mt =  {__index = Checkbox}
Checkbox.s = {}

function Checkbox:new()
  local o = Button:new()
  setmetatable(o, Checkbox.mt)
  o.font = fonts.latoitalic
  o.text = lg.newText( o.font )
  o.ticked = false
  o.color = {
    back = colors.bb,
    outline = colors.bt,
    inside = colors.bt
  }
  
  self.func = function() self.ticked = not self.ticked end
  
  lobby.clickables[o] = true
  
  return o
end

function Checkbox:setToggleVariable(f)
  self.checkfunc = f
  return self
end

function Checkbox:setText(str)
  self.text:set(str)
  return self
end

function Checkbox:draw()
  lg.setColor(self.color.back)
  lg.rectangle("fill", self.x, self.y, self.w, self.h)
  lg.setColor(self.color.outline)
  lg.rectangle("line", self.x, self.y, self.w, self.h)
  if self.checkfunc() then
    lg.setColor(self.color.inside)
    lg.rectangle("fill", self.x + 4, self.y + 4, self.w - 8, self.h - 8)
  end
  lg.setFont(self.font)
  lg.setColor(colors.text)
  lg.draw(self.text, self.x + self.w + 2, self.y)
end

Hyperlink = Button:new()
Hyperlink.mt =  {__index = Hyperlink}
Hyperlink.s = {}

function Hyperlink:new()
  local o = {}
  setmetatable(o, Hyperlink.mt)
  o.text = ""
  o.color = {6/255, 69/255, 173/255}
  
  Hyperlink.s[o] = true
  return o
end

function Hyperlink:click(x, y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    local success = love.system.openURL(self.text)
    if success then self.color = {11/255, 0/255, 128/255} end
    return success
  end
  return false
end

function Hyperlink:draw()
  lg.setFont(fonts.latosmall)
  lg.setColor(self.color)
  lg.line(self.x, self.y + self.h, self.x + self.w, self.y + self.h)
  lg.print(self.text, self.x, self.y)
  lg.setColor(1,1,1)
end

ChannelTab = Button:new()
ChannelTab.mt =  {__index = ChannelTab}
ChannelTab.s = {}

function ChannelTab:new(x,y,w,h,text,func)
  local o = {}
  setmetatable(o, ChannelTab.mt)
  o.type = "default"
  o.x = x or 0
  o.y = y or 0
  o.w = w or 160
  o.h = h or 100
  o.text = text or ""
  o.visible = false
  
  o.func = func or function() end
  
  self.s[o.text] = o
  
  return o
end

function ChannelTab:draw()
  local h = 0
  local channel = self.text
  if channel == "Battle" then
    channel = Battle:getActiveBattle():getChannel().title
  end
  local text = "#" .. self.text
  if Channel:getActive() and (channel == Channel:getActive().title) then
    lg.setColor(colors.bb)
    lg.rectangle("fill", self.x, self.y-1, self.w, self.h + h+1)
    lg.setColor(colors.text)
    lg.setFont(fonts.latochantabbold)
    lg.printf(text, self.x, self.y + self.h/2 + h - fonts.latochantabbold:getHeight()/2, self.w, "center")
  elseif Channel.s[channel].newMessage then
    --h = 3
    lg.setColor(colors.bg)
    lg.setFont(fonts.latochantabbold)
    lg.rectangle("fill", self.x, self.y, self.w, self.h + h)
    lg.setColor(colors.bt)
    lg.printf(text, self.x, self.y + self.h/2 + h - fonts.latochantabbold:getHeight()/2, self.w, "center")
  else
    lg.setFont(fonts.latochantab)
    lg.setColor(colors.bg)
    lg.rectangle("fill", self.x, self.y, self.w, self.h + h)
    lg.setColor(colors.bt)
    lg.printf(text, self.x, self.y + self.h/2 + h - fonts.latochantab:getHeight()/2, self.w, "center")
  end
  lg.setFont(fonts.robotosmall)
  lg.setColor(1,1,1)
end

BattleTab = Button:new()
BattleTab.mt = {__index = BattleTab}
BattleTab.s = {}
function BattleTab:new(id)
  local new = Button:new()
  setmetatable(new, BattleTab.mt)
  
  new.colors = {
    background = {
      default = colors.bb,
      highlight = colors.bd
    }   
  }
  new.highlighted = false
  new.visible = true
  new.battleid = id
  new.func = function()
    if Battle:getActiveBattle() then
      tcp:send("LEAVEBATTLE" .. "\n")
      Battle:getActiveBattle():getChannel().display = false
    end
    local sp = string.match(love.math.random(), "0%.(.*)")
    Battle.s[id].myScriptPassword = sp
    tcp:send("JOINBATTLE " .. id .. " EMPTY " .. sp .."\n")
  end
  table.insert(self.s, new)
  return new
end

function BattleTab:isOver(x,y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    lobby.battleTabHover = self
    lobby.battleTabHoverTimer = 0.9
    self.highlighted = true
    return true
  end
  self.highlighted = false
  return false
end

function BattleTab:draw()
  local battle = Battle.s[self.battleid]
  local y = self.y
  local x = self.x
  local w = self.w
  local h = self.h
  lg.setFont(fonts.latosmall) 
  local fontHeight = fonts.latosmall:getHeight()
  if self.highlighted then
    lg.setColor(self.colors.background.highlight)
  else
    lg.setColor(self.colors.background.default) 
  end
  lg.rectangle("fill", x, y, w, h)
  -- BATTLE TITLE
  lg.setColor(colors.text)
  lg.printf(battle.title, x + h + 5, y+5, w/2, "left")
  -- PLAYER/SPEC COUNTS
  local pcount = math.max(0, battle.userCount - battle.spectatorCount + 1)
  local maxpcount = "/" .. battle.maxPlayers
  local scount = math.max(0, battle.spectatorCount - 1)
  lg.setColor(1,1,1)
  if pcount == 0 then
    lg.setColor(colors.bt)
    lg.draw(img["players_zero"], x + w/2, y + h/2 + 5, 0, 1, 1, 41/2, 44/2)
  elseif lobby.darkMode then
    lg.draw(img["playersDark"], x + w/2, y + h/2 + 5, 0, 1, 1, 41/2, 44/2)
    lg.setColor(colors.bargreen)
  else
    lg.draw(img["playersLight"], x + w/2, y + h/2 + 5, 0, 1, 1, 41/2, 44/2)
    lg.setColor(colors.bargreen)
  end
  local by = y + h/2 - fonts.latoboldbiggest:getHeight()/2 + 5
  lg.setFont(fonts.latoboldbigger)
  lg.print(maxpcount, x + w/2 + 45 + fonts.latoboldbiggest:getWidth(pcount), y + h/2)
  lg.setFont(fonts.latoboldbiggest)
  lg.print(pcount, x + w/2 + 40, by)
  lg.setColor(colors.bt)
  lg.print(scount, x + w - fonts.latoboldbiggest:getWidth(scount) - 25, by)
  lg.setColor(colors.text)
  lg.draw(img.eye, x + w - fonts.latoboldbiggest:getWidth("00") - 45, y + h/2)
  -- MAP NAME
  lg.setFont(fonts.latolightitalic)
  local mapName = battle.mapName
  local _, wt = fonts.latolightitalic:getWrap(mapName .. "..", w/2)
  if #wt > 1 then
    lg.print(wt[1], x + h + 5, y + h - fontHeight - 2)
  else
    lg.print(mapName, x + h + 5, y + h - fontHeight - 2)
  end
  -- IMAGES
  lg.setColor(colors.bd)
  lg.rectangle("fill", x, y, h, h)
  lg.setFont(fonts.latosmall)
  lg.setColor(1,1,1)
  if battle.minimap then
    local modx = math.min(1, battle.mapWidthHeightRatio)
    local mody = math.min(1, 1/battle.mapWidthHeightRatio)
    lg.draw(battle.minimap, x - (modx-1)*h/2, y - (mody-1)*h/2, 0,
      modx*h/1024, mody*h/1024)
  else
    lg.draw(img["nomap"], x + 25, y + 25)
  end
  lg.setColor(colors.text)
  if battle.founder.ingame then
    lg.draw(img["gamepad"], x + w - 18, y + 1, 0, 1/4)
  end
end

BattleTabHoverWindow = Window:new()
BattleTabHoverWindow.mt = {__index = BattleTabHoverWindow}
function BattleTabHoverWindow:new(battleid)
  local new = {}
  new.battle = Battle.s[battleid]
  setmetatable(new, BattleTabHoverWindow.mt)
  
  return new
end

function BattleTabHoverWindow:draw()
  local battle = self.battle
  if battle.userCount == 0 then
    return
  end
  local msx, msy = love.mouse.getPosition()
  lg.setFont(fonts.latosmall)
  local fontHeight = fonts.latosmall:getHeight()
  local y = msy + 10
  lg.setColor(colors.bb, 0.5)
  lg.rectangle("fill", msx, y+8, 140, fontHeight*battle.userCount + 2)
  lg.setColor(colors.text)
  lg.rectangle("line", msx, y+8, 140, fontHeight*battle.userCount + 2)
  for _, user in pairs(battle.users) do
    lg.setColor(1,1,1)
    lg.draw(user.flag, msx + 2, y + 10)
    lg.draw(user.insignia, msx + 21, y + 8, 0, 1/5, 1/4)
    if user.icon then lg.draw(img[user.icon], msx + 42, y + 8, 0, 1/4) end
    lg.setColor(colors.text)
    lg.print(user.name, msx + 56, y + 8)
    y = y + fontHeight
  end
end

BattleButton = Button:new()
BattleButton.mt = {__index = BattleButton}
function BattleButton:new()
  local new = Button:new()
  setmetatable(new, BattleButton.mt)
  
  new.font = fonts.latoitalicmedium
  new.text:setFont(new.font)
  lobby.clickables[new] = true
  return new
end

function Button:resetPosition(f)
  if f then
    self.resetFunc = f
  end
  self:setPosition(self.resetFunc())
  return self
end

UserButton = Button:new()
UserButton.mt = {__index = UserButton}
UserButton.s = {}
function UserButton:new(username)
  local o = {}
  setmetatable(o, UserButton.mt)
  o.username = username
  o.func = function()
    self.dropdown = Dropdown:new():setPosition(love.mouse.getPosition())
    self.dropdown:addButton(Button:new():setText("Message"):onClick(function() User.s[username]:openChannel() end))
    if User.s[username].ignoring then
      self.dropdown:addButton(Button:new():setText("UnIgnore"):onClick(function() User.s[username].ignoring = false end), 2)
    else
      self.dropdown:addButton(Button:new():setText("Ignore"):onClick(function() User.s[username].ignoring = true end), 2)
    end
    self.dropdown.parent = self
    lobby.dropDown = self.dropdown
    --UserButton.s[self] = true
    lobby.render()
  end
  return o
end

function UserButton:click(x, y, b)
  if b == 2 and x > self.x + 60 and x < self.x + self.w + 60 and y > self.y + 10 and y < self.y + 10 + self.h then
    self.func()
    return true
  end
  return false
end

function UserButton:draw()
  lg.setFont(fonts.latosmall)
  lg.setColor(1,1,1)
  --lg.rectangle("line", self.x + 60, self.y + 10, self.w, self.h)
  lg.draw(self.flag, self.x + 6, 12 + self.y)
  lg.draw(self.insignia, self.x + 25, 10 + self.y, 0, 1/5, 1/4)
  lg.setColor(colors.text)
  if self.icon then lg.draw(img[self.icon], self.x + 40, 10 + self.y, 0, 1/4) end
  lg.printf(self.username, self.x + 60, 10 + self.y, lobby.width - lobby.fixturePoint[2].x - 20)
end

Dropdown = Window:new()
Dropdown.mt = {__index = Dropdown}
function Dropdown:new()
  local o = {}
  o.buttons = {}
  o.button_count = 0
  setmetatable(o, Dropdown.mt)
  return o
end

function Dropdown:addButton(button, part)
  part = part or 1
  local y = self.y + 4*(part-1) + 21*self.button_count
  button:setPosition(self.x, y)
  button:setDimensions(100, 20)
  self.buttons[button] = true
  self.button_count = self.button_count + 1
  self.parts = math.max(1, part)
  self:setDimensions(100, 21*self.button_count + 4*(self.parts-1))
end

function Dropdown:click(x, y)
  for button in pairs(self.buttons) do
    button:click(x, y)
  end
end

function Dropdown:draw()
  lg.setColor(colors.bt)
  lg.rectangle("fill", self.x, self.y, self.w, self.h)
  for button in pairs(self.buttons) do
    button:draw()
  end
end