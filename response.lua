local bit = require("bit")
local lw = love.window
local lf = love.filesystem

local function ACCEPTED(words, sentences)
  lobby.username = login.nameBox.text
  login.nameBox.active = false
  login.passBox.active = false
  lobby.connected = true
  lobby.initialize()
end
local function ADDBOT(words, sentences)
end
local function ADDSTARTRECT(words, sentences)
  Battle:getActive().startrect[words[1] + 1] = {
    words[2]/200,
    words[3]/200,
    words[4]/200,
    words[5]/200
  }
  lobby.render.background()
end
local function ADDUSER(words, sentences)
  local existing_user = User.s[words[1]]
  local user = existing_user or {}
  user.name = words[1]
  user.country = words[2]
  user.flag = flag[user.country] or flag["XX"]
  user.status = 0
  user.rank = 1
  user.insignia = ranks[user.rank]
  user.away = false
  user.ingame = false
  user.access = 0
  user.isBot = false
  user.icon = false
  if user.name == lobby.username then
    user.ready = 0
    user.spectator = 1
    user.synced = 0
    user.color = 0
  end
  if existing_user then
    local chan = existing_user.channel 
    if chan then
      --table.insert(chan.lines, {time = os.date("%X"), msg = user.name .. " is now online."})
    end
    return
  end
  User:new(user)
end
local function AGREEMENT(words, sentences)
  table.insert(login.log, {from = true, msg = sentences[1] })
end
local function AGREEMENTEND(words, sentences)
  lobby.send("CONFIRMAGREEMENT")
  lobby.send(lobby.loginString)
  table.insert(login.log, {from = true, msg = reason })
end
local function BATTLECLOSED(words, sentences)
  local id = words[1]
  local active_battle = Battle:getActive()
  if active_battle and active_battle.id == id then
    active_battle:leave()
  end
  Battle.s[id] = nil
  Battle.count = Battle.count - 1
  lobby.refreshBattleTabs()
