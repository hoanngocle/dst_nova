local assets =
{
	Asset("ANIM", "anim/rock_basalt.zip"),
}

SetSharedLootTable("chasni_basalt", { 
	{"rocks",  0.1},
	{"flint",  0.05},
})

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBank("rock_basalt")
	inst.AnimState:SetBuild("rock_basalt")
	inst.AnimState:PlayAnimation("full")
	local color = 0.5 + math.random() * 0.5
	inst.AnimState:SetMultColour(color, color, color, 1)

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("chasni_basalt")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	inst.components.workable:SetOnWorkCallback(function(inst, worker, workleft)
		if workleft <= 0 then
			local pt = inst:GetPosition()
			SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
			inst.components.lootdropper:DropLoot(pt)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
			local fx = SpawnPrefab("collapse_small")
			fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

			inst:Remove()
		else
			if workleft < TUNING.ROCKS_MINE*(1/3) then
				inst.AnimState:PlayAnimation("low")
			elseif workleft < TUNING.ROCKS_MINE*(2/3) then
				inst.AnimState:PlayAnimation("med")
			else
				inst.AnimState:PlayAnimation("full")
			end
		end
	end)

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "ROCK"

	MakeSnowCovered(inst, .01)
	return inst
end

return Prefab("chasni_basalt", fn, assets)