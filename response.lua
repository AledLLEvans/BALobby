local bit = require("bit")
local lw = love.window
local ACCEPTED = {}
local ADDBOT = {}
local ADDSTARTRECT = {}
local ADDUSER = {}
local AGREEMENT = {}
local AGREEMENTEND = {}
local BATTLECLOSED = {}
local BATTLEOPENED = {}
local BRIDGEDCLIENTFROM = {}
local CHANGEEMAILACCEPTED = {}
local CHANGEEMAILDENIED = {}
local CHANGEEMAILREQUESTACCEPTED = {}
local CHANGEEMAILREQUESTDENIED = {}
local CHANNEL = {}
local CHANNELMESSAGE = {}
local CHANNELTOPIC = {}
local CLIENTBATTLESTATUS = {}
local CLIENTIPPORT = {}
local CLIENTS = {}
local CLIENTSFROM = {}
local CLIENTSTATUS = {}
local COMPFLAGS = {}
local DENIED = {}
local DISABLEUNITS = {}
local ENABLEALLUNITS = {}
local ENABLEUNITS = {}
local ENDOFCHANNELS = {}
local FAILED = {}
local FORCEQUITBATTLE = {}
local HOSTPORT = {}
local IGNORE = {}
local IGNORELIST = {}
local IGNORELISTBEGIN = {}
local IGNORELISTEND = {}
local JOIN = {}
local JOINBATTLE = {}
local JOINBATTLEFAILED = {}
local JOINBATTLEREQUEST = {}
local JOINED = {}
local JOINEDBATTLE = {}
local JOINEDFROM = {}
local JOINFAILED = {}
local JSON = {}
local KICKFROMBATTLE = {}
local LEFT = {}
local LEFTBATTLE = {}
local LEFTFROM = {}
local LOGININFOEND = {}
local MOTD = {}
local OK = {}
local OPENBATTLE = {}
local OPENBATTLEFAILED = {}
local PONG = {}
local REDIRECT = {}
local REGISTRATIONACCEPTED = {}
local REGISTRATIONDENIED = {}
local REMOVEBOT = {}
local REMOVESCRIPTTAGS = {}
local REMOVESTARTRECT = {}
local REMOVEUSER = {}
local REQUESTBATTLESTATUS = {}
local RESENDVERIFICATIONACCEPTED = {}
local RESENDVERIFICATIONDENIED = {}
local RESETPASSWORDACCEPTED = {}
local RESETPASSWORDDENIED = {}
local RESETPASSWORDREQUESTACCEPTED = {}
local RESETPASSWORDREQUESTDENIED = {}
local RING = {}
local SAID = {}
local SAIDBATTLE = {}
local SAIDBATTLEEX = {}
local SAIDEX = {}
local SAIDFROM = {}
local SAIDPRIVATE = {}
local SAIDPRIVATEEX = {}
local SAYPRIVATE = {}
local SAYPRIVATEEX = {}
local SERVERMSG = {}
local SERVERMSGBOX = {}
local SETSCRIPTTAGS = {}
local TASSERVER = {}
local UDPSOURCEPORT = {}
local UNBRIDGEDCLIENTFROM = {}
local UNIGNORE = {}
local UPDATEBATTLEINFO = {}
local UPDATEBOT = {}

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
  ["TASSERVER"] = TASSERVER,
  ["UDPSOURCEPORT"] = UDPSOURCEPORT,
  ["UNBRIDGEDCLIENTFROM"] = UNBRIDGEDCLIENTFROM,
  ["UNIGNORE"] = UNIGNORE,
  ["UPDATEBATTLEINFO"] = UPDATEBATTLEINFO,
  ["UPDATEBOT"] = UPDATEBOT,
}

function ACCEPTED.respond(words, sentences)
  lobby.username = login.nameBox.text
  login.nameBox.active = false
  login.passBox.active = false
  lobby.connected = true
  lobby.enter()
end
function ADDBOT.respond(words, sentences)
end
function ADDSTARTRECT.respond(words, sentences)
end
function ADDUSER.respond(words, sentences)
  local user = {}
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
  User:new(user)
end
function AGREEMENT.respond(words, sentences)
  table.insert(login.log, {from = true, msg = sentences[1] })
end
function AGREEMENTEND.respond(words, sentences)
  lobby.send("CONFIRMAGREEMENT" .. "\n")
  lobby.send(lobby.loginString)
  table.insert(login.log, {from = true, msg = reason })
end
function BATTLECLOSED.respond(words, sentences)
  local id = words[1]
  Battle.s[id] = nil
  Battle.count = Battle.count - 1
  lobby.refreshBattleTabs()
