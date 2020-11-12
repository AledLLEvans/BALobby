local channel = love.thread.getChannel("minimap")
local nfs = require "lib/nativefs"
local ld = love.data
local spring = require "spring"
local map_directory = ...
local li = require "love.image"
local lfs = love.filesystem

for _, file in pairs(nfs.getDirectoryItems(map_directory)) do
  local archiveName, ext = file:match("(.+)%.(.+)")
  local mapName = spring.getMapNameFromArchiveName(archiveName, map_directory )
  if mapName then
     if spring.cacheMinimap(mapName, map_directory) then
      channel:push(mapName)
    end
  end
  local peek = channel:peek()
  if peek and peek == "quit" then channel:push("quitend") return end
  --[[local path = "maps/mini/" .. mapName
  if lfs.getInfo( path ) then
    channel:push({true, path, mapName})
  elseif nfs.mount(map_directory .. file, "map") then
    local mapData = lfs.read(spring.getSMF("map"))
    if mapData then
      local  _, _, _, mapWidth, mapHeight, _, _, _, _, _, _, _, _, minimapOffset, _, _ = 
      ld.unpack("c16 i4 I4 i4 i4 i4 i4 i4 f f i4 i4 i4 i4 i4 i4", mapData)
      local minimapData = ld.unpack("c699048", mapData, minimapOffset + 1)
      minimapData = spring.headerStr .. minimapData
      local bytedata = ld.newByteData( minimapData )
      local compdata = li.newCompressedData(bytedata)
      lfs.write(path, bytedata:getString())
      channel:push({false, compdata, mapName, mapWidth, mapHeight})
    end
    nfs.unmount(map_directory .. file, "map")
  end]]
end
