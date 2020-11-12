local spring = {}
local ld = love.data
local li = require "love.image"
local nfs = require "lib/nativefs"
local lfs = love.filesystem
local lg = love.graphics

local header = {}
header[1] = 'DDS ' -- magic... technically not part of the header
header[2] = ld.pack('string', 'I4', 124) -- headersize
header[3] = ld.pack('string', 'I4', 8+4096+4194304) --1+2+4+0x1000+0x20000) -- flags
header[4] = ld.pack('string', 'I4', 1024) -- height
header[5] = ld.pack('string', 'I4', 1024) -- width
header[6] = ld.pack('string', 'I4', 8*0x10000) -- pitch
header[7] = ld.pack('string', 'I4', 0) -- depth
header[8] = ld.pack('string', 'I4', 8) -- mipmapcount
for i=1,11 do
  header[8+i] = ld.pack('string', 'I4', 0) -- reserved
end
-- pixelformat here
header[20] = ld.pack('string', 'I4', 32) -- structure size
header[21] = ld.pack('string', 'I4', 4) -- flags
header[22] = ld.pack('string', 'c4', 'DXT1') -- format... technically DWORD but easier to convert from string
header[23] = ld.pack('string', 'I4', 0) -- bits in uncompressed, unused
header[24] = ld.pack('string', 'I4', 0) -- 4 masks, unused
header[25] = ld.pack('string', 'I4', 0) --
header[26] = ld.pack('string', 'I4', 0) --
header[27] = ld.pack('string', 'I4', 0) --
-- pixelformat structure end
header[28] = ld.pack('string', 'I4', 0x401008) -- surface is texture
header[29] = ld.pack('string', 'I4', 0) -- 4 unused from here
header[30] = ld.pack('string', 'I4', 0) --
header[31] = ld.pack('string', 'I4', 0) --
header[32] = ld.pack('string', 'I4', 0) --
local headerStr = table.concat(header)
spring.headerStr = headerStr

local launchCode = [[
  local exec = ...
  io.popen(exec)
]]


function spring.launch(path)
  if not spring.thread then spring.thread = love.thread.newThread( launchCode ) end
  spring.thread:start(path)
end

function spring.getSMF(dir)
  for _, filename in pairs(lfs.getDirectoryItems( dir )) do
    local path = dir .. "/" .. filename
    if lfs.getInfo(path).type == "directory" then
      local smf = spring.getSMF(path)
      if smf then return smf end
    elseif string.find(filename, ".smf") then
      return path
    end
  end
  return false
end

function spring.hasMap(mapName, map_folder)
  map_folder = map_folder or lobby.mapFolder
  for i, k in pairs(nfs.getDirectoryItems(map_folder)) do
    if k == mapName .. ".sdz" or k == mapName .. ".sd7" then return k end
  end
  return false
end

function spring.hasMod(gameName)
  for i, k in pairs(nfs.getDirectoryItems(lobby.gameFolder)) do
    if k == gameName .. ".sdz" or k == gameName .. ".sd7" then return k end
  end
  return false
end

local function getMapData(mapName, map_folder)
  map_folder = map_folder or lobby.mapFolder
  mapName = mapName:lower():gsub(" ", "_")
  local mapArchive = spring.hasMap(mapName, map_folder)
  if not mapArchive or not nfs.mount(map_folder .. mapArchive, "map") then return false end
  local mapData = lfs.read(spring.getSMF("map"))
  if not mapData then return false end
  nfs.unmount(map_folder .. mapArchive, "map")
  return mapData
end

local map_width = {}
local map_height = {}
local map_names = {}
local function mapInfo_parse()
  for _, file in pairs(lfs.getDirectoryItems("maps/info")) do
    for line in lfs.lines("maps/info/" .. file) do
      local name, width, height = line:match("(.+):(%d+):(%d+)")
      map_width[name] = width
      map_height[name] = height
      map_names[name:lower():gsub(" ", "_")] = name
    end
  end
end

function spring.getMapNameFromArchiveName( archiveName, map_folder )
  if map_names[archiveName] then return map_names[archiveName] end
  map_folder = map_folder or lobby.mapFolder
  local mapArchive = spring.hasMap(archiveName, map_folder)
  if not mapArchive or not nfs.mount(map_folder .. mapArchive, "map") then return false end
  local mapName = spring.getSMF("map"):match(".*/(.+)%.smf")
  nfs.unmount(map_folder .. mapArchive, "map")
  return mapName or false
end

function spring.parseMinimapInfo( mapName )
  local path = "maps/info/" .. mapName .. ".txt"
  if lfs.getInfo(path) then
    local name, width, height = lfs.read(path):match("(.+):(%d+):(%d+)")
    map_width[name] = width
    map_height[name] = height
    map_names[name:lower():gsub(" ", "_")] = name
  end
