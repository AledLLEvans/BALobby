require("resources")
require("textbox")
require("button")
require("download")
require("lobby")
require("login")
require("user")
require("battle")
require("channel")

WIDTH = 256
HEIGHT = 200

local MAX_FRAMETIME = 1/20
local MIN_FRAMETIME = 1/60

STATE_LAUNCHPAD, STATE_LOGIN, STATE_LOBBY = 0,1,2

gamestates = {[0]=launchpad, [1]=login, [2]=lobby}
local nfs = require "nativefs"
local lg = love.graphics
function love.load()
  lg.setFont(fonts.robotosmall)
  love.filesystem.setIdentity("BALobby")
  lobby.springFilePath = [[C:\Users\]] .. os.getenv("USERNAME") .. '\\Documents\\My Games\\Spring\\'
  lobby.exeFilePath = love.filesystem.getUserDirectory() .. 'Documents\\My Games\\Spring\\engine\\blobby\\103.0\\spring.exe'
  lobby.engineFolder = lobby.springFilePath .. "engine\\"
  lobby.gameFolder = lobby.springFilePath .. "games\\"
  lobby.mapFolder = lobby.springFilePath .. "maps\\"
  if nfs.getInfo( lobby.exeFilePath ) then
    lobby.gotEngine = true
  end
  login.enter()
end

function love.threaderror(thread, err)
  error(err)
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
    tcp:send("EXIT")
  end
end