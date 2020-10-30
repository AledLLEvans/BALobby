topbar = {}

local lg = love.graphics

local launchCode = [[
  local exec = ...
  io.popen(exec)
]]

function topbar.initialize()
  topbar.singleplayer = Button:new()
  :setPosition(36, 0)
  :setDimensions(100, 32)
  :setText("Single Player")
  :onClick(function()
    sound.tab:play()
    local battle = Battle:getActive()
    if battle then --and not battle.single then
      lobby.send("LEAVEBATTLE")
      battle:getChannel().display = false
    end
    if not lobby.springThread then
      lobby.springThread = love.thread.newThread( launchCode )
    end
    --love.window.minimize( )
    lobby.springThread:start("\"" .. lobby.exeFilePath .. "\"")
    --Battle.enterSingle()
  end)

  topbar.hostbattle = Button:new()
  :setPosition(136, 0)
  :setDimensions(90, 32)
  :setText("Host Battle")
  :onClick(function()
    sound.tab:play()
    Battle.host()
  end)

  topbar.replays = Button:new()
  :setPosition(226, 0)
  :setDimensions(80, 32)
  :setText("Replays")
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