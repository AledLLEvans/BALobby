battlelist = {}

local lg = love.graphics

local function sortBattleIDsByPlayerCount()
  local battleIDs = {}
  local battleIDsByPlayerCount = {}
  for i in pairs(Battle.s) do
    table.insert(battleIDs, i)
  end
  while #battleIDs > 0 do
    local highestIndex
    local highestPlayerCount = -1
    local highestBattleID
    for index, battleid in pairs(battleIDs) do
      local playerCount = Battle.s[battleid].userCount
      if playerCount > highestPlayerCount then
        highestPlayerCount = playerCount
        highestIndex = index
        highestBattleID = battleid
      end
    end
    table.insert(battleIDsByPlayerCount, highestBattleID)
    table.remove(battleIDs, highestIndex)
  end
  return battleIDsByPlayerCount
end

lobby.battleTabDisplayRows = 1
lobby.battleTabDisplayCols = 1
function battlelist.refresh()
  for _, bt in pairs(BattleTab.s) do
    bt.visible = false
  end
  if not lobby.state == "landing" then
    return
  end
  local BattleIDsByPlayerCount = sortBattleIDsByPlayerCount()
  for rank = 1, #BattleIDsByPlayerCount do
    Battle.s[BattleIDsByPlayerCount[rank]].rankByPlayerCount = rank
  end
  local bth = 100
  local i = 1
  local y = 40 - battlelist.scrollbar:getOffset()
  local x = 0
  local xmin = 0
  local ymin = - 60
  local ymax = lobby.fixturePoint[1].y
  local xmax = lobby.fixturePoint[2].x
  lobby.battleTabDisplayCols = math.floor((xmax - xmin) / 600)
  local w = (xmax - xmin) / lobby.battleTabDisplayCols
  local c = 1
  while y < ymax and i <= #BattleIDsByPlayerCount do
    if y >= ymin then
      BattleTab.s[BattleIDsByPlayerCount[i]]
      :setPosition(x+8, y+5)
      :setDimensions(w - 16, bth)
      BattleTab.s[BattleIDsByPlayerCount[i]].visible = true
    end
    i = i + 1
    x = x + w
    c = c + 1
    if c > lobby.battleTabDisplayCols then
      c = 1
      x = xmin
      y = y + bth + 10
    end
  end
  lobby.battleTabSubText = "Showing " .. #BattleIDsByPlayerCount .. " battles."
  if not lobby.loginInfoEnd then
    lobby.battleTabSubText = lobby.battleTabSubText .. "(Loading .. )"
  end
  lobby.battleTabDisplayRows = math.floor((ymax-ymin)/(bth + 10)) - 1
  local len = lobby.fixturePoint[2].y - 40
  local sblen = math.max(0, math.ceil(#BattleIDsByPlayerCount/lobby.battleTabDisplayCols) - lobby.battleTabDisplayRows)
  lobby.battlelist.scrollbar
  :setPosition(lobby.fixturePoint[2].x - 3, 40)
  :setLength(len)
  :setScrollBarLength((len - 100)/sblen)
  :setOffsetMax(sblen * (bth + 10))
  lobby.battlelist.scrollbar:getZone()
  :setDimensions(lobby.fixturePoint[2].x, lobby.fixturePoint[2].y - 90)
  lobby.render.battlelist()
end

local timer = 0
function battlelist:update(dt)
  timer = timer - dt
  if timer < 0 then
    if lobby.battleTabHover and not lobby.battleTabHoverWindow then
      lobby.battleTabHoverWindow = BattleTabHoverWindow:new(lobby.battleTabHover.battleid)
      lobby.render.background()
    end
  end
end

function BattleTab:isOver(x,y)
  if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
    lobby.battleTabHover = self
    timer = 0.5
    self.highlighted = true
    return true
  end
  self.highlighted = false
  return false
end

function battlelist.initialize()
  lobby.events[battlelist] = true
  battlelist.scrollbar = ScrollBar:new()
  :setScrollSpeed(25)
  :setRenderFunction(function() lobby.battlelist.refresh() end)
  battlelist.scrollbar:getZone()
  :setPosition(0, 90)
  :setDimensions(lobby.fixturePoint[2].x, lobby.fixturePoint[2].y - 90)
  battlelist.refresh()
end

function battlelist.resize()
  lobby.battlelist.scrollbar:setOffset(0)
  lobby.render.battlelist()
end

return battlelist