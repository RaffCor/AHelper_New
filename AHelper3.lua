script_name('AHelper')
script_authors('Ken_Higa (RaffCor)')
script_version_number(145)
script_version("3.0")
script_properties("work-in-pause")
--script_properties("forced-reloading-only")

-- Подключение библиотек
local font_flag = require('moonloader').font_flag
local dlstatus = require('moonloader').download_status
local result_sampev, sampev = pcall (require, 'lib.samp.events')
local result_imgui, imgui = pcall (require, 'imgui')
local result_requests = pcall (require, 'requests')
local result_encoding, encoding = pcall (require, 'encoding')
local result_memory, memory = pcall (require, 'memory')
local result_icons, fa = pcall (require, 'fAwesome5')
local result_lanes = pcall (require, 'lanes')
local result_imgui_notf, notf = pcall (import, 'imgui_notf.lua')
local result_vkeys, vkeys = pcall (require, 'vkeys')
local result_slnet, slnet = pcall (require, 'slnet')
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

local Matrix3X3 = require "matrix3x3"
local Vector3D = require "vector3d"

keyToggle = VK_MBUTTON
keyApply = VK_LBUTTON

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

-- Переменные:
local pInfo = { -- Главная информация, которая сохраняется в БД
	info = {
		playerAccountNumber = 0,
		adminLevel = 0,
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
			in_s = true
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

	},
	user = {
		checkAccount = false,
		addAccount = false,
		loadAccount = false,
		loadChecker = false,
		loadAdm = false,
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
}

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
	},
	chat = {
		input_chat = imgui.ImBuffer(1024),
	},
	checker = {
		change_players = {}
	},
	cheat = {
		invisible_onfoot = imgui.ImBool(false),
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
	}
}

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
local players = {}
local g_admin = {}

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
local a_chat = imgui.ImFloat4(0, 0, 0, 0);
local a_report = imgui.ImFloat4(0, 0, 0, 0);
local a_pm = imgui.ImFloat4(0, 0, 0, 0);
local a_sms = imgui.ImFloat4(0, 0, 0, 0);


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

