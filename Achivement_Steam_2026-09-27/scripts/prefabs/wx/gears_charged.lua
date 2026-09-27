local assets =
{
    Asset("ANIM", "anim/gears_charged.zip"),
    Asset("ATLAS", "images/inventoryimages/gears_charged.xml"),
}

local function onpickup(inst)
    inst.Light:Enable(false)
end

local function ondropped(inst)
    inst.Light:Enable(true)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.7)

    inst.AnimState:SetBank("gears_charged")
    inst.AnimState:SetBuild("gears_charged")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)

    inst.pickupsound = "metal"
    inst:AddTag("molebait")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "GEARS"

    inst:AddComponent("bait")
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "gears_charged"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/gears_charged.xml"

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GEARS
    inst.components.edible.healthvalue = TUNING.HEALING_HUGE
    inst.components.edible.hungervalue = TUNING.CALORIES_HUGE
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE
    inst.components.edible:SetOnEatenFn(function(_, eater)
        if eater.components.upgrademoduleowner then
            eater.components.upgrademoduleowner:AddCharge(6)
        end
    end)

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.GEARS
    inst.components.repairer.workrepairvalue = TUNING.REPAIR_GEARS_WORK * 10

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "gears"

    inst:ListenForEvent("onputininventory", onpickup)
    inst:ListenForEvent("ondropped", ondropped)

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("chasni_gears_charged", fn, assets)