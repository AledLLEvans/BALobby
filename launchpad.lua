launchpad = {}

local nfs = require "nativefs"

local lg = love.graphics
local lfs = love.filesystem

function launchpad.validateFiles()
  lobby.springFilePath = [[C:\Users\]] .. os.getenv("USERNAME") .. '\\Documents\\My Games\\Spring\\'
  lobby.exeFilePath = lfs.getUserDirectory() .. '\\Documents\\\"My Games\"\\Spring\\engine\\blobby\\103.0\\spring.exe'
  lobby.engineFolder = lobby.springFilePath .. "engine\\"
  lobby.gameFolder = lobby.springFilePath .. "games\\"
  lobby.mapFolder = lobby.springFilePath .. "maps\\"
  if nfs.getInfo( lobby.exeFilePath ) then
    lobby.gotEngine = true
  end
end

launchpad.width, launchpad.height = lg.getDimensions()
function launchpad.enter()
  launchpad.validateFiles()
	state = STATE_LAUNCHPAD
  launchpad.video = lg.newVideo( "bamovie3.ogv" )
  --launchpad.video:getSource():setLooping(true)
  launchpad.video:play()
  
  launchpad.singleB = Button:create(640-160-50, 250, 160, 100, "Offline Mode",
    function() love.event.quit() os.exectue(lobby.exeFilePath) end)
  launchpad.singleB:activate()
  
  launchpad.upB = Button:create(50, 250, 160, 100, "Launch", 
    function() login.enter() end)
  launchpad.upB:activate()
end

local function replayVideo()
  if not launchpad.video:isPlaying() then
    launchpad.video:rewind()
    launchpad.video:play()
  end
end

function launchpad.update(dt)
  replayVideo()
end

function launchpad.draw()
  lg.draw(launchpad.video, 0, 0, 0, launchpad.width/1920, launchpad.height/1080)
  lg.print(tostring(launchpad.video:isPlaying()), 10, 10)
  for i, k in pairs(Button.actives) do
    k:draw()
  end
end

function launchpad.mousereleased( x, y, button, istouch, presses )
  if not button == 1 then
    return
  end
  for i, k in pairs(Button.actives) do
    if x > k.x and x < k.x + k.w and y > k.y and y < k.y + k.h then
      k:click()
    end
  end
end

function launchpad.keypressed(k)
  if k == "return" then
    launchpad.upB:click()
  end
end
