img = {}

local lg = love.graphics

local IMAGE_FILES = {
  "loginBox",
  "balanced+annihilation+big+loadscreen-min",
  "indicator_red",
  "indicator_green",
  "popup_box",
  "nomap",
  "gamepad",
  "nothome",
  "monitor",
  "popup_box"
}

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

ranks = {}
for i=1,8 do
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
fonts.notable = lg.newFont("data/fonts/Notable/Notable-Regular.ttf", 30)
fonts.roboto = lg.newFont("data/fonts/Roboto/Roboto-Black.ttf", 20)
fonts.robotosmall = lg.newFont("data/fonts/Roboto/Roboto-Black.ttf", 12)
  
sound = {}
sound.ring = love.audio.newSource("data/sounds/doorbell-old-tring.ogg", "static")
sound.ding = love.audio.newSource("data/sounds/bell_02.ogg", "static")

--[[local function WriteScript(script)
  local txt = io.open('script.txt', 'w+')

	txt:write('[Game]\n{\n\n')
	-- First write Tables
	for key, value in pairs(script) do
		if type(value) == 'table' then
			txt:write('\t['..key..']\n\t{\n')
			for key, value in pairs(value) do
				txt:write('\t\t'..key..' = '..value..';\n')
			end
			txt:write('\t}\n\n')
		end
	end
	-- Then the rest (purely for aesthetics)
	for key, value in pairs(script) do
		if type(value) ~= 'table' then
			txt:write('\t'..key..' = '..value..';\n')
		end
	end
	txt:write('}')

	txt:close()
end

local script = {
	player0  =  {
		isfromdemo = 0,
		name = 'Local',
		rank = 0,
		spectator = 0,
		team = 0,
	},
	
	team0  =  {
		allyteam = 0,
		rgbcolor = '0.99609375 0.546875 0',
		side = 'CORE',
		teamleader = 0,
	},
	
	allyteam0  =  {
		numallies = 0,
	},

	gametype = 'Balanced Annihilation Reloaded Core $VERSION',
	hostip = '127.0.0.1',
	hostport = 8452,
	ishost = 1,
	mapname = 'Icy_Shell_v01',
	myplayername = 'Local',
	nohelperais = 0,
	numplayers = 1,
	numusers = 2,
	startpostype = 2,
}]]