end
local function BATTLEOPENED(words, sentences)
  local battle = {}
  battle.id = words[1]
  battle.type = words[2]
  battle.natType = words[3]
  battle.founder = User.s[words[4]]
  battle.ip = words[5]
  battle.port = words[6]
  battle.maxPlayers = words[7]
  battle.passworded = words[8]
  battle.rank = words[9]
  battle.mapHash = words[10]
  
  battle.engineName = sentences[2]
  battle.engineVersion = sentences[2]
  
  battle.mapName = ""
  --[[for i = 12, #words do
    battle.mapName = battle.mapName .. " " .. words[i]
  end]]
  battle.title = string.gsub(string.gsub(sentences[2], "%a+ ", "", 1), "%b() ", "", 1)
  battle.gameName = sentences[#sentences] or "gameName"
  
  --battle.channel = words[16]
  battle.tab = BattleTab:new(battle.id)
  Battle.s[battle.id] = Battle:new(battle)
  Battle.count = Battle.count + 1
  
  lobby.refreshBattleTabs()
end
local function BRIDGEDCLIENTFROM(words, sentences)
end
local function CHANGEEMAILACCEPTED(words, sentences)
end
local function CHANGEEMAILDENIED(words, sentences)
end
local function CHANGEEMAILREQUESTACCEPTED(words, sentences)
end
local function CHANGEEMAILREQUESTDENIED(words, sentences)
end
local function CHANNEL(words, sentences)
  local chan = words[1]
  lobby.channels[chan] = words[2]
  lobby.channel_topics[chan] = words[3]
  lobby.render.userlist()
end
local function CHANNELMESSAGE(words, sentences)
end
local function CHANNELTOPIC(words, sentences)
end
local function CLIENTBATTLESTATUS(words, sentences)
  local username = words[1]
  local battleStatus = words[2]
  local teamColor = words[3]
  local user = User.s[username]

  local tab = {}
  local n = tonumber(battleStatus)
  for i = 0, 31 do
    tab[i] = bit.band(n,1)
    n=bit.rshift(n,1)
  end

  user.battleStatus = battleStatus
  
  user.ready = tab[1] == 1
  user.teamNo = tab[5]*8 + tab[4]*4 + tab[3]*2 + tab[2] + 1
  user.allyTeamNo = tab[9]*8 + tab[8]*4 + tab[7]*2 + tab[6] + 1
  user.isSpectator = tab[10] == 0
  user.handicap = tab[11]*64 + tab[12]*32 + tab[13]*16 + tab[14]*8 + tab[15]*4 + tab[16]*2 + tab[17]
  user.syncStatus = tab[23]*2 + tab[22]
  user.side = tab[24]*8 + tab[25]*4 + tab[26]*2 + tab[27]
  
  user.teamColor = teamColor
  
  local coltab = {}
  n = tonumber(teamColor)
  for i = 1, 4 do
    local p = 1
    coltab[i] = 0
    for j = 1, 8 do
      coltab[i] = coltab[i] + p * bit.band(n,1)
      p = p * 2
      n=bit.rshift(n,1)
    end
  end
  -- pack
  -- c = ((a & 0xff) << 24) | ((b & 0xff) << 16) | ((g & 0xff) << 8) | (r & 0xff)

  user.teamColorUnpacked = coltab
  --[[ unpack
  user.teamColorUnpacked[1] = bit.band(teamColor,0x000000ff)
  user.teamColorUnpacked[2] = bit.band(bit.rshift(teamColor,8), 0x000000ff)
  user.teamColorUnpacked[3] = bit.band(bit.rshift(teamColor,16), 0x000000ff)
  user.teamColorUnpacked[4] = bit.band(bit.rshift(teamColor,24), 0x000000ff)  ]]

  local teams = {}
  local battle = Battle:getActive()
  for i=1,16 do
    for username, user in pairs(battle.users) do
      if not user.isSpectator and i == user.allyTeamNo then
        table.insert(teams, user)
      end
    end
  end
  battle.playersByTeam = teams
  battle.teamCount = #teams
  
  --[[if username == lobby.username then
    if user.ready then 
      battle.buttons.ready:setTextColor(colors.text)
    else
      battle.buttons.ready:setTextColor(colors.bt)
    end
    if user.isSpectator then
      battle.buttons.spectate:setTextColor(colors.bt)
      battle.buttons.spectate:setText("Unspectate")
    else
      battle.buttons.spectate:setTextColor(colors.text)
      battle.buttons.spectate:setText("Spectate")
    end
  end]]
  
  lobby.render.background()
end
local function CLIENTIPPORT(words, sentences)
end
local function CLIENTS(words, sentences)
  local chan = words[1]
  for i = 2, #words do
    Channel.s[chan].users[words[i]] = User.s[words[i]]
  end
  lobby.render.userlist()
end
local function CLIENTSFROM(words, sentences)
end
local function CLIENTSTATUS(words, sentences)
  local username = words[1]
  local status = words[2]
  local user = User.s[username]
  user.status = status
  
  local statusTable = {}
  local n = tonumber(status)
  local i = 0
  for i = 0, 6 do
    statusTable[i] = bit.band(n,1)
    n=bit.rshift(n,1)
  end

  user.ingame = statusTable[0] == 1
  user.away = statusTable[1] == 1
  user.rank = statusTable[4] * 4 + statusTable[3] * 2 + statusTable[2]
  user.insignia = ranks[user.rank+1] or ranks[1]
  user.access = statusTable[5]
  user.isBot = statusTable[6] == 1
  user.isHuman = not user.isBot
  
  user.icon = user.isBot and "server" or user.ingame and "gamepad" or user.away and "nothome" or false
  
  
  local battle = Battle:getActive()
  if battle and battle.founder == user and user.ingame and lobby.launchOnGameStart then
    lobby.launchSpring()
  end
end
local function COMPFLAGS(words, sentences)
end
local function DENIED(words, sentences)
end
local function DISABLEUNITS(words, sentences)
end
local function ENABLEALLUNITS(words, sentences)
end
local function ENABLEUNITS(words, sentences)
end
local function ENDOFCHANNELS(words, sentences)
  
  lobby.render.userlist()
  --[[local text = "Index Name Users\n"
  for id, channel in pairs(lobby.channels) do
    text = text .. id .. ". #" .. channel.name .. ", " .. channel.users .. "\n"
  end
  lw.showMessageBox("Channel List", text, "info" )]]
end
local function FAILED(words, sentences)
  lw.showMessageBox("FAILED", "REASON: " .. string.gsub(sentences[1], "%S+ ", "", 1), "info" )
end
local function FORCEQUITBATTLE(words, sentences)
  local battle = Battle:getActive()
  if battle then battle:leave(true) end
  lw.showMessageBox("For your information", "You were kicked from the battle!", "info" )
end
local function HOSTPORT(words, sentences)
  local port = words[1]
  Battle:getActive().hostport = port
end
local function IGNORE(words, sentences)
end
local function IGNORELIST(words, sentences)
end
local function IGNORELISTBEGIN(words, sentences)
end
local function IGNORELISTEND(words, sentences)
end
local function JOIN(words, sentences)
  local channelname = words[1]
  local channel = Channel.s[channelname]
  if not channel then
    channel = Channel:new({title = channelname, isChannel = true})
    if lobby.channel_topics[channel] then
      Channel.onMessage(lobby.channel_topics[channelname] .. " **" .. "\n", channelname, "", false, true)
      --table.insert(Channel.s[chan].lines, lobby.channel_topics[chan])
    end
    if channelname == "main" then
      channel.isMain = true
      for i = 1, #lobby.MOTD do
        Channel.onMessage(lobby.MOTD[i].msg .. " **" .. "\n", channelname, "", false, true)
        --table.insert(Channel.s[chan].lines, lobby.MOTD[i])
      end
    end
  end
  channel:open()
end
local function JOINBATTLE(words, sentences)
  local id = words[1]
  local hashCode = words[2]
  local channel = words[3]
  Battle.active = Battle.s[id]
  if not Battle.active.channel then
    Battle.active.channel = Channel:new({title = "Battle_" .. id, isBattle = true})
  else
    Battle.active.channel.display = true
  end
  sound.down:play()
  Battle.active:joined(id)
  --lobby.refreshUserButtons()
  Battle.enter(true)
end
local function JOINBATTLEFAILED(words, sentences)
  --Channel:broadcast("REQUEST TO JOIN BATTLE FAILED, REASON: " .. string.gsub(sentences[1], "%S+ ", "", 1))
  --lw.showMessageBox("REQUEST TO JOIN BATTLE FAILED", "REASON: " .. string.gsub(sentences[1], "%S+ ", "", 1), "info" )
end
local function JOINBATTLEREQUEST(words, sentences)
end
local function JOINED(words, sentences)
  local chan = words[1]
  local user = words[2]
  Channel.s[chan].users[user] = User.s[user]
  lobby.render.userlist()
end
local function JOINEDBATTLE(words, sentences)
  local battleid = words[1]
  local user = words[2]
  local scriptPassword = words[3]
  User.s[user].battleid = battleid
  Battle.s[battleid].users[user] = User.s[user]
  Battle.s[battleid].userCount = Battle.s[battleid].userCount + 1
  Battle.s[battleid].scriptPassword = scriptPassword
  local battle = Battle:getActive()
  if battle and battleid == battle.id then
    local chan = battle:getChannel()
    --table.insert(chan.lines, {time = os.date("%X"), green = true, msg = user .." has joined the battle."})
    Battle.render()
  end
  
  lobby.refreshBattleTabs()
end
local function JOINEDFROM(words, sentences)
end
local function JOINFAILED(words, sentences)
  --table.insert(Channel.s[words[1]].lines, {msg = "Failure to join channel, reason: " .. words[2]})
end
local function JSON(words, sentences)
end
local function KICKFROMBATTLE(words, sentences)
end
local function LEFT(words, sentences)
  local channelname = words[1]
  local username = words[2]
  if username == lobby.username then
    Channel.s[channelname].display = false
    if not Channel.active then Channel.active = Channel.s["main"] end
    Channel:refreshTabs()
  end
  lobby.render.userlist()
end
local function LEFTBATTLE(words, sentences)
  local battleid = words[1]
  local user = words[2]
  Battle.s[battleid].users[user] = nil
  Battle.s[battleid].userCount = Battle.s[battleid].userCount - 1
  User.s[user].battleid = nil
  
  local battle = Battle:getActive()
  if battle and battleid == battle.id then
    local chan = battle:getChannel()
    --table.insert(chan.lines, {time = os.date("%X"), green = true, msg = user .." has left the battle."})
    Battle.render()
  end

  lobby.refreshBattleTabs()
end
local function LEFTFROM(words, sentences)
end
local function LOGININFOEND(words, sentences)
  lobby.send("JOIN en")
  lobby.send("JOIN newbies")
  lobby.send("JOIN main")
  lobby.loginInfoEnd = true
  lobby.refreshBattleTabs()
  lobby.render.background()
  lobby.render.userlist()
end
local function MOTD(words, sentences)
  --Channel.onMessage(" " .. string.gsub(sentences[1], "%u+ ", "", 1) .. " **" .. "\n", "main", "", false, true)
  table.insert(lobby.MOTD, {time = os.date("%X"), user = "", ex = true, msg = string.gsub(sentences[1], "%u+ ", "", 1)})
end
local function OK(words, sentences)
  local k, v = words[1]:match("(.+)=(.+)")
  login.handleResponse(k, v)
end
local function OPENBATTLE(words, sentences)
  local battleid = words[1]
  Battle.enter(true)--)
  Battle.s[battleid].users[lobby.username] = User.s[lobby.username]
  Battle.s[battleid].userCount = Battle.s[battleid].userCount + 1