function main()
	-- Ожидание загрузки модулей, чтобы скрипт не крашился при запуске игры
	if not isSampfuncsLoaded() or not isSampLoaded() then
			return
	end
	while not isSampAvailable() do
			wait(0)
	end

	-- Проверка на наличие нужных библиотек
	if not result_imgui then
		sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует библиотека {80EC42}'imgui'", 0x4682B4)
		sampAddChatMessage("[AHelper] {FFFFFF}Скрипт не загружен", 0x4682B4)
		thisScript():unload()
	else
		if not result_requests or not result_encoding or not result_memory or not result_sampev or not result_icons or not result_lanes or not result_imgui_notf or not result_slnet or not result_vkeys then
			sampAddChatMessage("[AHelper] {FFFFFF}Отсутствует одна или несколько необходимых библиотек. Начинается скачивание...", 0x4682B4)
			sampDisconnectWithReason(quit)
			if not result_icons then
				downloadLibrary ('icons')
			end
			if not result_sampev then
				downloadLibrary ('sampev')
			end
			if not result_encoding then
				downloadLibrary ('encoding')
			end
			if not result_requests then
				downloadLibrary ('requests')
			end
			if not result_lanes then
				downloadLibrary ('lanes')
			end
			if not result_vkeys then
				downloadLibrary ('vkeys')
			end
			if not result_slnet then
				downloadLibrary ('slnet')
			end
			if not result_imgui_notf then
				downloadLibrary ('notf')
			end
		end
	end

	while not result_imgui or not result_encoding or not result_sampev or not result_icons or not result_requests or not result_lanes or not result_imgui_notf or not result_vkeys or not result_slnet do
		wait (0)
	end
	print ("Все библиотеки загружены")
	if not sampIsLocalPlayerSpawned() then sampSetGamestate(1) end
	sampev = require 'lib.samp.events'
	fa = require 'fAwesome5'
	notf = import 'imgui_notf.lua'
	-- Кодировка
	encoding = require 'encoding'
	encoding.default = 'CP1251'
	u8 = encoding.UTF8

	memory.fill(sampGetBase()+0x2D3C45, 0, 2, true)

	-- Проверка на название файла, чтобы не запустилось два дубликата скрипта одновременно, может можно как-то по-другому, хз
	if thisScript().filename ~= "AHelper.luac" and thisScript().filename ~= "AHelper3.lua" then
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



	-- Регистрация команд
	sampRegisterChatCommand ("aut", function()
		if getLocalPlayerName() == "Ken_Higa" or getLocalPlayerName() == "RaffCor" then
			pTemp.user.checkAccount = true
		end
	end)
	sampRegisterChatCommand ("chat", function()
		if pTemp.login then
			win_state['chat'].v = not win_state['chat'].v
		end
	end)
	sampRegisterChatCommand ("amenu", aMenu)
	sampRegisterChatCommand ("checker", checkerPlayer)

	initializeRender()

	lua_thread.create (check_account)
	lua_thread.create (register_account)
	lua_thread.create (load_account)
	lua_thread.create (WallHack)
	lua_thread.create (send_packet)
	lua_thread.create (updateAdmList)
	lua_thread.create (statUpdate)
	lua_thread.create (ClickWarpTP)

	--lua_thread.create (load_answers)
	--lua_thread.create (load_table_punishments)
	lua_thread.create (load_checker)
	--lua_thread.create (Test_Punish)
	--lua_thread.create (load_custom_cmd)
	--lua_thread.create (check_requests)
	--lua_thread.create (give_pr)
	lua_thread.create (load_adm)
	lua_thread.create (fastMap)

	if sampIsLocalPlayerSpawned() then pTemp.user.checkAccount = true end -- Запуск скрипта при перезагрузке
	-- Цикл main
	while true do
		wait (0)
		client:check_updates()
		-- Курсор и блокировка движения в зависимости от значений переменных
		imgui.ShowCursor = win_state['main'].v or win_state['update_info'].v or win_state['chat'].v or win_state['checker'].v
		if pTemp.spec_id == sInfo.MAX_PLAYERS then
			imgui.LockPlayer = win_state['main'].v or win_state['update_info'].v or win_state['chat'].v or win_state['checker'].v
		else imgui.LockPlayer = false end

		local connection_status = client.status
		if connection_status == SLNET_CONNECTED then
			pTemp.slnet_conn = 1
		elseif connection_status == SLNET_CONNECTING then
			pTemp.slnet_conn = 2
		else
			pTemp.slnet_conn = 3
		end

		if pTemp.login then

			if (pInfo.set.OnlineAdmins == '1' or pInfo.set.OnlineAdmins == true) and not isPauseMenuActive() then
				local sX, sY = getScreenResolution()
				local y = sY-220
				local x = sX / 3.8
				if pInfo.set.cX ~= '0' then
					x = pInfo.set.cX
					y = pInfo.set.cY
				end
				renderFontDrawText(my_font, 'Администрация онлайн:', x, y-30, 0xFFFFFFFF)
				for i, v in ipairs (admList) do
					local aColor = ''
					if v.adminLevel == '6' then aColor = '{2D94F0}'
					elseif v.adminLevel == '1' then aColor = '{CDCDCD}'
					elseif v.adminLevel == '2' then aColor = '{FC7C37}'
					else aColor = '{18B637}' end
					renderFontDrawText (my_font, string.format ("%s%s[%d] - %d level %s", aColor, v.adminNick, v.adminID, v.adminLevel, v.adminNext), x, y, 0xFFFFFFFF)
					y = y + 20 - 3 * (3-pInfo.set.font_size)
				end
			end

			if (pInfo.set.OnlinePlayers == '1' or pInfo.set.OnlinePlayers == true) and not isPauseMenuActive() then
				local sX, sY = getScreenResolution()
				local y = sY-220
				local x = sX / 1.65
				if pInfo.set.pX ~= '0' then
					x = pInfo.set.pX
					y = pInfo.set.pY
				end
				renderFontDrawText(my_font, 'Игроки онлайн:', x, y-30, 0xFFFFFFFF)
				for i in ipairs (players) do
					for j = 0, sampGetMaxPlayerId (false) do
						if sampIsPlayerConnected (j) then
							if players[i] == getPlayerName (j) then
								renderFontDrawText (my_font, string.format ("{F4522F}%s [%d]", players[i], j), x, y, 0xFFFFFFFF)
								y = y + 20
							end
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
					end
				end
			end

			if getCharArmour(PLAYER_PED) < 1000 and (pInfo.set.invisible_onfoot == true or pInfo.set.invisible_onfoot == '1') then pTemp.antiCheat = true end
			if pTemp.antiCheat == true and getCharArmour(PLAYER_PED) == 1000 then pTemp.antiCheat = false end

			if pTemp.spectate == false then
				pTemp.spec_id = sInfo.MAX_PLAYERS
			end

			if pTemp.spectate == true then
				win_state['re_panel'].v = pTemp.spectate
				win_state['right_panel'].v = pTemp.spectate
			else
				if pTemp.objectSetPos == 3 then
					win_state['re_panel'].v = true
					win_state['right_panel'].v = false
				end
				if pTemp.objectSetPos == 4 then
					win_state['re_panel'].v = false
					win_state['right_panel'].v = true
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

		end

	end
