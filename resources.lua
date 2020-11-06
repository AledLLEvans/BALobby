img = {}

local lg = love.graphics
local lfs = love.filesystem

local flag_codes ={
"AF",
"AX",
"AL",
"DZ",
"AS",
"AD",
"AO",
"AI",
"AG",
"AR",
"AM",
"AW",
"AU",
"AT",
"AZ",
"BS",
"BH",
"BD",
"BB",
"BY",
"BE",
"BZ",
"BJ",
"BM",
"BT",
"BO",
"BA",
"BW",
"BV",
"BR",
"IO",
"BN",
"BG",
"BF",
"BI",
"CV",
"KH",
"CM",
"CA",
"KY",
"CF",
"TD",
"CL",
"CN",
"CX",
"CC",
"CO",
"KM",
"CG",
"CD",
"CK",
"CR",
"CI",
"HR",
"CU",
"CY",
"CZ",
"DK",
"DJ",
"DM",
"DO",
"EC",
"EG",
"SV",
"GQ",
"ER",
"EE",
"SZ",
"ET",
"FK",
"FO",
"FJ",
"FI",
"FR",
"GF",
"PF",
"TF",
"GA",
"GM",
"GE",
"DE",
"GH",
"GI",
"GR",
"GL",
"GD",
"GP",
"GU",
"GT",
"GN",
"GW",
"GY",
"HT",
"HM",
"VA",
"HN",
"HK",
"HU",
"IS",
"IN",
"ID",
"IR",
"IQ",
"IE",
"IL",
"IT",
"JM",
"JP",
"JO",
"KZ",
"KE",
"KI",
"KP",
"KR",
"KW",
"KG",
"LA",
"LV",
"LB",
"LS",
"LR",
"LY",
"LI",
"LT",
"LU",
"MO",
"MG",
"MW",
"MY",
"MV",
"ML",
"MT",
"MH",
"MQ",
"MR",
"MU",
"YT",
"MX",
"FM",
"MD",
"MC",
"MN",
"ME",
"MS",
"MA",
"MZ",
"MM",
"NA",
"NR",
"NP",
"NL",
"NC",
"NZ",
"NI",
"NE",
"NG",
"NU",
"NF",
"MK",
"MP",
"NO",
"OM",
"PK",
"PW",
"PS",
"PA",
"PG",
"PY",
"PE",
"PH",
"PN",
"PL",
"PT",
"PR",
"QA",
"RE",
"RO",
"RU",
"RW",
"SH",
"KN",
"LC",
"PM",
"VC",
"WS",
"SM",
"ST",
"SA",
"SN",
"RS",
"SC",
"SL",
"SG",
"SK",
"SI",
"SB",
"SO",
"ZA",
"GS",
"ES",
"LK",
"SD",
"SR",
"SJ",
"SE",
"CH",
"SY",
"TW",
"TJ",
"TZ",
"TH",
"TL",
"TG",
"TK",
"TO",
"TT",
"TN",
"TR",
"TM",
"TC",
"TV",
"UG",
"UA",
"AE",
"GB",
"US",
"UM",
"UY",
"UZ",
"VU",
"VE",
"VN",
"VG",
"VI",
"WF",
"XX",
"EH",
"YE",
"ZM",
"ZW",
}

local IMAGE_FILES = {
  --"balanced+annihilation+big+loadscreen-min",
  --"nomap",
  "gamepad",
  "nothome",
  "server",
  --"MenuButtonLight",
 --"MenuButtonDark",
  --"MenuPanelLight",
  --"MenuPanelDark",
  "eye",
  "players_zero",
  --"playersLight",
  --"playersDark",
  "playersBlue",
  --"playerslist_closed_light",
  --"playerslist_closed",
  "playerslist_closedBlue",
  --"playerslist_light",
  --"playerslist",
  "playerslistBlue",
  "musicOn",
  "musicOff",
  "back",
  "gear",
  "map",
  "bot",
  "exclamation",
  "ticked",
  "unticked"
}

--success = love.system.openURL( url )

ranks = {}
for i=1, 8 do
  ranks[i] = lg.newImage("data/images/ranks/rank"..i..".png")
end

local function loadImages()
  for i,v in ipairs(IMAGE_FILES) do
		img[v] = lg.newImage("data/images/"..v..".png")
	end
end