end
function BATTLEOPENED.respond(words, sentences)
  local battle = {}
  battle.id = words[1]
  battle.type = words[2]
  battle.natType = words[3]
  battle.founder = words[4]
  battle.ip = words[5]
  battle.port = words[6]
  battle.maxPlayers = words[7]
  battle.passworded = words[8]
  battle.rank = words[9]
  battle.mapHash = words[10]
  
  battle.engineName = sentences[2]
  battle.engineVersion = sentences[2]
  
  battle.mapName = words[11]
  for i = 12, #words do
    battle.mapName = battle.mapName .. " " .. words[i]
  end
  battle.title = string.gsub(string.gsub(sentences[2], "%a+ ", "", 1), "%b() ", "", 1)
  battle.gameName = sentences[#sentences] or "gameName"
  
  --battle.channel = words[16]
  
  Battle:new(battle)
  lobby.refreshBattleTabs()
end
function BRIDGEDCLIENTFROM.respond(words, sentences)
end
function CHANGEEMAILACCEPTED.respond(words, sentences)
end
function CHANGEEMAILDENIED.respond(words, sentences)
end
function CHANGEEMAILREQUESTACCEPTED.respond(words, sentences)
end
function CHANGEEMAILREQUESTDENIED.respond(words, sentences)
end
function CHANNEL.respond(words, sentences)
end
function CHANNELMESSAGE.respond(words, sentences)
end
function CHANNELTOPIC.respond(words, sentences)
end
function CLIENTBATTLESTATUS.respond(words, sentences)
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
  user.syncStatus = tab[22]*2 + tab[23]
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
  
  if username == lobby.username then
    if user.ready then 
      battle.buttons.ready:setTextColor(colors.w)
    else
      battle.buttons.ready:setTextColor(colors.bt)
    end
    if user.isSpectator then
      battle.buttons.spectate:setTextColor(colors.bt)
    else
      battle.buttons.spectate:setTextColor(colors.w)
    end
  end
  
  lobby.render()
end
function CLIENTIPPORT.respond(words, sentences)
end
function CLIENTS.respond(words, sentences)
  local chan = words[1]
  for i = 2, #words do
    Channel.s[chan].users[words[i]] = User.s[words[i]]
  end
end
function CLIENTSFROM.respond(words, sentences)
end
function CLIENTSTATUS.respond(words, sentences)
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
  
  user.icon = user.isBot and "monitor" or user.ingame and "gamepad" or user.away and "nothome" or false
end
function COMPFLAGS.respond(words, sentences)
end
function DENIED.respond(words, sentences)
end
function DISABLEUNITS.respond(words, sentences)
end
function ENABLEALLUNITS.respond(words, sentences)
end
function ENABLEUNITS.respond(words, sentences)
end
function ENDOFCHANNELS.respond(words, sentences)
end
function FAILED.respond(words, sentences)
end
function FORCEQUITBATTLE.respond(words, sentences)
  Battle:getActiveBattle():getChannel():addMessage("You were kicked from the battle!")
  lw.showMessageBox("For your information", "You were kicked from the battle!", "info" )
end
function HOSTPORT.respond(words, sentences)
  local port = words[1]
  Battle:getActiveBattle().hostport = port
end
function IGNORE.respond(words, sentences)
end
function IGNORELIST.respond(words, sentences)
end
function IGNORELISTBEGIN.respond(words, sentences)
end
function IGNORELISTEND.respond(words, sentences)
end
function JOIN.respond(words, sentences)
  local chan = words[1]
  Channel:new({title = chan})
  if chan == "main" then
    Channel.active = Channel.s[chan]
    for i = 1, #lobby.MOTD do
      table.insert(Channel.s[chan].lines, lobby.MOTD[i])
    end
  end
  lobby.refreshUserButtons()
  Channel:refreshTabs()
end
function JOINBATTLE.respond(words, sentences)
  local id = words[1]
  local hashCode = words[2]
  local channel = words[3]
  Battle.active = Battle.s[id]
  if not Battle.active.channel then
    Battle.active.channel = BattleChannel:new({title = "Battle_" .. id})
  else
    Battle.active.channel.display = true
  end
  Battle.active:joined(id)
  lobby.refreshUserButtons()
  Battle.enter()
end
function JOINBATTLEFAILED.respond(words, sentences)
  Channel:broadcast(" REQUEST TO JOIN BATTLE FAILED, REASON: " .. string.gsub(sentences[1], "%S+ ", "", 1))
  lw.showMessageBox("REQUEST TO JOIN BATTLE FAILED", "REASON: " .. string.gsub(sentences[1], "%S+ ", "", 1), "info" )
end
function JOINBATTLEREQUEST.respond(words, sentences)
end
function JOINED.respond(words, sentences)
  local chan = words[1]
  local user = words[2]
  Channel.s[chan].users[user] = User.s[user]
end
function JOINEDBATTLE.respond(words, sentences)
  local battleid = words[1]
  local user = words[2]
  local scriptPassword = words[3]
  User.s[user].battleid = battleid
  Battle.s[battleid].users[user] = User.s[user]
  Battle.s[battleid].userCount = Battle.s[battleid].userCount + 1
  Battle.s[battleid].scriptPassword = scriptPassword
  lobby.refreshBattleTabs()
end
function JOINEDFROM.respond(words, sentences)
end
function JOINFAILED.respond(words, sentences)
  table.insert(Channel.s[words[1]].lines, {msg = "Failure to join channel, reason: " .. words[2]})
end
function JSON.respond(words, sentences)
end
function KICKFROMBATTLE.respond(words, sentences)
end
function LEFT.respond(words, sentences)
  local chan = words[1]
  local user = words[2]
  Channel.s[chan].users[user] = nil
  if user == lobby.username then
    Channel.s[chan].display = false
    Channel:refreshTabs()
  end
end
function LEFTBATTLE.respond(words, sentences)
  local battleid = words[1]
  local user = words[2]
  Battle.s[battleid].users[user] = nil
  Battle.s[battleid].userCount = Battle.s[battleid].userCount - 1
  User.s[user].battleid = nil
  lobby.refreshBattleTabs()
end
function LEFTFROM.respond(words, sentences)
end
function LOGININFOEND.respond(words, sentences)
  lobby.send("JOIN main" .. "\n")
  lobby.send("JOIN en" .. "\n")
  lobby.send("JOIN newbies" .. "\n")
  lobby.refreshBattleTabs()
  lobby.loginInfoEnd = true
  lobby.refreshBattleTabs()
end
function MOTD.respond(words, sentences)
  table.insert(lobby.MOTD, {time = os.date("%X"), user = "", ex = true, msg = " " .. string.gsub(sentences[1], "%u+ ", "", 1) .. " **" .. "\n"})
end
function OK.respond(words, sentences)
end
function OPENBATTLE.respond(words, sentences)
end
function OPENBATTLEFAILED.respond(words, sentences)
end
function PONG.respond(words, sentences)
  lobby.timeSinceLastPong = 0
end
function REDIRECT.respond(words, sentences)
end
function REGISTRATIONACCEPTED.respond(words, sentences)
  local reason = sentences[1]
  table.insert(login.log, {from = true, msg = reason })
end
function REGISTRATIONDENIED.respond(words, sentences)
  local reason = sentences[1]
  table.insert(login.log, {from = true, msg = reason })
end
function REMOVEBOT.respond(words, sentences)
end
function REMOVESCRIPTTAGS.respond(words, sentences)
  local battle = Battle:getActive()
  print("remove")
  for i = 2, #sentences do
    print(sentences[i])
    local tbl = battle
    local c = sentences[i]:gmatch("(/[^/]+)")
    print("c: " .. c)
    for w in sentences[i]:gmatch("([^/]+)") do
      print(w)
      if w == c then
        tbl[w] = nil
      else
        tbl = tbl[w]
      end
    end
  end
  lobby.render()
end
function REMOVESTARTRECT.respond(words, sentences)
end
function REMOVEUSER.respond(words, sentences)
  local user = words[1]
  User.s[user] = nil
  for name, chan in pairs(Channel.s) do
    chan.users[user] = nil
  end
end
function REQUESTBATTLESTATUS.respond(words, sentences)
  User.s[lobby.username].ready = false
  User.s[lobby.username].spectator = true
  lobby.sendMyBattleStatus()
end
function RESENDVERIFICATIONACCEPTED.respond(words, sentences)
end
function RESENDVERIFICATIONDENIED.respond(words, sentences)
end
function RESETPASSWORDACCEPTED.respond(words, sentences)
end
function RESETPASSWORDDENIED.respond(words, sentences)
end
function RESETPASSWORDREQUESTACCEPTED.respond(words, sentences)
end
function RESETPASSWORDREQUESTDENIED.respond(words, sentences)
end
function RING.respond(words, sentences)
  sound["ring"]:play()
end
local function mentioned(text, channel)
  channel.newMessage = true
  if string.find(text, lobby.username) then
    if not channel:isActive() then
      sound["ding"]:play()
    end
    if not lw.isOpen() then
      lw.requestAttention( )
      sound["ding"]:play()
    end
    return true
  end
  return false
end
function SAID.respond(words, sentences, data)
  local chan = words[1]
  local user = words[2]
  local text = string.gsub(sentences[1], "%S+", "", 3) .. "\n"
  
  local mention = mentioned(text, Channel.s[chan])
  for link in text:gmatch("http[s]*://%S+") do
    local links = links or {}
    local i, j = string.find(text, link)
    table.insert(links, {link = link, i = i, j = j})
  end
  
  table.insert(Channel.s[chan].lines, {time = os.date("%X"), links = links, mention = mention, user = user, msg = text})
  lobby.render()
  love.filesystem.write( "chatlogs/" .. chan .. ".txt", user .. ": " .. text )
end
function SAIDBATTLE.respond(words, sentences)
  local user = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  local battle = Battle:getActiveBattle()
  local founder = battle.founder
  local chan = battle:getChannel()
  local mention = mentioned(text, chan)
  local ingame = false
  if user == founder then
    ingame = true
    user = "INGAME"
  end
  table.insert(chan.lines, {time = os.date("%X"), ingame = ingame, mention = mention, user = user, msg = text})
  lobby.render()
end
function SAIDBATTLEEX.respond(words, sentences)
  local user = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  local battle = Battle:getActiveBattle()
  local founder = battle.founder
  local mention = mentioned(text, battle:getChannel())
  if user == founder then
    table.insert(battle:getChannel().infolines, {time = os.date("%X"), ex = true, user = user, msg = text})
  else
    table.insert(battle:getChannel().lines, {time = os.date("%X"), mention = mention, ex = true, user = user, msg = text})
  end
  lobby.render()
end
function SAIDEX.respond(words, sentences)
  local chan = words[1]
  local user = words[2]
  local text = string.gsub(sentences[1], "%S+", "", 3) .. "\n"
  
  local mention = mentioned(text, Channel.s[chan])
  for link in text:gmatch("http[s]*://%S+") do
    local links = links or {}
    local i, j = string.find(text, link)
    table.insert(links, {link = link, i = i, j = j})
  end
  
  table.insert(Channel.s[chan].lines, {time = os.date("%X"), links = links, mention = mention, ex = true, user = user, msg = text})
  lobby.render()
  love.filesystem.write( "chatlogs/" .. chan .. ".txt", user .. ": " .. text )
end
function SAIDFROM.respond(words, sentences)
end
function SAIDPRIVATE.respond(words, sentences)
  local user = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  if not Channel.s[user] then
    User.s[user]:openChannel()
  end
  mentioned(lobby.username, Channel.s[user])
  table.insert(Channel.s[user].lines, {time = os.date("%X"), user = user, msg = text})
  lobby.render()
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SAIDPRIVATEEX.respond(words, sentences)
  local user = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  if not Channel.s[user] then
    User.s[user]:openChannel()
  end
  mentioned(lobby.username, Channel.s[user])
  table.insert(Channel.s[user].lines, {time = os.date("%X"), ex = true, user = user, msg = text})
  lobby.render()
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SAYPRIVATE.respond(words, sentences)
  local user = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  table.insert(Channel.s[user].lines, {time = os.date("%X"), user = lobby.username, msg = text})
  lobby.render()
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SAYPRIVATEEX.respond(words, sentences)
  local user = words[1]
  local text = string.gsub(sentences[1], "%S+", "", 2) .. "\n"
  table.insert(Channel.s[user].lines, {time = os.date("%X"), ex = true, user = lobby.username, msg = text})
  lobby.render()
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SERVERMSG.respond(words, sentences)
end
function SERVERMSGBOX.respond(words, sentences)
end
function SETSCRIPTTAGS.respond(words, sentences)
  local battle = Battle:getActive()
  for i = 2, #sentences do
    local tbl = battle
    for w in sentences[i]:gmatch("([^/]+)") do
      local k, v = w:match("(.+)=(.+)")
      if k and v then
        tbl[k] = v
      else
        tbl[w] = tbl[w] or {}
        tbl = tbl[w]
      end
    end
  end
  lobby.render()
end
function TASSERVER.respond(words, sentences)
  if not login.TLS then
    lobby.send("STLS" .. "\n")
    login.TLS = true
  end
end
function UDPSOURCEPORT.respond(words, sentences)
end
function UNBRIDGEDCLIENTFROM.respond(words, sentences)
end
function UNIGNORE.respond(words, sentences)
end
function UPDATEBATTLEINFO.respond(words, sentences)
  local id = words[1]
  if not Battle.s[id] then return end
  local spectatorCount = words[2] or 0
  local locked = words[3]
  local mapHash = words[4]
  local mapName = string.gsub(string.gsub(sentences[1], "%a+ ", "", 1), "-*%d+ ", "", 4)
  Battle.s[id].locked = locked
  Battle.s[id].mapHash = mapHash
  Battle.s[id].spectatorCount = spectatorCount
  Battle.s[id].mapName = mapName
  if Battle:getActive() and Battle:getActive() == Battle.s[id] and Battle.s[id]:mapHandler() and Battle.s[id]:modHandler() then
    lobby.setSynced(true)
  end
  Battle.s[id]:getMinimap()
  lobby.refreshBattleTabs()
end
function UPDATEBOT.respond(words, sentences)
end

return responses