end

function spring.cacheMinimap( mapName, map_folder )
  if not lfs.getInfo( "maps/mini/" .. mapName ) or
  not lfs.getInfo( "maps/info/" .. mapName ..".txt" ) then
    if not spring.cacheMapImages(mapName, map_folder) then
      --print(mapName, " minimap images could not be cached, please check the map archive.")
      return false
    end
  end
  return true
end

function spring.getMinimapOnly(mapName, map_folder)
  if not lfs.getInfo( "maps/mini/" .. mapName ) or
  not lfs.getInfo( "maps/info/" .. mapName ..".txt" ) then
    return false
  end
  return lg.newImage( "maps/mini/" .. mapName ),
  map_width[mapName],
  map_height[mapName]
end

function spring.getMinimaps(mapName)
  local archiveName = mapName:lower():gsub(" ", "_")
  if not spring.hasMap(archiveName) then return false end
  if not lfs.getInfo( "maps/mini/" .. mapName ) or
    not lfs.getInfo( "maps/metal/" .. mapName .. ".png" ) or 
    not lfs.getInfo( "maps/height/" .. mapName .. ".png" ) or
    not lfs.getInfo( "maps/info/" .. mapName .. ".txt" ) then
    if not spring.cacheMapImages(mapName, lobby.mapFolder) then
      print(mapName, " minimap images could not be cached, please check the map archive.")
      return false
    end
  end
  return lg.newImage( "maps/mini/" .. mapName ),
  lg.newImage( "maps/metal/" .. mapName .. ".png" ),
  lg.newImage( "maps/height/" .. mapName .. ".png" ),
  map_width[mapName],
  map_height[mapName]
end

function spring.cacheMapImages(mapName, map_folder)
  local mapData = getMapData(mapName, map_folder)
  if not mapData then return false end
  
  local  _, _, _, mapWidth, mapHeight, _, _, _, _, _, heightmapOffset, _, _, minimapOffset, metalmapOffset, _ = 
  ld.unpack("c16 i4 I4 i4 i4 i4 i4 i4 f f i4 i4 i4 i4 i4 i4", mapData)
  
   do --Mini Map
    local path = "maps/mini/" .. mapName
    local minimapData = ld.unpack("c699048", mapData, minimapOffset + 1)
    minimapData = headerStr .. minimapData
    local bytedata = ld.newByteData( minimapData )
    local compdata = li.newCompressedData( bytedata )
    lfs.write(path, bytedata:getString())
  end
  
  do --Metal Map
    local path = "maps/metal/" .. mapName .. ".png"
    local bytes = (mapWidth/2) * (mapHeight/2)
    local metalmapData = ld.unpack("c"..tostring(bytes), mapData, metalmapOffset + 1)
    local imageData = li.newImageData( (mapWidth)/2, (mapHeight)/2, "r8", metalmapData )
    local imageDatargba8 = li.newImageData( (mapWidth)/2, (mapHeight)/2 )
    imageDatargba8:paste( imageData, 0, 0, 0, 0, (mapWidth)/2, (mapHeight)/2  )
    imageDatargba8:encode( "png", path )
  end
  
  do --HeightMap
    local path = "maps/height/" .. mapName .. ".png"
    local bytes = (mapWidth + 1) * (mapHeight + 1) * 2
    local heightmapDataString = mapData:sub(heightmapOffset+1)
    local imageData = li.newImageData(mapWidth + 1, mapHeight + 1, "r8")
    for i = 1, bytes, 2 do
      local a, b = heightmapDataString:byte(i, i + 1)
      local index = (i - 1) / 2
      local x = index % (mapWidth + 1)
      local y = math.floor(index / (mapWidth + 1))
      local s = (b * 256 + a) / 65535
      imageData:setPixel(x, y, s, s, s)
    end
    local imageDatargba8 = li.newImageData( mapWidth + 1, mapHeight + 1 )
    imageDatargba8:paste( imageData, 0, 0, 0, 0, mapWidth + 1, mapHeight + 1 )
    imageDatargba8:encode( "png", path )
  end
  
  map_width[mapName] = mapWidth
  map_height[mapName] = mapHeight
  map_names[mapName:lower():gsub(" ", "_")] = mapName
  if not lfs.write("maps/info/" .. mapName .. ".txt", string.format("%s:%s:%s\n", mapName, mapWidth, mapHeight)) then error("Could not write to %appdata%/maps/info.txt") end
  
  return true
end

local sha1 = require("sha1")
function spring.getArchiveChecksum(fpath)
  print(fpath)
  local archive = nfs.read(fpath)
  if archive then return sha1(archive) end
  return false
end

function spring.initialize()
  mapInfo_parse()
end

return spring