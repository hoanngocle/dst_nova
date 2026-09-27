local assets =
{
	Asset("ANIM", "anim/tree_rainforest_purple_build.zip"),
	Asset("ANIM", "anim/tree_rainforest_short.zip"),
	Asset("ANIM", "anim/tree_rainforest_normal.zip"),
	Asset("ANIM", "anim/tree_rainforest_tall.zip"),
	Asset("ANIM", "anim/tree_jungle_tall.zip"),
	Asset("ANIM", "anim/tree_rainforest_web_purple_build.zip"),
}

local prefabs =
{
	"log",
	"charcoal",
	"silk",
	"splash_spiderweb"
}

local WORK_COUNT = 15
local SHAVE_PREFAB = "silk"
local SHAVE_COUNT = chasni_getitemconfig("chasni_cocoontree", "SILK") or 5
local COCOONTREE_GROW_TIME =
{
	base = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("chasni_cocoontree", "GROW") or 4.5),
	random = 0.5 * TUNING.TOTAL_DAY_TIME,
}
local burnt_highlight_override = {.5,.5,.5}

local types =
{
	normal = {
		build = "tree_rainforest_purple_build",
		bank = "rainforesttree",
		prefab_name = "chasni_cocoontree",
		fx = "purple_leaves",
		chopfx = "purple_leaves_chop",
		loot = {"log", "log", "log"},
	},
	cocoon = {
		build = "tree_rainforest_web_purple_build",
		bank = "jungletree",
		prefab_name = "chasni_cocoontree",
		fx = "purple_leaves",
		chopfx = "purple_leaves_chop",
		loot = {"log", "log", "log", "silk", "silk"},
	},
}

local anims = {
	idle 			= "idle_tall",
	sway1 			= "sway1_loop_tall",
	sway2 			= "sway2_loop_tall",
	chop 			= "chop_tall",
	fallleft 		= "fallleft_tall",
	fallright 		= "fallright_tall",
	stump 			= "stump_tall",
	burning 		= "burning_loop_tall",
	burnt 			= "burnt_tall",
	chop_burnt		= "chop_burnt_tall",
	idle_chop_burnt = "idle_chop_burnt_tall",
	blown1 			= "blown_loop_tall1",
	blown2 			= "blown_loop_tall2",
	blown_pre 		= "blown_pre_tall",
	blown_pst 		= "blown_pst_tall"
}

local function GetType(inst)
	return types[inst.type] or types.normal
end

local function PushSway(inst)
	if math.random() > .5 then
		inst.AnimState:PushAnimation(anims.sway1, true)
	else
		inst.AnimState:PushAnimation(anims.sway2, true)
	end
end

local function Sway(inst)
	if math.random() > .5 then
		inst.AnimState:PlayAnimation(anims.sway1, true)
	else
		inst.AnimState:PlayAnimation(anims.sway2, true)
	end
	inst.AnimState:SetTime(math.random()*2)
end

local function dig_up_stump(inst, chopper)
	inst.components.lootdropper:SpawnLootPrefab("log")
	inst.components.lootdropper:SpawnLootPrefab("silk")
	inst.components.lootdropper:SpawnLootPrefab("silk")
	inst:Remove()
end

local function chop_down_burnt_tree(inst, chopper)
	inst:RemoveComponent("workable")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
	inst.AnimState:PlayAnimation(anims.chop_burnt)
	RemovePhysicsColliders(inst)
	inst.components.lootdropper:SpawnLootPrefab("charcoal")
	inst.components.lootdropper:DropLoot()
	if inst.burnttask then
		inst.burnttask:Cancel()
		inst.burnttask = nil
	end
	inst:ListenForEvent("animover", inst.Remove)
end

local function SetBurnt(inst)
	local function changes()
		if inst.components.burnable then
			inst.components.burnable:Extinguish()
		end
		inst:RemoveComponent("burnable")
		inst:RemoveComponent("propagator")
		inst:RemoveComponent("growable")
		inst:RemoveTag("shelter")
		inst:RemoveTag("dragonflybait_lowprio")
		inst:RemoveTag("fire")
		inst:RemoveTag("gustable")

		inst.components.lootdropper:SetLoot({})

		if inst.components.workable then
			inst.components.workable:SetWorkLeft(1)
			inst.components.workable:SetOnWorkCallback(nil)
			inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
		end
	end

	inst:DoTaskInTime(0.5, changes)
	inst.highlight_override = burnt_highlight_override
	inst.AnimState:PlayAnimation(anims.burnt, true)
	inst:AddTag("burnt")
end

