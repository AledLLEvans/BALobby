require("resources")
require("user")
require("options")
require("textbox")
require("download")
require("menu")
require("lobby")
require("login")
require("battle")
require("channel")
require("replays")

STATE_LAUNCHPAD, STATE_LOGIN, STATE_LOBBY = 0,1,2

gamestates = {[0]=launchpad, [1]=login, [2]=lobby}

local lfs = love.filesystem
local nfs = require "nativefs"
local lg = love.graphics

local function checkOS()
  local os = love.system.getOS()
  local engine = "103.0"
  if os == "Windows" then
    lobby.springFilePath = lfs.getUserDirectory() .. 'Documents\\My Games\\Spring\\'
    lobby.engineFolder = lobby.springFilePath .. "engine\\"
    lobby.exeFilePath = lobby.engineFolder .. engine .. "\\spring.exe"
    lobby.gameFolder = lobby.springFilePath .. "games\\"
    lobby.mapFolder = lobby.springFilePath .. "maps\\"
    lobby.replayFolder = lobby.springFilePath .. "demos\\"
  elseif os == "Linux" then
    lobby.springFilePath = lfs.getUserDirectory() .. "/.spring/"
    lobby.engineFolder = lobby.springFilePath .. "engine/"
    lobby.exeFilePath = lobby.engineFolder .. engine .. "/spring.exe"
    lobby.gameFolder = lobby.springFilePath .. "games/"
    lobby.replayFolder = lobby.springFilePath .. "demos/"
  elseif os == "OS X" then
    lobby.springFilePath = lfs.getUserDirectory() .. "/.spring/"
    lobby.engineFolder = lobby.springFilePath .. "engine/"
    lobby.exeFilePath = lobby.engineFolder .. engine .. "/spring.exe"
    lobby.gameFolder = lobby.springFilePath .. "games/"
    lobby.mapFolder = lobby.springFilePath .. "maps/"
    lobby.replayFolder = lobby.springFilePath .. "demos/"
  else
    error("Operating System not recognised")
  end
end

function love.load()
  checkOS()
  if not lfs.getInfo("chatlogs") then
    lfs.createDirectory("chatlogs")
  end
  lg.setFont(fonts.robotosmall)
  if nfs.getInfo( lobby.exeFilePath ) then
    lobby.gotEngine = true
  end
  login.enter()
end

function love.threaderror(thread, err)
  print(thread,err)
end

function love.resize( w, h )
  if gamestates[state].resize then
    gamestates[state].resize(w,h)
  end
end

function love.update(dt)
	gamestates[state].update(dt)
end

function love.draw()
	gamestates[state].draw()
end

function love.keypressed(k, uni)
  if gamestates[state].keypressed then
    gamestates[state].keypressed(k, uni)
  end
end

function love.keyreleased(k, uni)
  if gamestates[state].keyreleased then
    gamestates[state].keyreleased(k, uni)
  end
end

function love.mousepressed(x,y,b)
  if gamestates[state].mousepressed then
    gamestates[state].mousepressed(x,y,b)
  end
end

function love.mousemoved( x, y, dx, dy, istouch )
  if gamestates[state].mousemoved then
    gamestates[state].mousemoved( x, y, dx, dy, istouch )
  end
end

function love.mousereleased(x,y,b)
  if gamestates[state].mousereleased then
    gamestates[state].mousereleased(x,y,b)
  end
end

function love.textinput(text)
  if gamestates[state].textinput then
    gamestates[state].textinput(text)
  end
end

function love.wheelmoved(x, y)
  if gamestates[state].wheelmoved then
    gamestates[state].wheelmoved(x,y)
  end
end

function love.quit()
  if tcp and tcp:getpeername() then
    tcp:send("EXIT" .. "\n")
  end
end