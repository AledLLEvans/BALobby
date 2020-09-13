local header = {}
local lg = love.graphics

function header.initialize(bool)
  if bool then
    lobby.clickables[header.close] = nil
    lobby.clickables[header.maximize] = nil
    lobby.clickables[header.minimize] = nil
    return
  end
  header.close = Button:new()
  :setPosition(lobby.width-30, 0)
  :setDimensions(30,30)
  :setFunction(function() love.event.quit() end)
  
  header.maximize = Button:new()
  :setPosition(lobby.width-60, 0)
  :setDimensions(30,30)
  :setFunction(function()
      if love.window.isMaximized() then
        lobby.resize(800, 600)
        love.window.updateMode(800, 600)
      else 
        love.window.maximize()
        local _, _, flags = love.window.getMode() 
        lobby.resize(love.window.getDesktopDimensions( flags.display )) 
      end
    end)
  
  header.minimize = Button:new()
  :setPosition(lobby.width-90, 0)
  :setDimensions(30,30)
  :setFunction(function()
      if love.window.isMinimized() then
        love.window.restore( )
      else 
        love.window.minimize()
      end
    end)

  function header.close:draw()
    lg.setColor(colors.bargreen)
    lg.rectangle("fill", self.x, self.y, self.w, self.y)
    lg.setColor(colors.text)
    lg.setFont(fonts.latoboldbig)
    lg.print("X", self.x + self.w/4, self.y + self.h/4)
  end
  
  function header.maximize:draw()
    lg.setColor(colors.bt)
    lg.rectangle("fill", self.x, self.y, self.w, self.y)
    lg.setColor(colors.text)
    lg.setFont(fonts.latoboldbig)
    lg.print("| |", self.x + self.w/4, self.y + self.h/4)
  end
  
  function header.minimize:draw()
    lg.setColor(colors.bt)
    lg.rectangle("fill", self.x, self.y, self.w, self.y)
    lg.setColor(colors.text)
    lg.setFont(fonts.latoboldbig)
    lg.print("__", self.x + self.w/4, self.y + self.h/4)
  end
  
  lobby.clickables[header.close] = true
  lobby.clickables[header.maximize] = true
  lobby.clickables[header.minimize] = true
end

function header.resize()
  header.close:setPosition(lobby.width-30, 0)
  header.maximize:setPosition(lobby.width-60, 0)
  header.minimize:setPosition(lobby.width-90, 0)
end

function header:draw()
  header.close:draw()
  header.maximize:draw()
  header.minimize:draw()
end

return header