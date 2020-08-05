local utf8 = require("utf8")
login = {}
local base64 = require("base64")
local md5 = require("md5")
 
local nfs = require "nativefs"

local lg = love.graphics
local lfs = love.filesystem
local address, port = "springfightclub.com", 8200

local unpacker_channel = love.thread.getChannel("unpacker")

local socket = require "socket"

login.downloadText = ""
function login.enter()
  state = STATE_LOGIN
  love.keyboard.setKeyRepeat(true)
  login.video = lg.newVideo( "data/bamovie3.ogv" )
  login.video:play()
  login.log = {}

  settings.unpack()
  if settings.mode then
    if settings.mode == "light" then
      setLightMode()
      lobby.darkMode = false
      lobby.lightMode = true
    elseif settings.mode == "dark" then
      setDarkMode()
      lobby.darkMode = true
      lobby.lightMode = false
    end
  else
    settings.add({mode = "dark"})
    setDarkMode()
    lobby.darkMode = true
    lobby.lightMode = false
  end
  login.savePass = settings.savePass or false
  
  function lobby.send(msg)
    table.insert(lobby.serverChannel.lines, {time = os.date("%X"), to = true, msg = msg})
    return tcp:send(msg)
  end
  
  lobby.width = 800
  lobby.height = 450
  login.width = 800
  login.height = 450
  loginBox = {
    x = lobby.width/2,
    y = lobby.height/2,
    w = 400,
    h = 225
  }
  
  login.savePassCheckbox = Checkbox:new():setPosition(loginBox.x -loginBox.w/2 + 10, loginBox.y + loginBox.h/2 - 30):setDimensions(20, 20):setFunction(function()
      login.savePass = not login.savePass
    end):setText("Save Password?")
  function login.savePassCheckbox:draw()
    lg.setColor(self.color.back)
    lg.rectangle("fill", self.x, self.y, self.w, self.h)
    lg.setColor(self.color.outline)
    lg.rectangle("line", self.x, self.y, self.w, self.h)
    if login.savePass then
      lg.setColor(self.color.inside)
      lg.rectangle("fill", self.x + 3, self.y + 3, self.w - 6, self.h - 6)
    end
    lg.setColor(colors.text)
    lg.draw(self.text, self.x + self.w + 2, self.y)
  end
  
  --LOGIN TEXTBOXES
  login.nameBox = Textbox:new({name = 'Username'})
  login.nameBox:setDimensions(320, 30)
  login.nameBox:setFont(fonts.latomedium)
  --login.nameBox.colors.outline = {50/255, 50/255, 50/255, 255/255}
  
  login.passBox = TextboxPrivate:new({name = 'Password'})
  login.passBox:setDimensions(320, 30)
  login.passBox:setFont(fonts.latomedium)
  --login.passBox.colors.outline = {50/255, 50/255, 50/255, 255/255}
    
  if settings.name then
    login.nameBox:setText(settings.name)
    login.nameBox.charoffset = #settings.name
  end
  if settings.pass then
    login.passBox.faketext = true
    login.passBox:setText("*******")
    login.passBox:setBase64(settings.pass)
  end
  
  --LOGIN BUTTONS
  login.buttons = {}
  login.buttons.login = Button:new()
  login.buttons.login:setDimensions(80, 35)
  login.buttons.login:setText("Sign In")
  login.buttons.login:setFont(fonts.latosmall)
  login.buttons.login:setFunction(function() login.connectToServer() end)
  function login.buttons.login:draw()
    lg.setColor(colors.bb)
    lg.rectangle("fill", self.x, self.y, self.w, self.h, 5)
    lg.setColor(colors.text)
    lg.draw(self.text, self.x, self.y + self.h/2 - self.font:getHeight()/2 + 1)
  end
  login.buttons.register = Button:new()
  login.buttons.register:setDimensions(110, 35)
  login.buttons.register:setText("Create Account")
  login.buttons.register:setFont(fonts.latosmall)
  login.buttons.register:setFunction(function() login.registerAccount() end)
  function login.buttons.register:draw()
    lg.setColor(colors.bb)
    lg.rectangle("fill", self.x, self.y, self.w, self.h, 5)
    lg.setColor(colors.text)
    lg.draw(self.text, self.x, self.y + self.h/2 - self.font:getHeight()/2 + 1)
  end
  
  if not lobby.gotEngine then
    if settings.engine_downloaded then
      if settings.engine_unpacked then
        love.window.showMessageBox("Cant find engine.", "Check engine installation or delete settings.lua in appdata, you may have trouble launching the game", "error" )
        return
      end
      login.startEngineUnpack()
    else
      login.startEngineDownload()
    end
  end
  login.resize( login.width, login.height )
end

local progress_channel = love.thread.getChannel("progress_login")
function login.startEngineDownload()
  local url = "https://springrts.com/dl/buildbot/default/master/103.0/win64/spring_103.0_win64-minimal-portable.7z"
  
  local download_thread = love.thread.newThread("downloader.lua")
  download_thread:start(url, "spring_103.0_win64-minimal-portable.7z", lobby.springFilePath .. "engine", "login")
  login.downloading = true
  login.dl_status = {finished = false, downloaded = 0, file_size = 0}
  login.downloadText = "Retrieving URL .."
end

function login.startEngineUnpack()
  login.unpacking = true
  login.downloadText = "Unpacking .."
  nfs.createDirectory(lobby.springFilePath .. "engine\\103.0")
  local unpacker_thread = love.thread.newThread("unpacker.lua")
  unpacker_thread:start(
    lobby.engineFolder .. "spring_103.0_win64-minimal-portable.7z",
    lobby.springFilePath .. "engine\\103.0")
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
  if t then
    for i, k in pairs(t) do
      settings[i] = k
    end
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