end

local waitFuckingCursor = 0

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

function statUpdate()
	while true do
		wait (0)
		if pTemp.login then
			getStat()
			getAdmStat()
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
	for i in ipairs (players) do
		iVar.checker.change_players[i] = imgui.ImBuffer(256)
		iVar.checker.change_players[i].v = u8(string.format ("%s", players[i]))
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
				local i = 1
				for j in pairs(players) do table.remove(players, j) end
				for nick in u8:decode(response.text):gmatch("(.-)\n") do
					players[i] = nick
					i = i + 1
				end
				for i in ipairs (players) do
					iVar.checker.change_players[i] = imgui.ImBuffer(256)
					iVar.checker.change_players[i].v = u8(string.format ("%s", players[i]))
				end
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nЧекер игроков загружен', 7)
			end,
			function (err)

			end)
		end
	end
end


function send_packet()
	while true do
		wait (300)
		local bitstream = BitStream()
		bitstream:write('unsigned char', 24)
		bitstream:write('string', getLocalPlayerName())
		client:send_packet(3, bitstream)
	end
end

function fastMap()
	while true do
		wait (20)
		-- Проверка на то, что не открыт чат, не открыт диалог, не активно окно консоли сампфункса
		if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
			if isKeyDown (VK_M) then
				writeMemory(menuPtr + 0x33, 1, 1, false) -- activate menu
	        	-- wait for a next frame
		        wait(0)
		        writeMemory(menuPtr + 0x15C, 1, 1, false) -- textures loaded
		        writeMemory(menuPtr + 0x15D, 1, 5, false) -- current menu
		        writeMemory(menuPtr + 0x64, 4, representFloatAsInt(300.0), false)
		        while isKeyDown(VK_M) do
		          wait(80)
		        end
		        writeMemory(menuPtr + 0x32, 1, 1, false) -- close menu
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
					if not fourth_stage:find("| %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %d+ | %S+ | %d+ | %d+ | %d+ | .* | %d+ | %d+") then
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
						--a_recolor = imgui.ImBool(true)
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
						--WallHackAuto = imgui.ImBool(true)
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
					pInfo.info.adminLevel = tonumber (pInfo.info.adminLevel)
					old_level = tonumber(pInfo.info.adminLevel)
					--[[a_chat.v[1], a_chat.v[2], a_chat.v[3], a_chat.v[4] = imgui.ImColor(pInfo.set.colorAChat):GetRGBA()
					a_chat.v[1] = a_chat.v[1]/255
					a_chat.v[2] = a_chat.v[2]/255
					a_chat.v[3] = a_chat.v[3]/255
					old_achat = a_chat.v[1]]--

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
						--r_recolor = imgui.ImBool(true)
						pInfo.set.recolor_r = true
					elseif pInfo.set.recolor_r == '0' then
						pInfo.set.recolor_r = false
					end
					if pInfo.set.recolor_p == '1' then
						--p_recolor = imgui.ImBool(true)
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

					--[[type_wh.v = pInfo.set.type_wh
					if pInfo.set.newLip == '1' then newLipM.v = true
					else newLipM.v = false end

					if pInfo.set.AutoAnswer == '1' then AnswerAuto.v = true
					else AnswerAuto.v = false end]]--

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

					a_report.v[1], a_report.v[2], a_report.v[3], a_report.v[4] = imgui.ImColor(pInfo.set.colorReport):GetRGBA()
					a_report.v[1] = a_report.v[1]/255
					a_report.v[2] = a_report.v[2]/255
					a_report.v[3] = a_report.v[3]/255

					a_pm.v[1], a_pm.v[2], a_pm.v[3], a_pm.v[4] = imgui.ImColor(pInfo.set.colorPm):GetRGBA()
					a_pm.v[1] = a_pm.v[1]/255
					a_pm.v[2] = a_pm.v[2]/255
					a_pm.v[3] = a_pm.v[3]/255

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
					--[[if pInfo.set.warnings.textures == '1' then iVar.warnings.textures.v = true
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
					iVar.leftPanel.v = tonumber (pInfo.set.re_panel_style)
					if pInfo.set.warnings.speedhack == '1' then iVar.warnings.speedhack.v = true
					else iVar.warnings.speedhack.v = false end
					iVar.warnings.speedhack_delay.v = tonumber (pInfo.set.warnings.speedhack_delay)
					if pInfo.set.warnings.repair == '1' then iVar.warnings.cleoRepair.v = true
					else iVar.warnings.cleoRepair.v = false end
					if pInfo.set.converter == '1' then iVar.settings.infjm.v = true
					else iVar.settings.infjm.v = false end
					if pInfo.set.invisible_onfoot == '1' then iVar.invisible_onfoot.v = true
					else iVar.invisible_onfoot.v = false end
					if pInfo.set.air_activate == '1' then iVar.air_activate.v = true
					else iVar.air_activate.v = false end
					if pInfo.set.re_panel_change == '1' then iVar.leftPanel_cb.v = true
					else iVar.leftPanel_cb.v = false end
					if pInfo.set.ip_hash == '1' then iVar.ip_hash.v = true
					else iVar.ip_hash.v = false end
					if pInfo.set.right_panel_change == '1' then iVar.right_panel_change.v = true
					else iVar.right_panel_change.v = false end
					if pInfo.set.fps_unlock == '1' then
						enableFPSUnlock()
						iVar.fps_unlock.v = true
					else iVar.fps_unlock.v = false end
					if pInfo.set.clickwarp == '1' then iVar.clickwarp.v = true
					else iVar.clickwarp.v = false end
					if pInfo.set.clock == '1' then iVar.clock.v = true
					else iVar.clock.v = false end
					if pInfo.set.forms == '1' or pInfo.set.forms == true then iVar.forms.v = true
					else iVar.forms.v = false end
					if pInfo.set.recolor_s == '1' then
						s_recolor = imgui.ImBool(true)
						pInfo.set.recolor_s = true
					elseif pInfo.set.recolor_s == '0' then
						pInfo.set.recolor_s = false
					end

					pInfo.set.colorSMS = tonumber (pInfo.set.colorSMS)

					a_sms.v[1], a_sms.v[2], a_sms.v[3], a_sms.v[4] = imgui.ImColor(pInfo.set.colorSMS):GetRGBA()
					a_sms.v[1] = a_sms.v[1]/255
					a_sms.v[2] = a_sms.v[2]/255
					a_sms.v[3] = a_sms.v[3]/255]]--

					pInfo.set.font_size, pInfo.set.widget.kills, pInfo.set.widget.time_s, pInfo.set.widget.pm_all, pInfo.set.widget.pun_all, pInfo.set.widget.pm_day, pInfo.set.widget.pun_day,
					pInfo.set.widget.datetime, pInfo.set.widget.in_s, pInfo.set.sizeWidget, pInfo.set.keys_panel, pInfo.set.kX, pInfo.set.kY, pInfo.set.r_text, pInfo.set.auto_screen, pInfo.set.admSortType = fourth_stage:match ("| (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%d+) | (%S+) | (%d+) | (%d+) | (%d+) | (.*) | (%d+) | (%d+)")

					--[[if pInfo.set.widget.kills == '1' then iVar.widget.kills.v = true
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
					if pInfo.set.keys_panel == '1' then iVar.keys_panel.v = true
					else iVar.keys_panel.v = false end
					if pInfo.set.auto_screen == '1' then iVar.auto_screen.v = true
					else iVar.auto_screen.v = false end
					iVar.sizeWidget.v = tonumber (pInfo.set.sizeWidget)]]--

					pInfo.set.font_size = tonumber (pInfo.set.font_size)
					iVar.main_settings.fontSizeAdmList.v = pInfo.set.font_size
					my_font = renderCreateFont('Arial', 7+pInfo.set.font_size-(3-pInfo.set.font_size), 1+4)

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


					--nick12 = getLocalPlayerName()
					--load_answers()
					--load_table_punishments()
				--	load_checker()
					--load_adm()
					--xuynya_kakayato() -- если не поместить переменные в отдельную функцию, то будет error -_-


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


					client:connect('176.119.157.232', 445)
					local bitstream = BitStream()
					bitstream:write('unsigned char', 44)
					bitstream:write('string', getLocalPlayerName()..' | '..srv)
					client:send_packet(1, bitstream)
					client:send_packet(5, nil)

					print ("Аккаунт загружен.")
					notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nАккаунт успешно загружен', 7)
					pTemp.admUpdate = true
					sampSendChat("/admins")
					pTemp.user.loadChecker = true
					pTemp.user.loadAdm = true
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
		end
	end
end

function aMenu()
	--if pTemp.login then
		getStat()
		getAdmStat()
		win_state['main'].v = not win_state['main'].v
	--end
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
		imgui.SetNextWindowSize(imgui.ImVec2(1300, 630), imgui.Cond.FirstUseEver)
		imgui.Begin(u8('Главное меню | v'..thisScript().version..' (#'..thisScript().version_num..')'), win_state['main'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus)
		imgui.GetStyle().Colors[imgui.Col.ChildWindowBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
		imgui.BeginChild ('main child', imgui.ImVec2(205, 590), false)
			imgui.GetStyle().Colors[imgui.Col.ChildWindowBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00);
			imgui.BeginChild ('list', imgui.ImVec2(200, 450), true)
				imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 0.00); -- Прозрачные кнопки
				imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.0, 0.5) -- Текст на кнопках по левому краю
				imgui.CenterTextColoredRGB('Меню')
				imgui.Separator()
				if imgui.ActiveButtonMC (1, '  '..fa.ICON_FA_INFO_CIRCLE..u8'      Главная', imgui.ImVec2(185, 20)) then pTemp.menu_id = 1 end
				if imgui.ActiveButtonMC (2, '  '..fa.ICON_FA_USER_COG..u8'     Настройки', imgui.ImVec2(185, 20)) then pTemp.menu_id = 2 end
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
			imgui.BeginChild ('bottom', imgui.ImVec2(200, 115), true) -- Нижний левый прямоугольник

			imgui.EndChild()
		imgui.EndChild()
		imgui.SameLine()
		if pTemp.menu_id == 1 then
			imgui.BeginChild ('content', imgui.ImVec2(1072, 587), true) -- Главная

			imgui.EndChild()
		elseif pTemp.menu_id == 2 then -- Настройки
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

			imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(1.00, 0.28, 0.28, 1.00);
			imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

			imgui.EndChild()
			imgui.SameLine()
			if pTemp.submenu_id == 1 then
				submenu_1()
			elseif pTemp.submenu_id == 2 then
				submenu_2()
			elseif pTemp.submenu_id == 5 then
				submenu_5()
			end
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
				if pTemp.chat.chat_delay < os.time() then
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
		imgui.SetNextWindowSize(imgui.ImVec2 (320, 450), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2 , screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8'Чекер игроков', win_state['checker'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
		for i in ipairs(players) do
			imgui.InputText(string.format (u8"Ник игрока##%d", i),iVar.checker.change_players[i])
			if imgui.Button(u8(string.format ("Сохранить ник##%d", i))) then
				local g__admin = false
				for j in ipairs (g_admin) do
					if iVar.checker.change_players[i].v == g_admin[j] then g__admin = true end
				end
				if g__admin == false then
					local upd_rep = {}
					upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&players="..u8:decode(iVar.checker.change_players[i].v).."&old_players="..players[i]
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
			if imgui.Button(u8(string.format ("Удалить ник##%d", i))) then
				local upd_rep = {}
				upd_rep.data = "srv="..srv.."&num="..pInfo.info.playerAccountNumber.."&old_players="..players[i]
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
			imgui.NewLine()
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
		imgui.Begin('Widget', win_state['widget'], imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
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
			imgui.Text(u8"Инвиз: ")
			imgui.SameLine()
			if iVar.cheat.invisible_onfoot.v == false then imgui.TextColored(imgui.ImColor(251, 43, 19, 255):GetVec4(), u8"выключен")
			else imgui.TextColored(imgui.ImColor(15, 162, 35, 255):GetVec4(), u8"включен") end
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
	imgui.NewLine()
	imgui.SameLine(17)
	if imgui.Checkbox(u8'Приветствие при взятии жалобы', iVar.main_settings.answerAuto) then
		pInfo.set.AutoAnswer = iVar.main_settings.answerAuto.v
		if pInfo.set.AutoAnswer then savedata ('autoanswer', 1)
		else savedata ('autoanswer', 0) end
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
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестопложение сохранено', 5)
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
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестопложение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('px', 2)
				savedata ('py', 2)
				pTemp.objectSetPos = 0
			end
		end
	end
	imgui.NewLine()
	imgui.SameLine(17)
	imgui.PushItemWidth(150)
	if imgui.SliderInt(u8'Размер шрифта', iVar.main_settings.fontSizeAdmList, 1, 4) then
		pInfo.set.font_size = iVar.main_settings.fontSizeAdmList.v
		my_font = renderCreateFont('Arial', 7+pInfo.set.font_size-(3-pInfo.set.font_size), 1+4)
		savedata ('font_size', 2)
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
					notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестопложение сохранено', 5)
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
				notf.addNotification(os.date("%d.%m.%Y %H:%M:%S")..'\n\nМестопложение сохранено', 5)
				sampSetCursorMode(0)
				savedata ('rpX', 2)
				savedata ('rpY', 2)
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

function submenu_5()
	imgui.BeginChild ('settings_tracers', imgui.ImVec2(872, 587), true)
	imgui.Checkbox (u8'Включить/Выключить', iVar.tracers.BulletTrackActivate)
	imgui.Separator()
	imgui.Checkbox (u8'Отображать только для одного игрока', iVar.tracers.BulletTrackOnlyPlayer)
	imgui.Separator()
	imgui.PushItemWidth(250)
	imgui.SliderInt(u8"Время задержки", iVar.tracers.BulletTrackTime, 1, 20)
	imgui.SliderInt(u8"Максимальное количество линий", iVar.tracers.BulletTrackMaxLines, 10, 100)
	imgui.SliderInt(u8"Толщина линий", iVar.tracers.BulletTrackMaxWeight, 1, 10)
	imgui.Separator()
	imgui.Checkbox (u8'Окончания на линиях', iVar.tracers.BulletTrackPolyginActivate)
	imgui.SliderInt(u8"Размер окончаний на линиях", iVar.tracers.BulletTrackSizePolygon, 1, 50)
	imgui.SliderInt(u8"Количество углов на окончании", iVar.tracers.BulletTrackCountPolygin, 3, 50)
	imgui.SliderInt(u8"Градус поворота на окончании", iVar.tracers.BulletTrackRotationPolygon, 0, 360)
	imgui.Separator()
	imgui.ColorEdit4(u8"Цвет при попадании в игрока", shot_in_player)
	imgui.ColorEdit4(u8"Цвет при попадании в игрока AFK", shot_in_player_afk)
	imgui.ColorEdit4(u8"Цвет при попадании в транспорт", shot_in_vehicle)
	imgui.ColorEdit4(u8"Цвет при попадании в статический объект", shot_in_static_obj)
	imgui.ColorEdit4(u8"Цвет при попадании в динамический объект", shot_in_dynamic_obj)
	imgui.Separator()
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

function Converter(seconds)
	seconds = tonumber (seconds)
	if seconds < 3600 then
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

function downloadLibrary(lib)
	local path = getGameDirectory() .. '\\moonloader\\lib\\'
	if lib == 'icons' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/fAwesome5.lua', path..'fAwesome5.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла fAwesome5.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/fa-solid-900.ttf', getGameDirectory() .. '\\moonloader\\resource\\fonts\\fa-solid-900.ttf', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла fa-solid-900.ttf завершена", -1)
				result_icons = true
				if result_encoding and result_imgui_notf and result_lanes and result_requests and result_sampev and result_slnet then thisScript():reload() end
			end

		end)
	elseif lib == 'sampev' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/events.lua', path..'samp\\events.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/events.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/raknet.lua', path..'samp\\raknet.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/raknet.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/synchronization.lua', path..'samp\\synchronization.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/synchronization.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/events/bitstream_io.lua', path..'samp\\events\\bitstream_io.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/events/bitstream_io.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/events/core.lua', path..'samp\\events\\core.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/events/core.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/events/extra_types.lua', path..'samp\\events\\extra_types.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/events/extra_types.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/events/handlers.lua', path..'samp\\events\\handlers.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/events/handlers.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/samp/events/utils.lua', path..'samp\\events\\utils.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла samp/events/utils.lua завершена", -1)
				result_sampev = true
				if result_imgui_notf and result_lanes and result_encoding and result_requests and result_slnet then thisScript():reload() end
			end
		end)
	elseif lib == 'encoding' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/encoding.lua', path..'encoding.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла encoding.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/iconv.dll', path..'iconv.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла iconv.dll завершена", -1)
				result_encoding = true
				if result_imgui_notf and result_lanes and result_requests and result_slnet then thisScript():reload() end
			end
		end)
	elseif lib == 'notf' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/imgui_notf.lua', getGameDirectory()..'\\moonloader\\imgui_notf.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла imgui_notf.lua завершена", -1)
				result_imgui_notf = true
				thisScript():reload()
			end
		end)
	elseif lib == 'requests' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/requests.lua', path..'requests.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла requests.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/ssl/https.lua', path..'ssl\\https.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла ssl/https.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/ssl.lua', path..'ssl.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла ssl.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/ssl.dll', path..'ssl.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла ssl.dll завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/cjson.dll', path..'cjson.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла cjson.dll завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/copas.lua', path..'copas.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла copas.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/copas/ftp.lua', path..'copas\\ftp.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла copas/ftp.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/copas/http.lua', path..'copas\\http.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла copas/http.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/copas/limit.lua', path..'copas\\limit.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла copas/limit.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/copas/smtp.lua', path..'copas\\smtp.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла copas/smtp.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lfs.dll', path..'lfs.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lfs.dll завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lub/Autoload.lua', path..'lub\\Autoload.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lub/Autoload.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lub/Dir.lua', path..'lub\\Dir.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lub/Dir.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lub/init.lua', path..'lub\\init.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lub/init.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lub/Param.lua', path..'lub\\Param.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lub/Param.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lub/Template.lua', path..'lub\\Template.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lub/Template.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/md5.lua', path..'md5.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла md5.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/md5/core.dll', path..'md5\\core.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла md5/core.dll завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/mime.lua', path..'mime.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла mime.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/mimetypes.lua', path..'mimetypes.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла mimetypes.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/ltn12.lua', path..'ltn12.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла ltn12.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/cjson/util.lua', path..'cjson\\util.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла cjson/util.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/mime/core.dll', path..'mime\\core.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла mime/core.dll завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket.lua', path..'socket.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/core.dll', path..'socket\\core.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/core.dll завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/ftp.lua', path..'socket\\ftp.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/ftp.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/headers.lua', path..'socket\\headers.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/headers.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/http.lua', path..'socket\\http.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/http.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/smtp.lua', path..'socket\\smtp.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/smtp.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/tp.lua', path..'socket\\tp.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/tp.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/socket/url.lua', path..'socket\\url.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла socket/url.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/xml/Parser.lua', path..'xml\\Parser.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла xml/Parser.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/xml/init.lua', path..'xml\\init.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла xml/init.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/xml/core.dll', path..'xml\\core.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла xml/core.dll завершена", -1)
				result_requests = true
				if result_lanes and result_imgui_notf and result_slnet then thisScript():reload() end
			end
		end)
	elseif lib == 'lanes' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lanes.lua', path..'lanes.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lanes.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/lanes/core.dll', path..'lanes\\core.dll', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла lanes/core.dll завершена", -1)
				if result_imgui_notf and result_slnet == true then thisScript():reload() end
				lua_thread.create (function ()
					wait (500)
					result_lanes = true
					lanes = require('lanes').configure()
				end)
			end
		end)
	elseif lib == 'vkeys' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/vkeys.lua', path..'vkeys.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла vkeys.lua завершена", -1)
			end
		end)
	elseif lib == 'slnet' then
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/slnet.lua', path..'slnet.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла slnet.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/slnet/init.lua', path..'slnet\\init.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла slnet/init.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/slnet/bitcoder.lua', path..'slnet\\bitcoder.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла slnet/bitcoder.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/slnet/bitstream.lua', path..'slnet\\bitstream.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла slnet/bitstream.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/slnet/client.lua', path..'slnet\\client.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла slnet/client.lua завершена", -1)
			end
		end)
		downloadUrlToFile ('https://raw.githubusercontent.com/RaffCor/AHelper_New/master/lib/slnet/server.lua', path..'slnet\\server.lua', function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage ("Загрузка файла slnet/server.lua завершена", -1)
				lua_thread.create (function()
					wait (1000)
					--result_slnet = true
					--slnet = require 'slnet'
					--client = slnet.client()
					thisScript():reload()
					--if result_imgui_notf then thisScript():reload() end
				end)
			end
		end)
	end
