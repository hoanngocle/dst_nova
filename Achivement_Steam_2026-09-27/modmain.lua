local _G = GLOBAL
local require = GLOBAL.require
local Profile = require("playerprofile")()

_G.INTEGRATEDBACKPACK_CONFIG 	= Profile:GetIntegratedBackpack() --GetModConfigData('WXWIDGET')

_G.LOGING_CONFIG 		= false
_G.ASSISTRANGE_CONFIG 	= GetModConfigData('ASSISTRANGE')
_G.REFUND_CONFIG 		= GetModConfigData('REFUND')
_G.HPPENALTY_CONFIG 	= GetModConfigData('HPPENALTY')
_G.PLAYS_CONFIG 		= GetModConfigData('PLAYS')
_G.LEVEL_LIMIT 			= GetModConfigData('LEVEL_LIMIT')
_G.EXP_MULT 			= GetModConfigData('EXP_MULT')
_G.LEVELPOINTS 			= GetModConfigData('LEVELPOINTS')
_G.NOTIFICATION 		= GetModConfigData('NOTIFICATION')
_G.NOAWARDS 			= false
_G.FOODXP 				= GetModConfigData('FOODXP')
_G.BUILDXP 				= GetModConfigData('BUILDXP')
_G.KILLXP 				= GetModConfigData('KILLXP')
_G.WORKXP 				= GetModConfigData('WORKXP')
_G.COOKXP 				= GetModConfigData('COOKXP')
_G.PLANTXP 				= GetModConfigData('PLANTXP')
_G.FISHXP 				= GetModConfigData('FISHXP')
_G.PICKXP 				= GetModConfigData('PICKXP')
_G.HEALTHGAIN 			= GetModConfigData('HEALTHGAIN')
_G.SANITYGAIN 			= GetModConfigData('SANITYGAIN')
_G.HUNGERGAIN 			= GetModConfigData('HUNGERGAIN')
_G.SPEEDGAIN 			= GetModConfigData('SPEEDGAIN')
_G.ABSORBGAIN 			= GetModConfigData('ABSORBGAIN')
_G.DAMAGEGAIN 			= GetModConfigData('DAMAGEGAIN')
_G.MAX_ABSORBGAIN 		= GetModConfigData('MAX_ABSORBGAIN')
_G.UI_ACH_TOGGLE		= 122
_G.UI_PERK_TOGGLE		= 120
_G.UI_LEVEL_TOGGLE		= 118
_G.KEYBOARD_SHORTCUT    = GetModConfigData('SHORTCUT')

PrefabFiles = require "system/prefabs"
Assets = require "system/assets"

require "functions/helperfunctions"
require "system/balance"
_G.ach_lists = require "constants/achievementdata"
_G.ach_list_lists = require "constants/achievementlistdata"
_G.boss_bonus_xp = require "constants/bossxplistdata"
_G.level_lists = require "constants/leveldata"
_G.perk_lists = require "constants/perkdata"
_G.cz_trinkets = require "constants/trinketdata"
require "system/main_rpc"
require "system/rpc"

local function chasni_getperkexcludeconfig_LOCAL(...)
	if not (TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.HIDEPERK) then
		return nil
	end

	for _, perk in ipairs({...}) do
		if not TUNING.CHASNI_CONFIG.HIDEPERK[string.upper(perk)] then
			return nil
		end
	end

	return true
end

if not chasni_getperkexcludeconfig_LOCAL("blueprintextractor", "itemmerger", "itemcleaner", "sharemap") then
	require 'system/extraperkrpc'
end
if not chasni_getperkexcludeconfig_LOCAL("bosshunting") then
	require 'system/bookvokerrpc'

	local function epress()
		if not TheNet:IsServerPaused() then
			SendModRPCToServer(MOD_RPC["InvokerBook"]["E"])
		end
	end
	local function qpress()
		if not TheNet:IsServerPaused() then
			SendModRPCToServer(MOD_RPC["InvokerBook"]["Q"])
		end
	end
	local function wpress()
		if not TheNet:IsServerPaused() then
			SendModRPCToServer(MOD_RPC["InvokerBook"]["W"])
		end
	end
	GLOBAL.TheInput:AddKeyUpHandler(101, epress)
	GLOBAL.TheInput:AddKeyUpHandler(113, qpress)
	GLOBAL.TheInput:AddKeyUpHandler(119, wpress)
end
if not chasni_getperkexcludeconfig_LOCAL("groundedscream") then
	require 'system/groundedrpc'
end

modimport("main_strings_vi.lua")

