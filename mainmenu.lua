lg = love.graphics
mainmenu = {}

player = {}

function mainmenu.new()
  
end

function mainmenu.enter()
	state = STATE_MAINMENU
end

MAINMENU_MAIN = 0
MAINMENU_TUTORIAL = 1
MAINMENU_PLAY = 2
MAINMENU_OPTIONS = 3
MAINMENU_ABOUT = 4
mainmenu.buttons = {"Instructions", "Play", "Options", "Credits"}
mainmenu.options = {"Leisure", "Normal", "Challenge", "Insane"}
smw, smh = love.graphics.getDimensions()

function mainmenu.update(dt)
  
end

function mainmenu.keypressed(k, uni)
  
end

function mainmenu.keyreleased(k, uni)
  
end

function mainmenu.draw()
  for i, k in pairs(mainmenu.snails) do
    lg.draw(img.snail1, k.x, k.y, 0, 10/300)
  end
  if mainmenu.screen == MAINMENU_MAIN then
    mainmenu.draw_main()
  elseif mainmenu.screen == MAINMENU_TUTORIAL then
    mainmenu.draw_tutorial()
  elseif mainmenu.screen == MAINMENU_ABOUT then
    lg.printf("Game by Masta Ali\n\nArt and Images by Don Richard\n\nMusic by /soundimage.org/", 40, 100, 120, "left", 0, 5)
  elseif mainmenu.screen == MAINMENU_OPTIONS then
    mainmenu.draw_options()
  end
  lg.draw(img.sun, 50,50)
end

function mainmenu.draw_main()
  if player.bestscore > 0 then
    lg.printf("HIGHSCORE:", smw/2-50, 80, 500, "left")
    lg.printf(player.bestscore, smw/2-40, 100, 500, "left")
  end
  if #player.won > 0 then
    lg.printf("Beaten on:", smw/2+50, 80, 500, "left")
    j = 0
    for i, k in ipairs(mainmenu.options) do
      if player.won[i] then
        j = j + 1
        lg.printf(k.." in "..player.won[i].." seconds", smw/2+60, 80 + j*20, 500, "left")
      end
    end
  end
  for i = 1, #mainmenu.buttons do
    if mainmenu.keyheld and i == mainmenu.selection then
      lg.draw(img.BTN_GRAY_RECT_IN, smw/2 + 10, smh/2 - 60 + 5 + i*50, 0, 1/4, 1/4, 381/2, 138/2)
    else
      lg.draw(img.BTN_GRAY_RECT_OUT, smw/2 + 10, smh/2 - 60 + 5 + i*50, 0, 1/4, 1/4, 381/2, 138/2)
    end
    lg.setColor(0, 0, 0)
    lg.print(mainmenu.buttons[i], smw/2 - 20 - 2, smh/2 - 60 -4 + i*50)
    lg.setColor(1, 1, 1)
  end
  if mainmenu.keyheld then
    lg.draw(img.arrowright, smw/2 - 50 , smh/2 + mainmenu.selection*50 - 60+5, 0, 3/4, 3/4, 45/2, 52/2)
  else
    lg.draw(img.arrowright, smw/2 - 50 - 20, smh/2 + mainmenu.selection*50 - 60+5, 0, 2/3, 2/3, 45/2, 52/2)
  end
end

function mainmenu.draw_tutorial()
  lg.printf("Instructions:", 40, 120, 500, "left")
  lg.printf("Arrow keys or WASD to move, consume snails smaller than you to grow.", 40, 140, 500, "left")
  lg.printf("Do not touch larger snails, you will be consumed!", 40, 160, 500, "left")
  lg.printf("Hit P to pause.", 40, 180, 500, "left")
  lg.printf("Difficulty determines your starting size and growth rate in addition to the quantity, size and speed of the other snails.", 40, 200, 500, "left")
  lg.printf("Hints:", 40, 260, 500, "left")
  lg.printf("Stay away from the edges of the screen.", 40, 280, 500, "left")
  lg.printf("Your snail MUST be bigger, dont take that risk if you aren't certain!", 40, 300, 500, "left")
  lg.printf("Some snails are very elusive, tackling them head on gives you a better chance.", 40, 320, 500, "left")
  lg.printf("A snail will not run away if it is bigger than you.", 40, 340, 500, "left")
  lg.printf("This is a game of patience, dont be a rash guppy.", 40, 360, 500, "left")
  
  if mainmenu.keyheld then
    lg.draw(img.BTN_GRAY_RECT_IN, smw/2 - 200, smh/2 + 200, 0, 1/4, 1/4, 381/2, 138/2)
  else
    lg.draw(img.BTN_GRAY_RECT_OUT, smw/2 - 200, smh/2 + 200, 0, 1/4, 1/4, 381/2, 138/2)
  end
  lg.setColor(0, 0, 0)
  lg.print("Back", smw/2 - 200 - 15, smh/2 + 200 - 4)
  lg.setColor(1, 1, 1)
end
  
function mainmenu.draw_options()
  if mainmenu.keyheld then
   lg.draw(img.arrowright, smw/2 + 50 - 120+20, smh/2 + mainmenu.options_selection*50 + 50 - 60 + 5, 0, 3/4, 3/4, 45/2, 52/2)
 else
   lg.draw(img.arrowright, smw/2 + 50 - 120, smh/2 + mainmenu.options_selection*50 + 50 - 60 + 5, 0, 2/3, 2/3, 45/2, 52/2)
  end
  for i, k in pairs (mainmenu.options) do
    if mainmenu.keyheld and i-1 == mainmenu.options_selection then
      lg.draw(img.BTN_GRAY_RECT_IN, smw/2 + 10, smh/2 - 60 + 5 + i*50, 0, 1/4, 1/4, 381/2, 138/2)  
    else
      lg.draw(img.BTN_GRAY_RECT_OUT, smw/2 + 10, smh/2 - 60 + 5 + i*50, 0, 1/4, 1/4, 381/2, 138/2)
    end
    lg.draw(img.BTN_CHECKBOX_OUT, smw/2 + 10 + 90, smh/2 - 60 + 5 + i*50, 0, 1/2, 1/2, 30, 30)
    lg.setColor(0, 0, 0)
    lg.print(k, smw/2 - 20, smh/2 - 60 + i*50)
    lg.setColor(1, 1, 1)
  end
  if mainmenu.keyheld and mainmenu.options_selection == 4 then
    lg.draw(img.BTN_GRAY_RECT_IN, smw/2 + 10, smh/2 - 60 + 5 + 5*50, 0, 1/4, 1/4, 381/2, 138/2)
  else
    lg.draw(img.BTN_GRAY_RECT_OUT, smw/2 + 10, smh/2 - 60 + 5 + 5*50, 0, 1/4, 1/4, 381/2, 138/2)
  end
  lg.draw(img.BTN_CHECKBOX_IN, smw/2 + 10 + 90, smh/2 - 60 + 5 + DIFFICULTY*50 + 50, 0, 1/2, 1/2, 30, 30)
  lg.setColor(0, 0, 0)
  lg.print("Main Menu", smw/2 - 20, smh/2 - 60 + 5*50)
  lg.setColor(1, 1, 1)
end