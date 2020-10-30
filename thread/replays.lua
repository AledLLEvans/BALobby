local channel = love.thread.getChannel("replays")
local nfs = require "lib/nativefs"
local ld = love.data
local spring = require "spring"
local replays_directory = ...
local li = require "love.image"

local function parse(path)
  local info = nfs.getInfo(path)
  local gzip, size = nfs.read(path)
  if size == 0 then self.empty = true return end
  local decomp = ld.decompress( "string", "gzip", gzip )
    
  --[[if not info then return end
  if not ((info.type == "file") and (info.size > 0)) then return end
  local fd = nfs.newFileData(path)]]
  
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
  
  self.script = script
  
  local mapName = self.script["game"].mapname
  if mapName then
    mapName = string.gsub(mapName:lower(), " ", "_")
    local minimap = self:getMinimap(mapName)
    self.minimap = minimap
    self.mapWidthHeightRatio = widths[mapName]/heights[mapName]
  end
  
  self.header = {
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
--[[    ["magic"] = magic,
    ["version"] = version,
    ["headerSize"] = headerSize,
    ["versionString"] = versionString,
    ["gameID"] = gameID,
    ["unixTime"] = unixTime,
    ["scriptSize"] = scriptSize,
    ["demoStreamSize"] = demoStreamSize,
    ["gameTime"] = gameTime,
    ["wallclockTime"] = wallclockTime,
    ["numPlayers"] = numPlayers,
    ["playerStatSize"] = playerStatSize,
    ["playerStatElemSize"] = playerStatElemSize,
    ["numTeams"] = numTeams,
    ["teamStatSize"] = teamStatSize,
    ["teamStatElemSize"] = teamStatElemSize,
    ["teamStatPeriod"] = teamStatPeriod,
    ["winningAllyTeamsSize"] = winningAllyTeamsSize
  }]]

  --[[print("magic", magic)
  print("version", version)
  print("headerSize", headerSize)
  print("versionString", versionString)
  print("gameID", gameID)
  print("unixTime", unixTime)  
  print("scriptSize", scriptSize)
  print("demoStreamSize", demoStreamSize)
  print("gameTime", gameTime)
  print("wallclockTime", wallclockTime)
  print("numPlayers", numPlayers)
  print("playerStatSize", playerStatSize)
  print("playerStatElemSize", playerStatElemSize)
  print("numTeams", numTeams)
  print("teamStatSize", teamStatSize)
  print("teamStatElemSize", teamStatElemSize)
  print("teamStatPeriod", teamStatPeriod)
  print("winningAllyTeamsSize", winningAllyTeamsSize)]]

end

for i, file in pairs(nfs.getDirectoryItems(replays_directory)) do
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
      
      channel:push({header, script, dateAndTimeString, mapName, filepath})
    end
  end
end