local nova_achievements = require "constants/novaachievements"
if #nova_achievements > 0 then
	_G.STRINGS.GUI.nova = "Mới"
	for _, achievement in ipairs(nova_achievements) do
		_G.STRINGS.ACHIEVEMENTS[achievement.id] =
			achievement.strings.vi
	end
end

modimport("main_globalpostInits.lua")
modimport("main_achivpostInits.lua")
modimport("main_novapostInit.lua")
modimport("main_perkpostInits.lua")
modimport("main_levelpostInits.lua")
if not chasni_getperkexcludeconfig_LOCAL("bosshunting") then
	modimport("main_RoGpostInit.lua")
end
if not chasni_getperkexcludeconfig_LOCAL("trinketowner") then
	modimport("main_trinketslotpostInit.lua")
end
modimport("main_initialize.lua")
modimport("main_recipes.lua")
modimport("main_containers.lua")
modimport("scripts/functions/customtechtree.lua")
modimport("main_fx.lua")
if not chasni_getperkexcludeconfig_LOCAL("trinketowner") then
	modimport("scripts/brains/postinit/animallover.lua")
end
if not chasni_getperkexcludeconfig_LOCAL("bosshunting") then
	modimport("scripts/brains/postinit/crabkingbrain.lua")
end
modimport("scripts/system/registeratlas.lua")

AddPlayerPostInit(function(inst)
	-- ach
	for index = 1, 6 do
		inst["seasonaltaskid"..index] = GLOBAL.net_string(inst.GUID,"seasonaltaskid"..index)
		inst["seasonaltaskprogress"..index] = GLOBAL.net_ushortint(inst.GUID,"seasonaltaskprogress"..index)
		inst["seasonaltasktarget"..index] = GLOBAL.net_ushortint(inst.GUID,"seasonaltasktarget"..index)
		inst["seasonaltaskdone"..index] = GLOBAL.net_bool(inst.GUID,"seasonaltaskdone"..index)
	end
	inst.seasonalround = GLOBAL.net_byte(inst.GUID,"seasonalround")
	inst.seasonalfinished = GLOBAL.net_bool(inst.GUID,"seasonalfinished")
	for index = 1, 4 do
		inst["seasonalreward"..index] = GLOBAL.net_string(inst.GUID,"seasonalreward"..index)
	end
	inst.taskprize1 = GLOBAL.net_bool(inst.GUID,"taskprize1")
	inst.taskprize2 = GLOBAL.net_bool(inst.GUID,"taskprize2")
	inst.taskprize3 = GLOBAL.net_bool(inst.GUID,"taskprize3")
	inst.taskprize4 = GLOBAL.net_bool(inst.GUID,"taskprize4")
	for achname, ach in pairs(ach_lists) do
		inst["check"..achname] = GLOBAL.net_shortint(inst.GUID,"check"..achname)
		if ach.current then
			if ach.type == "int" then
				inst["current"..achname] = GLOBAL.net_int(inst.GUID,"current"..achname)
			else
				inst["current"..achname] = GLOBAL.net_shortint(inst.GUID,"current"..achname)
			end
		end
		if ach.list then
			inst["current"..achname.."list"] = GLOBAL.net_string(inst.GUID,"current"..achname.."list")
		end
	end

	-- perk
	inst.currentcoinamount = GLOBAL.net_int(inst.GUID,"currentcoinamount")
	for perkname, perk in pairs(perk_lists) do
		if perk.single ~= true then
			inst["current".. perkname] = GLOBAL.net_shortint(inst.GUID,"current".. perkname)
			if perk.multi then
				inst[perkname .."cost"] = GLOBAL.net_shortint(inst.GUID, perkname .."cost")
			end
		end
	end

	-- level system
	inst.currentlevel = GLOBAL.net_uint(inst.GUID,"currentlevel")
	inst.currentlevelxp = GLOBAL.net_uint(inst.GUID,"currentlevelxp")
	inst.currentoverallxp = GLOBAL.net_uint(inst.GUID,"currentoverallxp")
	inst.currentattributepoints = GLOBAL.net_uint(inst.GUID,"currentattributepoints")
	inst.currentpetlevel = GLOBAL.net_uint(inst.GUID,"currentpetlevel")
	inst.currentpetlevelxp = GLOBAL.net_uint(inst.GUID,"currentpetlevelxp")
	inst.currentpetoverallxp = GLOBAL.net_uint(inst.GUID,"currentpetoverallxp")
	inst.currentpetattributepoints = GLOBAL.net_uint(inst.GUID,"currentpetattributepoints")
	inst.currentpetcanevolve = GLOBAL.net_bool(inst.GUID,"currentpetcanevolve")
	for lvlname, lvl in pairs(level_lists) do
		inst["current"..lvlname] = GLOBAL.net_shortint(inst.GUID,"current"..lvlname)
		inst["current"..lvlname.."cost"] = GLOBAL.net_shortint(inst.GUID,"current"..lvlname.."cost")
		inst["current"..lvlname.."max"] = GLOBAL.net_float(inst.GUID,"current"..lvlname.."max")
	end

	-- ui
	inst.currentzoomlevel = GLOBAL.net_float(inst.GUID,"currentzoomlevel")
	inst.currentmainhudtype = GLOBAL.net_bool(inst.GUID,"currentmainhudtype")
	inst.currentwidgetxpos = GLOBAL.net_float(inst.GUID,"currentwidgetxpos")

	inst:AddComponent("allachivevent")
	inst:AddComponent("allachivcoin")
	inst:AddComponent("levelsystem")
	if not GLOBAL.TheNet:GetIsClient() then
		inst.components.allachivevent:Init(inst)
		inst.components.allachivcoin:Init(inst)
		inst.components.levelsystem:Init(inst)
	end
end)

