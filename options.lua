options = {}

local lg = love.graphics

function options.initialize()
  options.button = Button:new()
  :setPosition(0, 0)
  :setDimensions(36,36)
  :onClick(function()
    sound.tab:play()
    options.expanded = not options.expanded
    lobby.clickables[options.panel] = not lobby.clickables[options.panel]
    lobby.render.background()
  end)
  
  options.panel = Dropdown:new()
  :setPosition(0, 36)
  :setDimensions(163,174)
  
  options.expanded = false
  lobby.clickables[options.panel] = false
  
  function options.panel:click(x,y)
    local bool = false
    for button in pairs(self.buttons) do
      bool = button:click(x, y) or bool
    end
    options.expanded = false
    lobby.clickables[options.panel] = false
    return bool
  end
  
  function options.button:draw()
    if lobby.darkMode then
      lg.draw(img["MenuButtonDark"], self.x, self.y)
    else
      lg.draw(img["MenuButtonLight"], self.x, self.y)
    end
  end
  
  options.panel:addButton(Button:new():setText("Switch Mode")
    :setFunction(function()
          if lobby.darkMode then
            setLightMode()
            lobby.darkMode = false
            lobby.lightMode = true
            settings.add({mode = "light"})
          else
            setDarkMode()
            lobby.darkMode = true
            lobby.lightMode = false
            settings.add({mode = "dark"})
          end
          Channel.textbox.colors.background = colors.bg
          Channel.textbox.colors.text = colors.text
          local battle = Battle:getActive()
          if battle then
            for i, k in pairs(battle.buttons) do
              k.colors.background = colors.bb
              k.colors.text = colors.text
            end
          end
          for k in pairs(options.panel.buttons) do
            k.colors.background = colors.bb
            k.colors.text = colors.text
          end
          for id, bt in pairs(BattleTab.s) do
            bt.colors.background.default = colors.bb
            bt.colors.background.highlight = colors.bd
          end
          lobby.battlelist.scrollbar.colors.main = colors.bt
          lobby.battlelist.scrollbar.colors.inner = colors.bargreen
          Channel:getActive().scrollBar.colors.main = colors.bt
          Channel:getActive().scrollBar.colors.inner = colors.bargreen
          Channel.addButton.colors.background = colors.bg
          Channel.addButton.colors.text = colors.text
          lobby.refreshBattleTabs()
          lobby.render.userlist()
        end))
    
    options.panel:addButton(Button:new():setText("Replays")
    :setFunction(function()
          Replay.fetchLocalReplays()
          lobby.state = "replays"
        end))
    
    options.panel:addButton(Button:new():setText("Open Spring Dir")
    :setFunction(function()
          love.system.openURL(lobby.springFilePath)
        end))
    
    options.panel:addButton(Button:new():setText("Options")
    :setFunction(function()
          love.window.showMessageBox("FYI", "Coming Soon", "info")
          lobby.render.background()
        end))
  
  lobby.clickables[options.button] = true
end

return options