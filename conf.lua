function love.conf(t)
  t.identity = "BALobby"
  t.window.title = "Balanced Annihilation Lobby"
  t.window.icon = "data/images/balogo.png"

  t.window.width = 640
  t.window.height = 288

  t.window.minwidth = 640
  t.window.minheight = 288

  t.window.resizable = false
  t.window.borderless = false
  
  --t.window.vsync = 2

  t.window.highdpi = true
  t.window.usedpiscale = true

  t.modules.audio = true
  t.modules.data = true
  t.modules.event = true
  t.modules.font = true
  t.modules.graphics = true
  t.modules.image = true
  t.modules.joystick = false
  t.modules.keyboard = true
  t.modules.math = true
  t.modules.mouse = true
  t.modules.physics = false
  t.modules.sound = true
  t.modules.system = true
  t.modules.thread = true
  t.modules.timer = true
  t.modules.touch = false
  t.modules.video = true
  t.modules.window = true
end