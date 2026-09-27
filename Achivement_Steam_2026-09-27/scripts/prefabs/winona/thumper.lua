local assets =
{
	Asset("ANIM", "anim/wagstaff_thumper.zip"),

	Asset("ATLAS", "images/inventoryimages/thumper.xml"),
	Asset("IMAGE", "images/inventoryimages/thumper.tex"),
}

local DAMAGE = chasni_getitemconfig("thumper", "DMG") or 100
local function TurnOn(inst)
	inst.sg:GoToState("raise")
	local pos = inst:GetPosition()
	inst._activeplayer = FindClosestPlayerInRange(pos.x, pos.y, pos.z, 5, true)
end

local function GetStatus(inst, viewer)
	if inst.on then
		return "ON"
	else
		return "OFF"
	end
end

local function OnBuilt(inst)
	inst.sg:GoToState("place")
end

local function OnHammered(inst, worker)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
	inst:Remove()
end

local function OnHit(inst, dist)
	if inst.sg:HasStateTag("idle") then
		inst.sg:GoToState("hit_low")
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.entity:AddMiniMapEntity()
	inst.MiniMapEntity:SetPriority(5)
	inst.MiniMapEntity:SetIcon("thumper.tex")

	inst:AddTag("groundpoundimmune")
	inst:AddTag("metal")
	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBank("wagstaff_thumper")
	inst.AnimState:SetBuild("wagstaff_thumper")
	inst.AnimState:PlayAnimation("idle")
	inst.on = false

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.cooldowntime = 1

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)

	inst:AddComponent("groundpounder")
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.damageRings = 3
	inst.components.groundpounder.destructionRings = 3
	inst.components.groundpounder.numRings = 3
	inst.components.groundpounder.groundpounddamagemult = 1

	inst:AddComponent("combat")
	inst.components.combat.defaultdamage = DAMAGE
	inst.components.combat:SetRange(12, 12)

	MakeSnowCovered(inst, .01)

	inst:SetStateGraph("SGCZthumper")
	inst:ListenForEvent("onbuilt", OnBuilt)

	if _G.WORKXP == true then
		inst:ListenForEvent("finishedwork",	function()
			if _G.WORKXP ~= true then return end
			if inst._activeplayer and inst._activeplayer.components.levelsystem then
				local xpmult = 8
				if inst._activeplayer.components.allachivcoin and inst._activeplayer.components.allachivcoin.expertwinona1 then
					xpmult = 16
				end
				inst._activeplayer.components.levelsystem:xpDoDelta(xpmult, inst._activeplayer)
			end
		end)
	end
	if _G.KILLXP == true then
		inst:ListenForEvent("killed", function(killer, data)
			if _G.KILLXP ~= true then return end
			if inst._activeplayer and inst._activeplayer.components.levelsystem then
				local victim = data.victim
				if victim and victim.components.health and inst._activeplayer:HasTag("player") then
					chasni_checkkilllevel(victim)
				end
			end
		end)
	end

	return inst
end

return Prefab("chasni_thumper", fn, assets), 
MakePlacer("chasni_thumper_placer", "wagstaff_thumper", "wagstaff_thumper", "idle")