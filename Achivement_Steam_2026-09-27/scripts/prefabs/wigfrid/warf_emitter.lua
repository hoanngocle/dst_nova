local assets =
{
	Asset("ANIM", "anim/warf_emitter.zip"),
	Asset("ATLAS", "images/inventoryimages/warf_emitter.xml"),
	Asset("IMAGE", "images/inventoryimages/warf_emitter.tex"),
}

local prefabs =
{
	"collapse_small",
}

local BASE_SPAWN_INTERVAL = 2
local DURATION = 60
local COOLDOWN = (chasni_getitemconfig("warf_emitter", "CD") or 20) * TUNING.TOTAL_DAY_TIME
local HEALTH = chasni_getitemconfig("warf_emitter", "CD") or 500
local SPAWN_DIST = 25
local BAITLIST = {
	chasni_wargfant_tooth = {
		icehound = 0.35,
		firehound = 0.35,
		warglet = 0.15,
		warg = 0.1,
		chasni_wargfant = 0.05,
	},
	chasni_palmtreeguard_log = {
		leif = 0.35,
		leif_sparse = 0.35,
		chasni_treeguard = 0.15,
		chasni_mandrakeman = 0.15,
	},
	chasni_cocoontreeseed = {
		spider_warrior = 0.35,
		spider_healer = 0.35,
		chasni_spider_poison = 0.2,
		chasni_spidermonkey = 0.1,
	},
	chasni_grub_skull = {
		slurtle = 0.35,
		rocky = 0.35,
		snurtle = 0.2,
		chasni_giantgrub = 0.1,
	},
	chasni_pangolden_scale = {
		koalefant_summer = 0.5,
		koalefant_winter = 0.2,
		spat = 0.15,
		chasni_pangolden = 0.15,
	},
	gears = {
		knight = 0.4,
		bishop = 0.3,
		rook = 0.3,
	},
	pigskin = {
		pigman = 0.4,
		moonpig = 0.3,
		pigguard = 0.3,
	},
}
local BAITLIST_WATER = {
	chasni_crocodog_skin = {
		chasni_crocodog = 0.4,
		chasni_poisoncrocodog = 0.3,
		chasni_watercrocodog = 0.3,
	},
	chasni_hippo_skin = {
		otter = 0.5,
		grassgator = 0.35,
		chasni_hippopotamoose = 0.15,
	},
	chasni_gas = {
		shark = 0.4,
		gnarwail = 0.4,
		chasni_waterbishop = 0.2,
	},
	mosquitosack = {
		mosquito = 0.3,
		beeguard = 0.3,
		chasni_blackfly = 0.2,
		chasni_mosquito_poison = 0.2,
	}
}
local REWARDLIST = {
	chasni_wargfant_tooth = 5,
	chasni_palmtreeguard_log = 3,
	chasni_cocoontreeseed = 4,
	chasni_grub_skull = 3,
	chasni_pangolden_scale = 2,
	gears = 1,
	pigskin = 0,
	chasni_crocodog_skin = 2,
	chasni_hippo_skin = 4,
	chasni_gas = 5,
	mosquitosack = 1,
}

local function keeptargetfn()
	return false
end

local function ondone(inst)
	inst:AddTag("noattack")
	if inst._lightfx then
		inst._lightfx:KillFX()
		inst._lightfx = nil
	end
	inst._giveachievement = false
	inst.AnimState:PlayAnimation("off", true)
	if inst.spawningtask then
		inst.spawningtask:Cancel()
		inst.spawningtask = nil
	end
	if inst.finishtask then
		inst.finishtask:Cancel()
		inst.finishtask = nil
	end
	for i, v in ipairs(inst._spawnedenemies) do
		v:RemoveTag("epicxphp")
		v:RemoveTag("epicxpdmg")
	end
	inst._spawnedenemies = {}
	inst._participant = {}
	inst.components.health:SetPercent(1)
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
	ondone(inst)
	inst:Remove()
end

local function onwin(inst)
	if inst._giveachievement then
		local winningpoint = -math.huge
		local winningplayer
		for _, entry in pairs(inst._participant) do
			if entry.point and entry.point > winningpoint then
				winningpoint = entry.point
				winningplayer = entry.player
			end
		end

		if _G.NOAWARDS ~= true and winningplayer then
			if winningpoint > 10 and winningplayer.components.allachivcoin then
				SpawnPrefab("seffc").entity:SetParent(winningplayer.entity)
				winningplayer.components.allachivcoin:coinDoDelta(1)
				TheNet:Announce(winningplayer:GetDisplayName().." là MVP của Trận Chiến Sóng Warf và nhận "..inst._coinamount.." điểm Thành Tựu")
			else
				TheNet:Announce("Không ai là MVP của Trận Chiến Sóng Warf! Không có điểm Thành Tựu nào được trao.")
			end
		end
	end
	ondone(inst)
end

local function abletoaccepttest(inst, item, giver)
	if inst.components.timer:TimerExists("cooldown") then
		chasni_retalk(giver, "ANNOUNCE_CHASNI_WARF_EMITTER_COOLDOWN")
		return false, "WARF_EMITTER_COOLDOWN"
	end

	local pt = inst:GetPosition()
	local boat = TheWorld.Map:GetPlatformAtPoint(pt.x,pt.z)
	if boat and boat:HasTag("boat") then
		if BAITLIST_WATER[item.prefab] then
			return true
		end
	else
		if BAITLIST[item.prefab] then
			return true
		end
	end

	chasni_retalk(giver, "ANNOUNCE_CHASNI_NOT_EMITTER_ITEM")
	return false, "NOT_EMITTER_ITEM"
