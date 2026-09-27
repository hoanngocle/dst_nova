local prefabs = {}

local assets =
{
    Asset("ANIM", "anim/spider_poison_mutator.zip"),
    Asset("ATLAS", "images/inventoryimages/spider_poison_mutator.xml"),
}

local mutator_targets =
{
    "poison",
}

local mutator_extra_data =
{
    ["poison"] = {
        bank = "spider_poison_mutator",
        build = "spider_poison_mutator",
    },
}

local function MakeMutatorFn(mutator_target, extra_data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank((extra_data and extra_data.bank) or "spider_mutator_all")
    inst.AnimState:SetBuild((extra_data and extra_data.build) or "spider_mutators")
    inst.AnimState:PlayAnimation(mutator_target)

    inst:AddTag("spidermutator")
    inst:AddTag("monstermeat")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("stackable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "spider_poison_mutator"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/spider_poison_mutator.xml"

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.secondaryfoodtype = FOODTYPE.MONSTER
    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst:AddComponent("spidermutator")
    inst.components.spidermutator:SetMutationTarget("chasni_spider_" .. mutator_target)

    MakeHauntableLaunch(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)

    return inst
end

for _, mutator_target in ipairs(mutator_targets) do
    table.insert(prefabs, "chasni_spider_" .. mutator_target)
end

local mutator_prefabs = {}
for _, mutator_target in ipairs(mutator_targets) do
    local extra_data = mutator_extra_data[mutator_target]
    table.insert(
            mutator_prefabs,
            Prefab(
                    "chasni_mutator_" .. mutator_target,
                    function()
                        return MakeMutatorFn(mutator_target, extra_data)
                    end,
                    assets,
                    prefabs
            )
    )
end

return unpack(mutator_prefabs)