local function tree_burnt(inst)
	SetBurnt(inst)
	inst.burnttask = inst:DoTaskInTime(10, function()
		local pt = Vector3(inst.Transform:GetWorldPosition())
		if math.random(0, 1) == 1 then
			pt = pt + TheCamera:GetRightVec()
		else
			pt = pt - TheCamera:GetRightVec()
		end
		inst.components.lootdropper:DropLoot(pt)
		inst.burnttask = nil
	end)
end

local function DoTransform(inst, build)
	if not inst:HasTag("burnt") then
		inst.type = build
		inst.AnimState:SetBuild(GetType(inst).build)
		inst.AnimState:SetBank(GetType(inst).bank)
	end
end

local function SetStump(inst)
	inst:RemoveComponent("burnable")
	MakeLargeBurnable(inst)
	inst:RemoveComponent("propagator")
	MakeLargePropagator(inst)

	inst:RemoveTag("shelter")
	inst:RemoveTag("cattoyairborne")
	inst:AddTag("stump")

	RemovePhysicsColliders(inst)

	inst:RemoveComponent("workable")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(dig_up_stump)
	inst.components.workable:SetWorkLeft(1)

	if inst.components.growable then
		inst.components.growable:StopGrowing()
	end
end

local function spawnFX(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	chasni_spawnprefab("splash_spiderweb", x, y + 5, z)
end

local function SetNormal(inst)
	if inst.components.workable then
		inst.components.workable:SetWorkLeft(WORK_COUNT)
	end
	DoTransform(inst, "normal")
	inst.components.lootdropper:SetLoot(GetType(inst).loot)
	inst.components.growable:StartGrowing()
	Sway(inst)
end

local function ToNormal(inst)
	spawnFX(inst)
	SetNormal(inst)
end

local function SetCocoon(inst)
	if inst.components.workable then
		inst.components.workable:SetWorkLeft(WORK_COUNT)
	end
	DoTransform(inst, "cocoon")
	inst.components.lootdropper:SetLoot(GetType(inst).loot)
	Sway(inst)
end

local function ToCocoon(inst)
	spawnFX(inst)
	SetCocoon(inst)
end

local function inspect_tree(inst)
	if inst:HasTag("burnt") then
		return "BURNT"
	elseif inst:HasTag("stump") then
		return "CHOPPED"
	end
end

local GROWTH_STAGES =
{
	{name="normal", time = function(inst) return GetRandomWithVariance(COCOONTREE_GROW_TIME.base, COCOONTREE_GROW_TIME.random) end, fn = function(inst) SetNormal(inst) end,  growfn = function(inst) ToNormal(inst) end },
	{name="cocoon", time = function(inst) return GetRandomWithVariance(COCOONTREE_GROW_TIME.base, COCOONTREE_GROW_TIME.random) end, fn = function(inst) SetCocoon(inst) end,  growfn = function(inst) ToCocoon(inst) end },
}

local function chop_tree(inst, chopper, chops)
	if not (chopper and chopper:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound(chopper and chopper:HasTag("beaver") and
				"dontstarve/characters/woodie/beaver_chop_tree" or 
				"dontstarve/wilson/use_axe_tree"
		)
	end

	inst.AnimState:PlayAnimation(anims.chop)
	inst.AnimState:PushAnimation(anims.sway1, true)
end

local function chop_down_tree(inst, chopper)
	local pt = Vector3(inst.Transform:GetWorldPosition())
	local hispos = Vector3(chopper.Transform:GetWorldPosition())
	local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
	if he_right then
		inst.AnimState:PlayAnimation(anims.fallleft)
		inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
	else
		inst.AnimState:PlayAnimation(anims.fallright)
		inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
	end

	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	inst:DoTaskInTime(.4, function() ShakeAllCameras(CAMERASHAKE.FULL, .25, .03, .5, inst, 6) end)
	inst.AnimState:PushAnimation(anims.stump)

	SetStump(inst)
end

local function can_shave(inst, shaver, shave_item)
	return inst.components.growable and inst.components.growable:GetStage() == 2 and not inst:HasTag("burnt") and not inst:HasTag("fire") and not inst:HasTag("stump")
end

local function on_shaved(inst, shaver, shave_item)
	inst.components.growable:SetStage(1)
	ToNormal(inst)
end

local function handler_regrowcocoon(inst)
	if inst.AnimState:IsCurrentAnimation(anims.sway1) or inst.AnimState:IsCurrentAnimation(anims.sway2) then
		inst.components.growable:SetStage(2)
		ToCocoon(inst)
		inst:RemoveEventCallback("animover", handler_regrowcocoon)
	end
end

local function handler_growfromseed(inst)
	inst.components.growable:SetStage(1)
	inst.AnimState:SetBuild(GetType(inst).build)
	inst.AnimState:SetBank(GetType(inst).bank)
	inst.AnimState:PlayAnimation("grow_seed_to_short")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	inst.AnimState:PushAnimation("grow_short_to_normal")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	inst.AnimState:PushAnimation("grow_normal_to_tall")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	PushSway(inst)
	inst:ListenForEvent("animover", handler_regrowcocoon)
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or inst:HasTag("fire") then
		data.burnt = true
	end

	if inst:HasTag("stump") then
		data.stump = true
	end

	if inst.type then
		data.type = inst.type
	end
end

local function onload(inst, data)
	if data then
		inst.type = data.type and types[data.type] and data.type or "normal"
		DoTransform(inst, data.type)

		if data.burnt then
			inst:AddTag("fire")
		end

		if data.stump then
			SetStump(inst)
		end
	end
end

local function OnEntitySleep(inst)
	local fire = false
	if inst:HasTag("fire") then
		fire = true
	end
	inst:RemoveComponent("burnable")
	inst:RemoveComponent("propagator")
	inst:RemoveComponent("inspectable")
	if fire then
		inst:AddTag("fire")
	end
end

local function OnEntityWake(inst)
	if not inst:HasTag("burnt") and not inst:HasTag("fire") then
		if not inst.components.burnable then
			if inst:HasTag("stump") then
				MakeLargeBurnable(inst)
			else
				MakeLargeBurnable(inst)
				inst.components.burnable:SetFXLevel(5)
				inst.components.burnable:SetOnBurntFn(tree_burnt)
			end
		end

		if not inst.components.propagator then
			if inst:HasTag("stump") then
				MakeLargePropagator(inst)
			else
				MakeLargePropagator(inst)
				inst.components.burnable:SetOnIgniteFn(DefaultIgniteFn)
			end
		end
	elseif not inst:HasTag("burnt") and inst:HasTag("fire") then
		SetBurnt(inst, true)
	end

	if not inst.components.inspectable then
		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree
	end
end

local function makefn(type, stage, data)
	local function fn()
		local l_stage = stage
		if l_stage == 0 then
			l_stage = math.random(1, 2)
		end

		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, .25)

		inst.Transform:SetScale(0.6, 0.6, 0.6)

		inst:AddTag("tree")
		inst:AddTag("workable")
		inst:AddTag("shelter")
		inst:AddTag("plant")

		inst.type = type
		local color = 0.5 + math.random() * 0.5
		inst.AnimState:SetBuild(GetType(inst).build)
		inst.AnimState:SetBank(GetType(inst).bank)
		inst.AnimState:SetMultColour(color, color, color, 1)

		inst.entity:SetPristine()
		if not TheWorld.ismastersim then
			return inst
		end

		-------------------
		MakeLargeBurnable(inst)
		inst.components.burnable:SetFXLevel(3)
		inst.components.burnable:SetOnBurntFn(tree_burnt)
		inst.components.burnable:SetOnIgniteFn(DefaultIgniteFn)

		MakeLargePropagator(inst)

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetOnWorkCallback(chop_tree)
		inst.components.workable:SetOnFinishCallback(chop_down_tree)
		inst.components.workable:SetWorkLeft(WORK_COUNT)

		inst:AddComponent("shaveable")
		inst.components.shaveable:SetPrize(SHAVE_PREFAB, SHAVE_COUNT)
		inst.components.shaveable.can_shave_test = can_shave
		inst.components.shaveable.on_shaved = on_shaved

		-------------------
		inst:AddComponent("lootdropper")
		---------------------
		inst:AddComponent("growable")
		inst.components.growable.stages = GROWTH_STAGES
		inst.components.growable:SetStage(l_stage)
		inst.components.growable.loopstages = false
		inst.components.growable.springgrowth = true
		inst.components.growable:StartGrowing()

		inst.growfromseed = handler_growfromseed

		inst.AnimState:SetTime(math.random()*2)

		inst.OnSave = onsave
		inst.OnLoad = onload

		MakeSnowCovered(inst, .01)
		---------------------

		inst:SetPrefabName(GetType(inst).prefab_name)

		if data == "burnt"  then
			SetBurnt(inst)
		end
		if data == "stump"  then
			inst.AnimState:PlayAnimation(anims.stump)
			SetStump(inst)
		end

		inst.OnEntitySleep = OnEntitySleep
		inst.OnEntityWake = OnEntityWake
		if type == "cocoon" then
			handler_growfromseed(inst)
		end

		return inst
	end
	return fn
end

local function tree(name, build, stage, data)
	return Prefab("chasni_cocoontree"..name, makefn(build, stage, data), assets, prefabs)
end

return
tree("", "normal", 0),
tree("_normal", "normal", 1),
tree("_cocoon", "cocoon", 2),
tree("_burnt", "normal", 0, "burnt"),
tree("_stump", "normal", 0, "stump")
