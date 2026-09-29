Assets = {
	Asset("ATLAS", "images/icons.xml"),
	Asset("IMAGE", "images/icons.tex"),
}

local CreateEntity = GLOBAL.CreateEntity

local minimap_atlas_registry = {}

local function TryAddAtlasToRuntime(atlas)
	local minimap = GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.minimap or nil
	if minimap ~= nil and minimap.MiniMap ~= nil then
		local ok, resolved = GLOBAL.pcall(GLOBAL.resolvefilepath, atlas)
		if ok and resolved ~= nil then
			minimap.MiniMap:AddAtlas(resolved)
		end
	end
end

local function RegisterMinimapAtlas(atlas)
	if atlas == nil then
		return
	end

	atlas = atlas:gsub("\\", "/")
	if minimap_atlas_registry[atlas] then
		return
	end

	minimap_atlas_registry[atlas] = true
	AddMinimapAtlas(atlas)
	TryAddAtlasToRuntime(atlas)
end

local DEFAULT_MINIMAP_ATLASES = {
	"images/inventoryimages.xml",
	"images/inventoryimages1.xml",
	"images/inventoryimages2.xml",
	"images/inventoryimages3.xml",
	"images/inventoryimages4.xml",
	"images/icons.xml",
}

for _, atlas in ipairs(DEFAULT_MINIMAP_ATLASES) do
	RegisterMinimapAtlas(atlas)
end

local PREFABS_WITH_VANILLA_ICONS = {
	alterguardianhatshard = true,
	axe = true,
	bee = true,
	bluegem = true,
	boards = true,
	butterfly = true,
	cane = true,
	canary = true,
	canary_poisoned = true,
	chester_eyebone = true,
	crow = true,
	farm_hoe = true,
	fireflies = true,
	firestaff = true,
	flint = true,
	gears = true,
	greenstaff = true,
	goldenaxe = true,
	goldenpickaxe = true,
	goldenpitchfork = true,
	goldenshovel = true,
	goldnugget = true,
	greengem = true,
	manrabbit_tail = true,
	beefalohat = true,
	beehat = true,
	bushhat = true,
	earmuffshat = true,
	featherhat = true,
	flowerhat = true,
	hammer = true,
	hutch_fishbowl = true,
	icestaff = true,
	killerbee = true,
	mandrake = true,
	mole = true,
	moonglassaxe = true,
	mosquito = true,
	opalstaff = true,
	orangestaff = true,
	orangegem = true,
	pickaxe = true,
	pitchfork = true,
	poop = true,
	purplegem = true,
	rabbit = true,
	razor = true,
	redgem = true,
	robin = true,
	robin_winter = true,
	rocks = true,
	sewing_kit = true,
	seeds = true,
	shovel = true,
	staff_lunarplant = true,
	slurper = true,
	spider = true,
	strawhat = true,
	sweatervest = true,
	tophat = true,
	staff_tornado = true,
	telestaff = true,
	golden_farm_hoe = true,
	yellowstaff = true,
	yellowgem = true,
	trunkvest_summer = true,
	trunkvest_winter = true,
	watermelonhat = true,
	winterhat = true,
	walking_stick = true,
}

local PREFABS_WITH_CUSTOM_ICON_OVERRIDES = {
	beefalo = "beefalo_domesticated.png", -- no beefalo.tex in icons.xml; vanilla only enables its own icon once domesticated
	wall_ruins_2 = "wall_ruins",
	wall_stone_2 = "wall_stone",
}

-- Prefabs that already have a minimap icon in vanilla: re-skin that icon instead of
-- parenting a second one to the entity (which would draw two icons in the same spot).
local PREFABS_WITH_EXISTING_MAP_ICONS = {
	antlion = true,
	batcave = true,
	beequeenhivegrown = true,
	catcoonden = true,
	crabking = true,
	marsh_bush = true,
	mermhouse = true,
	minotaur = true,
	monkeybarrel = true,
	slurtlehole = true,
	spiderhole = true,
	-- wormlight_plant is NOT here: vanilla adds a MiniMapEntity but never sets an icon
	-- (its SetIcon is commented out in vanilla), so the helper approach stays correct.
}

-- Prefabs that share another prefab's config option (worldgen-only variants).
local CONFIG_ALIASES = {
	wall_ruins_2 = "wall_ruins",
	wall_stone_2 = "wall_stone",
}