end

if not result_sampev or not result_slnet then
	return
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


function sampev.onServerMessage(color, text)
	if text == "Данный режим доступен с звания ''Новичок'' (/rank)" then
		sampAddChatMessage("[AHelper] {FFFFFF}Сейчас вы не можете перейти на GangWar. Режим изменён", 0x4682B4)
		aInfo.set.typeSpawn = 1
	end

	if text == "Неверный пароль!" then
		aInfo.set.lPass_On = false
		aInfo.info.lPass = ""
	end
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
			sampAddChatMessage(data.targetType, -1)
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
				sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] возможно попал сквозь текстуру в %s[%d] с %s", getPlayerName(playerid), playerid, getPlayerName(data.targetId), data.targetId, getWeaponModelName (data.weaponId)), 0xE33B27)
				pTemp.delay.textures[playerid] = os.time() + warnings.delay_textures
			end
		end
	end

	if pInfo.set.warnings.hit == true or pInfo.set.warnings.hit == '1' then
		if data.targetType == 1 then
			if data.weaponId == 24 then
				Hit.Deagle[playerid] = Hit.Deagle[playerid] + 1
				if Hit.Deagle[playerid] == pInfo.set.warnings.deagle then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Desert Eagle", getPlayerName(playerid), playerid, warnings.shooting.Deagle.maxHit), 0xE33B27)
					Hit.Deagle[playerid] = 0
				end
			elseif data.weaponId == 31 then
				Hit.M4[playerid] = Hit.M4[playerid] + 1
				if Hit.M4[playerid] == pInfo.set.warnings.m4 then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с M4", getPlayerName(playerid), playerid, warnings.shooting.M4.maxHit), 0xE33B27)
					Hit.M4[playerid] = 0
				end
			elseif data.weaponId == 22 then
				Hit.Pistol9mm[playerid] = Hit.Pistol9mm[playerid] + 1
				if Hit.Pistol9mm[playerid] == pInfo.set.warnings.pistol then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с 9mm", getPlayerName(playerid), playerid, warnings.shooting.Pistol.maxHit), 0xE33B27)
					Hit.Pistol9mm[playerid] = 0
				end
			elseif data.weaponId == 23 then
				Hit.Silenced[playerid] = Hit.Silenced[playerid] + 1
				if Hit.Silenced[playerid] == pInfo.set.warnings.silenced then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Silenced 9mm", getPlayerName(playerid), playerid, warnings.shooting.Silenced.maxHit), 0xE33B27)
					Hit.Silenced[playerid] = 0
				end
			elseif data.weaponId == 25 then
				Hit.Shotgun[playerid] = Hit.Shotgun[playerid] + 1
				if Hit.Shotgun[playerid] == pInfo.set.warnings.shotgun then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Shotgun", getPlayerName(playerid), playerid, warnings.shooting.Shotgun.maxHit), 0xE33B27)
					Hit.Shotgun[playerid] = 0
				end
			elseif data.weaponId == 29 then
				Hit.MP5[playerid] = Hit.MP5[playerid] + 1
				if Hit.MP5[playerid] == pInfo.set.warnings.mp5 then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с MP-5", getPlayerName(playerid), playerid, warnings.shooting.MP5.maxHit), 0xE33B27)
					Hit.MP5[playerid] = 0
				end
			elseif data.weaponId == 30 then
				Hit.AK47[playerid] = Hit.AK47[playerid] + 1
				if Hit.AK47[playerid] == pInfo.set.warnings.ak47 then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с AK-47", getPlayerName(playerid), playerid, warnings.shooting.AK47.maxHit), 0xE33B27)
					Hit.AK47[playerid] = 0
				end
			elseif data.weaponId == 33 then
				Hit.Rifle[playerid] = Hit.Rifle[playerid] + 1
				if Hit.Rifle[playerid] == pInfo.set.warnings.rifle then
					sampAddChatMessage(string.format ("[WARNING] {82807F}%s[%d] попал %d раз(а) подряд с Country Rifle", getPlayerName(playerid), playerid, warnings.shooting.Rifle.maxHit), 0xE33B27)
					Hit.Rifle[playerid] = 0
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
end