local function PositionUI(self, screensize)
	local hudscale = self.top_root:GetScale()
	local screenw_full, _ = GLOBAL.unpack(screensize)
	self.uiachievement:SetScale(.6*hudscale.x,.6*hudscale.y,1)
	self.uiachievement.mainbutton.hudscale = self.top_root:GetScale()
	self.uiachievement.mainbutton:SetScale(hudscale.x,hudscale.y,1)
	local pos = self.uiachievement.mainbutton:GetPosition()
	pos = self.uiachievement.mainbutton:GetPosition()
	if self.uiachievement.menuposition == nil then
		self.uiachievement.mainbutton:SetPosition(screenw_full*0.09, pos.y, pos.z)
	else
		if self.uiachievement.menuposition.x > screenw_full then
			self.uiachievement.mainbutton:SetPosition(screenw_full-256, pos.y, pos.z)
		end
	end
end

--UI
local uiachievement = require("widgets/uiachievement")
local uiachievementWidget
local function hideMenus()
	if type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then return end
	uiachievementWidget:hideAll()
end
local function showAch()
	if not TheInput:IsKeyDown(GLOBAL.KEY_ALT) or type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then return end
	if uiachievementWidget.mainbutton.achievementbutton.onclickfn then
		uiachievementWidget.mainbutton.achievementbutton.onclickfn()
	end
end
local function showPerk()
	if not TheInput:IsKeyDown(GLOBAL.KEY_ALT) or type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then return end
	if uiachievementWidget.mainbutton.perkbutton.onclickfn then
		uiachievementWidget.mainbutton.perkbutton.onclickfn()
	end
end
local function showLevel()
	if not TheInput:IsKeyDown(GLOBAL.KEY_ALT) or type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then return end
	if uiachievementWidget.mainbutton.levelbutton.onclickfn then
		uiachievementWidget.mainbutton.levelbutton.onclickfn()
	end
end
local function Adduiachievement(self)
	self.uiachievement = self.top_root:AddChild(uiachievement(self.owner))
	uiachievementWidget = self.uiachievement
	local screensize = {GLOBAL.TheSim:GetScreenSize()}
	PositionUI(self, screensize)
	self.uiachievement:SetHAnchor(0)
	self.uiachievement:SetVAnchor(0)
	self.uiachievement:MoveToFront()
	local OnUpdate_base = self.OnUpdate
	self.OnUpdate = function(self_, dt, ...)
		OnUpdate_base(self_, dt, ...)
		local curscreensize = {GLOBAL.TheSim:GetScreenSize()}
		if curscreensize[1] ~= screensize[1] or curscreensize[2] ~= screensize[2] then
			PositionUI(self_, curscreensize)
			screensize = curscreensize
		end
	end

	self.owner:WatchWorldState("season", function()
		SendModRPCToServer(MOD_RPC["AchievementUI"]["requestSeasonalSync"])
		self.owner:DoTaskInTime(0.5, function()
			uiachievementWidget:rebuild()
		end)
	end)

	GLOBAL.TheInput:AddKeyUpHandler(GLOBAL.KEY_ESCAPE, hideMenus)
	if _G.KEYBOARD_SHORTCUT then
		GLOBAL.TheInput:AddKeyUpHandler(_G.UI_ACH_TOGGLE, showAch)
		GLOBAL.TheInput:AddKeyUpHandler(_G.UI_PERK_TOGGLE, showPerk)
		GLOBAL.TheInput:AddKeyUpHandler(_G.UI_LEVEL_TOGGLE, showLevel)
	end
end

AddClassPostConstruct("widgets/controls", Adduiachievement)

GLOBAL.EQUIPSLOTS.CHASNI_TRINKET_CONTAINERS = "chasni_trinket_container"