end
local function OPENBATTLEFAILED(words, sentences)
  lw.showMessageBox("OPENBATTLEFAILED", "OPENBATTLEFAILED " .. sentences[1], "info" )
end
local function PONG(words, sentences)
  lobby.timeSinceLastPong = 0
end
local function REDIRECT(words, sentences)
end
local function REGISTRATIONACCEPTED(words, sentences)
  local reason = sentences[1]
  table.insert(login.log, {from = true, msg = reason })  lw.showMessageBox("Registration Accepted", "Please login again", "info" )
end
local function REGISTRATIONDENIED(words, sentences)
  local reason = sentences[1]
  table.insert(login.log, {from = true, msg = reason })
  lw.showMessageBox("Registration Denied", "REASON: " .. string.gsub(sentences[1], "%S+ ", "", 1), "info" )
end
local function REMOVEBOT(words, sentences)
end
local function REMOVESCRIPTTAGS(words, sentences)
  local battle = Battle:getActive()
  for i = 2, #sentences do
    local tbl = battle
    local c = sentences[i]:gmatch("(/[^/]+)")
    for w in sentences[i]:gmatch("([^/]+)") do
      if w == c then
        tbl[w] = nil
      else
        tbl = tbl[w]
      end
    end
  end
  lobby.render.background()
