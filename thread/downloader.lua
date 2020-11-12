local http = require("socket.http")
local nativefs = require "lib/nativefs"
local download_finished = false

local url, filename, filepath, channel_string = ...

local channel = love.thread.getChannel(channel_string)
local killchannel = love.thread.getChannel("k"..channel_string)

local quit = false
local function love_file_sink(filename, filepath)
  if filepath then
    local dir_ok = nativefs.createDirectory(filepath)
    if not dir_ok then error("Could not create directory "..filepath) end
  end
  local file = nativefs.newFile(filepath .. "\\" .. filename)
  local ok, err = file:open("w")
  if not ok then error(err) end
  return function(chunk, err)
    if killchannel:pop() == 1 then print("removing") file:close() print(nativefs.remove(filepath .. "\\" .. filename)) killchannel:push(2) return nil end
    if chunk then
      local ok, err = file:write(chunk, #chunk)
      if not ok then return nil, err end
    else
      file:close()
      return nil, err
    end
    return true
  end
end

local function progress_sink(output_sink)
  return function(chunk, err)
    if chunk then
      channel:push({chunk = #chunk})
    else
      if err then
        channel:push({error = err})
      else
        channel:push({finished = true, downloading = false})
        download_finished = true
      end
    end
    return output_sink(chunk, err)
  end
end

while not download_finished do
  local proceed
  do
    local request = {
      url = url,
      method = "HEAD"
    }
    local success, status_code, response_header = http.request(request)
    if success then
      if status_code == 200 then
        channel:push({file_size = tonumber(response_header["content-length"])})
        proceed = true
      else
        channel:push({error = string.format("Received status code %d", tonumber(status_code))})
      end
    else
      local err = status_code
      channel:push({error = err})
    end
  end

  if proceed then
    local output_sink = love_file_sink(filename, filepath)
    local request = {
      url = url,
      sink = progress_sink(output_sink),
      method = "GET",
    }
    local success, status_code = http.request(request)
    if success then
      if status_code ~= 200 then
        channel:push({error = string.format("Received status code %d", tonumber(status_code))})
      end
    else
      local err = status_code
      channel:push({error = err})
    end
  end
end