cursor = {}
cursor[2] = love.mouse.newCursor("data/images/scrollVertical.png", 25, 25)
cursor[3] = love.mouse.newCursor("data/images/scrollHorizontal.png", 25, 25)

flag = {}
local function loadFlags()
  	for i,v in ipairs(flag_codes) do
		flag[v] = lg.newImage("data/images/png/"..v:lower()..".png")
	end
end

loadFlags()
loadImages()

fonts = {}
fonts.krone =                 lg.newFont("data/fonts/Krone/krone.extrabold.ttf", 30)
fonts.krones =                lg.newFont("data/fonts/Krone/krone.shadow.ttf", 30)

fonts.notable =               lg.newFont("data/fonts/Notable/Notable-Regular.ttf", 30)

fonts.roboto =                lg.newFont("data/fonts/Roboto/Roboto-Black.ttf", 20)
fonts.robotoB =               lg.newFont("data/fonts/Roboto/Roboto-Black.ttf", 24)
fonts.robotosmall =           lg.newFont("data/fonts/Roboto/Roboto-Black.ttf", 12)
fonts.robotoitalic =          lg.newFont("data/fonts/Roboto/Roboto-Italic.ttf", 20)

fonts.latosmall =             lg.newFont("data/fonts/Lato/Lato-Regular.ttf", 12)
fonts.latoregular13 =         lg.newFont("data/fonts/Lato/Lato-Regular.ttf", 13)
fonts.latobig =               lg.newFont("data/fonts/Lato/Lato-Regular.ttf", 16)
fonts.latochantab =           lg.newFont("data/fonts/Lato/Lato-Regular.ttf", 12)
fonts.latochantabbold =       lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 14)
fonts.latomedium =            lg.newFont("data/fonts/Lato/Lato-Regular.ttf", 18)
fonts.latoitalic =            lg.newFont("data/fonts/Lato/Lato-Italic.ttf", 14)
fonts.latoitalicmedium =      lg.newFont("data/fonts/Lato/Lato-Italic.ttf", 18)
fonts.latolightitalic =       lg.newFont("data/fonts/Lato/Lato-LightItalic.ttf", 12)
fonts.latobold12 =            lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 12)
fonts.latobold14 =            lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 14)
fonts.latobold16 =            lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 16)
fonts.latobold18 =            lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 18)
fonts.latobold19 =            lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 19)
fonts.latobold20 =            lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 20)
fonts.latoboldbigger =        lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 24)
fonts.latoboldbiggest =       lg.newFont("data/fonts/Lato/Lato-Bold.ttf", 48)
fonts.latobolditalic =        lg.newFont("data/fonts/Lato/Lato-BoldItalic.ttf", 12)
fonts.latobolditalicmedium =  lg.newFont("data/fonts/Lato/Lato-BoldItalic.ttf", 16)

fonts.freesansbold12 =        lg.newFont("data/fonts/FreeSansBold.otf", 12)
fonts.freesansbold14 =        lg.newFont("data/fonts/FreeSansBold.otf", 14)
fonts.freesansbold16 =        lg.newFont("data/fonts/FreeSansBold.otf", 16)

fonts.latobold = fonts.latobold12
fonts.latoboldmedium = fonts.latobold14
fonts.latoboldbig = fonts.latobold16

sound = {}

sound.up = love.audio.newSource("data/sounds/sfx_09a.ogg", "static")
sound.down = love.audio.newSource("data/sounds/sfx_09b.ogg", "static")

sound.check = love.audio.newSource("data/sounds/sfx_20a.ogg", "static")

sound.woosh = love.audio.newSource("data/sounds/sfx_06.ogg", "static")
sound.woosh:setPitch(5)

sound.dwoosh = love.audio.newSource("data/sounds/sfx_10a.ogg", "static")
sound.dwoosh:setPitch(0.7)

sound.intro = love.audio.newSource("data/sounds/sfx_18a.ogg", "static")
sound.intro:setPitch(4)

sound.userlist = love.audio.newSource("data/sounds/sfx_10a.ogg", "static")

sound.tab = love.audio.newSource("data/sounds/sfx_04a.ogg", "static")
sound.tab:setPitch(5)

sound.cancel = love.audio.newSource("data/sounds/sfx_05c.ogg", "static")
sound.cancel:setPitch(1)