end
local function REMOVESTARTRECT(words, sentences)
  Battle:getActive().startrect[words[1]] = nil
  lobby.render.background()
end
local function REMOVEUSER(words, sentences)
  local user = words[1]
  local chan = User.s[user].channel
  if chan then
    table.insert(chan.lines, {time = os.date("%X"), msg = user .. " is now offline."})
  else
    User.s[user] = nil
  end
end
local function REQUESTBATTLESTATUS(words, sentences)
  local user = User.s[lobby.username]
  user.ready = false
  user.spectator = false
  user.newAllyTeamNo = 0
  user.newTeamNo = 0
  user.newSide = 0
  lobby.sendMyBattleStatus()
end
local function RESENDVERIFICATIONACCEPTED(words, sentences)
end
local function RESENDVERIFICATIONDENIED(words, sentences)
end
local function RESETPASSWORDACCEPTED(words, sentences)
end
local function RESETPASSWORDDENIED(words, sentences)
end
local function RESETPASSWORDREQUESTACCEPTED(words, sentences)
end
local function RESETPASSWORDREQUESTDENIED(words, sentences)
end
local function RING(words, sentences)
  sound["ring"]:play()
end
local function SAID(words, sentences, data)
  local channelname = words[1]
  local username = words[2]
  local text = string.gsub(sentences[1], "%S+", "", 3) .. "\n"
  
  --[[for link in text:gmatch("http[s]*://%S+") do
    local links = links or {}
    local i, j = string.find(text, link)
    table.insert(links, {link = link, i = i, j = j})
  end]]
  
  Channel.onMessage(text, channelname, username, false, false)
  --table.insert(Channel.s[chan].lines, {time = os.date("%X"), links = links, mention = mention, user = user, msg = text})
  lobby.render.foreground()
  lf.write( "chatlogs/" .. channelname .. ".txt", username .. ": " .. text )
