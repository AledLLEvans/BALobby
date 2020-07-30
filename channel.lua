Channel = {}
Channel.mt =  {__index = Channel}
local lg = love.graphics

Channel.s = {}
Channel.tabs = {}
Channel.textbox = Textbox:new()
Channel.x = 0
Channel.y = 0
Channel.w = 10
Channel.h = 10

function Channel:new(o, bool)
  setmetatable(o, Channel.mt)
  
  o.font = fonts.latosmall
  o.scrollBar = ScrollBar:new():setScrollBarLength(-20):setScrollSpeed(o.font:getHeight())
  o.lines = {}
  o.users = {} 
  o.sents = {}
  o.display = true
  o.text = ""
  
  if not bool then self.s[o.title] = o end
  return o
end

ServerChannel = Channel:new({title = "server"})
BattleChannel = Channel:new({title = "battle"}, true)
BattleChannel.mt = {__index = BattleChannel}

function BattleChannel:new(o)
  o = Channel:new(o)
  o.isBattle = true
  o.infolines = {}
  o.infoBoxScrollBar = ScrollBar:new():setScrollBarLength(-20):setScrollSpeed(o.font:getHeight())
  setmetatable(o, BattleChannel.mt)
  return o
end

function Channel:broadcast(msg)
  for i, k in pairs(self.s) do
    table.insert(k.lines, {time = os.date("%X"), msg=msg})
  end
end

function Channel:getActive()
  return self.active
end

function Channel:isActive()
  return self.active == self
end

function Channel:isUser()
  return self.user
end

function Channel:getTextbox()
  return self.textbox
end

function Channel:getName()
  return self.title
end

function Channel:getTabs()
  return self.tabs
end

function Channel:getActive()
  return self.active
end

function Channel:getTextbox()
  return self.textbox
end

function Channel:addMessage(msg)
  table.insert(self.lines, {time = os.date("%X"), user = "Battle", msg = msg})
end

