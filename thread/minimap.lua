local channel = love.thread.getChannel("minimap")
local nfs = require "lib/nativefs"
local ld = love.data
local spring = require "spring"
local map_directory = ...
local li = require "love.image"

for i, file in pairs(nfs.getDirectoryItems(map_directory)) do
  local mapName, ext = file:match("(.+)%.(.+)")
  if nfs.mount(map_directory .. file, "map") then
    local mapData = love.filesystem.read(spring.getSMF("map"))
    if mapData then
      local  _, _, _, mapWidth, mapHeight, _, _, _, _, _, _, _, _, minimapOffset, _, _ = 
      ld.unpack("c16 i4 I4 i4 i4 i4 i4 i4 f f i4 i4 i4 i4 i4 i4", mapData)
      local minimapData = ld.unpack("c699048", mapData, minimapOffset + 1)
      minimapData = spring.headerStr .. minimapData
      local bytedata = ld.newByteData( minimapData )
      local compdata = li.newCompressedData(bytedata)
      channel:push({compdata, mapName, mapWidth, mapHeight})
    end
    nfs.unmount(map_directory .. file, "map")
  end
end