end
local function SAIDBATTLE(words, sentences)
  local username = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  local battle = Battle:getActiveBattle()
  local founder = battle.founder
  local channel = battle:getChannel()
  local ingame = false
  
  if username == founder.name and not battle.isMyBattle then
    ingame = true
    username = "INGAME"
  end
  Channel.onMessage(text, battle.channel.title, username, true, false)
  --table.insert(chan.lines, {time = os.date("%X"), ingame = ingame, mention = mention, user = user, msg = text})
  lobby.render.foreground()
end
local function SAIDBATTLEEX(words, sentences)
  local username = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  local battle = Battle:getActiveBattle()
  local founder = battle.founder
  
  Channel.onMessage(text, battle.channel.title, username, true, true)
  
  if username == founder.name then
    --table.insert(battle:getChannel().infolines, {time = os.date("%X"), ex = true, user = user, msg = text})
  else
    --table.insert(battle:getChannel().lines, {time = os.date("%X"), mention = mention, ex = true, user = user, msg = text})
  end
  lobby.render.foreground()
end
local function SAIDEX(words, sentences)
  local channelname = words[1]
  local username = words[2]
  local text = string.gsub(sentences[1], "%S+", "", 3) .. "\n"

  --[[for link in text:gmatch("http[s]*://%S+") do
    local links = links or {}
    local i, j = string.find(text, link)
    table.insert(links, {link = link, i = i, j = j})
  end]]
  
  Channel.onMessage(text, channelname, username, false, true)
  --table.insert(Channel.s[chan].lines, {time = os.date("%X"), links = links, mention = mention, ex = true, user = user, msg = text})
  lobby.render.foreground()
  lf.write( "chatlogs/" .. channelname .. ".txt", username .. ": " .. text )
end
local function SAIDFROM(words, sentences)
end
local function SAIDPRIVATE(words, sentences)
  local username = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  if not Channel.s[username] then
    User.s[username]:openChannel()
  end

  Channel.onMessage(text, username, username, false, false)
  
  --table.insert(Channel.s[user].lines, {time = os.date("%X"), user = user, msg = text})
  lobby.render.foreground()
  lf.write( "chatlogs/" .. username .. ".txt", username .. ": " .. text )
end
local function SAIDPRIVATEEX(words, sentences)
  local username = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  if not Channel.s[user] then
    User.s[user]:openChannel()
  end
  
  Channel.onMessage(text, username, username, false, false)
  
  --table.insert(Channel.s[user].lines, {time = os.date("%X"), ex = true, user = user, msg = text})
  lobby.render.foreground()
  lf.write( "chatlogs/" .. username .. ".txt", username .. ": " .. text )
end
local function SAYPRIVATE(words, sentences)
  local username = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  
  Channel.onMessage(text, username, username, false, false)
  --table.insert(Channel.s[user].lines, {time = os.date("%X"), user = lobby.username, msg = text})
  lobby.render.foreground()
  lf.write( "chatlogs/" .. username .. ".txt", username .. ": " .. text )
end
local function SAYPRIVATEEX(words, sentences)
  local username = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  
  Channel.onMessage(text, username, username, false, true)
  
  --table.insert(Channel.s[user].lines, {time = os.date("%X"), ex = true, user = lobby.username, msg = text})
  lobby.render.foreground()
  lf.write( "chatlogs/" .. username .. ".txt", username .. ": " .. text )
