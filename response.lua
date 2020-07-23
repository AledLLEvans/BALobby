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

function ACCEPTED.respond(words, sentances)
  lobby.enter()
  lobby.username = login.nameBox.text
  login.nameBox.active = false
  login.passBox.active = false
  lobby.connected = true 
end
function ADDBOT.respond(words, sentances)
end
function ADDSTARTRECT.respond(words, sentances)
end
function ADDUSER.respond(words, sentances)
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
function AGREEMENT.respond(words, sentances)
  table.insert(login.log, {from = true, msg = sentances[1] })
end
function AGREEMENTEND.respond(words, sentances)
  lobby.send("CONFIRMAGREEMENT" .. "\n")
  lobby.send(lobby.loginString)
  table.insert(login.log, {from = true, msg = reason })
end
function BATTLECLOSED.respond(words, sentances)
  local id = words[1]
  Battle.s[id] = nil
  lobby.refreshBattleList()
end
function BATTLEOPENED.respond(words, sentances)
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
  
  battle.engineName = sentances[2]
  battle.engineVersion = sentances[2]
  
  battle.mapName = words[11]
  for i = 12, #words do
    battle.mapName = battle.mapName .. " " .. words[i]
  end
  battle.title = string.gsub(string.gsub(sentances[2], "%a+ ", "", 1), "%b() ", "", 1)
  battle.gameName = sentances[#sentances] or "gameName"
  
  --battle.channel = words[16]
  battle.spectatorCount = 0
  battle.locked = false
  battle.users = {}
  battle.userCount = 0
  
  battle.noOfTeams = 0
  battle.userListScrollOffset = 0
  
  Battle:new(battle)
  lobby.refreshBattleList()
end
function BRIDGEDCLIENTFROM.respond(words, sentances)
end
function CHANGEEMAILACCEPTED.respond(words, sentances)
end
function CHANGEEMAILDENIED.respond(words, sentances)
end
function CHANGEEMAILREQUESTACCEPTED.respond(words, sentances)
end
function CHANGEEMAILREQUESTDENIED.respond(words, sentances)
end
function CHANNEL.respond(words, sentances)
end
function CHANNELMESSAGE.respond(words, sentances)
end
function CHANNELTOPIC.respond(words, sentances)
end
function CLIENTBATTLESTATUS.respond(words, sentances)
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
  local battle = Battle:getActiveBattle()
  for i=1,16 do
    for username, user in pairs(battle.users) do
      if not user.isSpectator and i == user.allyTeamNo then
        table.insert(teams, user)
      end
    end
  end
  battle.playersByTeam = teams
  lobby.refreshPlayerButtons()
end
function CLIENTIPPORT.respond(words, sentances)
end
function CLIENTS.respond(words, sentances)
  local chan = words[1]
  for i = 2, #words do
    Channel.s[chan].users[words[i]] = User.s[words[i]]
  end
end
function CLIENTSFROM.respond(words, sentances)
end
function CLIENTSTATUS.respond(words, sentances)
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
function COMPFLAGS.respond(words, sentances)
end
function DENIED.respond(words, sentances)
end
function DISABLEUNITS.respond(words, sentances)
end
function ENABLEALLUNITS.respond(words, sentances)
end
function ENABLEUNITS.respond(words, sentances)
end
function ENDOFCHANNELS.respond(words, sentances)
end
function FAILED.respond(words, sentances)
end
function FORCEQUITBATTLE.respond(words, sentances)
  Battle:getActiveBattle():getChannel():addMessage("You were kicked from the battle!")
  lw.showMessageBox("For your information", "You were kicked from the battle!", "info" )
end
function HOSTPORT.respond(words, sentances)
  local port = words[1]
  Battle:getActiveBattle().hostport = port
end
function IGNORE.respond(words, sentances)
end
function IGNORELIST.respond(words, sentances)
end
function IGNORELISTBEGIN.respond(words, sentances)
end
function IGNORELISTEND.respond(words, sentances)
end
function JOIN.respond(words, sentances)
  Channel:new({title = words[1]})
  Channel:refreshTabs()
end
function JOINBATTLE.respond(words, sentances)
  local id = words[1]
  local hashCode = words[2]
  local channel = words[3]
  Battle.active = Battle.s[id]
  local battle = Battle.active
  if not battle.channel then
    battle.channel = BattleChannel:new({title = "Battle_" .. id})
  else
    battle.channel.display = true
  end
  if battle:mapHandler() and battle:modHandler() then
    lobby.setSynced(true)
  end
  battle.buttons = {
  spectate = BattleButton:new(lobby.fixturePoint[2].x - 100, lobby.fixturePoint[2].y - 50, 90, 40,
    "Spectate",
    function() lobby.setSpectator(not User.s[lobby.username].spectator) end),
  ready = BattleButton:new(lobby.fixturePoint[2].x - 200, lobby.fixturePoint[2].y - 50, 90, 40,
    "Ready",
    function() if not User.s[lobby.username].spectator then lobby.setReady(not User.s[lobby.username].ready) end end),
    }
  Channel:refreshTabs()
  Channel.active = Channel.s["Battle_" .. id]
  battle.display = true
  lobby.refreshBattleList()
end
function JOINBATTLEFAILED.respond(words, sentances)
  Channel:broadcast(" REQUEST TO JOIN BATTLE FAILED, REASON: " .. string.gsub(sentances[1], "%S+ ", "", 1))
  lw.showMessageBox("REQUEST TO JOIN BATTLE FAILED", "REASON: " .. string.gsub(sentances[1], "%S+ ", "", 1), "info" )
end
function JOINBATTLEREQUEST.respond(words, sentances)
end
function JOINED.respond(words, sentances)
  local chan = words[1]
  local user = words[2]
  Channel.s[chan].users[user] = User.s[user]
end
function JOINEDBATTLE.respond(words, sentances)
  local battleid = words[1]
  local user = words[2]
  local scriptPassword = words[3]
  User.s[user].battleid = battleid
  Battle.s[battleid].users[user] = User.s[user]
  Battle.s[battleid].userCount = Battle.s[battleid].userCount + 1
  Battle.s[battleid].scriptPassword = scriptPassword
  lobby.refreshBattleList()
end
function JOINEDFROM.respond(words, sentances)
end
function JOINFAILED.respond(words, sentances)
  table.insert(Channel.s[words[1]].lines, {msg = "Failure to join channel, reason: " .. words[2]})
end
function JSON.respond(words, sentances)
end
function KICKFROMBATTLE.respond(words, sentances)
end
function LEFT.respond(words, sentances)
  local chan = words[1]
  local user = words[2]
  Channel.s[chan].users[user] = nil
  if user == lobby.username then
    Channel.s[chan].display = false
    Channel:refreshTabs()
  end
end
function LEFTBATTLE.respond(words, sentances)
  local battleid = words[1]
  local user = words[2]
  Battle.s[battleid].users[user] = nil
  Battle.s[battleid].userCount = Battle.s[battleid].userCount - 1
  User.s[user].battleid = nil
  lobby.refreshBattleList()
end
function LEFTFROM.respond(words, sentances)
end
function LOGININFOEND.respond(words, sentances)
  lobby.send("JOIN main" .. "\n")
  lobby.send("JOIN en" .. "\n")
  lobby.send("JOIN newbies" .. "\n")
  lobby.refreshBattleList()
  lobby.loginInfoEnd = true
end
function MOTD.respond(words, sentances)
  table.insert(lobby.serverChannel.lines, {from = true, msg = string.gsub(sentances[1], "%u+ ", "", 1) .. "\n"})
end
function OK.respond(words, sentances)
end
function OPENBATTLE.respond(words, sentances)
end
function OPENBATTLEFAILED.respond(words, sentances)
end
function PONG.respond(words, sentances)
  lobby.timeSinceLastPong = 0
end
function REDIRECT.respond(words, sentances)
end
function REGISTRATIONACCEPTED.respond(words, sentances)
  local reason = sentances[1]
  table.insert(login.log, {from = true, msg = reason })
end
function REGISTRATIONDENIED.respond(words, sentances)
  local reason = sentances[1]
  table.insert(login.log, {from = true, msg = reason })
end
function REMOVEBOT.respond(words, sentances)
end
function REMOVESCRIPTTAGS.respond(words, sentances)
end
function REMOVESTARTRECT.respond(words, sentances)
end
function REMOVEUSER.respond(words, sentances)
  local user = words[1]
  User.s[user] = nil
  for name, chan in pairs(Channel.s) do
    chan.users[user] = nil
  end
end
function REQUESTBATTLESTATUS.respond(words, sentances)
  lobby.sendMyBattleStatus()
end
function RESENDVERIFICATIONACCEPTED.respond(words, sentances)
end
function RESENDVERIFICATIONDENIED.respond(words, sentances)
end
function RESETPASSWORDACCEPTED.respond(words, sentances)
end
function RESETPASSWORDDENIED.respond(words, sentances)
end
function RESETPASSWORDREQUESTACCEPTED.respond(words, sentances)
end
function RESETPASSWORDREQUESTDENIED.respond(words, sentances)
end
function RING.respond(words, sentances)
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
function SAID.respond(words, sentances, data)
  local chan = words[1]
  local user = words[2]
  local text = string.gsub(sentances[1], "%S+", "", 3) .. "\n"
  local mention = mentioned(text, Channel.s[chan])
  table.insert(Channel.s[chan].lines, {time = os.date("%X"), mention = mention, user = user, msg = text})
  love.filesystem.write( "chatlogs/" .. chan .. ".txt", user .. ": " .. text )
end
function SAIDBATTLE.respond(words, sentances)
  local user = words[1]
  local text = string.gsub(sentances[1], "%S+", "", 2) .. "\n"
  local battle = Battle:getActiveBattle()
  local founder = battle.founder
  local chan = battle:getChannel()
  local mention = mentioned(text, chan)
  if user == founder then
    user = "ingame"
  end
  table.insert(chan.lines, {time = os.date("%X"), mention = mention, user = user, msg = text})
end
function SAIDBATTLEEX.respond(words, sentances)
  local user = words[1]
  local text = string.gsub(sentances[1], "%S+", "", 2) .. "\n"
  local battle = Battle:getActiveBattle()
  local founder = battle.founder
  local mention = mentioned(text, battle:getChannel())
  if user == founder then
    table.insert(battle:getChannel().infolines, {time = os.date("%X"), ex = true, user = user, msg = text})
  else
    table.insert(battle:getChannel().lines, {time = os.date("%X"), mention = mention, ex = true, user = user, msg = text})
  end
end
function SAIDEX.respond(words, sentances)
  local chan = words[1]
  local user = words[2]
  local text = string.gsub(sentances[1], "%S+", "", 3) .. "\n"
  local mention = mentioned(text, Channel.s[chan])
  table.insert(Channel.s[chan].lines, {time = os.date("%X"), mention = mention, ex = true, user = user, msg = text})
  love.filesystem.write( "chatlogs/" .. chan .. ".txt", user .. ": " .. text )
end
function SAIDFROM.respond(words, sentances)
end
function SAIDPRIVATE.respond(words, sentances)
  local user = words[1]
  local text = string.gsub(sentances[1], "%S+", "", 2) .. "\n"
  if not Channel.s[user] then
    Channel.s[user] = Channel:new({title = user, user = true, display = true})
    Channel:refreshTabs()
  end
  mentioned(lobby.username, Channel.s[user])
  table.insert(Channel.s[user].lines, {time = os.date("%X"), user = user, msg = text})
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SAIDPRIVATEEX.respond(words, sentances)
  local user = words[1]
  local text = string.gsub(sentances[1], "%S+", "", 2) .. "\n"
  if not Channel.s[user] then
    Channel.s[user] = Channel:new({title = user, user = true})
  end
  mentioned(lobby.username, Channel.s[user])
  table.insert(Channel.s[user].lines, {time = os.date("%X"), ex = true, user = user, msg = text})
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SAYPRIVATE.respond(words, sentances)
  local user = words[1]
  local text = string.gsub(sentances[1], "%S+", "", 2) .. "\n"
  table.insert(Channel.s[user].lines, {time = os.date("%X"), user = lobby.username, msg = text})
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SAYPRIVATEEX.respond(words, sentances)
  local user = words[1]
  local text = string.gsub(sentances[1], "%S+", "", 2) .. "\n"
  table.insert(Channel.s[user].lines, {time = os.date("%X"), ex = true, user = lobby.username, msg = text})
  love.filesystem.write( "chatlogs/" .. user .. ".txt", user .. ": " .. text )
end
function SERVERMSG.respond(words, sentances)
end
function SERVERMSGBOX.respond(words, sentances)
end
function SETSCRIPTTAGS.respond(words, sentances)
end
function TASSERVER.respond(words, sentances)
  if not login.TLS then
    lobby.send("STLS" .. "\n")
    login.TLS = true
  end
end
function UDPSOURCEPORT.respond(words, sentances)
end
function UNBRIDGEDCLIENTFROM.respond(words, sentances)
end
function UNIGNORE.respond(words, sentances)
end
function UPDATEBATTLEINFO.respond(words, sentances)
  local id = words[1]
  if not Battle.s[id] then return end
  local spectatorCount = words[2] or 0
  local locked = words[3]
  local mapHash = words[4]
  local mapName = string.gsub(string.gsub(sentances[1], "%a+ ", "", 1), "-*%d+ ", "", 4)
  Battle.s[id].locked = locked
  Battle.s[id].mapHash = mapHash
  Battle.s[id].spectatorCount = spectatorCount
  Battle.s[id].mapName = mapName
  --Battle.s[id]:mapHandler()
  Battle.s[id]:getMinimap()
  lobby.refreshBattleList()
end
function UPDATEBOT.respond(words, sentances)
end

return responses