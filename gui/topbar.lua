topbar = {}

local lg = love.graphics

local spring = require("spring")

function topbar.initialize()
  
  topbar.singleplayer = Button:new()
  :setPosition(36, 0)
  :setDimensions(100, 32)
  :setText("Single Player")
  :setBackgroundColor(colors.bbb)
  :onClick(function()
    sound.tab:play()
    local battle = Battle:getActive()
    if battle then --and not battle.single then
      lobby.send("LEAVEBATTLE")
      battle:getChannel().display = false
    end
    spring.launch("\"" .. lobby.exeFilePath .. "\"")
  end)

  topbar.hostbattle = Button:new()
  :setPosition(136, 0)
  :setDimensions(90, 32)
  :setText("Host Battle")
  :setBackgroundColor(colors.bbb)
  :onClick(function()
    sound.tab:play()
    Battle.host()
  end)

  topbar.replays = Button:new()
  :setPosition(226, 0)
  :setDimensions(80, 32)
  :setText("Replays")
  :setBackgroundColor(colors.bbb)
  :onClick(function()
    sound.tab:play()
    Replay.enter()
  end)
  
  lobby.clickables[topbar.singleplayer] = true
  lobby.clickables[topbar.hostbattle] = true
  lobby.clickables[topbar.replays] = true
  
  function topbar:draw()
    topbar.singleplayer:draw()
    topbar.hostbattle:draw()
    topbar.replays:draw()
  end
  
  function topbar.resize()
    topbar.singleplayer
    :setPosition(36, 0)
    :setDimensions(100, 32)

    topbar.hostbattle
    :setPosition(136, 0)
    :setDimensions(90, 32)

    topbar.replays
    :setPosition(226, 0)
    :setDimensions(80, 32)
  end
end

return topbar