sound.ring = love.audio.newSource("data/sounds/doorbell-old-tring.ogg", "static")
sound.ding = love.audio.newSource("data/sounds/bell_02.ogg", "static")
sound.click = love.audio.newSource("data/sounds/metal_02.ogg", "static")
sound.click:setPitch(0.5)

function setSoundVolumes()
  sound.ring:setVolume(0.5)
  sound.click:setVolume(0.5)
  sound.intro:setVolume(0.5)
  sound.dwoosh:setVolume(0.7)
  sound.woosh:setVolume(0.5)
end
setSoundVolumes()

colors = {}

function setLightMode()
  colors.w = {1, 1, 1}
  colors.text = {0, 0, 0}
  colors.bgt = {219/255, 219/255, 219/255, 0.6}
  colors.bg = {225/255, 225/255, 225/255}
  colors.bb = {212/255, 212/255, 212/255}
  colors.bbb = {240/255, 240/255, 240/255}
  colors.bbh = {206/255, 206/255, 206/255}
  colors.bd = {200/255, 200/255, 200/255}
  colors.bt = {112/255, 112/255, 112/255}
  colors.mo = {50/255, 50/255, 50/255}
  colors.bargreen = {0, 191/255, 165/255}
  colors.barblue = {73/255, 203/255, 222/255}
  colors.textblue = {73/255, 203/255, 222/255}
  colors.orange = {252/255, 49/255, 281/255}
  colors.yellow = {1/2, 1/2, 0}
  colors.green = {28/255,252/255,139/255}
  lg.setBackgroundColor(colors.bg)
end

function setDarkMode()
  colors.w = {1, 1, 1}
  colors.text = {1, 1, 1, 1}
  colors.cb = {6/255, 7/255, 9/255}
  colors.bgt = {28/255, 28/255, 28/255, 0.6}
  colors.bg = {12/255, 14/255, 17/255}
  colors.bb = {4/255, 5/255, 5/255} --colors.bb = {33/255, 33/255, 33/255}
  colors.brb = {2/255, 6/255, 7/255, 0.6}
  colors.bbb = {0/255, 0/255, 0/255}
  colors.bbh = {8/255, 9/255, 12/255}
  colors.bd = {7/255, 9/255, 12/255}
  colors.bt = {112/255, 112/255, 112/255}
  colors.mo = {201/255, 201/255, 201/255}
  colors.bargreen = {28/255, 252/255, 139/255}
  colors.barblue = {73/255, 203/255, 222/255}
  colors.textblue = {73/255, 203/255, 222/255}
  colors.orange = {240/255, 71/255, 71/255}
  colors.yellow = {1, 1, 0}
  colors.green = {28/255,252/255,139/255}
  colors.readygreen = {33/255, 235/255, 62/255}
  colors.startgreen = {33/255, 235/255, 104/255}
  colors.readyred = {230/255,39/255,30/255}
  lg.setBackgroundColor(colors.bg)
end

settings = {}
function settings.unpack()
  local path = love.filesystem.getSaveDirectory( ) .. "/settings.lua"
  if lfs.getInfo( "settings.lua" ) then
    t = require "settings"
  end
  if t then
    for i, k in pairs(t) do
      settings[i] = k
    end
  end
  return settings
end

function settings.pack()
  local str = "return {"
  for i, k in pairs(settings) do
    if type(k) == "string" then
      k = string.gsub(k, "\"", "\\\"")
      str = str .. i .. " = \"" .. k .. "\","
    elseif type(k) == "number" then
      str = str .. i .. " = " .. k .. ","
    elseif type(k) == "boolean" then
      str = str .. i .. " = " .. tostring(k) .. ","
    end
  end
  str = str .. "}"
  return lfs.write( "settings.lua", str)
end

function settings.add(t, v)
  if type(t) == "table" then
    for i, k in pairs(t) do
      settings[i] = k
    end
  else
    settings[t] = v
  end
  return settings.pack()
end

function settings.remove(t)
  for i, _ in pairs(t) do
    settings[i] = nil
  end
  return settings.pack()
end

lobby = {}
settings.unpack()
if settings.mode then
  if settings.mode == "light" then
    setLightMode()
    lobby.darkMode = false
    lobby.lightMode = true
  elseif settings.mode == "dark" then
    setDarkMode()
    lobby.darkMode = true
    lobby.lightMode = false
  end
else
  settings.add({mode = "dark"})
  setDarkMode()
  lobby.darkMode = true
  lobby.lightMode = false
end