local function GetVanillaIconName(prefab)
	local entry = PREFABS_WITH_VANILLA_ICONS[prefab]
	if entry == nil then
		return nil
	end

	if entry == true then
		return prefab .. ".tex"
	end

	if type(entry) == "string" then
		if entry:find("%.%w+$") then
			return entry
		end
		return entry .. ".tex"
	end

	return nil
end

local function GetCustomIconOverride(prefab)
	local entry = PREFABS_WITH_CUSTOM_ICON_OVERRIDES[prefab]
	if entry == nil then
		return nil, nil
	end

	local atlas = "images/icons.xml"
	local image = prefab .. ".tex"

	if entry == true then
		return image, atlas
	end

	local entry_type = type(entry)

	if entry_type == "string" then
		if entry:find("%.%w+$") then
			image = entry
		else
			image = entry .. ".tex"
		end
		return image, atlas
	end

	if entry_type == "table" then
		if entry.image ~= nil then
			if entry.image:find("%.%w+$") then
				image = entry.image
			else
				image = entry.image .. ".tex"
			end
		end

		if entry.atlas ~= nil then
			atlas = entry.atlas
		end

		return image, atlas
	end

	return image, atlas
end

local PREFAB_GROUPS = {
	chestpets = {
		"chester_eyebone",
		"hutch_fishbowl",
	},

	densandanimals = {
		"batcave",
		"catcoonden",
		"monkeybarrel",
		"molehill",
		"rabbithole",
		"slurtlehole",
		"spiderhole",
	},

	bosses = {
		"alterguardian_phase1",
		"alterguardian_phase2",
		"alterguardian_phase3",
		"alterguardian_phase3dead",
		"antlion",
		"bearger",
		"beequeen",
		"beequeenhivegrown",
		"bishop_nightmare",
		"crabking",
		"daywalker",
		"deerclops",
		"dragonfly",
		"eyeofterror",
		"knight_nightmare",
		"leif",
		"leif_sparse",
		"lordfruitfly",
		"malbatross",
		"minotaur",
		"moose",
		"rook_nightmare",
		"shadow_bishop",
		"shadow_knight",
		"shadow_rook",
		"toadstool",
		"toadstool_dark",
	},

	creatures = {
		"abigail",
		"babybeefalo",
		"bat",
		"beefalo",
		"birchnutdrake",
		"bishop",
		"bunnyman",
		"butterfly",
		"canary",
		"canary_poisoned",
		"catcoon",
		"crawlinghorror",
		"crawlingnightmare",
		"crow",
		"deer",
		"deer_blue",
		"deer_red",
		"eyeplant",
		"firehound",
		"frog",
		"fruitfly",
		"ghost",
		"hound",
		"icehound",
		"knight",
		"koalefant_summer",
		"koalefant_winter",
		"krampus",
		"lavae",
		"lavae_pet",
		"lightninggoat",
		"little_walrus",
		"mandrake",
		"mandrake_active",
		"mandrake_planted",
		"merm",
		"mole",
		"monkey",
		"mosquito",
		"mossling",
		"nightmarebeak",
		"perd",
		"pigguard",
		"pigman",
		"powder_monkey",
		"rabbit",
		"ruins_shadeling",
		"robin",
		"robin_winter",
		"rocky",
		"rook",
		"slurper",
		"slurtle",
		"snurtle",
		"spider",
		"spider_dropper",
		"spider_hider",
		"spider_spitter",
		"spider_warrior",
		"spiderqueen",
		"stalker",
		"stalker_atrium",
		"stalker_forest",
		"stalker_minion1",
		"stalker_minion2",
		"tallbird",
		"tentacle",
		"terrorbeak",
		"walrus",
		"wanderingtrader",
		"warg",
		"warglet",
		"worm",
	},

	resources = {
		"alterguardianhatshard",
		"animal_track",
		"boards",
		"bluegem",
		"dirtpile",
		"flint",
		"gears",
		"goldnugget",
		"greengem",
		"houndbone",
		"manrabbit_tail",
		"orangegem",
		"poop",
		"purplegem",
		"redgem",
		"rocks",
		"skeleton",
		"yellowgem",
		--"opalpreciousgem", (missing)
	},

	structures = {
		"ancient_altar",
		"ancient_altar_broken",
		"mermhead",
		"mermhouse",
		"pighead",
		"pigtorch",
		"stagehand",
		"wall_hay",
		"wall_moonrock",
		"wall_ruins",
		"wall_ruins_2",
		"wall_stone",
		"wall_stone_2",
		"wall_wood",
	},

	clothing = {
		"sewing_kit",
		"flowerhat",
		"strawhat",
		"tophat",
		"beefalohat",
		"featherhat",
		"bushhat",
		"winterhat",
		"beehat",
		"earmuffshat",
		"watermelonhat",
		"sweatervest",
		"trunkvest_summer",
		"trunkvest_winter",
	},

	tools = {
		"axe",
		"cane",
		"farm_hoe",
		"golden_farm_hoe",
		"goldenaxe",
		"goldenpickaxe",
		"goldenpitchfork",
		"goldenshovel",
		"hammer",
		"orangestaff",
		"icestaff",
		"greenstaff",
		"yellowstaff",
		"telestaff",
		"firestaff",
		"staff_lunarplant",
		"opalstaff",
		"moonglassaxe",
		"pickaxe",
		"pitchfork",
		"razor",
		"shovel",
		"staff_tornado",
		"walking_stick",
	},

	vegetation = {
		"blue_mushroom",
		"carrot_planted",
		"flower",
		"green_mushroom",
		"marsh_bush",
		"red_mushroom",
		"seeds",
		"wormlight_plant",
	},
}

