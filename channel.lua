Channel = {}
Channel.mt =  {__index = Channel}
local lg = love.graphics

Channel.s = {}
Channel.x = 0
Channel.y = 0
Channel.w = 10
Channel.h = 10
Channel.scrollBar = ScrollBar:new():setScrollBarLength(-20):setScrollSpeed(fonts.latobold:getHeight())
Channel.textbox = Textbox:new()

lobby.channels = {}
lobby.channel_topics = {}
Channel.addButton = Button:new():setFunction(
  function()
    lobby.userlist.bar:open()
    lobby.send("CHANNELS")
    Channel.active = nil
    Channel:refreshTabs()
  end)
Channel.addButton.colors.background = colors.bbb
lobby.clickables[Channel.addButton] = true
  
function Channel:new(o, bool)
  o = o or {}
  setmetatable(o, Channel.mt)
  
  local title = o.title
  if o.isServer then
    title = "Server"
  elseif o.isChannel then
    title = "#" .. title
  end
  o.tab = ChannelTab:new()
  o.tab.textWidth = fonts.latochantab:getWidth(title)
  o.tab.w = fonts.latochantab:getWidth(title)
  o.tab.parent = o
  o.tab:setText(title):setFont(fonts.latochantab)
  
  o.font = fonts.latobold
  o.lines = {}
  o.users = {} 
  o.sents = {}
  o.display = true
  o.text = ""
  
  if not bool then self.s[o.title] = o end
  return o
end

ServerChannel = Channel:new({title = "server", isServer = true})
BattleChannel = Channel:new({title = "battle", isBattle = true}, true)
BattleChannel.mt = {__index = BattleChannel}
lobby.serverChannel = Channel.s["server"]
Channel.active = lobby.serverChannel

function BattleChannel:new(o)
  o = Channel:new(o)
  o.isBattle = true
  o.tab:setText("Battle")
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

function Channel:open()
  Channel.active = self
  self.display = true
  Channel:refreshTabs()
end

function Channel:addMessage(msg)
  table.insert(self.lines, {time = os.date("%X"), user = "Battle", msg = msg})
end

