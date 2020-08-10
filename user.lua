User = {}
User.mt =  {__index = User}
local lg = love.graphics

User.s = {}
User.count = 0

function User:new(o)
  local new = o or {}
	setmetatable(new, User.mt)
  
  new.battleid = 0
  self.count = self.count + 1
  
  self.s[new.name] = new
	return new
end

function User:openChannel()
  if self.channel then self.channel.display = true return self.channel end
  self.channel = Channel:new({title = self.name, user = true, display = true})
  self.channel.users = {[self.name] = self, [lobby.username] = User.s[lobby.username]}
  Channel.s[self.name] = self.channel
  Channel.active = self.channel
  Channel:refreshTabs()
  self.channel:getTextbox().active = true
  lobby.render.userlist()
  return self.channel
end