end
local function SERVERMSG(words, sentences)
end
local function SERVERMSGBOX(words, sentences)
end
local function SETSCRIPTTAGS(words, sentences)
  local battle = Battle:getActive()
  for i = 2, #sentences do
    local tbl = battle
    for w in sentences[i]:gmatch("([^/]+)") do
      local k, v = w:match("(.+)=(.+)")
      if k and v then
        if k == "mo_ffa" then
          if v == "1" then
            battle.ffa = true
          elseif v == 0 then
            battle.ffa = false
          end
        end
        tbl[k] = v
      else
        tbl[w] = tbl[w] or {}
        tbl = tbl[w]
      end
    end
  end
  lobby.render.background()
end
local function TASS(words, sentences)
  login.handleResponse("tass")
end
local function UDPSOURCEPORT(words, sentences)
end
local function UNBRIDGEDCLIENTFROM(words, sentences)
end
local function UNIGNORE(words, sentences)
end
local function UPDATEBATTLEINFO(words, sentences)
  local id = words[1]
  local battle = Battle.s[id]
  if not battle then return end
  local spectatorCount = words[2] or 0
  local locked = words[3]
  local mapHash = words[4]
  local mapName = string.gsub(string.gsub(sentences[1], "%a+ ", "", 1), "-*%d+ ", "", 4)
  battle.locked = locked
  battle.mapHash = mapHash
  battle.spectatorCount = spectatorCount
  if battle.mapName == "" then
    battle.mapName = mapName
    battle:getMinimap()
  elseif battle.mapName ~= mapName then
    battle.minimap = nil
    battle.metalmap = nil
    battle.heightmap = nil
    battle.mapWidthHeightRatio = nil
    battle.mapW = nil
    battle.mapH = nil
    battle.mapName = mapName
    local active_battle = Battle:getActive()
    if active_battle and active_battle.id == id then
      battle.game.mapoptions = nil
      for i = 1,16 do
        battle.startrect[i] = nil
      end
      if battle:mapHandler() then
        lobby.setSynced(true)
        battle:getMinimap()
      end
    end
  end
  lobby.refreshBattleTabs()
