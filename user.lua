User = {}
User.mt =  {__index = User}
local lg = love.graphics

User.s = {}

function User:new(o)
  local new = o or {}
	setmetatable(new, User.mt)
  
  new.battleid = 0
  
  self.s[new.name] = new
	return new
end