function settings.remove(t)
  for i, _ in pairs(t) do
    settings[i] = nil
  end
  return settings.pack()
end

local function connect()
  if tcp then
    return true
  else
    tcp = socket.tcp()
  end
  if not tcp then
    error("no tcp connection")
    love.event.quit()
  end
  tcp:connect(address, port)
  tcp:settimeout(0)
end

login.action = 0
function login.registerAccount()
  login.action = 2
  if connect() then
    login.handleResponse()
  end
end

function login.handleResponse()
 --if v == "STLS" then
  ip, _ = tcp:getsockname()
  if not ip then
    lw.showMessageBox("For your information", "tcp connection failed", "error" )
    return
  end
  if login.action == 1 then
    login.loginString = "LOGIN " .. 
    login.nameBox.text .. 
    " " .. 
    login.passBox.base64 ..
    " 0 " .. 
    "* " .. --ip .. 
    "BAlogin 0.1 0" .. "\n"
    tcp:send(login.loginString)
    table.insert(login.log, {to = true, msg = "LOGIN " .. login.nameBox.text .. " " .. ip })
  elseif login.action == 2 then 
    login.registerString = "REGISTER " .. 
    login.nameBox.text .. 
    " " .. 
    login.passBox.base64 .. "\n"
    tcp:send(login.registerString)
    table.insert(login.log, {to = true, msg = "REGISTER " .. login.nameBox.text })
  end
--end
end

function login.connectToServer()
  login.action = 1
  if login.savePass then
    settings.add({
        name = login.nameBox.text,
        pass = login.passBox.base64,
        savePass = true
      })
  else
    settings.add({
        name = login.nameBox.text,
        pass = false,
        savePass = false
      })
  end
  if connect() then
    login.handleResponse()
  end
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
  if login.downloading then
    login.updateDownload(dt)
  end
  if login.unpacking then
    login.updateUnpack(dt)
  end
  if not tcp then return end
  lobby.timer = lobby.timer + dt
  if lobby.timer > 30 then
    tcp:send("PING" .. "\n")
    table.insert(login.log, {to = true, msg = "PING"})
    lobby.timer = 0
  end
  local data = tcp:receive()
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
end

function login.resize( w, h )
  login.width = w
  login.height = h
  lobby.width = w
  lobby.height = h
  loginBox.x = w/2
  loginBox.y = h/2
  login.nameBox:setPosition(
          loginBox.x - loginBox.w/2 + 30,
          loginBox.y - loginBox.h/2 + 50)
  login.passBox:setPosition(
          loginBox.x - loginBox.w/2 + 30,
          loginBox.y - loginBox.h/2 + 105)
  login.buttons.login:setPosition(
        loginBox.x + loginBox.w/2 - 210,
        loginBox.y + loginBox.h/2 - 50)
  login.buttons.register:setPosition(
        loginBox.x + loginBox.w/2 - 120,
        loginBox.y + loginBox.h/2 - 50)
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
    login.delay = 0.5
    --if login.mode == "login" then
      login.connectToServer()
    --elseif login.mode == "register" then
      --login.registerAccount()
    --end
  end,
  ["tab"] = function() 
    login.nameBox:toggle()
    login.passBox:toggle()
  end,
  ["escape"] = function()
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
  for _, k in pairs(login.buttons) do
    k:click(x, y)
  end
  login.savePassCheckbox:click(x,y)
end

function login.drawLoginBox()
  lg.setColor(colors.bgt)
  lg.rectangle("fill",
              loginBox.x-loginBox.w/2,
              loginBox.y-loginBox.h/2,
              loginBox.w, loginBox.h, 5)
  lg.setColor(colors.bd)
  login.nameBox:draw()
  login.passBox:draw()
  login.nameBox:renderText()
  login.passBox:renderText()
  lg.setFont(fonts.latoitalic)
  lg.setColor(colors.text)
  for _, k in pairs(login.buttons) do
    k:draw()
  end
  login.savePassCheckbox:draw()
end

function login.draw()
  lg.setColor(1,1,1)
  lg.draw(login.video, 0, 0, 0, login.width/1920, (login.height)/970)
  login.drawLoginBox()
  if not lobby.gotEngine then
    login.drawDownloadBars()
    login.drawDownloadText()
  end
  --
  lg.setFont(fonts.robotosmall)
  for i, k in pairs(login.log) do
    lg.print(k.msg, 10, 10 + 10*i)
  end
  --
end

function login.drawDownloadBars()
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

function login.drawDownloadText()
  lg.setColor(colors.bgt)
  lg.rectangle("fill", lobby.width/2 - 30, 10, 60, 20)
  lg.setColor(colors.text)
  lg.printf(login.downloadText, 0, 20, login.width, "center")
  local fontHeight = fonts.robotosmall:getHeight()
  if login.dl_status then
    if login.dl_status.file_size > 0 then
      local perc = math.floor(login.dl_status.downloaded / login.dl_status.file_size * 100)/100
      lg.print(perc .."%",  login.width/2-20, 20 + fontHeight)
    end
    if login.dl_status.err then
      lg.print(login.dl_status.err, 0, 32)
    end
  elseif login.unpackerCount then
    if login.unpackerCount > 0 then
      lg.print(login.unpackerCount .. "/" .. login.fileCount, login.width/2 + 10, 20 + fontHeight)
    end
  end
end