end
local function UPDATEBOT(words, sentences)
end
local responses = {
  ["ACCEPTED"] = ACCEPTED,
  ["ADDBOT"] = ADDBOT,
  ["ADDSTARTRECT"] = ADDSTARTRECT,
  ["ADDUSER"] = ADDUSER,
  ["AGREEMENT"] = AGREEMENT,
  ["AGREEMENTEND"] = AGREEMENTEND,
  ["BATTLECLOSED"] = BATTLECLOSED,
  ["BATTLEOPENED"] = BATTLEOPENED,
  ["BRIDGEDCLIENTFROM"] = BRIDGEDCLIENTFROM,
  ["CHANGEEMAILACCEPTED"] = CHANGEEMAILACCEPTED,
  ["CHANGEEMAILDENIED"] = CHANGEEMAILDENIED,
  ["CHANGEEMAILREQUESTACCEPTED"] = CHANGEEMAILREQUESTACCEPTED,
  ["CHANGEEMAILREQUESTDENIED"] = CHANGEEMAILREQUESTDENIED,
  ["CHANNEL"] = CHANNEL,
  ["CHANNELMESSAGE"] = CHANNELMESSAGE,
  ["CHANNELTOPIC"] = CHANNELTOPIC,
  ["CLIENTBATTLESTATUS"] = CLIENTBATTLESTATUS,
  ["CLIENTIPPORT"] = CLIENTIPPORT,
  ["CLIENTS"] = CLIENTS,
  ["CLIENTSFROM"] = CLIENTSFROM,
  ["CLIENTSTATUS"] = CLIENTSTATUS,
  ["COMPFLAGS"] = COMPFLAGS,
  ["DENIED"] = DENIED,
  ["DISABLEUNITS"] = DISABLEUNITS,
  ["ENABLEALLUNITS"] = ENABLEALLUNITS,
  ["ENABLEUNITS"] = ENABLEUNITS,
  ["ENDOFCHANNELS"] = ENDOFCHANNELS,
  ["FAILED"] = FAILED,
  ["FORCEQUITBATTLE"] = FORCEQUITBATTLE,
  ["HOSTPORT"] = HOSTPORT,
  ["IGNORE"] = IGNORE,
  ["IGNORELIST"] = IGNORELIST,
  ["IGNORELISTBEGIN"] = IGNORELISTBEGIN,
  ["IGNORELISTEND"] = IGNORELISTEND,
  ["JOIN"] = JOIN,
  ["JOINBATTLE"] = JOINBATTLE,
  ["JOINBATTLEFAILED"] = JOINBATTLEFAILED,
  ["JOINBATTLEREQUEST"] = JOINBATTLEREQUEST,
  ["JOINED"] = JOINED,
  ["JOINEDBATTLE"] = JOINEDBATTLE,
  ["JOINEDFROM"] = JOINEDFROM,
  ["JOINFAILED"] = JOINFAILED,
  ["JSON"] = JSON,
  ["KICKFROMBATTLE"] = KICKFROMBATTLE,
  ["LEFT"] = LEFT,
  ["LEFTBATTLE"] = LEFTBATTLE,
  ["LEFTFROM"] = LEFTFROM,
  ["LOGININFOEND"] = LOGININFOEND,
  ["MOTD"] = MOTD,
  ["OK"] = OK,
  ["OPENBATTLE"] = OPENBATTLE,
  ["OPENBATTLEFAILED"] = OPENBATTLEFAILED,
  ["PONG"] = PONG,
  ["REDIRECT"] = REDIRECT,
  ["REGISTRATIONACCEPTED"] = REGISTRATIONACCEPTED,
  ["REGISTRATIONDENIED"] = REGISTRATIONDENIED,
  ["REMOVEBOT"] = REMOVEBOT,
  ["REMOVESCRIPTTAGS"] = REMOVESCRIPTTAGS,
  ["REMOVESTARTRECT"] = REMOVESTARTRECT,
  ["REMOVEUSER"] = REMOVEUSER,
  ["REQUESTBATTLESTATUS"] = REQUESTBATTLESTATUS,
  ["RESENDVERIFICATIONACCEPTED"] = RESENDVERIFICATIONACCEPTED,
  ["RESENDVERIFICATIONDENIED"] = RESENDVERIFICATIONDENIED,
  ["RESETPASSWORDACCEPTED"] = RESETPASSWORDACCEPTED,
  ["RESETPASSWORDDENIED"] = RESETPASSWORDDENIED,
  ["RESETPASSWORDREQUESTACCEPTED"] = RESETPASSWORDREQUESTACCEPTED,
  ["RESETPASSWORDREQUESTDENIED"] = RESETPASSWORDREQUESTDENIED,
  ["RING"] = RING,
  ["SAID"] = SAID,
  ["SAIDBATTLE"] = SAIDBATTLE,
  ["SAIDBATTLEEX"] = SAIDBATTLEEX,
  ["SAIDEX"] = SAIDEX,
  ["SAIDFROM"] = SAIDFROM,
  ["SAIDPRIVATE"] = SAIDPRIVATE,
  ["SAIDPRIVATEEX"] = SAIDPRIVATEEX,
  ["SAYPRIVATE"] = SAYPRIVATE,
  ["SAYPRIVATEEX"] = SAYPRIVATEEX,
  ["SERVERMSG"] = SERVERMSG,
  ["SERVERMSGBOX"] = SERVERMSGBOX,
  ["SETSCRIPTTAGS"] = SETSCRIPTTAGS,
  ["TASS"] = TASS,
  ["UDPSOURCEPORT"] = UDPSOURCEPORT,
  ["UNBRIDGEDCLIENTFROM"] = UNBRIDGEDCLIENTFROM,
  ["UNIGNORE"] = UNIGNORE,
  ["UPDATEBATTLEINFO"] = UPDATEBATTLEINFO,
  ["UPDATEBOT"] = UPDATEBOT,
}

return responses