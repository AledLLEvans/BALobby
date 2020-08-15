require("resources")
require("user")
require("gui/textbox")
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
local nfs = require "lib/nativefs"
local lg = love.graphics

local function checkOS()
  local os = love.system.getOS()
  local engine = "103"
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

local version = {1, 1, 8}
local versionString = "alpha-v"
.. version[1] .. "."
.. version[2] .. "."
.. version[3]

local function checkVersion()
  local http = require "socket.http"
  local url = "https://balancedannihilation.com/data/lobbies/balobby/"
  local data, err = http.request(url)
  print(data, err)
  for line in data:gmatch("[^\n]+") do
    print(line)
  end
end

local function makeColorWheel()
  local imageData = love.image.newImageData(4096, 4096)
  local i = 16777216
  for r = 0, 255 do
    for g = 0, 255 do
      for b = 0, 255 do
        i = i - 1
        local x = i % 4096
        local y = math.floor(i / 4096)
        imageData:setPixel(x, y, r/255, g/255, b/255)
      end
    end
  end
  return lg.newImage(imageData)
end

function love.load()
  --checkVersion()
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