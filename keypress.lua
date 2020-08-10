local lk = love.keyboard
local ls = love.system
return {
  ["c"] = function()
    if (lk.isDown("lctrl") or lk.isDown("rctrl")) and Channel:getTextbox():isActive() then
      ls.setClipboardText( Channel:getTextbox():getText() )
    end
  end,
  ["v"] = function()
    if (lk.isDown("lctrl") or lk.isDown("rctrl")) and Channel:getTextbox():isActive() then
      Channel:getTextbox():addText(ls.getClipboardText( ))
    end
  end,
  ["up"] = function()
    if lobby.channelMessageHistoryID then
      lobby.channelMessageHistoryID = math.max(1, lobby.channelMessageHistoryID - 1)
    else
      table.insert(Channel:getActive().sents, Channel:getActive():getText())
      lobby.channelMessageHistoryID = #Channel:getActive().sents
    end
    if Channel:getActive().sents[lobby.channelMessageHistoryID] then
      Channel:getActive():getTextbox():setText(Channel:getActive().sents[lobby.channelMessageHistoryID])
      Channel:getActive():getTextbox():toEnd()
    end
  end,
  ["down"] = function()
    if not lobby.channelMessageHistoryID then return end
    lobby.channelMessageHistoryID = math.min(lobby.channelMessageHistoryID + 1, #Channel:getActive().sents)
    if Channel:getActive().sents[lobby.channelMessageHistoryID] then
      Channel:getActive():getTextbox():setText(Channel:getActive().sents[lobby.channelMessageHistoryID])
      Channel:getActive():getTextbox():toEnd()
    end
  end,
  ["delete"] = function()
    Channel:getTextbox():delete()
  end,
  ["backspace"] = function()
    Channel:getTextbox():backspace()
  end,
  ["return"] = function()
    if Channel.active then
      if Channel:getTextbox():isActive() then
        if Channel:getTextbox():getText() == "" then return end
        if Channel:getActive().isServer then
          lobby.send(Channel:getActive():getText())
          return
        end
        local cmd = "SAY"
        local to = " " .. Channel:getActive():getName() .. " "
        if string.find(Channel:getActive():getName(), "Battle") then
          cmd = cmd .. "BATTLE"
          to = " "
        elseif Channel:getActive():isUser() then
          cmd = cmd .. "PRIVATE"
        end
        local text, sub = string.gsub(Channel:getActive():getText(), "^/me ", "", 1)
        if sub == 1 then cmd = cmd .. "EX" end
        lobby.send(cmd .. to .. text)
        lobby.channelMessageHistoryID = false
        table.insert(Channel:getActive().sents, Channel:getTextbox():getText())
        Channel:getTextbox():clearText()
      end
    end
  end,
  ["tab"] = function() 
  end,
  ["escape"] = function()
    if lobby.state == "replays" then
      lobby.state = "landing"
      ReplayTab:clean()
    elseif Battle:getActive() then
      Battle.exit()
    end
  end,
  ["left"] = function()
    if Channel:getActive() and Channel:getActive():getTextbox():isActive() then
      Channel:getActive():getTextbox():moveLeft()
    end
  end,
  ["right"] = function()
    if Channel:getActive() and Channel:getActive():getTextbox():isActive() then
      Channel:getActive():getTextbox():moveRight()
    end
  end
}