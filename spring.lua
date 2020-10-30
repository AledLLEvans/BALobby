local spring = {}
local ld = love.data
local li = love.image
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

function spring.hasMap(mapName)
  for i, k in pairs(nfs.getDirectoryItems(lobby.mapFolder)) do
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

local function getMapData(mapName)
  mapName = string.gsub(mapName:lower(), " ", "_")
  local mapArchive = spring.hasMap(mapName)
  if not mapArchive or not nfs.mount(lobby.mapFolder .. mapArchive, "map") then return false end
  local mapData = lfs.read(spring.getSMF("map"))
  if not mapData then return false end
  nfs.unmount(lobby.mapFolder .. mapArchive, "map")
  return mapData
end

function spring.getMinimap(mapName)
  local mapData = getMapData(mapName)
  if not mapData then return false end
  
  local  _, _, _, mapWidth, mapHeight, _, _, _, _, _, _, _, _, minimapOffset, _, _ = 
  ld.unpack("c16 i4 I4 i4 i4 i4 i4 i4 f f i4 i4 i4 i4 i4 i4", mapData)
  
  local minimapData = ld.unpack("c699048", mapData, minimapOffset + 1)
  minimapData = headerStr .. minimapData
  local bytedata = ld.newByteData( minimapData )
  local compdata = li.newCompressedData(bytedata)
  return lg.newImage(compdata), mapWidth, mapHeight
end

function spring.getMapData(mapName)
  local data = {}
  
  local mapData = getMapData(mapName)
  if not mapData then return false end
  
  local  _, _, _, mapWidth, mapHeight, _, _, _, _, _, heightmapOffset, _, _, minimapOffset, metalmapOffset, _ = 
  ld.unpack("c16 i4 I4 i4 i4 i4 i4 i4 f f i4 i4 i4 i4 i4 i4", mapData)

  data.mapwidth = mapWidth
  data.mapheight = mapHeight
  data.widthHeightRatio = mapWidth/mapHeight
  
  do --Mini Map
    local minimapData = ld.unpack("c699048", mapData, minimapOffset + 1)
    minimapData = headerStr .. minimapData
    local bytedata = ld.newByteData( minimapData )
    local compdata = li.newCompressedData(bytedata)
    data.minimap = lg.newImage(compdata)
  end
  
  do --Metal Map
    local bytes = (mapWidth/2) * (mapHeight/2)
    local metalmapData = ld.unpack("c"..tostring(bytes), mapData, metalmapOffset + 1)
    local imageData = li.newImageData( (mapWidth)/2, (mapHeight)/2, "r8", metalmapData )
    data.metalmap = lg.newImage(imageData)
  end
  
  do --HeightMap
    local bytes = (mapWidth + 1) * (mapHeight + 1) * 2
    --local byteData = ld.newByteData(mapData, heightmapOffset + 1, bytes)
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
    data.heightmap = lg.newImage(imageData)
  end
  
  return data
end



return spring