local channel_dimensions = {
  ["landing"] = function() return {
      x = 5,
      y = lobby.fixturePoint[1].y,
      w = lobby.fixturePoint[2].x - 10,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["battle"] = function() return {
      x = lobby.fixturePoint[1].x + 5,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - lobby.fixturePoint[1].x - 10,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["battleWithList"] = function() return {
      x = lobby.fixturePoint[1].x + 5,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - lobby.fixturePoint[1].x - 10,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["options"] = function() return {
      x = 0
    } end,
}

function Channel.refresh()
  Channel.x = channel_dimensions[lobby.state]().x
  Channel.y = channel_dimensions[lobby.state]().y
  Channel.w = channel_dimensions[lobby.state]().w
  Channel.h = channel_dimensions[lobby.state]().h
  Channel.textbox:setPosition(Channel.x + 1, Channel.y + Channel.h - 21):setDimensions(Channel.w - 2, 20)
  Channel:refreshTabs()
end

function Channel:refreshTabs()
  local i = 1
  local totalWidth = 0
  for i, k in pairs(self.tabs) do
    lobby.clickables[k] = nil
  end
  self.tabs = {}
  for chanName, channel in pairs(self.s) do
    if channel.display then
      local showChanName = chanName
      if string.find(chanName, "Battle") then
        showChanName = "Battle"
      end
      local textWidth = fonts.latosmall:getWidth("#" .. chanName)
      self.tabs[chanName] = ChannelTab:new(self.x + totalWidth + 4,
        self.y + 3,
        3 + textWidth,
        20,
        showChanName,
        function()
          if Channel:getActive() then
            Channel:getActive().newMessage = false
          end
          self.active = channel
          channel.newMessage = false
          lobby.channelMessageHistoryID = false
          lobby.refreshUserButtons()
        end)
      lobby.clickables[self.tabs[chanName]] = true
      i = i + 1
      totalWidth = totalWidth + textWidth + 6
    end
  end
  lobby.render()
end

function Channel:getText()
  return Channel:getTextbox():getText()
end

local drawFunc = {
  ["user"] = function(t) return  "<" .. t .. ">"  end,
  ["mention"] = function(t) lg.setColor(1,0,0) return  "<" .. t .. ">"  end,
  ["ingame"] = function(t) lg.setColor(colorss.bt) return  "[" .. t .. "]"  end,
  ["ex"] = function(t) lg.setColor(1,1,0) return  "*" .. t .. "*"  end,
  ["system"] = function() lg.setColor(1,0,0) return  "! SYSTEM : "  end
}

function Channel:render()
  lg.setFont(self.font)
  local fontHeight = self.font:getHeight()
  self.scrollBar
  :setPosition(Channel.x + Channel.w, Channel.y + Channel.h - 25)
  :setLength(-Channel.h + 50)
  :setOffsetMax(math.max(0, #self.lines - math.floor((self.h - 20 - 21)/fontHeight) - 1) * fontHeight)
  self.scrollBar:draw()

  lg.setColor(1,1,1)
  local i = #self.lines 
  local y = 20 - self.scrollBar:getOffset()
  while i > 0 do
    while y < 20 do
      y = y + fontHeight
      i = i - 1
    end
    local line = self.lines[i]
    local drawType = line.user and
                    (line.ex and "ex"
                    or line.mention and
                    "mention" or "user")
                    or "system"
    local align = line.user and "left" or "center"
    local text = "[" .. line.time .. "] " .. drawFunc[drawType](line.user) .. line.msg
    local w, wt = self.font:getWrap(text, self.w - 5)
    local j = #wt
    repeat
      lg.printf(wt[j], self.x + 10, self.y + self.h - y - 21, self.w - 5, align)
      y = y + fontHeight
      j = j - 1
    until self.h < y + 21 + 20 or j == 0
    if self.h < y + 21 + 20 then break end
    i = i - 1
    lg.setColor(1,1,1)
  end
end

function ServerChannel:render()
  lg.setFont(self.font)
  local fontHeight = self.font:getHeight()
  self.scrollBar
  :setPosition(Channel.x + Channel.w, Channel.y + Channel.h - 25)
  :setLength(-Channel.h + 50)
  :setOffsetMax(math.max(0, #self.lines - math.floor((self.h - 20 - 21)/fontHeight) - 1) * fontHeight)
  self.scrollBar:draw()

  lg.setColor(1,1,1)
  local i = #self.lines 
  local y = 20 - self.scrollBar:getOffset()
  while i > 0 do
    while y < 20 do
      y = y + fontHeight
      i = i - 1
    end
    local text = "[" .. self.lines[i].time .. "] " .. self.lines[i].msg
    local align = self.lines[i].to and "left" or self.lines[i].from and "right" or "center"
    local w, wt = self.font:getWrap(text, self.w - 10)
    local j = #wt
    repeat
      lg.printf(wt[j], self.x + 5, self.y + self.h - y - 21, self.w - 10, align)
      y = y + fontHeight
      j = j - 1
    until self.h < y + 21 + 20 or j == 0
    if self.h < y + 21 + 20 then break end
    i = i - 1
    lg.setColor(1,1,1)
  end
end

function BattleChannel:render()
  local battle = Battle:getActiveBattle()
  lg.setFont(self.font)
  local fontHeight = self.font:getHeight()
  local tw = self.w
  local w = 2*tw/3
  local ow = tw/3
  lg.setColor(1,1,1)
  self.infoBoxScrollBar
  :setPosition(Channel.x + Channel.w, Channel.y + Channel.h - 25)
  :setLength(-Channel.h + 50)
  :setOffsetMax(math.max(0, #self.infolines - math.floor((self.h - 20 - 21)/fontHeight) - 1) * fontHeight)
  self.infoBoxScrollBar:draw()
  lg.setColor(colors.bt)
  lg.line(self.x + w, self.y, self.x + w, self.y + self.h - 21)
  lg.setColor(1,1,0)
  lg.printf(battle.founder, self.x + w + 10, self.y + fontHeight, ow - 5, "center")  
  local i = #self.infolines
  local y = 20 - self.infoBoxScrollBar:getOffset()
  while i > 0 do
    while y < 20 do
      y = y + fontHeight
      i = i - 1
    end
    local text = self.infolines[i].msg
    local _, wt = self.font:getWrap(text, ow - 5)
    local j = #wt
    repeat
      lg.printf(wt[j], self.x + w + 10, self.y + self.h - y - 21, ow - 5, "left")
      y = y + fontHeight
      j = j - 1
    until self.h < y + 21 + 20 or j == 0
    if self.h < y + 21 + 20 then break end
    i = i - 1
  end
  
  lg.setColor(1,1,1)
  self.scrollBar
  :setPosition(Channel.x + w - 5, Channel.y + Channel.h - 25)
  :setLength(-Channel.h + 50)
  :setOffsetMax(math.max(0, #self.lines - math.floor((self.h - 20 - 21)/fontHeight) - 1) * fontHeight)
  self.scrollBar:draw()
  
  lg.setColor(1,1,1)
  i = #self.lines
  y = 20 - self.scrollBar:getOffset() 
  while i > 0 do
    while y < 20 do
      y = y + fontHeight
      i = i - 1
    end
    local line = self.lines[i]
    local drawType = line.user and
                    (line.ex and "ex"
                    or line.ingame and "ingame"
                    or line.mention and "mention"
                    or "user")
                    or "system"
    local text = "[" .. line.time .. "] " .. drawFunc[drawType](line.user) .. line.msg
    local align = line.user and "left" or "center"
    local _, wt = self.font:getWrap(text, w - 10)
    local j = #wt
    repeat
      lg.printf(wt[j], self.x + 10, self.y + self.h - y - 21, w - 10, align)
      y = y + fontHeight
      j = j - 1
    until self.h < y + 21 + 20 or j == 0
    if self.h < y + 21 + 20 then break end
    i = i - 1
    lg.setColor(1,1,1)
  end
  
end

--[[for link in wt[j]:gmatch("http[s]*://%S+") do
  local si = string.find(wt[j], link)
  if not si then break end
  Hyperlink:new():setPosition(self.x + w + 5 + fonts.latosmall:getWidth(string.sub(wt[j], 1, si-1)), self.y + h - m - 21):setDimensions(fonts.latosmall:getWidth(link), fontHeight):setText(link)
end]]