end

local function ontimerdone(inst)
	inst.AnimState:PlayAnimation("on_pst", true)
end

local function spawnEnemy(inst, spawnedprefabs)
	local pt = inst:GetPosition()
	--local spawn_dist = inst._bait == "chasni_gas" and 12 or SPAWN_DIST
	local spawn_pt = inst._onboat and chasni_getspawnpointwater(pt, SPAWN_DIST) or chasni_getspawnpoint(pt, SPAWN_DIST)
	if inst._spawnedenemies then
		for _, enemy in ipairs(inst._spawnedenemies) do
			if enemy.components.combat then
				enemy.components.combat:SetTarget(inst)
			end
		end
	end
	if spawn_pt then
		local spawnedprefab = weighted_random_choice(spawnedprefabs)
		local enemy = SpawnPrefab(spawnedprefab)
		if enemy then
			enemy.Physics:Teleport(spawn_pt:Get())
			enemy:FacePoint(pt:Get())
			if enemy.components.combat then
				enemy.components.combat:SetTarget(inst)
				inst:ListenForEvent("death", function(_inst, data)
					if data and data.afflicter and data.afflicter:HasTag("player") then
						if not inst._participant[data.afflicter.userid] then
							inst._participant[data.afflicter.userid] = {}
							inst._participant[data.afflicter.userid].player = data.afflicter
							inst._participant[data.afflicter.userid].point = 0
						end
						inst._participant[data.afflicter.userid].point = inst._participant[data.afflicter.userid].point + 1
					end
				end, enemy)
				table.insert(inst._spawnedenemies, enemy)
			end
			if inst._giveachievement then
				if enemy.components.combat then
					local old_damage = enemy.components.combat.defaultdamage
					enemy.components.combat:SetDefaultDamage(old_damage + (old_damage * TheWorld.state.cycles/50000))
					enemy:AddTag("epicxpdmg")
				end
				if enemy.components.health then
					local old_health = enemy.components.health:GetMaxWithPenalty()
					enemy.components.health:SetMaxHealth(old_health + (old_health * TheWorld.state.cycles/5000))
					enemy:AddTag("epicxphp")
				end
			end
		end
	end
end

local function spawnWave(inst, spawnedprefabs, playercount)
	inst.AnimState:PlayAnimation("on", true)
	local spawninterval = BASE_SPAWN_INTERVAL - (1 - (1 / playercount))
	inst.spawningtask = inst:DoPeriodicTask(spawninterval, function() spawnEnemy(inst, spawnedprefabs) end)
	inst.finishtask = inst:DoTaskInTime(inst._giveachievement and DURATION * 2 or DURATION, onwin)
end

local function ongivenitem(inst, giver, item)
	local pt = inst:GetPosition()
	local boat = TheWorld.Map:GetPlatformAtPoint(pt.x,pt.z)
	inst._onboat = boat and boat:HasTag("boat")
	local spawnedprefabs = inst._onboat and BAITLIST_WATER[item.prefab] or BAITLIST[item.prefab]
	if spawnedprefabs then
		local x, y, z = inst.Transform:GetWorldPosition()
		local range = 20
		local players = TheSim:FindEntities(x, y, z, range, { "player" })
		inst._coinamount = REWARDLIST[item.prefab] or (inst._giveachievement and 1) or 0
		inst._giveachievement = giver.prefab == "wathgrithr" and #players >= 2
		inst._bait = item.prefab
		spawnWave(inst, spawnedprefabs, #players)
		inst.components.timer:StartTimer("cooldown", COOLDOWN)
		inst:RemoveTag("noattack")
		inst._lightfx = chasni_spawnprefab("positronbeam_back", x, y + 3, z)
	end
end

local function onload(inst, data)
	if inst.components.timer:TimerExists("cooldown") then
		inst.AnimState:PlayAnimation("off", true)
	else
		inst.AnimState:PlayAnimation("on_pst", true)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.AnimState:SetBank("warf_emitter")
	inst.AnimState:SetBuild("warf_emitter")
	inst.AnimState:PlayAnimation("on_pst", true)
	inst.Transform:SetScale(2.5 ,2.5 ,2.5)

	inst:AddTag("structure")
	inst:AddTag("trader")
	inst:AddTag("noattack")
	inst:AddTag("warf_emitter")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
	inst:AddComponent("inspectable")

	inst:AddComponent("trader")
	inst.components.trader:SetAbleToAcceptTest(abletoaccepttest)
	inst.components.trader.acceptnontradable = true
	inst.components.trader.deleteitemonaccept = true
	inst.components.trader.onaccept = ongivenitem

	inst:AddComponent("combat")
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(HEALTH)
	inst.components.health:SetMinHealth(1)
	inst.components.health:SetMaxDamageTakenPerHit(50)

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst:ListenForEvent("minhealth", onhammered)

	inst.ison = true
	inst._spawnedenemies = {}
	inst._participant = {}
	inst.OnLoad = onload

	return inst
end

return Prefab("warf_emitter", fn, assets, prefabs),
MakePlacer("warf_emitter_placer", "warf_emitter", "warf_emitter", "on_pst", nil, nil, nil, 2.5)