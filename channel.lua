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
  
  o.offset = 0
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
  o.infoboxoffset = 0
  o.infolines = {}
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
      x = 0,
      y = lobby.fixturePoint[1].y,
      w = lobby.fixturePoint[2].x - 10,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["battle"] = function() return {
      x = lobby.fixturePoint[1].x,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - lobby.fixturePoint[1].x - 20,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["battleWithList"] = function() return {
      x = lobby.fixturePoint[1].x,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - lobby.fixturePoint[1].x - 20,
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
  Channel.textbox:setPosition(Channel.x + 1, Channel.y + Channel.h - 21):setDimensions(Channel.w, 20)
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
          lobby.userListOffset = 0
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
  ["ex"] = function(t) lg.setColor(1,1,0) return  "*" .. t .. "*"  end,
  ["system"] = function() lg.setColor(1,0,0) return  "! SYSTEM !"  end
}

function Channel:draw()
  lg.setFont(fonts.latosmall)
  local fontHeight = fonts.latosmall:getHeight()
  local m = 0
  local i = #self.lines - self.offset
  lg.translate(self.x, self.y)
  local h = self.h
  local w = self.w - 20
  while i > 0 and h - 4*fontHeight > m do
    local drawType = self.lines[i].user and (self.lines[i].ex and "ex" or self.lines[i].mention and "mention" or "user") or "system"
    local text = "[" .. self.lines[i].time .. "] " .. drawFunc[drawType](self.lines[i].user) .. self.lines[i].msg
    local _, wt = fonts.latosmall:getWrap(text, w)
    local j = #wt
    local align = self.lines[i].user and "left" or "center"
    while j > 0 and h - 4*fontHeight > m do
      m = m + fontHeight
      lg.printf(wt[j], 10, h - m - 21, w, align)
      j = j - 1
    end
    lg.setColor(1,1,1)
    i = i - 1
  end
  lg.origin()
  lg.setColor(1, 1, 1)
end

function BattleChannel:draw()
  lg.setFont(fonts.latosmall)
  local battle = Battle:getActiveBattle()
  local fontHeight = fonts.latosmall:getHeight()
  local m = 0
  local i = #self.infolines - self.infoboxoffset
  lg.translate(self.x, self.y)
  local h = self.h
  local tw = self.w
  local w = 2*tw/3
  local ow = tw/3
  lg.setColor(lobby.color.bt)
  lg.line(w, 0, w, h - 21)
  lg.setColor(1,1,0)
  lg.printf(battle.founder, w + 10, fontHeight, ow - 10, "center")
  while i > 0 and h - 4*fontHeight > m do
    local text = self.infolines[i].msg
    local _, wt = fonts.latosmall:getWrap(text, ow - 10)
    local j = #wt
    local align = "left"
    while j > 0 and h - 4*fontHeight > m do
      m = m + fontHeight
      lg.printf(wt[j], w + 5, h - m - 21, ow - 10, align)
      j = j - 1
    end
    i = i - 1
  end
  i = #self.lines - self.offset
  m = 0
  lg.setColor(1, 1, 1)
  while i > 0 and h - 4*fontHeight > m do
    local drawType = self.lines[i].user and (self.lines[i].ex and "ex" or self.lines[i].mention and "mention" or "user") or "system"
    local text = "[" .. self.lines[i].time .. "] " .. drawFunc[drawType](self.lines[i].user) .. self.lines[i].msg
    local _, wt = fonts.latosmall:getWrap(text, w - 10)
    local j = #wt
    local align = self.lines[i].user and "left" or "center"
    while j > 0 and h - 4*fontHeight > m do
      m = m + fontHeight
      lg.printf(wt[j], 5, h - m - 21, w - 10, align)
      j = j - 1
    end
    lg.setColor(1,1,1)
    i = i - 1
  end
  lg.origin()
  lg.setColor(1, 1, 1)
end

function ServerChannel:draw()
  lg.setFont(fonts.latosmall)
  local fontHeight = fonts.latosmall:getHeight()
  local m = 0
  local i = #self.lines - self.offset
  lg.translate(self.x, self.y)
  local h = self.h
  local w = self.w - 20
  while i > 0 and h - 4*fontHeight > m do
    local text = "[" .. self.lines[i].time .. "] " .. self.lines[i].msg
    local _, wt = fonts.latosmall:getWrap(text, w)
    local j = #wt
    local align = self.lines[i].to and "left" or self.lines[i].from and "right" or "center"
    while j > 0 and h - 4*fontHeight > m do
      m = m + fontHeight
      lg.printf(wt[j], 10, h - m - 21, w, align)
      j = j - 1
    end
    i = i - 1
  end
  lg.origin()
end
