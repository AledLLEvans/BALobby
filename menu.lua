local lg = love.graphics
local utf8 = require("utf8")
local base64 = require("base64")
local md5 = require("md5")

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
end

function Window:getPosition()
  return self.x, self.y
end

function Window:setDimensions(w, h)
  self.w = w or self.w
  self.h = h or self.h
end

function Window:getDimensions()
  return self.w, self.h
end

Button = Window:new()
Button.mt =  {__index = Button}

function Button:new()
  local o = {}
  setmetatable(o, Button.mt)
  o.text = ""
  o.clickSound = "click"
  
  o.func = function() end
  
  return o
end

function Button:setText(text)
  self.text = text
end

function Button:draw()
  local x, y = x or self.x, y or self.y
  lg.rectangle("line", x, y, self.w, self.h)
  lg.printf(self.text, x, y + self.h/2 - fonts.robotosmall:getHeight()/2, self.w, "center")
end

function Button:click(x,y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    sound[self.clickSound]:stop()
    sound[self.clickSound]:play()
    self.func()
  end
end

function Button:setFunction(func)
  self.func = func
end

PlayerButton = Button:new()
PlayerButton.mt = {__index = PlayerButton}
PlayerButton.s = {}
function PlayerButton:new(username)
  local o = {}
  setmetatable(o, PlayerButton.mt)
  o.username = username
  o.func = function()
    local PMbutton = Button:new()
    PMbutton:setText("Message")
    lobby.cursorDropdown = Dropdown:new()
    lobby.cursorDropdown:setPosition(love.mouse.getPosition())
    lobby.cursorDropdown:addButton(PMbutton)
    lobby.clickables[lobby.cursorDropdown] = true
  end

  return o
end

function PlayerButton:draw()
  lg.rectangle("line", self.x + 60, self.y + 10, self.w, self.h)
  lg.draw(self.flag, self.x + 6, 12 + self.y)
  lg.draw(self.insignia, self.x + 25, 10 + self.y, 0, 1/5, 1/4)
  if self.icon then lg.draw(img[self.icon], self.x + 40, 10 + self.y, 0, 1/4) end
  lg.printf(self.username, self.x + 60, 10 + self.y, lobby.width - lobby.fixturePoint[2].x - 20)
  if self.dropdown then
    self.dropdown:draw()
  end
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
  if Channel:getActive() and (channel == Channel:getActive().title) then
    h = 3
    lg.rectangle("fill", self.x, self.y, self.w, self.h + h)
    lg.setColor(0,0,0)
    lg.printf(self.text, self.x, self.y + self.h/2 + h - fonts.robotosmall:getHeight()/2, self.w, "center")
  elseif Channel.s[channel].newMessage then
    h = 3
    lg.rectangle("line", self.x, self.y, self.w, self.h + h)
    lg.printf(self.text, self.x, self.y + self.h/2 + h - fonts.robotosmall:getHeight()/2, self.w, "center")
  else
    lg.rectangle("line", self.x, self.y, self.w, self.h + h)
    lg.printf(self.text, self.x, self.y + self.h/2 + h - fonts.robotosmall:getHeight()/2, self.w, "center")
  end
  lg.setColor(1,1,1)
end

BattleTab = Button:new()
BattleTab.mt = {__index = BattleTab}
BattleTab.s = {}
function BattleTab:new(id)
  local new = Button:new()
  setmetatable(new, BattleTab.mt)
  
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

function BattleTab:draw()
  local battle = Battle.s[self.battleid]
  local y = self.y
  local x = self.x
  local w = self.w
  local h = self.h
  local fontHeight = fonts.robotosmall:getHeight()
  if User.s[battle.founder].ingame then
    lg.setColor(0,0.8,0.1,0.9)
  else
    lg.setColor(1,1,1,0.75)
  end
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(0,0,0)
  lg.rectangle("line", x, y, w, h)
  --lg.printf(battle.engineName, x-5, y+5, w, "center")
  --lg.printf(battle.gameName, x-5, y +10, w, "center")
  lg.printf(battle.title, x+60, y+5, w-60, "left")
  local _, wt = fonts.robotosmall:getWrap(battle.title,w-60)
  lg.printf(battle.mapName, x+5, y + h - fontHeight - 2, w-5, "left")
  lg.printf(battle.userCount - battle.spectatorCount + 1 .. "/" .. battle.maxPlayers .. " +" .. battle.spectatorCount, x+60, y+5+fontHeight*#wt + 1, w, "left")
  lg.setColor(1,1,1)
  if battle.minimap then
    lg.draw(battle.minimap, x + 4, y + 12, 0, 50/1024, 50/1024)
  else
    lg.draw(img["nomap"], x + 4, y + 15)
  end
  if User.s[battle.founder].ingame then
    lg.draw(img["gamepad"], x + w - 18, y + h - 16, 0, 1/4)
  end
end

BattleButton = Button:new()
BattleButton.mt = {__index = BattleButton}
BattleButton.s = {}
function BattleButton:new(x,y,w,h,text,func)
  local new = Button:new(x,y,w,h,text,func)
  setmetatable(new, BattleButton.mt)
  
  new.visible = true
  table.insert(self.s, new)
  return new
end

Dropdown = Window:new()
Dropdown.mt = {__index = Dropdown}
function Dropdown:new()
  local o = {}
  o.buttons = {}
  setmetatable(o, Dropdown.mt)
  return o
end

function Dropdown:addButton(button, part)
  part = part or 1
  local y = 4*part + 10*#self.buttons
  button:setPosition(self.x, y)
  button:setDimensions(100, 10)
  table.insert(self.buttons, button)
end

function Dropdown:click(x, y)
  for _, button in pairs(self.buttons) do
    button:click(x, y)
  end
end

function Dropdown:draw()
  for i, k in pairs(self.buttons) do
    k:draw()
  end
  lg.rectangle("line", self.x, self.y, self.w, self.h)
end