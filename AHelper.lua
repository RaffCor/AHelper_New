script_name('AHelper')
script_authors('Ken_Higa (RaffCor)')
script_version_number(1)
script_version("3.0")
script_properties("work-in-pause")

-- Подключение библиотек
local font_flag = require('moonloader').font_flag
local dlstatus = require('moonloader').download_status
local result_sampev, sampev = pcall (require, 'lib.samp.events')
local result_imgui, imgui = pcall (require, 'imgui')
local result_requests, requests = pcall (require, 'requests')
local result_encoding, encoding = pcall (require, 'encoding')
local result_memory, memory = pcall (require, 'memory')
local result_icons, fa = pcall (require, 'fAwesome5')
local result_lanes = pcall (require, 'lanes')
local result_imgui_notf, notf = pcall (import, 'imgui_notf.lua')
local result_vkeys, vkeys = pcall (require, 'vkeys')
local result_slnet, slnet = pcall (require, 'slnet')
local result_hotkeys, hk = pcall (require, 'hotkey')
local result_rkeys, rkeys = pcall (require, 'rkeys')
local result_matrix, Matrix3X3 = pcall (require, "matrix3x3")
local result_vector, Vector3D = pcall (require, "vector3d")
local ffi = require 'ffi'
local inicfg = require 'inicfg'


if result_lanes then
	lanes = require ('lanes').configure()
end
if result_slnet then
	client = slnet.client()
end

ffi.cdef[[
	short GetKeyState(int nVirtKey);
	bool GetKeyboardLayoutNameA(char* pwszKLID);
	int GetLocaleInfoA(int Locale, int LCType, char* lpLCData, int cchData);


]]
local BuffSize = 32
local KeyboardLayoutName = ffi.new("char[?]", BuffSize)
local LocalInfo = ffi.new("char[?]", BuffSize)


ffi.cdef[[
struct stKillEntry
{
	char					szKiller[25];
	char					szVictim[25];
	uint32_t				clKillerColor; // D3DCOLOR
	uint32_t				clVictimColor; // D3DCOLOR
	uint8_t					byteType;
} __attribute__ ((packed));

struct stKillInfo
{
	int						iEnabled;
	struct stKillEntry		killEntry[5];
	int 					iLongestNickLength;
  	int 					iOffsetX;
  	int 					iOffsetY;
	void			    	*pD3DFont; // ID3DXFont
	void		    		*pWeaponFont1; // ID3DXFont
	void		   	    	*pWeaponFont2; // ID3DXFont
	void					*pSprite;
	void					*pD3DDevice;
	int 					iAuxFontInited;
    void 		    		*pAuxFont1; // ID3DXFont
    void 			    	*pAuxFont2; // ID3DXFont
} __attribute__ ((packed));
]]

keyToggle = VK_MBUTTON
keyApply = VK_LBUTTON

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

local tCarsName = {"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
	"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BFInjection", "Hunter",
	"Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo",
	"RCBandit", "Romero","Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed",
	"Yankee", "Caddy", "Solair", "Berkley'sRCVan", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RCBaron", "RCRaider", "Glendale", "Oceanic", "Sanchez", "Sparrow",
	"Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage",
	"Dozer", "Maverick", "NewsChopper", "Rancher", "FBIRancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "BlistaCompact", "PoliceMaverick",
	"Boxvillde", "Benson", "Mesa", "RCGoblin", "HotringRacerA", "HotringRacerB", "BloodringBanger", "Rancher", "SuperGT", "Elegant", "Journey", "Bike",
	"MountainBike", "Beagle", "Cropduster", "Stunt", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "hydra", "FCR-900", "NRG-500", "HPV1000",
	"CementTruck", "TowTruck", "Fortune", "Cadrona", "FBITruck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight",
	"Streak", "Vortex", "Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada",
	"Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RCTiger", "Flash", "Tahoma", "Savanna", "Bandito",
	"FreightFlat", "StreakCarriage", "Kart", "Mower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "NewsVan",
	"Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club", "FreightBox", "Trailer", "Andromada", "Dodo", "RCCam", "Launch", "PoliceCar", "PoliceCar",
	"PoliceCar", "PoliceRanger", "Picador", "S.W.A.T", "Alpha", "Phoenix", "GlendaleShit", "SadlerShit", "Luggage A", "Luggage B", "Stairs", "Boxville", "Tiller",
	"UtilityTrailer"}
local tCarsTypeName = {"Автомобиль", "Мотоицикл", "Вертолёт", "Самолёт", "Прицеп", "Лодка", "Другое", "Поезд", "Велосипед"}
local tCarsSpeed = {43, 40, 51, 30, 36, 45, 30, 41, 27, 43, 36, 61, 46, 30, 29, 53, 42, 30, 32, 41, 40, 42, 38, 27, 37,
	54, 48, 45, 43, 55, 51, 36, 26, 30, 46, 0, 41, 43, 39, 46, 37, 21, 38, 35, 30, 45, 60, 35, 30, 52, 0, 53, 43, 16, 33, 43,
	29, 26, 43, 37, 48, 43, 30, 29, 14, 13, 40, 39, 40, 34, 43, 30, 34, 29, 41, 48, 69, 51, 32, 38, 51, 20, 43, 34, 18, 27,
	17, 47, 40, 38, 43, 41, 39, 49, 59, 49, 45, 48, 29, 34, 39, 8, 58, 59, 48, 38, 49, 46, 29, 21, 27, 40, 36, 45, 33, 39, 43,
	43, 45, 75, 75, 43, 48, 41, 36, 44, 43, 41, 48, 41, 16, 19, 30, 46, 46, 43, 47, -1, -1, 27, 41, 56, 45, 41, 41, 40, 41,
	39, 37, 42, 40, 43, 33, 64, 39, 43, 30, 30, 43, 49, 46, 42, 49, 39, 24, 45, 44, 49, 40, -1, -1, 25, 22, 30, 30, 43, 43, 75,
	36, 43, 42, 42, 37, 23, 0, 42, 38, 45, 29, 45, 0, 0, 75, 52, 17, 32, 48, 48, 48, 44, 41, 30, 47, 47, 40, 41, 0, 0, 0, 29, 0, 0
}
local tCarsType = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1,
	3, 1, 1, 1, 1, 6, 1, 1, 1, 1, 5, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 6, 3, 2, 8, 5, 1, 6, 6, 6, 1,
	1, 1, 1, 1, 4, 2, 2, 2, 7, 7, 1, 1, 2, 3, 1, 7, 6, 6, 1, 1, 4, 1, 1, 1, 1, 9, 1, 1, 6, 1,
	1, 3, 3, 1, 1, 1, 1, 6, 1, 1, 1, 3, 1, 1, 1, 7, 1, 1, 1, 1, 1, 1, 1, 9, 9, 4, 4, 4, 1, 1, 1,
	1, 1, 4, 4, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 8, 7, 1, 1, 1, 1, 1, 1, 1,
	1, 3, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 8, 7, 1, 1, 1, 1, 1, 4,
	1, 1, 1, 2, 1, 1, 5, 1, 2, 1, 1, 1, 7, 5, 4, 4, 7, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 1, 5, 5
}


-- Переменные:
local pInfo = { -- Главная информация, которая сохраняется в БД
	info = {
		playerAccountNumber = 0,
		adminLevel = 1,
		reports = 0,
		punishments = 0,
		accept = true,
		nickname = ""
	},
	set = {
		AutoDuty = false,
		AutoAint = false,
		AutoTogphone = false,
		AutoFon = false,
		AutoSmson = false,
		AutoHideIP = false,
		AutoHideChat = false,
		AutoWH = false,
		AutoBan = false,
		AutoAnswer = false,
		OnlineAdmins = false,
		OnlinePlayers = false,
		recolor_a = false,
		recolor_r = false,
		recolor_p = false,
		recolor_s = false,
		newLip = false,
		converter = false,
		invisible_onfoot = false,
		air_activate = true,
		fps_unlock = true,
		clickwarp = false,
		clock = false,
		forms = true,
		keys_panel = false,
		re_panel_change = false,
		re_panel_style = 1,
		right_panel_change = 0,
		font_size = 3,
		rpX = 0,
		rpY = 0,
		lpX = 0,
		lpY = 0,
		clX = 0,
		clY = 0,
		kX = 0,
		kY = 0,
		ip_hash = 1,
		type_wh,
		cX,
		cY,
		pX,
		pY,
		SkinDuty,
		FloodMinute,
		CapsMinute,
		OfftopMinute,
		OskMinute,
		NeuvMonute,
		NeadMinute,
		CaptOMinute,
		CaptKMinute,
		OskNickMinute,
		skMinute,
		tkMinute,
		mopDays,
		tpDays,
		gmcarDays,
		aimDays,
		fWHDays,
		dgunDays,
		airbrkDays,
		antistunDays,
		turboDays,
		AirBrakeSpeed,
		colorAChat = 4278241535,
		colorReport = 2905604013,
		colorPm = 872388915,
		colorSMS = 872388915,
		sizeWidget = 1.0,
		r_text = "",
		auto_screen = 0,
		admSortType = 0,
		fastMap = false,
		premium = 1,
		a_n_chat = true,
		a_n_color = 0,
		p_admAct = false,
		p_admAct_color = 0,
		p_admSpec = false,
		p_admSpec_color = 0,
		p_gang = false,
		p_pang_color = 0,
		p_msg = false,
		p_msg_color = 0,
		panel_cheat = true,
		p_cheat = true,
		pcx = 0,
		pcy = 0,
		s_notf = false,
		s_notf_id = 1,
		nget = false,
		afk = true,
		bindAccess = false,
		bsync = {
			enable = true,
			ponly = false,
			polygon_enable = true,
			maxLines = 50,
			time = 2,
			weightLine = 2,
			sizePolygon = 3,
			countCorners = 50,
			rotation = 0,
			colorPlayer = 1828657947,
			colorPlayerAFK = 1821900944,
			colorCar = -8466176,
			colorStaticObj = -1,
			colorDynamicObj = -1
		},
		warnings = {
			textures = true,
			hit = true,
			deagle = 5,
			m4 = 10,
			shotgun = 8,
			pistol = 7,
			silenced = 7,
			mp5 = 10,
			ak47 = 10,
			rifle = 10,
			speedhack = true,
			speedhack_delay = 2,
			repair = true
		},
		widget = {
			kills = true,
			time_s = true,
			pm_all = true,
			pun_all = true,
			pm_day = true,
			pun_day = true,
			datetime = true,
			in_s = true,
			chat = true,
			server_status = true,
		},
		chatlog_name = "chatlog_" .. os.date("%d") .. "-" .. os.date("%m") .. "-" .. os.date("%y") .. " " .. os.date("%H") .. "-" .. os.date("%M") .. "-" .. os.date("%S")
	}
}

local x, y = getScreenResolution()

local pTemp = { -- Временные переменные, обнуляемые при перезапуске скрипта/перезаходе в игру
	login = false,
	lim = false,
	check_numberAccount = false,
	update = {
		menu = false,
		status = false,
		version = "",
		date = "",
		description = "",
		unsupported_number = 0,
		unsupported_version = ""
	},
	user = {
		checkAccount = false,
		addAccount = false,
		loadAccount = false,
		loadChecker = false,
		loadAdm = false,
		check_access = false,
		old_level = 0,
		load_colors = false,
		load_custom_cmd = false,
		load_answers = false,
		load_bans = false,
		second_ip = false,
		second_ip1 = false,
		load_hkeys = false,
		load_cmds = false,
	},
	menu_id = 1,
	submenu_id = 1,
	show_pass = false,
	show_pass_a = false,
	adminPassword = false,
	stage = 0,
	admTD = {},
	admTD_Click = {},
	one_time = false,
	spec_id = 300,
	WH_Status = false,
	spec_veh = nil,
	chat = {
		chat_delay = os.time(),
		chat_text = "",
		chat_text_temp = "",
	},
	slnet_conn = 0,
	adminQuit = {},
	admUpdate = false,
	objectSetPos = 0,
	specTime = 0,
	spectate = 0,
	count_reports_all = 0,
	count_punish_all = 0,
	count = 0,
	count_punish = 0,
	count_ban = 0,
	count_cban = 0,
	count_sban = 0,
	count_scban = 0,
	count_mute = 0,
	count_kick = 0,
	count_skick = 0,
	count_jail = 0,
	count_form_ban = 0,
	count_form_jail = 0,
	count_form_ban_y = 0,
	count_form_jail_y = 0,
	change_re_panel_pos = imgui.ImVec2(x / 10, y / 2),
	change_re_panel_pos_right = imgui.ImVec2(x / 1.2, y / 1.35),
	connecting = false,
	re_panel = {
		nick = "",
		id = 0,
		kills = 0,
		deaths = 0,
		loc = "",
		skill = "",
		health = 0,
		armour = 0,
		shot = 0,
		hit = "",
		speed = 0,
		weapon = "",
		ammo = 0,
		session_time = "",
		skin = 0,
		ping = 0,
		fps = 0,
		package_loss = "",
		ip = ""
	},
	veh_speed = 0,
	max_veh_speed = 0,
	vehicle_health = 1000,
	player_time_session = {},
	antiCheat = false,
	delay = {
		speedhack = {},
		air = {},
		textures = {}
	},
	punish = {
		ban = false,
		cban = false,
		sban = false,
		scban = false,
		jail = false,
		unban = false,
		uncban = false,
		unbanip = false,
		days = 0,
		d_reason = "nil",
		d_nick = "nil",
		d_days = 0,
		d_status = false,
		d_cstatus = false,
		d_mstatus = false,
		d_jstatus = false,
		da_status = false,
		da_cstatus = false,
		da_mstatus = false,
		da_jstatus = false,
	},
	connection_timeout = os.time() + 30 * 60,
	pers_activate = false,
	report_nick = '',
	spec_name = '',
	s_id = 300,
	fast_punish = 0,
	time_message = os.time(),
	AirBrake = false,
	nick_off = '',
	tp_marker_fix = false,
	markX = 0,
	markY = 0,
	textures_id = 300,
	users_online = 0,
	tempCheatID = 300,
	exchange_id = 0,
	start_afk = 0,
	statusafk = true,
	afk_time = 0,
	loading_time = 0,
	AnswerID = 300,
	tempCheatNickName = '',
	key_antiflood = false,
	setkey = 0,
	cmd_antiflood = os.time(),
	focus = true,
	acr = false,
	req_id = 0,
	in_ac = false,
}

local a_cmd = {}
local change_cmd = {}
local answers = {}
local change_answers_title = {}
local change_answers_text = {}
local Panel = {
	aim = {},
	air = {}
}
local bans = {}
local bans_change_type = {}
local bans_change_time = {}
local bans_change_reason = {}

local uhkey = {}
local imgui_hkey = {}
local imgui_action = {
	'Главное меню',
	'Переход к главной странице',
	'Переход к статистике',
	'Переход к настройкам',
	'Переход к оффлайн наказаниям',
	'Переход к меню мероприятий',
	'Переход к командам',
	'Переход к таблице наказаний',
	'Переход к списку изменений',
	'Быстрая слежка на варнинги',
	'Меню быстрых наказаний (только в реконе)',
	'Быстрый бан за оскорбление родных',
	'Быстрый мут за упоминание родных',
	'Принять форму',
	'Отклонить форму',
	'Быстрая карта'
}
for i = 1, #imgui_action do
	imgui_hkey[i] = imgui.ImBuffer(256)
end

local aim_warnings = {
	M4 = {
		first = {},
		series = 2,
		count = {}
	},
	Deagle = {
		first = {},
		series = 3,
		count = {}
	},
	Pistol = {
		first = {},
		series = 3,
		count = {}
	},
	Silenced = {
		first = {},
		series = 3,
		count = {}
	},
	Shotgun = {
		first = {},
		series = 4,
		count = {}
	},
	MP5 = {
		first = {},
		series = 2,
		count = {}
	},
	AK47 = {
		first = {},
		series = 2,
		count = {}
	},
	Rifle = {
		first = {},
		series = 2,
		count = {}
	}
}

local warnings = {
	shooting = {
		M4 = {
			maxHit = 10
		},
		Deagle = {
			maxHit = 5
		},
		Pistol = {
			maxHit = 7
		},
		Silenced = {
			maxHit = 7
		},
		Shotgun = {
			maxHit = 8
		},
		MP5 = {
			maxHit = 10
		},
		AK47 = {
			maxHit = 10
		},
		Rifle = {
			maxHit = 8
		}
	},
	speedhack = {
		delay = 2
	},
	delay_textures = 3,
	cleo_repair = {},
	teleport = {
		old_pos = {
			x = {},
			y = {},
			z = {}
		}
	}
}

local pVar = {
	-- для вывода данных из БД по формам
	pID = {},
	pAdmin = {},
	pNumAdmin = {},
	pPlayer = {},
	pType = {},
	pTime = {},
	pReason = {},
	pReasU8 = {},
	pDate = {},
	pStatus = {},
	pAdmin_Ext = {},
	pDate_Ext = {},
	pStatusExt = {}
}

local rVar = {
	-- для вывода данных из БД по формам
	pID = {},
	pAdmin = {},
	pNumAdmin = {},
	pPlayer = {},
	pType = {},
	pTime = {},
	pReason = {},
	pReasU8 = {},
	pDate = {},
	pStatus = {},
	pAdmin_Ext = {},
	pDate_Ext = {},
	pStatusExt = {}
}

local Hit = {
	Deagle = {},
	M4 = {},
	Shotgun = {},
	MP5 = {},
	AK47 = {},
	Rifle = {},
	Silenced = {},
	Pistol9mm = {}
}

local sInfo = { -- Инфа о настройках скрипта, получаемая из .json файлов
	status = "", -- Отвечает, разрешён ли запуск скрипта
	url = "", -- URL для запросов
	reason_off = "", -- Причина для отключения или ограничения работы скрипта
	MAX_PLAYERS = 300, -- Максимальное количество игроков на сервере
	delay = 60, -- Задержка при проверке новых запросов на снятие наказаний
}

for i = 0, sInfo.MAX_PLAYERS do
	aim_warnings.Deagle.first[i] = os.clock()
	aim_warnings.Deagle.count[i] = 0
	aim_warnings.M4.first[i] = os.clock()
	aim_warnings.M4.count[i] = 0
	aim_warnings.Pistol.first[i] = os.clock()
	aim_warnings.Pistol.count[i] = 0
	aim_warnings.AK47.first[i] = os.clock()
	aim_warnings.AK47.count[i] = 0
	aim_warnings.MP5.first[i] = os.clock()
	aim_warnings.MP5.count[i] = 0
	aim_warnings.Rifle.first[i] = os.clock()
	aim_warnings.Rifle.count[i] = 0
	aim_warnings.Shotgun.first[i] = os.clock()
	aim_warnings.Shotgun.count[i] = 0
	aim_warnings.Silenced.first[i] = os.clock()
	aim_warnings.Silenced.count[i] = 0
end

for i = 0, sInfo.MAX_PLAYERS do
	pTemp.player_time_session[i] = 0
	Hit.Deagle[i] = tonumber (Hit.Deagle)
	Hit.Deagle[i] = 0
	Hit.M4[i] = tonumber(Hit.M4[i])
	Hit.M4[i] = 0
	Hit.Shotgun[i] = tonumber(Hit.Shotgun[i])
	Hit.Shotgun[i] = 0
	Hit.MP5[i] = tonumber(Hit.MP5[i])
	Hit.MP5[i] = 0
	Hit.AK47[i] = tonumber(Hit.AK47[i])
	Hit.AK47[i] = 0
	Hit.Rifle[i] = tonumber(Hit.Rifle[i])
	Hit.Rifle[i] = 0
	Hit.Silenced[i] = tonumber(Hit.Silenced[i])
	Hit.Silenced[i] = 0
	Hit.Pistol9mm[i] = tonumber(Hit.Pistol9mm[i])
	Hit.Pistol9mm[i] = 0
	pTemp.delay.speedhack[i] = 0
	pTemp.delay.textures[i] = 0
	warnings.teleport.old_pos.x[i] = -1
	warnings.teleport.old_pos.y[i] = -1
	warnings.teleport.old_pos.z[i] = -1
	pTemp.delay.air[i] = os.time()
	pTemp.adminQuit[i] = false
end

local iVar = { -- imgui переменные
	ath = {
		duty = imgui.ImBool(false),
		dutySkin = imgui.ImBuffer (256),
		aint = imgui.ImBool(false),
		togphone = imgui.ImBool(false),
		fon = imgui.ImBool(false),
		smson = imgui.ImBool(false),
		password = imgui.ImBuffer(256),
		password_b = imgui.ImBool(false),
		a_password = imgui.ImBuffer(256),
		a_password_b = imgui.ImBool(false),
		a_spawn = imgui.ImBool(false),
		type_spawn = imgui.ImInt (0),
		dm_loc = imgui.ImBuffer (256),
		dm_skin = imgui.ImBuffer(256),
		gw_gang = imgui.ImInt (0),
	},
	main_settings = {
		hideip = imgui.ImBool(false),
		hidea = imgui.ImBool(false),
		answerAuto = imgui.ImBool(false),
		answerText = imgui.ImBuffer(256),
		convert = imgui.ImBool(false),
		fpsunlock = imgui.ImBool(false),
		chatlog = imgui.ImBool(false),
		a_forms = imgui.ImBool(false),
		autoScreen = imgui.ImBool(false),
		adminList = imgui.ImBool(false),
		adminListSort = imgui.ImInt (1),
		playerChecker = imgui.ImBool(false),
		fontSizeAdmList = imgui.ImInt (3),
		newLip = imgui.ImBool(false),
		ipHash = imgui.ImBool(false),
		fastMap = imgui.ImBool(false),
		p_cheat = imgui.ImBool(true),
		s_notf = imgui.ImBool(false),
		s_notf_id = imgui.ImInt(1),
		nget = imgui.ImBool(false),
		afk = imgui.ImBool(true),
	},
	recon = {
		leftPanel = imgui.ImBool(false),
		leftPanelStyle = imgui.ImInt (1),
		rightPanel = imgui.ImBool(false),
		keysPanel = imgui.ImBool(false),
	},
	widget = {
		activated = imgui.ImBool(false),
		sizeWidget = imgui.ImFloat(1.0),
		kills = imgui.ImBool(true),
		time_s = imgui.ImBool(true),
		pm_all = imgui.ImBool(true),
		pun_all = imgui.ImBool(true),
		pm_day = imgui.ImBool(true),
		pun_day = imgui.ImBool(true),
		datetime = imgui.ImBool(true),
		in_s = imgui.ImBool(true),
		chat = imgui.ImBool(true),
		server_status = imgui.ImBool(true),
	},
	chat = {
		input_chat = imgui.ImBuffer(1024),
	},
	checker = {
		change_players = {},
		change_desc = {},
		change_full = {}
	},
	cheat = {
		invisible_onfoot = imgui.ImBool(false),
		wallhack = imgui.ImBool(false),
		type_wh = imgui.ImInt (0),
		air_activate = imgui.ImBool(true),
		air_speed = imgui.ImInt (1),
		clickwarp = imgui.ImBool(false)
	},
	tracers = {
		BulletTrackActivate = imgui.ImBool(false),
		BulletTrackOnlyPlayer = imgui.ImBool(false),
		BulletTrackPolyginActivate = imgui.ImBool(false),
		BulletTrackClistColorActivate = imgui.ImBool(false),
		BulletTrackTime = imgui.ImInt(2),
		BulletTrackMaxLines = imgui.ImInt(50),
		BulletTrackMaxWeight = imgui.ImInt(2),
		BulletTrackSizePolygon = imgui.ImInt(3),
		BulletTrackCountPolygin = imgui.ImInt(50),
		BulletTrackRotationPolygon = imgui.ImInt(0),
		BulletTrackClistAlpha = imgui.ImInt(255),
	},
	colors = {
		a_recolor = imgui.ImBool(false),
		p_recolor = imgui.ImBool(false),
		r_recolor = imgui.ImBool(false),
		s_recolor = imgui.ImBool(false),
		g_recolor = imgui.ImBool(false),
		m_recolor = imgui.ImBool(false),
		r_recolor = imgui.ImBool(false),
		a_chat = imgui.ImFloat4(0, 0, 0, 0),
		report = imgui.ImFloat4(0, 0, 0, 0),
		pm = imgui.ImFloat4(0, 0, 0, 0),
		sms = imgui.ImFloat4(0, 0, 0, 0),
		msg = imgui.ImFloat4(0, 0, 0, 0),
		gang = imgui.ImFloat4(0, 0, 0, 0),
		admin = imgui.ImFloat4(0, 0, 0, 0),
		admChat = imgui.ImFloat4(0, 0, 0, 0),
		a_p_recolor = imgui.ImBool(false),
		admNick = imgui.ImFloat4(0, 0, 0, 0),
		p_admAct = imgui.ImBool(false),
		p_admActColor = imgui.ImFloat4(0, 0, 0, 0)
	},
	keys = {
		change_key = imgui.ImBuffer(256)
	},
	warnings = {
		textures = imgui.ImBool(true),
		hit = imgui.ImBool(true),
		deagle = imgui.ImInt(5),
		shotgun = imgui.ImInt(8),
		m4 = imgui.ImInt(10),
		mp5 = imgui.ImInt(10),
		ak47 = imgui.ImInt(10),
		rifle = imgui.ImInt(8),
		silenced = imgui.ImInt(7),
		pistol = imgui.ImInt(7),
		speedhack = imgui.ImBool(true),
		cleoRepair = imgui.ImBool(true),
		speedhack_delay = imgui.ImInt(2)
	},
	cmds = {
		name = {},
		ctype = {},
		time = {},
		text = {},
	},
}

keysDown = {}
for key = 1, 8 do
	keysDown[key] = false
end

local pAct = {
	pType = {},
	pNick = {},
	pSucc = {}
}

local wait_check_time = 0
local wait_punish_time = 0
local r_wait_req_time = 0

local iterator = 1
local iterator1 = 1

local r_iterator = 1
local r_iterator1 = 1
local _type = ""
local __type = ""

local aInfo = inicfg.load ({
	info = {
		lPass = "",
		aPass = "",
		IP = ""
	},
	set = {
		lPass_On = false,
		aPass_On = false,
		aSpawn = false,
		typeSpawn = 1,
		dmLoc = 100,
		dmSkin = 1,
		gwGang = 1,
		waitSpawn = 1,
		chatlog = true
	}
}, "AHelper\\settings.ini")

local BulletSync = {lastId = 0, maxLines = 100}
for i = 1, BulletSync.maxLines do
	BulletSync[i] = {
		enable = false,
		o = {x, y, z},
		t = {x, y, z},
		time = 0,
		timeDelete = 2,
		tType = 0,
		tWeightLine = 2,
		tSizePolygon = 3,
		tCountCorners = 50,
		tRotation = 0,
	}
end

local p_id = {}
local p_player = {}
local p_type = {}
local p_time = {}
local p_reason = {}
local p_admin = {}
local p_num_admin = {}
local punish = false
local nick12

local r_id = {}
local r_player = {}
local r_time = {}
local r_type = {}
local r_reason = {}
local r_admin = {}
local r_num_admin = {}
local __request = false

local infban_array = {}
local infban_ip_array = {}
local infban_kostyl_syka = {}
local infban_type = "nil"
local checkBansIp = 0
local counter_array = 0
local waitInfban = 0
local kostyl = 0
local syka = 1
local syka1 = 1
local asd = 1
local waitLip = 0

local sp_ignor_1 = {
  "LD_Beat:Chit";
  "LD_Beat:Chit";
  "LD_SPAC:white";
  "Stats";
  "Ban";
  "CBan";
  "sLAP";
  "Spawn";
  "Get";
  "EXIt";
  "NEXT";
  "UPDATE";
  "BACK";
  "LD_Beat:Chit";
  "LD_Beat:Chit";
  }

local sp_ignor_2 = {
	"LD_Beat:Chit";
  "LD_Beat:Chit";
  "LD_SPAC:white";
	"LD_Beat:Chit";
  "LD_Beat:Chit";
	"NEXT";
  "UPDATE";
  "BACK";
  "LD_Beat:Chit";
  "LD_Beat:Chit";
}

local _re_panel = {
	"Name:~N~Kills-Deaths:~n~Skill:~N~Location:",
	"Health-Armour:~N~PlayerSpeed:",
	"Weapon-Ammo:~N~WeaponShot:",
	"Ping-Loss:~N~FPS:~N~IP:~N~SAMPCAC:"
}

local admList = {}
local admListAccess = {}
local players = {}
local cmds = {}
local g_admin = {}
local colorNicks = {}
local rlist = {}

local menuPtr = 0x00BA6748

writeMemory(0x555854, 4, -1869574000, true)
writeMemory(0x555858, 1, 144, true)

-- Главная тема /amenu
function theme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(0.12, 0.12, 0.12, 1.00);
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
    colors[clr.Border]                 = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
    colors[clr.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
    colors[clr.TitleBg]                = ImVec4(0.14, 0.14, 0.14, 0.81);
    colors[clr.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[clr.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
    colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.Button]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ButtonHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
    colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
    colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
    colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
end
theme()

function table_style()
	imgui.SwitchContext()
	--imgui.SetWindowFontScale (1.0)
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

	style.WindowPadding       = ImVec2(6, 2)
	style.WindowRounding      = 0
	style.ChildWindowRounding = 3
	style.FramePadding        = ImVec2(7, 4)
	style.ItemSpacing         = ImVec2(3, 8)
	style.ItemInnerSpacing    = ImVec2(8, 6)
	style.IndentSpacing       = 21
	style.ScrollbarSize       = 1
	style.ScrollbarRounding   = 0
	style.GrabMinSize         = 1
	style.GrabRounding        = 0
	style.FrameRounding       = 0
	style.WindowTitleAlign    = ImVec2(0.5, 0.5)
	style.ButtonTextAlign     = ImVec2(0.5, 0.5)


	colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
	colors[clr.WindowBg]             = ImVec4(0.00, 0.00, 0.00, 0.94)
	colors[clr.ChildWindowBg]        = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PopupBg]              = ImVec4(0.00, 0.00, 0.00, 0.94)
	colors[clr.Border]               = ImVec4(0.00, 0.00, 0.00, 0.50)
	colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]              = ImVec4(0.66, 0.24, 0.24, 0.54)
	colors[clr.FrameBgHovered]       = ImVec4(0.00, 0.00, 0.00, 0.40)
	colors[clr.FrameBgActive]        = ImVec4(0.00, 0.00, 0.00, 0.67)
	colors[clr.TitleBg]              = ImVec4(0.00, 0.00, 0.00, 0.67)
	colors[clr.TitleBgActive]        = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.67)
	colors[clr.MenuBarBg]            = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]        = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.ScrollbarGrabActive]  = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.ComboBg]              = ImVec4(0.00, 0.00, 0.00, 0.99)
	colors[clr.CheckMark]            = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.SliderGrab]           = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.SliderGrabActive]     = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.Button]               = ImVec4(0.00, 0.00, 0.00, 0.65)
	colors[clr.ButtonHovered]        = ImVec4(0.00, 0.00, 0.00, 0.65)
	colors[clr.ButtonActive]         = ImVec4(0.00, 0.00, 0.00, 0.50)
	colors[clr.Header]               = ImVec4(0.00, 0.00, 0.00, 0.54)
	colors[clr.HeaderHovered]        = ImVec4(0.00, 0.00, 0.00, 0.65)
	colors[clr.HeaderActive]         = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.Separator]            = ImVec4(0.75, 0.75, 0.86, 0.50)
	colors[clr.SeparatorHovered]     = ImVec4(0.95, 0.88, 0.88, 0.54)
	colors[clr.SeparatorActive]      = ImVec4(0.00, 0.00, 0.00, 0.54)
	colors[clr.ResizeGrip]           = ImVec4(0.00, 0.00, 0.00, 0.54)
	colors[clr.ResizeGripHovered]    = ImVec4(0.00, 0.00, 0.00, 0.66)
	colors[clr.ResizeGripActive]     = ImVec4(0.00, 0.00, 0.00, 0.66)
	colors[clr.CloseButton]          = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.CloseButtonHovered]   = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.CloseButtonActive]    = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.PlotLines]            = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.PlotLinesHovered]     = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.PlotHistogram]        = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.TextSelectedBg]       = ImVec4(0.00, 0.00, 0.00, 0.35)
	colors[clr.ModalWindowDarkening] = ImVec4(0.00, 0.00, 0.00, 0.35)
end

function left_panel_style()
		imgui.SwitchContext()
		local style  = imgui.GetStyle()
		local colors = style.Colors
		local clr    = imgui.Col
		local ImVec4 = imgui.ImVec4
		local ImVec2 = imgui.ImVec2

		style.WindowPadding       = ImVec2(3, 4)
		style.WindowRounding      = 0
		style.ChildWindowRounding = 0
		style.FramePadding        = ImVec2(12, 7)
		style.FrameRounding       = 0
		style.ItemSpacing         = ImVec2(3, 4)
		style.TouchExtraPadding   = ImVec2(5, 0)
		style.IndentSpacing       = 20
		style.ScrollbarSize       = 1
		style.ScrollbarRounding   = 0
		style.GrabMinSize         = 1
		style.GrabRounding        = 0
		style.WindowTitleAlign    = ImVec2(0.5, 0.5)
		style.ButtonTextAlign     = ImVec2(0.5, 0.5)

		colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
		colors[clr.WindowBg]             = ImVec4(0.161, 0.161, 0.161, 0.94)
		colors[clr.ChildWindowBg]        = ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.PopupBg]              = ImVec4(0.00, 0.00, 0.00, 0.94)
		colors[clr.Border]               = ImVec4(0.00, 0.00, 0.00, 0.50)
		colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.FrameBg]              = ImVec4(0.00, 0.00, 0.00, 0.54)
		colors[clr.FrameBgHovered]       = ImVec4(0.00, 0.00, 0.00, 0.40)
		colors[clr.FrameBgActive]        = ImVec4(0.00, 0.00, 0.00, 0.67)
		colors[clr.TitleBg]              = ImVec4(0.00, 0.00, 0.00, 0.67)
		colors[clr.TitleBgActive]        = ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.67)
		colors[clr.MenuBarBg]            = ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
		colors[clr.ScrollbarGrab]        = ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.ScrollbarGrabHovered] = ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
		colors[clr.ComboBg]              = ImVec4(0.00, 0.00, 0.00, 0.99)
		colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.SliderGrab]           = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.SliderGrabActive]     = ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.Button]               = ImVec4(0.00, 0.00, 0.00, 0.650)
		colors[clr.ButtonHovered]        = ImVec4(1.00, 1.00, 1.00, 0.650)
		colors[clr.ButtonActive]         = ImVec4(1.00, 1.00, 1.00, 0.50)
		colors[clr.Header]               = ImVec4(0.00, 0.00, 0.00, 0.54)
		colors[clr.HeaderHovered]        = ImVec4(0.00, 0.00, 0.00, 0.65)
		colors[clr.HeaderActive]         = ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
		colors[clr.SeparatorHovered]     = ImVec4(0.71, 0.39, 0.39, 0.54)
		colors[clr.SeparatorActive]      = ImVec4(0.71, 0.39, 0.39, 0.54)
		colors[clr.ResizeGrip]           = ImVec4(0.71, 0.39, 0.39, 0.54)
		colors[clr.ResizeGripHovered]    = ImVec4(0.84, 0.66, 0.66, 0.66)
		colors[clr.ResizeGripActive]     = ImVec4(0.84, 0.66, 0.66, 0.66)
		colors[clr.CloseButton]          = ImVec4(0.41, 0.41, 0.41, 1.00)
		colors[clr.CloseButtonHovered]   = ImVec4(0.98, 0.39, 0.36, 1.00)
		colors[clr.CloseButtonActive]    = ImVec4(0.98, 0.39, 0.36, 1.00)
		colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
		colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
		colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
		colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
		colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
end

local shot_in_player = imgui.ImFloat4(0, 0, 0, 0);
local shot_in_player_afk = imgui.ImFloat4(0, 0, 0, 0);
local shot_in_vehicle = imgui.ImFloat4(0, 0, 0, 0);
local shot_in_static_obj = imgui.ImFloat4(0, 0, 0, 0);
local shot_in_dynamic_obj = imgui.ImFloat4(0, 0, 0, 0);


local win_state = {}
win_state['main'] = imgui.ImBool(false)
win_state['fast'] = imgui.ImBool (false)
win_state['show_log'] = imgui.ImBool(false)
win_state['show_month_log'] = imgui.ImBool(false)
win_state['checker'] = imgui.ImBool(false)
win_state['cheat'] = imgui.ImBool(false)
win_state['re_panel'] = imgui.ImBool(false)
win_state['right_panel'] = imgui.ImBool(false)
win_state['widget'] = imgui.ImBool(true)
win_state['_requests'] = imgui.ImBool(false)
win_state['update_info'] = imgui.ImBool(false)
win_state['chat'] = imgui.ImBool(false)
win_state['panel'] = imgui.ImBool(true)
win_state['list'] = imgui.ImBool(false)
win_state['table'] = imgui.ImBool(false)

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then
			return
	end
	while not isSampAvailable() do
			wait(0)
	end


	if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\config\\AHelper\\chatlogs") then
		createDirectory(getGameDirectory() .. "\\moonloader\\config\\AHelper\\chatlogs")
	end

	-- Проверка на наличие нужных библиотек
	if not result_imgui then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'imgui'", 0x4682B4)
		print ('Отсутствует библиотека imgui')
	end
	if not result_icons then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'fAwesome5'", 0x4682B4)
		print ('Отсутствует библиотека fAwesome5')
	end
	if not result_encoding then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'encoding'", 0x4682B4)
		print ('Отсутствует библиотека encoding')
	end
	if not result_requests then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'requests'", 0x4682B4)
		print ('Отсутствует библиотека requests')
	end
	if not result_lanes then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'lanes'", 0x4682B4)
		print ('Отсутствует библиотека lanes')
	end
	if not result_vkeys then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'vkeys'", 0x4682B4)
		print ('Отсутствует библиотека vkeys')
	end
	if not result_slnet then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'slnet'", 0x4682B4)
		print ('Отсутствует библиотека slnet')
	end
	if not result_imgui_notf then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует модуль {80EC42}'imgui_notf'", 0x4682B4)
		print ('Отсутствует модуль imgui_notf')
	end
	if not result_sampev then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'samp'", 0x4682B4)
		print ('Отсутствует библиотека samp')
	end
	if not result_hotkeys then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'hotkey'", 0x4682B4)
		print ('Отсутствует библиотека hotkey')
	end
	if not result_rkeys then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'rkeys'", 0x4682B4)
		print ('Отсутствует библиотека rkeys')
	end
	if not result_matrix then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'matrix3x3'", 0x4682B4)
		print ('Отсутствует библиотека matrix3x3')
	end
	if not result_vector then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'vector3d'", 0x4682B4)
		print ('Отсутствует библиотека vector3d')
	end
	if not result_requests or not result_encoding or not result_memory or not result_sampev or not result_icons or not result_lanes or not result_imgui_notf or not result_slnet or not result_vkeys or not result_sampev or not result_hotkeys
	or not result_rkeys or not result_matrix or not result_vector then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует одна или несколько необходимых библиотек", 0x4682B4)
		sampAddChatMessage("[AHelper] {FFFFFF}Скрипт не загружен", 0x4682B4)
		print ('Отсутствует одна или несколько библиотек')
		thisScript():unload()
	end

	encoding = require 'encoding'
	encoding.default = 'CP1251'
	u8 = encoding.UTF8


	memory.fill(sampGetBase()+0x2D3C45, 0, 2, true)

	-- Проверка на название файла, чтобы не запустилось два дубликата скрипта одновременно, может можно как-то по-другому, хз
	if thisScript().filename ~= "AHelper.luac" and thisScript().filename ~= "AHelper3.lua" and thisScript().filename ~= 'AHelper.lua' then
		sampAddChatMessage ("[AHelper] {FFFFFF}Скрипт должен иметь название AHelper.luac", 0x4682B4)
		thisScript():unload()
		return
	end

	-- Загрузка настроек скрипта из JSON файла
	async_http_request("GET", "https://raw.githubusercontent.com/RaffCor/AHelper_New/master/settings.json", nil,
	function (response)
		sInfo = decodeJson(response.text)
	end,
	function (err)

	end)

	-- Проверка на сервер
	async_http_request("GET", "https://raw.githubusercontent.com/RaffCor/AHelper_New/master/servers.json", nil,
	function (response)
		local info = decodeJson(response.text)
		if info.One == sampGetCurrentServerAddress() then
			srv = 1
			gameServer = "One"
			print ("Сервер "..gameServer)
		elseif info.Two == sampGetCurrentServerAddress() then
			srv = 2
			gameServer = "Two"
			print ("Сервер "..gameServer)
		elseif info.Three == sampGetCurrentServerAddress() then
			srv = 3
			gameServer = "Three"
			print ("Сервер "..gameServer)
		elseif info.Test == sampGetCurrentServerAddress() then
			srv = 99
			gameServer = "Test"
			print ("Сервер "..gameServer)
		else
			sampAddChatMessage("[AHelper] {FFFFFF}Скрипт не поддерживается на этом сервере", 0x4682B4)
			thisScript():unload()
		end
	end,
	function (err)

	end)

local td_id = 0

	-- Регистрация команд
	sampRegisterChatCommand ("aut", function()
		if getLocalPlayerName() == "Ken_Higa" or getLocalPlayerName() == "RaffCor" then
			pTemp.user.checkAccount = true
			check_update_menu()
		end
	end)
	sampRegisterChatCommand ("chat", function()
		if pTemp.login then
			win_state['chat'].v = not win_state['chat'].v
		end
	end)
	sampRegisterChatCommand ("amenu", aMenu)
	sampRegisterChatCommand ("checker", checkerPlayer)
	sampRegisterChatCommand ("scmd", sendCMD)
	sampRegisterChatCommand ("notf", notification)
	sampRegisterChatCommand ("fakes", fakeString)
	sampRegisterChatCommand ("togphone", tog_kostyl)
	sampRegisterChatCommand ("test", test)
	sampRegisterChatCommand ("test1", test1)
	sampRegisterChatCommand ("fcheat", fCheat)
	sampRegisterChatCommand ("for", fOr)
	sampRegisterChatCommand ("punish", Cheat)
	sampRegisterChatCommand ("or", OskRod)
	sampRegisterChatCommand ("caps", Capss)
	sampRegisterChatCommand ("osk", OskIgr)
	sampRegisterChatCommand ("nead", Neadekvat)
	sampRegisterChatCommand ("neuv", Neuv)
	sampRegisterChatCommand ("offtop", Offtop)
	sampRegisterChatCommand ("aosk", OskAdm)
	sampRegisterChatCommand ("up", UpRod)
	sampRegisterChatCommand ("nosk", OskNick)
	sampRegisterChatCommand ("captK", CaptK)
	sampRegisterChatCommand ("captO", CaptO)
	sampRegisterChatCommand ("sor", OskRodS)
	sampRegisterChatCommand ("scheat", sCheat)
	sampRegisterChatCommand ("flood", Flood)
	sampRegisterChatCommand ("p", FastAnswer)
	sampRegisterChatCommand ("td", checkTD)
	sampRegisterChatCommand ("ofban", OfBan_log)
	sampRegisterChatCommand ("ofcban", OfcBan_log)
	sampRegisterChatCommand ("ofmute", Ofmute_log)
	sampRegisterChatCommand ("ofjail", Ofjail_log)
	sampRegisterChatCommand ("ofunjail", Ofunjail)
	sampRegisterChatCommand ("upd", UpdInfo)
	sampRegisterChatCommand ("rec", Reconnect)
	sampRegisterChatCommand ("tk", TeamKill)
	sampRegisterChatCommand ("sk", SpawnKill)
	sampRegisterChatCommand ("db", DriveBy)
	sampRegisterChatCommand ("mpmenu", MpMenu)
	sampRegisterChatCommand ("mp_close", Mp_Close)
	sampRegisterChatCommand ("mp_win", Mp_Win)
	sampRegisterChatCommand ("in", invisible_change)
	sampRegisterChatCommand ("bnead", nead_ban)
	sampRegisterChatCommand ("forum", forum)
	sampRegisterChatCommand ("access", access)
	sampRegisterChatCommand ("requests", Requests)
	sampRegisterChatCommand ("ch", check_script)
	sampRegisterChatCommand ("list", r_list)
	sampRegisterChatCommand ("cn", function()
		print (client.status)
	end)

	initializeRender()

	client.connection_timeout = 60
	-- Потоки
	lua_thread.create (check_account)
	lua_thread.create (register_account)
	lua_thread.create (load_account)
	lua_thread.create (WallHack)
	lua_thread.create (send_packet)
	lua_thread.create (updateAdmList)
	lua_thread.create (statUpdate)
	lua_thread.create (remove_panel)
	lua_thread.create (ClickWarpTP)
	lua_thread.create (loadColors)
	lua_thread.create (load_answers)
	--lua_thread.create (load_table_punishments)
	lua_thread.create (load_checker)
	--lua_thread.create (Test_Punish)
	lua_thread.create (load_custom_cmd)
	lua_thread.create (check_requests)
	lua_thread.create (give_pr)
	lua_thread.create (load_adm)
	lua_thread.create (hkeyPressed)
	lua_thread.create (tpMarker)
	lua_thread.create (load_bans)
	lua_thread.create (load_hkeys)
	lua_thread.create (spec_id)
	lua_thread.create (load_cmds)
	lua_thread.create (create_list_checker)
	lua_thread.create (remove_nicks)

	if sampIsLocalPlayerSpawned() then
		pTemp.user.checkAccount = true
		check_update_menu()
	end -- Запуск скрипта при перезагрузке
	-- Цикл main
	while true do
		wait (0)
		client:check_updates()
		-- Курсор и блокировка движения в зависимости от значений переменных
		imgui.ShowCursor = win_state['main'].v or win_state['update_info'].v or win_state['chat'].v or win_state['checker'].v or win_state['cheat'].v or win_state['fast'].v or win_state['_requests'].v or win_state['list'].v
		if pTemp.spec_id == sInfo.MAX_PLAYERS then
			imgui.LockPlayer = win_state['main'].v or win_state['update_info'].v or win_state['chat'].v or win_state['checker'].v or win_state['_requests'].v or win_state['list'].v
		else imgui.LockPlayer = false end

		if pTemp.spec_id ~= sInfo.MAX_PLAYERS then
			if not win_state['main'].v or not win_state['update_info'].v or not win_state['chat'].v or not win_state['checker'].v or not win_state['list'].v then imgui.LockPlayer = false end
		end

		if pTemp.login then



			if win_state['cheat'].v and pTemp.tempCheatID ~= sInfo.MAX_PLAYERS then
				if not sampIsPlayerConnected(pTemp.tempCheatID) and pTemp.tempCheatID ~= sInfo.MAX_PLAYERS then
					sampAddChatMessage(string.format ("[AHelper] {FFFFFF}%s отключился от сервера", pTemp.tempCheatNickName), 0x4682B4)
					pTemp.tempCheatID = sInfo.MAX_PLAYERS
					win_state['cheat'].v = false
				end
			end

			if pInfo.set.afk == true or pInfo.set.afk == '1' then
				if pTemp.start_afk > 0 and pTemp.start_afk + 4 < os.time() and not isGamePaused() then
					pTemp.afk_time = os.time() - pTemp.start_afk
					lua_thread.create (function()
						wait (300)
						sampAddChatMessage('[AHelper] {FFFFFF}Вы были в АФК {FF8C09}'..ConverterNotNull (pTemp.afk_time), 0x4682B4)
						if pTemp.afk_time >= 120 then
							client:connect('176.119.157.232', 445)
							local bitstream = BitStream()
							bitstream:write('unsigned char', 44)
							bitstream:write('string', getLocalPlayerName()..' | '..srv)
							client:send_packet(1, bitstream)
							client:send_packet(5, nil)
						end
					end)
				end
			end

			if not isGamePaused() then pTemp.start_afk = os.time() end


			if pTemp.connection_timeout <= os.time() then
				client:connect('176.119.157.232', 445)
				local bitstream = BitStream()
				bitstream:write('unsigned char', 44)
				bitstream:write('string', getLocalPlayerName()..' | '..srv)
				client:send_packet(1, bitstream)
				client:send_packet(5, nil)
				pTemp.connection_timeout = os.time() + 60 * 30
			end

			local connection_status = client.status
			if connection_status == SLNET_CONNECTED then
				pTemp.slnet_conn = 2
			elseif connection_status == SLNET_CONNECTING then
				pTemp.slnet_conn = 1
			else
				if pTemp.slnet_conn ~= 3 then
					while srv == nil do
						wait (0)
					end
					client:connect('176.119.157.232', 445)
					local bitstream = BitStream()
					bitstream:write('unsigned char', 44)
					bitstream:write('string', getLocalPlayerName()..' | '..srv)
					client:send_packet(1, bitstream)
					local bitstream1 = BitStream()
					bitstream1:write('unsigned char', 44)
					bitstream1:write('string', tostring(srv))
					client:send_packet(5, bitstream1)
					pTemp.slnet_conn = 3
				end
			end


			if (pInfo.set.OnlineAdmins == '1' or pInfo.set.OnlineAdmins == true) and not isPauseMenuActive() then
				local sX, sY = getScreenResolution()
				local y = sY-220
				local x = sX / 3.8
				if pInfo.set.cX ~= '0' then
					x = pInfo.set.cX
					y = pInfo.set.cY
				end
				renderFontDrawText(my_font, 'Администрация онлайн ['..#admList..']:', x, y-30, 0xFFFFFFFF)
				for i, v in ipairs (admList) do
					local aColor = ''
					if v.adminLevel == '6' then aColor = '{2D94F0}'
					elseif v.adminLevel == '1' then aColor = '{CDCDCD}'
					elseif v.adminLevel == '2' then aColor = '{FC7C37}'
					else aColor = '{18B637}' end
					local access = 0
					local result = false
					local s_access = ''
					for j, k in ipairs (admListAccess) do
						if k.nickname == v.adminNick then
							if k.access == '1' then access = 1
							else access = 0 end
							result = true
						else
							--result = false
						end
					end
					if not result then
						s_access = 'Н'
					else
						if access == 0 then s_access = '{FB2B13}Б'
						else s_access = '{0FA223}Д' end
					end
					renderFontDrawText (my_font, string.format ("%s%s[%d] - %d level - {FFFFFF}[%s{FFFFFF}] %s", aColor, v.adminNick, v.adminID, v.adminLevel, s_access, v.adminNext), x, y, 0xFFFFFFFF)
					y = y + 20 - 3 * (3-pInfo.set.font_size)
				end
			end

			if pInfo.set.panel_cheat == '1' or pInfo.set.panel_cheat == true then
				if not isPauseMenuActive() then
					local scX, scY = getScreenResolution()
					if pInfo.set.panel_cheat == true or pInfo.set.panel_cheat == '1' then
						local aim_x = 157
						local air_x = 100
						local aim_y = scY - 50
						local air_y = scY - 25
						if pInfo.set.pcx ~= 0 or pInfo.set.pcy ~= 0 then
							aim_x = pInfo.set.pcx + 57
							air_x = pInfo.set.pcx
							aim_y = pInfo.set.pcy
							air_y = pInfo.set.pcy + 25

						end
						renderFontDrawText (font_panel, 'AIM: ', aim_x, aim_y, 0xFFFFFFFF)
						aim_x = aim_x + 53
						for i, v in ipairs (Panel.aim) do
							renderFontDrawText (font_panel, tostring(v.id), aim_x, aim_y, 0xFFF06B1B)
							aim_x = aim_x + 40
						end
						renderFontDrawText (font_panel, 'TP/FLY/AIR: ', air_x, air_y, 0xFFFFFFFF)
						air_x = air_x + 110
						for i, v in ipairs (Panel.air) do
							renderFontDrawText (font_panel, tostring(v.id), air_x, air_y, 0xFFD9E5F7)
							air_x = air_x + 40
						end
					end
				end
			end


			if pTemp.objectSetPos > 0 then
				sampSetCursorMode(2)
				if isKeyDown (1) then
					local x, y = getCursorPos()
					if pTemp.objectSetPos == 1 then
						pInfo.set.cX = x
						pInfo.set.cY = y
					elseif pTemp.objectSetPos == 2 then
						pInfo.set.pX = x
						pInfo.set.pY = y
					elseif pTemp.objectSetPos == 3 then
						pInfo.set.lpX = x
						pInfo.set.lpY = y
					elseif pTemp.objectSetPos == 4 then
						pInfo.set.rpX = x
						pInfo.set.rpY = y
					elseif pTemp.objectSetPos == 5 then
						pInfo.set.kX = x
						pInfo.set.kY = y
					elseif pTemp.objectSetPos == 6 then
						pInfo.set.clX = x
						pInfo.set.clY = y
					elseif pTemp.objectSetPos == 7 then
						pInfo.set.pcx = x
						pInfo.set.pcy = y
					end
				end
			end

			if getCharArmour(PLAYER_PED) < 1000 and (pInfo.set.invisible_onfoot == true or pInfo.set.invisible_onfoot == '1') then pTemp.antiCheat = true end
			if pTemp.antiCheat == true and getCharArmour(PLAYER_PED) == 1000 then pTemp.antiCheat = false end

			if pInfo.info.adminLevel >= 6 and checkBansIp == os.time() and checkBansIp ~= 0 then
				checkBansIp = 0
				counter_array = 1
				waitInfban = os.time() + 5
				for j in ipairs (infban_array) do
					sampSendChat(string.format ("/infban %s", infban_array[j]))
				end

			end






			if pTemp.spectate == true then
				win_state['re_panel'].v = pTemp.spectate
				win_state['right_panel'].v = pTemp.spectate
			else
				if pTemp.objectSetPos == 3 then
					win_state['re_panel'].v = true
					win_state['right_panel'].v = false
				elseif pTemp.objectSetPos == 4 then
					win_state['re_panel'].v = false
					win_state['right_panel'].v = true
				else
					win_state['re_panel'].v = false
					win_state['right_panel'].v = false
				end
			end

			local oTime = os.time()
			if not isPauseMenuActive() and pInfo.set.bsync.enable == true then
				for i = 1, BulletSync.maxLines do
					if BulletSync[i].enable == true and BulletSync[i].time >= oTime then
						local sx, sy, sz = calcScreenCoors(BulletSync[i].o.x, BulletSync[i].o.y, BulletSync[i].o.z)
						local fx, fy, fz = calcScreenCoors(BulletSync[i].t.x, BulletSync[i].t.y, BulletSync[i].t.z)
						if sz > 1 and fz > 1 then
							local color_line = pInfo.set.bsync.colorStaticObj
							if BulletSync[i].tType == 1 then color_line = pInfo.set.bsync.colorPlayer
								elseif BulletSync[i].tType == 2 then color_line = pInfo.set.bsync.colorCar
								elseif BulletSync[i].tType == 3 then color_line = pInfo.set.bsync.colorPlayerAFK
								elseif BulletSync[i].tType == 4 then color_line = pInfo.set.bsync.colorDynamicObj
							end
							renderDrawLine(sx, sy, fx, fy, BulletSync[i].tWeightLine, color_line)
							if pInfo.set.bsync.polygon_enable == true then renderDrawPolygon(fx, fy-1, BulletSync[i].tSizePolygon, 3, BulletSync[i].tCountCorners, BulletSync[i].tRotation, color_line) end
						end
					end
				end
			end

			--[[if isKeyDown(VK_LMENU) and isKeyJustPressed(VK_1) then

			end

			if isKeyDown(VK_LMENU) and isKeyJustPressed(VK_2) then

			end]]--



			if not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() and not isSampfuncsConsoleActive() then
				if tonumber(pTemp.spec_id) ~= sInfo.MAX_PLAYERS then
					if isKeyJustPressed(VK_I) and pInfo.info.adminLevel >= 6 then
						for td =  10, 1000 do
							if string.find (sampTextdrawGetString(td), "IP:_") then td_id = td end
						end
						if td_id ~= 0 then
							local player_ip = string.match (sampTextdrawGetString(td_id), "IP:_(.-)%~")
							sampSendChat("/lip "..player_ip)
						end
					end
					--if isKeyJustPressed(VK_X) and not sh_x then sampProcessChatInput(string.format ("/punish %d", pTemp.spec_id)) end
				end
			end

			sh_x = false

			if getCharArmour(PLAYER_PED) == 1000 and (pInfo.set.AutoWH == true or pInfo.set.AutoWH == '1') and pTemp.WH_Status == false then
				nameTagOn()
				pTemp.WH_Status = true
			end

			if getCharArmour(PLAYER_PED) ~= 1000 and (pInfo.set.AutoWH == true or pInfo.set.AutoWH == '1') and pTemp.WH_Status == true and tonumber (pTemp.spec_id) == sInfo.MAX_PLAYERS then
				nameTagOff()
				pTemp.WH_Status = false
			end

			if sampIsChatInputActive() == false and sampIsDialogActive() == false then
				if isKeyJustPressed(VK_RSHIFT) then
					if (pInfo.set.air_activate == true or pInfo.set.air_activate == '1') and getCharArmour(PLAYER_PED) == 1000 then
						pTemp.AirBrake = not pTemp.AirBrake
						if pTemp.AirBrake then
							local posX, posY, posZ = getCharCoordinates(playerPed)
							airBrkCoords = {posX, posY, posZ, 0.0, 0.0, getCharHeading(playerPed)}
							oldZCoords = 0
							printStyledString("~n~~n~~n~~n~~n~~n~~w~AirBrake ~g~activated", 500, 4)
						else
							printStyledString("~n~~n~~n~~n~~n~~n~~w~AirBrake ~r~deactivated", 500, 4)
						end
					end
				end
			end

			if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and pTemp.spec_id < sInfo.MAX_PLAYERS then
				if isKeyJustPressed (VK_Y) then sampSendChat ("/y") end
			end

			local time = os.clock() * 1000
			if pTemp.AirBrake and (pInfo.set.air_activate == true or pInfo.set.air_activate == '1') and getCharArmour(PLAYER_PED) == 1000 then
				if isCharInAnyCar(playerPed) then heading = getCarHeading(storeCarCharIsInNoSave(playerPed))
				else heading = getCharHeading(playerPed) end
				local camCoordX, camCoordY, camCoordZ = getActiveCameraCoordinates()
				local targetCamX, targetCamY, targetCamZ = getActiveCameraPointAt()
				local angle = getHeadingFromVector2d(targetCamX - camCoordX, targetCamY - camCoordY)
				if not isCharInAnyCar(playerPed) then setCharHeading(playerPed, angle)
				else setCarHeading(storeCarCharIsInNoSave(playerPed), angle) end
				if srv == 5 and isCharInAnyCar(playerPed) then pInfo.set.AirBrakeSpeed = 0.05 end
				if isCharInAnyCar(playerPed) then difference = 0.79 else difference = 1.0 end
				setCharCoordinates(playerPed, airBrkCoords[1], airBrkCoords[2], airBrkCoords[3] - difference)
				if sampIsChatInputActive() == false and sampIsDialogActive() == false then
					if isKeyDown(VK_W) then
						airBrkCoords[1] = airBrkCoords[1] + pInfo.set.AirBrakeSpeed * math.sin(-math.rad(angle))
						airBrkCoords[2] = airBrkCoords[2] + pInfo.set.AirBrakeSpeed * math.cos(-math.rad(angle))
						if not isCharInAnyCar(playerPed) then setCharHeading(playerPed, angle)
						else setCarHeading(storeCarCharIsInNoSave(playerPed), angle) end
					elseif isKeyDown(VK_S) then
						airBrkCoords[1] = airBrkCoords[1] - pInfo.set.AirBrakeSpeed * math.sin(-math.rad(heading))
						airBrkCoords[2] = airBrkCoords[2] - pInfo.set.AirBrakeSpeed * math.cos(-math.rad(heading))
					end
					if isKeyDown(VK_A) then
						airBrkCoords[1] = airBrkCoords[1] - pInfo.set.AirBrakeSpeed * math.sin(-math.rad(heading - 90))
						airBrkCoords[2] = airBrkCoords[2] - pInfo.set.AirBrakeSpeed * math.cos(-math.rad(heading - 90))
					elseif isKeyDown(VK_D) then
						airBrkCoords[1] = airBrkCoords[1] - pInfo.set.AirBrakeSpeed * math.sin(-math.rad(heading + 90))
						airBrkCoords[2] = airBrkCoords[2] - pInfo.set.AirBrakeSpeed * math.cos(-math.rad(heading + 90))
					end
					if isKeyDown(VK_Q) then airBrkCoords[3] = airBrkCoords[3] + pInfo.set.AirBrakeSpeed / 2.0 end
					if isKeyDown(VK_E) and airBrkCoords[3] > -95.0 then airBrkCoords[3] = airBrkCoords[3] - pInfo.set.AirBrakeSpeed / 2.0 end
					if isKeyJustPressed(VK_DOWN) then
						oldZCoords = airBrkCoords[3]
						airBrkCoords[3] = getGroundZFor3dCoord (airBrkCoords[1], airBrkCoords[2], 999) + 1
					end
					if isKeyJustPressed(VK_UP) and oldZCoords ~= 0 then
						airBrkCoords[3] = oldZCoords
					end
				end
			end

			local kgX, kgY = getScreenResolution()
			local kg_x = kgX / 1.6
			local kg_y = kgY - 800
			if pInfo.set.kX ~= '0'  then
				kg_x = pInfo.set.kX
				kg_y = pInfo.set.kY
			end

			if not isPauseMenuActive() then
				if tonumber (pTemp.spec_id) ~= sInfo.MAX_PLAYERS or pTemp.objectSetPos == 5 then
					if pInfo.set.keys_panel == true or pInfo.set.keys_panel == '1' or pTemp.objectSetPos == 5 then
						if keysDown[1] == false then renderFontDrawText (font_keys, "ЛКМ", kg_x, kg_y, 0xFFCB2A2A) else renderFontDrawText (font_keys, "ЛКМ", kg_x, kg_y, 0xFF32B509) end
						if keysDown[2] == false then renderFontDrawText (font_keys, "ПКМ", kg_x, kg_y+20, 0xFFCB2A2A) else renderFontDrawText (font_keys, "ПКМ", kg_x, kg_y+20, 0xFF32B509) end
						if keysDown[3] == false then renderFontDrawText (font_keys, "C", kg_x, kg_y+40, 0xFFCB2A2A) else renderFontDrawText (font_keys, "C", kg_x, kg_y+40, 0xFF32B509) end
						if keysDown[4] == false then renderFontDrawText (font_keys, "SPRINT", kg_x, kg_y+60, 0xFFCB2A2A) else renderFontDrawText (font_keys, "SPRINT", kg_x, kg_y+60, 0xFF32B509) end
						if keysDown[5] == false then renderFontDrawText (font_keys, "JUMP", kg_x, kg_y+80, 0xFFCB2A2A) else renderFontDrawText (font_keys, "JUMP", kg_x, kg_y+80, 0xFF32B509) end
						if keysDown[6] == false then renderFontDrawText (font_keys, "ALT", kg_x, kg_y+100, 0xFFCB2A2A) else renderFontDrawText (font_keys, "ALT", kg_x, kg_y+100, 0xFF32B509) end
						if keysDown[7] == false then renderFontDrawText (font_keys, "TAB", kg_x, kg_y+120, 0xFFCB2A2A) else renderFontDrawText (font_keys, "TAB", kg_x, kg_y+120, 0xFF32B509) end
						if keysDown[8] == false then renderFontDrawText (font_keys, "F", kg_x, kg_y+140, 0xFFCB2A2A) else renderFontDrawText (font_keys,  "F", kg_x, kg_y+140, 0xFF32B509) end
					end
				end
			end
		end

	end
end


local waitFuckingCursor = 0

function tpMarker()
	while true do
		wait (0)
		local result, posx, posy, posz = getTargetBlipCoordinates()

		if result and markX ~= posx and markY ~= posy and not isPauseMenuActive() then
			setCharCoordinates(playerPed, posx, posy, posz)
			--wait (0)
			local z1 = getGroundZFor3dCoord(posx, posy, 999)
			setCharCoordinates(playerPed, posx, posy, z1)
			markX = posx
			markY = posy
			pTemp.tp_marker_fix = false
		end
	end
end

function ClickWarpTP()
	while true do
		--if pInfo.set.clickwarp == true or pInfo.set.clickwarp == '1' then
			if not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() and not win_state['main'].v and not win_state['show_log'].v and not win_state['show_month_log'].v and not win_state['checker'].v and not win_state['re_panel'].v and not win_state['right_panel'].v
			and not win_state['cheat'].v and not win_state['fast'].v and not win_state['_requests'].v and getCharArmour(PLAYER_PED) == 1000  and waitFuckingCursor < os.time() then
				while isPauseMenuActive() do
		      	if cursorEnabled then
		        	showCursorCW(false)
		      	end
		      	wait(100)
		    end
				if pInfo.set.clickwarp == true or pInfo.set.clickwarp == '1' then

					if isKeyDown(keyToggle) then
			      cursorEnabled = not cursorEnabled
			      showCursorCW(cursorEnabled)
			      while isKeyDown(keyToggle) do wait(80) end
			    end



			    if cursorEnabled then
			      local mode = sampGetCursorMode()
			      if mode == 0 then
			        showCursorCW(true)
			      end
			      local sx, sy = getCursorPos()
			      local sw, sh = getScreenResolution()
			      -- is cursor in game window bounds?
			      if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
			        local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
			        local camX, camY, camZ = getActiveCameraCoordinates()
			        -- search for the collision point
			        local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
			        if result and colpoint.entity ~= 0 then
			          local normal = colpoint.normal
			          local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
			          local zOffset = 300
			          if normal[3] >= 0.5 then zOffset = 1 end
			          -- search for the ground position vertically down
			          local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3,
			            true, true, false, true, false, false, false)
			          if result then
			            pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)

			            local curX, curY, curZ  = getCharCoordinates(playerPed)
			            local dist              = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
			            local hoffs             = renderGetFontDrawHeight(font)

			            sy = sy - 2
			            sx = sx - 2
			            renderFontDrawText(font, string.format("%0.2fm", dist), sx, sy - hoffs, 0xEEEEEEEE)

			            local tpIntoCar = nil
			            if colpoint.entityType == 2 then
			              local car = getVehiclePointerHandle(colpoint.entity)
			              if doesVehicleExist(car) and (not isCharInAnyCar(playerPed) or storeCarCharIsInNoSave(playerPed) ~= car) then
			                displayVehicleName(sx, sy - hoffs * 2, getNameOfVehicleModel(getCarModel(car)))
			                local color = 0xAAFFFFFF
			                if isKeyDown(VK_RBUTTON) then
			                  tpIntoCar = car
			                  color = 0xFFFFFFFF
			                end
			                renderFontDrawText(font2, "Hold right mouse button to teleport into the car", sx, sy - hoffs * 3, color)
			              end
			            end

			            createPointMarker(pos.x, pos.y, pos.z)

			            -- teleport!
			            if isKeyDown(keyApply) then
			              if tpIntoCar then
			                if not jumpIntoCar(tpIntoCar) then
			                  -- teleport to the car if there is no free seats
			                  teleportPlayer(pos.x, pos.y, pos.z)
			                end
			              else
			                if isCharInAnyCar(playerPed) then
			                  local norm = Vector3D(colpoint.normal[1], colpoint.normal[2], 0)
			                  local norm2 = Vector3D(colpoint2.normal[1], colpoint2.normal[2], colpoint2.normal[3])
			                  rotateCarAroundUpAxis(storeCarCharIsInNoSave(playerPed), norm2)
			                  pos = pos - norm * 1.8
			                  pos.z = pos.z - 0.8
			                end
			                teleportPlayer(pos.x, pos.y, pos.z)
			              end
			              removePointMarker()

			              while isKeyDown(keyApply) do wait(0) end
			              showCursorCW(false)
			            end
			          end
			        end
			      end
			    end
				end
			end
	    wait(0)
	    removePointMarker()
		--end
	end
end

function initializeRender()
	font = renderCreateFont("Tahoma", 10, FCR_BOLD + FCR_BORDER)
  font2 = renderCreateFont("Arial", 8, FCR_ITALICS + FCR_BORDER)
end

function ClockFont()
	font_clock = renderCreateFont("Tahoma", 16, FCR_BOLD + FCR_BORDER)
end

--- Functions
function rotateCarAroundUpAxis(car, vec)
  local mat = Matrix3X3(getVehicleRotationMatrix(car))
  local rotAxis = Vector3D(mat.up:get())
  vec:normalize()
  rotAxis:normalize()
  local theta = math.acos(rotAxis:dotProduct(vec))
  if theta ~= 0 then
    rotAxis:crossProduct(vec)
    rotAxis:normalize()
    rotAxis:zeroNearZero()
    mat = mat:rotate(rotAxis, -theta)
  end
  setVehicleRotationMatrix(car, mat:get())
end

function readFloatArray(ptr, idx)
  return representIntAsFloat(readMemory(ptr + idx * 4, 4, false))
end

function writeFloatArray(ptr, idx, value)
  writeMemory(ptr + idx * 4, 4, representFloatAsInt(value), false)
end

function getVehicleRotationMatrix(car)
  local entityPtr = getCarPointer(car)
  if entityPtr ~= 0 then
    local mat = readMemory(entityPtr + 0x14, 4, false)
    if mat ~= 0 then
      local rx, ry, rz, fx, fy, fz, ux, uy, uz
      rx = readFloatArray(mat, 0)
      ry = readFloatArray(mat, 1)
      rz = readFloatArray(mat, 2)

      fx = readFloatArray(mat, 4)
      fy = readFloatArray(mat, 5)
      fz = readFloatArray(mat, 6)

      ux = readFloatArray(mat, 8)
      uy = readFloatArray(mat, 9)
      uz = readFloatArray(mat, 10)
      return rx, ry, rz, fx, fy, fz, ux, uy, uz
    end
  end
end

function setVehicleRotationMatrix(car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
  local entityPtr = getCarPointer(car)
  if entityPtr ~= 0 then
    local mat = readMemory(entityPtr + 0x14, 4, false)
    if mat ~= 0 then
      writeFloatArray(mat, 0, rx)
      writeFloatArray(mat, 1, ry)
      writeFloatArray(mat, 2, rz)

      writeFloatArray(mat, 4, fx)
      writeFloatArray(mat, 5, fy)
      writeFloatArray(mat, 6, fz)

      writeFloatArray(mat, 8, ux)
      writeFloatArray(mat, 9, uy)
      writeFloatArray(mat, 10, uz)
    end
  end
end

function displayVehicleName(x, y, gxt)
  x, y = convertWindowScreenCoordsToGameScreenCoords(x, y)
  useRenderCommands(true)
  setTextWrapx(640.0)
  setTextProportional(true)
  setTextJustify(false)
  setTextScale(0.33, 0.8)
  setTextDropshadow(0, 0, 0, 0, 0)
  setTextColour(255, 255, 255, 230)
  setTextEdge(1, 0, 0, 0, 100)
  setTextFont(1)
  displayText(x, y, gxt)
end

function createPointMarker(x, y, z)
  pointMarker = createUser3dMarker(x, y, z + 0.3, 4)
end

function removePointMarker()
  if pointMarker then
    removeUser3dMarker(pointMarker)
    pointMarker = nil
  end
end

function showCursorCW(toggle)
	if toggle then
		sampSetCursorMode(CMODE_LOCKCAM)
	else
		sampToggleCursor(false)
	end

	cursorEnabled = toggle
end

function getCarFreeSeat(car)
  if doesCharExist(getDriverOfCar(car)) then
    local maxPassengers = getMaximumNumberOfPassengers(car)
    for i = 0, maxPassengers do
      if isCarPassengerSeatFree(car, i) then
        return i + 1
      end
    end
    return nil -- no free seats
  else
    return 0 -- driver seat
  end
end

function jumpIntoCar(car)
  local seat = getCarFreeSeat(car)
  if not seat then return false end                         -- no free seats
  if seat == 0 then warpCharIntoCar(playerPed, car)         -- driver seat
  else warpCharIntoCarAsPassenger(playerPed, car, seat - 1) -- passenger seat
  end
  restoreCameraJumpcut()
  return true
end

function teleportPlayer(x, y, z)
  if isCharInAnyCar(playerPed) then
    setCharCoordinates(playerPed, x, y, z)
  end
  setCharCoordinatesDontResetAnim(playerPed, x, y, z)
end

function setCharCoordinatesDontResetAnim(char, x, y, z)
  if doesCharExist(char) then
    local ptr = getCharPointer(char)
    setEntityCoordinates(ptr, x, y, z)
  end
end

function setEntityCoordinates(entityPtr, x, y, z)
  if entityPtr ~= 0 then
    local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
    if matrixPtr ~= 0 then
      local posPtr = matrixPtr + 0x30
      writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
      writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
      writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
    end
  end
end

function calcScreenCoors(fX,fY,fZ)
	local dwM = 0xB6FA2C

	local m_11 = memory.getfloat(dwM + 0*4)
	local m_12 = memory.getfloat(dwM + 1*4)
	local m_13 = memory.getfloat(dwM + 2*4)
	local m_21 = memory.getfloat(dwM + 4*4)
	local m_22 = memory.getfloat(dwM + 5*4)
	local m_23 = memory.getfloat(dwM + 6*4)
	local m_31 = memory.getfloat(dwM + 8*4)
	local m_32 = memory.getfloat(dwM + 9*4)
	local m_33 = memory.getfloat(dwM + 10*4)
	local m_41 = memory.getfloat(dwM + 12*4)
	local m_42 = memory.getfloat(dwM + 13*4)
	local m_43 = memory.getfloat(dwM + 14*4)

	local dwLenX = memory.read(0xC17044, 4)
	local dwLenY = memory.read(0xC17048, 4)

	frX = fZ * m_31 + fY * m_21 + fX * m_11 + m_41
	frY = fZ * m_32 + fY * m_22 + fX * m_12 + m_42
	frZ = fZ * m_33 + fY * m_23 + fX * m_13 + m_43

	fRecip = 1.0/frZ
	frX = frX * (fRecip * dwLenX)
	frY = frY * (fRecip * dwLenY)

    if(frX<=dwLenX and frY<=dwLenY and frZ>1)then
        return frX, frY, frZ
	else
		return -1, -1, -1
	end
end

function updateAdmList()
	while true do
		wait (0)
		if pTemp.login then
			wait (5000)
			if not sampIsDialogActive() then
				pTemp.admUpdate = true
				sampSendChat ('/admins')
			end
		end
	end
end

function remove_panel()
	while true do
		wait (0)
		if pTemp.login then
			for i, v in ipairs (Panel.aim) do
				local result = false
				for j = 0, sampGetMaxPlayerId (false) do
					if sampIsPlayerConnected (j) then
						if j == tonumber(v.id) and getPlayerName (j) == v.nick then result = true end
					end
				end
				if not result then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 144)
					bitstream:write('string', 'aim | '..srv..' | '..v.nick..' | '..v.id)
					client:send_packet(11, bitstream)
					table.remove (Panel.aim, i)

				end
			end

			for i, v in ipairs (Panel.air) do
				local result = false
				for j = 0, sampGetMaxPlayerId (false) do
					if sampIsPlayerConnected (j) then
						if j == tonumber(v.id) and getPlayerName (j) == v.nick then result = true end
					end
				end
				if not result then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 144)
					bitstream:write('string', 'air | '..srv..' | '..v.nick..' | '..v.id)
					client:send_packet(11, bitstream)
					table.remove (Panel.air, i)

				end
			end
			wait (5000)
		end
	end
end


function statUpdate()
	while true do
		wait (0)
		if pTemp.login then
			getStat()
			getAdmStat()
			pTemp.user.check_access = true
			sampSendChat ("/ia")


			wait (60000)
		end
	end
end

function load_adm()
	while true do
		wait (0)
		if pTemp.user.loadAdm == true then
			pTemp.user.loadAdm = false
			local load_admins = {}
			load_admins.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_admins.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url..'/load_admins.php', load_admins,
			function (response)
				local i = 1
				for j in pairs(g_admin) do table.remove(g_admin, j) end
				for nick in u8:decode(response.text):gmatch("(.-)\n") do
					g_admin[i] = nick
					i = i + 1
				end
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nСписок старшей администрации загружен', 7)
			end,
			function (err)

			end)
		end
	end
end

function checkerPlayer()
	for i, k in ipairs (players) do
		iVar.checker.change_players[i] = imgui.ImBuffer(256)
		iVar.checker.change_desc[i] = imgui.ImBuffer(256)
		iVar.checker.change_full[i] = imgui.ImBool(true)
		iVar.checker.change_players[i].v = u8(string.format ("%s", k.nick))
		iVar.checker.change_desc[i].v = u8(k.desc)
		if k.full == '1' then iVar.checker.change_full[i].v = true else iVar.checker.change_full[i].v = false end
	end
	win_state['checker'].v = not win_state['checker'].v
end


function load_checker()
	while true do
		wait (0)
		if pTemp.user.loadChecker == true then
			pTemp.user.loadChecker = false
			local load_players = {}
			load_players.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_players.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			--response = requests.post ("http://martin-rojo.myjino.ru/check_players.php", load_players)
			async_http_request("POST", sInfo.url..'/check_players.php', load_players,
			function (response)
				for i = #players, 1, -1 do
					table.remove(players, i)
				end
				for id, nick, desc, full in u8:decode(response.text):gmatch("(%d+) | (.-) | (.-) | (%d+)\n") do
					--players[i] = nick
					table.insert (players, {
						id = id,
						nick = nick,
						desc = desc,
						full = full
					})
				end
				for i = #iVar.checker.change_players, 1, -1 do
					table.remove(iVar.checker.change_players, i)
				end
				for i = #iVar.checker.change_desc, 1, -1 do
					table.remove(iVar.checker.change_desc, i)
				end
				for i = #iVar.checker.change_full, 1, -1 do
					table.remove(iVar.checker.change_full, i)
				end
				for i, k in ipairs (players) do
					iVar.checker.change_players[i] = imgui.ImBuffer(256)
					iVar.checker.change_desc[i] = imgui.ImBuffer(256)
					iVar.checker.change_full[i] = imgui.ImBool(true)
					iVar.checker.change_players[i].v = u8(string.format ("%s", k.nick))
					iVar.checker.change_desc[i].v = u8(k.desc)
					if k.full == '1' then iVar.checker.change_full[i].v = true else iVar.checker.change_full[i].v = false end
				end
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nЧекер игроков загружен', 7)
			end,
			function (err)

			end)
		end
	end
end

function spec_id()
	while true do
		wait (200)
		if pTemp.spectate == false then
			pTemp.spec_id = sInfo.MAX_PLAYERS
		end
	end
end

function load_hkeys()
	while true do
		wait (0)
		if pTemp.user.load_hkeys then
			pTemp.user.load_hkeys = false
			local load_hk = {}
			load_hk.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_hk.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url.."/hk_load.php", load_hk,
			function (response)
				if response.text:find ('|') then
					for id, key, action in u8:decode(response.text):gmatch ('(%d+) | (.-) | (.-)\n') do
						table.insert(uhkey, {
							id = id,
							key = key,
							action = action
						})
					end
				else
					print ('Error: '..response.text)
				end
			end,
			function (err)

			end)
		end
	end
end

function load_bans()
	while true do
		wait (0)
		if pTemp.user.load_bans then
			pTemp.user.load_bans = false
			local load_bans = {}
			load_bans.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_bans.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url.."/load_bans.php", load_bans,
			function (response)
				if u8:decode (response.text):find ('|') then
					for i = #bans, 1, -1 do
						table.remove(bans, i)
					end
					for i = #bans_change_type, 1, -1 do
						table.remove(bans_change_type, i)
					end
					for i = #bans_change_time, 1, -1 do
						table.remove(bans_change_time, i)
					end
					for i = #bans_change_reason, 1, -1 do
						table.remove(bans_change_reason, i)
					end
					for id, type, time, reason in u8:decode(response.text):gmatch ('(%d+) | (.-) | (%d+) | (.-)\n') do
						table.insert (bans, {
							id = id,
							type = type,
							time = time,
							reason = reason
						})
					end
					for i = 1, #bans do
						bans_change_reason[i] = imgui.ImBuffer(256)
						bans_change_time[i] = imgui.ImBuffer(256)
						bans_change_type[i] = imgui.ImInt (0)
					end
					for i, k in ipairs (bans) do
						bans_change_type[i].v = k.type
						bans_change_time[i].v = k.time
						bans_change_reason[i].v = u8(k.reason)
					end
					print ('Пользовательские наказания загружены')
				elseif response.text:find ('Rows not found') then
					print ('Пользовательские наказания не найдена')
				else
					print ('Error: '..response.text)
				end
			end,
			function (err)

			end)
		end
	end
end

function load_answers()
	while true do
		wait (0)
		if pTemp.user.load_answers then
			pTemp.user.load_answers = false
			local load_answers = {}
			load_answers.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_answers.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url.."/answer_load.php", load_answers,
			function (response)
				if u8:decode(response.text):find("|") then
					for i = #answers, 1, -1 do
						table.remove(answers, i)
					end
					for i = #change_answers_title, 1, -1 do
						table.remove(change_answers_title, i)
					end
					for i = #change_answers_text, 1, -1 do
						table.remove(change_answers_text, i)
					end
					for id, title, text in u8:decode(response.text):gmatch("(%d+) | (.-) | (.-)\n") do
						table.insert (answers, {
							id = id,
							title = title,
							text = text
						})
					end
					for i = 1, #answers do
						change_answers_title[i] = imgui.ImBuffer(256)
						change_answers_text[i] = imgui.ImBuffer(256)
					end
					for i, k in ipairs (answers) do
						change_answers_title[i].v = u8(k.title)
						change_answers_text[i].v = u8(k.text)
					end

					print ("Быстрые ответы загружены")
				elseif u8:decode(response.text):find("Данных нет") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка при загрузке быстрых ответов (нет данных).", 0x4682B4)
				end
			end,
			function (err)

			end)
		end
	end
end

function remove_nicks()
	while true do
		wait (1000)
		if pInfo.set.OnlinePlayers == '1' or pInfo.set.OnlinePlayers == true then
			for i, v in ipairs (players) do
				for j in ipairs (g_admin) do
					if v.nick == g_admin[j] and getLocalPlayerName() ~= 'Ken_Higa' then v.gla = true end
				end
			end
		end
	end
end

function create_list_checker()
	while true do
		wait (0)
		if (pInfo.set.OnlinePlayers == '1' or pInfo.set.OnlinePlayers == true) and not isPauseMenuActive() then
			local sX, sY = getScreenResolution()
			local y = sY-220
			local x = sX / 1.65

			if pInfo.set.pX ~= '0' then
				x = pInfo.set.pX
				y = pInfo.set.pY
			end
			renderFontDrawText(my_font, 'Игроки онлайн:', x, y-30, 0xFFFFFFFF)
			for i, v in ipairs (players) do
				if v.full == '1' then
					for j = 0, sampGetMaxPlayerId (false) do
						if sampIsPlayerConnected (j) then
							--[[for jj in ipairs (g_admin) do
								if getPlayerName (j):lower() == g_admin[jj]:lower() and getLocalPlayerName() ~= 'Ken_Higa' then g__admin = true end
							end]]--
							if v.nick == getPlayerName (j) and not v.gla then
								if v.desc:len() == 0 then renderFontDrawText (my_font, string.format ("{F4522F}%s [%d]", v.nick, j), x, y, 0xFFFFFFFF)
								else renderFontDrawText (my_font, string.format ("{F4522F}%s [%d] {ADF6AE}(%s)", v.nick, j, v.desc), x, y, 0xFFFFFFFF) end
								y = y + 20
							end
						end
					end
				else
					local count = 1
					if v.desc:len() == 0 then renderFontDrawText (my_font, string.format ("Совпадения с '%s':", v.nick), x, y, 0xFFFFFFFF)
					else renderFontDrawText (my_font, string.format ("Совпадения с '%s' {ADF6AE}(%s):", v.nick, v.desc), x, y, 0xFFFFFFFF) end
					y = y + 20
					for j = 0, sampGetMaxPlayerId (false) do
						if sampIsPlayerConnected (j) then
							if count <= 5 then
								--[[for jj in ipairs (g_admin) do
									if getPlayerName (j):lower() == g_admin[jj]:lower()  and getLocalPlayerName() ~= 'Ken_Higa' then g__admin = true end
								end]]--
								if getPlayerName (j):lower():find (v.nick:lower()) and not v.gla then
									renderFontDrawText (my_font, string.format ("{F4522F}%d. %s [%d]", count, getPlayerName (j), j), x+20, y, 0xFFFFFFFF)
									y = y + 20
									count  = count+1
								end
							end
						end
					end
					if count == 1 then
						 renderFontDrawText (my_font, 'Не найдено', x+20, y, 0xFFFFFFFF)
						 y = y + 20
					 end
				end
			end
		end
	end
end

function checker()
	while true do
		wait (1000)

	end
end

function load_cmds()
	while true do
		wait (0)
		if pTemp.user.load_cmds then
			pTemp.user.load_cmds = false
			local load_cmds = {}
			load_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_cmds.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url.."/ucmd_load.php", load_cmds,
			function (response)
				for i = #cmds, 1, -1 do
					sampUnregisterChatCommand(cmds[i]['name'])
					table.remove(cmds, i)
					table.remove (iVar.cmds.ctype, i)
					table.remove (iVar.cmds.name, i)
					table.remove (iVar.cmds.time, i)
					table.remove (iVar.cmds.text, i)
				end
				if u8:decode(response.text):find("| (%d+) | (.-) | (%d+) | (%d+) | (.-) | (%d+)\n") then
					for id, cmd, ctype, time, reason, standard in u8:decode(response.text):gmatch ("| (%d+) | (.-) | (%d+) | (%d+) | (.-) | (%d+)\n") do
						table.insert (cmds, {
							id = id,
							name = cmd,
							ctype = ctype,
							time = time,
							text = reason,
							standard = standard
						})
						--[[sampRegisterChatCommand(u8:decode(cmd), function (params)
							if ctype == '1' then sampAddChatMessage('/kick '..params..' '..reason, -1)
							elseif ctype == '2' then sampAddChatMessage('/skick '..params..' '..reason, -1) end
						end)]]--
					end
					for i, k in ipairs (cmds) do
						iVar.cmds.ctype[i] = imgui.ImInt (0)
						iVar.cmds.name[i] = imgui.ImBuffer(256)
						iVar.cmds.text[i] = imgui.ImBuffer(256)
						iVar.cmds.time[i] = imgui.ImBuffer(256)
						iVar.cmds.ctype[i].v = k.ctype
						iVar.cmds.name[i].v = k.name
						iVar.cmds.text[i].v = u8(k.text)
						iVar.cmds.time[i].v = k.time
					end

				end
			end,
			function (err)

			end)
		end
	end
end

function load_custom_cmd()
	while true do
		wait (0)
		if pTemp.user.load_custom_cmd then
			pTemp.user.load_custom_cmd = false
			local load_custom_cmds = {}
			load_custom_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			load_custom_cmds.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url.."/cmd_load.php", load_custom_cmds,
			function (response)
				if u8:decode(response.text):find("| (%d+) | (.-)\n") then
					for i = #a_cmd, 1, -1 do
						table.remove(a_cmd, i)
					end
					for i = #change_cmd, 1, -1 do
						table.remove(change_cmd, i)
					end
					for id, cmd in u8:decode(response.text):gmatch("| (%d+) | (.-)\n") do
						table.insert (a_cmd, {
							id = id,
							cmd = cmd,
						})
					end
					for i, k in ipairs (a_cmd) do
						change_cmd[i] = imgui.ImBuffer(256)
						change_cmd[i].v = u8(string.format ("%s", k.cmd))
					end
					print ("Кастомные команды загружены")
					if os.clock() < 90 then
						if not win_state['main'].v then
							for i, v in ipairs (a_cmd) do
								sampProcessChatInput(v.cmd)
							end
						end
					end
				elseif u8:decode(response.text):find("Данных нет") then
					--sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка при загрузке своих команд (нет данных).", 0x4682B4)
					print ("Кастомные команды не найдены")
				end
			end,
			function (err)

			end)
		end
	end
end

function send_packet()
	while true do
		wait (2000)
		local bitstream = BitStream()
		bitstream:write('unsigned char', 24)
		bitstream:write('string', getLocalPlayerName()..' | '..srv)
		client:send_packet(3, bitstream)
	end
end

function hkeyPressed()
	while true do
		wait (0)
		if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
			local res, key = hk.getKeyPressed()
			if res then

				if pTemp.setkey == 0 then
					for i, v in ipairs (uhkey) do
						if v.key == hk.getKeyName(key) then
							while hk.getKeyPressed() and v.action ~= '16' do
								wait (0)
							end
							if v.action == '1' then sampProcessChatInput('/amenu')
							elseif tonumber (v.action) >= 2 and tonumber (v.action) <= 9 then
								if not win_state['main'].v then win_state['main'].v = true end
								pTemp.menu_id = tonumber (v.action) - 1
								if pTemp.menu_id == 6 then
									ctext = 'Загрузка...'
									async_http_request('GET', sInfo.url..'/script_commands.php', nil,
									function (response)
										ctext = u8:decode(response.text)
									end)
								elseif pTemp.menu_id == 7 then
									itext = 'Загрузка...'
									async_http_request('GET', sInfo.url..'/table.php?srv='..srv, nil,
									function (response)
										itext = u8:decode(response.text)
									end)
									pTemp.menu_id = 7
								end
							elseif v.action == '10' then
								if tonumber (pTemp.textures_id) ~= sInfo.MAX_PLAYERS  then
									sampSendChat ("/re "..pTemp.textures_id)
									sh_x = true
								end
							elseif v.action == '11' and not win_state['main'].v then
								if not sh_x and tonumber(pTemp.spec_id) ~= sInfo.MAX_PLAYERS then sampProcessChatInput(string.format ("/punish %d", pTemp.spec_id)) end
							elseif v.action == '12' and not win_state['main'].v then
								if pInfo.set.bindAccess == true then
									if pTemp.fast_punish == 1 and tonumber(pTemp.s_id) ~= tonumber(sInfo.MAX_PLAYERS) then
										if pInfo.info.adminLevel < 3 then  sampProcessChatInput(string.format ("/for %d", tonumber(pTemp.s_id)))
										else sampProcessChatInput(string.format ("/or %d", tonumber(pTemp.s_id))) end
										--pTemp.fast_punish = 0
									end
									if pTemp.fast_punish == 2 and pInfo.info.adminLevel >= 3 then
										sampProcessChatInput(string.format ("/ofban %s 30 оскорбление родных", pTemp.nick_off))
										if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
											lua_thread.create (function()
												wait (500)
												makeScreenshot(disable)
											end)
										end
										--pTemp.fast_punish = 0
									end
								else
									sampAddChatMessage("[AHelper] {FFFFFF}У вас нет доступа к блокировкам", 0x4682B4)
								end
							elseif v.action == '13' and not win_state['main'].v then
								if pTemp.fast_punish == 1 and tonumber(pTemp.s_id) ~= tonumber(sInfo.MAX_PLAYERS) and pInfo.set.bindAccess == true then
									sampSendChat(string.format ("/mute %d 180 упоминание родных.", tonumber(pTemp.s_id)))
									if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
										lua_thread.create (function()
											wait (500)
											makeScreenshot(disable)
										end)
									end
									--pTemp.fast_punish = 0
								end
								if pTemp.fast_punish == 2 and pInfo.info.adminLevel >= 3 and pInfo.set.bindAccess == true then
									sampProcessChatInput(string.format ("/ofmute %s 180 упоминание родных", pTemp.nick_off))
									if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
										lua_thread.create (function()
											wait (500)
											makeScreenshot(disable)
										end)
									end
									--pTemp.fast_punish = 0
								end
							elseif v.action == '16' and not win_state['main'].v then
								if pInfo.set.fastMap == true or pInfo.set.fastMap == '1' then
									writeMemory(menuPtr + 0x33, 1, 1, false) -- activate menu
									-- wait for a next frame
									wait(0)
									writeMemory(menuPtr + 0x15C, 1, 1, false) -- textures loaded
									writeMemory(menuPtr + 0x15D, 1, 5, false) -- current menu
									writeMemory(menuPtr + 0x64, 4, representFloatAsInt(300.0), false)
									while hk.getKeyPressed() do
									  wait(80)
									end
									writeMemory(menuPtr + 0x32, 1, 1, false) -- close menu
								end
							end
						end
					end
				end
				if pTemp.setkey > 0 then
					while hk.getKeyPressed() do
						wait (0)
					end
					local result = false
					for i, v in ipairs (uhkey) do
						if v.key == hk.getKeyName(key) and i ~= pTemp.setkey then
							result = true
							break
						end
					end
					if not result then
						if hk.getKeyName(key) == 'Backspace' then
							uhkey[pTemp.setkey]['key'] = 'Не назначено'
							pTemp.setkey = 0
						else
							uhkey[pTemp.setkey]['key'] = hk.getKeyName(key)
						end
						local hk_upd = {}
						hk_upd.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&key="..u8(uhkey[pTemp.setkey]['key']).."&id="..uhkey[pTemp.setkey]['id'].."&action="..pTemp.setkey
						hk_upd.headers = {
							['content-type']='application/x-www-form-urlencoded'
						}
						hk_upd.data = hk_upd.data:gsub ('+', '%+')
						async_http_request ('POST', sInfo.url.."/hk_upd.php", hk_upd,
						function (response)
							if u8:decode(response.text):find("Данные обновлены") then
								sampAddChatMessage("[AHelper] {FFFFFF}Клавиша изменена", 0x4682B4)
							elseif u8:decode(response.text):find("Запрос не сработал") then
								sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при сохранении", 0x4682B4)
							elseif u8:decode(response.text):find("Не получены данные") then
								sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#103). Работа скрипта остановлена.", 0xFF0000)
								print("RepUpd ErrTrue: "..u8:decode(response.text))
								thisScript():unload()
							end
						end,
						function (err)

						end)
						pTemp.setkey = 0
					else
						sampAddChatMessage('[AHelper] {FFFFFF}Клавиша {FF9A50}'..hk.getKeyName(key)..'{FFFFFF} выполняет другое действие. Для удаления используйте Backspace', 0x4682B4)
					end
				end
			end
		end
	end
end

function sampev.onPlayerDeathNotification(killerId, killedId, reason)
	local kill = ffi.cast('struct stKillInfo*', sampGetKillInfoPtr())
	local _, myid = sampGetPlayerIdByCharHandle(playerPed)

	local n_killer = ( sampIsPlayerConnected(killerId) or killerId == myid ) and sampGetPlayerNickname(killerId) or nil
	local n_killed = ( sampIsPlayerConnected(killedId) or killedId == myid ) and sampGetPlayerNickname(killedId) or nil
	lua_thread.create(function()
		wait(0)
		if n_killer then kill.killEntry[4].szKiller = ffi.new('char[25]', ( n_killer .. '[' .. killerId .. ']' ):sub(1, 24) ) end
		if n_killed then kill.killEntry[4].szVictim = ffi.new('char[25]', ( n_killed .. '[' .. killedId .. ']' ):sub(1, 24) ) end
	end)
end

function getLocalPlayerName()
	_, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
	nickname = sampGetPlayerNickname(myID)
	if string.find(nickname, "^%[GW%]") or string.find(nickname, "^%[DM%]") or string.find(nickname, "^%[TR%]") or string.find(nickname, "^%[LC%]") or string.find(nickname, "^%[PVP%]") or string.find(nickname, "^%[TS%]") or string.find(nickname, "^%[GG%]") then
		prefix = string.match(nickname, "^%[([A-Z]+)%].*")
		nickname = string.gsub(nickname, "^%[[A-Z]+%]", "")
	end
	return nickname
end

function getStat()
	local stats = {}
	stats.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&type=/pm"
	stats.headers = {
		['content-type']='application/x-www-form-urlencoded'
	}
	async_http_request ('POST', sInfo.url..'/check_stat.php', stats,
	function (response)
	--response = requests.post ("http://martin-rojo.myjino.ru/check_stat.php", stats)
		if response.text:find("%d+") then
			pTemp.count = response.text:match ("(%d+)")
			pTemp.count = tonumber (pTemp.count)
		elseif u8:decode(response.text):find("Аккаунт не найден") then
			sampAddChatMessage("[AHelper]{FFFFFF} Аккаунт не найден. Данные не обновлены.", 0x4682B4)
			print ("Аккаунт не найден, репорт не обновлен")
		elseif u8:decode(response.text):find("Не получены данные") then
			sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#2). Работа скрипта остановлена.", 0xFF0000)
			print("RepUpd ErrTrue: "..u8:decode(response.text))
			thisScript():unload()
		end
	end,
	function (err)
		print(err)
		return
	end)
	local stats = {}
	stats.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&type=all"
	stats.headers = {
		['content-type']='application/x-www-form-urlencoded'
	}
	async_http_request ('POST', sInfo.url..'/check_stat.php', stats,
	function (response)
	--response = requests.post ("http://martin-rojo.myjino.ru/check_stat.php", stats)
		if response.text:find("%d+ | %d+") then
			pTemp.count_reports_all, pTemp.count_punish_all = response.text:match ("(%d+) | (%d+)")
		elseif u8:decode(response.text):find("Аккаунт не найден") then
			sampAddChatMessage("[AHelper]{FFFFFF} Аккаунт не найден. Данные не обновлены.", 0x4682B4)
			print ("Аккаунт не найден, репорт не обновлен")
		elseif u8:decode(response.text):find("Не получены данные") then
			sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#2). Работа скрипта остановлена.", 0xFF0000)
			print("RepUpd ErrTrue: "..u8:decode(response.text))
			thisScript():unload()
		end
	end,
	function (err)
		print(err)
		sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка при обновлении данных (#66)", 0x4682B4)
		return
	end)
end

function getAdmStat()
	local get_punish = {}
	get_punish.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&type=punish"
	get_punish.headers = {
		['content-type']='application/x-www-form-urlencoded'
	}
	async_http_request ('POST', sInfo.url..'/check_stat.php', get_punish,
	function (response)
	--response = requests.post ("http://martin-rojo.myjino.ru/check_stat.php", stats)
		if response.text:find("%d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+") then
			pTemp.count_punish, pTemp.count_ban, pTemp.count_cban, pTemp.count_sban,
			pTemp.count_scban, pTemp.count_mute, pTemp.count_kick, pTemp.count_skick,
			pTemp.count_jail, pTemp.count_form_ban, pTemp.count_form_jail,
			pTemp.count_form_ban_y, pTemp.count_form_jail_y = response.text:match ("(%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+)")
			pTemp.count_punish = tonumber (pTemp.count_punish)
			pTemp.count_ban = tonumber (pTemp.count_ban)
		elseif u8:decode(response.text):find("Аккаунт не найден") then
			sampAddChatMessage("[AHelper]{FFFFFF} Аккаунт не найден. Данные не обновлены.", 0x4682B4)
			print ("Аккаунт не найден, репорт не обновлен")
		elseif u8:decode(response.text):find("Не получены данные") then
			sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#2). Работа скрипта остановлена.", 0xFF0000)
			print("RepUpd ErrTrue: "..u8:decode(response.text))
			thisScript():unload()
		end
	end,
	function (err)
		print(err)
		return
	end)
end

function WallHack()
	while true do
		wait (0)
		if pTemp.login == true then
			if (pInfo.set.AutoWH == true or pInfo.set.AutoWH == '1') and (pInfo.set.type_wh == '1' or pInfo.set.type_wh == 1) and (getCharArmour(PLAYER_PED) == 1000 or tonumber (pTemp.spec_id) < sInfo.MAX_PLAYERS) then
				if not isPauseMenuActive() then
					for i = 0, sampGetMaxPlayerId() do
					if sampIsPlayerConnected(i) then
						local result, cped = sampGetCharHandleBySampPlayerId(i)
						local color = sampGetPlayerColor(i)
						local aa, rr, gg, bb = explode_argb(color)
						local color = join_argb(255, rr, gg, bb)
						if result then
							if doesCharExist(cped) and isCharOnScreen(cped) then
								local t = {3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2}
								for v = 1, #t do
									pos1X, pos1Y, pos1Z = getBodyPartCoordinates(t[v], cped)
									pos2X, pos2Y, pos2Z = getBodyPartCoordinates(t[v] + 1, cped)
									pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
									pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
									renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
								end
								for v = 4, 5 do
									pos2X, pos2Y, pos2Z = getBodyPartCoordinates(v * 10 + 1, cped)
									pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
									renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
								end
								local t = {53, 43, 24, 34, 6}
								for v = 1, #t do
									posX, posY, posZ = getBodyPartCoordinates(t[v], cped)
									pos1, pos2 = convert3DCoordsToScreen(posX, posY, posZ)
								end
							end
						end
					end
				end
				else
					nameTagOff()
					while isPauseMenuActive() or isKeyDown(VK_F8) do wait(0) end
					nameTagOn()
				end
			end
		end
	end
end

function getBodyPartCoordinates(id, handle)
  local pedptr = getCharPointer(handle)
  local vec = ffi.new("float[3]")
  getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
  return vec[0], vec[1], vec[2]
end

function nameTagOn()
	local pStSet = sampGetServerSettingsPtr();
	NTdist = memory.getfloat(pStSet + 39)
	NTwalls = memory.getint8(pStSet + 47)
	NTshow = memory.getint8(pStSet + 56)
	memory.setfloat(pStSet + 39, 1488.0)
	memory.setint8(pStSet + 47, 0)
	memory.setint8(pStSet + 56, 1)
	nameTag = true
end

function nameTagOff()
	local pStSet = sampGetServerSettingsPtr();
	memory.setfloat(pStSet + 39, NTdist)
	memory.setint8(pStSet + 47, NTwalls)
	memory.setint8(pStSet + 56, NTshow)
	nameTag = false
end

function join_argb(a, r, g, b)
  local argb = b  -- b
  argb = bit.bor(argb, bit.lshift(g, 8))  -- g
  argb = bit.bor(argb, bit.lshift(r, 16)) -- r
  argb = bit.bor(argb, bit.lshift(a, 24)) -- a
  return argb
end

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end


function getPlayerName(id)
	p_nickname = sampGetPlayerNickname(id)
	if string.find(p_nickname, "^%[GW%]") or string.find(p_nickname, "^%[DM%]") or string.find(p_nickname, "^%[TR%]") or string.find(p_nickname, "^%[LC%]") or string.find(p_nickname, "^%[PVP%]") or string.find(p_nickname, "^%[TS%]") or string.find(p_nickname, "^%[GG%]")  then
		prefix = string.match(p_nickname, "^%[([A-Z]+)%].*")
		p_nickname = string.gsub(p_nickname, "^%[[A-Z]+%]", "")
	end
	return p_nickname
end

function string.split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function isKeysDown(keylist, pressed)
	local tKeys = string.split(keylist, " ")
	if pressed == nil then
		pressed = false
	end
	if tKeys[1] == nil then
		return false
	end
	local bool = false
	local key = #tKeys < 2 and tonumber(tKeys[1]) or tonumber(tKeys[2])
	local modified = tonumber(tKeys[1])
	if #tKeys < 2 then
		if not isKeyDown(VK_RMENU) and not isKeyDown(VK_LMENU) and not isKeyDown(VK_LSHIFT) and not isKeyDown(VK_RSHIFT) and not isKeyDown(VK_LCONTROL) and not isKeyDown(VK_RCONTROL) then
			if wasKeyPressed(key) and not pressed then
				bool = true
			elseif isKeyDown(key) and pressed then
				bool = true
			end
		end
	else
		if isKeyDown(modified) and not wasKeyReleased(modified) then
			if wasKeyPressed(key) and not pressed then
				bool = true
			elseif isKeyDown(key) and pressed then
				bool = true
			end
		end
	end
	if tostring(nextLockKey) == tostring(keylist) then
		if pressed and not wasKeyReleased(key) then
			bool = false
--			nextLockKey = ""
		else
			bool = false
			nextLockKey = ""
		end
	end
	return bool
end

function async_http_request(method, url, args, resolve, reject)
	local request_lane = lanes.gen('*', {package = {path = package.path, cpath = package.cpath}}, function()
		local requests = require 'requests'
        local ok, result = pcall(requests.request, method, url, args)
        if ok then
            result.json, result.xml = nil, nil
            return true, result
        else
            return false, result
        end
    end)
    if not reject then reject = function() end end
    lua_thread.create(function()
        local lh = request_lane()
        while true do
            local status = lh.status
            if status == 'done' then
                local ok, result = lh[1], lh[2]
                if ok then resolve(result) else reject(result) end
                return
            elseif status == 'error' then
                return reject(lh[1])
            elseif status == 'killed' or status == 'cancelled' then
                return reject(status)
            end
            wait(0)
        end
    end)
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.TextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function check_account()
	while true do
		wait (0)
		if pTemp.user.checkAccount then
			pTemp.user.checkAccount = false
			print ("Проверка наличия аккаунта")
			pTemp.check_numberAccount = true
			if srv ~= 99 then sampSendChat ("/stats")
			else pInfo.info.numberAccount = 1546365352 end
			while pInfo.info.playerAccountNumber == 0 do
				wait (0)
			end
			local getacc = {}
			while srv == nil do
				wait (0)
			end

			getacc.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			getacc.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			while sInfo.url:len() == 0 do
				wait (0)
			end
			async_http_request ('POST', sInfo.url.."/account_check.php", getacc,
			function (response)
				if response.text:find ("Account is found") then
					print ("Аккаунт найден, переход к загрузке")
					pTemp.loading_time = os.clock()
					pTemp.user.loadAccount = true
				elseif response.text:find ("Account not found") then
					print ("Аккаунт не найден, переход к регистрации")
					pTemp.user.addAccount = true
				elseif response.text:find ("Data not found") then
					sampAddChatMessage("[AHelper] {FFFFFF}Ошибка при передаче данных ("..response.text..")", 0x4682B4) -- Передалось нулевое значение, выводим инфу из PHP и выгружаем скрипт
					thisScript():unload()
				else
					sampAddChatMessage("[AHelper] {FFFFFF}Ошибка на стороне обработчика. Подробнее в консоли (~ или moonloader.log)", 0x4682B4)
					print ("Other information: "..response.text) -- На стороне сайта произошла ошибка, выводим инфу и выгружаем скрипт
					thisScript():unload()
				end
			end,
			function (err)
				sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при поиске аккаунта. Повторная попытка", 0x4682B4)
				print (err.text)
				thisScript():reload()
			end)
		end
	end
end


function load_account()
	while true do
		wait (0)
		if pTemp.user.loadAccount then
			pTemp.user.loadAccount = false
			local accload = {}
			accload.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&version="..thisScript().version.."&nick="..getLocalPlayerName().."&version_num="..thisScript().version_num
			accload.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request("POST", sInfo.url.."/account_load.php", accload,
			function (response)
				if not response.text:find("<1>(.*)<2>(.*)<3>(.*)<4>(.*)<5>") then
				--if not response.text:find("| %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | (%S+) | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+") then
					print("LoadInfo error: "..u8:decode(response.text))
					sampAddChatMessage("[AHelper]{FFFFFF} Не удалось загрузить данные из базы данных.", 0x4682B4)
					sampAddChatMessage("[AHelper]{FFFFFF} Подробная информация в консоли (~) или в файле moonloader.log", 0x4682B4)
				else
					local one_stage = response.text:match ("<1>(.*)<2>")
					local two_stage = response.text:match ("<2>(.*)<3>")
					local third_stage = response.text:match ("<3>(.*)<4>")
					local fourth_stage = response.text:match ("<4>(.*)<5>")
					if not one_stage:find("| %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | (%S+) | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+") then
						print ("Не загружен первый этап")
						print ("Error: "..one_stage)
					end
					if not two_stage:find("| %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %S+ | %S+ | %S+ | %S+ | %S+ | %S+ | %S+ | %S+ | %S+ | %S+ | %S+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+") then
						print ("Не загружен второй этап")
						print ("Error: "..two_stage)
					end
					if not third_stage:find("| %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+") then
						print ("Не загружен третий этап")
						print ("Error: "..third_stage)
					end
					if not fourth_stage:find("| %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %S+ | %d+ | %d+ | %d+ | .* | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+") then
						print ("Не загружен четвёртый этап")
						print ("Error: "..fourth_stage)
					end
					--
					pInfo.info.adminLevel, pInfo.info.reports, pInfo.info.punishments, pInfo.set.AutoDuty, pInfo.set.AutoAint,
					pInfo.set.AutoTogphone, pInfo.set.AutoFon, pInfo.set.AutoSmson,
					pInfo.set.SkinDuty, pInfo.set.FloodMinute, pInfo.set.CapsMinute,
					pInfo.set.OfftopMinute, pInfo.set.OskMinute, pInfo.set.NeuvMinute,
					pInfo.set.NeadMinute, pInfo.set.CaptOMinute, pInfo.set.CaptKMinute,
					pInfo.set.OskNickMinute, pInfo.set.AutoWH, pInfo.set.AutoHideIP,
					pInfo.set.AutoHideChat, pInfo.set.AirBrakeSpeed, pInfo.set.AutoBan,
					pInfo.set.AutoAnswer, pInfo.set.OnlineAdmins, pInfo.set.cX, pInfo.set.cY,
					pInfo.set.OnlinePlayers, pInfo.set.pX, pInfo.set.pY, pInfo.set.recolor_a, -- 34
					pInfo.set.colorAChat = one_stage:match ("| (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%S+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+)")
					pInfo.set.colorAChat = tonumber (pInfo.set.colorAChat)
					temp_color_a = pInfo.set.colorAChat
					if pInfo.set.AutoDuty == '1' then
						if getCharArmour(PLAYER_PED) ~= 1000 then
							sampSendChat ("/duty "..tonumber(pInfo.set.SkinDuty))
						end
						iVar.ath.duty = imgui.ImBool(true)
					end
					if pInfo.set.AutoAint == '1' then
						iVar.ath.aint = imgui.ImBool(true)
						sampSendChat ("/aint")
					end
					if pInfo.set.AutoTogphone == '1' then
						iVar.ath.togphone = imgui.ImBool(true)
						sampSendChat ("/togphone")
					end
					if pInfo.set.AutoFon == '1' then
						iVar.ath.fon = imgui.ImBool(true)
						sampSendChat ("/fon")
					end
					if pInfo.set.AutoSmson == '1' then
						iVar.ath.smson = imgui.ImBool(true)
						sampSendChat ("/smson")
					end
					if pInfo.set.OnlineAdmins == '1' then
						iVar.main_settings.adminList.v = true
					end
					if pInfo.set.OnlinePlayers == '1' then
						iVar.main_settings.playerChecker.v = true
					end
					if pInfo.set.recolor_a == '1' then
						iVar.colors.a_recolor = imgui.ImBool(true)
						pInfo.set.recolor_a = true
					elseif pInfo.set.recolor_a == '0' then
						pInfo.set.recolor_a = false
					end

					if pInfo.set.AutoWH == '1' then
						local pStSet = sampGetServerSettingsPtr();
						NTdist = memory.getfloat(pStSet + 39)
						NTwalls = memory.getint8(pStSet + 47)
						NTshow = memory.getint8(pStSet + 56)
						memory.setfloat(pStSet + 39, 1488.0)
						memory.setint8(pStSet + 47, 0)
						memory.setint8(pStSet + 56, 1)
						pTemp.WH_Status = true
						iVar.cheat.wallhack = imgui.ImBool(true)
					end
					if pInfo.set.AutoHideIP == '1' then
						iVar.main_settings.hideip.v = true
						pInfo.set.AutoHideIP = true
						sampAddChatMessage ("[AHelper] {FFFFFF}Строки, содержащие IP-адреса, будут скрываться автоматически.", 0x4682B4)
					end
					if pInfo.set.AutoHideChat == '1' then
						iVar.main_settings.hidea.v = true
						pInfo.set.AutoHideChat = true
						sampAddChatMessage ("[AHelper] {FFFFFF}Сообщения в админ-чате не будут отображаться.", 0x4682B4)
					end
					iVar.ath.dutySkin.v = pInfo.set.SkinDuty
					--[[editFloodMinute.v = pInfo.set.FloodMinute
					editCapsMinute.v = pInfo.set.CapsMinute
					editOfftopMinute.v = pInfo.set.OfftopMinute
					editNeuvMinute.v = pInfo.set.NeuvMinute
					editOskMinute.v = pInfo.set.OskMinute
					editNeadMinute.v = pInfo.set.NeadMinute
					editCaptKMinute.v = pInfo.set.CaptKMinute
					editCaptOMinute.v = pInfo.set.CaptOMinute
					editOskNickMinute.v = pInfo.set.OskNickMinute
					editAirBrakeSpeed1.v = pInfo.set.AirBrakeSpeed]]--
					--pInfo.info.adminLevel = tonumber (pInfo.info.adminLevel)
					--old_level = tonumber(pInfo.info.adminLevel)

					pInfo.set.recolor_r, pInfo.set.colorReport, pInfo.set.recolor_p, pInfo.set.colorPm,
					pInfo.set.bsync.enable, pInfo.set.bsync.ponly, pInfo.set.bsync.maxLines, pInfo.set.bsync.time,
					pInfo.set.bsync.weightLine, pInfo.set.bsync.sizePolygon, pInfo.set.bsync.countCorners,
					pInfo.set.bsync.rotation, pInfo.set.bsync.colorPlayer, pInfo.set.bsync.colorPlayerAFK,
					pInfo.set.bsync.colorCar, pInfo.set.bsync.colorStaticObj,
					pInfo.set.bsync.colorDynamicObj, pInfo.set.bsync.polygon_enable, pInfo.set.skMinute, pInfo.set.tkMinute, pInfo.set.mopDays, pInfo.set.tpDays, pInfo.set.gmcarDays, pInfo.set.aimDays, pInfo.set.fWHDays, pInfo.set.dgunDays, pInfo.set.airbrkDays, pInfo.set.antistunDays, pInfo.set.turboDays, pInfo.set.type_wh, pInfo.set.newLip = two_stage:match ("| (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%S+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+)")
					pInfo.set.colorReport = tonumber (pInfo.set.colorReport)
					pInfo.set.colorPm = tonumber (pInfo.set.colorPm)
					temp_color_r = pInfo.set.colorReport
					if pInfo.set.recolor_r == '1' then
						iVar.colors.r_recolor = imgui.ImBool(true)
						pInfo.set.recolor_r = true
					elseif pInfo.set.recolor_r == '0' then
						pInfo.set.recolor_r = false
					end
					if pInfo.set.recolor_p == '1' then
						iVar.colors.p_recolor = imgui.ImBool(true)
						pInfo.set.recolor_p = true
					elseif pInfo.set.recolor_p == '0' then
						pInfo.set.recolor_p = false
					end

					if pInfo.set.bsync.enable == '1' then
						pInfo.set.bsync.enable = true
						iVar.tracers.BulletTrackActivate = imgui.ImBool(true)
					else
						pInfo.set.bsync.enable = false
					end

					if pInfo.set.bsync.ponly == '1' then
						pInfo.set.bsync.ponly = true
						iVar.tracers.BulletTrackOnlyPlayer = imgui.ImBool(true)
					else
						pInfo.set.bsync.ponly = false
					end

					if pInfo.set.bsync.polygon_enable == '1' then
						pInfo.set.bsync.polygon_enable = true
						iVar.tracers.BulletTrackPolyginActivate = imgui.ImBool(true)
					else
						pInfo.set.bsync.polygon_enable = false
					end

					iVar.cheat.type_wh.v = pInfo.set.type_wh

					BulletSync.maxLines = tonumber (pInfo.set.bsync.maxLines)
					for t = 1, BulletSync.maxLines do
						BulletSync[t].timeDelete = tonumber (pInfo.set.bsync.time)
						BulletSync[t].tWeightLine = tonumber (pInfo.set.bsync.weightLine)
						BulletSync[t].tSizePolygon = tonumber (pInfo.set.bsync.sizePolygon)
						BulletSync[t].tCountCorners = tonumber (pInfo.set.bsync.countCorners)
						BulletSync[t].tRotation = tonumber (pInfo.set.bsync.rotation)
					end

					--[[fastAim.v = tonumber (pInfo.set.aimDays)
					fastAirbrk.v = tonumber (pInfo.set.airbrkDays)
					fastAntistun.v = tonumber (pInfo.set.antistunDays)
					fastCaps.v = tonumber (pInfo.set.CapsMinute)
					fastDgun.v = tonumber (pInfo.set.dgunDays)
					fastFlood.v = tonumber (pInfo.set.FloodMinute)
					fastGmCar.v = tonumber (pInfo.set.gmcarDays)
					fastMop.v = tonumber (pInfo.set.mopDays)
					fastNeuv.v = tonumber (pInfo.set.NeuvMinute)
					fastOfftop.v = tonumber (pInfo.set.OfftopMinute)
					fastOsk.v = tonumber (pInfo.set.OskMinute)
					fastSK.v = tonumber (pInfo.set.skMinute)
					fastTK.v = tonumber (pInfo.set.tkMinute)
					fastTp.v = tonumber (pInfo.set.tpDays)
					fastTurbo.v = tonumber (pInfo.set.turboDays)
					fastWh.v = tonumber (pInfo.set.fWHDays)]]--

					iVar.tracers.BulletTrackCountPolygin.v = pInfo.set.bsync.countCorners
					iVar.tracers.BulletTrackMaxLines.v = pInfo.set.bsync.maxLines
					iVar.tracers.BulletTrackMaxWeight.v = pInfo.set.bsync.weightLine
					iVar.tracers.BulletTrackRotationPolygon.v = pInfo.set.bsync.rotation
					iVar.tracers.BulletTrackSizePolygon.v = pInfo.set.bsync.sizePolygon
					iVar.tracers.BulletTrackTime.v = pInfo.set.bsync.time

					shot_in_player.v[4], shot_in_player.v[1], shot_in_player.v[2], shot_in_player.v[3] = explode_argb(pInfo.set.bsync.colorPlayer)
					shot_in_player.v[1] = shot_in_player.v[1]/255
					shot_in_player.v[2] = shot_in_player.v[2]/255
					shot_in_player.v[3] = shot_in_player.v[3]/255
					shot_in_player.v[4] = shot_in_player.v[4]/255

					shot_in_player_afk.v[4], shot_in_player_afk.v[1], shot_in_player_afk.v[2], shot_in_player_afk.v[3] = explode_argb(pInfo.set.bsync.colorPlayerAFK)
					shot_in_player_afk.v[1] = shot_in_player_afk.v[1]/255
					shot_in_player_afk.v[2] = shot_in_player_afk.v[2]/255
					shot_in_player_afk.v[3] = shot_in_player_afk.v[3]/255
					shot_in_player_afk.v[4] = shot_in_player_afk.v[4]/255

					shot_in_vehicle.v[4], shot_in_vehicle.v[1], shot_in_vehicle.v[2], shot_in_vehicle.v[3] = explode_argb(pInfo.set.bsync.colorCar)
					shot_in_vehicle.v[1] = shot_in_vehicle.v[1]/255
					shot_in_vehicle.v[2] = shot_in_vehicle.v[2]/255
					shot_in_vehicle.v[3] = shot_in_vehicle.v[3]/255
					shot_in_vehicle.v[4] = shot_in_vehicle.v[4]/255

					shot_in_dynamic_obj.v[4], shot_in_dynamic_obj.v[1], shot_in_dynamic_obj.v[2], shot_in_dynamic_obj.v[3] = explode_argb(pInfo.set.bsync.colorDynamicObj)
					shot_in_dynamic_obj.v[1] = shot_in_dynamic_obj.v[1]/255
					shot_in_dynamic_obj.v[2] = shot_in_dynamic_obj.v[2]/255
					shot_in_dynamic_obj.v[3] = shot_in_dynamic_obj.v[3]/255
					shot_in_dynamic_obj.v[4] = shot_in_dynamic_obj.v[4]/255

					shot_in_static_obj.v[4], shot_in_static_obj.v[1], shot_in_static_obj.v[2], shot_in_static_obj.v[3] = explode_argb(pInfo.set.bsync.colorStaticObj)
					shot_in_static_obj.v[1] = shot_in_static_obj.v[1]/255
					shot_in_static_obj.v[2] = shot_in_static_obj.v[2]/255
					shot_in_static_obj.v[3] = shot_in_static_obj.v[3]/255
					shot_in_static_obj.v[4] = shot_in_static_obj.v[4]/255

					pInfo.set.warnings.textures, pInfo.set.warnings.hit, pInfo.set.warnings.deagle,
					pInfo.set.warnings.m4, pInfo.set.warnings.shotgun, pInfo.set.warnings.pistol,
					pInfo.set.warnings.silenced, pInfo.set.warnings.mp5, pInfo.set.warnings.ak47,
					pInfo.set.warnings.rifle, pInfo.set.warnings.speedhack, pInfo.set.warnings.speedhack_delay,
					pInfo.set.warnings.repair, pInfo.set.converter, pInfo.set.invisible_onfoot,
					pInfo.set.air_activate, pInfo.set.re_panel_change, pInfo.set.re_panel_style,
					pInfo.set.ip_hash, pInfo.set.right_panel_change, pInfo.set.rpX,
					pInfo.set.rpY, pInfo.set.lpX, pInfo.set.lpY,
					pInfo.set.fps_unlock, pInfo.set.clickwarp, pInfo.set.clock,
					pInfo.set.clX, pInfo.set.clY, pInfo.set.forms, pInfo.set.recolor_s, pInfo.set.colorSMS = third_stage:match ("| (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+)")

					pInfo.set.warnings.deagle = tonumber(pInfo.set.warnings.deagle)
					pInfo.set.warnings.m4 = tonumber(pInfo.set.warnings.m4)
					pInfo.set.warnings.shotgun = tonumber(pInfo.set.warnings.shotgun)
					pInfo.set.warnings.pistol = tonumber(pInfo.set.warnings.pistol)
					pInfo.set.warnings.silenced = tonumber(pInfo.set.warnings.silenced)
					pInfo.set.warnings.mp5 = tonumber(pInfo.set.warnings.mp5)
					pInfo.set.warnings.ak47 = tonumber(pInfo.set.warnings.ak47)
					pInfo.set.warnings.rifle = tonumber(pInfo.set.warnings.rifle)
					pInfo.set.warnings.speedhack_delay = tonumber(pInfo.set.warnings.speedhack_delay)
					pInfo.set.re_panel_style = tonumber (pInfo.set.re_panel_style)
					pInfo.set.rpX = tonumber (pInfo.set.rpX)
					pInfo.set.rpY = tonumber (pInfo.set.rpY)
					pInfo.set.lpX = tonumber (pInfo.set.lpX)
					pInfo.set.lpY = tonumber (pInfo.set.lpY)
					pInfo.set.clX = tonumber (pInfo.set.clX)
					pInfo.set.clY = tonumber (pInfo.set.clY)

					if pInfo.set.fps_unlock == '1' then
						iVar.main_settings.fpsunlock.v = true
						enableFPSUnlock()
					else iVar.main_settings.fpsunlock.v = false end


					pInfo.set.font_size, pInfo.set.widget.kills, pInfo.set.widget.time_s, pInfo.set.widget.pm_all, pInfo.set.widget.pun_all, pInfo.set.widget.pm_day, pInfo.set.widget.pun_day,
					pInfo.set.widget.datetime, pInfo.set.widget.in_s, pInfo.set.sizeWidget, pInfo.set.keys_panel, pInfo.set.kX, pInfo.set.kY, pInfo.set.r_text, pInfo.set.auto_screen, pInfo.set.admSortType,
					pInfo.set.fastMap, pInfo.set.widget.chat, pInfo.set.widget.server_status, pInfo.set.premium, pInfo.set.a_n_chat, pInfo.set.a_n_color, pInfo.set.p_admAct, pInfo.set.p_admAct_color,
					pInfo.set.p_cheat, pInfo.set.pcx, pInfo.set.pcy, pInfo.set.s_notf, pInfo.set.s_notf_id, pInfo.set.nget, pInfo.set.afk, pInfo.set.bindAccess = fourth_stage:match ("| (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%S+) | (%d+) | (%d+) | (%d+) | (.*) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+)")

					if pInfo.set.widget.kills == '1' then iVar.widget.kills.v = true
					else iVar.widget.kills.v = false end
					if pInfo.set.widget.time_s == '1' then iVar.widget.time_s.v = true
					else iVar.widget.time_s.v = false end
					if pInfo.set.widget.pm_all == '1' then iVar.widget.pm_all.v = true
					else iVar.widget.pm_all.v = false end
					if pInfo.set.widget.pun_all == '1' then iVar.widget.pun_all.v = true
					else iVar.widget.pun_all.v = false end
					if pInfo.set.widget.pm_day == '1' then iVar.widget.pm_day.v = true
					else iVar.widget.pm_day.v = false end
					if pInfo.set.widget.pun_day == '1' then iVar.widget.pun_day.v = true
					else iVar.widget.pun_day.v = false end
					if pInfo.set.widget.datetime == '1' then iVar.widget.datetime.v = true
					else iVar.widget.datetime.v = false end
					if pInfo.set.widget.in_s == '1' then iVar.widget.in_s.v = true
					else iVar.widget.in_s.v = false end
					if pInfo.set.keys_panel == '1' then iVar.recon.keysPanel.v = true
					else iVar.recon.keysPanel.v = false end
					if pInfo.set.widget.chat == '1' then iVar.widget.chat.v = true
					else iVar.widget.chat.v = false end
					iVar.widget.sizeWidget.v = tonumber (pInfo.set.sizeWidget)
					pInfo.set.premium = tonumber (pInfo.set.premium)
					if pInfo.set.air_activate == '1' then iVar.cheat.air_activate.v = true
					else iVar.cheat.air_activate.v = false end
					if pInfo.set.p_cheat == '1' then iVar.main_settings.p_cheat.v = true
					else iVar.main_settings.p_cheat.v = false end
					pInfo.set.pcx = tonumber (pInfo.set.pcx)
					pInfo.set.pcy = tonumber (pInfo.set.pcy)
					if pInfo.set.s_notf == '1' then iVar.main_settings.s_notf.v = true
					else iVar.main_settings.s_notf.v = false end
					pInfo.set.s_notf_id = tonumber (pInfo.set.s_notf_id)
					iVar.main_settings.s_notf_id.v = pInfo.set.s_notf_id
					if pInfo.set.p_admAct == '1' then
						iVar.colors.p_admAct.v = true
						pInfo.set.p_admAct = true
					else
						iVar.colors.p_admAct.v = false
						pInfo.set.p_admAct = false
					end

					pInfo.set.font_size = tonumber (pInfo.set.font_size)
					iVar.main_settings.fontSizeAdmList.v = pInfo.set.font_size
					my_font = renderCreateFont('Arial', 7+pInfo.set.font_size-(3-pInfo.set.font_size), 1+4)
					font_panel = renderCreateFont('Arial', 11, 1+4)
					font_keys = renderCreateFont('Arial', 14, font_flag.BOLD + font_flag.BORDER)

					--imgui.SetMouseCursor(imgui.MouseCursor.None)
					imgui.Process = true
					imgui.ShowCursor = false
					imgui.LockPlayer = false


					if not doesDirectoryExist("moonloader\\config\\AHelper\\images") then
						createDirectory("moonloader\\config\\AHelper\\images")
					end
					for i = 1, 3 do
						if not doesFileExist(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_'..i..'.png') then
							downloadUrlToFile('http://martin-rojo.myjino.ru/images/screenshot_'..i..'.png', getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_'..i..'.png')
							print ("Отсутствовал screenshot_"..i..".png в configAHelper//images. Скачан")
						end
					end
					RE_STYLE_1 = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_1.PNG')
					RE_STYLE_2 = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_2.PNG')
					RE_RIGHT_PANEL = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_3.PNG')


					iVar.ath.a_password.v = aInfo.info.aPass
					iVar.ath.a_password_b.v = aInfo.set.aPass_On
					iVar.ath.password.v = tostring(aInfo.info.lPass)
					iVar.ath.password_b.v = aInfo.set.lPass_On
					iVar.ath.a_spawn.v = aInfo.set.aSpawn
					iVar.ath.type_spawn.v = aInfo.set.typeSpawn - 1
					iVar.ath.gw_gang.v = aInfo.set.gwGang - 1
					iVar.ath.dm_loc.v = tostring (aInfo.set.dmLoc)
					iVar.ath.dm_skin.v = tostring (aInfo.set.dmSkin)

					if aInfo.info.IP ~= sampGetCurrentServerAddress() then
						aInfo.set.lPass_On = false
						aInfo.set.aPass_On = false
						aInfo.set.aSpawn = false
						aInfo.info.aPass = ""
						aInfo.info.lPass = ""
					end

					pInfo.set.admSortType = tonumber (pInfo.set.admSortType)
					iVar.main_settings.adminListSort.v = pInfo.set.admSortType - 1

					if pInfo.set.AutoAnswer == '1' then iVar.main_settings.answerAuto.v = true
					else iVar.main_settings.answerAuto.v = false end
					if pInfo.set.converter == '1' then iVar.main_settings.convert.v = true
					else iVar.main_settings.convert.v = false end
					if pInfo.set.auto_screen == '1' then iVar.main_settings.autoScreen.v = true
					else iVar.main_settings.autoScreen.v = false end
					if pInfo.set.forms == '1' then iVar.main_settings.a_forms.v = true
					else iVar.main_settings.a_forms.v = false end
					iVar.main_settings.chatlog.v = aInfo.set.chatlog
					iVar.main_settings.answerText.v = pInfo.set.r_text
					if pInfo.set.re_panel_change == '1' then iVar.recon.leftPanel.v = true
					else iVar.recon.leftPanel.v = false end
					iVar.recon.leftPanelStyle.v = tonumber (pInfo.set.re_panel_style)
					if pInfo.set.right_panel_change == '1' then iVar.recon.rightPanel.v = true
					else iVar.recon.rightPanel.v = false end
					if pInfo.set.ip_hash == '1' then iVar.main_settings.ipHash.v = true
					else iVar.main_settings.ipHash.v = false end
					if pInfo.set.newLip == '1' then iVar.main_settings.newLip.v = true
					else iVar.main_settings.newLip.v = false end
					iVar.widget.sizeWidget.v = tonumber (pInfo.set.sizeWidget)
					if pInfo.set.invisible_onfoot == '1' then iVar.cheat.invisible_onfoot.v = true
					else iVar.cheat.invisible_onfoot.v = false end
					if pInfo.set.clock == '1' then iVar.widget.activated.v = true
					else iVar.widget.activated.v = false end
					if pInfo.set.fastMap == '1' then iVar.main_settings.fastMap.v = true
					else iVar.main_settings.fastMap.v = false end
					if pInfo.set.a_n_chat == '1' then iVar.colors.a_p_recolor.v = true
					else iVar.colors.a_p_recolor.v = false end
					pInfo.info.adminLevel = tonumber (pInfo.info.adminLevel)
					if pInfo.set.recolor_s == '1' then
						iVar.colors.s_recolor = imgui.ImBool(true)
						pInfo.set.recolor_s = true
					elseif pInfo.set.recolor_s == '0' then
						pInfo.set.recolor_s = false
					end
					if pInfo.set.clickwarp == '1' then iVar.cheat.clickwarp.v = true
					else iVar.cheat.clickwarp.v = false end
					if pInfo.set.nget == '1' then iVar.main_settings.nget.v = true
					else iVar.main_settings.nget.v = false end
					if pInfo.set.afk == '1' then iVar.main_settings.afk.v = true
					else iVar.main_settings.afk.v = false end

					iVar.colors.a_chat.v[1], iVar.colors.a_chat.v[2], iVar.colors.a_chat.v[3], iVar.colors.a_chat.v[4] = imgui.ImColor(pInfo.set.colorAChat):GetRGBA()
					iVar.colors.a_chat.v[1] = iVar.colors.a_chat.v[1]/255
					iVar.colors.a_chat.v[2] = iVar.colors.a_chat.v[2]/255
					iVar.colors.a_chat.v[3] = iVar.colors.a_chat.v[3]/255

					iVar.colors.report.v[1], iVar.colors.report.v[2], iVar.colors.report.v[3], iVar.colors.report.v[4] = imgui.ImColor(pInfo.set.colorReport):GetRGBA()
					iVar.colors.report.v[1] = iVar.colors.report.v[1]/255
					iVar.colors.report.v[2] = iVar.colors.report.v[2]/255
					iVar.colors.report.v[3] = iVar.colors.report.v[3]/255

					iVar.colors.pm.v[1], iVar.colors.pm.v[2], iVar.colors.pm.v[3], iVar.colors.pm.v[4] = imgui.ImColor(pInfo.set.colorPm):GetRGBA()
					iVar.colors.pm.v[1] = iVar.colors.pm.v[1]/255
					iVar.colors.pm.v[2] = iVar.colors.pm.v[2]/255
					iVar.colors.pm.v[3] = iVar.colors.pm.v[3]/255

					pInfo.set.colorSMS = tonumber (pInfo.set.colorSMS)
					iVar.colors.sms.v[1], iVar.colors.sms.v[2], iVar.colors.sms.v[3], iVar.colors.sms.v[4] = imgui.ImColor(pInfo.set.colorSMS):GetRGBA()
					iVar.colors.sms.v[1] = iVar.colors.sms.v[1]/255
					iVar.colors.sms.v[2] = iVar.colors.sms.v[2]/255
					iVar.colors.sms.v[3] = iVar.colors.sms.v[3]/255

					pInfo.set.a_n_color = tonumber (pInfo.set.a_n_color)
					iVar.colors.admNick.v[1], iVar.colors.admNick.v[2], iVar.colors.admNick.v[3], iVar.colors.admNick.v[4] = imgui.ImColor(pInfo.set.a_n_color):GetRGBA()
					iVar.colors.admNick.v[1] = iVar.colors.admNick.v[1]/255
					iVar.colors.admNick.v[2] = iVar.colors.admNick.v[2]/255
					iVar.colors.admNick.v[3] = iVar.colors.admNick.v[3]/255

					pInfo.set.p_admAct_color = tonumber (pInfo.set.p_admAct_color)
					iVar.colors.p_admActColor.v[1], iVar.colors.p_admActColor.v[2], iVar.colors.p_admActColor.v[3], iVar.colors.p_admActColor.v[4] = imgui.ImColor(pInfo.set.p_admAct_color):GetRGBA()
					iVar.colors.p_admActColor.v[1] = iVar.colors.p_admActColor.v[1]/255
					iVar.colors.p_admActColor.v[2] = iVar.colors.p_admActColor.v[2]/255
					iVar.colors.p_admActColor.v[3] = iVar.colors.p_admActColor.v[3]/255

					if pInfo.set.warnings.textures == '1' then iVar.warnings.textures.v = true
					else iVar.warnings.textures.v = false end
					if pInfo.set.warnings.hit == '1' then iVar.warnings.hit.v = true
					else iVar.warnings.hit.v = false end
					iVar.warnings.deagle.v = tonumber (pInfo.set.warnings.deagle)
					iVar.warnings.m4.v = tonumber (pInfo.set.warnings.m4)
					iVar.warnings.shotgun.v = tonumber (pInfo.set.warnings.shotgun)
					iVar.warnings.pistol.v = tonumber (pInfo.set.warnings.pistol)
					iVar.warnings.silenced.v = tonumber (pInfo.set.warnings.silenced)
					iVar.warnings.mp5.v = tonumber (pInfo.set.warnings.mp5)
					iVar.warnings.ak47.v = tonumber (pInfo.set.warnings.ak47)
					iVar.warnings.rifle.v = tonumber (pInfo.set.warnings.rifle)
					if pInfo.set.warnings.speedhack == '1' then iVar.warnings.speedhack.v = true
					else iVar.warnings.speedhack.v = false end
					iVar.warnings.speedhack_delay.v = tonumber (pInfo.set.warnings.speedhack_delay)
					if pInfo.set.warnings.repair == '1' then iVar.warnings.cleoRepair.v = true
					else iVar.warnings.cleoRepair.v = false end
					if pInfo.set.bindAccess == '1' then pInfo.set.bindAccess = true
					else pInfo.set.bindAccess = false end

					print ("Аккаунт загружен.")
					print (string.format ('[DEBUG] Данные загружены за %d ms', (os.clock()-pTemp.loading_time)*1000))
					notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАккаунт успешно загружен', 7)
					pTemp.admUpdate = true
					sampSendChat("/admins")
					pTemp.user.loadChecker = true
					pTemp.user.loadAdm = true
					pTemp.user.load_colors = true
					pTemp.user.load_custom_cmd = true
					pTemp.user.load_answers = true
					pTemp.user.load_bans = true
					pTemp.user.load_hkeys = true
					pTemp.user.load_cmds = true
					pTemp.req_id = 0
					pTemp.login = true
				end
			end,
			function (err)

			end)
		end
	end
end


function savedata (params, status)
	local savedata = {}
	if status ~= 2 then
		if params == 'autoduty' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=AutoDuty&value="..status
		elseif params == 'autoaint' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=AutoAint&value="..status
		elseif params == 'autotogphone' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=AutoTogphone&value="..status
		elseif params == 'autofon' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=AutoFon&value="..status
		elseif params == 'smson' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=AutoSmson&value="..status
		elseif params == 'wallhack' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=wallhack&value="..status
		elseif params == 'hideip' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=hideip&value="..status
		elseif params == 'hidechat' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=hidechat&value="..status
		elseif params == 'autoban' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=autoban&value="..status
		elseif params == 'autoanswer' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=autoanswer&value="..status
		elseif params == 'onlineadmins' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=onlineadmins&value="..status
		elseif params == 'onlineplayers' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=onlineplayers&value="..status
		elseif params == 'recolor_a' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=recolor_a&value="..status
		elseif params == 'recolor_r' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=recolor_r&value="..status
		elseif params == 'recolor_p' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=recolor_p&value="..status
		elseif params == 'recolor_s' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=recolor_s&value="..status
		elseif params == 'b_enable' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_enable&value="..status
		elseif params == 'b_ponly' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_ponly&value="..status
		elseif params == 'b_polygon_enable' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_polygon_enable&value="..status
		elseif params == 'newlip' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=newlip&value="..status
		elseif params == 'converter' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=converter&value="..status
		elseif params == 'textures' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=textures&value="..status
		elseif params == 'hit' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=hit&value="..status
		elseif params == 'speedhack' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=speedhack&value="..status
		elseif params == 'repair' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=repair&value="..status
		elseif params == 'invisible' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=invisible&value="..status
		elseif params == 'air_act' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=air_activate&value="..status
		elseif params == 're_panel_change' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=re_panel_change&value="..status
		elseif params == 'right_panel_change' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=right_panel_change&value="..status
		elseif params == 'ip_hash' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=ip_hash&value="..status
		elseif params == 'fps_unlock' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=fps_unlock&value="..status
		elseif params == 'clock' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=time&value="..status
		elseif params == 'forms' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=forms&value="..status
		elseif params == 'w_kills' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_kills&value="..status
		elseif params == 'w_time_s' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_time_s&value="..status
		elseif params == 'w_pm_all' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_pm_all&value="..status
		elseif params == 'w_pun_all' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_pun_all&value="..status
		elseif params == 'w_pm_day' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_pm_day&value="..status
		elseif params == 'w_pun_day' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_pun_day&value="..status
		elseif params == 'w_datetime' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_datetime&value="..status
		elseif params == 'w_in_s' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_in_s&value="..status
		elseif params == 'keys_panel' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=keys_panel&value="..status
		elseif params == 'auto_screen' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=auto_screen&value="..status
		elseif params == 'fastmap' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=fastMap&value="..status
		elseif params == 'w_chat' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_chat&value="..status
		elseif params == 'w_server' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=w_server&value="..status
		elseif params == 'a_n_chat' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=a_n_chat&value="..status
		elseif params == 'p_admAct' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=p_admAct&value="..status
		elseif params == 'p_cheat' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=p_cheat&value="..status
		elseif params == 's_notf' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=s_notf&value="..status
		elseif params == 'nget' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=nget&value="..status
		elseif params == 'afk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=afk&value="..status
		elseif params == 'clickwarp' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=clickwarp&value="..status end
	else
		if params == 'skin' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=skin&value="..pInfo.set.SkinDuty
		elseif params == 'flood' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=flood&value="..pInfo.set.FloodMinute
		elseif params == 'caps' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=caps&value="..pInfo.set.CapsMinute
		elseif params == 'offtop' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=offtop&value="..pInfo.set.OfftopMinute
		elseif params == 'osk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=osk&value="..pInfo.set.OskMinute
		elseif params == 'neuv' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=neuv&value="..pInfo.set.NeuvMinute
		elseif params == 'nead' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=nead&value="..pInfo.set.NeadMinute
		elseif params == 'capto' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=capto&value="..pInfo.set.CaptOMinute
		elseif params == 'captk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=captk&value="..pInfo.set.CaptKMinute
		elseif params == 'osknick' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=osknick&value="..pInfo.set.OskNickMinute
		elseif params == 'tk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=tk&value="..pInfo.set.tkMinute
		elseif params == 'sk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=sk&value="..pInfo.set.skMinute
		elseif params == 'mop' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=mop&value="..pInfo.set.mopDays
		elseif params == 'tp' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=tp&value="..pInfo.set.tpDays
		elseif params == 'gmcar' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=gmcar&value="..pInfo.set.gmcarDays
		elseif params == 'aim' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=aim&value="..pInfo.set.aimDays
		elseif params == 'fWH' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=fWH&value="..pInfo.set.fWHDays
		elseif params == 'dgun' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=dgun&value="..pInfo.set.dgunDays
		elseif params == 'airbrk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=airbrk&value="..pInfo.set.airbrkDays
		elseif params == 'antistun' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=antistun&value="..pInfo.set.antistunDays
		elseif params == 'turbo' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=turbo&value="..pInfo.set.turboDays
		elseif params == 'airbrake' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=airbrake&value="..pInfo.set.AirBrakeSpeed
		elseif params == 'adminlvl' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=level&value="..pInfo.info.adminLevel
		elseif params == 'cx' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=cX&value="..pInfo.set.cX
		elseif params == 'cy' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=cY&value="..pInfo.set.cY
		elseif params == 'px' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=pX&value="..pInfo.set.pX
		elseif params == 'py' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=pY&value="..pInfo.set.pY
		elseif params == 'color_a' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=color_a&value="..pInfo.set.colorAChat
		elseif params == 'color_r' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=color_r&value="..pInfo.set.colorReport
		elseif params == 'color_p' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=color_p&value="..pInfo.set.colorPm
		elseif params == 'color_s' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=color_s&value="..pInfo.set.colorSMS
		elseif params == 'color_player' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_colorPlayer&value="..pInfo.set.bsync.colorPlayer
		elseif params == 'color_player_afk' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_colorPlayerAFK&value="..pInfo.set.bsync.colorPlayerAFK
		elseif params == 'color_car' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_colorCar&value="..pInfo.set.bsync.colorCar
		elseif params == 'color_dynamic' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_colorStaticObj&value="..pInfo.set.bsync.colorDynamicObj
		elseif params == 'color_static' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_colorDynamicObj&value="..pInfo.set.bsync.colorStaticObj
		elseif params == 'b_time' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_time&value="..pInfo.set.bsync.time
		elseif params == 'b_maxlines' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_maxLines&value="..pInfo.set.bsync.maxLines
		elseif params == 'b_weightlines' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_weightLine&value="..pInfo.set.bsync.weightLine
		elseif params == 'b_sizepolygon' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_sizePolygon&value="..pInfo.set.bsync.sizePolygon
		elseif params == 'b_countcorners' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_countCorners&value="..pInfo.set.bsync.countCorners
		elseif params == 'b_rotation' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=b_rotation&value="..pInfo.set.bsync.rotation
		elseif params == 'type_wh' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=type_wh&value="..pInfo.set.type_wh
		elseif params == 'deagle' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=deagle&value="..pInfo.set.warnings.deagle
		elseif params == 'm4' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=m4&value="..pInfo.set.warnings.m4
		elseif params == 'shotgun' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=shotgun&value="..pInfo.set.warnings.shotgun
		elseif params == 'pistol' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=9mm&value="..pInfo.set.warnings.pistol
		elseif params == 'silenced' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=silenced&value="..pInfo.set.warnings.silenced
		elseif params == 'mp5' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=mp5&value="..pInfo.set.warnings.mp5
		elseif params == 'ak47' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=ak47&value="..pInfo.set.warnings.ak47
		elseif params == 'rifle' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=rifle&value="..pInfo.set.warnings.rifle
		elseif params == 'speedhack_delay' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=speedhack_delay&value="..pInfo.set.warnings.speedhack_delay
		elseif params == 're_panel_style' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=re_panel_style&value="..pInfo.set.re_panel_style
		elseif params == 'rpX' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=rpX&value="..pInfo.set.rpX
		elseif params == 'rpY' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=rpY&value="..pInfo.set.rpY
		elseif params == 'lpX' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=lpX&value="..pInfo.set.lpX
		elseif params == 'lpY' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=lpY&value="..pInfo.set.lpY
		elseif params == 'clX' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=clX&value="..pInfo.set.clX
		elseif params == 'clY' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=clY&value="..pInfo.set.clY
		elseif params == 'font_size' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=font_size&value="..pInfo.set.font_size
		elseif params == 'sizewidget' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=sizewidget&value="..pInfo.set.sizeWidget
		elseif params == 'kX' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=keys_x&value="..pInfo.set.kX
		elseif params == 'kY' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=keys_y&value="..pInfo.set.kY
		elseif params == 'report_text' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=report_text&value="..pInfo.set.r_text
		elseif params == 'admsort' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=typeSort&value="..pInfo.set.admSortType
		elseif params == 'a_n_color' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=a_n_color&value="..pInfo.set.a_n_color
		elseif params == 'p_admActColor' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=p_admActColor&value="..pInfo.set.p_admAct_color
		elseif params == 'pcx' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=pcx&value="..pInfo.set.pcx
		elseif params == 'pcy' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=pcy&value="..pInfo.set.pcy
		elseif params == 's_notf_id' then savedata.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name=s_notf_id&value="..pInfo.set.s_notf_id
		end
	end
	savedata.headers = {
		['content-type']='application/x-www-form-urlencoded'
	}
	async_http_request('POST', sInfo.url.."/account_update.php", savedata,
	function(response)
		if response.text:find("Account not found") or u8:decode(response.text):find("Data not found") then
			print("UpdInfo ErrTrue: "..u8:decode(response.text))
		end
	end,
	function(err)
		print(err)
	end)
end

function register_account()
	while true do
		wait (0)
		if pTemp.user.addAccount then
			pTemp.user.addAccount = false
			local regstat = {}
			regstat.data = "srv="..srv.."&num="..pInfo.info.playerAccoutNumber.."&lvl="..pInfo.info.adminLevel.."&nick="..getLocalPlayerName()
			regstat.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request('POST', sInfo.url..'/account_add.php', regstat,
			function (response)
				if u8:decode(response.text):find("Успешная регистрация.") then
					sampAddChatMessage("[AHelper]{FFFFFF} Вы успешно прошли регистрацию.", 0x4682B4)
					print("AddInfo: "..u8:decode(response.text))
					if not doesDirectoryExist("moonloader\\config\\AHelper\\images") then
						createDirectory("moonloader\\config\\AHelper\\images")
					end
					for i = 1, 3 do
						if not doesFileExist(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_'..i..'.png') then
							downloadUrlToFile('http://martin-rojo.myjino.ru/images/screenshot_'..i..'.png', getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_'..i..'.png')
							print ("Отсутствовал screenshot_"..i..".png в config/AHelper/images. Скачан")
						end
					end
					RE_STYLE_1 = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_1.PNG')
					RE_STYLE_2 = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_2.PNG')
					RE_RIGHT_PANEL = imgui.CreateTextureFromFile(getGameDirectory() .. '\\moonloader\\config\\AHelper\\images\\screenshot_3.PNG')
					thisScript():reload()
				elseif u8:decode(response.text):find("Данный аккаунт уже существует") or u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#1). Работа скрипта остановлена.", 0xFFFF00)
					print("AddInfo ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)

			end)

		end
	end
end

function aMenu()
	--if pTemp.login then
		getStat()
		getAdmStat()
		for i, k in ipairs (a_cmd) do
			change_cmd[i] = imgui.ImBuffer(256)
			change_cmd[i].v = u8(string.format ("%s", k.cmd))
		end
		win_state['main'].v = not win_state['main'].v
	--end
end

function check_update_menu()
	async_http_request("GET", "https://raw.githubusercontent.com/RaffCor/AHelper_New/master/update.json", nil,
	function (response)
		local update = decodeJson(response.text)
		if thisScript().version_num ~= update.latest_number then
			pTemp.update.status = true
			pTemp.update.version = update.latest
			pTemp.update.date = update.latest_date
			pTemp.update.unsupported_number = update.unsupported_number
			pTemp.update.unsupported_version = update.unsupported_version
			pTemp.update.description = u8:decode(update.latest_description)
			if pTemp.update.unsupported_number > thisScript().version_num then
				sampAddChatMessage("[AHelper] {FFFFFF}Ваша версия скрипта устарела. Производится принудительное обновление до актуальной версии "..pTemp.update.version, 0x4682B4)
				async_http_request('GET', 'https://raw.githubusercontent.com/RaffCor/AHelper_New/master/AHelper.luac', nil,
				function(response)
					local f = assert(io.open(getWorkingDirectory() .. '/AHelper.luac', 'wb'))
					f:write(response.text)
					f:close()
					sampAddChatMessage("[AHelper]{FFFFFF} Обновление успешно, скрипт перезагружается", 0x4682B4)
					win_state['main'].v = false
					win_state['update_info'].v = false
					imgui.Process = false
					imgui.ShowCursor = false
					lua_thread.create (function()
						wait (1000)
						thisScript():reload()
					end)
				end,
				function(err)
					print(err)
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка при обновлении, попробуйте позже.", 0x4682B4)
					return
				end)
			end
		else
			if pTemp.update.menu then
				win_state['update_info'].v = true
				pTemp.update.status = false
				pTemp.update.menu = false
			end

		end
		if pTemp.update.unsupported_number <= thisScript().version_num and thisScript().version_num ~= update.latest_number then
			if pTemp.update.menu then
				win_state['update_info'].v = true
				pTemp.update.menu = false
			else
				sampAddChatMessage("[AHelper] {FFFFFF}Найдено обновление до версии "..pTemp.update.version, 0x4682B4)
				sampAddChatMessage('[AHelper] {FFFFFF}Чтобы обновить скрипт введите команду {AEFAA5}/amenu{FFFFFF} и выберите {AEFAA5}"Проверить обновления"', 0x4682B4)
			end
		end
	end,
	function (err)

	end)
end

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true

        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
end

function imgui.OnDrawFrame()
	local screenX, screenY = getScreenResolution() -- Получение разрешения экрана
	if win_state['main'].v then
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(1315, 630), imgui.Cond.FirstUseEver)
		if win_state['update_info'].v then imgui.Begin(u8('Главное меню | v'..thisScript().version..' (#'..thisScript().version_num..')'), win_state['main'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus)
		else imgui.Begin(u8('Главное меню | v'..thisScript().version..' (#'..thisScript().version_num..')'), win_state['main'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) end
		imgui.GetStyle().Colors[imgui.Col.ChildWindowBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
		imgui.BeginChild ('main child', imgui.ImVec2(220, 590), false)
			imgui.GetStyle().Colors[imgui.Col.ChildWindowBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00);
			imgui.BeginChild ('list', imgui.ImVec2(215, 450), true)
				imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00); -- Прозрачные кнопки
				imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.0, 0.5) -- Текст на кнопках по левому краю
				imgui.CenterTextColoredRGB('Меню')
				imgui.Separator()
				if imgui.ActiveButtonMC (1, '  '..fa.ICON_FA_INFO_CIRCLE..u8'      Главная', imgui.ImVec2(185, 20)) then pTemp.menu_id = 1 end
				if imgui.ActiveButtonMC (3, '  '..fa.ICON_FA_USER_COG..u8'     Настройки', imgui.ImVec2(185, 20)) then pTemp.menu_id = 3 end
				if imgui.ActiveButtonMC (6, '  '..fa.ICON_FA_CODE..u8'     Команды', imgui.ImVec2(185, 20)) then
					ctext = 'Загрузка...'
					async_http_request('GET', sInfo.url..'/script_commands.php', nil,
					function (response)
						ctext = u8:decode(response.text)
					end)
					pTemp.menu_id = 6
				end
				if imgui.ActiveButtonMC (7, '  '..fa.ICON_FA_FILE_ALT..u8'       Таблица наказаний', imgui.ImVec2(185, 20)) then
					itext = 'Загрузка...'
					async_http_request('GET', sInfo.url..'/table.php?srv='..srv, nil,
					function (response)
						itext = u8:decode(response.text)
					end)
					pTemp.menu_id = 7
				end

				imgui.NewLine()
				imgui.NewLine()
				imgui.CenterTextColoredRGB('Функции скрипта')
				imgui.Separator()
				imgui.Button ('   '..fa.ICON_FA_FILE_WORD..u8'     Список изменений', imgui.ImVec2(185, 20))
				if imgui.Button ('  '..fa.ICON_FA_DOWNLOAD..u8'     Проверить обновления', imgui.ImVec2(185, 20)) then
					pTemp.update.menu = true
					check_update_menu()
				end
				if imgui.Button ('  '..fa.ICON_FA_SYNC_ALT..u8'     Перезагрузить', imgui.ImVec2(185, 20)) then
					win_state['main'].v = false
					imgui.Process = false
					imgui.ShowCursor = false
					lua_thread.create (function ()
						wait (1000)
						thisScript():reload()
					end)

				end
				if imgui.Button ('  '..fa.ICON_FA_POWER_OFF..u8'     Отключить', imgui.ImVec2(185, 20)) then
					win_state['main'].v = false
					imgui.Process = false
					imgui.ShowCursor = false
					lua_thread.create (function ()
						wait (1000)
						thisScript():unload()
					end)
				end
				-- Возвращение настроек обратно
				imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00);
				imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
			imgui.EndChild()
			imgui.NewLine()
			imgui.BeginChild ('bottom', imgui.ImVec2(215, 115), true) -- Нижний левый прямоугольник
				--imgui.SameLine(40)
				local p_time = ''
				if pInfo.set.premium > os.time() then
					p_time = '{FC7B15}'..Converter(pInfo.set.premium - os.time())
				elseif pInfo.set.premium == 0 then p_time = '{1FDC2E}навсегда'
				else p_time = '{DC4A1F}отсутствует' end
				if pInfo.set.premium - os.time() < 8640000 then
					imgui.TextColoredRGB('Премиум версия: '..p_time)
				else imgui.TextColoredRGB('Премиум версия:\n '..p_time) end
				imgui.NewLine()
				imgui.Text (u8'Пользователей онлайн: '..pTemp.users_online)
			imgui.EndChild()
		imgui.EndChild()
		imgui.SameLine()
		if pTemp.menu_id == 1 then
			imgui.BeginChild ('content', imgui.ImVec2(1072, 587), true) -- Главная

			imgui.EndChild()
		elseif pTemp.menu_id == 3 then -- Настройки
			imgui.BeginChild ('settings_menu', imgui.ImVec2(195, 587), true)
			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00); -- Прозрачные кнопки
			imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.0, 0.5) -- Текст на кнопках по левому краю

			if imgui.ActiveButton (1, u8' Настройки при входе', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 1 end
			if imgui.ActiveButton (2, u8' Основные настройки', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 2 end
			if imgui.ActiveButton (10, u8' Виджет', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 10 end
			if imgui.ActiveButton (3, u8' Быстрая выдача наказаний', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 3 end
			if imgui.ActiveButton (4, u8' Быстрые ответы на репорт', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 4 end
			if imgui.ActiveButton (11, u8' Изменение цветов чата', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 11 end
			if imgui.ActiveButton (5, u8' Трейсеры пуль', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 5 end
			if imgui.ActiveButton (6, u8' Настройки варнингов', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 6 end
			if imgui.ActiveButton (7, u8' Настройки читов', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 7 end
			if imgui.ActiveButton (8, u8' Ввод команд при входе', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 8 end
			if imgui.ActiveButton (9, u8' Горячие клавиши', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 9 end
			if imgui.ActiveButton (12, u8' Сокращенные команды', imgui.ImVec2(180, 20)) then pTemp.submenu_id = 12 end

			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00);
			imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

			imgui.EndChild()
			imgui.SameLine()
			if pTemp.submenu_id == 1 then
				submenu_1()
			elseif pTemp.submenu_id == 2 then
				submenu_2()
			elseif pTemp.submenu_id == 3 then
				submenu_3()
			elseif pTemp.submenu_id == 4 then
				submenu_4()
			elseif pTemp.submenu_id == 5 then
				submenu_5()
			elseif pTemp.submenu_id == 6 then
				submenu_6()
			elseif pTemp.submenu_id == 7 then
				submenu_7()
			elseif pTemp.submenu_id == 8 then
				submenu_8()
			elseif pTemp.submenu_id == 9 then
				submenu_9()
			elseif pTemp.submenu_id == 10 then
				submenu_10()
			elseif pTemp.submenu_id == 11 then
				submenu_11()
			elseif pTemp.submenu_id == 12 then
				submenu_12()
			end
		elseif pTemp.menu_id == 6 then
			imgui.BeginChild ('command_menu', imgui.ImVec2(1072, 587), true)
			imgui.PushTextWrapPos(imgui.GetFontSize() * 73.0)
			imgui.TextUnformatted(u8(ctext))
			imgui.PopTextWrapPos()
			imgui.EndChild()
		elseif pTemp.menu_id == 7 then
			imgui.BeginChild ('table_menu', imgui.ImVec2(1072, 587), true)
	        imgui.PushTextWrapPos(imgui.GetFontSize() * 73.0)
	        imgui.TextUnformatted(u8(itext))
	        imgui.PopTextWrapPos()
			imgui.EndChild()
		end
		imgui.End()
	end
	if win_state['update_info'].v then
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(420, 200), imgui.Cond.FirstUseEver)
		imgui.Begin(u8('Проверка обновления'), win_state['update_info'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)
		if pTemp.update.status then
			imgui.CenterTextColoredRGB('\t\tНайдено обновление {AEFAA5}'..pTemp.update.version..'{FFFFFF} от '..pTemp.update.date..'\t\t')
			imgui.NewLine()
			imgui.NewLine()
			imgui.CenterTextColoredRGB('Описание:')
			imgui.Text(u8('\n'..pTemp.update.description..'\n\n\n'))
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 120)
			if imgui.Button(u8'Установить', imgui.ImVec2(120, 20)) then
				async_http_request('GET', 'https://raw.githubusercontent.com/RaffCor/AHelper_New/master/AHelper.luac', nil,
				function(response)
					local f = assert(io.open(getWorkingDirectory() .. '/AHelper.luac', 'wb'))
					f:write(response.text)
					f:close()
					win_state['main'].v = false
					win_state['update_info'].v = false
					imgui.Process = false
					imgui.ShowCursor = false
					sampAddChatMessage("[AHelper]{FFFFFF} Обновление успешно, скрипт перезагружается", 0x4682B4)
					lua_thread.create (function()
						wait (1000)
						thisScript():reload()
					end)
				end,
				function(err)
					print(err)
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка при обновлении, попробуйте позже.", 0x4682B4)
					return
				end)
				win_state['update_info'].v = false
			end
			imgui.SameLine()

			if imgui.Button(u8'Закрыть', imgui.ImVec2(120, 20)) then win_state['update_info'].v = false end
		else
			imgui.CenterTextColoredRGB('Обновления не найдены. Вы используете актуальную версию')
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 60)
			if imgui.Button(u8'Закрыть', imgui.ImVec2(120, 20)) then win_state['update_info'].v = false end
		end
		imgui.End()
	end
	if win_state['_requests'].v == true then
		local ScreenX, ScreenY = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(ScreenX / 2 , ScreenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600, 505), imgui.Cond.FirstUseEver)
		imgui.Begin(u8"Снятие наказаний", win_state['_requests'], imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		imgui.Text (u8"От кого")
		imgui.SameLine(170)
		imgui.Text (u8"Кому")
		imgui.SameLine(340)
		imgui.Text (u8"Тип")
		imgui.SameLine(425)
		imgui.Text (u8"Причина")
		imgui.NewLine()
		imgui.Separator()
		for i in ipairs(rVar.pAdmin) do
			if rVar.pStatusExt[i] ~= "completed" then
				if tonumber(rVar.pNumAdmin[i]) == pInfo.info.playerAccoutNumber then imgui.TextColored(imgui.ImColor(149, 245, 194, 255):GetVec4(), string.format ("%s", rVar.pAdmin[i]))
				--elseif pInfo.info.accept == false and (rVar.pType[i] == "/unban" or rVar.pType[i] == "/uncban") then imgui.TextColored(imgui.ImColor(247, 77, 57, 255):GetVec4(), string.format ("%s", rVar.pAdmin[i]))
				else imgui.Text(string.format ("%s", rVar.pAdmin[i])) end
				imgui.SameLine(170)
				if tonumber(rVar.pNumAdmin[i]) == pInfo.info.playerAccoutNumber then imgui.TextColored(imgui.ImColor(149, 245, 194, 255):GetVec4(), string.format ("%s", rVar.pPlayer[i]))
				--elseif pInfo.info.accept == false and (rVar.pType[i] == "/unban" or rVar.pType[i] == "/uncban") then imgui.TextColored(imgui.ImColor(247, 77, 57, 255):GetVec4(), string.format ("%s", rVar.pAdmin[i]))
				else imgui.Text(string.format ("%s", rVar.pPlayer[i])) end
				imgui.SameLine(340)
				if tonumber(rVar.pNumAdmin[i]) == pInfo.info.playerAccoutNumber then imgui.TextColored(imgui.ImColor(149, 245, 194, 255):GetVec4(), string.format ("%s", rVar.pType[i]))
			--	elseif pInfo.info.accept == false and (rVar.pType[i] == "/unban" or rVar.pType[i] == "/uncban") then imgui.TextColored(imgui.ImColor(247, 77, 57, 255):GetVec4(), string.format ("%s", rVar.pAdmin[i]))
				else imgui.Text(string.format ("%s", rVar.pType[i])) end
				imgui.SameLine(425)
				if tonumber(rVar.pNumAdmin[i]) == pInfo.info.playerAccoutNumber then imgui.TextColored(imgui.ImColor(149, 245, 194, 255):GetVec4(), string.format ("%s", rVar.pReason[i]))
				--elseif pInfo.info.accept == false and (rVar.pType[i] == "/unban" or rVar.pType[i] == "/uncban") then imgui.TextColored(imgui.ImColor(247, 77, 57, 255):GetVec4(), string.format ("%s", rVar.pAdmin[i]))
				else imgui.Text(string.format ("%s", rVar.pReason[i])) end
				imgui.Separator()
			end
		end
		if imgui.Button (u8"Снять наказания", imgui.ImVec2(-1, 22)) then
			Show_Requests()
		end
		imgui.End()
	end
	if win_state['fast'].v == true then
		imgui.SetNextWindowSize(imgui.ImVec2(422, 400), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8'Меню быстрых ответов', win_state['fast'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
		imgui.Text(u8"[Информация: изменить ответы можно в меню настроек скрипта]")
		for i, k in ipairs(answers) do
			if imgui.Button(string.format ("%s", u8(k.title)), imgui.ImVec2(-1, 22)) then
				sampSendChat (string.format ("/pm %d %s", pTemp.AnswerID, k.text))
				--print (string.format ("/pm %d %s", pTemp.AnswerID, k.text))
				win_state['fast'].v = false
			end
		end
		imgui.End()
	end
	if win_state['cheat'].v == true then
		if sampIsPlayerConnected(pTemp.tempCheatID) and pTemp.tempCheatID ~= sInfo.MAX_PLAYERS then
			imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
			imgui.SetNextWindowSize(imgui.ImVec2(286, 500), imgui.Cond.FirstUseEver)
			imgui.Begin(getPlayerName (pTemp.tempCheatID)..'['..pTemp.tempCheatID..']', win_state['cheat'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.65, 0.16, 0.16, 1.00);
			for i, k in ipairs (bans) do
				local p_type = ''
				k.type = tonumber (k.type)
				if k.type == 1 then p_type = '/kick'
				elseif k.type == 2 then p_type = '/skick'
				elseif k.type == 3 then p_type = '/jail'
				elseif k.type == 4 then p_type = '/mute'
				elseif k.type == 5 then
					p_type = '/ban'
					pTemp.punish.ban = true
				elseif k.type == 6 then
					p_type = '/sban'
					pTemp.punish.sban = true
				elseif k.type == 7 then
					p_type = '/cban'
					pTemp.punish.cban = true
				elseif k.type == 8 then
					p_type = '/scban'
					pTemp.punish.scban = true
				end
				pTemp.punish.days = tonumber(k.time)
				if imgui.Button(u8(k.reason..' ('..p_type..' '..k.time..')##'..i), imgui.ImVec2(270, 22)) then
					local final_cmd = p_type..' '..pTemp.tempCheatID..' '..k.time..' '..k.reason
					sampSendChat (final_cmd)
					pTemp.tempCheatID = sInfo.MAX_PLAYERS
					win_state['cheat'].v = false
					print ('выполнено')
				end
			end
			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00);
			imgui.End()
		end


	end
	if win_state['table'].v then
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400, 500), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'test', win_state['table'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus)
		imgui.TextWrapped (u8(itext))
		imgui.End()
	end
	if win_state['list'].v then
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(405, 500), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Список оскорблений/упоминаний родных', win_state['list'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus)
		local result = {}
		for i, v in ipairs (rlist) do
			local messages = {}
			local rsl = false
			for ii, vv in ipairs (result) do
				if vv.nick == v.nick then rsl = true end
			end
			if not rsl then
				local count = 1
				table.insert (messages, {
					message = v.mess,
					time = v.time
				})
				for j, k in ipairs (rlist) do
					if v.nick == k.nick and i ~= j then
						--sampAddChatMessage (k.mess, -1)
						table.insert (messages, {
							message = k.mess,
							time = k.time
						})
						count = count + 1
					end
				end
				local status = ''
				if v.online then status = '{0FA223}online{FFFFFF}'
				else status = '{FB2B13}offline{FFFFFF}' end
				imgui.TextColoredRGB (v.nick..' ['..status..']')
				imgui.SameLine (265)
				if imgui.Button (u8'Мут##'..i) then
					if v.online then
						sampSendChat('/mute '..v.id..' 180 Упоминание родных')
						--sampAddChatMessage('/mute '..v.id..' 180 Упоминание родных', -1)
					else
						if pInfo.info.adminLevel >= 3 then
							sampProcessChatInput('/ofmute '..v.nick..' 180 Упоминание родных')
							--sampAddChatMessage('/ofmute '..v.nick..' 180 Упоминание родных', -1)
						else
							sampAddChatMessage('[AHelper] {FFFFFF}Выдача мута оффлайн доступна с 3 уровня админки', 0x4682B4)
						end
					end
				end
				imgui.SameLine()
				if imgui.Button (u8'Бан##'..i) then
					if pInfo.info.accept then
						if v.online then
							sampSendChat('/ban '..v.id..' 30 Оскорбление родных')
							--sampAddChatMessage('/ban '..v.id..' 30 Оскорбление родных', -1)
						else
							if pInfo.info.adminLevel >= 3 then
								sampProcessChatInput('/ofban '..v.nick..' 30 Оскорбление родных')
								--sampAddChatMessage('/ofban '..v.nick..' 30 Оскорбление родных', -1)
							else
								sampAddChatMessage('[AHelper] {FFFFFF}Выдача бана оффлайн доступна с 3 уровня админки', 0x4682B4)
							end
						end
					else
						sampAddChatMessage('[AHelper] {FFFFFF}У вас нет доступа к блокировкам', 0x4682B4)
					end
				end
				imgui.SameLine()
				if imgui.Button (u8'Удалить##'..i) then
					table.remove (rlist, i)
				end
				local chtext = u8'Сообщение'
				if count > 1 then chtext = u8'Сообщения' end
				if imgui.CollapsingHeader (chtext..'##'..i) then
					for j, k in ipairs (messages) do
						imgui.TextWrapped ('['..k.time..'] '..u8(k.message))
					end
				end
				imgui.Separator()
				--imgui.NewLine()
				table.insert (result, {
					nick = v.nick
				})
			end
			--::continue::
		end
		imgui.End()
	end
	if win_state['chat'].v then
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600, 550), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'AHelper | Чат между серверами', win_state['chat'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus)
		--chat_text = chat_text_temp
		imgui.BeginChild ('main child', imgui.ImVec2(583, 482), false)
		imgui.TextColoredRGB(pTemp.chat.chat_text)
		local maxy = imgui.GetScrollMaxY()
		if one ~= true then
			imgui.SetScrollHere ('1.0')
			one = true
		end
		imgui.EndChild()
		imgui.SetCursorPosY(imgui.GetWindowHeight() - 32)
		imgui.PushItemWidth(480)
		imgui.Separator()
		imgui.InputText ('##input', iVar.chat.input_chat, imgui.InputTextFlags.EnterReturnsTrue)
		imgui.SameLine()
		if imgui.Button (u8'Отправить', imgui.ImVec2 (100, 20)) then
			if iVar.chat.input_chat.v:len() > 0 then
				if pTemp.chat.chat_delay <= os.time() then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 144)
					bitstream:write('string', u8:decode (iVar.chat.input_chat.v)..' | '..getLocalPlayerName()..' | '..srv)
					pTemp.chat.chat_text_temp = ""
					client:send_packet(2, bitstream)
					pTemp.chat.chat_text_temp = pTemp.chat.chat_text
					lua_thread.create (function()
						while pTemp.chat.chat_text_temp == pTemp.chat.chat_text do
							wait (0)
							one = false
						end
					end)
					iVar.chat.input_chat.v = ''
					imgui.SetKeyboardFocusHere (true)
					pTemp.chat.chat_delay = os.time() + 1
				else
					sampAddChatMessage("[AHelper] {FFFFFF}Сообщения можно отправлять один раз в секунду", 0x4682B4)
				end
			end
		end
		imgui.End()
	end
	if win_state['checker'].v == true then
		imgui.SetNextWindowSize(imgui.ImVec2 (720, 450), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2 , screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8'Чекер игроков', win_state['checker'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
		for i, k in ipairs(players) do
			imgui.PushItemWidth(135)
			imgui.InputText(string.format (u8"Ник##%d", i),iVar.checker.change_players[i])
			imgui.SameLine()
			imgui.PushItemWidth(170)
			imgui.InputText(u8'Примечание##'..i, iVar.checker.change_desc[i])
			imgui.SameLine()
			imgui.Checkbox(u8'Полное соответствие##'..i, iVar.checker.change_full[i])
			imgui.SameLine()
			if imgui.Button(u8(string.format ("Сохранить##%d", i))) then
				local g__admin = false
				for j in ipairs (g_admin) do
					if iVar.checker.change_players[i].v == g_admin[j]  and getLocalPlayerName() ~= 'Ken_Higa' then g__admin = true end
				end
				if g__admin == false then
					local status
					if iVar.checker.change_full[i].v == true then status = 1 else status = 0 end
					local upd_rep = {}
					upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&players="..u8:decode(iVar.checker.change_players[i].v).."&description="..u8:decode(iVar.checker.change_desc[i].v).."&full="..status.."&id="..k.id
					upd_rep.headers = {
						['content-type']='application/x-www-form-urlencoded'
					}
					async_http_request("POST", sInfo.url..'/upd_checker.php', upd_rep,
					function (response)
						if u8:decode(response.text):find("Данные обновлены") then
							--load_checker()
							pTemp.user.loadChecker = true
							sampAddChatMessage("[AHelper] {FFFFFF}Ник игрока сохранен", 0x4682B4)
						elseif u8:decode(response.text):find("Запрос не сработал") then
							sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
						elseif u8:decode(response.text):find("Не получены данные") then
							sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#6). Работа скрипта остановлена.", 0xFF0000)
							print("RepUpd ErrTrue: "..u8:decode(response.text))
							thisScript():unload()
						end
					end,
					function (err)

					end)
				else
					sampAddChatMessage("[AHelper] {FFFFFF}Запрет на добавление этого ника", 0xFF0000)
				end
			end
			imgui.SameLine()
			if imgui.Button(u8(string.format ("Удалить##%d", i))) then
				local upd_rep = {}
				upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id="..k.id
				upd_rep.headers = {
					['content-type']='application/x-www-form-urlencoded'
				}
				async_http_request('POST', sInfo.url..'/del_checker.php', upd_rep,
				function (response)
					if u8:decode(response.text):find("Данные удалены") then
						--load_checker()
						pTemp.user.loadChecker = true
						sampAddChatMessage("[AHelper] {FFFFFF}Ник игрока удален", 0x4682B4)
					elseif u8:decode(response.text):find("Запрос не сработал") then
						sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
					elseif u8:decode(response.text):find("Не получены данные") then
						sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#7). Работа скрипта остановлена.", 0xFF0000)
						print("RepUpd ErrTrue: "..u8:decode(response.text))
						thisScript():unload()
					end
				end,
				function (err)

				end)

			end
			imgui.Separator()
			--imgui.NewLine()
		end
		imgui.SetCursorPosX(imgui.GetWindowWidth()/2-60)
		if imgui.Button(u8'Добавить новый ник') then
			local upd_rep = {}
			upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			upd_rep.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request('POST', sInfo.url..'/add_checker.php', upd_rep,
			function (response)
				if u8:decode(response.text):find("Данные добавлены") then
					--load_checker()
					pTemp.user.loadChecker = true
					sampAddChatMessage("[AHelper] {FFFFFF}Новая строка добавлена", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#7). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)

			end)
		end
		imgui.End()
	end
	if pInfo.set.clock == true or pInfo.set.clock == '1' or pTemp.objectSetPos == 5 then
		table_style()
		if pInfo.set.clX ~= 0 then pos = imgui.ImVec2 (pInfo.set.clX, pInfo.set.clY)
		else pos = imgui.ImVec2 (ScreenX/1.238709677419355, ScreenY/1.963636363636364) end
		imgui.SetNextWindowSize(imgui.ImVec2(300, 145), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(pos)
		imgui.Begin('Widget', win_state['widget'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoBringToFrontOnFocus)
		_, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
		nick = getLocalPlayerName()
		lvl = sampGetPlayerScore(myID)
		imgui.SetWindowFontScale (iVar.widget.sizeWidget.v)
		imgui.Text(u8'Ник:')
		--imgui.SetWindowFontScale (1.0)
		imgui.SameLine()
		imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..nick..'')
		imgui.Text(u8'ID:')
		imgui.SameLine()
		imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..myID..'')
		if pInfo.set.widget.kills == true or pInfo.set.widget.kills == '1' then
			imgui.Text(u8'Убийств:')
			imgui.SameLine()
			imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..lvl..'')
		end
		if pInfo.set.widget.time_s == true or pInfo.set.widget.time_s == '1' then
			imgui.Text(u8'Время за сеанс:')
			imgui.SameLine()
			imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..FormatTime(os.clock())..'')
		end
		imgui.Separator()
		if pInfo.set.widget.pm_all == true or pInfo.set.widget.pm_all == '1' then
			imgui.Text (u8"Ответов на репорт всего:")
			imgui.SameLine()
			imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..pTemp.count_reports_all..'')
		end
		if pInfo.set.widget.pun_all == true or pInfo.set.widget.pun_all == '1' then
			imgui.Text (u8"Наказаний всего:")
			imgui.SameLine()
			imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..pTemp.count_punish_all..'')
		end
		if (pInfo.set.widget.pm_all == true or pInfo.set.widget.pm_all == '1') or (pInfo.set.widget.pun_all == true or pInfo.set.widget.pun_all == '1') then imgui.Separator() end
		if pInfo.set.widget.pm_day == true or pInfo.set.widget.pm_day == '1' then
			imgui.Text (u8"Количество ответов на репорт за сегодня:")
			imgui.SameLine()
			imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..pTemp.count..'')
		end
		if pInfo.set.widget.pun_day == true or pInfo.set.widget.pun_day == '1' then
			imgui.Text(u8'Наказаний за сегодня:')
			imgui.SameLine()
			imgui.TextColored(imgui.ImColor(255, 229, 160, 255):GetVec4(), u8''..pTemp.count_punish..'')
		end
		if (pInfo.set.widget.pm_day == true or pInfo.set.widget.pm_day == '1') or (pInfo.set.widget.pun_day == true or pInfo.set.widget.pun_day == '1') then imgui.Separator() end
		if pInfo.set.widget.datetime == true or pInfo.set.widget.datetime == '1' then imgui.Text(os.date(u8"Дата и время: %d.%m.%y %H:%M:%S", os.time())) end
		if pInfo.set.widget.in_s == true or pInfo.set.widget.in_s == '1' then
			--imgui.Separator()
			imgui.Text(u8"Инвиз: ")
			imgui.SameLine()
			local a_status = pTemp.in_ac and " " or "{FB2B13}(неактивен)"
			if iVar.cheat.invisible_onfoot.v == false then
				imgui.TextColored(imgui.ImColor(251, 43, 19, 255):GetVec4(), u8"выключен")
				imgui.SameLine()
				imgui.TextColoredRGB (' ')
			else
				imgui.TextColored(imgui.ImColor(15, 162, 35, 255):GetVec4(), u8"включен")
				imgui.SameLine()
				imgui.TextColoredRGB (a_status)
				--imgui.NewLine()

			end
		end
		if pInfo.set.widget.server_status == true or pInfo.set.widget.server_status == '1' then
			imgui.Separator()
			local s_status = ''
			if pTemp.slnet_conn == 2 then s_status = '{0FA223}подключено'
			elseif pTemp.slnet_conn == 1 then s_status = '{E3DA1C}выполняется подключение'
			else s_status = '{FB2B13}отключено' end
			imgui.TextColoredRGB('Статус сервера: '..s_status)
		end
		if pInfo.set.widget.chat == true or pInfo.set.widget.chat == '1' then
			imgui.Separator()
			if imgui.Button(fa.ICON_FA_COMMENTS) then win_state['chat'].v = not win_state['chat'].v end
		end
		--imgui.SetWindowFontScale (1.0)
		imgui.End()
		theme()
	end
	if (pInfo.set.re_panel_change == true or pInfo.set.re_panel_change == '1') and pInfo.set.re_panel_style == 1 and tonumber (pTemp.spec_id) < sInfo.MAX_PLAYERS or pTemp.objectSetPos == 3 then
		left_panel_style()
		if pInfo.set.lpX ~= 0 then pTemp.change_re_panel_pos = imgui.ImVec2(pInfo.set.lpX, pInfo.set.lpY) end
		if win_state['re_panel'].v then
			imgui.SetNextWindowSize(imgui.ImVec2 (285, 240), imgui.Cond.FirsUseEver)
			imgui.SetNextWindowPos(pTemp.change_re_panel_pos, imgui.Cond.FirsUseEver, imgui.ImVec2(0.5, 0.5))
			imgui.Begin('##re_panel', win_state['re_panel'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove+ imgui.WindowFlags.NoBringToFrontOnFocus+ imgui.WindowFlags.NoTitleBar+ imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.AlwaysAutoResize)
			if imgui.Button(u8"Статистика", imgui.ImVec2(-1, 25)) then sampSendClickTextdraw(7) end
			if imgui.Button(u8"Забанить аккаунт", imgui.ImVec2(-1, 25)) then
				sampSendClickTextdraw(8)
				if pTemp.spec_id ~= sInfo.MAX_PLAYERS then add_logs ("/ban", getLocalPlayerName(), getPlayerName(pTemp.spec_id), 30, "Cheat") end
			end
			if imgui.Button(u8"Забанить аккаунт и IP", imgui.ImVec2(-1, 25)) then
				sampSendClickTextdraw(9)
				if pTemp.spec_id ~= sInfo.MAX_PLAYERS then add_logs ("/cban", getLocalPlayerName(), getPlayerName(pTemp.spec_id), 30, "Cheat") end
			end
			if imgui.Button(u8"Подкинуть", imgui.ImVec2(-1, 25)) then sampSendClickTextdraw(10) end
			if imgui.Button(u8"Заспавнить", imgui.ImVec2(-1, 25)) then sampSendClickTextdraw(11) end
			if imgui.Button(u8"Информация об IP", imgui.ImVec2(-1, 25)) then sampSendClickTextdraw(12) end
			if imgui.Button(u8"Выход из слежки", imgui.ImVec2(-1, 25)) then sampSendClickTextdraw(13) end
			if imgui.Button(u8"Предыдущий") then sampSendClickTextdraw(6) end
			imgui.SameLine()
			if imgui.Button(u8"Обновить") then sampSendClickTextdraw(26) end
			imgui.SameLine()
			if imgui.Button(u8"Следующий") then sampSendClickTextdraw(25) end
			imgui.End()
		end
		theme()
	end
	if pInfo.set.right_panel_change == true or pInfo.set.right_panel_change == '1' or pTemp.objectSetPos == 4 then
		if tonumber (pTemp.spec_id) < sInfo.MAX_PLAYERS or pTemp.objectSetPos == 4 then
			table_style()
			if pInfo.set.rpX ~= 0 then pTemp.change_re_panel_pos_right = imgui.ImVec2(pInfo.set.rpX, pInfo.set.rpY) end
			if win_state['right_panel'].v then
				imgui.SetNextWindowSize(imgui.ImVec2 (420, 266), imgui.Cond.FirsUseEver)
				imgui.SetNextWindowPos(pTemp.change_re_panel_pos_right, imgui.Cond.FirsUseEver, imgui.ImVec2(0.5, 0.5))
				imgui.Begin(pTemp.re_panel.nick..' ['..pTemp.re_panel.id..']', win_state['right_panel'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
				imgui.Columns(4, "right_panel")
				imgui.Separator()
				imgui.Text(u8"Убийств:") imgui.NextColumn()
				if pTemp.re_panel.kills ~= nil and pTemp.re_panel.kills ~= 0 then imgui.Text(pTemp.re_panel.kills)
				else imgui.Text("0") end
				imgui.NextColumn()
				imgui.Text(u8"Локация:") imgui.NextColumn()
				imgui.Text(pTemp.re_panel.loc) imgui.NextColumn()
				imgui.Separator()
				imgui.Text(u8"Смертей:") imgui.NextColumn()
				if pTemp.re_panel.deaths ~= nil and pTemp.re_panel.deaths ~= 0 then imgui.Text(pTemp.re_panel.deaths)
				else imgui.Text("0") end
				imgui.NextColumn()
				imgui.Text(u8"Скилл:") imgui.NextColumn()
				imgui.Text(pTemp.re_panel.skill)
				imgui.NextColumn()
				imgui.Separator()
				if pTemp.spec_veh == nil then imgui.Text(u8"Здоровье:")
				else imgui.Text(u8"Здоровье / авто:") end
				imgui.NextColumn()
				if pTemp.re_panel.health ~= nil and pTemp.re_panel.health ~= 0 and pTemp.vehicle_health ~= nil then
					if pTemp.spec_veh == nil then imgui.Text(string.format ("%d", pTemp.re_panel.health))
					else imgui.Text(string.format ("%d / %d", pTemp.re_panel.health, pTemp.vehicle_health)) end
				else imgui.Text("0") end
				imgui.NextColumn()
				imgui.Text(u8"Выстрелов:") imgui.NextColumn()
				if pTemp.re_panel.shot ~= nil and pTemp.re_panel.shot ~= 0 then imgui.Text(pTemp.re_panel.shot)
				else imgui.Text("0") end
				imgui.NextColumn()
				imgui.Separator()
				imgui.Text(u8"Броня:") imgui.NextColumn()
				if pTemp.re_panel.armour ~= nil and pTemp.re_panel.armour ~= 0 then imgui.Text(string.format ("%d", pTemp.re_panel.armour))
				else imgui.Text("0") end
				imgui.NextColumn()
				imgui.Text(u8"Попаданий:") imgui.NextColumn()
				if pTemp.re_panel.hit ~= nil and pTemp.re_panel.hit ~= 0 then imgui.Text(pTemp.re_panel.hit..'%')
				else imgui.Text("0%") end
				imgui.NextColumn()
				imgui.Separator()
				--print (spec_veh)
				if pTemp.spec_veh == nil then imgui.Text(u8"Скорость:")
				else imgui.Text(u8"Скорость (авто):") end
				imgui.NextColumn()
				if pTemp.re_panel.speed ~= nil and pTemp.re_panel.speed ~= 0 and pTemp.veh_speed ~= nil and pTemp.max_veh_speed ~= nil then
					if pTemp.spec_veh == nil then imgui.Text(string.format ("%d", pTemp.re_panel.speed))
					else imgui.Text(string.format ("%d / %d", pTemp.veh_speed, pTemp.max_veh_speed)) end
				else imgui.Text("0") end
				imgui.NextColumn()
				imgui.Text(u8"Оружие/пт:") imgui.NextColumn()
				if pTemp.re_panel.ammo ~= nil and pTemp.re_panel.ammo ~= 0 and pTemp.re_panel.weapon ~= nil then imgui.Text(pTemp.re_panel.weapon..', '..pTemp.re_panel.ammo)
				else imgui.Text (u8"Неизвестно, 0") end
				imgui.NextColumn()
				imgui.Separator()
				imgui.Text(u8"Время сессии:") imgui.NextColumn()
				if pTemp.player_time_session[tonumber (pTemp.re_panel.id)] > 0 then imgui.Text(Converter (os.time() - pTemp.player_time_session[tonumber (pTemp.re_panel.id)]))
				else imgui.Text (u8"Неизвестно") end
				imgui.NextColumn()
				imgui.Text(u8"Скин:") imgui.NextColumn()
				if pTemp.re_panel.skin ~= nil and pTemp.re_panel.skin ~= 0 then imgui.Text(string.format ("%d", pTemp.re_panel.skin))
				else imgui.Text (u8"Неизвестно") end
				imgui.NextColumn()
				imgui.Separator()
				imgui.Text(u8"Пинг:") imgui.NextColumn()
				if pTemp.re_panel.ping ~= nil and pTemp.re_panel.ping ~= 0 then imgui.Text(pTemp.re_panel.ping)
				else imgui.Text (u8"Неизвестно") end
				imgui.NextColumn()
				imgui.Text(u8"Потеря пакетов:") imgui.NextColumn()
				imgui.Text(pTemp.re_panel.package_loss) imgui.NextColumn()
				imgui.Separator()
				imgui.Text(u8"FPS:") imgui.NextColumn()
				if pTemp.re_panel.fps ~= nil and pTemp.re_panel.fps ~= 0 then imgui.Text(pTemp.re_panel.fps)
				else imgui.Text (u8"Неизвестно") end
				imgui.NextColumn()
				imgui.Text(u8"IP:") imgui.NextColumn()
				imgui.Text(pTemp.re_panel.ip) imgui.NextColumn()
				imgui.Separator()
				imgui.End()
			end
			theme()
		end
	end
end



function FormatTime(time)
    local timezone_offset = 86400 - os.date('%H', 0) * 3600
    local time = time + timezone_offset
    return  os.date((os.date("%H",time) == "00" and '%M:%S' or '%H:%M:%S'), time)
end

function enableFPSUnlock()
	local result, samphandle = loadDynamicLibrary("samp.dll")
	if result then
		local ihaveasociophobia = samphandle + 0x9D9D0
		writeMemory(ihaveasociophobia, 4, 0x5051FF15, 1)
		writeMemory(0xBAB318, 1, 0, 1)
		writeMemory(0x53E94C, 1, 0, 1)
	else
		sampAddChatMessage("[AHelper] {FFFFFF}FPSUnlock не активирован: не удалось открыть библиотеку SA-MP", 0x4682B4)
	end
end

function getStrByState(keyState)
	if keyState == 0 then
		return "Выкл"
	end
	return "Вкл"
end

function submenu_1()
	imgui.BeginChild ('settings_content_aut', imgui.ImVec2(872, 587), true)
	imgui.SameLine (17)
	if imgui.Checkbox (u8'Автоматически заступать на дежурство (/duty)', iVar.ath.duty) then
		pInfo.set.AutoDuty = iVar.ath.duty.v
		if pInfo.set.AutoDuty then savedata ('autoduty', 1)
		else savedata ('autoduty', 0) end
		local a_status = pInfo.set.AutoDuty and "включено" or "выключено"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАвтоматическое заступление на дежурство '..a_status, 5)
	end
	if iVar.ath.duty.v then
		imgui.PushItemWidth(30)
		imgui.PushAllowKeyboardFocus(false)
		imgui.NewLine()
		imgui.SameLine (17)
		if imgui.InputText(u8"Скин на дежурстве##SkinDuty", iVar.ath.dutySkin, imgui.InputTextFlags.CharsDecimal) then
			if iVar.ath.dutySkin.v:len() > 0 then
				local skin = tonumber(iVar.ath.dutySkin.v)
				if skin > 0 and skin <= 311 and skin ~= 74 then
					pInfo.set.SkinDuty = skin
					savedata ('skin', 2)
				else
					iVar.ath.dutySkin.v = ''
				end
			end
		end
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Телепортироваться в админ-интерьер (/aint)', iVar.ath.aint) then
		pInfo.set.AutoAint = iVar.ath.aint.v
		if pInfo.set.AutoAint then savedata ('autoaint', 1)
		else savedata ('autoaint', 0) end
		local a_status = pInfo.set.AutoAint and "включен" or "выключен"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАвтоматический телепорт в админ-интерьер '..a_status, 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Выключать сообщения (/togphone)', iVar.ath.togphone) then
		pInfo.set.AutoTogphone = iVar.ath.togphone.v
		if pInfo.set.AutoTogphone then savedata ('autotogphone', 1)
		else savedata ('autotogphone', 0) end
		local a_status = pInfo.set.AutoTogphone and "активно" or "неактивно"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАвтоматическое выключение сообщений '..a_status, 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Включать чаты банд (/fon)', iVar.ath.fon) then
		pInfo.set.AutoFon = iVar.ath.fon.v
		if pInfo.set.AutoFon then savedata ('autofon', 1)
		else savedata ('autofon', 0) end
		local a_status = pInfo.set.AutoFon and "активно" or "неактивно"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАвтоматическое включение чатов банд '..a_status, 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Включать сообщения игроков (/smson)', iVar.ath.smson) then
		pInfo.set.AutoSmson = iVar.ath.smson.v
		if pInfo.set.AutoSmson then savedata ('smson', 1)
		else savedata ('smson', 0) end
		local a_status = pInfo.set.AutoSmson and "активно" or "неактивно"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАвтоматическое включение сообщений игроков '..a_status, 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'FPS Unlock', iVar.main_settings.fpsunlock) then
		pInfo.set.fps_unlock = iVar.main_settings.fpsunlock.v
		if pInfo.set.fps_unlock then savedata ('fps_unlock', 1)
		else savedata ('fps_unlock', 0) end
		local a_status = pInfo.set.fps_unlock and "активен" or "неактивен"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nFPS Unlock '..a_status, 5)
		if not pInfo.set.fps_unlock then sampAddChatMessage('[AHelper] {FFFFFF}Для выключения необоходимо перезапустить игру', 0x4682B4)
		else enableFPSUnlock() end
	end
	imgui.NewLine()
	imgui.Separator()
	imgui.SameLine(17)

	imgui.NewLine()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	local capsState = ffi.C.GetKeyState(20)
	local success = ffi.C.GetKeyboardLayoutNameA(KeyboardLayoutName)
	local errorCode = ffi.C.GetLocaleInfoA(tonumber(ffi.string(KeyboardLayoutName), 16), 0x00000002, LocalInfo, BuffSize)
	local localName = ffi.string(LocalInfo)
	imgui.Text (u8(string.format ("Капс: %s | Язык: %s", getStrByState(capsState), string.match(localName, "([^%(]*)"))))
	imgui.NewLine()
	imgui.PushItemWidth(150)
	imgui.PushAllowKeyboardFocus(false)
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Автоматический ввод пароля авторизации', iVar.ath.password_b) then
		local pass = tostring (iVar.ath.password.v)
		if pass:len() == 0 then
			sampAddChatMessage("[AHelper] {FFFFFF}Ошибка: пустое поле с паролем", 0x4682B4)
			iVar.ath.password_b.v = false
		else
			if iVar.ath.password_b.v == true then
				aInfo.info.lPass = pass
				aInfo.set.lPass_On = true
				aInfo.info.IP = sampGetCurrentServerAddress()
				inicfg.save(aInfo, "\\AHelper\\settings.ini")
				sampAddChatMessage("[AHelper] {FFFFFF}При авторизации пароль будет введён автоматически", 0x4682B4)
			else
				aInfo.info.lPass = ""
				aInfo.set.lPass_On = false
				iVar.ath.password.v = ''
				inicfg.save(aInfo,"AHelper\\settings.ini")
				sampAddChatMessage("[AHelper] {FFFFFF}При авторизации пароль не будет вводиться автоматически", 0x4682B4)
			end
		end
	end
	imgui.SameLine(310)
	if not pTemp.show_pass then imgui.InputText("##login_pass", iVar.ath.password, imgui.InputTextFlags.Password + imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.CharsNoBlank)
	else imgui.InputText("##login_pass", iVar.ath.password, imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.CharsNoBlank) end
	imgui.SameLine()
	local icon = ""
	if not pTemp.show_pass then icon = fa.ICON_FA_EYE_SLASH
	else icon = fa.ICON_FA_EYE end
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00); -- Прозрачные кнопки
	if imgui.Button(icon) then pTemp.show_pass = not pTemp.show_pass end
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00);

	if iVar.ath.password_b.v then
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Автоматический спавн', iVar.ath.a_spawn) then
			aInfo.set.aSpawn = iVar.ath.a_spawn.v
			if aInfo.set.aSpawn == true then sampAddChatMessage("[AHelper] {FFFFFF}При авторизации вы будете заспавнены автоматически", 0x4682B4)
			else sampAddChatMessage("[AHelper] {FFFFFF}При авторизации вы не будете спавниться автоматически", 0x4682B4) end
			inicfg.save(aInfo, "AHelper\\settings.ini")
		end
		if iVar.ath.a_spawn.v then
			imgui.NewLine()
			imgui.SameLine(17)
			local type_spawn = {"DeathMatch", "Antic + C", "Fast", "Pro", "OneShot", "GangWar"}
			if imgui.Combo (u8'Режим', iVar.ath.type_spawn, type_spawn) then
				aInfo.set.typeSpawn = iVar.ath.type_spawn.v + 1
				inicfg.save(aInfo, "AHelper\\settings.ini")
			end
			imgui.SameLine()
			if iVar.ath.type_spawn.v <= 4 then
				imgui.PushItemWidth(30)
				imgui.PushAllowKeyboardFocus(false)
				if imgui.InputText(u8"Номер локации (1-100)##DMLOC", iVar.ath.dm_loc, imgui.InputTextFlags.CharsDecimal) then
					if iVar.ath.dm_loc.v:len() > 0 then
						local loc = tonumber(iVar.ath.dm_loc.v)
						if loc > 0 and loc <= 100 then
							aInfo.set.dmLoc = loc
							inicfg.save(aInfo, "AHelper\\settings.ini")
						else
							iVar.ath.dm_loc.v = ''
						end
					end
				end
				imgui.SameLine()
				imgui.PushItemWidth(30)
				imgui.PushAllowKeyboardFocus(false)
				if imgui.InputText(u8"ID скина (1-311)##DMSKIN", iVar.ath.dm_skin, imgui.InputTextFlags.CharsDecimal) then
					if iVar.ath.dm_skin.v:len() > 0 then
						local skin = tonumber(iVar.ath.dm_skin.v)
						if skin > 0 and skin <= 311 and skin ~= 74 then
							aInfo.set.dmSkin = skin
							inicfg.save(aInfo, "AHelper\\settings.ini")
						else
							iVar.ath.dm_skin.v = ''
						end
					end
				end
			else
				local gang_name = {"Grove", "Ballas", "Vagos", "Aztec"}

				imgui.PushItemWidth(90)
				if imgui.Combo(u8'Банда', iVar.ath.gw_gang, gang_name) then
					aInfo.set.gwGang = iVar.ath.gw_gang.v + 1
					inicfg.save(aInfo, "AHelper\\settings.ini")
				end
			end
			imgui.NewLine()
		end
	end

	imgui.NewLine()
	imgui.PushItemWidth(150)
	imgui.PushAllowKeyboardFocus(false)
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Автоматический ввод админ-пароля', iVar.ath.a_password_b) then
		local pass = tostring (iVar.ath.a_password.v)
		if pass:len() == 0 then
			sampAddChatMessage("[AHelper] {FFFFFF}Ошибка: пустое поле с паролем", 0x4682B4)
			iVar.ath.a_password_b.v = false
		else
			if iVar.ath.a_password_b.v == true then
				aInfo.info.aPass = pass
				aInfo.set.aPass_On = true
				inicfg.save(aInfo, "AHelper\\settings.ini")
				sampAddChatMessage("[AHelper] {FFFFFF}При авторизации админ пароль будет введён автоматически", 0x4682B4)
			else
				aInfo.info.aPass = ""
				aInfo.set.aPass_On = false
				inicfg.save(aInfo, "AHelper\\settings.ini")
				sampAddChatMessage("[AHelper] {FFFFFF}При авторизации админ пароль не будет вводиться автоматически", 0x4682B4)
			end
		end
	end
	imgui.SameLine(310)
	if not pTemp.show_pass_a then imgui.InputText("##admin_pass", iVar.ath.a_password, imgui.InputTextFlags.Password + imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.CharsNoBlank)
	else imgui.InputText("##admin_pass", iVar.ath.a_password, imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.CharsNoBlank) end
	imgui.SameLine()
	local icon_a = ""
	if not pTemp.show_pass_a then icon_a = fa.ICON_FA_EYE_SLASH
	else icon_a = fa.ICON_FA_EYE end
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00); -- Прозрачные кнопки
	if imgui.Button(icon_a..'##a') then pTemp.show_pass_a = not pTemp.show_pass_a end
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00);
	imgui.EndChild()
end

function submenu_2()
	imgui.BeginChild ('settings_content_main', imgui.ImVec2(872, 587), true)
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Конвертер секунд в минуты в /infmute и /infjail', iVar.main_settings.convert) then
		pInfo.set.converter = iVar.main_settings.convert.v
		if pInfo.set.converter then savedata ('converter', 1)
		else savedata ('converter', 0) end
		local a_status = pInfo.set.converter and "активен" or "неактивен"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nКонвертер секунд в минуты '..a_status, 5)
	end
	imgui.SameLine(400)
	if imgui.Checkbox(u8'Скрывать IP-адреса', iVar.main_settings.hideip) then
		pInfo.set.AutoHideIP = iVar.main_settings.hideip.v
		if pInfo.set.AutoHideIP then savedata ('hideip', 1)
		else savedata ('hideip', 0) end
		local a_status = pInfo.set.AutoHideIP and "будут" or "не будут"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nIP адреса '..a_status..' скрыты', 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Сессионный чат-лог', iVar.main_settings.chatlog) then
		aInfo.set.chatlog = iVar.main_settings.chatlog.v
		inicfg.save(aInfo, "AHelper\\settings.ini")
		local a_status = aInfo.set.chatlog and "активен" or "неактивен"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nСессионный чат-лог '..a_status, 5)
	end
	imgui.SameLine(400)
	if imgui.Checkbox(u8'Скрывать админ-чат', iVar.main_settings.hidea) then
		pInfo.set.AutoHideChat = iVar.main_settings.hidea.v
		if pInfo.set.AutoHideChat then savedata ('hidechat', 1)
		else savedata ('hidechat', 0) end
		local a_status = pInfo.set.AutoHideChat and "будет" or "не будет"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАдмин-чат '..a_status..' скрыт', 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Формы в админ-чате', iVar.main_settings.a_forms) then
		aInfo.set.forms = iVar.main_settings.a_forms.v
		local a_status = aInfo.set.forms and "активны" or "неактивны"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nФормы в админ-чате '..a_status, 5)
	end
	imgui.SameLine(400)
	if imgui.Checkbox(u8'Быстрая карта (по-умолчанию: англ. M)', iVar.main_settings.fastMap) then
		pInfo.set.fastMap = iVar.main_settings.fastMap.v
		if pInfo.set.fastMap then savedata ('fastmap', 1)
		else savedata ('fastmap', 0) end
		local a_status = pInfo.set.AutoHideChat and "включена" or "выключена"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nБыстрая карта '..a_status, 5)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Автоматический скриншот при выдаче наказаний', iVar.main_settings.autoScreen) then
		pInfo.set.auto_screen = iVar.main_settings.autoScreen.v
		if pInfo.set.auto_screen == true then savedata ('auto_screen', 1)
		else savedata ('auto_screen', 0) end
		local a_status = pInfo.set.auto_screen and "активны" or "неактивны"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАвтоматические скриншоты '..a_status, 5)
	end
	imgui.SameLine() showHelp(u8'Автоматический скриншот при выдаче наказаний за оскорбление/упоминание родных, а также при использовании команд /osk /caps /flood и т.д.')
	imgui.SameLine(400)
	if imgui.Checkbox(u8'Замена /get', iVar.main_settings.nget) then
		pInfo.set.nget = iVar.main_settings.nget.v
		if pInfo.set.nget == true then savedata ('nget', 1)
		else savedata ('nget', 0) end
		local a_status = pInfo.set.auto_screen and "активна" or "неактивна"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nЗамена /get '..a_status, 5)
	end
	imgui.SameLine() showHelp(u8'Более детальная информация об IP')
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Приветствие при взятии жалобы', iVar.main_settings.answerAuto) then
		pInfo.set.AutoAnswer = iVar.main_settings.answerAuto.v
		if pInfo.set.AutoAnswer then savedata ('autoanswer', 1)
		else savedata ('autoanswer', 0) end
	end
	imgui.SameLine(400)
	if imgui.Checkbox(u8'Время нахождения в АФК', iVar.main_settings.afk) then
		pInfo.set.afk = iVar.main_settings.afk.v
		if pInfo.set.afk == true then savedata ('afk', 1)
		else savedata ('afk', 0) end
		local a_status = pInfo.set.auto_screen and "активно" or "неактивно"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nВремя нахождения в АФК '..a_status, 5)
	end
	if pInfo.set.AutoAnswer == '1' or pInfo.set.AutoAnswer == true then
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.Text('')
		imgui.Separator()
		imgui.NewLine()
		imgui.PushItemWidth(420)
		imgui.InputText(u8'Текст приветствия', iVar.main_settings.answerText)
		if iVar.main_settings.answerText.v:find ("{player_name}") then
			local r_t = iVar.main_settings.answerText.v:gsub ("{player_name}", getLocalPlayerName())
			imgui.TextColored (imgui.ImColor(145, 218, 159, 255):GetVec4(), r_t)
			imgui.Text(u8'     * Для проверки взят ваш ник')
			imgui.Text('')
		else
			imgui.TextColored(imgui.ImColor(145, 218, 159, 255):GetVec4(), iVar.main_settings.answerText.v)
		end
		imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 60)

		if imgui.Button(u8'Сохранить##report_text', imgui.ImVec2(120, 20)) then
			pInfo.set.r_text = iVar.main_settings.answerText.v
			savedata('report_text', 2)
			notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nТекст приветствия сохранён', 5)
		end
		imgui.Text('')
	end
	imgui.Separator()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Список администрации онлайн', iVar.main_settings.adminList) then
		pInfo.set.OnlineAdmins = iVar.main_settings.adminList.v
		if pInfo.set.OnlineAdmins == true then savedata ('onlineadmins', 1)
		else savedata ('onlineadmins', 0) end
		local a_status = pInfo.set.OnlineAdmins and "включен" or "выключен"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nСписок администрации онлайн '..a_status, 5)
	end
	if pInfo.set.OnlineAdmins == true or pInfo.set.OnlineAdmins == '1' then
		imgui.SameLine(270)
		if imgui.Button(u8'Изменить местоположение##admList') then
			sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите список в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
			pTemp.objectSetPos = 1
		end
		if pTemp.objectSetPos == 1 then
			imgui.SameLine()
			if imgui.Button(u8'Сохранить') then
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('cx', 2)
				savedata ('cy', 2)
				pTemp.objectSetPos = 0
			end
		end
		imgui.SameLine()
		imgui.PushItemWidth(190)
		local type_sort = {u8'Без сортировки', u8'По возрастанию уровня', u8'По убыванию уровня'}
		if imgui.Combo(u8'Сортировка', iVar.main_settings.adminListSort, type_sort) then
			pInfo.set.admSortType = iVar.main_settings.adminListSort.v + 1
			savedata ('admsort', 2)
			pTemp.admUpdate = true
			sampSendChat ('/admins')
		end
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Чекер игроков (/checker)', iVar.main_settings.playerChecker) then
		pInfo.set.OnlinePlayers = iVar.main_settings.playerChecker.v
		if pInfo.set.OnlinePlayers == true then savedata ('onlineplayers', 1)
		else savedata ('onlineplayers', 0) end
	end
	if pInfo.set.OnlinePlayers == true or pInfo.set.OnlinePlayers == '1' then
		imgui.SameLine(270)
		if imgui.Button(u8'Изменить местоположение##playerList') then
			sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите список в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
			pTemp.objectSetPos = 2
		end
		if pTemp.objectSetPos == 2 then
			imgui.SameLine()
			if imgui.Button(u8'Сохранить') then
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('px', 2)
				savedata ('py', 2)
				pTemp.objectSetPos = 0
			end
		end
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if (pInfo.set.OnlineAdmins == true or pInfo.set.OnlineAdmins == '1') or (pInfo.set.OnlinePlayers == true or pInfo.set.OnlinePlayers == '1') then
		imgui.PushItemWidth(150)
		if imgui.SliderInt(u8'Размер шрифта', iVar.main_settings.fontSizeAdmList, 1, 4) then
			pInfo.set.font_size = iVar.main_settings.fontSizeAdmList.v
			my_font = renderCreateFont('Arial', 7+pInfo.set.font_size-(3-pInfo.set.font_size), 1+4)
			savedata ('font_size', 2)
		end
		imgui.NewLine()
		imgui.SameLine(17)
	end
	imgui.NewLine()
	imgui.Separator()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Панель предполагаемых читеров', iVar.main_settings.p_cheat) then
		pInfo.set.p_cheat = iVar.main_settings.p_cheat.v
		if pInfo.set.p_cheat == true then savedata ('p_cheat', 1)
		else savedata ('p_cheat', 0) end
	end
	if pInfo.set.p_cheat == true or pInfo.set.p_cheat == '1' then
		imgui.SameLine(270)
		if imgui.Button(u8'Изменить местоположение##p_cheat') then
			sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите панель в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
			pTemp.objectSetPos = 7
		end
		if pTemp.objectSetPos == 7 then
			imgui.SameLine()
			if imgui.Button(u8'Сохранить') then
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('pcx', 2)
				savedata ('pcy', 2)
				pTemp.objectSetPos = 0
			end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Звук при обновлении строки', iVar.main_settings.s_notf) then
			pInfo.set.s_notf = iVar.main_settings.s_notf.v
			if pInfo.set.s_notf == true then savedata ('s_notf', 1)
			else savedata ('s_notf', 0) end
		end
		if pInfo.set.s_notf == '1' or pInfo.set.s_notf == true then
			imgui.SameLine(270)
			local id_sound = {u8"Звук 1", u8"Звук 2", u8"Звук 3", u8"Звук 4", u8"Звук 5", u8"Звук 6"}
			if imgui.Combo (u8"Номер звука", iVar.main_settings.s_notf_id, id_sound) then
				pInfo.set.s_notf_id = iVar.main_settings.s_notf_id.v
				savedata ("s_notf_id", 2)
				if iVar.main_settings.s_notf_id.v == 0 then addOneOffSound(0.0, 0.0, 0.0, 1137)
				elseif iVar.main_settings.s_notf_id.v == 1 then addOneOffSound(0.0, 0.0, 0.0, 1135)
				elseif pInfo.set.s_notf_id == 2 then addOneOffSound(0.0, 0.0, 0.0, 1150)
				elseif pInfo.set.s_notf_id == 3 then addOneOffSound(0.0, 0.0, 0.0, 1149)
				elseif pInfo.set.s_notf_id == 4 then addOneOffSound(0.0, 0.0, 0.0, 1084)
				elseif pInfo.set.s_notf_id == 5 then addOneOffSound(0.0, 0.0, 0.0, 1054) end
			end
		end
	end
	imgui.NewLine()
	imgui.Separator()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8"Замена левой панели", iVar.recon.leftPanel) then
		pInfo.set.re_panel_change = iVar.recon.leftPanel.v
		if pInfo.set.re_panel_change == true then savedata ('re_panel_change', 1)
		else savedata ('re_panel_change', 0) end
	end
	if iVar.recon.leftPanel.v then
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.RadioButton (u8"Замена кнопок", iVar.recon.leftPanelStyle, 1) then
			pInfo.set.re_panel_style = tonumber (iVar.recon.leftPanelStyle.v)
			savedata('re_panel_style', 2)
			sampAddChatMessage("[AHelper] {FFFFFF}Для применения изменений необходимо перезайти в игру", 0x4682B4)
		end
		imgui.SameLine()
		showImage_1 ()
		if iVar.recon.leftPanelStyle.v == 1 then
			imgui.SameLine(270)
			if imgui.Button(u8"Изменить местоположение##leftPanel") then
				sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите панель в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
				pTemp.objectSetPos = 3
			end
			if pTemp.objectSetPos == 3 then
				imgui.SameLine()
				if imgui.Button(u8"Сохранить##leftPanel") then
					notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
					sampSetCursorMode(0)
					savedata ('lpX', 2)
					savedata ('lpY', 2)
					pTemp.objectSetPos = 0
				end
			end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.RadioButton (u8"Кнопки внизу",iVar.recon.leftPanelStyle, 2) then
			pInfo.set.re_panel_style = tonumber (iVar.recon.leftPanelStyle.v)
			savedata('re_panel_style', 2)
			sampAddChatMessage("[AHelper] {FFFFFF}Для применения изменений необходимо перезайти в игру", 0x4682B4)
		end
		imgui.SameLine()
		showImage_2 ()
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8"Замена правой панели", iVar.recon.rightPanel) then
		pInfo.set.right_panel_change = iVar.recon.rightPanel.v
		if pInfo.set.right_panel_change == true then savedata ('right_panel_change', 1)
		else savedata ('right_panel_change', 0) end
	end
	imgui.SameLine()
	showImage_3 ()
	if iVar.recon.rightPanel.v then
		imgui.SameLine(270)
		if imgui.Button(u8"Изменить местоположение##right") then
			sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите панель в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
			pTemp.objectSetPos = 4
		end
		if pTemp.objectSetPos == 4 then
			imgui.SameLine()
			if imgui.Button(u8"Сохранить##right") then
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('rpX', 2)
				savedata ('rpY', 2)
				pTemp.objectSetPos = 0
			end
		end
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Панель нажатия клавиш', iVar.recon.keysPanel) then
		pInfo.set.keys_panel = iVar.recon.keysPanel.v
		if pInfo.set.keys_panel then savedata ('keys_panel', 1)
		else savedata ('keys_panel', 0) end
		local a_status = pInfo.set.keys_panel and "включена" or "выключена"
		notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nПанель нажатия клавиш '..a_status, 5)
	end
	if pInfo.set.keys_panel == true or pInfo.set.keys_panel == '1' then
		imgui.SameLine(270)
		if imgui.Button(u8"Изменить местоположение##keys") then
			sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите панель в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
			pTemp.objectSetPos = 5
		end
		if pTemp.objectSetPos == 5 then
			imgui.SameLine()
			if imgui.Button(u8"Сохранить##keys") then
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('kX', 2)
				savedata ('kX', 2)
				pTemp.objectSetPos = 0
			end
		end
	end
	imgui.NewLine()
	imgui.Separator()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	if pInfo.info.adminLevel >= 6 then
		if imgui.Checkbox(u8'Замена /lip и /rip', iVar.main_settings.newLip) then
			pInfo.set.newLip = iVar.main_settings.newLip.v
			if pInfo.set.newLip == true then savedata ('newlip', 1)
			else savedata('newlip', 0) end
			local a_status = pInfo.set.newLip and "включена" or "выключена"
			notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nЗамена /lip и /rip '..a_status, 5)
		end
		imgui.SameLine()
		showHelp (u8'При вводе /lip и /rip будут показываться баны на аккаунтах')
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'IP/HASH в админ чекере', iVar.main_settings.ipHash) then
			pInfo.set.ip_hash = iVar.main_settings.ipHash.v
			if pInfo.set.ip_hash == true then savedata ('ip_hash', 1)
			else savedata('ip_hash', 0) end
			local a_status = pInfo.set.ip_hash and "включены" or "выключены"
			notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nIP/HASH в админ-чекере '..a_status, 5)
		end
		imgui.NewLine()
		imgui.Separator()
	end
	imgui.EndChild()
end

function submenu_4()
	imgui.BeginChild ('settings_fast_answers', imgui.ImVec2(872, 587), true)
	for i, k in ipairs(answers) do
		imgui.PushItemWidth(225)
		imgui.InputText(string.format (u8"##з%d", i),change_answers_title[i])
		imgui.SameLine()
		imgui.PushItemWidth(487)
		imgui.InputText(string.format (u8"##т%d", i),change_answers_text[i])
		imgui.SameLine()
		if imgui.Button(u8(string.format ("Сохранить##%d", i))) then
			local upd_rep = {}
			upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&title="..u8:decode(change_answers_title[i].v).."&text="..u8:decode(change_answers_text[i].v).."&id="..k.id
			upd_rep.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request ('POST', sInfo.url.."/answer_upd.php", upd_rep,
			function (response)
			--response = requests.post ("http://martin-rojo.myjino.ru/upd_answers.php", upd_rep)
				if u8:decode(response.text):find("Данные обновлены") then
					--load_answers()
					pTemp.user.load_answers = true
					sampAddChatMessage("[AHelper] {FFFFFF}Ответ успешно изменен", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#6). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)
				print(err)
				return
			end)
		end
		imgui.SameLine()
		if imgui.Button(u8(string.format ("Удалить##%d", i))) then
			local upd_rep = {}
			upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id="..k.id
			upd_rep.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request ('POST', sInfo.url.."/answer_del.php", upd_rep,
			function (response)
			--response = requests.post ("http://martin-rojo.myjino.ru/del_answers.php", upd_rep)
				if u8:decode(response.text):find("Данные удалены") then
					--load_answers()
					pTemp.user.load_answers = true
					sampAddChatMessage("[AHelper] {FFFFFF}Ответ успешно удалён", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#7). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)
				print(err)
				return
			end)
		end
		imgui.Separator()
	end
	if imgui.Button(u8'Добавить новый ответ') then
		local upd_rep = {}
		upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
		upd_rep.headers = {
			['content-type']='application/x-www-form-urlencoded'
		}
		async_http_request ('POST', sInfo.url.."/answer_add.php", upd_rep,
		function (response)
		--response = requests.post ("http://martin-rojo.myjino.ru/add_answer.php", upd_rep)
			if u8:decode(response.text):find("Данные добавлены") then
				--load_answers()
				pTemp.user.load_answers = true
				sampAddChatMessage("[AHelper] {FFFFFF}Новая строка для ответа успешно добавлена", 0x4682B4)
			elseif u8:decode(response.text):find("Запрос не сработал") then
				sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
			elseif u8:decode(response.text):find("Не получены данные") then
				sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#7). Работа скрипта остановлена.", 0xFF0000)
				print("RepUpd ErrTrue: "..u8:decode(response.text))
				thisScript():unload()
			end
		end,
		function (err)
			print(err)
			return
		end)
	end
	imgui.EndChild()
end

function submenu_10()
	imgui.BeginChild ('settings_widget', imgui.ImVec2(872, 587), true)
	imgui.SameLine(17)
	if imgui.Checkbox (u8'Включить/Выключить', iVar.widget.activated) then
		pInfo.set.clock = iVar.widget.activated.v
		if pInfo.set.clock == true then savedata ('clock', 1)
		else savedata ('clock', 0) end
	end
	imgui.Separator()
	imgui.NewLine()
	imgui.SameLine(17)
	if pInfo.set.clock == true or pInfo.set.clock == '1' then
		if imgui.Checkbox(u8'Убийства', iVar.widget.kills) then
			pInfo.set.widget.kills = iVar.widget.kills.v
			if pInfo.set.widget.kills == true then savedata ('w_kills', 1)
			else savedata ('w_kills', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Время за сеанс', iVar.widget.time_s) then
			pInfo.set.widget.time_s = iVar.widget.time_s.v
			if pInfo.set.widget.time_s == true then savedata ('w_time_s', 1)
			else savedata ('w_time_s', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Ответов на репорт всего', iVar.widget.pm_all) then
			pInfo.set.widget.pm_all = iVar.widget.pm_all.v
			if pInfo.set.widget.pm_all == true then savedata ('w_pm_all', 1)
			else savedata ('w_pm_all', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Наказаний всего', iVar.widget.pun_all) then
			pInfo.set.widget.pun_all = iVar.widget.pun_all.v
			if pInfo.set.widget.pun_all == true then savedata ('w_pun_all', 1)
			else savedata ('w_pun_all', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Ответов на репорт за день', iVar.widget.pm_day) then
			pInfo.set.widget.pm_day = iVar.widget.pm_day.v
			if pInfo.set.widget.pm_day == true then savedata ('w_pm_day', 1)
			else savedata ('w_pm_day', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Наказаний за день', iVar.widget.pun_day) then
			pInfo.set.widget.pun_day = iVar.widget.pun_day.v
			if pInfo.set.widget.pun_day == true then savedata ('w_pun_day', 1)
			else savedata ('w_pun_day', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Дата и время', iVar.widget.datetime) then
			pInfo.set.widget.datetime = iVar.widget.datetime.v
			if pInfo.set.widget.datetime == true then savedata ('w_datetime', 1)
			else savedata ('w_datetime', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Статус инвиза', iVar.widget.in_s) then
			pInfo.set.widget.in_s = iVar.widget.in_s.v
			if pInfo.set.widget.in_s == true then savedata ('w_in_s', 1)
			else savedata ('w_in_s', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Индикатор чата', iVar.widget.chat) then
			pInfo.set.widget.chat = iVar.widget.chat.v
			if pInfo.set.widget.chat == true then savedata ('w_chat', 1)
			else savedata ('w_chat', 0) end
		end
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox(u8'Статус сервера', iVar.widget.server_status) then
			pInfo.set.widget.server_status = iVar.widget.server_status.v
			if pInfo.set.widget.server_status == true then savedata ('w_server', 1)
			else savedata ('w_server', 0) end
		end
		imgui.Separator()
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.PushItemWidth(238)
		imgui.SliderFloat(u8"Размер виджета", iVar.widget.sizeWidget, 0.5, 1.3, "%.2f")
		imgui.SameLine()
		if imgui.Button(u8"Сохранить##widget_size") then
			pInfo.set.widget.sizeWidget = iVar.widget.sizeWidget.v
			savedata ('sizewidget', 2)
			sampAddChatMessage("[AHelper] {FFFFFF}Размер виджета сохранён", 0x4682B4)
		end
		imgui.Separator()
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Button(u8"Изменить местоположение##clock") then
			sampAddChatMessage("[AHelper] {4AF376}Информация: {FFFFFF}перетащите виджет в нужное вам место и нажмите кнопку \"Сохранить\"", 0x4682B4)
			pTemp.objectSetPos = 6
		end
		if pTemp.objectSetPos == 6 then
			imgui.SameLine()
			if imgui.Button(u8"Сохранить##widget") then
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестоположение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('clX', 2)
				savedata ('clY', 2)
				pTemp.objectSetPos = 0
			end
		end
	end
	imgui.EndChild()
end

function submenu_3()
	imgui.BeginChild ('settings_user_punish', imgui.ImVec2(872, 587), true)
	imgui.SameLine(30)
	imgui.Text (u8'Тип') imgui.SameLine(150)
	imgui.Text (u8'Время') imgui.SameLine(300)
	imgui.Text (u8'Причина')
	imgui.NewLine()
	imgui.Separator()
	for i, k in ipairs (bans) do
		local p_type = {u8"Выбрать", "/kick", "/skick", "/jail", "/mute", "/ban", "/sban", "/cban", "/scban"}
		if #bans > 1 then
			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00); -- Прозрачные кнопки
			local str_id = tonumber (k.id)
			imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(1.00, 0.39, 0.39, 1.00);
			if imgui.ActiveButtonPunish (str_id, fa.ICON_FA_EXCHANGE_ALT..'##'..str_id) then
				if pTemp.exchange_id == str_id then
					pTemp.exchange_id = 0
				else
					if pTemp.exchange_id == 0 then
						pTemp.exchange_id = str_id
					else
						local exchange = {}

						exchange.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id1="..pTemp.exchange_id.."&id2="..str_id
						exchange.headers = {
							['content-type']='application/x-www-form-urlencoded'
						}
						async_http_request ('POST', sInfo.url.."/bans_exchange.php", exchange,
						function (response)
						--response = requests.post ("http://martin-rojo.myjino.ru/upd_answers.php", upd_rep)
							if u8:decode(response.text):find("Данные обновлены") then
								--load_answers()
								pTemp.exchange_id = 0
								pTemp.user.load_bans = true
								sampAddChatMessage("[AHelper] {FFFFFF}Вы поменяли наказания местами", 0x4682B4)
							elseif u8:decode(response.text):find("Запрос не сработал") then
								sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при изменении", 0x4682B4)
							elseif u8:decode(response.text):find("Не получены данные") then
								sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#100). Работа скрипта остановлена.", 0xFF0000)
								print("RepUpd ErrTrue: "..u8:decode(response.text))
								thisScript():unload()
							end
						end,
						function (err)
							print(err)
							return
						end)
					end
				end
			end
			imgui.SameLine()
			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00); -- Прозрачные кнопки
		end
		imgui.PushItemWidth(120)
		imgui.Combo(string.format (u8"##т%d", i), bans_change_type[i], p_type)
		imgui.SameLine()
		imgui.PushItemWidth(90)
		imgui.InputText(string.format (u8"##в%d", i), bans_change_time[i])
		imgui.SameLine()
		imgui.PushItemWidth(230)
		imgui.InputText(string.format (u8"##п%d", i), bans_change_reason[i])
		imgui.SameLine()
		if imgui.Button(u8'Сохранить##'..i)  then
			local result_type = true
			local result_time = true
			local result_reason = true
			if bans_change_type[i].v > 0 then
				if bans_change_time[i].v ~= nil and bans_change_time[i].v:len() > 0 then
					local time_bans = tonumber(bans_change_time[i].v)
					if bans_change_type[i].v == 3 then
						if time_bans < 1 or time_bans > 300 then
							sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 300)', 0x4682B4)
							result_time = false
						end
					elseif bans_change_type[i].v == 4 then
						if time_bans < 1 or time_bans > 180 then
							sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 180)', 0x4682B4)
							result_time = false
						end
					elseif bans_change_type[i].v >= 5 then
						if not pInfo.info.accept then
							sampAddChatMessage('[AHelper] {FFFFFF}У вас нет доступа к блокировкам', 0x4682B4)
							result_type = false
						else
							if time_bans < 1 or time_bans > 90 then
								sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 90)', 0x4682B4)
								result_type = false
							end
						end
					else
						if time_bans ~= 0 then
							sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (для /kick и /skick должно быть указано 0)', 0x4682B4)
							result_type = false
						end
					end

				else
					sampAddChatMessage('[AHelper] {FFFFFF}Пустое поле со временем наказания (для /kick и /skick время должно быть 0)', 0x4682B4)
					result_time = false
				end
			else
				sampAddChatMessage('[AHelper] {FFFFFF}Выберите тип наказания', 0x4682B4)
				result_time = false
			end
			if bans_change_reason[i].v == nil or bans_change_reason[i].v:len() == 0 then
				sampAddChatMessage('[AHelper] {FFFFFF}Пустое поле с причиной наказания', 0x4682B4)
				result_reason = false
			end
			if result_time and result_type and result_reason then
				local upd_pun = {}
				upd_pun.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&reason="..u8:decode(bans_change_reason[i].v).."&type="..bans_change_type[i].v.."&time="..bans_change_time[i].v.."&id="..k.id
				upd_pun.headers = {
					['content-type']='application/x-www-form-urlencoded'
				}
				async_http_request ('POST', sInfo.url.."/bans_upd.php", upd_pun,
				function (response)
				--response = requests.post ("http://martin-rojo.myjino.ru/upd_answers.php", upd_rep)
					if u8:decode(response.text):find("Данные обновлены") then
						--load_answers()
						pTemp.user.load_bans = true
						print (response.text)
						sampAddChatMessage("[AHelper] {FFFFFF}Наказание изменено", 0x4682B4)
					elseif u8:decode(response.text):find("Запрос не сработал") then
						sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
					elseif u8:decode(response.text):find("Не получены данные") then
						sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#100). Работа скрипта остановлена.", 0xFF0000)
						print("RepUpd ErrTrue: "..u8:decode(response.text))
						thisScript():unload()
					end
				end,
				function (err)
					print(err)
					return
				end)
			end

		end
		imgui.SameLine()
		if imgui.Button(u8'Удалить##'..i) then
			local del_pun = {}
			del_pun.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id="..k.id
			del_pun.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request ('POST', sInfo.url.."/bans_del.php", del_pun,
			function (response)
			--response = requests.post ("http://martin-rojo.myjino.ru/del_answers.php", upd_rep)
				if u8:decode(response.text):find("Данные удалены") then
					--load_answers()
					pTemp.user.load_bans = true
					sampAddChatMessage("[AHelper] {FFFFFF}Наказание удалено", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при удалении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#101). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)
				print(err)
				return
			end)
		end
		imgui.Separator()
		--imgui.NewLine()
	end
	if imgui.Button(u8'Добавить строку') then
		local add_oun = {}
		add_oun.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
		add_oun.headers = {
			['content-type']='application/x-www-form-urlencoded'
		}
		async_http_request ('POST', sInfo.url.."/bans_add.php", add_oun,
		function (response)
		--response = requests.post ("http://martin-rojo.myjino.ru/add_answer.php", upd_rep)
			if u8:decode(response.text):find("Данные добавлены") then
				--load_answers()
				pTemp.user.load_bans = true
				sampAddChatMessage("[AHelper] {FFFFFF}Новая строка для наказания успешно добавлена", 0x4682B4)
			elseif u8:decode(response.text):find("Запрос не сработал") then
				sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при добавлении", 0x4682B4)
			elseif u8:decode(response.text):find("Не получены данные") then
				sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#102). Работа скрипта остановлена.", 0xFF0000)
				print("RepUpd ErrTrue: "..u8:decode(response.text))
				thisScript():unload()
			end
		end,
		function (err)
			print(err)
			return
		end)
	end

	imgui.EndChild()
end

function submenu_12()
	imgui.BeginChild ('settings_cmds', imgui.ImVec2(872, 587), true)
	for i, k in ipairs (cmds) do
		imgui.Text('/')
		imgui.SameLine()
		imgui.PushItemWidth(90)
		if pInfo.set.premium == 0 or pInfo.set.premium > os.time() then imgui.InputText(u8'##'..i, iVar.cmds.name[i])
		else
			if k.standard == '1' then
				imgui.SameLine(13)
				imgui.Text (iVar.cmds.name[i].v)
			else imgui.InputText(u8'##'..i, iVar.cmds.name[i]) end
		end
		imgui.SameLine(115)
		local items_cmds = {u8"Выбрать", "/pm", "/msg", "/o", "/a", "/f", "/af", "/sms", "/kick", "/skick", "/mute", "/jail", "/unjail", "/rmute", "/ban", "/sban", "/cban", "/scban"}
		--imgui.Combo (u8"Тип##"..i, iVar.cmds.ctype[i], items_cmds)
		if pInfo.set.premium == 0 or pInfo.set.premium > os.time() then imgui.Combo (u8"Тип##"..i, iVar.cmds.ctype[i], items_cmds)
		else
			if k.standard == '1' then imgui.Text (items_cmds[iVar.cmds.ctype[i].v+1])
			else imgui.Combo (u8"Тип##"..i, iVar.cmds.ctype[i], items_cmds) end
		end
		imgui.SameLine(242)
		if iVar.cmds.ctype[i].v > 9 and iVar.cmds.ctype[i].v ~= 12  then
			--imgui.SameLine()
			imgui.PushItemWidth(30)
			imgui.InputText(u8'Время##'..i, iVar.cmds.time[i])
		end
		--imgui.SameLine()
		imgui.PushItemWidth(350)
		imgui.SameLine(325)
		imgui.InputText(u8'Текст##'..i, iVar.cmds.text[i])
		if k.standard == '1' then
			--if pInfo.set.premium == 0 or pInfo.set.premium > os.time() then
				imgui.SameLine(730)
				if imgui.Button(u8'Сохранить##'..i) then
					local result_type = true
					local result_time = true
					local result_reason = true
					if iVar.cmds.ctype[i].v > 9 and iVar.cmds.ctype[i].v ~= 12  then
						local cctime = tonumber (iVar.cmds.time[i].v)
						if type (cctime) == 'number' then
							if cctime > 0 then
								if iVar.cmds.time[i].v ~= nil and iVar.cmds.time[i].v:len() > 0 then
									if iVar.cmds.ctype[i].v == 11 then
										if cctime < 1 or cctime > 300 then
											sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 300)', 0x4682B4)
											result_time = false
										end
									elseif iVar.cmds.ctype[i].v == 10 then
										if cctime < 1 or cctime > 180 then
											sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 180)', 0x4682B4)
											result_time = false
										end
									elseif iVar.cmds.ctype[i].v >= 13 then
										if not pInfo.info.accept then
											sampAddChatMessage('[AHelper] {FFFFFF}У вас нет доступа к блокировкам', 0x4682B4)
											result_type = false
										else
											if cctime < 1 or cctime > 90 then
												sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 90)', 0x4682B4)
												result_type = false
											end
										end
									end
								end
							else
								sampAddChatMessage('[AHelper] {FFFFFF}Указано неверное время', 0x4682B4)
								result_time = false
							end
							if iVar.cmds.text[i].v == nil or iVar.cmds.text[i].v:len() == 0 then
								sampAddChatMessage('[AHelper] {FFFFFF}Пустое поле с текстом', 0x4682B4)
								result_reason = false
							end
						else
							sampAddChatMessage('[AHelper] {FFFFFF}Указано неверное время', 0x4682B4)
							result_time = false
						end
					end
					if iVar.cmds.name[i].v == nil or iVar.cmds.name[i].v:len() == 0 then
						sampAddChatMessage('[AHelper] {FFFFFF}Пустое поле с названием команды', 0x4682B4)
						result_type = false
					end
					if iVar.cmds.ctype[i].v == 0 then
						sampAddChatMessage('[AHelper] {FFFFFF}Выберите тип команды', 0x4682B4)
						result_type = false
					end
					if result_type and result_time and result_reason then
						local rslt = false
						for j in ipairs (cmds) do
							if cmds[j]['name'] == iVar.cmds.name[i].v and j ~= i then rslt = true end
						end
						if not rslt then
							if pInfo.set.premium > 0 and pInfo.set.premium < os.time() then
								iVar.cmds.name[i].v = k.name
								iVar.cmds.ctype[i].v = k.ctype
							end
							local upd_cmds = {}
							upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name="..iVar.cmds.name[i].v.."&ctype="..iVar.cmds.ctype[i].v.."&time="..iVar.cmds.time[i].v.."&text="..iVar.cmds.text[i].v.."&id="..k.id
							upd_cmds.headers = {
								['content-type']='application/x-www-form-urlencoded'
							}
							async_http_request ('POST', sInfo.url.."/ucmd_upd.php", upd_cmds,
							function (response)
								if u8:decode(response.text):find("Данные обновлены") then
									pTemp.user.load_cmds = true
									sampAddChatMessage("[AHelper] {FFFFFF}Команда успешно изменена", 0x4682B4)
								elseif u8:decode(response.text):find("Запрос не сработал") then
									sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
								elseif u8:decode(response.text):find("Не получены данные") then
									sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#105). Работа скрипта остановлена.", 0xFF0000)
									print("RepUpd ErrTrue: "..u8:decode(response.text))
									thisScript():unload()
								end
							end,
							function (err)
								print(err)
								return
							end)
						else
							sampAddChatMessage('[AHelper] {FFFFFF}Команда /'..iVar.cmds.name[i].v..' уже используется', 0x4682B4)
						end
					end
				end
				if pInfo.set.premium == 0 or pInfo.set.premium > os.time() then
					imgui.SameLine()
					if imgui.Button(u8'Удалить##'..i) then
						local upd_cmds = {}
						upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id="..k.id
						upd_cmds.headers = {
							['content-type']='application/x-www-form-urlencoded'
						}
						async_http_request ('POST', sInfo.url.."/ucmd_del.php", upd_cmds,
						function (response)
							if u8:decode(response.text):find("Данные удалены") then
								pTemp.user.load_cmds = true
								sampAddChatMessage("[AHelper] {FFFFFF}Команда успешно удалена", 0x4682B4)
							elseif u8:decode(response.text):find("Запрос не сработал") then
								sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
							elseif u8:decode(response.text):find("Не получены данные") then
								sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#107). Работа скрипта остановлена.", 0xFF0000)
								print("RepUpd ErrTrue: "..u8:decode(response.text))
								thisScript():unload()
							end
						end,
						function (err)
							print(err)
							return
						end)
					end
				end
			--end
		else
			imgui.SameLine(730)
			if imgui.Button(u8'Сохранить##'..i) then
				local result_type = true
				local result_time = true
				local result_reason = true
				if iVar.cmds.ctype[i].v > 9 and iVar.cmds.ctype[i].v ~= 12  then
					local cctime = tonumber (iVar.cmds.time[i].v)
					if type (cctime) == 'number' then
						if cctime > 0 then
							if iVar.cmds.time[i].v ~= nil and iVar.cmds.time[i].v:len() > 0 then
								if iVar.cmds.ctype[i].v == 11 then
									if cctime < 1 or cctime > 300 then
										sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 300)', 0x4682B4)
										result_time = false
									end
								elseif iVar.cmds.ctype[i].v == 10 then
									if cctime < 1 or cctime > 180 then
										sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 180)', 0x4682B4)
										result_time = false
									end
								elseif iVar.cmds.ctype[i].v >= 13 then
									if not pInfo.info.accept then
										sampAddChatMessage('[AHelper] {FFFFFF}У вас нет доступа к блокировкам', 0x4682B4)
										result_type = false
									else
										if cctime < 1 or cctime > 90 then
											sampAddChatMessage('[AHelper] {FFFFFF}Неверное время выдачи наказания (от 1 до 90)', 0x4682B4)
											result_type = false
										end
									end
								end
							end
						else
							sampAddChatMessage('[AHelper] {FFFFFF}Указано неверное время', 0x4682B4)
							result_time = false
						end

					else
						sampAddChatMessage('[AHelper] {FFFFFF}Указано неверное время', 0x4682B4)
						result_time = false
					end
				end
				if iVar.cmds.name[i].v == nil or iVar.cmds.name[i].v:len() == 0 then
					sampAddChatMessage('[AHelper] {FFFFFF}Пустое поле с названием команды', 0x4682B4)
					result_type = false
				end
				if iVar.cmds.ctype[i].v == 0 then
					sampAddChatMessage('[AHelper] {FFFFFF}Выберите тип команды', 0x4682B4)
					result_type = false
				end
				if iVar.cmds.text[i].v == nil or iVar.cmds.text[i].v:len() == 0 then
					sampAddChatMessage('[AHelper] {FFFFFF}Пустое поле с текстом', 0x4682B4)
					result_reason = false
				end
				if result_type and result_time and result_reason then
					local rslt = false
					for j in ipairs (cmds) do
						if cmds[j]['name'] == iVar.cmds.name[i].v and j ~= i then rslt = true end
					end
					if not rslt then
						local upd_cmds = {}
						upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&name="..iVar.cmds.name[i].v.."&ctype="..iVar.cmds.ctype[i].v.."&time="..iVar.cmds.time[i].v.."&text="..iVar.cmds.text[i].v.."&id="..k.id
						upd_cmds.headers = {
							['content-type']='application/x-www-form-urlencoded'
						}
						async_http_request ('POST', sInfo.url.."/ucmd_upd.php", upd_cmds,
						function (response)
						--response = requests.post ("http://martin-rojo.myjino.ru/upd_answers.php", upd_rep)
							if u8:decode(response.text):find("Данные обновлены") then
								--load_answers()
								pTemp.user.load_cmds = true
								sampAddChatMessage("[AHelper] {FFFFFF}Команда успешно изменена", 0x4682B4)
							elseif u8:decode(response.text):find("Запрос не сработал") then
								sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
							elseif u8:decode(response.text):find("Не получены данные") then
								sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#105). Работа скрипта остановлена.", 0xFF0000)
								print("RepUpd ErrTrue: "..u8:decode(response.text))
								thisScript():unload()
							end
						end,
						function (err)
							print(err)
							return
						end)
					else
						sampAddChatMessage('[AHelper] {FFFFFF}Команда /'..iVar.cmds.name[i].v..' уже используется', 0x4682B4)
					end
				end
			end
			imgui.SameLine()
			if imgui.Button(u8'Удалить##'..i) then
				local upd_cmds = {}
				upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id="..k.id
				upd_cmds.headers = {
					['content-type']='application/x-www-form-urlencoded'
				}
				async_http_request ('POST', sInfo.url.."/ucmd_del.php", upd_cmds,
				function (response)
					if u8:decode(response.text):find("Данные удалены") then
						pTemp.user.load_cmds = true
						sampAddChatMessage("[AHelper] {FFFFFF}Команда успешно удалена", 0x4682B4)
					elseif u8:decode(response.text):find("Запрос не сработал") then
						sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
					elseif u8:decode(response.text):find("Не получены данные") then
						sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#107). Работа скрипта остановлена.", 0xFF0000)
						print("RepUpd ErrTrue: "..u8:decode(response.text))
						thisScript():unload()
					end
				end,
				function (err)
					print(err)
					return
				end)
			end
		end
		imgui.Separator()
	end
	if pInfo.set.premium == 0 or pInfo.set.premium > os.time() then
		if imgui.Button(u8'Добавить новую команду') then
			local upd_cmds = {}
			upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
			upd_cmds.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request ('POST', sInfo.url.."/ucmd_add.php", upd_cmds,
			function (response)
				if u8:decode(response.text):find("Данные добавлены") then
					pTemp.user.load_cmds = true
					sampAddChatMessage("[AHelper] {FFFFFF}Новая строка для команды успешно добавлена", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#104). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)
				print(err)
				return
			end)
		end
	end
	imgui.EndChild()
end

function submenu_11()
	imgui.BeginChild ('settings_color-chat', imgui.ImVec2(872, 587), true)
	imgui.SameLine(17)
	if imgui.Checkbox (u8'Админ чат', iVar.colors.a_recolor) then
		pInfo.set.recolor_a =  iVar.colors.a_recolor.v
		if pInfo.set.recolor_a == true then savedata ('recolor_a', 1)
		else savedata ('recolor_a', 0) end
	end
	imgui.SameLine(160)
	imgui.ColorEdit4("##a_chat", iVar.colors.a_chat, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.NoAlpha)
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox (u8'Репорт', iVar.colors.r_recolor) then
		pInfo.set.recolor_r = iVar.colors.r_recolor.v
		if pInfo.set.recolor_r == true then savedata ('recolor_r', 1)
		else savedata ('recolor_r', 0) end
	end
	imgui.SameLine(160)
	imgui.ColorEdit4("##report", iVar.colors.report, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.NoAlpha)
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox (u8'Ответы на репорт', iVar.colors.p_recolor) then
		pInfo.set.recolor_p = iVar.colors.p_recolor.v
		if pInfo.set.recolor_p == true then savedata ('recolor_p', 1)
		else savedata ('recolor_p', 0) end
	end
	imgui.SameLine(160)
	imgui.ColorEdit4("##pm", iVar.colors.pm, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.NoAlpha)
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox (u8'SMS', iVar.colors.s_recolor) then
		pInfo.set.recolor_s = iVar.colors.s_recolor.v
		if pInfo.set.recolor_s == true then savedata ('recolor_s', 1)
		else savedata ('recolor_s', 0) end
	end
	imgui.SameLine(160)
	imgui.ColorEdit4("##sms", iVar.colors.sms, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.NoAlpha)
	imgui.NewLine()
	if pInfo.set.premium == 0 or pInfo.set.premium > os.time() then
		imgui.Separator()
		imgui.NewLine()
		imgui.CenterTextColoredRGB('PREMIUM')
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox (u8'Цвет ника в админ-чате', iVar.colors.a_p_recolor) then
			pInfo.set.a_n_chat = iVar.colors.a_p_recolor.v
			if pInfo.set.a_n_chat == true then savedata ('a_n_chat', 1)
			else savedata ('a_n_chat', 0) end
			lua_thread.create (function ()
				wait (2000)
				local bitstream = BitStream()
				bitstream:write('unsigned char', 44)
				bitstream:write('string', tostring(srv))
				client:send_packet(8, bitstream)
			end)
		end
		imgui.SameLine(250)
		imgui.ColorEdit4("##a_n_chat", iVar.colors.admNick, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.NoAlpha)

		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Checkbox (u8'Цвет действий администрации', iVar.colors.p_admAct) then
			pInfo.set.p_admAct = iVar.colors.p_admAct.v
			if pInfo.set.p_admAct == true then savedata ('p_admAct', 1)
			else savedata ('p_admAct', 0) end
		end
		imgui.SameLine(250)
		imgui.ColorEdit4("##p_admActColor", iVar.colors.p_admActColor, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.NoAlpha)
		imgui.NewLine()

	end
	imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
	if imgui.Button(u8'Сохранить настройки цвета', imgui.ImVec2(200, 20)) then
		newColor = imgui.ImColor.FromFloat4(iVar.colors.a_chat.v[1], iVar.colors.a_chat.v[2], iVar.colors.a_chat.v[3], iVar.colors.a_chat.v[4]):GetVec4()
		pInfo.set.colorAChat = imgui.ImColor(newColor):GetU32()
		newColor = imgui.ImColor.FromFloat4(iVar.colors.report.v[1], iVar.colors.report.v[2], iVar.colors.report.v[3], iVar.colors.report.v[4]):GetVec4()
		pInfo.set.colorReport = imgui.ImColor(newColor):GetU32()
		newColor = imgui.ImColor.FromFloat4(iVar.colors.pm.v[1], iVar.colors.pm.v[2], iVar.colors.pm.v[3], iVar.colors.pm.v[4]):GetVec4()
		pInfo.set.colorPm = imgui.ImColor(newColor):GetU32()
		newColor = imgui.ImColor.FromFloat4(iVar.colors.sms.v[1], iVar.colors.sms.v[2], iVar.colors.sms.v[3], iVar.colors.sms.v[4]):GetVec4()
		pInfo.set.colorSMS = imgui.ImColor(newColor):GetU32()
		newColor = imgui.ImColor.FromFloat4(iVar.colors.admNick.v[1], iVar.colors.admNick.v[2], iVar.colors.admNick.v[3], iVar.colors.admNick.v[4]):GetVec4()
		pInfo.set.a_n_color = imgui.ImColor(newColor):GetU32()
		newColor = imgui.ImColor.FromFloat4(iVar.colors.p_admActColor.v[1], iVar.colors.p_admActColor.v[2], iVar.colors.p_admActColor.v[3], iVar.colors.p_admActColor.v[4]):GetVec4()
		pInfo.set.p_admAct_color = imgui.ImColor(newColor):GetU32()
		savedata ('a_n_color', 2)
		savedata ('color_a', 2)
		savedata ('color_r', 2)
		savedata ('color_p', 2)
		savedata ('color_s', 2)
		savedata ('p_admActColor', 2)
		sampAddChatMessage("[AHelper] {FFFFFF}Настройки цвета чата сохранены", 0x4682B4)
		lua_thread.create (function ()
			wait (2000)
			local bitstream = BitStream()
			bitstream:write('unsigned char', 44)
			bitstream:write('string', tostring(srv))
			client:send_packet(8, bitstream)
		end)
	end

	imgui.EndChild()
end

function submenu_6()
	imgui.BeginChild ('settings_warnings', imgui.ImVec2(872, 587), true)
	imgui.SameLine(17)
	imgui.Checkbox(u8"Стрельба через текстуры", iVar.warnings.textures)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Checkbox(u8"Серия попаданий", iVar.warnings.hit)
	if iVar.warnings.hit.v == true then
		imgui.Separator()
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("9mm", iVar.warnings.pistol, 5, 20)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("Silenced 9mm", iVar.warnings.silenced, 5, 20)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("Deagle", iVar.warnings.deagle, 3, 10)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("Shotgun", iVar.warnings.shotgun, 3, 15)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("MP-5", iVar.warnings.mp5, 5, 30)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("M4", iVar.warnings.m4, 5, 50)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("AK-47", iVar.warnings.ak47, 5, 30)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt("Rifle", iVar.warnings.rifle, 5, 15)
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.Separator()
	end
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Checkbox(u8"Спидхак", iVar.warnings.speedhack)
	if iVar.warnings.speedhack.v == true then
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.SliderInt(u8"Задержка между варнингами", iVar.warnings.speedhack_delay, 1, 10)
	end
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Checkbox(u8"Починка авто", iVar.warnings.cleoRepair)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Separator()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Button(u8"Сохранить настройки") then
		pInfo.set.warnings.textures = iVar.warnings.textures.v
		pInfo.set.warnings.hit = iVar.warnings.hit.v
		pInfo.set.warnings.deagle = tonumber (iVar.warnings.deagle.v)
		pInfo.set.warnings.m4 = tonumber (iVar.warnings.m4.v)
		pInfo.set.warnings.shotgun = tonumber (iVar.warnings.shotgun.v)
		pInfo.set.warnings.pistol = tonumber (iVar.warnings.pistol.v)
		pInfo.set.warnings.silenced = tonumber (iVar.warnings.silenced.v)
		pInfo.set.warnings.mp5 = tonumber (iVar.warnings.mp5.v)
		pInfo.set.warnings.ak47 = tonumber (iVar.warnings.ak47.v)
		pInfo.set.warnings.rifle = tonumber (iVar.warnings.rifle.v)
		pInfo.set.warnings.speedhack = iVar.warnings.speedhack.v
		pInfo.set.warnings.speedhack_delay = tonumber (iVar.warnings.speedhack_delay.v)
		pInfo.set.warnings.repair = iVar.warnings.cleoRepair.v
		if iVar.warnings.textures.v == true then savedata ('textures', 1)
		else savedata ('textures', 0) end
		if iVar.warnings.hit.v == true then savedata ('hit', 1)
		else savedata ('hit', 0) end
		savedata ('deagle', 2)
		savedata ('m4', 2)
		savedata ('shotgun', 2)
		savedata ('pistol', 2)
		savedata ('silenced', 2)
		savedata ('mp5', 2)
		savedata ('ak47', 2)
		savedata ('rifle', 2)
		if iVar.warnings.speedhack.v == true then savedata ('speedhack', 1)
		else savedata ('speedhack', 0) end
		savedata ('speedhack_delay', 2)
		if iVar.warnings.cleoRepair.v == true then savedata ('repair', 1)
		else savedata ('repair', 0) end
	end
	imgui.EndChild()
end

function submenu_5()
	imgui.BeginChild ('settings_tracers', imgui.ImVec2(872, 587), true)
	imgui.SameLine(17)
	imgui.Checkbox (u8'Включить/Выключить', iVar.tracers.BulletTrackActivate)
	imgui.Separator()
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Checkbox (u8'Отображать только для одного игрока', iVar.tracers.BulletTrackOnlyPlayer)
	imgui.Separator()
	imgui.NewLine()
	imgui.PushItemWidth(250)
	imgui.SameLine(17)
	imgui.SliderInt(u8"Время задержки", iVar.tracers.BulletTrackTime, 1, 20)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.SliderInt(u8"Максимальное количество линий", iVar.tracers.BulletTrackMaxLines, 10, 100)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.SliderInt(u8"Толщина линий", iVar.tracers.BulletTrackMaxWeight, 1, 10)
	imgui.Separator()
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Checkbox (u8'Окончания на линиях', iVar.tracers.BulletTrackPolyginActivate)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.SliderInt(u8"Размер окончаний на линиях", iVar.tracers.BulletTrackSizePolygon, 1, 50)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.SliderInt(u8"Количество углов на окончании", iVar.tracers.BulletTrackCountPolygin, 3, 50)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.SliderInt(u8"Градус поворота на окончании", iVar.tracers.BulletTrackRotationPolygon, 0, 360)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.Separator()
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.ColorEdit4(u8"Цвет при попадании в игрока", shot_in_player)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.ColorEdit4(u8"Цвет при попадании в игрока AFK", shot_in_player_afk)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.ColorEdit4(u8"Цвет при попадании в транспорт", shot_in_vehicle)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.ColorEdit4(u8"Цвет при попадании в статический объект", shot_in_static_obj)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.ColorEdit4(u8"Цвет при попадании в динамический объект", shot_in_dynamic_obj)
	imgui.Separator()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Button(u8'Сохранить настройки') then
		BulletSync.maxLines = iVar.tracers.BulletTrackMaxLines.v
		for i = 1, BulletSync.maxLines do
			BulletSync[i].timeDelete = iVar.tracers.BulletTrackTime.v
			BulletSync[i].tWeightLine = iVar.tracers.BulletTrackMaxWeight.v
			BulletSync[i].tSizePolygon = iVar.tracers.BulletTrackSizePolygon.v
			BulletSync[i].tCountCorners = iVar.tracers.BulletTrackCountPolygin.v
			BulletSync[i].tRotation = iVar.tracers.BulletTrackRotationPolygon.v
		end
		pInfo.set.bsync.enable = iVar.tracers.BulletTrackActivate.v
		pInfo.set.bsync.ponly = iVar.tracers.BulletTrackOnlyPlayer.v
		pInfo.set.bsync.polygon_enable =iVar.tracers. BulletTrackPolyginActivate.v
		pInfo.set.bsync.time = iVar.tracers.BulletTrackTime.v
		pInfo.set.bsync.maxLines = iVar.tracers.BulletTrackMaxLines.v
		pInfo.set.bsync.weightLine = iVar.tracers.BulletTrackMaxWeight.v
		pInfo.set.bsync.sizePolygon = iVar.tracers.BulletTrackSizePolygon.v
		pInfo.set.bsync.countCorners = iVar.tracers.BulletTrackCountPolygin.v
		pInfo.set.bsync.rotation = iVar.tracers.BulletTrackRotationPolygon.v

		newColor = imgui.ImColor.FromFloat4(shot_in_player.v[1], shot_in_player.v[2], shot_in_player.v[3], shot_in_player.v[4]):GetVec4()
		pInfo.set.bsync.colorPlayer = imgui.ImColor(newColor):GetU32()
		r, g, b, a = imgui.ImColor(pInfo.set.bsync.colorPlayer):GetRGBA()
		pInfo.set.bsync.colorPlayer = join_argb(a, r, g, b)

		newColor = imgui.ImColor.FromFloat4(shot_in_player_afk.v[1], shot_in_player_afk.v[2], shot_in_player_afk.v[3], shot_in_player_afk.v[4]):GetVec4()
		pInfo.set.bsync.colorPlayerAFK = imgui.ImColor(newColor):GetU32()
		r, g, b, a = imgui.ImColor(pInfo.set.bsync.colorPlayerAFK):GetRGBA()
		pInfo.set.bsync.colorPlayerAFK = join_argb(a, r, g, b)

		newColor = imgui.ImColor.FromFloat4(shot_in_vehicle.v[1], shot_in_vehicle.v[2], shot_in_vehicle.v[3], shot_in_vehicle.v[4]):GetVec4()
		pInfo.set.bsync.colorCar = imgui.ImColor(newColor):GetU32()
		r, g, b, a = imgui.ImColor(pInfo.set.bsync.colorCar):GetRGBA()
		pInfo.set.bsync.colorCar = join_argb(a, r, g, b)

		newColor = imgui.ImColor.FromFloat4(shot_in_static_obj.v[1], shot_in_static_obj.v[2], shot_in_static_obj.v[3], shot_in_static_obj.v[4]):GetVec4()
		pInfo.set.bsync.colorStaticObj = imgui.ImColor(newColor):GetU32()
		r, g, b, a = imgui.ImColor(pInfo.set.bsync.colorStaticObj):GetRGBA()
		pInfo.set.bsync.colorStaticObj = join_argb(a, r, g, b)

		newColor = imgui.ImColor.FromFloat4(shot_in_dynamic_obj.v[1], shot_in_dynamic_obj.v[2], shot_in_dynamic_obj.v[3], shot_in_dynamic_obj.v[4]):GetVec4()
		pInfo.set.bsync.colorDynamicObj = imgui.ImColor(newColor):GetU32()
		r, g, b, a = imgui.ImColor(pInfo.set.bsync.colorDynamicObj):GetRGBA()
		pInfo.set.bsync.colorDynamicObj = join_argb(a, r, g, b)

		if pInfo.set.bsync.enable == true then savedata ('b_enable', 1)
		else savedata ('b_enable', 0) end
		if pInfo.set.bsync.ponly == true then savedata ('b_ponly', 1)
		else savedata ('b_ponly', 0) end
		if pInfo.set.bsync.polygon_enable == true then savedata ('b_polygon_enable', 1)
		else savedata ('b_polygon_enable', 0) end
		savedata ('color_player', 2)
		savedata ('color_player_afk', 2)
		savedata ('color_car', 2)
		savedata ('color_static', 2)
		savedata ('color_dynamic', 2)
		savedata ('b_time', 2)
		savedata ('b_maxlines', 2)
		savedata ('b_weightlines', 2)
		savedata ('b_sizepolygon', 2)
		savedata ('b_countcorners', 2)
		savedata ('b_rotation', 2)

		sampAddChatMessage("[AHelper] {FFFFFF}Настройки трейсеров пуль сохранены", 0x4682B4)
	end
	imgui.EndChild()
end

function submenu_7()
	imgui.BeginChild ('settings_cheats', imgui.ImVec2(872, 587), true)

	imgui.SameLine(17)
	if imgui.Checkbox (u8'Активировать WH', iVar.cheat.wallhack) then
		pInfo.set.AutoWH = iVar.cheat.wallhack.v
		if pInfo.set.AutoWH == true then savedata ('wallhack', 1)
		else savedata ('wallhack', 0) end
		if pInfo.set.AutoWH then
			nameTagOn()
			pTemp.WH_Status = true
		else
			nameTagOff()
			pTemp.WH_Status = false
		end
	end
	if pInfo.set.AutoWH == true or pInfo.set.AutoWH == '1' then
		imgui.NewLine()
		imgui.SameLine(17)
	--	imgui.SameLine()
		imgui.PushItemWidth(250)
		local items_wh = {u8"Стандартный", u8"Скелет"}
		if imgui.Combo (u8"Тип WH", iVar.cheat.type_wh, items_wh) then
			pInfo.set.type_wh = iVar.cheat.type_wh.v
			savedata ("type_wh", 2)
		end
		imgui.NewLine()
	end
	imgui.Separator()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8"Активировать Airbrake (правый Shift)", iVar.cheat.air_activate) then
		pInfo.set.air_activate = iVar.cheat.air_activate.v
		if pInfo.set.air_activate == true then savedata ("air_act", 1)
		else savedata("air_act", 0) end
	end
	imgui.PushItemWidth(246)
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.SliderInt(u8'Скорость', iVar.cheat.air_speed, 1, 15);
	imgui.SameLine()
	if imgui.Button(u8"Сохранить##air") then
		sampAddChatMessage("[AHelper] {FFFFFF}Скорость сохранена", 0x4682B4)
		pInfo.set.AirBrakeSpeed = tonumber(iVar.cheat.air_speed.v)
		savedata ('airbrake', 2)
	end
	imgui.NewLine()
	imgui.Separator()
	imgui.NewLine()
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8"Инвиз (onfoot)", iVar.cheat.invisible_onfoot) then
		pInfo.set.invisible_onfoot = iVar.cheat.invisible_onfoot.v
		if pInfo.set.invisible_onfoot == true then savedata ('invisible', 1)
		else savedata ('invisible', 0) end
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox (u8'Телепорт на колёсико', iVar.cheat.clickwarp) then
		pInfo.set.clickwarp = iVar.cheat.clickwarp.v
		if pInfo.set.clickwarp == true then savedata ('clickwarp', 1)
		else savedata ('clickwarp', 0) end
	end

	imgui.EndChild()
end

function submenu_9()
	imgui.BeginChild ('settings_hotkeys', imgui.ImVec2(872, 587), true)
	for i in ipairs (uhkey) do
		imgui_hkey[i].v = u8(uhkey[i]['key'])
		imgui.SameLine(17)
		imgui.Text (u8(imgui_action[i]))
		imgui.SameLine(290)
		imgui.PushItemWidth(180)
		imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00)
		imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(1.00, 0.39, 0.39, 1.00);
		if imgui.ActiveButtonKey(i, imgui_hkey[i].v..'##'..i) then
			if pTemp.setkey == i then pTemp.setkey = 0 else pTemp.setkey = i end
		end
		imgui.Separator()
		imgui.NewLine()
	end
	imgui.EndChild()
end

function submenu_8()
	imgui.BeginChild ('settings_cmd_enter', imgui.ImVec2(872, 587), true)
	for i, k in ipairs(a_cmd) do
		imgui.NewLine()
		imgui.SameLine(17)
		imgui.InputText(string.format (u8"Команда ##%d", i), change_cmd[i])
		imgui.NewLine()
		imgui.SameLine(17)
		if imgui.Button(u8(string.format ("Сохранить##%d", i))) then
			local upd_cmds = {}
			upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&cmd="..u8:decode(change_cmd[i].v).."&id="..k.id
			upd_cmds.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request ('POST', sInfo.url.."/cmd_upd.php", upd_cmds,
			function (response)
			--response = requests.post ("http://martin-rojo.myjino.ru/upd_answers.php", upd_rep)
				if u8:decode(response.text):find("Данные обновлены") then
					--load_answers()
					pTemp.user.load_custom_cmd = true
					sampAddChatMessage("[AHelper] {FFFFFF}Команда успешно изменена", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#6). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)
				print(err)
				return
			end)
		end
		imgui.SameLine()
		if imgui.Button(u8(string.format ("Удалить##%d", i))) then
			local upd_cmds = {}
			upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&id="..k.id
			upd_cmds.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request ('POST', sInfo.url.."/cmd_del.php", upd_cmds,
			function (response)
			--response = requests.post ("http://martin-rojo.myjino.ru/del_answers.php", upd_rep)
				if u8:decode(response.text):find("Данные удалены") then
					--load_answers()
					pTemp.user.load_custom_cmd = true
					sampAddChatMessage("[AHelper] {FFFFFF}Команда успешно удалена", 0x4682B4)
				elseif u8:decode(response.text):find("Запрос не сработал") then
					sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
				elseif u8:decode(response.text):find("Не получены данные") then
					sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#7). Работа скрипта остановлена.", 0xFF0000)
					print("RepUpd ErrTrue: "..u8:decode(response.text))
					thisScript():unload()
				end
			end,
			function (err)
				print(err)
				return
			end)
		end
		imgui.NewLine()
		imgui.Separator()
		imgui.NewLine()
	end
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Button(u8'Добавить новую команду') then
		local upd_cmds = {}
		upd_cmds.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber
		upd_cmds.headers = {
			['content-type']='application/x-www-form-urlencoded'
		}
		async_http_request ('POST', sInfo.url.."/cmd_add.php", upd_cmds,
		function (response)
		--response = requests.post ("http://martin-rojo.myjino.ru/add_answer.php", upd_rep)
			if u8:decode(response.text):find("Данные добавлены") then
				--load_answers()
				pTemp.user.load_custom_cmd = true
				sampAddChatMessage("[AHelper] {FFFFFF}Новая строка для команды успешно добавлена", 0x4682B4)
			elseif u8:decode(response.text):find("Запрос не сработал") then
				sampAddChatMessage("[AHelper] {FFFFFF}Произошла ошибка при обновлении", 0x4682B4)
			elseif u8:decode(response.text):find("Не получены данные") then
				sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#7). Работа скрипта остановлена.", 0xFF0000)
				print("RepUpd ErrTrue: "..u8:decode(response.text))
				thisScript():unload()
			end
		end,
		function (err)
			print(err)
			return
		end)
	end
	imgui.EndChild()
end

function showImage_1()
    imgui.TextDisabled(u8'(Скриншот)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
		imgui.Image(RE_STYLE_1, imgui.ImVec2(250, 250))
        imgui.EndTooltip()
    end
end

function showImage_2()
    imgui.TextDisabled(u8'(Скриншот)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
		imgui.Image(RE_STYLE_2, imgui.ImVec2(480, 80))
        imgui.EndTooltip()
    end
end

function showImage_3()
    imgui.TextDisabled(u8'(Скриншот)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
		imgui.Image(RE_RIGHT_PANEL, imgui.ImVec2(330, 270))
        imgui.EndTooltip()
    end
end

function ConverterNotNull(seconds) -- Костыль
	seconds = tonumber (seconds)
	if seconds > 86400 then
		local days, hrs = math.modf (seconds / 86400)
		local minutes = math.floor (seconds / 60)
		local hours = math.floor (hrs * 24)
		local mnts = seconds - 86400 * days
		mnts = math.floor (mnts/60)
		seconds = seconds - minutes * 60
		mnts = mnts - hours * 60
		new_time = string.format ("%d дн. %d:%02d:%02d", days, hours, mnts, seconds)
	elseif seconds < 3600 then
		local minutes = math.floor(seconds/60)
		seconds = seconds - minutes * 60
		new_time = string.format ("%d:%02d", minutes, seconds)
	else
		local minutes = math.floor(seconds/60)
		local hours = math.floor(minutes/60)
		seconds = seconds - minutes * 60
		minutes = minutes - hours * 60
		new_time = string.format ("%d:%02d:%02d", hours, minutes, seconds)
	end
	return new_time
end

function Converter(seconds)
	seconds = tonumber (seconds)
	if seconds > 86400 then
		local days, hrs = math.modf (seconds / 86400)
		local minutes = math.floor (seconds / 60)
		local hours = math.floor (hrs * 24)
		local mnts = seconds - 86400 * days
		mnts = math.floor (mnts/60)
		seconds = seconds - minutes * 60
		mnts = mnts - hours * 60
		new_time = string.format ("%d дн. %02d:%02d:%02d", days, hours, mnts, seconds)
	elseif seconds < 3600 then
		local minutes = math.floor(seconds/60)
		seconds = seconds - minutes * 60
		new_time = string.format ("%02d:%02d", minutes, seconds)
	else
		local minutes = math.floor(seconds/60)
		local hours = math.floor(minutes/60)
		seconds = seconds - minutes * 60
		minutes = minutes - hours * 60
		new_time = string.format ("%d:%02d:%02d", hours, minutes, seconds)
	end
	return new_time
end

function showHelp(param)
    imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(imgui.GetFontSize() * 35.0)
        imgui.TextUnformatted(param)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function imgui.ActiveButton(id, ...)
	if id == pTemp.submenu_id then
		imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00)
		imgui.Button(...)
		imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00);
	else
		return imgui.Button(...)
	end
end

function imgui.ActiveButtonPunish(id, ...)
	if id == pTemp.exchange_id then
		imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.22, 0.85, 0.12, 1.00)
		imgui.GetStyle().Colors[imgui.Col.ButtonHovered]  	= imgui.ImVec4(0.22, 0.85, 0.12, 1.00)
		return imgui.Button(...)
	else
		return imgui.Button(...)
	end
end

function imgui.ActiveButtonKey(id, ...)

	if id == pTemp.setkey then
		imgui.GetStyle().Colors[imgui.Col.Button] 			= imgui.ImVec4(0.22, 0.85, 0.12, 1.00)
		imgui.GetStyle().Colors[imgui.Col.ButtonHovered]  	= imgui.ImVec4(0.22, 0.85, 0.12, 1.00)
		return imgui.Button(...)
		--imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00)
	else
		return imgui.Button(...)
	end
end

function imgui.ActiveButtonMC(id, ...)
	if id == pTemp.menu_id then
		imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00)
		imgui.Button(...)
		imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00);
	else
		return imgui.Button(...)
	end
end

function enableFPSUnlock()
	local result, samphandle = loadDynamicLibrary("samp.dll")
	if result then
		local wmem = samphandle + 0x9D9D0
		writeMemory(wmem, 4, 0x5051FF15, 1)
		writeMemory(0xBAB318, 1, 0, 1)
		writeMemory(0x53E94C, 1, 0, 1)
	else
		aidAddChatMessage("[AHelper] {FFFFFF}FPSUnlock не активирован: не удалось открыть библиотеку SA-MP", 0x4682B4)
	end
end


function onScriptLoad (script)
	if script == thisScript() then
		if not doesDirectoryExist("moonloader\\lib\\samp") then
			createDirectory("moonloader\\lib\\samp")
			createDirectory("moonloader\\lib\\samp\\events")
		end
		if not doesDirectoryExist("moonloader\\resource") then
			createDirectory("moonloader\\resource")
			createDirectory("moonloader\\resource\\fonts")
		end
		if not doesDirectoryExist("moonloader\\lib\\ssl") then
			createDirectory("moonloader\\lib\\ssl")
		end
		if not doesDirectoryExist("moonloader\\lib\\lanes") then
			createDirectory("moonloader\\lib\\lanes")
		end
		if not doesDirectoryExist("moonloader\\lib\\cjson") then
			createDirectory("moonloader\\lib\\cjson")
		end
		if not doesDirectoryExist("moonloader\\lib\\mime") then
			createDirectory("moonloader\\lib\\mime")
		end
		if not doesDirectoryExist("moonloader\\lib\\socket") then
			createDirectory("moonloader\\lib\\socket")
		end
		if not doesDirectoryExist("moonloader\\lib\\xml") then
			createDirectory("moonloader\\lib\\xml")
		end
		if not doesDirectoryExist("moonloader\\lib\\md5") then
			createDirectory("moonloader\\lib\\md5")
		end
		if not doesDirectoryExist("moonloader\\lib\\lub") then
			createDirectory("moonloader\\lib\\lub")
		end
		if not doesDirectoryExist("moonloader\\lib\\slnet") then
			createDirectory("moonloader\\lib\\slnet")
		end
		if not doesFileExist('AHelper\\settings.ini') then
			inicfg.save(aInfo, 'AHelper\\settings.ini')
		end
	end
end

function chatlogwrite(slot0)
	slot1 = io.open(getGameDirectory() .. "\\moonloader\\config\\AHelper\\chatlogs\\" .. pInfo.set.chatlog_name .. ".txt", "a")

	slot1:write(slot0 .. "\n")
	slot1:close()
end

function makeScreenshot(disable) -- если передать true, интерфейс и чат будут скрыты
    if disable then displayHud(false) sampSetChatDisplayMode(0) end
    require('memory').setuint8(sampGetBase() + 0x119CBC, 1)
    if disable then displayHud(true) sampSetChatDisplayMode(2) end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		inicfg.save(aInfo, "AHelper\\settings.ini")
		client:send_packet(4, getLocalPlayerName())
	end
end

function onExitScript(quitGame)
	client:send_packet(4, getLocalPlayerName())
end

function sampev.onSendCommand (cmd)
	if pInfo.set.newLip == true or pInfo.set.newLip == '1' then
		if cmd:find ("/lip") or cmd:find ("/rip") and pInfo.info.adminLevel >= 6 then
			checkBansIp = os.time() + 5
			counter_array = 1
			for i in ipairs (infban_array) do table.remove(infban_array, i) end
			for i in ipairs (infban_ip_array) do table.remove(infban_ip_array, i) end
			sampAddChatMessage("[AHelper] {FFFFFF}Идёт формирование списка аккаунтов...", 0x4682B4)
		end
		if cmd:find ("/infban") then
			if waitInfban < os.time() then kostyl = os.time() + 1 end
		end
	end
	if cmd:find ("/infjail ") then
		local arg = cmd:match ("/infjail (.*)")
		if type(tonumber(arg)) == 'number' then
			local arg = tonumber (arg)
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if arg == nil then
				arg = myId
			end
			if sampIsPlayerConnected(arg) and arg ~= myId then
				sampSendChat("/infjail "..getPlayerName(arg))
				return false
			end
		end
	end
	if cmd:find ("/infmute ") then
		local arg = cmd:match ("/infmute (.*)")
		if type(tonumber(arg)) == 'number' then
			local arg = tonumber (arg)
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if arg == nil then
				arg = myId
			end
			if sampIsPlayerConnected(arg) and arg ~= myId then
				sampSendChat("/infmute "..getPlayerName(arg))
				return false
			end
		end
	end
	if pTemp.login == true then
		if cmd:find("/cban ") then
			if pInfo.info.adminLevel >= 4 then
				if pTemp.cmd_antiflood > os.time() then
					sampAddChatMessage('Не флудите', -1)
					return false
				end
				local id, days, text = string.match(cmd, "/cban (%d+)%s+(%d+)%s+(.+)")
				if id ~= nil and text ~= nil and days ~= nil then
					local _, myId = sampGetPlayerIdByCharHandle(playerPed)
					if id == nil then
						id = myId
					end
					id = tonumber (id)
					myId = tonumber (myId)
					days = tonumber (days)
					if sampIsPlayerConnected(id) and id ~= myId then
						local name = getLocalPlayerName()
						local player = getPlayerName(id)
						pTemp.punish.cban = true
						pTemp.punish.days = days
						if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
					end
				end
			end
		elseif cmd:find("/ban ") then
			if pInfo.info.adminLevel >= 3 then
				if pTemp.cmd_antiflood > os.time() then
					sampAddChatMessage('Не флудите', -1)
					return false
				end
				local id, days, text = string.match(cmd, "/ban (%d+)%s+(%d+)%s+(.+)")
				if id ~= nil and text ~= nil and days ~= nil then
					local _, myId = sampGetPlayerIdByCharHandle(playerPed)
					if id == nil then
						id = myId
					end
					id = tonumber (id)
					myId = tonumber (myId)
					days = tonumber (days)
					if sampIsPlayerConnected(id) and id ~= myId then
						local name = getLocalPlayerName()
						local player = getPlayerName(id)
						pTemp.punish.ban = true
						pTemp.punish.days = days
						if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
					end
				end
			end
		elseif cmd:find("/sban ") then
			if pInfo.info.adminLevel >= 4 then
				if pTemp.cmd_antiflood > os.time() then
					sampAddChatMessage('Не флудите', -1)
					return false
				end
				local id, days, text = string.match(cmd, "/sban (%d+)%s+(%d+)%s+(.+)")
				if id ~= nil and text ~= nil and days ~= nil then
					local _, myId = sampGetPlayerIdByCharHandle(playerPed)
					if id == nil then
						id = myId
					end
					id = tonumber (id)
					myId = tonumber (myId)
					days = tonumber (days)
					if sampIsPlayerConnected(id) and id ~= myId then
						local name = getLocalPlayerName()
						local player = getPlayerName(id)
						pTemp.punish.sban = true
						pTemp.punish.days = days
						if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
					end
				end
			end
		elseif cmd:find("/scban ") then
			print ('/scban')
			if pInfo.info.adminLevel >= 5 then
				if pTemp.cmd_antiflood > os.time() then
					sampAddChatMessage('Не флудите', -1)
					return false
				end
				local id, days, text = string.match(cmd, "/scban (%d+)%s+(%d+)%s+(.+)")
				if id ~= nil and text ~= nil and days ~= nil then
					local _, myId = sampGetPlayerIdByCharHandle(playerPed)
					if id == nil then
						id = myId
					end
					id = tonumber (id)
					myId = tonumber (myId)
					days = tonumber (days)
					if sampIsPlayerConnected(id) and id ~= myId then
						local name = getLocalPlayerName()
						local player = getPlayerName(id)
						pTemp.punish.scban = true
						pTemp.punish.days = days
						if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
					end
				end
			end
		elseif cmd:find("/pm ") then
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return false
			end
		elseif cmd:find ("/unban ") then
			if pInfo.info.adminLevel >= 3 then
				local text = string.match(cmd, "/unban (.+)")
				if text ~= nil then
					local name = getLocalPlayerName()
					pTemp.punish.unban = true
				end
			end
		elseif cmd:find ("/uncban ") then
			if pInfo.info.adminLevel >= 4 then
				local text = string.match(cmd, "/uncban (.+)")
				if text ~= nil then
					local name = getLocalPlayerName()
					UpdStop = false
					pTemp.punish.uncban = true
				end
			end
		elseif cmd:find ("/unbanip ") then
			if pInfo.info.adminLevel >= 4 then
				local text = string.match(cmd, "/unbanip (.+)")
				if text ~= nil then
					local name = getLocalPlayerName()
					pTemp.punish.unbanip = true
					pTemp.punish.days = days
				end
			end
		elseif cmd:find ("/offban ") then
			if pInfo.info.adminLevel >= 3 then
				pTemp.punish.d_days, pTemp.punish.d_nick = cmd:match ("/offban (%d+)%s+(.*)")
				if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil then
					pTemp.punish.da_status = true
				end
			end
		elseif cmd:find ("/offcban ") then
			if pInfo.info.adminLevel >= 4 then
				pTemp.punish.d_days, pTemp.punish.d_nick = cmd:match ("/offcban (%d+)%s+(.*)")
				if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil then
					pTemp.punish.cstatus = true
				end
			end
		elseif cmd:find ("/offmute ") then
			if pInfo.info.adminLevel >= 3 then
				pTemp.punish.d_days, pTemp.punish.d_nick = cmd:match ("/offmute (%d+)%s+(.*)")
				if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil then
					pTemp.punish.da_mstatus = true
				end
			end
		elseif cmd:find ("/offjail ") then
			if pInfo.info.adminLevel >= 3 then
				pTemp.punish.d_days, pTemp.punish.d_nick = cmd:match ("/offjail (%d+)%s+(.*)")
				if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil then
					pTemp.punish.da_jstatus = true
				end
			end
		elseif cmd:find ("/jail ") then
			if pInfo.info.adminLevel >= 2 then
				if pTemp.cmd_antiflood > os.time() then
					sampAddChatMessage('Не флудите', -1)
					return false
				end
				local id, days, text = string.match(cmd, "/jail (%d+)%s+(%d+)%s+(.+)")
				if id ~= nil and text ~= nil and days ~= nil then
					local _, myId = sampGetPlayerIdByCharHandle(playerPed)
					if id == nil then
						id = myId
					end
					id = tonumber (id)
					myId = tonumber (myId)
					days = tonumber (days)
					if sampIsPlayerConnected(id) and id ~= myId then
						local name = getLocalPlayerName()
						local player = getPlayerName(id)
						pTemp.punish.jail = true
						pTemp.punish.days = days
						if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
					end
				end
			end
		end
	end
end

function sampev.onServerMessage(color, text)
	if text == "Данный режим доступен с звания ''Новичок'' (/rank)" then
		sampAddChatMessage("[AHelper] {FFFFFF}Сейчас вы не можете перейти на GangWar. Режим изменён", 0x4682B4)
		aInfo.set.typeSpawn = 1
	end

	if text:find ('возможно использует AirBreak') then
		local nick, id = text:match ('%{FF0000%}%[AntiCheat%] %{ffffff%}(.*) %[ID:(%d+)%] возможно использует')
		local bitstream = BitStream()
		bitstream:write('unsigned char', 144)
		bitstream:write('string', 'air | '..srv..' | '..nick..' | '..id)
		client:send_packet(10, bitstream)
	end

	if text:find ('вероятно использует Aim') then
		local nick, id = text:match ('%{FF0000%}%[AntiCheat%] %{ffffff%}(.*) %[ID:(%d+)%] вероятно использует')
		local bitstream = BitStream()
		bitstream:write('unsigned char', 144)
		bitstream:write('string', 'aim | '..srv..' | '..nick..' | '..id)
		client:send_packet(10, bitstream)
	end

	if text == "Неверный пароль!" then
		aInfo.set.lPass_On = false
		aInfo.info.lPass = ""
	end

	if aInfo.set.chatlog == true then
		chatlogwrite(tostring("[" .. os.date("%d") .. "-" .. os.date("%m") .. "-" .. os.date("%y") .. " " .. os.date("%H") .. ":" .. os.date("%M") .. ":" .. os.date("%S") .. "] " .. text))
	end

	if string.find (text, 'Личные сообщения включ') and pTemp.pers_activate == false and pInfo.set.AutoTogphone == '1'  then
		sampSendChat("/togphone")
	end

	if pTemp.login then

		if id_x ~= nil then
			if pAct.pSucc[id_x] == false and pAct.pSucc[id_x] ~= nil then
				if pAct.pType[id_x] == "/offunmute" then
					if text:find ("Аккаунт не найден") then
						err_type = 2
						err_mes = "Аккаунт не найден"
					elseif text:find ("У данного игрока нет бана чата!") or text:find ("У данного игрока нету бана чата") then
						err_type = 3
						err_mes = "У данного игрока нет бана чата"
					elseif text:find(string.format ("Администратор %s", userNick)) then
						if text:match("Администратор (.*) снял бан чата у игрока (.*)") or text:match("Администратор (.*) снял бан чата оффлайн игроку (.*)") then
							err_type = 1
							err_mes = "Бан чата снят"
						end
					end
				elseif pAct.pType[id_x] == "/offunjail" then
						if text:find ("Аккаунт не найден") then
							err_type = 2
							err_mes = "Аккаунт не найден"
						elseif text:find ("Данный игрок не находится в тюрьме") then
							err_type = 3
							err_mes = "Данный игрок не находится в тюрьме"
						elseif text:find(string.format ("Администратор %s", userNick)) then
							if text:match("Администратор (.*) выпустил из тюрьмы игрока (.*)") or text:match("Администратор (.*) выпустил из тюрьмы оффлайн игрока (.*)") then
								err_type = 1
								err_mes = "Игрок выпущен из КПЗ"
							end
						end
				elseif pAct.pType[id_x] == "/unban" then
					if text:find ("Игрок не забанен") then
						err_type = 3
						err_mes = "Игрок не забанен или такого аккаунта не существует"
					elseif text:find(string.format ("Администратор %s", userNick)) then
						if text:match ("Администратор (.*) разбанил аккаунт (.*)") then
							err_type = 1
							err_mes = "Аккаунт разбанен"
						end
					end
				elseif pAct.pType[id_x] == "/uncban" then
					if text:find ("Ник/IP не забанен!") then
						err_type = 3
						err_mes = "Ник/IP не забанен или такого аккаунта не существует"
					elseif text:find(string.format ("Администратор %s", userNick)) then
						if text:match ("Администратор (.*) разбанил (.*) и (.-)") then
							err_type = 1
							err_mes = "Аккаунт/IP разбанен"
						end
					end
				end
				pAct.pSucc[id_x] = true
			end
		end

		if pInfo.set.AutoHideIP == true then
			if text:match ("(%d+)%.(%d+)%.(%d+)%.(%d+)") then
				text = text:gsub ("(%d+)%.(%d+)%.(%d+)%.(%d+)", "<< IP адрес скрыт >>")
				return {color, text}
			end
		end

		if pInfo.set.converter == true or pInfo.set.converter == '1' then
			if text:find ("UnMute: ") then
				local nick, adm, reas, time_sec = text:match("Аккаунт (.*) | Кем: (.*) | Причина: (.*) | UnMute: (%d+) сек")
				local c_time = Converter (time_sec)
				sampAddChatMessage(string.format ("Аккаунт: %s | Кем: %s | Причина: %s | UnMute: %s (%d сек.)", nick, adm, reas, c_time, time_sec), -1)
				return false
			end

			if text:find ("UnJail: ") then
				local nick, adm, reas, time_sec = text:match("Аккаунт (.*) | Кем: (.*) | Причина: (.*) | UnJail: (%d+) сек")
				local c_time = Converter (time_sec)
				sampAddChatMessage(string.format ("Аккаунт: %s | Кем: %s | Причина: %s | UnJail: %s (%d сек.)", nick, adm, reas, c_time, time_sec), -1)
				return false
			end
		end

		local mesReport = string.match(text, "^%{FF4366%}(.*)")
		local mesPm = string.match(text, "^%{488331%}(.*)")

		local mesGang = string.match (text, "^{01FCFF}(.*)")
		if mesGang and text:find ("^%{01FCFF%}%*%*") then
			--print (mesGang)
			print (text)
			--local tag, gtext = text:match ("^%{01FCFF%}%*%* (.+)%} (.*) %*%*")
			--print (tag..'}')
			--print (gtext)
			--sampAddChatMessage('** ', color)
		end


		if mesReport then
			r, g, b, a = imgui.ImColor(pInfo.set.colorReport):GetRGBA()
			local nColor = join_argb(r, g, b, 255)
			return {pInfo.set.recolor_r and nColor or 0xFF4366FF, mesReport}
		end

		if mesPm then
			if text:match ("%* (.*)%[(%d+)%] отвечает (.*)%[(%d+)%]: (.+)") then
				local admNick, admID, plNick, plID, reason = text:match ("%* (.*)%[(%d+)%] отвечает (.*)%[(%d+)%]: (.+)")
				if admNick == getLocalPlayerName() then
					add_logs ("/pm", admNick, plNick, 0, reason)
					pTemp.cmd_antiflood = os.time() + 6
				end
			end
			r, g, b, a = imgui.ImColor(pInfo.set.colorPm):GetRGBA()
			local nColor = join_argb(r, g, b, 255)
			return {pInfo.set.recolor_p and nColor or 0x488331FF, mesPm}
		end

		if pInfo.set.bindAccess then
			if text:find ("%[Стандартный чат%]") or text:find("%[/f%]") or text:find("%[/o%]") or text:find("%[/sms%]") then
				if text:match ("%[(.*)%] (.*) %[ID:(%d+)%]: .*") then
					local chat_type, nick, id, mess = text:match ("%[(.*)%] (.*) %[ID:(%d+)%]: (.*)")
					pTemp.s_id = id
					pTemp.fast_punish = 1
					pTemp.time_message = os.time()
					local tkey1 = uhkey[12]['key']
					if tkey1:find ('^L') and tkey1 ~= 'L' then tkey1 = tkey1:gsub ('^L', '') end
					local tkey2 = uhkey[13]['key']
					if tkey2:find ('^L') and tkey2 ~= 'L' then tkey2 = tkey2:gsub ('^L', '') end
					sampAddChatMessage("[AHelper] {FFFFFF}Подозрение на упоминание/оскорбление родных", 0x4682B4)
					sampAddChatMessage("[AHelper] {FFFFFF}Нажмите {EB472A}"..tkey1.."{FFFFFF}, чтобы выдать бан или {EB472A}"..tkey2.."{FFFFFF}, чтобы выдать мут", 0x4682B4)
					print (id, nick, chat_type, mess)
					table.insert (rlist, {
						id = id,
						nick = nick,
						chat_type = chat_type,
						mess = mess,
						online = true,
						time = os.date("%H:%M:%S")
					})
				end
			end
		end

		if text:match ("Администратор (.*) выдал бан чата игроку (.*) на (%d+) минут. Причина: (.*)") then
			local admNick, plNick, value, reason = text:match ("Администратор (.*) выдал бан чата игроку (.*) на (%d+) минут. Причина: (.*)")
			for i, v in ipairs (rlist) do
				if v.nick == plNick then
					table.remove (rlist, i)
				end
			end
		elseif text:match ("Администратор (.*) забанил игрока (.*). Причина: (.*)") then
			local admNick, plNick, reason = text:match ("Администратор (.*) забанил игрока (.*). Причина: (.*)")
			for i, v in ipairs (rlist) do
				if v.nick == plNick then
					table.remove (rlist, i)
				end
			end
		elseif text:match ("Администратор (.*) по%-тихому забанил игрока (.*). Причина: (.*)") then
			local admNick, plNick, reason = text:match ("Администратор (.*) по%-тихому забанил игрока (.*). Причина: (.*)")
			for i, v in ipairs (rlist) do
				if v.nick == plNick then
					table.remove (rlist, i)
				end
			end
		end

		if text:find(string.format ("Администратор %s", getLocalPlayerName())) then
			if text:match ("Администратор (.*) выдал бан чата игроку (.*) на (%d+) минут. Причина: (.*)") then
				local admNick, plNick, value, reason = text:match ("Администратор (.*) выдал бан чата игроку (.*) на (%d+) минут. Причина: (.*)")
				add_logs ("/mute", admNick, plNick, value, reason)
				pTemp.cmd_antiflood = os.time()+6
				if (pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true) and pTemp.acr then
					lua_thread.create (function()
						wait (500)
						makeScreenshot(disable)
						pTemp.acr = false
					end)
				end
				if pTemp.s_id ~= sInfo.MAX_PLAYERS then if plNick == getPlayerName(pTemp.s_id) then pTemp.fast_punish = 0 end end
			elseif text:find ("тихому кикнул игрока") then
				local admNick, plNick, reason = text:match ("Администратор (.*) по%-тихому кикнул игрока (.*). Причина: (.*)")
				add_logs ("/skick", admNick, plNick, 0, reason)
				pTemp.cmd_antiflood = os.time()+6
			elseif text:match("Администратор (.*) кикнул игрока (.*). Причина: (.*)") then
				local admNick, plNick, reason = text:match ("Администратор (.*) кикнул игрока (.*). Причина: (.*)")
				add_logs ("/kick", admNick, plNick, 0, reason)
				pTemp.cmd_antiflood = os.time()+6
			elseif text:match("Администратор (.*) снял бан чата у игрока (.*)") then
				local admNick, plNick = text:match("Администратор (.*) снял бан чата у игрока (.*)")
				add_logs ("/unmute", admNick, plNick, 0, "*no_reason*")
				pTemp.cmd_antiflood = os.time()+6
			elseif text:match("Администратор (.*) снял бан чата оффлайн игроку (.*)") then
				local admNick, plNick = text:match("Администратор (.*) снял бан чата оффлайн игроку (.*)")
				add_logs ("/offunmute", admNick, plNick, 0, "*no_reason*")
				pTemp.cmd_antiflood = os.time()+6
			elseif text:match ("Администратор (.*) забанил игрока (.*). Причина: (.*)") and pTemp.punish.ban == true then
				local admNick, plNick, reason = text:match ("Администратор (.*) забанил игрока (.*). Причина: (.*)")
				if admNick == getLocalPlayerName() then add_logs ("/ban", admNick, plNick, pTemp.punish.days, reason) end
				if pTemp.s_id ~= sInfo.MAX_PLAYERS then if plNick == getPlayerName(pTemp.s_id) then pTemp.fast_punish = 0 end end
				pTemp.punish.ban = false
				pTemp.cmd_antiflood = os.time()+6
				if (pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true) and pTemp.acr then
					lua_thread.create (function()
						wait (500)
						makeScreenshot(disable)
						pTemp.acr = false
					end)
				end
			elseif text:match ("Администратор (.*) забанил игрока (.*). Причина: (.*)") and pTemp.punish.cban == true then
				local admNick, plNick, reason = text:match ("Администратор (.*) забанил игрока (.*). Причина: (.*)")
				print (admNick, getLocalPlayerName())
				if admNick == getLocalPlayerName() then add_logs ("/cban", admNick, plNick, pTemp.punish.days, reason) end
				if pTemp.s_id ~= sInfo.MAX_PLAYERS then if plNick == getPlayerName(pTemp.s_id) then pTemp.fast_punish = 0 end end
				pTemp.punish.cban = false
				pTemp.cmd_antiflood = os.time()+6
				if (pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true) and pTemp.acr then
					lua_thread.create (function()
						wait (500)
						makeScreenshot(disable)
						pTemp.acr = false
					end)
				end
			elseif text:match ("Администратор (.*) по%-тихому забанил игрока (.*). Причина: (.*)") and pTemp.punish.sban == true then
				local admNick, plNick, reason = text:match ("Администратор (.*) по%-тихому забанил игрока (.*). Причина: (.*)")
				if admNick == getLocalPlayerName() then add_logs ("/sban", admNick, plNick, pTemp.punish.days, reason) end
				if pTemp.s_id ~= sInfo.MAX_PLAYERS then if plNick == getPlayerName(pTemp.s_id) then pTemp.fast_punish = 0 end end
				pTemp.punish.sban = false
				pTemp.cmd_antiflood = os.time()+6
				if (pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true) and pTemp.acr then
					lua_thread.create (function()
						wait (500)
						makeScreenshot(disable)
						pTemp.acr = false
					end)
				end
			elseif text:match ("Администратор (.*) по%-тихому забанил игрока (.*). Причина: (.*)") and pTemp.punish.scban == true then
				local admNick, plNick, reason = text:match ("Администратор (.*) по%-тихому забанил игрока (.*). Причина: (.*)")
				print ('выполнено 1')
				if admNick == getLocalPlayerName() then add_logs ("/scban", admNick, plNick, pTemp.punish.days, reason) end
				if pTemp.s_id ~= sInfo.MAX_PLAYERS then if plNick == getPlayerName(pTemp.s_id) then pTemp.fast_punish = 0 end end
				pTemp.punish.scban = false
				pTemp.cmd_antiflood = os.time()+6
				if (pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true) and pTemp.acr then
					lua_thread.create (function()
						wait (500)
						makeScreenshot(disable)
						pTemp.acr = false
					end)
				end
			elseif text:match ("Администратор (.*) разбанил аккаунт (.*)") and pTemp.punish.unban == true then
				local admNick, plNick = text:match ("Администратор (.*) разбанил аккаунт (.*)")
				if admNick == getLocalPlayerName() then add_logs ("/unban", admNick, plNick, 0, "*no_reason*") end
				pTemp.punish.unban = false
			elseif text:match ("Администратор (.*) разбанил (.*) и (.-)") and pTemp.punish.uncban == true then
				local admNick, plNick, IP = text:match ("Администратор (.*) разбанил (.*) и (.-)")
				if admNick == getLocalPlayerName() then add_logs ("/uncban", admNick, plNick, 0, "*no_reason*") end
				pTemp.punish.uncban = false
			elseif text:match ("Администратор (.*) разбанил (.-)") and pTemp.punish.unbanip == true then
				local admNick, IP = text:match ("Администратор (.*) разбанил (.-)")
				if admNick == getLocalPlayerName() then add_logs ("/unbanip", admNick, IP, 0, "*no_reason*") end
				pTemp.punish.unbanip = false
			elseif text:match ("Администратор (.*) посадил в тюрьму игрока (.*). Причина: (.*)") then
				local admNick, plNick, reason = text:match ("Администратор (.*) посадил в тюрьму игрока (.*). Причина: (.*)")
				if admNick == getLocalPlayerName() and c_days ~= 0 then add_logs ("/jail", admNick, plNick, pTemp.punish.days, reason) end
				pTemp.punish.jail = false
				pTemp.cmd_antiflood = os.time()+6
			end
		end
		if text:find ("Администратор") then
			if text:find ("//") then
				if text:match("Администратор (.*) посадил в тюрьму игрока (.*). Причина: (.+) // (.*)") then
					local admNick, plNick, reason, mNick = text:match("Администратор (.*) посадил в тюрьму игрока (.*). Причина: (.+) // (.*)")
					if admNick == getLocalPlayerName() then
						add_logs("jail_form_y", admNick, plNick, -1, string.format ("%s // %s", reason, mNick))
						pTemp.cmd_antiflood = os.time()+6
					elseif mNick == getLocalPlayerName() then add_logs("jail_form", mNick, plNick, -1, reason) end
				elseif text:match("Администратор (.*) забанил игрока (.*). Причина: (.+) // (.*)") then
					local admNick, plNick, reason = text:match("Администратор (.*) забанил игрока (.*). Причина: (.*)")
					if admNick == getLocalPlayerName() then
						add_logs("ban_form_y", admNick, plNick, -1, reason)
						pTemp.cmd_antiflood = os.time()+6
					elseif mNick == getLocalPlayerName() then add_logs("ban_form", mNick, plNick, -1, reason) end
				end
			end
		end

		local mesAdmAct = string.match(text, "^%{FF6347%}(.*)")
		if mesAdmAct and text:find ("Администратор ") then
			r, g, b, a = imgui.ImColor(pInfo.set.p_admAct_color):GetRGBA()
			local nColor = join_argb(r, g, b, 255)
			return {pInfo.set.p_admAct and nColor or 0xFF6347FF, mesAdmAct}
		end

		if text == "{9EC73D}Для зачисления онлайна в статистику /ia необходимо заступить на дежурство (/duty)" then
			pTemp.user.checkAccount = true
			check_update_menu()
		end

		local mesSMS = string.match(text, "^%{FFD700%}(.*)")
		if mesSMS and text:find ("SMS от") then
			r, g, b, a = imgui.ImColor(pInfo.set.colorSMS):GetRGBA()
			local nColor = join_argb(r, g, b, 255)
			return {pInfo.set.recolor_s and nColor or 0xFFD700FF, mesSMS}
		end

		if pInfo.set.AutoHideChat == true then
			local aLvl, aNick, aId = text:match("%{00CD66%}%[A:(%d+)%] (%S+) %[ID:(%d+)%]:.*")
			if aLvl and aNick and aId then
				adminChat1 = string.format("{00CD66}[A:%d] %s [ID:%d]: {FFFFFF}<Сообщение скрыто>.", aLvl, aNick, aId)
				sampAddChatMessage(adminChat1, -1)
				return false
			end
		end

		local adminChat = string.match(text, "^%{00CD66%}(.*)")

		if adminChat then


			r, g, b, a = imgui.ImColor(pInfo.set.colorAChat):GetRGBA()
			local nColor = join_argb(r, g, b, 255)

			for i, v in ipairs (colorNicks) do
				if adminChat:find ("%[A:(%d+)%] "..v.nickname.." %[ID:(%d+)%]:.*") then
					local clr = ''
					local nclr = ''
					local nr, ng, nb, na = imgui.ImColor (tonumber(v.color)):GetRGBA()
					if pInfo.set.recolor_a then clr = join_argb (0, r, g, b)
					else clr = '00CD66' end
					nclr = join_argb (0, nr, ng, nb)
					local nickname = adminChat:match ("%] (.*) %[")
					if pInfo.set.recolor_a then adminChat = string.gsub (adminChat, "%] (.*) %[", "%] {"..string.format ('%06x', nclr).."}"..nickname.."{"..string.format ('%06x', clr).."} %[")
					else adminChat = string.gsub (adminChat, "%] (.*) %[", "%] {"..string.format ('%06x', nclr).."}"..nickname.."{00CD66} %[") end
				end
			end
			--print (rgbToHex(r..g..b))
			return {pInfo.set.recolor_a and nColor or 0x00CD66FF, adminChat}
		end

		if pInfo.set.newLip == true or pInfo.set.newLip == '1' then

			if kostyl < os.time() then

				if text:find ("LAST IP") then
					infban_type = "LAST IP"
					for nick, IP in text:gmatch ("(.*) | LAST IP: (.*)") do
						infban_array[counter_array] = nick
						infban_ip_array[counter_array] = IP
						use_IP = IP
						counter_array = counter_array + 1
					end
					return false
				end

				if text:find ("REG IP") then
					infban_type = "REG IP"
					for nick, IP in text:gmatch ("(.*) | REG IP: (.*)") do
						infban_array[counter_array] = nick
						infban_ip_array[counter_array] = IP
						use_IP = IP
						counter_array = counter_array + 1
					end
					return false
				end

				if (text:find ("| Кем:") and text:find ("Ban")) or text:find ("Аккаунт не забанен!") and waitInfban >= os.time() then
					--if checkBansIp ~= 0 then
					if text:find ("| Кем:") then
						local nick, anick, reason, type_p, ban_date = text:match ("Ник: (.*) | Кем: (.*) | Причина: (.*) | Тип: (.-) | Ban: (.-) |")
						local day, month, year, hour, minute = ban_date:match ("(%d+)%.(%d+)%.(%d+) %- (%d+%d+):(%d+%d+)")
						-- внизу упоротая хуйня
						local fix_time = tonumber(hour)-13
						day = tonumber (day)
						month = tonumber (month)
						year = tonumber (year)
						if fix_time < 0 then
							fix_time = 24-13+hour
							day = day - 1
							if day <= 0 then
								month = month - 1
								if month <= 0 then
									year = year - 1
								end
								if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12 then day = 31
								elseif month == 2 then
									if year == 2024 then day = 29
									else day = 28 end
								else
									day = 30
								end
							end
						end
						fix_time = string.format ("%02d.%02d.%d - %02d:%02d", day, month, year, fix_time, minute)
						if use_IP == infban_ip_array[counter_array] then sampAddChatMessage(string.format ("{EED2EE}%s | %s: %s | {FF0000}%s - %s - %s - %s", nick, infban_type, infban_ip_array[counter_array], anick, type_p, fix_time, reason), 0xFFFFFF) end
					elseif text:find ("Аккаунт не забанен!") then
						if use_IP == infban_ip_array[counter_array] then sampAddChatMessage(string.format ("{EED2EE}%s | %s: %s", infban_array[counter_array], infban_type, infban_ip_array[counter_array]), 0xFFFFFF ) end
					end
					counter_array = counter_array + 1
					return false
				end
				--end
			end

			if text:find ("| Кем:") and text:find ("Ban") and waitInfban < os.time() then
				local nick, anick, reason, type_p, ban_date, unban_date = text:match ("Ник: (.*) | Кем: (.*) | Причина: (.*) | Тип: (.-) | Ban: (.-) | UnBan: (.*)")
				local day, month, year, hour, minute = text:match ("| Ban: (%d+)%.(%d+)%.(%d+) %- (%d+):(%d+) |")
				local day1, month1, year1, hour1, minute1 = text:match ("| UnBan: (%d+)%.(%d+)%.(%d+) %- (%d+):(%d+)")
				-- внизу упоротая хуйня
				local fix_time = tonumber(hour)-13
				day = tonumber (day)
				month = tonumber (month)
				year = tonumber (year)
				if fix_time < 0 then
					fix_time = 24-13+hour
					day = day - 1
					if day <= 0 then
						month = month - 1
						if month <= 0 then
							year = year - 1
						end
						if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12 then day = 31
						elseif month == 2 then
							if year == 2024 then day = 29
							else day = 28 end
						else
							day = 30
						end
					end
				end

				local fix_time1 = tonumber(hour1)-13
				day1 = tonumber (day1)
				month1 = tonumber (month1)
				year1 = tonumber (year1)
				if fix_time1 < 0 then
					fix_time1 = 24-13+hour1
					day1 = day1 - 1
					if day1 <= 0 then
						month1 = month1 - 1
						if month1 <= 0 then
							year1 = year1 - 1
						end
						if month1 == 1 or month1 == 3 or month1 == 5 or month1 == 7 or month1 == 8 or month1 == 10 or month1 == 12 then day1 = 31
						elseif month1 == 2 then
							if year1 == 2024 then day1 = 29
							else day1 = 28 end
						else
							day1 = 30
						end
					end
				end
				fix_time = string.format ("%02d.%02d.%d - %02d:%02d", day, month, year, fix_time, minute)
				fix_time1 = string.format ("%02d.%02d.%d - %02d:%02d", day1, month1, year1, fix_time1, minute1)
				sampAddChatMessage(string.format ("Ник: %s | Кем: %s | Причина: %s | Тип: %s | Ban: %s | UnBan: %s", nick, anick, reason, type_p, fix_time, fix_time1),  -1)
				return false
			end
		else
			if text:find ("| Кем:") and text:find ("Ban") then
				local nick, anick, reason, type_p, ban_date, unban_date = text:match ("Ник: (.*) | Кем: (.*) | Причина: (.*) | Тип: (.-) | Ban: (.-) | UnBan: (.*)")
				local day, month, year, hour, minute = text:match ("| Ban: (%d+)%.(%d+)%.(%d+) %- (%d+):(%d+) |")
				local day1, month1, year1, hour1, minute1 = text:match ("| UnBan: (%d+)%.(%d+)%.(%d+) %- (%d+):(%d+)")
				-- внизу упоротая хуйня
				local fix_time = tonumber(hour)-13
				day = tonumber (day)
				month = tonumber (month)
				year = tonumber (year)
				if fix_time < 0 then
					fix_time = 24-13+hour
					day = day - 1
					if day <= 0 then
						month = month - 1
						if month <= 0 then
							year = year - 1
						end
						if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12 then day = 31
						elseif month == 2 then
							if year == 2024 then day = 29
							else day = 28 end
						else
							day = 30
						end
					end
				end

				local fix_time1 = tonumber(hour1)-13
				day1 = tonumber (day1)
				month1 = tonumber (month1)
				year1 = tonumber (year1)
				if fix_time1 < 0 then
					fix_time1 = 24-13+hour1
					day1 = day1 - 1
					if day1 <= 0 then
						month1 = month1 - 1
						if month1 <= 0 then
							year1 = year1 - 1
						end
						if month1 == 1 or month1 == 3 or month1 == 5 or month1 == 7 or month1 == 8 or month1 == 10 or month1 == 12 then day1 = 31
						elseif month1 == 2 then
							if year1 == 2024 then day1 = 29
							else day1 = 28 end
						else
							day1 = 30
						end
					end
				end
				fix_time = string.format ("%02d.%02d.%d - %02d:%02d", day, month, year, fix_time, minute)
				fix_time1 = string.format ("%02d.%02d.%d - %02d:%02d", day1, month1, year1, fix_time1, minute1)
				sampAddChatMessage(string.format ("Ник: %s | Кем: %s | Причина: %s | Тип: %s | Ban: %s | UnBan: %s", nick, anick, reason, type_p, fix_time, fix_time1),  -1)
				return false
			end
		end

	end
end

function rgbToHex(rgb)
	local hexadecimal = '0X'

	for key, value in pairs(rgb) do
		local hex = ''
		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex
		end
		if(string.len(hex) == 0)then
			hex = '00'
		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end
		hexadecimal = hexadecimal .. hex
	end
	return hexadecimal
end

function sampev.onPlayerSync (id, data)
	pTemp.re_panel.id = tonumber (pTemp.re_panel.id)
	if id == pTemp.re_panel.id and id == pTemp.spec_id and pTemp.spec_id ~= sInfo.MAX_PLAYERS then
		pTemp.re_panel.health = data.health
		pTemp.re_panel.armour = data.armor
		--if data.weapon == 0 then pTemp.re_panel.weapon = "No weapon" end
		pTemp.re_panel.speed = (math.floor(math.sqrt(data.moveSpeed.x^2 + data.moveSpeed.y^2 + data.moveSpeed.z^2) * 100) + 1)/2
		local result, cped = sampGetCharHandleBySampPlayerId(id)
		if result then
			pTemp.re_panel.skin = getCharModel(cped)
		end
	end

	if tonumber (pTemp.spec_id) == id then
		if data.keysData == 132 or data.keysData == 4 then keysDown[1] = true
		elseif data.keysData ~= 132 and data.keysData ~= 4 then 	keysDown[1] = false end

		if data.keysData == 128 or data.keysData == 132 then keysDown[2] = true
		elseif data.keysData ~= 128 and data.keysData ~= 132 then 	keysDown[2] = false end

		if data.keysData == 2 or data.keysData == 130 or data.keysData == 134 then keysDown[3] = true
		elseif data.keysData ~= 2 and data.keysData ~= 130  and data.keysData ~= 134 then 	keysDown[3] = false end

		if data.keysData == 8 or data.keysData == 40 then keysDown[4] = true
		elseif data.keysData ~= 8 and data.keysData ~= 40 then 	keysDown[4] = false end

		if data.keysData == 32 or data.keysData == 40 then keysDown[5] = true
		elseif data.keysData ~= 32 and data.keysData ~= 40 then 	keysDown[5] = false end

		if data.keysData == 1024 then keysDown[6] = true
		elseif data.keysData ~= 1024 then 	keysDown[6] = false end

		if data.keysData == 1 then keysDown[7] = true
		elseif data.keysData ~= 1 then 	keysDown[7] = false end

		if data.keysData == 16 then keysDown[8] = true
		elseif data.keysData ~= 16 then 	keysDown[8] = false end
	end
end

function onReceiveRpc (id, bitstream)
	if id == 105 then
		local td_re_panel = raknetBitStreamReadInt16(bitstream)
		local td_text = sampTextdrawGetString(td_re_panel)
		if td_text:find ("Name:_") then
			pTemp.re_panel.nick, pTemp.re_panel.id, pTemp.re_panel.kills, pTemp.re_panel.deaths, pTemp.re_panel.skill, pTemp.re_panel.loc = td_text:match ("Name:_(.*)_%[(%d+)%]~N~Kills%-Deaths:_(%d+)/(%d+)~n~Skill:_(.*)~N~Location:_(.*)")
		end
		if td_text:find ("Health%-Armour:_") then
			pTemp.re_panel.health, _, pTemp.re_panel.speed = td_text:match ("Health%-Armour:_(%d+)/(%d+)~N~PlayerSpeed:_(%d+)_km/h")
		end
		if td_text:find ("Weapon%-Ammo:") then
			pTemp.re_panel.weapon, pTemp.re_panel.ammo, pTemp.re_panel.shot, pTemp.re_panel.hit = td_text:match ("Weapon%-Ammo:_(.*)_%[(%d+)%]~N~WeaponShot:_(%d+)/(%d+)")
			if pTemp.re_panel.weapon == 'Kyћak' then pTemp.re_panel.weapon = "No weapon" end
		end
		if td_text:find ("Ping%-Loss:_") then
			pTemp.re_panel.ping, pTemp.re_panel.package_loss, pTemp.re_panel.fps, pTemp.re_panel.ip = td_text:match ("Ping%-Loss:_(%d+)/(.*)%~N~FPS:_(%d+)~N~IP:_(.*)~N~")
		end
	end
end

function load_requests_list()
	local punishments = {}
	punishments.data = "srv="..srv
	punishments.headers = {
		['content-type']='application/x-www-form-urlencoded'
	}
	for i = #rVar.pAdmin, 1, -1 do
		table.remove(rVar.pAdmin, i)
	end
	async_http_request('POST', sInfo.url..'/load_requests.php', punishments,
	function (response)
		if u8:decode(response.text):find("(%d+) | (%d+) | (.*) | (.*) | (%d+) | (.*) | (.*)") then
			local i = 1
			for id, admin_num, player, typ, tim, reas, adm in string.gmatch(u8:decode(response.text), "(%d+) | (%d+) | (.-) | (.-) | (%d+) | (.-) | (.-)\n") do
				rVar.pID[i] = id
				rVar.pNumAdmin[i] = admin_num
				rVar.pPlayer[i] = player
				rVar.pType[i] = typ
				rVar.pTime[i] = tim
				rVar.pReason[i] = reas
				rVar.pAdmin[i] = adm
				rVar.pStatusExt[i] = "not completed"
				i = i + 1
			end
			r_iterator = i - 1
			r_wait_req_time = 1
		end
	end,
	function (err)
		print (err)
	end)
	--response = requests.post ("http://martin-rojo.myjino.ru/load_requests.php", punishments)

end

function sampev.onBulletSync(playerid, data)
	if pInfo.set.bsync.ponly == true then
		if pTemp.spec_id == tonumber (playerid) then
			if data.target.x == -1 or data.target.y == -1 or data.target.z == -1 then
				return true
			end
			BulletSync.lastId = BulletSync.lastId + 1
			if BulletSync.lastId < 1 or BulletSync.lastId > BulletSync.maxLines then
				BulletSync.lastId = 1
			end
			local id = BulletSync.lastId
			BulletSync[id].enable = true
			BulletSync[id].tType = data.targetType
			--sampAddChatMessage(data.targetType, -1)
			BulletSync[id].time = os.time() + BulletSync[id].timeDelete
			BulletSync[id].o.x, BulletSync[id].o.y, BulletSync[id].o.z = data.origin.x, data.origin.y, data.origin.z
			BulletSync[id].t.x, BulletSync[id].t.y, BulletSync[id].t.z = data.target.x, data.target.y, data.target.z
		end
	else
		if data.target.x == -1 or data.target.y == -1 or data.target.z == -1 then
			return true
		end
		BulletSync.lastId = BulletSync.lastId + 1
		if BulletSync.lastId < 1 or BulletSync.lastId > BulletSync.maxLines then
			BulletSync.lastId = 1
		end
		local id = BulletSync.lastId
		BulletSync[id].enable = true
		BulletSync[id].tType = data.targetType
		BulletSync[id].time = os.time() + BulletSync[id].timeDelete
		BulletSync[id].o.x, BulletSync[id].o.y, BulletSync[id].o.z = data.origin.x, data.origin.y, data.origin.z
		BulletSync[id].t.x, BulletSync[id].t.y, BulletSync[id].t.z = data.target.x, data.target.y, data.target.z
	end

	if pInfo.set.warnings.textures == true or pInfo.set.warnings.textures == '1' then
		local result, colPoint = processLineOfSight (data.origin.x, data.origin.y, data.origin.z, data.target.x, data.target.y, data.target.z, true, false, false, true, true)

		if data.targetType == 1 and not isLineOfSightClear(data.origin.x, data.origin.y, data.origin.z, data.target.x, data.target.y, data.target.z, true, false, false, true, true) then
			local result, colPoint = processLineOfSight (data.origin.x, data.origin.y, data.origin.z, data.target.x, data.target.y, data.target.z, true, false, false, true, true)
			if colPoint.entityType == 1 and tonumber(pTemp.delay.textures[playerid]) < os.time() then
				local obj = getAllObjects()
				model = 0
                for i, val in ipairs(obj) do
                    local obs = val
                	model = getObjectModel(obs)
                end
				local tkey = uhkey[10]['key']
				if tkey:find ('^L') and tkey ~= 'L' then tkey = tkey:gsub ('^L', '') end
				sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал сквозь текстуру в %s[%d] с %s (model: %d) {FFFFFF}(Следить: %s)", getPlayerName(playerid), playerid, getPlayerName(data.targetId), data.targetId, getWeaponModelName (data.weaponId), model, tkey), 0xE33B27)
				pTemp.textures_id = playerid
				pTemp.delay.textures[playerid] = os.time() + warnings.delay_textures
				local bitstream = BitStream()
				bitstream:write('unsigned char', 144)
				bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
				client:send_packet(10, bitstream)
			end
		end
	end

	if pInfo.set.warnings.hit == true or pInfo.set.warnings.hit == '1' then
		if data.targetType == 1 then
			if data.weaponId == 24 then
				Hit.Deagle[playerid] = Hit.Deagle[playerid] + 1
				if Hit.Deagle[playerid] == pInfo.set.warnings.deagle then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Desert Eagle", getPlayerName(playerid), playerid, warnings.shooting.Deagle.maxHit), 0xE33B27)
					if aim_warnings.Deagle.count[playerid] == 0 then
						aim_warnings.Deagle.first = os.clock()
					end
					aim_warnings.Deagle.count[playerid] = aim_warnings.Deagle.count[playerid] + 1
					if aim_warnings.Deagle.count[playerid] == aim_warnings.Deagle.series and os.clock() - aim_warnings.Deagle.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.Deagle.count[playerid] = 0
					end
					Hit.Deagle[playerid] = 0
				end
			elseif data.weaponId == 31 then
				Hit.M4[playerid] = Hit.M4[playerid] + 1
				if Hit.M4[playerid] == pInfo.set.warnings.m4 then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с M4", getPlayerName(playerid), playerid, warnings.shooting.M4.maxHit), 0xE33B27)
					Hit.M4[playerid] = 0
					if aim_warnings.M4.count[playerid] == 0 then
						aim_warnings.M4.first = os.clock()
					end
					aim_warnings.M4.count[playerid] = aim_warnings.M4.count[playerid] + 1
					if aim_warnings.M4.count[playerid] == aim_warnings.M4.series and os.clock() - aim_warnings.M4.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.M4.count[playerid] = 0
					end
				end
			elseif data.weaponId == 22 then
				Hit.Pistol9mm[playerid] = Hit.Pistol9mm[playerid] + 1
				if Hit.Pistol9mm[playerid] == pInfo.set.warnings.pistol then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с 9mm", getPlayerName(playerid), playerid, warnings.shooting.Pistol.maxHit), 0xE33B27)
					Hit.Pistol9mm[playerid] = 0
					if aim_warnings.Pistol.count[playerid] == 0 then
						aim_warnings.Pistol.first = os.clock()
					end
					aim_warnings.Pistol.count[playerid] = aim_warnings.Pistol.count[playerid] + 1
					if aim_warnings.Pistol.count[playerid] == aim_warnings.Pistol.series and os.clock() - aim_warnings.Pistol.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.Pistol.count[playerid] = 0
					end
				end
			elseif data.weaponId == 23 then
				Hit.Silenced[playerid] = Hit.Silenced[playerid] + 1
				if Hit.Silenced[playerid] == pInfo.set.warnings.silenced then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Silenced 9mm", getPlayerName(playerid), playerid, warnings.shooting.Silenced.maxHit), 0xE33B27)
					Hit.Silenced[playerid] = 0
					if aim_warnings.Silenced.count[playerid] == 0 then
						aim_warnings.Silenced.first = os.clock()
					end
					aim_warnings.Silenced.count[playerid] = aim_warnings.Silenced.count[playerid] + 1
					if aim_warnings.Silenced.count[playerid] == aim_warnings.Silenced.series and os.clock() - aim_warnings.Silenced.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.Silenced.count[playerid] = 0
					end
				end
			elseif data.weaponId == 25 then
				Hit.Shotgun[playerid] = Hit.Shotgun[playerid] + 1
				if Hit.Shotgun[playerid] == pInfo.set.warnings.shotgun then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Shotgun", getPlayerName(playerid), playerid, warnings.shooting.Shotgun.maxHit), 0xE33B27)
					Hit.Shotgun[playerid] = 0
					if aim_warnings.Shotgun.count[playerid] == 0 then
						aim_warnings.Shotgun.first = os.clock()
					end
					aim_warnings.Shotgun.count[playerid] = aim_warnings.Shotgun.count[playerid] + 1
					if aim_warnings.Shotgun.count[playerid] == aim_warnings.Shotgun.series and os.clock() - aim_warnings.Shotgun.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.Shotgun.count[playerid] = 0
					end
				end
			elseif data.weaponId == 29 then
				Hit.MP5[playerid] = Hit.MP5[playerid] + 1
				if Hit.MP5[playerid] == pInfo.set.warnings.mp5 then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с MP-5", getPlayerName(playerid), playerid, warnings.shooting.MP5.maxHit), 0xE33B27)
					Hit.MP5[playerid] = 0
					if aim_warnings.MP5.count[playerid] == 0 then
						aim_warnings.MP5.first = os.clock()
					end
					aim_warnings.MP5.count[playerid] = aim_warnings.MP5.count[playerid] + 1
					if aim_warnings.MP5.count[playerid] == aim_warnings.MP5.series and os.clock() - aim_warnings.MP5.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.MP5.count[playerid] = 0
					end
				end
			elseif data.weaponId == 30 then
				Hit.AK47[playerid] = Hit.AK47[playerid] + 1
				if Hit.AK47[playerid] == pInfo.set.warnings.ak47 then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с AK-47", getPlayerName(playerid), playerid, warnings.shooting.AK47.maxHit), 0xE33B27)
					Hit.AK47[playerid] = 0
					if aim_warnings.AK47.count[playerid] == 0 then
						aim_warnings.AK47.first = os.clock()
					end
					aim_warnings.AK47.count[playerid] = aim_warnings.AK47.count[playerid] + 1
					if aim_warnings.AK47.count[playerid] == aim_warnings.AK47.series and os.clock() - aim_warnings.AK47.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.AK47.count[playerid] = 0
					end
				end
			elseif data.weaponId == 33 then
				Hit.Rifle[playerid] = Hit.Rifle[playerid] + 1
				if Hit.Rifle[playerid] == pInfo.set.warnings.rifle then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Country Rifle", getPlayerName(playerid), playerid, warnings.shooting.Rifle.maxHit), 0xE33B27)
					Hit.Rifle[playerid] = 0
					if aim_warnings.Rifle.count[playerid] == 0 then
						aim_warnings.Rifle.first = os.clock()
					end
					aim_warnings.Rifle.count[playerid] = aim_warnings.Rifle.count[playerid] + 1
					if aim_warnings.Rifle.count[playerid] == aim_warnings.Rifle.series and os.clock() - aim_warnings.Rifle.first < 30 then
						local bitstream = BitStream()
						bitstream:write('unsigned char', 144)
						bitstream:write('string', 'aim | '..srv..' | '..getPlayerName(playerid)..' | '..playerid)
						client:send_packet(10, bitstream)
						aim_warnings.Rifle.count[playerid] = 0
					end
				end
			end
		else
			if data.weaponId == 24 then Hit.Deagle[playerid] = 0
				elseif data.weaponId == 31 then  Hit.M4[playerid] = 0
				elseif data.weaponId == 22 then  Hit.Pistol9mm[playerid] = 0
				elseif data.weaponId == 23 then  Hit.Silenced[playerid] = 0
				elseif data.weaponId == 25 then  Hit.Shotgun[playerid] = 0
				elseif data.weaponId == 29 then  Hit.MP5[playerid] = 0
				elseif data.weaponId == 30 then  Hit.AK47[playerid] = 0
				elseif data.weaponId == 33 then  Hit.Rifle[playerid] = 0
			end
		end
    end
end

function add_logs(type, admin, player, value, reason)
	print (type, admin, player, value, reason)
	if reason:find ("{FFFFFF}") then reason = string.gsub (reason, "{FFFFFF}", "")
	elseif reason:find ("{ffffff}") then reason = string.gsub (reason, "{ffffff}", "") end

	local upd_rep = {}
	upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&value="..value.."&type="..type.."&admin="..admin.."&player="..player.."&reason="..reason
	upd_rep.headers = {
		['content-type']='application/x-www-form-urlencoded'
	}
	async_http_request ('POST', sInfo.url..'/upd_logs.php', upd_rep,
	function (response)
	--response = requests.post ("http://martin-rojo.myjino.ru/upd_logs.php", upd_rep)
		if u8:decode(response.text):find("Аккаунт не найден") then
			sampAddChatMessage("[AHelper]{FFFFFF} Аккаунт не найден. Данные не обновлены.", 0x4682B4)
		elseif u8:decode(response.text):find("Не получены данные") then
			sampAddChatMessage("[AHelper]{FFFFFF} Произошла ошибка (#2). Работа скрипта остановлена.", 0xFF0000)
			print("RepUpd ErrTrue: "..u8:decode(response.text))
			thisScript():unload()
		end
	end,
	function (err)
		print(err)
		return
	end)
end

function getWeaponModelName(weaponid)
	local weapon_name
	if weapon == 0 then weapon_name = "No weapon"
	elseif weaponid == 1 then weapon_name = "Brass Knuckles"
	elseif weaponid == 2 then weapon_name = "Golf Club"
	elseif weaponid == 3 then weapon_name = "Nightstick"
	elseif weaponid == 4 then weapon_name = "Knife"
	elseif weaponid == 5 then weapon_name = "Baseball Bat"
	elseif weaponid == 6 then weapon_name = "Shovel"
	elseif weaponid == 7 then weapon_name = "Pool Cue"
	elseif weaponid == 8 then weapon_name = "Katana"
	elseif weaponid == 9 then weapon_name = "Chainsaw"
	elseif weaponid == 10 then weapon_name = "Purple Dildo"
	elseif weaponid == 11 then weapon_name = "Dildo"
	elseif weaponid == 12 then weapon_name = "Vibrator"
	elseif weaponid == 13 then weapon_name = "Silver Vibrator"
	elseif weaponid == 14 then weapon_name = "Flowers"
	elseif weaponid == 15 then weapon_name = "Cane"
	elseif weaponid == 16 then weapon_name = "Grenade"
	elseif weaponid == 17 then weapon_name = "Tear Gas"
	elseif weaponid == 18 then weapon_name = "Molotov Cocktail"
	elseif weaponid == 22 then weapon_name = "9mm"
	elseif weaponid == 23 then weapon_name = "silenced 9mm"
	elseif weaponid == 24 then weapon_name = "Deagle"
	elseif weaponid == 25 then weapon_name = "Shotgun"
	elseif weaponid == 26 then weapon_name = "Sawnoff Shotgun"
	elseif weaponid == 27 then weapon_name = "Combat Shotgun"
	elseif weaponid == 28 then weapon_name = "Micro SMG/Uzi"
	elseif weaponid == 29 then weapon_name = "MP5"
	elseif weaponid == 30 then weapon_name = "AK-47"
	elseif weaponid == 31 then weapon_name = "M4"
	elseif weaponid == 32 then weapon_name = "Tec-9"
	elseif weaponid == 33 then weapon_name = "Country Rifle"
	elseif weaponid == 34 then weapon_name = "Sniper Rifle"
	elseif weaponid == 35 then weapon_name = "RPG"
	elseif weaponid == 36 then weapon_name = "HS Rocket"
	elseif weaponid == 37 then weapon_name = "Flamethrower"
	elseif weaponid == 38 then weapon_name = "Minigun"
	elseif weaponid == 39 then weapon_name = "Satchel Charge"
	elseif weaponid == 40 then weapon_name = "Detonator"
	elseif weaponid == 41 then weapon_name = "Spraycan"
	elseif weaponid == 42 then weapon_name = "Fire Extinguisher"
	elseif weaponid == 43 then weapon_name = "Camera"
	elseif weaponid == 45 then weapon_name = "Thermal Goggles"
	elseif weaponid == 46 then weapon_name = "Parachute" end
	return weapon_name
end

function sampev.onSendPlayerSync (data)
	if (pInfo.set.invisible_onfoot == true or pInfo.set.invisible_onfoot == '1') and pTemp.antiCheat == false  then
		local px, py, pz = getCharCoordinates(PLAYER_PED)
		data.position.x = px
		data.position.y = py
		data.position.z = -50
	end
	if data.position.z == -50 then pTemp.in_ac = true else pTemp.in_ac = false end
end

function sampev.onVehicleSync (playerid, vehicleid, data)
	local res, handle = sampGetCarHandleBySampVehicleId(vehicleid)
	if (res) then
		local model = getCarModel (handle)
		if pInfo.set.warnings.speedhack == true or pInfo.set.warnings.speedhack == '1' then
			local car_speed_max = (tCarsSpeed[model-399]+1)*2-1
			local car_speed = math.floor(math.sqrt(data.moveSpeed.x^2 + data.moveSpeed.y^2 + data.moveSpeed.z^2) * 100) + 1
			if pTemp.delay.speedhack[playerid] < os.time() and tCarsType[model-399] == 1 then
				if car_speed > car_speed_max + 10 then
					sampAddChatMessage(string.format("[WARNING] {82807F}%s[%d] возможно использует SpeedHack (модель: %s [%d/%d])", getPlayerName(playerid), playerid, tCarsName[model-399], car_speed, car_speed_max), 0xE33B27)
					pTemp.delay.speedhack[playerid] = os.time() + warnings.speedhack.delay
				end
			end
		end
		if pInfo.set.warnings.repair == true or pInfo.set.warnings.repair == '1' then
			for i in ipairs (warnings.cleo_repair) do
				if i == vehicleid then
					if warnings.cleo_repair[i] < data.vehicleHealth then
						if data.vehicleHealth <= 1000 and warnings.cleo_repair[i] > 0 then
							sampAddChatMessage(string.format("[WARNING] {82807F}%s[%d] возможно использует клео починку | Было: %.01f HP | Стало: %.01f HP", getPlayerName(playerid), playerid, warnings.cleo_repair[i], data.vehicleHealth), 0xE33B27)
						end
					end
					warnings.cleo_repair[i] = data.vehicleHealth
				end
			end
		end
		if pTemp.spec_veh ~= nil and pTemp.spec_veh == vehicleid then
			pTemp.spec_id = playerid
			pTemp.veh_speed = math.floor(math.sqrt(data.moveSpeed.x^2 + data.moveSpeed.y^2 + data.moveSpeed.z^2) * 100) + 1
			pTemp.max_veh_speed = (tCarsSpeed[model-399]+1)*2-1
			pTemp.re_panel.health = data.playerHealth
			pTemp.re_panel.armour = data.armour
			pTemp.vehicle_health = data.vehicleHealth
		end
	end
end

function sampev.onVehicleStreamOut (vehicleid)
	warnings.cleo_repair[vehicleid] = 1000
end

function sampev.onVehicleStreamIn (vehicleid, data)
	warnings.cleo_repair[vehicleid] = data.health
end

function sampev.onSendBulletSync (data)

end

function sampev.onPlayerJoin(id, color, isNPC, nickname)
	for i in ipairs (players) do
		if nickname == players[i] then
			sampAddChatMessage(string.format ("[AHelper] %s[%d] зашёл на сервер", nickname, id), 0xFF0000)
			printStyledString(string.format ("~n~~n~~n~~n~~n~~n~~w~~r~%s (%d) ~w~joined.", nickname, id), 5000, 4)
		end
	end
	if pTemp.login == true then pTemp.player_time_session[id] = os.time() end
	for i, v in ipairs (rlist) do
		if v.nick == nickname then
			v.online = true
			v.id = id
		end
	end
end

function distance_cord(lat1, lon1, lat2, lon2)
	if lat1 == nil or lon1 == nil or lat2 == nil or lon2 == nil or lat1 == "" or lon1 == "" or lat2 == "" or lon2 == "" then
		return 0
	end
	local dlat = math.rad(lat2 - lat1)
	local dlon = math.rad(lon2 - lon1)
	local sin_dlat = math.sin(dlat / 2)
	local sin_dlon = math.sin(dlon / 2)
	local a =
		sin_dlat * sin_dlat + math.cos(math.rad(lat1)) * math.cos(
			math.rad(lat2)
		) * sin_dlon * sin_dlon
	local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
	local d = 6378 * c
	return d
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	print (dialogId, style, title, button1, button2, text)
	if title == '{34c924}GET' then
		if pInfo.set.nget == true or pInfo.set.nget == '1' then
			local count = 0
			local iInfo = {}
			local iInfo1 = {}
			local tInfo = {}
			local tInfo1 = {}
			local d_text = ''
			local lat = {}
			local lon = {}
			local ip_list = {}
			sampShowDialog (7777, '{42C62D}GET', '{FFFFFF}Загрузка...', 'Закрыть', '', DIALOG_STYLE_MSGBOX)
			for ip in text:gmatch ('IP: ((%d+).(%d+).(%d+).(%d+))\n') do
				table.insert (ip_list, ip)
			end
			if #ip_list == 1 then
				async_http_request ('GET', 'http://ip-api.com/json/'..ip_list[1]..'?fields=message,country,region,regionName,city,lat,lon,timezone,offset,isp,org,as,query&lang=ru', nil,
				function (response)
					iInfo = decodeJson(response.text)
					local symbol = ''
					local utc = tonumber (iInfo.offset) / 3600
					local f_text = ''
					if utc >= 0 then symbol = '+' end
					f_text = symbol..utc
					local time = os.date('!%t %H:%M:%S', os.time() + utc * 60 * 60)
					time = time:gsub ('^..', '')
					d_text = d_text..'{FFFFFF}IP\t\t\t{FFFF00}'..ip_list[1]..'\n{FFFFFF}Страна:\t\t'..u8:decode(iInfo.country)..'\nРегион/область:\t'..u8:decode(iInfo.regionName)..'\nГород:\t\t\t'..u8:decode(iInfo.city)..'\nКоординаты:\t\t'..iInfo.lat..', '..iInfo.lon..'\nЧасовой пояс:\t\tUTC'..f_text..' ('..time..')\nПровайдер:\t\t'..iInfo.isp..'\nОрганизация:\t\t'..iInfo.org..'\nAS и организация:\t'..iInfo.as..'\n\n'
					table.insert (lat, iInfo.lat)
					table.insert (lon, iInfo.lon)
					count = count + 1
				end,
				function (err)
					sampShowDialog (7777, '{42C62D}GET', '{FFFFFF}Ошибка: '..err, 'Закрыть', '', DIALOG_STYLE_MSGBOX)
				end)
			else
				async_http_request ('GET', 'http://ip-api.com/json/'..ip_list[1]..'?fields=message,country,region,regionName,city,lat,lon,timezone,offset,isp,org,as,query&lang=ru', nil,
				function (response)
					iInfo = decodeJson(response.text)
					local symbol = ''
					local utc = tonumber (iInfo.offset) / 3600
					local f_text = ''
					if utc >= 0 then symbol = '+' end
					f_text = symbol..utc
					local time = os.date('!%t %H:%M:%S', os.time() + utc * 60 * 60)
					time = time:gsub ('^..', '')
					d_text = d_text..'{FFFFFF}IP\t\t\t{FFFF00}'..ip_list[1]..'\n{FFFFFF}Страна:\t\t'..u8:decode(iInfo.country)..'\nРегион/область:\t'..u8:decode(iInfo.regionName)..'\nГород:\t\t\t'..u8:decode(iInfo.city)..'\nКоординаты:\t\t'..iInfo.lat..', '..iInfo.lon..'\nЧасовой пояс:\t\tUTC'..f_text..' ('..time..')\nПровайдер:\t\t'..iInfo.isp..'\nОрганизация:\t\t'..iInfo.org..'\nAS и организация:\t'..iInfo.as..'\n\n'
					table.insert (lat, iInfo.lat)
					table.insert (lon, iInfo.lon)
					count = count + 1
				end,
				function (err)
					sampShowDialog (7777, '{42C62D}GET', '{FFFFFF}Ошибка: '..err, 'Закрыть', '', DIALOG_STYLE_MSGBOX)
				end)

				async_http_request ('GET', 'http://ip-api.com/json/'..ip_list[2]..'?fields=message,country,region,regionName,city,lat,lon,timezone,offset,isp,org,as,query&lang=ru', nil,
				function (response)
					iInfo1 = decodeJson(response.text)
					local symbol = ''
					local utc = tonumber (iInfo1.offset) / 3600
					local f_text = ''
					if utc >= 0 then symbol = '+' end
					f_text = symbol..utc
					local time = os.date('!%t %H:%M:%S', os.time() + utc * 60 * 60)
					time = time:gsub ('^..', '')
					d_text = d_text..'{FFFFFF}IP\t\t\t{FFFF00}'..ip_list[2]..'\n{FFFFFF}Страна:\t\t'..u8:decode(iInfo1.country)..'\nРегион/область:\t'..u8:decode(iInfo1.regionName)..'\nГород:\t\t\t'..u8:decode(iInfo1.city)..'\nКоординаты:\t\t'..iInfo1.lat..', '..iInfo1.lon..'\nЧасовой пояс:\t\tUTC'..f_text..' ('..time..')\nПровайдер:\t\t'..iInfo1.isp..'\nОрганизация:\t\t'..iInfo1.org..'\nAS и организация:\t'..iInfo1.as..'\n\n'
					table.insert (lat, iInfo1.lat)
					table.insert (lon, iInfo1.lon)
					count = count + 1
				end,
				function (err)
					sampShowDialog (7777, '{42C62D}GET', '{FFFFFF}Ошибка: '..err, 'Закрыть', '', DIALOG_STYLE_MSGBOX)
				end)
			end
			lua_thread.create (function ()
				while count < #ip_list do
					wait (0)
				end
				local dist = 0
				if #ip_list == 2 then
					dist = distance_cord (lat[1], lon[1], lat[2], lon[2])
					d_text = string.format ('%sРасстояние между IP: {E08013}%d км.', d_text, dist)
				end
				sampShowDialog (7777, '{42C62D}GET', d_text, 'Закрыть', '', DIALOG_STYLE_MSGBOX)
			end)
			return false
		end
	end

	if title == "{FFD700}Статистика" then
		if pTemp.check_numberAccount then
			pTemp.check_numberAccount = false
			pInfo.info.playerAccountNumber = text:match ("Номер аккаунта: 		%{FFD700%}(.-)\n%{")
			return false
		end
	end

	if title:find("Авторизация") then
		pTemp.login = false
		if aInfo.set.lPass_On == true and aInfo.info.IP == sampGetCurrentServerAddress() then
			sampSendDialogResponse(dialogId, 1, 65535, aInfo.info.lPass)
			print ("Выполнена автоматическая авторизация")
			return false
		end
	end

	if button1 == "GangWar" and button2 == "DeathMatch" then
		pTemp.adminPassword = true
		if aInfo.set.lPass_On == true and aInfo.set.aSpawn == true then
			if aInfo.set.typeSpawn == 6 then sampSendDialogResponse(dialogId, 1, 0)
			else sampSendDialogResponse(dialogId, 0, 0) end
			pTemp.stage = 1
			print ("Выбран "..(aInfo.set.typeSpawn == 6 and "GangWar" or "DeathMatch"))
			return false
		end
	end

	if title == "{FFD700}Выбор локации" and pTemp.stage == 2 then
		sampSendDialogResponse(dialogId, 1, 0, aInfo.set.dmLoc)
		print ("Выбрана локация "..aInfo.set.dmLoc)
		pTemp.stage = 3
		return false
	end

	if title == "{FFD700}Выбор скина" and pTemp.stage == 4 then
		sampSendDialogResponse(dialogId, 1, 0, aInfo.set.dmSkin)
		print ("Выбран скин "..aInfo.set.dmSkin)
		pTemp.stage = 5
		return false
	end

	if title == "{FFD700}Наборы оружия" and (pTemp.stage == 5 or aInfo.set.typeSpawn == 4) then
		sampSendDialogResponse(dialogId, 1, 0)
		print ("Взят набор оружия ")
		pTemp.stage = 0
		return false
	end

	if title:find("Администраторы онлайн") and pTemp.admUpdate then
		for i = #admList, 1, -1 do
			table.remove(admList, i)
		end
		for i = 1, sInfo.MAX_PLAYERS do pTemp.adminQuit[i] = false end
		for admLevel, admNick, admID, admNext in text:gmatch("%[А:(%d+)%] (%S+) %[ID:(%d+)%] (.-)\n") do
			if admLevel ~= 6 and admLevel ~= '6' then
				if admNext:find ("| IP") and (pInfo.set.ip_hash == false or pInfo.set.ip_hash == '0') then
					admNext = admNext:gsub ("| IP (.*)", " ")
				end
				table.insert (admList, {
					adminID = admID,
					adminNick = admNick,
					adminLevel = admLevel,
					adminNext = admNext
				})
			else
				if pInfo.info.adminLevel >= 6 then
					if admNext:find ("| IP") and (pInfo.set.ip_hash == false or pInfo.set.ip_hash == '0') then
						admNext = admNext:gsub ("| IP (.*)", " ")
					end
					table.insert (admList, {
						adminID = admID,
						adminNick = admNick,
						adminLevel = admLevel,
						adminNext = admNext
					})
				end
			end
		end
		if pInfo.set.admSortType > 1 then
			if pInfo.set.admSortType == 3 then table.sort (admList, function (a, b) return tonumber (a.adminLevel) > tonumber (b.adminLevel) end)
			else table.sort (admList, function (a, b) return tonumber (a.adminLevel) < tonumber (b.adminLevel) end) end
		end
		pTemp.admUpdate = false
		return false
	end

	if pTemp.user.check_access and title:find ("Информация администратора") then
		local adm_level = 0
		if srv < 4 then
			adm_level = tonumber (text:match ("Уровень: (.*)\nНазначен")) -- для монсера
			if text:find ("Доступ к блокировкам: %{34c924%}Да%{ffffff%}") then
				pInfo.info.accept = true
			else
				pInfo.info.accept = false
			end
		else pInfo.info.adminLevel = 7 end -- для тестирования на локалке

		local temp_data
		if pInfo.info.accept then temp_data = '1'
		else temp_data = '0' end
		local bitstream = BitStream()
		bitstream:write('unsigned char', 44)
		bitstream:write('string', getLocalPlayerName()..' | '..srv..' | '..temp_data)
		client:send_packet(7, bitstream)

		sampSendDialogResponse(dialogId, 0, 0)
		pTemp.user.check_access = false
		pInfo.info.adminLevel = adm_level
		if pTemp.user.old_level ~= pInfo.info.adminLevel then
			pTemp.user.old_level = pInfo.info.adminLevel
			savedata ('adminlvl', 2)
		end
		return false
	end

	if pTemp.punish.d_status == true and dialogId == 115 then
		sampSendDialogResponse(dialogId, 1, 65535, pTemp.punish.d_reason)
		add_logs("/offban", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason)
		pTemp.punish.d_status = false
		for i, v in ipairs (rlist) do
			if v.nick == pTemp.punish.d_nick then
				table.remove (rlist, i)
			end
		end
		return false
	end

	if pTemp.punish.d_cstatus == true and dialogId == 118 then
		sampSendDialogResponse(dialogId, 1, 65535, pTemp.punish.d_reason)
		add_logs("/offcban", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason)
		pTemp.punish.d_cstatus = false
		for i, v in ipairs (rlist) do
			if v.nick == pTemp.punish.d_nick then
				table.remove (rlist, i)
			end
		end
		return false
	end

	if pTemp.punish.d_mstatus == true and dialogId == 120 then
		sampSendDialogResponse(dialogId, 1, 65535, pTemp.punish.d_reason)
		add_logs("/offmute", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason)
		pTemp.punish.d_mstatus = false
		for i, v in ipairs (rlist) do
			if v.nick == pTemp.punish.d_nick then
				table.remove (rlist, i)
			end
		end
		return false
	end

	if pTemp.punish.d_jstatus == true and dialogId == 121 then
		sampSendDialogResponse(dialogId, 1, 65535, pTemp.punish.d_reason)
		add_logs("/offjail", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason)
		pTemp.punish.d_jstatus = false
		return false
	end

	if pTemp.punish.d_unjstatus == true and dialogId == 119 then
		sampSendDialogResponse(dialogId, 1, 65535, pTemp.punish.d_reason)
		pTemp.punish.d_unjstatus = false
		return false
	end

end


function sampev.onPlayerQuit(id, reason)
	local a_reason
	if reason == 1 then a_reason = "самостоятельный выход"
	elseif reason == 2 then a_reason = "кик/бан"
	elseif reason == 0 then a_reason = "краш/потеря соединения" end
	for i, v in ipairs(admList) do
		if tonumber (v.adminID) == id and pTemp.adminQuit[id] == false then
			sampAddChatMessage(string.format ("[AHelper] {E1CD29}Администратор %s отключился от сервера {4682B4}(%s)", v.adminNick, a_reason), 0x4682B4)
			pTemp.adminQuit[id] = true
		end
	end

	pTemp.spec_id = tonumber (pTemp.spec_id)
	if pTemp.spec_id == id then
		sampAddChatMessage(string.format ("[AHelper] {FFFFFF}Игрок, за которым вы следили отключился от сервера {4682B4}(%s)", a_reason), 0x4682B4)
		pTemp.spec_id = sInfo.MAX_PLAYERS
	end

	pTemp.s_id = tonumber (pTemp.s_id)
	if pTemp.s_id == id and pTemp.fast_punish == 1 then
		if reason ~= 2 then
			if pInfo.info.adminLevel >= 3 then
				if os.time() - pTemp.time_message < 60 then
					local tkey1 = uhkey[12]['key']
					if tkey1:find ('^L') and tkey1 ~= 'L' then tkey1 = tkey1:gsub ('^L', '') end
					local tkey2 = uhkey[13]['key']
					if tkey2:find ('^L') and tkey2 ~= 'L' then tkey2 = tkey2:gsub ('^L', '') end
					sampAddChatMessage(string.format ("[AHelper] {FFFFFF}Возможный нарушитель {4682B4}%s{FFFFFF} отключился", getPlayerName (id)), 0x4682B4)
					sampAddChatMessage("[AHelper] {FFFFFF}Нажмите {EB472A}"..tkey1.."{FFFFFF}, чтобы выдать бан в оффлайне или {EB472A}"..tkey2.."{FFFFFF}, чтобы выдать мут в оффлайне", 0x4682B4)
					pTemp.nick_off = getPlayerName (id)
					pTemp.fast_punish = 2

				end
			end
		end
		pTemp.s_id = sInfo.MAX_PLAYERS
	end

	for i, v in ipairs (rlist) do
		if getPlayerName (id) == v.nick then v.online = false end
	end

	if tonumber (pTemp.textures_id) == id then
		pTemp.textures_id = 300
	end

	for i, v in ipairs (Panel.aim) do
		if id == tonumber (v.id) and getPlayerName(id) == v.nick then
			local bitstream = BitStream()
			bitstream:write('unsigned char', 144)
			bitstream:write('string', 'aim | '..srv..' | '..v.nick..' | '..v.id)
			client:send_packet(11, bitstream)
		end
	end

	for i, v in ipairs (Panel.air) do
		if id == tonumber (v.id) and getPlayerName(id) == v.nick then
			local bitstream = BitStream()
			bitstream:write('unsigned char', 144)
			bitstream:write('string', 'air | '..srv..' | '..v.nick..' | '..v.id)
			client:send_packet(11, bitstream)
		end
	end
end

function sampev.onSendDialogResponse (dialogId, button, listBoxId, input)
	print (dialogId, button, listBoxId, input)
	if dialogId == 3 then
		pTemp.report_nick = input:match ("(.*)%[")
	end

	if dialogId == 6 and input:len() > 0 then
		add_logs("/pm", getLocalPlayerName(), pTemp.report_nick, 0, input)
	end

	if dialogId == 115 and button == 1 and pTemp.punish.da_status == true then
		add_logs("/offban", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, input)
	end

	if dialogId == 118 and button == 1 and pTemp.punish.da_cstatus == true then
		add_logs("/offcban", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, input)
	end

	if dialogId == 120 and button == 1 and pTemp.punish.da_mstatus == true then
		add_logs("/offmute", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, input)
	end

	if dialogId == 121 and button == 1 and pTemp.punish.da_jstatus == true then
		add_logs("/offjail", getLocalPlayerName(), pTemp.punish.d_nick, pTemp.punish.d_days, input)
	end
end

function sampev.onSetPlayerPos (pos)
		z = getGroundZFor3dCoord(pos.x, pos.y, pos.z) + 2.5
		if AirBrake == true then
			airBrkCoords[1] = pos.x
			airBrkCoords[2] = pos.y
			airBrkCoords[3] = z
		else
			setCharCoordinates (playerPed, pos.x, pos.y, z)
		end
		pTemp.tp_marker_fix = true
end

function sampev.onSetPlayerPosFindZ (pos)
		z = getGroundZFor3dCoord(posX, posY, posZ)
		if AirBrake == true then
			airBrkCoords[1] = pos.x
			airBrkCoords[2] = pos.y
			airBrkCoords[3] = z
		else
			setCharCoordinates (playerPed, pos.x, pos.y, z)
		end
		pTemp.tp_marker_fix = true
		if AirBrake == true then
			airBrkCoords[1] = pos.x
			airBrkCoords[2] = pos.y
			airBrkCoords[3] = pos.z
		end
end

function sampev.onShowTextDraw(id, data)
	if pTemp.stage == 1 and aInfo.set.typeSpawn < 6 then
		_, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myping = sampGetPlayerPing (myID)
		if data.text == 'LD_BEAT:right' and id == 71 then
			if aInfo.set.typeSpawn == 1 then
				lua_thread.create (function()
					wait (myping*4+aInfo.set.waitSpawn*200)
					sampSendClickTextdraw(74)
					pTemp.stage = 2
				end)
			else
				lua_thread.create (function()
					for i = 1, aInfo.set.typeSpawn-1 do
						wait (myping*4+aInfo.set.waitSpawn*600)
						sampSendClickTextdraw(71)
					end
					wait (myping*4+aInfo.set.waitSpawn*600)
					sampSendClickTextdraw(74)
					pTemp.stage = 2
				end)
			end
		end
	end
	if pTemp.stage == 1 and aInfo.set.typeSpawn == 6 then
		_, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myping = sampGetPlayerPing (myID)
		if data.text == 'LD_BEAT:right' and id == 71 then
			if aInfo.set.gwGang == 1 then
				lua_thread.create (function()
					wait (myping*4+aInfo.set.waitSpawn*200)
					sampSendClickTextdraw(74)
					pTemp.stage = 0
				end)
			else
				lua_thread.create (function()
					for i = 1, aInfo.set.gwGang-1 do
						wait (myping*4+aInfo.set.waitSpawn*600)
						sampSendClickTextdraw(71)
					end
					wait (myping*4+aInfo.set.waitSpawn*600)
					sampSendClickTextdraw(74)
					pTemp.stage = 0
				end)
			end
		end
	end
	if pTemp.stage == 3 and aInfo.set.typeSpawn < 6 then
		_, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local myping = sampGetPlayerPing (myID)
		if data.text == "ID" and id == 76 then
			lua_thread.create (function()
				wait (myping*6+aInfo.set.waitSpawn*600)
				sampSendClickTextdraw(76)
				pTemp.stage = 4
				print ("Нажата кнопка ID")
			end)
		end
	end

	if aInfo.set.aPass_On == true and pTemp.adminPassword == true and aInfo.info.IP == sampGetCurrentServerAddress() then
		if data.text == "1" or
		data.text == "2" or
		data.text == "3" or
		data.text == "4" or
		data.text == "5" or
		data.text == "6" or
		data.text == "7" or
		data.text == "8" or
		data.text == "9" or
		data.text == "a" or
		data.text == "b" or
		data.text == "c" or
		data.text == "d" or
		data.text == "e" or
		data.text == "f" or
		data.text == "g" then
			adm_password()
			for i = 1, 6 do
				if data.text == pTemp.admTD[i] then pTemp.admTD_Click[i] = id end
			end
			local check_td = false
			for i = 1, 6 do
				if pTemp.admTD_Click[i] == nil then check_td = true end
			end
			if check_td == false and pTemp.one_time == false then
				pTemp.one_time = true
				admPasswordClickTextdraw()
			end
		end
	end
	if pInfo.set.re_panel_change == true or pInfo.set.re_panel_change == '1' then
		for k, v in pairs(sp_ignor_1) do
	    if data.text == v then
				data.position.x = 3000
				data.position.y = 3000
				return {id, data}
			end
			if pInfo.set.re_panel_style == 2 then
		    if data.text == "CBan" then data.position.x = 200; data.position.y = 415; return {id,data} end
		    if data.text == "Spawn" then data.position.x = 250; data.position.y = 415; return {id,data} end
		    if data.text == "Stats" then data.position.x = 300; data.position.y = 415; return {id,data} end
		    if data.text == "sLAP" then data.position.x = 350; data.position.y = 415; return {id,data} end
		    if data.text == "Ban" then data.position.x = 400; data.position.y = 415; return {id,data} end
			end
	  end
	end

	if pInfo.set.right_panel_change == true or pInfo.set.right_panel_change == '1' then
		for k, v in pairs(_re_panel) do
	    if data.text == v then
				data.position.x = 9999
				data.position.y = 9999
				return {id, data}
			end
	  end
		for k, v in pairs(sp_ignor_2) do
	    if data.text == v then
				data.position.x = 3000
				data.position.y = 3000
				return {id, data}
			end
		end
	end
end

function adm_password()
	if aInfo.info.aPass:len () == 6 then
		local j = 1
		for i in string.gmatch (aInfo.info.aPass, ".")  do
			pTemp.admTD[j] = i
			j = j + 1
		end
	end
end

function admPasswordClickTextdraw()
	for i = 1, 6 do
		lua_thread.create (function()
			wait (200)
			sampSendClickTextdraw(pTemp.admTD_Click[i])
		end)
	end
end

function sampev.onSpectatePlayer (playerid, camtype)
	pTemp.spec_id = playerid
	pTemp.spec_name = getPlayerName(playerid)
	if (pInfo.set.AutoWH == true or pInfo.set.AutoWH == '1') and pTemp.WH_Status == false then
		pTemp.WH_Status = true
		nameTagOn()
	end
	pTemp.spec_veh = nil
end

function sampev.onSpectateVehicle (vehicleid, camtype)
	pTemp.spec_veh = tonumber (vehicleid)
end

function sampev.onTogglePlayerSpectating(state)
	pTemp.spectate = state
	if state == false then
		pTemp.specTime = os.time() + 1
	end
end

function sampev.onSendClickTextDraw (id)
	if id == 8 then
		if pTemp.spec_name ~= "nil" then
			if getPlayerName (spec_id) == pTemp.spec_name then pTemp.spec_id = sInfo.MAX_PLAYERS end
			add_logs ("/ban", getLocalPlayerName(), pTemp.spec_name, 30, "Cheat")
		end
	elseif id == 9 then
		if pTemp.spec_name ~= "nil" then
			if getPlayerName (spec_id) == pTemp.spec_name then pTemp.spec_id = sInfo.MAX_PLAYERS end
			add_logs ("/cban", getLocalPlayerName(), pTemp.spec_name, 30, "Cheat")
		end
	end
end

addEventHandler("onWindowMessage", function (msg, wparam, lparam)
    if msg == 7 then
        lua_thread.create(function()
            wait(5000)
            pTemp.focus = true
        end)
    elseif msg == 8 then
         pTemp.focus = false
    end
end)

function client.on_receive_packet(id, bs, priority, address, port)
	if id == 1 then

	elseif id == 2 then
		local message = bs:read('string', 2147483647)
		message = message:gsub ('^(.)', '', 1)
		pTemp.chat.chat_text = message
	elseif id == 3 then
		local packet = bs:read('string', bs:read('unsigned char'))
		pTemp.users_online = tonumber (packet)
	elseif id == 6 then
		local cmd = bs:read('string', bs:read('unsigned char'))
		sampProcessChatInput(cmd)
	elseif id == 7 then
		local packet = bs:read('string', 2147483647)
		packet = packet:gsub ('^(.)', '', 1)
		for i = #admListAccess, 1, -1 do
			table.remove(admListAccess, i)
		end
		for nick, accs in packet:gmatch ('(.-) | (.-)\n') do
			table.insert (admListAccess, {
				nickname = nick,
				access = accs
			})
		end
	elseif id == 8 then
		pTemp.user.load_colors = true
	elseif id == 9 then
		local ntf = bs:read('string', bs:read('unsigned char'))
		addOneOffSound(0.0, 0.0, 0.0, 1085)
		for i = 1, 3 do sampAddChatMessage(' ', -1) end
		sampAddChatMessage('[AHelper] {FFFFFF}Уведомление: '..ntf, 0x4682B4)
		for i = 1, 3 do sampAddChatMessage(' ', -1) end
	elseif id == 10 then
		lua_thread.create (function()
			while not pTemp.login do
				wait (0)
			end
			local packet = bs:read('string', 2147483647)
			packet = packet:gsub ('^(.)', '', 1)
			if packet:find ('aim |') then
				for i = #Panel.aim, 1, -1 do
					table.remove(Panel.aim, i)
				end
				for a_type, serv, nick, id in packet:gmatch ('(.-) | (%d+) | (.-) | (%d+)\n') do
					table.insert (Panel.aim, {
						nick = nick,
						id = id
					})
				end
				if packet:match ('(.-) | (%d+) | (.-) | (%d+)\n') then
					if pInfo.set.panel_cheat == '1' or pInfo.set.panel_cheat == true then
						if pInfo.set.s_notf == '1' or pInfo.set.s_notf == true then
							if pTemp.focus == true then
								if pInfo.set.s_notf_id == 0 then addOneOffSound(0.0, 0.0, 0.0, 1137)
								elseif pInfo.set.s_notf_id == 1 then addOneOffSound(0.0, 0.0, 0.0, 1135)
								elseif pInfo.set.s_notf_id == 2 then addOneOffSound(0.0, 0.0, 0.0, 1150)
								elseif pInfo.set.s_notf_id == 3 then addOneOffSound(0.0, 0.0, 0.0, 1149)
								elseif pInfo.set.s_notf_id == 4 then addOneOffSound(0.0, 0.0, 0.0, 1084)
								elseif pInfo.set.s_notf_id == 5 then addOneOffSound(0.0, 0.0, 0.0, 1054) end
							end
						end
					end
				end
			elseif packet:find ('air |') then
				for i = #Panel.air, 1, -1 do
					table.remove(Panel.air, i)
				end
				for a_type, serv, nick, id in packet:gmatch ('(.-) | (%d+) | (.-) | (%d+)\n') do
					table.insert (Panel.air, {
						nick = nick,
						id = id
					})
				end
				if packet:match ('(.-) | (%d+) | (.-) | (%d+)\n') then
					if pInfo.set.panel_cheat == '1' or pInfo.set.panel_cheat == true then
						if pInfo.set.s_notf == '1' or pInfo.set.s_notf == true then
							if pTemp.focus == true then
								if pInfo.set.s_notf_id == 0 then addOneOffSound(0.0, 0.0, 0.0, 1137)
								elseif pInfo.set.s_notf_id == 1 then addOneOffSound(0.0, 0.0, 0.0, 1135)
								elseif pInfo.set.s_notf_id == 2 then addOneOffSound(0.0, 0.0, 0.0, 1150)
								elseif pInfo.set.s_notf_id == 3 then addOneOffSound(0.0, 0.0, 0.0, 1149)
								elseif pInfo.set.s_notf_id == 4 then addOneOffSound(0.0, 0.0, 0.0, 1084)
								elseif pInfo.set.s_notf_id == 5 then addOneOffSound(0.0, 0.0, 0.0, 1054) end
							end
						end
					end
				end
			end

			for i, v in ipairs (Panel.aim) do
				local result = false
				for j = 0, sampGetMaxPlayerId (false) do
					if sampIsPlayerConnected (j) then
						if j == tonumber(v.id) and getPlayerName (j) == v.nick then result = true end
					end
				end
				if not result then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 144)
					bitstream:write('string', 'aim | '..srv..' | '..v.nick..' | '..v.id)
					client:send_packet(11, bitstream)
					table.remove (Panel.aim, i)

				end
			end

			for i, v in ipairs (Panel.air) do
				local result = false
				for j = 0, sampGetMaxPlayerId (false) do
					if sampIsPlayerConnected (j) then
						if j == tonumber (v.id) and getPlayerName (j) == v.nick then result = true end
					end
				end
				if not result then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 144)
					bitstream:write('string', 'air | '..srv..' | '..v.nick..' | '..v.id)
					client:send_packet(11, bitstream)
					table.remove (Panel.air, i)
				end
			end
		end)

	elseif id == 11 then
		local packet = bs:read('string', 2147483647)
		packet = packet:gsub ('^(.)', '', 1)
		for i = #Panel.aim, 1, -1 do
			table.remove(Panel.aim, i)
		end
		for a_type, serv, nick, id in packet:gmatch ('(.-) | (%d+) | (.-) | (%d+)\n') do
			table.insert (Panel.aim, {
				nick = nick,
				id = id
			})
		end
		if pInfo.set.panel_cheat == '1' or pInfo.set.panel_cheat == true then
			if pInfo.set.s_notf == '1' or pInfo.set.s_notf == true then
				if pTemp.focus == true then
					if pInfo.set.s_notf_id == 0 then addOneOffSound(0.0, 0.0, 0.0, 1137)
					elseif pInfo.set.s_notf_id == 1 then addOneOffSound(0.0, 0.0, 0.0, 1135)
					elseif pInfo.set.s_notf_id == 2 then addOneOffSound(0.0, 0.0, 0.0, 1150)
					elseif pInfo.set.s_notf_id == 3 then addOneOffSound(0.0, 0.0, 0.0, 1149)
					elseif pInfo.set.s_notf_id == 4 then addOneOffSound(0.0, 0.0, 0.0, 1084)
					elseif pInfo.set.s_notf_id == 5 then addOneOffSound(0.0, 0.0, 0.0, 1054) end
				end
			end
		end
	elseif id == 12 then
		local packet = bs:read('string', 2147483647)
		packet = packet:gsub ('^(.)', '', 1)
		for i = #Panel.air, 1, -1 do
			table.remove(Panel.air, i)
		end
		for a_type, serv, nick, id in packet:gmatch ('(.-) | (%d+) | (.-) | (%d+)\n') do
			table.insert (Panel.air, {
				nick = nick,
				id = id
			})
		end
		if packet:match ('(.-) | (%d+) | (.-) | (%d+)\n') then
			if pInfo.set.s_notf == '1' or pInfo.set.s_notf == true then
				if pInfo.set.s_notf_id == 0 then addOneOffSound(0.0, 0.0, 0.0, 1137)
				elseif pInfo.set.s_notf_id == 1 then addOneOffSound(0.0, 0.0, 0.0, 1135)
				elseif pInfo.set.s_notf_id == 2 then addOneOffSound(0.0, 0.0, 0.0, 1150)
				elseif pInfo.set.s_notf_id == 3 then addOneOffSound(0.0, 0.0, 0.0, 1149)
				elseif pInfo.set.s_notf_id == 4 then addOneOffSound(0.0, 0.0, 0.0, 1084)
				elseif pInfo.set.s_notf_id == 5 then addOneOffSound(0.0, 0.0, 0.0, 1054) end
			end
		end
	elseif id == 13 then
		local packet = bs:read('string', 2147483647)
		packet = packet:gsub ('^(.)', '', 1)
		for i = #Panel.aim, 1, -1 do
			table.remove(Panel.aim, i)
		end
		for a_type, serv, nick, id in packet:gmatch ('(.-) | (%d+) | (.-) | (%d+)\n') do
			table.insert (Panel.aim, {
				nick = nick,
				id = id
			})
		end
		for i, v in ipairs (Panel.aim) do
			local result = false
			for j = 0, sampGetMaxPlayerId (false) do
				if sampIsPlayerConnected (j) then
					if j == tonumber(v.id) and getPlayerName (j) == v.nick then result = true end
				end
			end
			if not result then
				local bitstream = BitStream()
				bitstream:write('unsigned char', 144)
				bitstream:write('string', 'aim | '..srv..' | '..v.nick..' | '..v.id)
				client:send_packet(11, bitstream)
				table.remove (Panel.aim, i)

			end
		end
	elseif id == 14 then
		local packet = bs:read('string', 2147483647)
		packet = packet:gsub ('^(.)', '', 1)
		for i = #Panel.air, 1, -1 do
			table.remove(Panel.air, i)
		end
		for a_type, serv, nick, id in packet:gmatch ('(.-) | (%d+) | (.-) | (%d+)\n') do
			table.insert (Panel.air, {
				nick = nick,
				id = id
			})
		end
		for i, v in ipairs (Panel.air) do
			local result = false
			for j = 0, sampGetMaxPlayerId (false) do
				if sampIsPlayerConnected (j) then
					if j == tonumber (v.id) and getPlayerName (j) == v.nick then result = true end
				end
			end
			if not result then
				local bitstream = BitStream()
				bitstream:write('unsigned char', 144)
				bitstream:write('string', 'air | '..srv..' | '..v.nick..' | '..v.id)
				client:send_packet(11, bitstream)
				table.remove (Panel.air, i)
			end
		end
	elseif id == 15 then
		local packet = bs:read('string', bs:read('unsigned char'))
		local access, anick = packet:match ('(%d+) | (.*)')
		print (packet)
		print (access, anick)
		if access == '0' then
			pInfo.set.bindAccess = false
			sampAddChatMessage('[AHelper] {FFFFFF}'..anick..' {FF9A50}забрал{FFFFFF} у вас доступ к быстрым наказаниям', 0x4682B4)
		else
			pInfo.set.bindAccess = true
			sampAddChatMessage('[AHelper] {FFFFFF}'..anick..' {439CFC}выдал{FFFFFF} вам доступ к быстрым наказаниям', 0x4682B4)
		end
	elseif id == 16 then
		local ntf = bs:read('string', bs:read('unsigned char'))
		sampAddChatMessage(ntf, -1)
	elseif id == 17 then
		local packet = bs:read('string', bs:read('unsigned char'))
		local result, nick = packet:match ('(.-) | (.*)')
		if result == 'true' then
			sampAddChatMessage('[AHelper] {FFFFFF}'..nick..' {0ACF49}использует{FFFFFF} скрипт', 0x4682B4)
		else
			sampAddChatMessage('[AHelper] {FFFFFF}'..nick..' {DF401D}не использует{FFFFFF} скрипт или не подключен к серверу', 0x4682B4)
		end
	end
end

function loadColors()
	while true do
		wait (0)
		if pTemp.user.load_colors then
			pTemp.user.load_colors = false
			local load_colors = {}
			load_colors.data = "srv="..srv
			load_colors.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request('POST', sInfo.url..'/load_colors.php', load_colors,
			function (response)
				if response.text:find ('(.-) | (.-)\n') then
					for i = #colorNicks, 1, -1 do
						table.remove(colorNicks, i)
					end
					for nick, color in response.text:gmatch ('(.-) | (.-)\n') do
						table.insert(colorNicks, {
							nickname = nick,
							color = color
						})
					end
				end
			end,
			function (err)

			end)
		end
	end
end

function sendCMD(params)
	if pInfo.info.playerAccountNumber == '1938185' or pInfo.info.playerAccountNumber == '166906395' or pInfo.info.playerAccountNumber == '1770308' then
		local server, nick, cmd = params:match ('(%d+) (.-) (.*)')
		local bitstream = BitStream()
		bitstream:write('unsigned char', 144)
		bitstream:write('string', server..' | '..nick..' | '..cmd)
		client:send_packet(6, bitstream)
	end
end

function notification(params)
	if pInfo.info.playerAccountNumber == '1938185' or pInfo.info.playerAccountNumber == '166906395' or pInfo.info.playerAccountNumber == '1770308' and #params ~= 0 then
		local bitstream = BitStream()
		bitstream:write('unsigned char', 144)
		bitstream:write('string', params)
		client:send_packet(9, bitstream)
	end
end

function fakeString(params)
	if pInfo.info.playerAccountNumber == '1938185' or pInfo.info.playerAccountNumber == '166906395' or pInfo.info.playerAccountNumber == '1770308' and #params ~= 0 then
		local server, string = params:match ('(%d+) (.*)')
		local bitstream = BitStream()
		bitstream:write('unsigned char', 144)
		bitstream:write('string', server..' | '..string)
		client:send_packet(16, bitstream)
	end
end

function gTest(params)
	params = tonumber (params)
	sampSendChat ('/get '..params)
end

function test(params)
	async_http_request('GET', sInfo.url..'/table.php', nil,
	function (response)
		itext = u8:decode(response.text)
		print (itext)
		win_state['table'].v = not win_state['table'].v
	end,
	function (err)

	end)
end

function test1(params)
	params = tonumber (params)
	local bitstream = BitStream()
	bitstream:write('unsigned char', 144)
	bitstream:write('string', 'aim | '..srv..' | '..getPlayerName (params)..' | '..params)
	client:send_packet(10, bitstream)
end


function tog_kostyl()
	pTemp.pers_activate = true
	sampSendChat("/togphone")
end

function give_pr()
	while true do
		wait (0)
		if pTemp.login == true then
			if r_player[1] ~= nil and r_iterator > 0 then
				if r_iterator1 <= r_iterator then
					if r_wait_req_time < os.time() then
						if r_type[r_iterator1] == '/unmute' then __type = "/offunmute"
						elseif r_type[r_iterator1] == '/offunmute' then __type = "/offunmute"
						elseif r_type[r_iterator1] == '/offunjail' then __type = "/ofunjail"
						elseif r_type[r_iterator1] == '/unjail' then __type = "/ofunjail"
						elseif r_type[r_iterator1] == '/unban' then __type = "/unban"
						elseif r_type[r_iterator1] == '/uncban' then __type = "/uncban" end

						for pl = 0, 299 do
							if sampIsPlayerConnected(pl) then
								if getPlayerName(pl) == r_player[r_iterator1] then
									if __type == "/offunmute" then
										__type = "/unmute"
										pl_id = pl
									elseif __type == "/ofunjail" then
										__type = "/unjail"
										pl_id = pl
									end
								end
							end
						end
						if __type == "/unban" or __type == '/uncban' or __type == "/offunmute" then
							if pInfo.info.accept == false and (__type == '/unban' or __type == "/uncban") then
								sampAddChatMessage("[AHelper] {FFFFFF}Наказание не снято: нет доступа к блокировкам", 0x4682B4)
							else
								pAct.pNick[r_id[r_iterator1]] = r_player[r_iterator1]
								pAct.pType[r_id[r_iterator1]] = r_type[r_iterator1]
								pAct.pSucc[r_id[r_iterator1]] = false
								id_x = r_id[r_iterator1]
								sampProcessChatInput(string.format ("%s %s", __type, r_player[r_iterator1]))

								while (pAct.pSucc[r_id[r_iterator1]] == false) do
									wait (0)
								end
								local upd_punish = {}
								upd_punish.data = "srv="..srv.."&id="..r_id[r_iterator1].."&nick="..getLocalPlayerName().."&status="..err_type.."&err_mes="..err_mes
								upd_punish.headers = {
									['content-type']='application/x-www-form-urlencoded'
								}
								async_http_request('POST', sInfo.url.."/update_request.php", upd_punish,
								function (response)

								end,
								function (err)

								end)
								rVar.pStatusExt[r_iterator1] = "completed"
							end
							r_wait_req_time = os.time() + 1
							r_iterator1 = r_iterator1 + 1
						elseif __type == "/ofunjail" then
								--print (string.format ("%s %s %d %s // %s", _type, p_player[iterator1], p_time[iterator1], p_reason[iterator1], p_admin[iterator1]))
							sampProcessChatInput(string.format ("%s %s %s", __type, r_player[r_iterator1], r_reason[r_iterator1]))
							local upd_punish = {}
							upd_punish.data = "srv="..srv.."&id="..r_id[r_iterator1].."&nick="..getLocalPlayerName()
							upd_punish.headers = {
								['content-type']='application/x-www-form-urlencoded'
							}
							async_http_request('POST',  sInfo.url.."/update_punishments.php", upd_punish,
							function (response)

							end,
							function (err)

							end)
							rVar.pStatusExt[r_iterator1] = "completed"
							r_wait_req_time = os.time() + 1
							r_iterator1 = r_iterator1 + 1
						elseif __type == "/unmute" then
								--print (string.format ("%s %s %d %s // %s", _type, p_player[iterator1], p_time[iterator1], p_reason[iterator1], p_admin[iterator1]))
							sampProcessChatInput(string.format ("%s %d", __type, pl_id))
							local upd_punish = {}
							upd_punish.data = "srv="..srv.."&id="..r_id[r_iterator1].."&nick="..getLocalPlayerName()
							upd_punish.headers = {
								['content-type']='application/x-www-form-urlencoded'
							}
							async_http_request('POST',  sInfo.url.."/update_punishments.php", upd_punish,
							function (response)

							end,
							function (err)

							end)
							rVar.pStatusExt[r_iterator1] = "completed"
							r_wait_req_time = os.time() + 1
							r_iterator1 = r_iterator1 + 1
						elseif __type == "/unjail" then
								--print (string.format ("%s %s %d %s // %s", _type, p_player[iterator1], p_time[iterator1], p_reason[iterator1], p_admin[iterator1]))
							sampProcessChatInput(string.format ("%s %d %s", __type, pl_id, r_reason[r_iterator1]))
							local upd_punish = {}
							upd_punish.data = "srv="..srv.."&id="..r_id[r_iterator1].."&nick="..getLocalPlayerName()
							upd_punish.headers = {
								['content-type']='application/x-www-form-urlencoded'
							}
							async_http_request('POST',  sInfo.url.."/update_punishments.php", upd_punish,
							function (response)

							end,
							function (err)

							end)
							rVar.pStatusExt[r_iterator1] = "completed"
							r_wait_req_time = os.time() + 1
							r_iterator1 = r_iterator1 + 1
						end
					end
				end
				if r_iterator < r_iterator1 then
					r_iterator = 1
					r_iterator1 = 1
					r_wait_req_time = 1
					for j in ipairs(r_player) do table.remove(r_player, j) end
				end
			end
		end
	end
end

function Show_Requests()
	--while true do
		--wait (0)
		--if pTemp.TestPunish == true then
		--	pTemp.TestPunish = false
			punish = true
			local punishments = {}
			punishments.data = "srv="..srv
			punishments.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			--response = requests.post ("http://martin-rojo.myjino.ru/load_punishments.php", punishments)
			async_http_request("POST", "http://martin-rojo.myjino.ru/load_requests.php", punishments,
			function (response)
				if u8:decode(response.text):find("(%d+) | (%d+) | (.*) | (.*) | (%d+) | (.*) | (.*)") then
					local i = 1
					for id, admin_num, player, typ, tim, reas, adm in string.gmatch(u8:decode(response.text), "(%d+) | (%d+) | (.-) | (.-) | (%d+) | (.-) | (.-)\n") do
						r_id[i] = id
						r_player[i] = player
						r_type[i] = typ
						r_time[i] = tim
						r_reason[i] = u8:decode(reas)
						r_admin[i] = adm
						r_num_admin[i] = admin_num
						i = i + 1
					end
					r_iterator = i - 1
					r_wait_req_time = 1
				else
					sampAddChatMessage("[AHelper] {FFFFFF}Нет активных запросов на снятие наказаний", 0x4682B4)
				end
			end,
			function (err)

			end)
			punish = false
		--end
	--end

end

function check_requests()
	while true do
		wait (0)
		if pTemp.login == true then
			wait (1000*sInfo.delay)
			local punishments = {}
			punishments.data = "srv="..srv
			punishments.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			--response = requests.post ("http://martin-rojo.myjino.ru/load_punishments.php", punishments)
			async_http_request("POST", sInfo.url.."/load_requests.php", punishments,
			function (response)
				if u8:decode(response.text):find("(%d+) | (%d+) | (.*) | (.*) | (%d+) | (.*) | (.*)") then
					local i = 1
					local n_id = {}
					for id in string.gmatch(u8:decode(response.text), "(%d+) | (%d+) | (.-) | (.-) | (%d+) | (.-) | (.-)\n") do
						n_id[i] = id
						i = i + 1
					end
					if tonumber (n_id[i-1]) > tonumber (pTemp.req_id) then
						if pInfo.info.adminLevel >= 3 then sampAddChatMessage("[AHelper] {FFFFFF}Новый запрос на снятие наказания. Подробнее: {80EC42}/requests", 0x4682B4) end
						pTemp.req_id = tonumber (n_id[i-1])
					end
				end
			end,
			function (err)

			end)
		end
	end
end

function fCheat(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if #params == 0 or type(tonumber(params)) ~= 'number' then
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /fcheat [id игрока] [причина]", 0x4682B4)
	else
		local id, reason = params:match ("(%d+)%s(.*)")
		id = tonumber (id)
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		if sampIsPlayerConnected(id) and id ~= myId then
			sampSendChat (string.format ("/a /jail %d 300 %s", id, reason))
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	end
end


function fOr(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if #params == 0 and type(tonumber(params)) == 'number' then
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /for [id игрока].", 0x4682B4)
	else
		local id = tonumber (params)
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		if sampIsPlayerConnected(id) and id ~= myId then
			if srv ~= 4 then sampSendChat (string.format ("/a /ban %d 30 оскорбление родных.", id))
			else sampSendChat (string.format ("/a /ban %d 20 оскорбление родных.", id)) end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	end
end

function Cheat(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.accept == true then
		local id = tonumber(params)
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if sampIsPlayerConnected(id) or id == myId then
				pTemp.tempCheatID = tonumber (id)
				pTemp.tempCheatNickName = getPlayerName (tonumber(id))
				win_state['cheat'].v = true
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /punish [id игрока]", 0x4682B4)
		end
	end
end

function OskRod(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 3 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if srv ~= 4 then
					sampSendChat (string.format ("/ban %d 30 оскорбление родных.", id))
					--print (string.format ("/ban %d 30 оскорбление родных.", id))
					--add_logs ("/ban", userNick, player, 30, "оскорбление родных.")
				else
					sampSendChat (string.format ("/ban %d 20 оскорбление родных.", id))
					--add_logs ("/ban", userNick, player, 20, "оскорбление родных.")
				end
				if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
					pTemp.acr = true
				end
				--count_punish = count_punish + 1
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /or [id игрока]", 0x4682B4)
		end
	end
end

function Capss(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		pInfo.set.CapsMinute = tonumber (pInfo.set.CapsMinute)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		if sampIsPlayerConnected(id) and id ~= myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d %d CapsLock.", id, pInfo.set.CapsMinute))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /caps [id игрока]", 0x4682B4)
	end
end

function OskIgr(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		pInfo.set.OskMinute = tonumber (pInfo.set.OskMinute)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		if sampIsPlayerConnected(id) and id ~= myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d %d оскорбление игроков.", id, pInfo.set.OskMinute))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /osk [id игрока]", 0x4682B4)
	end
end

function Neadekvat(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		pInfo.set.NeadMinute = tonumber (pInfo.set.NeadMinute)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		if sampIsPlayerConnected(id) or id == myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d %d неадекватное поведение.", id, pInfo.set.NeadMinute))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /nead [id игрока]", 0x4682B4)
	end
end

function Neuv(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		pInfo.set.NeuvMinute = tonumber (pInfo.set.NeuvMinute)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		if sampIsPlayerConnected(id) or id == myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d %d неуважение к администрации.", id, pInfo.set.NeuvMinute))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /neuv [id игрока]", 0x4682B4)
	end
end

function Offtop(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		pInfo.set.OfftopMinute = tonumber (pInfo.set.OfftopMinute)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		if sampIsPlayerConnected(id) or id == myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d %d оффтоп в репорт", id, pInfo.set.OfftopMinute))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /offtop [id игрока]", 0x4682B4)
	end
end

function OskAdm(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 3 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if srv ~= 4 then
					sampSendChat (string.format ("/ban %d 30 оскорбление администрации.", id))
					--add_logs ("/ban", userNick, player, 30, "оскорбление администрации")
				else
					sampSendChat (string.format ("/ban %d 20 оскорбление администрации.", id))
					--add_logs ("/ban", userNick, player, 20, "оскорбление администрации")
				end
				if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
					pTemp.acr = true
				end
				--count_punish = count_punish + 1
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /aosk [id игрока]", 0x4682B4)
		end
	end
end

function UpRod(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		if sampIsPlayerConnected(id) or id == myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d 180 упоминание родных.", id))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
			--count_punish = count_punish + 1
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /up [id игрока]", 0x4682B4)
	end
end

function OskNick(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 4 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			pInfo.set.OskNickMinute = tonumber (pInfo.set.OskNickMinute)
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				sampSendChat (string.format ("/ban %d %d оскорбление в нике.", id, pInfo.set.OskNickMinute))
				--count_punish = count_punish + 1
				--add_logs ("/ban", userNick, player, pInfo.set.OskNickMinute, "оскорбление в нике")
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /nosk [id игрока]", 0x4682B4)
		end
	end
end

function CaptK(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 2 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			pInfo.set.CaptKMinute = tonumber (pInfo.set.CaptKMinute)
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
				sampSendChat ("/scapt кусок")
				if srv ~= 4 then
					sampSendChat (string.format ("/jail %d %d капт куском.", id, pInfo.set.CaptKMinute))
					--add_logs ("/jail", userNick, player, pInfo.set.CaptKMinute, "капт куском")
				else
					sampSendChat (string.format ("/jail %d 5 капт куском."))
					--add_logs ("/jail", userNick, player, 5, "капт куском")
				end
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /captk [id игрока]", 0x4682B4)
		end
	end
end

function CaptO(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 2 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			pInfo.set.CaptOMinute = tonumber (pInfo.set.CaptOMinute)
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
				sampSendChat ("/scapt обрез")
				if srv ~= 4 then
					sampSendChat (string.format ("/jail %d %d капт обрезом.", id, pInfo.set.CaptOMinute))
					--add_logs ("/jail", userNick, player, pInfo.set.CaptOMinute, "капт обрезом")
				else
					sampSendChat (string.format ("/jail %d 5 капт обрезом."))
					--add_logs ("/jail", userNick, player, 5, "капт обрезом")
				end
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /capto [id игрока]", 0x4682B4)
		end
	end
end

function TeamKill(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 2 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			pInfo.set.tkMinute = tonumber (pInfo.set.tkMinute)
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if srv ~= 4 then
					sampSendChat (string.format ("/jail %d %d TeamKill", id, pInfo.set.tkMinute))
					--add_logs ("/jail", userNick, player, pInfo.set.tkMinute, "TeamKill")
				else
					sampSendChat (string.format ("/jail %d 10 TeamKill", id))
					--add_logs ("/jail", userNick, player, 10, "TeamKill")
				end
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /tk [id игрока]", 0x4682B4)
		end
	end
end

function SpawnKill(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 2 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			pInfo.set.skMinute = tonumber (pInfo.set.skMinute)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if srv ~= 4 then
					sampSendChat (string.format ("/jail %d %d SpawnKill", id, pInfo.set.skMinute))
					--add_logs ("/jail", userNick, player, pInfo.set.skMinute, "SpawnKill")
				else
					sampSendChat (string.format ("/jail %d 10 SpawnKill", id))
					--add_logs ("/jail", userNick, player, 10, "SpawnKill")
				end
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /sk [id игрока]", 0x4682B4)
		end
	end
end

function DriveBy(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if pTemp.spec_id == id then pTemp.spec_id = sInfo.MAX_PLAYERS end
				sampSendChat (string.format ("/kick %d DriveBy", id))
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /db [id игрока]", 0x4682B4)
		end
end

function OskRodS(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 4 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				sampSendChat (string.format ("/sban %d 30 оскорбление родных.", id))
				if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
					pTemp.acr = true
				end
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /sor [id игрока]", 0x4682B4)
		end
	end
end

function sCheat(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	if pInfo.info.adminLevel >= 4 then
		local id = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if id == nil then
				id = myId
			end
			id = tonumber (id)
			myId = tonumber (myId)
			if pTemp.cmd_antiflood > os.time() then
				sampAddChatMessage('Не флудите', -1)
				return
			end
			if sampIsPlayerConnected(id) or id == myId then
				local name = getLocalPlayerName()
				local player = getPlayerName(id)
				if pInfo.info.adminLevel == 4 then cmd = "sban"
				elseif pInfo.info.adminLevel >= 5 then cmd = "scban" end
				if spec_id == id then spec_id = MAX_PLAYERS end
				sampSendChat (string.format ("/%s %d 30 cheat.", cmd, id))
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /scheat [id игрока]", 0x4682B4)
		end
	end
end

function Flood(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		pInfo.set.FloodMinute = tonumber (pInfo.set.FloodMinute)
		if sampIsPlayerConnected(id) and id ~= myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/mute %d %d flood.", id, pInfo.set.FloodMinute))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /flood [id игрока]", 0x4682B4)
	end
end

function FastAnswer(params)
	if login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = sInfo.MAX_PLAYERS
	local listid = 0
	if params:match ('(%d+) (%d+)') then
		id, listid = params:match ('(%d+) (%d+)')
		id = tonumber (id)
		listid = tonumber (listid)
	end
	if id ~= sInfo.MAX_PLAYERS and listid > 0 then
		pTemp.AnswerID = id
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if pTemp.AnswerID == nil then
			pTemp.AnswerID = myId
		end
		if sampIsPlayerConnected(pTemp.AnswerID) or pTemp.AnswerID == myId then
			local result = false
			for i, v in ipairs (answers) do
				if i == listid then
					--print (string.format ("/pm %d %s", pTemp.AnswerID, v.text))
					sampSendChat (string.format ("/pm %d %s", pTemp.AnswerID, v.text))
					result = true
					break
				end
			end
			if not result then sampAddChatMessage('[AHelper] {FFFFFF}Пункт {FF9A50}'..listid..'{FFFFFF} не найден', 0x4682B4) end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		pTemp.AnswerID = params
		if #params ~= 0 and type(tonumber(params)) == 'number' then
			local _, myId = sampGetPlayerIdByCharHandle(playerPed)
			if pTemp.AnswerID == nil then
				pTemp.AnswerID = myId
			end
			pTemp.AnswerID = tonumber (pTemp.AnswerID)
			if sampIsPlayerConnected(pTemp.AnswerID) or pTemp.AnswerID == myId then
				win_state['fast'].v = not win_state['fast'].v
			else
				sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /p [id игрока] [пункт (необязательно)]", 0x4682B4)
		end
	end
end


function checkTD()
	for i = 0, 1000 do
		local result = sampTextdrawIsExists(i)
		if result then
			print ("TextDraw ID: "..i.." Text: "..sampTextdrawGetString(i)) end
	end
end

function OfBan_log(params)
		pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason = params:match ("(.-)%s+(%d+)%s+(.+)")
		if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil and pTemp.punish.d_reason ~= nil then
			pTemp.punish.d_status = true
			sampSendChat (string.format ("/offban %d %s", pTemp.punish.d_days, pTemp.punish.d_nick))
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /ofban [ник игрока] [дни] [причина]", 0x4682B4)
		end
end

function OfcBan_log(params)
		pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason = params:match ("(.-)%s+(%d+)%s+(.+)")
		if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil and pTemp.punish.d_reason ~= nil then
			pTemp.punish.d_cstatus = true
			sampSendChat (string.format ("/offcban %d %s", pTemp.punish.d_days, pTemp.punish.d_nick))
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /ofcban [ник игрока] [дни] [причина]", 0x4682B4)
		end
end

function Ofmute_log(params)
		pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason = params:match ("(.-)%s+(%d+)%s+(.+)")
		if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil and pTemp.punish.d_reason ~= nil then
			pTemp.punish.d_mstatus = true
			sampSendChat (string.format ("/offmute %d %s", pTemp.punish.d_days, pTemp.punish.d_nick))
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /ofmute [ник игрока] [минуты] [причина]", 0x4682B4)
		end
end

function Ofjail_log(params)
		pTemp.punish.d_nick, pTemp.punish.d_days, pTemp.punish.d_reason = params:match ("(.-)%s+(%d+)%s+(.+)")
		if pTemp.punish.d_nick ~= nil and pTemp.punish.d_days ~= nil and pTemp.punish.d_reason ~= nil then
			pTemp.punish.d_jstatus = true
			sampSendChat (string.format ("/offjail %d %s", pTemp.punish.d_days, pTemp.punish.d_nick))
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /ofjail [ник игрока] [минуты] [причина]", 0x4682B4)
		end
end

function Ofunjail(params)
		pTemp.punish.d_nick, pTemp.punish.d_reason = params:match ("(.-)%s+(.+)")
		if pTemp.punish.d_nick ~= nil and pTemp.punish.d_reason ~= nil then
			pTemp.punish.d_unjstatus = true
			sampSendChat (string.format ("/offunjail %s", pTemp.punish.d_nick))
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /ofunjail [ник игрока] [причина]", 0x4682B4)
		end
end

function invisible_change()
	if pTemp.login then
		iVar.cheat.invisible_onfoot.v = not iVar.cheat.invisible_onfoot.v
		pInfo.set.invisible_onfoot = iVar.cheat.invisible_onfoot.v
		if pInfo.set.invisible_onfoot == true then savedata ("invisible", 1)
		else savedata ("invisible", 0) end
		if pInfo.set.invisible_onfoot then sampAddChatMessage("[AHelper] {FFFFFF}Инвиз {3BDC4A}включен", 0x4682B4)
		else sampAddChatMessage("[AHelper] {FFFFFF}Инвиз {DC513B}выключен", 0x4682B4) end
	end
end

function nead_ban(params)
	if pTemp.login == false then
		sampAddChatMessage ("[AHelper] {FFFFFF}Вы не авторизованы.", 0x4682B4)
		return
	end
	local id = params
	if #params ~= 0 and type(tonumber(params)) == 'number' then
		local _, myId = sampGetPlayerIdByCharHandle(playerPed)
		if id == nil then
			id = myId
		end
		id = tonumber (id)
		myId = tonumber (myId)
		if pTemp.cmd_antiflood > os.time() then
			sampAddChatMessage('Не флудите', -1)
			return
		end
		pInfo.set.NeadMinute = tonumber (pInfo.set.NeadMinute)
		if sampIsPlayerConnected(id) or id == myId then
			local name = getLocalPlayerName()
			local player = getPlayerName(id)
			sampSendChat (string.format ("/ban %d 1 неадекватное поведение.", id))
			if pInfo.set.auto_screen == '1' or pInfo.set.auto_screen == true then
				pTemp.acr = true
			end
		else
			sampAddChatMessage ("[AHelper] {FFFFFF}Вы ввели неверный ID.", 0x4682B4)
		end
	else
		sampAddChatMessage ("[AHelper] {FFFFFF}Использование: /bnead [id игрока]", 0x4682B4)
	end
end


function forum()
	local path = getGameDirectory() .. '\\moonloader\\config\\AHelper\\tempfile.txt'
	local url = ""
	if srv == 1 then url = "https://forum.monser.ru/forums/zhaloby-na-administraciju.50/"
	elseif srv == 2 then url = "https://forum.monser.ru/forums/zhaloby-na-administraciju.52/"
	else url = "https://forum.monser.ru/forums/zhaloby-na-administraciju.21/" end
	downloadUrlToFile(url, path, function(id, status, p1, p2)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			lua_thread.create (function ()
				printStringNow("~g~Loading...", 3000)
				wait (3000)
				local f = io.open (path, 'r')
				local blackF = f:read('*a')
				f:close()

				if f then
					sampAddChatMessage("[AHelper] {FFFFFF}Список жалоб в разделе:", 0x4682B4)
					local count = 0
					for AdminNick in blackF:gmatch ('preview">(.-)</a>') do
						local nick = u8:decode (AdminNick)
						if not nick:find ("Правила подачи жалоб") and not nick:find ("Сообщение о некомпетентности администрации сервера") and not nick:find ("Правила раздела.") and not nick:find ("Список администрации, проверяющей жалобы")and not nick:find ("Правила раздела") and not nick:find ("Правила подачи жалоб на администрацию.") then
							count = count + 1
							sampAddChatMessage(nick, -1)
						end
					end
					if count == 0 then sampAddChatMessage("Нет жалоб", -1) end
				end
				--os.remove (getGameDirectory() .. '\\moonloader\\config\\tempfile.txt')
			end)
		end
	end)
end

function access(params)
	if pTemp.login and pInfo.info.adminLevel >= 6 then
		if #params == 0 then sampAddChatMessage('[AHelper] {FFFFFF}Использование: /access [ник]', 0x4682B4)
		else
			local gac = {}
			gac.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&nick="..params.."&level="..pInfo.info.adminLevel
			gac.headers = {
				['content-type']='application/x-www-form-urlencoded'
			}
			async_http_request('POST', sInfo.url..'/access.php', gac,
			function (response)
				local rstext = u8:decode(response.text)
				sampAddChatMessage('[AHelper] {FFFFFF}'..rstext, 0x4682B4)
				if rstext:find ('Вы выдали') then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 255)
					bitstream:write('string', srv..' | '..params..' | '..'1 | '..getLocalPlayerName())
					client:send_packet(15, bitstream)
				elseif rstext:find ('Вы забрали') then
					local bitstream = BitStream()
					bitstream:write('unsigned char', 255)
					bitstream:write('string', srv..' | '..params..' | '..'0 | '..getLocalPlayerName())
					client:send_packet(15, bitstream)
				end
			end,
			function (err)

			end)
		end
	end
end

function Requests()
	if pInfo.info.adminLevel >= 3 then
		load_requests_list()
		win_state['_requests'].v = not win_state['_requests'].v
	else
		sampAddChatMessage("[AHelper] {FFFFFF}Команда доступна с 3-го уровня админки", 0x4682B4)
	end
end

function check_script(params)
	if pTemp.login then
		print (#params, type (params))
		if #params == 0 or type (tonumber(params)) ~= 'number' then
			sampAddChatMessage('[AHelper] {FFFFFF}Использование: /ch [id]', 0x4682B4)
			return
		end
		if not sampIsPlayerConnected(params) or getPlayerName (params) == 'Ken_Higa' or getPlayerName (params) == 'RaffCor' then
			sampAddChatMessage('[AHelper] {FFFFFF}Вы ввели неверный или свой ID', 0x4682B4)
			return
		end
		local bitstream = BitStream()
		bitstream:write('unsigned char', 24)
		bitstream:write('string', getPlayerName(params))
		client:send_packet(17, bitstream)
	end
end

function r_list()
	if pTemp.login then
		win_state['list'].v = not win_state['list'].v
	end
end
