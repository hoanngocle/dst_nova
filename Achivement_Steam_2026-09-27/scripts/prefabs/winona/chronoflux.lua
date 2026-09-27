local assets =
{
	Asset("ANIM", "anim/porkalypse_totem.zip"),
	Asset("ATLAS", "images/inventoryimages/chronoflux.xml"),
}

local prefabs =
{
	"collapse_small",
}

local SEASON_COOLDOWN = (chasni_getitemconfig("chronoflux", "SCD") or 30) * TUNING.TOTAL_DAY_TIME
local PHASE_COOLDOWN = (chasni_getitemconfig("chronoflux", "PCD") or 3) * TUNING.TOTAL_DAY_TIME
local MOONEYELIST = { "redmooneye", "bluemooneye", "greenmooneye", "yellowmooneye", "orangemooneye", "purplemooneye" }
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
	inst:Remove()
end

local function abletoaccepttest(inst, item)
	if chasni_findprefab(MOONEYELIST, item.prefab) and not inst.components.timer:TimerExists("cooldown") then
		return true
	end
end

local function onsave(inst, data)
	data.ison = inst.ison
end

local function onload(inst, data)
	if data and data.ison == true then
		inst.ison = true
		inst.AnimState:PlayAnimation("idle_loop", true)
	else
		inst.ison = false
		inst.AnimState:PlayAnimation("idle_on", false)
	end
end

local function ontimerdone(inst)
	inst.ison = true
	inst.AnimState:PlayAnimation("idle_pre", false)
	inst.AnimState:PushAnimation("idle_loop", true)
end

local function changeseason(inst, season)
	TheWorld:PushEvent("ms_setseason", season)
	TheWorld:PushEvent("ms_advanceseason")
	TheWorld:PushEvent("ms_advanceseason")
	inst.ison = false
	inst.components.timer:StartTimer("cooldown", SEASON_COOLDOWN)
	inst.AnimState:PlayAnimation("idle_pst", false)
	inst.AnimState:PushAnimation("idle_on", false)
end

local function changephase(inst, phase)
	TheWorld:PushEvent("ms_setphase", phase)
	inst.ison = false
	inst.components.timer:StartTimer("cooldown", PHASE_COOLDOWN)
	inst.AnimState:PlayAnimation("idle_pst", false)
	inst.AnimState:PushAnimation("idle_on", false)
end

local function ongivenitem(inst, giver, item)
	local pfb = item.prefab
	local season, phase
	if pfb == "redmooneye" then
		season = "summer"
	elseif pfb == "bluemooneye" then
		season = "winter"
	elseif pfb == "greenmooneye" then
		season = "spring"
	elseif pfb == "yellowmooneye" then
		phase = "day"
	elseif pfb == "orangemooneye" then
		season = "autumn"
	elseif pfb == "purplemooneye" then
		phase = "night"
	end
	if season then
		changeseason(inst, season)
	elseif phase then
		changephase(inst, phase)
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.AnimState:SetBank("totem")
	inst.AnimState:SetBuild("porkalypse_totem")
	inst.AnimState:PlayAnimation("idle_loop", true)

	inst:AddTag("structure")
	inst:AddTag("trader")

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

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst.ison = true
	inst.OnSave = onsave
	inst.OnLoad = onload

	return inst
end

return Prefab("chronoflux", fn, assets, prefabs),
MakePlacer("chronoflux_placer", "totem", "porkalypse_totem", "idle_off")