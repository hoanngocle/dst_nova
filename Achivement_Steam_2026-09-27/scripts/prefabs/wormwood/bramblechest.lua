local assets =
{
	Asset("ANIM", "anim/bramblechest.zip"),
	Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),

	Asset("IMAGE", "images/inventoryimages/bramblechest.tex"),
	Asset("ATLAS", "images/inventoryimages/bramblechest.xml"),
}

local prefabs =
{
	"bramblefx_new",
}

local DEFAULT_PERSERVE = 1
local EXPERTWORM1_PERSERVE = -1.2
local function SpawnBramble(inst)
	local p = inst:GetPosition()
	local bramble = chasni_spawnprefab("bramblefx_new", p.x, p.y, p.z)
	bramble.knockback = true
end

local function OnOpen(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("open")
		inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_roottrunk/open")
		SpawnBramble(inst)
	end
end

local function OnClose(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("close")
		inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_roottrunk/close")
		SpawnBramble(inst)
	end
end

local function OnHammered(inst, worker)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end

	inst.components.lootdropper:DropLoot()

	if inst.components.container then
		inst.components.container:DropEverything()
	end

	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function OnHit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("closed", true)

		SpawnBramble(inst)
		if inst.components.container then
			inst.components.container:DropEverything()
			inst.components.container:Close()
		end
	end
end

local function OnBuilt(inst)
	inst.AnimState:PlayAnimation("close")
	inst.AnimState:PushAnimation("closed", true)
	inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_roottrunk/place")
end

local function OnSave(inst, data)
	if inst:HasTag("burnt") or inst:HasTag("fire") then
		data.burnt = true
	end
end

local function OnLoad(inst, data)
	if data and data.burnt then
		inst.components.burnable.onburnt(inst)
	end
end

local function expertworm1nearby(pos)
	local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 20)
	for k,v in pairs(ents) do
		if chasni_hastag2(v, "expertworm1")  then
			return true
		end
	end
	return false
end
local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("roottrunk")
	inst.AnimState:SetBuild("bramblechest")
	inst.AnimState:PlayAnimation("closed", true)

	inst:AddTag("structure")
	inst:AddTag("chest")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("bramblechest")
	inst.components.container.onopenfn = OnOpen
	inst.components.container.onclosefn = OnClose
	inst.components.container.skipclosesnd = true
	inst.components.container.skipopensnd = true
	inst.components.container:EnableInfiniteStackSize(true)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)
	inst.components.workable:SetWorkLeft(3)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
	inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		if haunter and haunter:HasTag("playerghost") and chasni_hastag2(haunter, "expertworm1") then
			return true
		end
		return false
	end)

	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(function(inst, item)
		local pos = Vector3(inst.Transform:GetWorldPosition())
		return expertworm1nearby(pos) and EXPERTWORM1_PERSERVE or DEFAULT_PERSERVE
	end)

	inst:DoPeriodicTask(10, function()
		local pos = Vector3(inst.Transform:GetWorldPosition())
		if expertworm1nearby(pos) then
			local items = inst.components.container:GetAllItems()
			for i, item in ipairs(items) do
				if item and not item:HasTag("charges_percentage") then
					if item.components.finiteuses then
						item.components.finiteuses:Repair(1)
					end
					if item.components.armor then
						item.components.armor:Repair(50)
					end
					if item.components.fueled then
						item.components.fueled:DoDelta(1)
					end
				end
			end
		end
	end)

	MakeMediumBurnable(inst, nil, nil, true)
	MakeLargePropagator(inst)

	inst:ListenForEvent("onbuilt", OnBuilt)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("bramblechest", fn, assets, prefabs),
	MakePlacer("bramblechest_placer", "roottrunk", "bramblechest", "closed")