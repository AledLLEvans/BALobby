local utf8 = require("utf8")
login = {}
local base64 = require("base64")
local md5 = require("md5")
 
local nfs = require "nativefs"

local lg = love.graphics
local lfs = love.filesystem
local address, port = "springfightclub.com", 8200

local requests_channel = love.thread.getChannel("requests")
local progress_channel = love.thread.getChannel("progress")
local unpacker_channel = love.thread.getChannel("unpacker")

local socket = require "socket"

function login.enter()
  login.video = lg.newVideo( "data/bamovie3.ogv" )
  login.video:play()
  login.savePass = true
  login.log = {}
  tcp = socket.tcp()
  if not tcp then
    error(tcp)
    love.event.quit()
  end
  tcp:connect(address, port)
  tcp:settimeout(0)
  function lobby.send(msg)
    table.insert(lobby.serverChannel.lines, {to = true, msg = msg})
    return tcp:send(msg)
  end
  
  Button:releaseAll()
  lobby.width = 800
  lobby.height = 600
  login.width = 800
  login.height = 600
  loginBox = {
    x = lobby.width/2,
    y = lobby.height/2
  }
  
  login.nameBox = Textbox:new({
    x = lobby.width/2-244/2+60,
    y = lobby.height/2-152/2+40,
    w = 100, h = 20, name = 'Username'})
  login.passBox = TextboxPrivate:new({
    x = lobby.width/2-244/2+60,
    y = lobby.height/2-152/2+40 + 40,
    w = 100, h = 20, name = 'Password'})
  
  state = STATE_LOGIN
  love.keyboard.setKeyRepeat(true)
  settings.unpack()
  if settings then
    if settings.name then
      login.nameBox:setText(settings.name)
      login.nameBox.charoffset = #settings.name
    end
    if settings.pass then
      login.passBox.faketext = true
      login.passBox:setText("*******")
      login.passBox:setBase64(settings.pass)
    end
  end
  
  if not lobby.gotEngine then
    if settings.engine_downloaded then
      if settings.engine_unpacked then
        error("check engine installation or delete settings.lua in appdata")
      end
      login.startEngineUnpack()
    else
      login.startEngineDownload()
    end
  end
end

function login.startEngineDownload()
  local url = "https://springrts.com/dl/buildbot/default/master/103.0/win64/spring_103.0_win64-minimal-portable.7z"
  local download_thread = love.thread.newThread("downloader.lua")
  download_thread:start()
  login.downloading = true
  login.dl_status = {finished = false, downloaded = 0, file_size = 0}
  requests_channel:push({url = url, filename = "spring_103.0_win64-minimal-portable.7z", filepath = lobby.engineFolder})
  login.downloadText = "Retrieving URL .."
end

function login.startEngineUnpack()
  login.unpacking = true
  login.downloadText = "Unpacking .."
  nfs.createDirectory(lobby.springFilePath .. "engine\\blobby\\103.0")
  local unpacker_thread = love.thread.newThread("unpacker.lua")
  unpacker_thread:start(lobby.engineFolder .. "spring_103.0_win64-minimal-portable.7z", lobby.springFilePath .. "engine\\blobby\\103.0")
  nfs.createDirectory(lobby.mapFolder)
  nfs.createDirectory(lobby.gameFolder)
end

function login.updateDownload(dt)
  local progress_update = progress_channel:pop()
  while progress_update do
    if progress_update.finished then
      settings.add({engine_downloaded = true})
      login.dl_status.finished = true
      login.downloading = false
      login.startEngineUnpack()
    end
    if progress_update.file_size then
      if login.dl_status.file_size == 0 then
        login.downloadText = "Downloading .."
      end
      login.dl_status.file_size = progress_update.file_size
    end
    if progress_update.chunk then
      login.dl_status.downloaded = login.dl_status.downloaded + progress_update.chunk
    end
    if progress_update.error then
      login.dl_status.err = progress_update.error
      login.downloadText = login.dl_status.err .. " Restart and try again?"
    end
    progress_update = progress_channel:pop()
  end
end

login.unpackerCount = 0
function login.updateUnpack(dt)
  local unpacker_update = unpacker_channel:pop()
  while unpacker_update do
    if unpacker_update.pop then
      login.unpackerCount = login.unpackerCount + 1
    end
    if unpacker_update.finished then
      settings.add({engine_unpacked = true})
      login.downloadText = "Up to Date"
    end
    if unpacker_update.fileCount then
      login.fileCount = unpacker_update.fileCount
    end
    if unpacker_update.error then
      error(unpacker_update.error)
    end
    unpacker_update = unpacker_channel:pop()
  end
end

settings = {}
function settings.unpack()
  local path = love.filesystem.getSaveDirectory( ) .. "/settings.lua"
  if lfs.getInfo( "settings.lua" ) then
    t = require "settings"
  end
  for i, k in pairs(t) do
    settings[i] = k
  end
  return settings
end

function settings.pack()
  local str = "return {"
  for i, k in pairs(settings) do
    if type(k) == "string" then
      str = str .. i .. " = \"" .. k .. "\","
    elseif type(k) == "number" then
      str = str .. i .. " = " .. k .. ","
    elseif type(k) == "boolean" then
      str = str .. i .. " = " .. tostring(k) .. ","
    end
  end
  str = str .. "}"
  return lfs.write( "settings.lua", str)
end

function settings.add(t)
  for i, k in pairs(t) do
    settings[i] = k
  end
  return settings.pack()
end