local channel_dimensions = {
  ["landing"] = function() return {
      x = 5,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - 10,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["battle"] = function() return {
      x = lobby.fixturePoint[1].x + 5,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - lobby.fixturePoint[1].x - 10,
      h = lobby.height - lobby.fixturePoint[2].y - 1} end,
  ["replays"] = function() return {
      x = lobby.fixturePoint[1].x + 5,
      y = lobby.fixturePoint[1].y,
      w = lobby.width - 10,
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
  for name, channel in pairs(self.s) do
    local tab = channel.tab
    lobby.clickables[tab] = nil
    if channel.display then
      tab:setPosition(self.x + totalWidth + 4, self.y + 3)
      :setDimensions(3 + tab.textWidth + 16, 35)
      --channel.tab.title = name
      --channel.tab.text = tab_name
      lobby.clickables[tab] = true
      i = i + 1
      totalWidth = totalWidth + tab.textWidth + 16
    end
  end
  Channel.addButton:setPosition(self.x + totalWidth + 4, self.y + 3):setDimensions(35, 35):setText("+")
  lobby.render.background()
  lobby.render.userlist()
  lobby.render.foreground()
end

function Channel:getText()
  return Channel:getTextbox():getText()
end

local drawFunc = {
  ["user"] = function(u, t) return  "<" .. u .. ">" .. t  end,
  ["mention"] = function(u, t) lg.setColor(1,0,0) return  "<" .. u .. ">" .. t  end,
  ["ingame"] = function(u, t) lg.setColor(colors.mo) return  "[" .. u .. "]" .. t end,
  ["ex"] = function(u, t) lg.setColor(colors.yellow) return  "*" .. u .. "*" .. t  end,
  ["system"] = function(u, t) lg.setColor(1,0,0) return  "::: ".. t .. " :::" end,
  ["green"] = function(u, t) lg.setColor(colors.textblue) return "*" .. t .. "*" end
}

local function sbOffsetMax(n, h, fh)
  return math.max(0, n - math.floor((h - 30 - 21)/fh)) * fh
end

local function sbPosX() return Channel.x + Channel.w end
local function sbPosY() return Channel.y + Channel.h - 25 end 
local function sbLength() return - Channel.h + 65 end

function Channel:render()
  lg.setFont(self.font)
  local fontHeight = self.font:getHeight()
  self.scrollBar
  :setPosition(sbPosX(), sbPosY())
  :setLength(sbLength())
  :setOffsetMax(sbOffsetMax(#self.lines, self.h, fontHeight)):draw()

  lg.setColor(colors.text)
  local i = #self.lines
  local y = 20 - self.scrollBar:getOffset()
  while i > 0 do
    while y < 20 do
      y = y + fontHeight
      i = i - 1
    end
    if i < 1 then return end
    local line = self.lines[i]
    local drawType = line.user and
                    (line.ex and "ex"
                    or line.mention and
                    "mention" or "user")
                    or "system"
    local align = line.user and "left" or "center"
    local text = "[" .. line.time .. "] " .. drawFunc[drawType](line.user, line.msg)
    local w, wt = self.font:getWrap(text, self.w - 5)
    local j = #wt
    repeat
      lg.printf(wt[j], self.x + 10, self.y + self.h - y - 21, self.w - 5, align)
      y = y + fontHeight
      j = j - 1
    until self.h < y + 21 + 30 or j == 0
    if self.h < y + 21 + 30 then break end
    i = i - 1
    lg.setColor(colors.text)
  end
  lg.setColor(1,1,1)
end

function ServerChannel:render()
  lg.setFont(self.font)
  local fontHeight = self.font:getHeight()
  self.scrollBar
  :setPosition(sbPosX(), sbPosY())
  :setLength(sbLength())
  :setOffsetMax(sbOffsetMax(#self.lines, self.h, fontHeight)):draw()

  lg.setColor(colors.text)
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
    until self.h < y + 21 + 40 or j == 0
    if self.h < y + 21 + 40 then break end
    i = i - 1
    lg.setColor(colors.text)
  end
  lg.setColor(1,1,1)
end

function BattleChannel:render()
  local battle = Battle:getActiveBattle()
  lg.setFont(self.font)
  local fontHeight = self.font:getHeight()
  local tw = self.w
  local w = math.floor(2*tw/3)
  local ow = math.floor(tw/3)
  
  if lobby.state == "battle" then
    -- "Info" Box
    lg.setColor(colors.text)
    self.infoBoxScrollBar
    :setPosition(sbPosX(), sbPosY())
    :setLength(sbLength())
    :setOffsetMax(sbOffsetMax(#self.infolines, self.h, fontHeight))
    :draw()
    
    lg.setColor(colors.bt)
    --lg.line(self.x + w, self.y, self.x + w, self.y + self.h - 21)
    lg.setColor(colors.yellow)
    lg.printf(battle.founder, self.x + w + 10, self.y + fontHeight + 10, ow - 5, "center")  
    local i = #self.infolines
    local ymin = 20
    local y = ymin - self.infoBoxScrollBar:getOffset()
    while i > 0 do
      while y < ymin do
        y = y + fontHeight
        i = i - 1
      end
      if i <= 0 then break end
      local text = self.infolines[i].msg
      local _, wt = self.font:getWrap(text, ow - 5)
      local j = #wt
      repeat
        lg.printf(wt[j], self.x + w + 10, self.y + self.h - y - 21, ow - 5, "left")
        y = y + fontHeight
        j = j - 1
      until self.h - 51 - fontHeight < y or j == 0
      if self.h - 41 - fontHeight < y then break end
      i = i - 1
    end
  end
  --
  
  -- Player Chat
  lg.setColor(colors.text)
  self.scrollBar
  :setPosition(2*Channel.w/3, sbPosY())
  :setLength(sbLength())
  :setOffsetMax(sbOffsetMax(#self.lines, self.h, fontHeight))
  :draw()

  lg.setColor(colors.text)
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
                    or line.green and "green"
                    or "system"
    local text = drawFunc[drawType](line.user, line.msg)
    local ttext = "[" .. line.time .. "] "
    local ttextw = self.font:getWidth(ttext)
    local align = line.user and "left" or "center"
    local _, wt = self.font:getWrap(text, w - 10 - ttextw)
    local j = #wt
    repeat
      lg.printf(ttext, self.x + 5, self.y + self.h - y - 21, w - 10, "left")
      lg.printf(wt[j], self.x + 5 + ttextw, self.y + self.h - y - 21, w - 5 - ttextw, align)
      y = y + fontHeight
      j = j - 1
    until self.h - 41 < y or j == 0
    if self.h - 51 < y then break end
    i = i - 1
    lg.setColor(colors.text)
  end
  --
  
  lg.setColor(1,1,1)
end

--[[for link in wt[j]:gmatch("http[s]*://%S+") do
  local si = string.find(wt[j], link)
  if not si then break end
  Hyperlink:new():setPosition(self.x + w + 5 + fonts.latosmall:getWidth(string.sub(wt[j], 1, si-1)), self.y + h - m - 21):setDimensions(fonts.latosmall:getWidth(link), fontHeight):setText(link)
end]]