local PREFAB_GROUP_ORDER = {
	"chestpets",
	"densandanimals",
	"bosses",
	"creatures",
	"resources",
	"structures",
	"clothing",
	"tools",
	"vegetation",
}

local persistent_icons = GetModConfigData("persistent_icons") ~= false
-- Mobile mobs despawn/die while unloaded, leaving stale cached icons on the map,
-- so creatures and bosses get their own persistence setting (default: Nearby Only).
local creature_persistent_icons = GetModConfigData("creature_persistent_icons") == true

local CREATURE_GROUPS = {
	bosses = true,
	creatures = true,
}


local function ShouldAddIcon(prefab)
	local setting = GetModConfigData(CONFIG_ALIASES[prefab] or prefab)
	if setting == nil then
		return true
	end
	return setting
end

local function AddMapIcon(prefab, persistent)
	AddPrefabPostInit(prefab, function(inst)
		if GLOBAL.TheNet ~= nil and GLOBAL.TheNet:IsDedicated() then
			return
		end

		if PREFABS_WITH_EXISTING_MAP_ICONS[prefab] and inst.MiniMapEntity ~= nil then
			-- OverrideExistingMapIcon re-skins the icon this prefab already has
			return
		end

		local targetprefab = inst.prefab or prefab
		local fallback_icon = targetprefab .. ".tex"

		local function UpdateIcon()
			if inst.emi_mapicon == nil then
				return
			end

			local iconname = fallback_icon
			local atlas = "images/icons.xml"

			local function UseVanillaIcon(image)
				if image ~= nil and GLOBAL.GetInventoryItemAtlas ~= nil then
					-- no_fallback: a miss must return nil, not inventoryimages4.xml
					local resolved = GLOBAL.GetInventoryItemAtlas(image, true)
					if resolved ~= nil then
						iconname = image
						atlas = resolved
						return true
					end
				end
				return false
			end

			local custom_icon, custom_atlas = GetCustomIconOverride(targetprefab)
			if custom_icon ~= nil then
				iconname = custom_icon
				if custom_atlas ~= nil then
					atlas = custom_atlas
				end
			else
				local vanilla_icon = GetVanillaIconName(targetprefab)
				if vanilla_icon ~= nil then
					local has_vanilla = UseVanillaIcon(vanilla_icon)
					if not has_vanilla and inst.replica ~= nil and inst.replica.inventoryitem ~= nil then
						UseVanillaIcon(inst.replica.inventoryitem:GetImage())
					end
				end
			end

			RegisterMinimapAtlas(atlas)

			inst.emi_mapicon.MiniMapEntity:SetIcon(iconname)
		end

		local function IsHeld(inst)
			if inst.components ~= nil then
				local inventoryitem = inst.components.inventoryitem
				if inventoryitem ~= nil then
					if inventoryitem.owner ~= nil then
						return true
					end

					if inventoryitem.GetGrandOwner ~= nil and inventoryitem:GetGrandOwner() ~= nil then
						return true
					end
				end
			end

			if inst.replica ~= nil and inst.replica.inventoryitem ~= nil then
				if inst.replica.inventoryitem:IsHeld() then
					return true
				end
			end

			if inst.entity:GetParent() ~= nil then
				return true
			end

			return false
		end

		local function RemoveHelper()
			if inst.emi_mapicon ~= nil then
				inst.emi_mapicon:Remove()
				inst.emi_mapicon = nil
			end
			if inst.emi_mapicon_refresh_task ~= nil then
				inst.emi_mapicon_refresh_task:Cancel()
				inst.emi_mapicon_refresh_task = nil
			end
		end

		local function RefreshVisibility()
			if inst.emi_mapicon == nil then
				return
			end

			if inst:HasTag("INLIMBO") then
				inst.emi_mapicon.MiniMapEntity:SetEnabled(false)
				return
			end

			if IsHeld(inst) then
				inst.emi_mapicon.MiniMapEntity:SetEnabled(false)
				return
			end

			inst.emi_mapicon.MiniMapEntity:SetEnabled(true)
		end

		inst:DoTaskInTime(0, function()
			if inst.entity == nil or not inst.entity:IsValid() then
				return
			end

			if inst.emi_mapicon ~= nil then
				RefreshVisibility()
				return
			end

			local helper = CreateEntity()
			if helper == nil then
				return
			end

			helper.persists = false
			helper.entity:SetCanSleep(false)
			helper:AddTag("CLASSIFIED")
			helper:AddTag("NOBLOCK")
			helper:AddTag("NOCLICK")

			helper.entity:AddTransform()
			helper.entity:AddMiniMapEntity()

			helper.entity:SetParent(inst.entity)
			helper.MiniMapEntity:SetCanUseCache(persistent)
			helper.MiniMapEntity:SetDrawOverFogOfWar(persistent)

			inst.emi_mapicon = helper
			UpdateIcon()
			RefreshVisibility()

			if inst.emi_mapicon_refresh_task == nil then
				-- safety net for held-state changes the event listeners miss
				inst.emi_mapicon_refresh_task = inst:DoPeriodicTask(1, RefreshVisibility)
			end
		end)

		inst:ListenForEvent("imagechange", UpdateIcon)
		inst:ListenForEvent("onputininventory", RefreshVisibility)
		inst:ListenForEvent("ondropped", RefreshVisibility)
		inst:ListenForEvent("enterlimbo", RefreshVisibility)
		inst:ListenForEvent("exitlimbo", RefreshVisibility)
		inst:ListenForEvent("onremove", RemoveHelper)
	end)