function sampev.onSendBulletSync (data)
	sampAddChatMessage(data.targetType, -1)
	sampAddChatMessage(data.target.x, -1)
	sampAddChatMessage(data.target.y, -1)
	sampAddChatMessage(data.target.z, -1)
end

function sampev.onPlayerJoin(id, color, isNPC, nickname)
	for i in ipairs (players) do
		if nickname == players[i] then
			sampAddChatMessage(string.format ("[AHelper] %s[%d] зашёл на сервер", nickname, id), 0xFF0000)
			printStyledString(string.format ("~n~~n~~n~~n~~n~~n~~w~~r~%s (%d) ~w~joined.", nickname, id), 5000, 4)
		end
	end
	if pTemp.login == true then pTemp.player_time_session[id] = os.time() end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	print (dialogId)
	print (title)
	print (text)
	print (button1)
	print (button2)
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

end


function sampev.onPlayerQuit(id, reason)
	local a_reason
	if reason == 1 then a_reason = "самостоятельный выход"
	elseif reason == 2 then a_reason = "кик/бан"
	elseif reason == 0 then a_reason = "краш/потеря соединения" end
	for i, v in ipairs(admList) do
		if v.adminID == id and pTemp.adminQuit[id] == false then
			sampAddChatMessage(string.format ("[AHelper] {E1CD29}Администратор %s отключился от сервера {4682B4}(%s)", v.adminNick, a_reason), 0x4682B4)
			pTemp.adminQuit[id] = true
		end
	end
end

function sampev.onSendDialogResponse (dialogId, button, listBoxId, input)
	--[[print ('----------')
	print (dialogId)
	print (button)
	print (listboxId)
	print (input)
	print ('----------')]]--
end

function sampev.onPlayerSync (id, data)

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

end

function client.on_receive_packet(id, bs, priority, address, port)
	if id == 1 then

	elseif id == 2 then
		local message = bs:read('string', 2147483647)
		pTemp.chat.chat_text = message
	end
end
