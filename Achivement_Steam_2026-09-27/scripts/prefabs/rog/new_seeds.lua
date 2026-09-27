local seeds = {}

local function createseed(name, bank, build, anim, treeprefab, plantedbank, plantedbuild, plantedanim)
	local assets =
	{
		Asset("ANIM", "anim/"..build..".zip"),
		Asset("ATLAS", "images/inventoryimages/"..build..".xml"),
	}

	local prefabs =
	{
		treeprefab,
	}

	local function ondeploy(inst, pt, deployer)
		inst = inst.components.stackable:Get()
		inst.Physics:Teleport(pt:Get())
		local tree = SpawnPrefab(treeprefab)
		tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
		tree.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
		inst:Remove()
	end

	plantedbank = plantedbank or bank
	plantedbuild = plantedbuild or build
	plantedanim = plantedanim or anim

	local function fn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)
		MakeInventoryFloatable(inst, "small", 0.05, 0.9)

		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation("idle")

		inst:AddTag("deployedplant")
		inst:AddTag("cattoy")
		inst:AddTag("treeseed")
		inst:AddTag("monkeyqueenbribe")

		inst.entity:SetPristine()
		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("tradable")
		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("fuel")
		inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = build
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..build..".xml"

		inst:AddComponent("deployable")
		inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
		inst.components.deployable.ondeploy = ondeploy

		inst:AddComponent("forcecompostable")
		inst.components.forcecompostable.brown = true

		MakeHauntableLaunchAndIgnite(inst)
		MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
		MakeSmallPropagator(inst)

		return inst
	end

	table.insert(seeds, Prefab(name, fn, assets, prefabs))
	table.insert(seeds, MakePlacer(name.."_placer", plantedbank, plantedbuild, plantedanim))
end

createseed("chasni_cocoontreeseed", "cocoontreeseed", "cocoontreeseed", "idle_planted", "chasni_cocoontree_cocoon")
createseed("chasni_snapdragon_seed", "snapdragon_seed", "snapdragon_seed", "idle_planted", "chasni_snapdragon_flower", "snapdragon_flower", "snapdragon_flower", "idle")

return unpack(seeds)
