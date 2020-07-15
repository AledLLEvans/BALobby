Button = {}
Button.mt =  {__index = Button}
local lg = love.graphics

Button.actives = {}

function Button:create(x,y,w,h,text,func)
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

function Button:click()
  self.func()
end

function Button:cancel()
  self.func = function() end
end

function Button:setFunc(func)
  self.func = func
end

ChannelTab = Button:create()
ChannelTab.mt =  {__index = ChannelTab}
ChannelTab.s = {}

function ChannelTab:create(x,y,w,h,text,func)
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
  local rect = "line"
  local h = 0
  if Channel:getActive()
  and (Channel:getActive().title == self.text
  or (string.find(Channel:getActive().title, "Battle") and "Battle" == self.text) )then
    rect = "fill"
    lg.setColor(0,0,0)
    h = 3
  end
  lg.rectangle(rect, self.x, self.y, self.w, self.h + h)
  lg.setColor(1,1,1)
  lg.printf(self.text, self.x, self.y + self.h/2 + h - fonts.robotosmall:getHeight()/2, self.w, "center")
end

BattleButton = Button:create()
BattleButton.mt = {__index = BattleButton}
BattleButton.s = {}
function BattleButton:create(id)
  local new = {}
  setmetatable(new, BattleButton.mt)
  
  new.visible = true
  new.battleid = id
  new.func = function()
    if Battle:getActiveBattle() then
      tcp:send("LEAVEBATTLE" .. "\n")
      Battle:getActiveBattle():getChannel().display = false
    end
    local sp = string.match(love.math.random(), "0%.(.*)")
    Battle.s[id].myScriptPassword = sp
    tcp:send("JOINBATTLE " .. id .. " " .. sp .."\n")
  end
  table.insert(self.s, new)
  return new
end

function BattleButton:draw()
  local battle = Battle.s[self.battleid]
  local y = self.y
  local x = self.x
  local w = self.w
  local h = self.h
  local fontHeight = fonts.robotosmall:getHeight()
  lg.setColor(1,1,1,0.75)
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
end
