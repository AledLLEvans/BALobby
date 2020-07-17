Button = {}
Button.mt =  {__index = Button}
local lg = love.graphics

Button.actives = {}

function Button:new(x,y,w,h,text,func)
  local o = {}
  setmetatable(o, Button.mt)
  o.type = "default"
  o.x = x or 0
  o.y = y or 0
  o.w = w or 160
  o.h = h or 100
  o.text = text or ""
  o.visible = false
  
  o.func = func or function() end
  
  return o
end

function Button:setPos(x, y)
  self.x, self.y = x, y
end

function Button:setDimensions(w,h)
  self.w, self.h = w, h
end

function Button:activate()
  self.visible = true
  table.insert(self.actives, self)
end

function Button:draw()
  lg.rectangle("line", self.x, self.y, self.w, self.h)
  lg.printf(self.text, self.x, self.y + self.h/2 - fonts.robotosmall:getHeight()/2, self.w, "center")
end

function Button:releaseAll()
  self.actives = {}
end

function Button:click(x,y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    sound["click"]:stop()
    sound["click"]:play()
    self.func()
  end
end

function Button:setFunc(func)
  self.func = func
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
  local new = Button:new(id)
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
