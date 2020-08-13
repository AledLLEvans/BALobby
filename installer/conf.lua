function love.conf(t)
  t.identity = "BALobby"
  t.window.title = "Balanced Annihilation Lobby Installer"
  t.window.icon = "balogo.png"

  t.window.width = 640
  t.window.height = 288

  t.window.minwidth = 640
  t.window.minheight = 288

  t.window.resizable = true
  
  --t.window.vsync = 2

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