local nfs = require "nativefs"
local lfs = love.filesystem
local unpacker_channel = love.thread.getChannel("unpacker")

local function count(folder, c)
  c = c or 0
	local filesTable = lfs.getDirectoryItems(folder)
	for i,v in ipairs(filesTable) do
		local file = folder.."/"..v
    local info = lfs.getInfo(file)
		if info and lfs.getInfo(file).type == "directory" then
			c = c + count(file)
    else
      c = c + 1
		end
	end
  return c
end

local function unzip(folder, saveDir)
	local filesTable = lfs.getDirectoryItems(folder)
	if saveDir ~= "" and not nfs.getInfo(saveDir) then nfs.createDirectory(saveDir) end
   
	for i,v in ipairs(filesTable) do
		local file = folder.."/"..v
		local saveFile = saveDir.."\\"..v
		if saveDir == "" then saveFile = v end
    local info = lfs.getInfo(file)
		if info and lfs.getInfo(file).type == "directory" then
			nfs.createDirectory(saveFile)
			unzip(file, saveFile)
		else
      unpacker_channel:push({pop = true})
			nfs.write(saveFile, tostring(lfs.read(file)))
		end
	end
  return true
end

local archive, destination = ...

local fileData = nfs.newFileData(archive)
local success = lfs.mount(fileData, "engine")
if not success then
  unpacker_channel:push({error = "could not mount engine 7zip"})
else
  unpacker_channel:push({fileCount = count("engine")})
  unpacker_channel:push({finished = unzip("engine", destination)})
end
lfs.unmount(fileData)