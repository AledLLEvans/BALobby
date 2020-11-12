Download = {}
Download.mt =  {__index = Download}

Download.s = 1

function Download:new(o)
  o = o or {}
	setmetatable(o, Download.mt)
  
  o.id = Download.s
  Download.s = Download.s + 1

  o.thread = love.thread.newThread("thread/downloader.lua")
  o.channel_string = "download_" .. o.id
  o.channel = love.thread.getChannel(o.channel_string)
  o.kchannel = love.thread.getChannel("k"..o.channel_string)
  
  o.downloading = false
  o.finished = false
  o.downloaded = 0
  o.file_size = 0
  o.filename = ""
  
  lobby.events[o] = true
	return o
end

function Download:push(url, filename, filepath)
  self.downloading = true
  self.filename = filename
  self.thread:start(url, filename, filepath, self.channel_string)
  print(url, filename, filepath, self.channel_string)
end

function Download:update(dt)
  local update = self.channel:pop()
  while update do
    if update.finished then
      self.finished = true
      self.downloading = false
      lobby.events[self] = nil
    end
    if update.file_size then
      print(update.file_size)
      self.file_size = update.file_size
    end
    if update.chunk then
      self.downloaded = self.downloaded + update.chunk
    end
    if update.error then
      print(update.error)
      self.error = update.error
      self.downloading = false
      lobby.events[self] = nil
    end
    update = self.channel:pop()
  end
end

function Download:quit()
  self.channel:push("quit")
end

function Download:release()
  self.thread:release()
end

return Download