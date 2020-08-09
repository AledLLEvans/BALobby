colors = {}

local lg = love.graphics

function setLightMode()
  colors.w = {1, 1, 1}
  colors.text = {0, 0, 0}
  colors.bgt = {219/255, 219/255, 219/255, 0.6}
  colors.bg = {225/255, 225/255, 225/255}
  colors.bb = {212/255, 212/255, 212/255}
  colors.bbh = {206/255, 206/255, 206/255}
  colors.bd = {200/255, 200/255, 200/255}
  colors.bt = {112/255, 112/255, 112/255}
  colors.mo = {50/255, 50/255, 50/255}
  colors.bargreen = {0, 191/255, 165/255}
  colors.orange = {1, 156/255, 67/255}
  colors.yellow = {1/2, 1/2, 0}
  lg.setBackgroundColor(colors.bg)
end

function setDarkMode()
  colors.w = {1, 1, 1}
  colors.text = {1, 1, 1}
  colors.bgt = {28/255, 28/255, 28/255, 0.6}
  colors.bg = {28/255, 28/255, 28/255}
  colors.bb = {33/255, 33/255, 33/255}
  colors.bbh = {39/255, 39/255, 39/255}
  colors.bd = {50/255, 50/255, 50/255}
  colors.bt = {112/255, 112/255, 112/255}
  colors.mo = {201/255, 201/255, 201/255}
  colors.bargreen = {28/255, 252/255, 139/255}
  colors.orange = {1, 156/255, 67/255}
  colors.yellow = {1, 1, 0}
  lg.setBackgroundColor(colors.bg)
end

setDarkMode()