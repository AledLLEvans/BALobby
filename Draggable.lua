--© 2020 GitHub, Inc.
local Draggable = {}

local previous_relative_mode = love.mouse.getRelativeMode()

local dragging = false

local zone = {
  ["left"] = "top_left",
  ["right"] = "top_right",
  ["center"] = "top"
}

function Draggable.move(dx, dy)
  if dragging then
    local start_x, start_y, display_index = love.window.getPosition()
    local display_w, display_h = love.window.getDesktopDimensions(display_index)
    local win_w, win_h = love.window.getMode()
    
    -- prevent window from moving > 80% out of current display
    local minimum_x = 0 -- -0.8 * win_w
    local maximum_x = display_w - win_w

    local minimum_y = 0 -- -0.8 * win_h
    local maximum_y = display_h - 0.8 * win_h

    local target_x = math.max(minimum_x, math.min(maximum_x, start_x + dx))
    local target_y = math.max(minimum_y, math.min(maximum_y, start_y + dy))

    love.window.setPosition(target_x, target_y, display_index)
  end
end

function Draggable.start(x, y)
  previous_relative_mode = love.mouse.getRelativeMode()
  love.mouse.setRelativeMode(true)
  if x < 36 or x > lobby.width - 90 or y > 30 then
    return false
  end
  dragging = {x = love.mouse.getX(), y = love.mouse.getY(), zone = "center"}
  
  return true
end

local expand = {
  ["left"] = function(w,h) love.window.setPosition(0,0) return w/2, h end,
  ["right"] = function(w,h) love.window.setPosition(w/2,0) return w/2, h end,
  --["center"] = function(w,h) return false end,
  ["top_left"] = function(w,h) love.window.setPosition(0,0) return w/2, h/2 end,
  ["top_right"] = function(w,h) love.window.setPosition(w/2,0) return w/2, h/2 end,
  ["top"] = function(w,h) 
    if love.window.isMaximized() then
        lobby.resize(800, 600)
        love.window.updateMode(800, 600)
      else 
        love.window.maximize()
      end 
    return w, h 
  end
}

function Draggable.stop()
  local x, y, display_index = love.window.getPosition()
  local win_w, win_h = love.window.getMode()
  love.mouse.setRelativeMode(previous_relative_mode)
  if dragging then
    if x < 0.05 * win_w then
      dragging.zone = "left"
    elseif x > 0.95 * win_w then
      dragging.zone = "right"
    else
      dragging.zone = "center"
    end
    if y < 0.05 * win_h then
      dragging.zone = zone[dragging.zone]
    end
    love.mouse.setPosition(dragging.x, dragging.y)
    if dragging.zone ~= "center" then
      local w, h = love.window.getDesktopDimensions(display_index)
      lobby.resize(expand[dragging.zone](w, h))
      love.window.updateMode(lobby.width, lobby.height)
    end
    dragging = false
    return true
  end
  return false
end

function Draggable.dragging()
  return dragging
end

return Draggable