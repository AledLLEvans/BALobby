local lfs = love.filesystem
local nfs = require "nativefs"
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

local video
function love.load()
  --checkOS()
  os.execute("BALobby.exe")
  
  
  video = lg.newVideo( "bamoviecrop4.ogv" )
  video:play()
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
  
end

function love.draw()
  lg.draw(video, 0, 0, 0, 1/3, 1/3)
  drawDownloadBars()
  --drawDownloadText()
end

function love.keypressed(k, uni)

end

function love.keyreleased(k, uni)

end

function love.mousepressed(x,y,b)

end

function love.mousemoved( x, y, dx, dy, istouch )

end

function love.mousereleased(x,y,b)

end

function love.textinput(text)

end

function love.wheelmoved(x, y)

end

function love.quit()
  
end

function drawDownloadBars()
  lg.setColor(colors.bargreen)
  if login.dl_status then
    if login.dl_status.file_size > 0 then
      local w = math.floor(login.dl_status.downloaded / login.dl_status.file_size * 100)/100
      lg.rectangle("fill", 0, 0, (lobby.width/2)*w, 2)
    end
  end
  if login.unpackerCount then
    if login.unpackerCount > 0 then
      local w = login.unpackerCount / login.fileCount
      lg.rectangle("fill", lobby.width/2, 0, (lobby.width/2)*w, 2)
    end
  end
  lg.setColor(1,1,1)
end