end

local function OverrideExistingMapIcon(prefab)
	AddPrefabPostInit(prefab, function(inst)
		if GLOBAL.TheNet ~= nil and GLOBAL.TheNet:IsDedicated() then
			return
		end

		local function ApplyOverride()
			if inst.MiniMapEntity == nil then
				return
			end

			local iconname, atlas = GetCustomIconOverride(prefab)
			if iconname == nil then
				iconname = prefab .. ".tex"
				atlas = "images/icons.xml"
			end

			atlas = atlas or "images/icons.xml"
			RegisterMinimapAtlas(atlas)
			inst.MiniMapEntity:SetIcon(iconname)
		end

		if inst.MiniMapEntity ~= nil then
			ApplyOverride()
		else
			inst:DoTaskInTime(0, ApplyOverride)
		end
	end)
end

local function AddIconsMap(group, persistent)
	for entities_count = 1, #group do
		local prefab = group[entities_count]
		if ShouldAddIcon(prefab) then
			AddMapIcon(prefab, persistent)
		end
	end
end

-- monkeybarrel has no config option on purpose (ShouldAddIcon defaults to true),
-- so its custom icon stays forced; everything else respects its Show/Hide setting.
for prefab, _ in pairs(PREFABS_WITH_EXISTING_MAP_ICONS) do
	if ShouldAddIcon(prefab) then
		OverrideExistingMapIcon(prefab)
	end
end

for _, group_name in ipairs(PREFAB_GROUP_ORDER) do
	local group = PREFAB_GROUPS[group_name]
	if group ~= nil then
		local persistent = persistent_icons
		if CREATURE_GROUPS[group_name] then
			persistent = creature_persistent_icons
		end
		AddIconsMap(group, persistent)
	end
end
