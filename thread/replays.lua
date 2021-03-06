local channel = love.thread.getChannel("replays")
local nfs = require "lib/nativefs"
local ld = love.data
local spring = require "spring"
local replays_directory = ...

local function iter(a, i)
  i = i - 1
  local v = a[i]
  if v then
    return i, v
  end
end
    
local function reverseipairs(a)
  return iter, a, #a+1
end

for i, file in reverseipairs(nfs.getDirectoryItems(replays_directory)) do
  local filepath = replays_directory .. file
  local dateAndTime, mapName, enginev, ext = file:match("(%d+_%d+)_(.+)_(%d+)%.(.+)")
  if dateAndTime and mapName and enginev and ext and ext == "sdfz" then
    local dateAndTimeString = dateAndTime:gsub("(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)(%d%d)", "%1-%2-%3 %4:%5:%6")
    local info = nfs.getInfo(filepath)
    local gzip, size = nfs.read(filepath)
    if size > 0 then
      local decomp = ld.decompress( "string", "gzip", gzip )
      
      local magic,
      version,
      headerSize,
      versionString,
      gameID,
      unixTime,
      scriptSize,
      demoStreamSize,
      gameTime,
      wallclockTime,
      numPlayers,
      playerStatSize,
      playerStatElemSize,
      numTeams,
      teamStatSize,
      teamStatElemSize,
      teamStatPeriod,
      winningAllyTeamsSize,
      _ =
      love.data.unpack("c16 i i c256 c16 c8 i i i i i i i i i i i", decomp)
      local scriptStr = love.data.unpack("c" .. scriptSize, decomp, headerSize)
      --local stats = love.data.unpack("c" .. playerStatSize, decomp, headerSize + scriptSize + demoStreamSize)
      --local demo = love.data.unpack("c" .. demoStreamSize, decomp, headerSize + scriptSize)
      local script = {["game"] = {}}
      --local open = false
      local tbl
      for line in string.gmatch(scriptStr,'[^\r\n]+') do
        local key = line:match("^%[(.+)%]$")
        if key then
          script[key] = {}
          tbl = script[key]
        end
        if line:find('}') then
          tbl = script["game"]
        end
        local k, v = line:match("(.+)=(.+);")
        if tbl and k and v then
          tbl[k] = v
        end
      end
      
      --[[local mapName = self.script["game"].mapname
      if mapName then
        mapName = string.gsub(mapName:lower(), " ", "_")
        local minimap = self:getMinimap(mapName)
        self.minimap = minimap
        self.mapWidthHeightRatio = widths[mapName]/heights[mapName]
      end]]
      
      local header = {
        {name = "magic", val = magic},
        {name = "version", val = version},
        {name = "headerSize", val = headerSize},
        {name = "versionString", val = versionString},
        --{name = "gameID", val = gameID},
        --{name = "unixTime", val = unixTime},
        {name = "scriptSize", val = scriptSize},
        {name = "demoStreamSize", val = demoStreamSize},
        {name = "gameTime", val = gameTime},
        {name = "wallclockTime", val = wallclockTime},
        {name = "numPlayers", val = numPlayers},
        {name = "playerStatSize", val = playerStatSize},
        {name = "playerStatElemSize", val = playerStatElemSize},
        {name = "numTeams", val = numTeams},
        {name = "teamStatSize", val = teamStatSize},
        {name = "teamStatElemSize", val = teamStatElemSize},
        {name = "teamStatPeriod", val = teamStatPeriod},
        {name = "winningAllyTeamsSize", val = winningAllyTeamsSize}
      }
      
      local gameType = "Duel"
      do
        local numallyteams = numTeams
        local mo_ffa = tonumber(script["modoptions"].mo_ffa)
        if numallyteams and numallyteams > 2 then
          if mo_ffa and mo_ffa == 1 then
            gameType = "FFA"
          else
            gameType = "Teams"
          end
        end
      end
  
      local gameTimeString = "N/A"
      do
        local gametime = header[7].val
        local hour = math.floor(gametime / 3600)
        local minute = math.floor(gametime / 60) - hour * 60
        local second = gametime - hour * 3600 - minute * 60
        if hour < 10 then hour = "0" .. hour end
        if minute < 10 then minute = "0" .. minute end
        if second < 10 then second = "0" .. second end
        if tonumber(second) > 0 then
          gameTimeString = hour ..":" .. minute .. ":" .. second
        end
      end
      channel:supply({header, script, dateAndTimeString, mapName, filepath, gameTimeString, gameType})
    end
  end
end
