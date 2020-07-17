local http = require("socket.http")
local nativefs = require "nativefs"


local url, filename, filepath, pid = ...

local progress_channel = love.thread.getChannel("progress_" .. pid)

local function love_file_sink(filename, filepath)
  if filepath then
    local dir_ok = nativefs.createDirectory(filepath)
    if not dir_ok then error("Could not create directory "..filepath) end
  end
  local file = nativefs.newFile(filepath .. "\\" .. filename)
  local ok, err = file:open("w")
  if not ok then error(err) end
  return function(chunk, err)
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
      progress_channel:push({chunk = #chunk})
    else
      if err then
        progress_channel:push({error = err})
      else
        progress_channel:push({finished = true, downloading = false})
      end
    end
    return output_sink(chunk, err)
  end
end


while true do
  local proceed
  do
    local request = {
      url = url,
      method = "HEAD"
    }
    local success, status_code, response_header = http.request(request)
    if success then
      if status_code == 200 then
        file_size = response_header["content-length"]
        progress_channel:push({file_size = tonumber(response_header["content-length"])})
        proceed = true
      else
        progress_channel:push({error = string.format("Received status code %d", tonumber(status_code))})
      end
    else
      local err = status_code
      progress_channel:push({error = err})
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
        progress_channel:push({error = string.format("Received status code %d", tonumber(status_code))})
      end
    else
      local err = status_code
      progress_channel:push({error = err})
    end
  end
end