function login.connectToServer()
  if login.savePass then
    settings.add({name = login.nameBox.text, pass = login.passBox.base64})
  else
    settings.add({name = login.nameBox.text})
  end
  local ip, _ = tcp:getsockname()
  if not ip then table.insert(login.log, {msg = "NO IP, NOT CONNECTED, CHECK INTERNET CONNECTION"}) return end
  login.loginString = "LOGIN " .. 
  login.nameBox.text .. 
  " " .. 
  login.passBox.base64 ..
  " 0 " .. 
  ip .. 
  " BAlogin 0.1 0\n"
  tcp:send(login.loginString)
  table.insert(login.log, {to = true, msg = "LOGIN " .. login.nameBox.text .. " " .. ip })
end

local responses = require("response")
function login.update( dt )
  if not login.video:isPlaying() then
    login.video:rewind()
    login.video:play()
  end
  login.delay = login.delay - dt
  login.nameBox:update(dt)
  login.passBox:update(dt)
  lobby.timer = lobby.timer + dt
  if lobby.timer > 30 then
    tcp:send("PING" .. "\n")
    table.insert(login.log, {to = true, msg = "PING"})
    lobby.timer = 0
  end
  data = tcp:receive()
  if data then
    love.filesystem.append( "log.txt", data .. "\n" )
    local cmd = string.match(data, "^%u+")
    local words = {}
    local sentances = {}
    for sentance in string.gmatch(data, "[^\t]+") do
      table.insert(sentances, sentance)
    end
    local i = 0
    for word in string.gmatch(sentances[1], "%S+") do
      if i > 0 then 
        table.insert(words, word)
      end
      i = i + 1
    end
    table.insert(login.log, {receive = true, msg = data})
    if responses[cmd] then
      responses[cmd].respond(words, sentances, data)
    end
  end
  if login.downloading then
    login.updateDownload(dt)
  end
  if login.unpacking then
    login.updateUnpack(dt)
  end
end

function login.resize( w, h )
  login.width = w
  login.height = h
  lobby.width = w
  lobby.height = h
  loginBox.x = w/2
  loginBox.y = h/2
  login.nameBox:setPos(w/2 - 244/2 + 60, h/2 - 152/2 + 40)
  login.passBox:setPos(w/2 - 244/2 + 60, h/2 - 152/2 + 40 + 40)
end

function login.textinput (text)
  if login.nameBox:isActive() then
    login.nameBox:addText(text)
  end
  if login.passBox:isActive() then
    login.passBox:addText(text)
    --login.passBox:setBase64(base64.encode(md5sum(login.passBox:getText())))
  end
end

login.delay = 0
local keypress = {
  ["delete"] = function()
    login.nameBox:delete()
    login.passBox:delete()
  end,
  ["backspace"] = function()
    login.nameBox:backspace()
    login.passBox:backspace()
  end,
  ["return"] = function()
    if login.delay > 0 then return end
    login.connectToServer()
    login.delay = 0.5
  end,
  ["tab"] = function() 
    login.nameBox:toggle()
    login.passBox:toggle()
  end,
  ["escape"] = function()
    tcp:send("EXIT\n")
    love.event.quit()
  end,
  ["left"] = function()
    login.nameBox:moveLeft()
    login.passBox:moveLeft()
  end,
  ["right"] = function()
    login.nameBox:moveRight()
    login.passBox:moveRight()
  end
}

function login.keypressed(k, uni)
  if keypress[k] then keypress[k]() end
end

function login.mousereleased (x, y, b)
  if not b == 1 then return end
  login.nameBox:click(x,y)
  login.passBox:click(x,y)
  for i, k in pairs(Button.actives) do
    if x > k.x and x < k.x + k.w and y > k.y and y < k.y + k.h then
      k:click()
    end
  end
end

function login.drawLoginBox()
  lg.draw(img["loginBox"], loginBox.x, loginBox.y, 0, 1, 1, 244/2, 152/2) 

  login.nameBox:draw()
  login.passBox:draw()
  lg.setColor(1,1,1)
end

function login.drawDownloadBars()
  lg.setColor(255, 255, 255)
  lg.printf(login.downloadText, 0, 20, login.width, "center")
  lg.rectangle("line", 50, 50, login.width - 100, 20)
  local fontHeight = fonts.robotosmall:getHeight()
  if login.dl_status then
    if login.dl_status.file_size > 0 then
      local perc = login.dl_status.downloaded / login.dl_status.file_size
      perc = math.floor(perc * 100)
      lg.rectangle("fill", 50, 50, (login.width/2-50)*perc/100, 20)
      lg.print(string.format("%d%%", perc), login.width/2-20, 20 + fontHeight)
    end
    if login.dl_status.err then
      lg.print(login.dl_status.err, 0, 32)
    end
  end
  if login.unpackerCount then
    if login.unpackerCount > 0 then
      local frac = login.unpackerCount / login.fileCount
      lg.rectangle("fill", login.width/2, 50, (login.width/2-50)*frac, 20)
      lg.print(login.unpackerCount .. "/" .. login.fileCount, login.width/2 + 10, 20 + fontHeight)
    end
  end
end

function login.draw()
  --lg.draw(img["balanced+annihilation+big+loadscreen-min"], 0, 0)
  lg.draw(login.video, 0, 0, 0, login.width/1920, login.height/1080)
  login.drawLoginBox()
  if not lobby.gotEngine then login.drawDownloadBars() end
  local fontHeight = fonts.robotosmall:getHeight()
  local i = #login.log
  lg.rectangle("line", 8, 80, 160, login.height - 160)
  while i > 0 and 80 + i*fontHeight < login.height - 160 do
    local txt = login.log[i].msg
    local _, wt = fonts.robotosmall:getWrap(txt, 156)
    lg.printf(txt, 12, 70 + i*fontHeight, 156, "left")
    i = i - #wt
  end
  for i, k in pairs(Button.actives) do
    k:draw()
  end
end
