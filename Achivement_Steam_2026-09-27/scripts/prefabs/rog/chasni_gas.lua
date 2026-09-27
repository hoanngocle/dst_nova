local assets =
{
    Asset("ANIM", "anim/chasni_gas.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_gas.xml"),
}

local function playidleanim(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if TheWorld.Map:IsOceanAtPoint(x, y, z, false) then
        inst.AnimState:PlayAnimation("idle_water")
    else
        inst.AnimState:PlayAnimation("idle")
    end
end

local function FuelTaken(inst, taker)
    if taker and taker:HasTag("campfire") then
        taker._chasni_gas_fueled = true
    end
    local fx = taker.components.burnable ~= nil and taker.components.burnable.fxchildren[1] or nil
    local x, y, z
    if fx ~= nil and fx:IsValid() then
        x, y, z = fx.Transform:GetWorldPosition()
    else
        x, y, z = taker.Transform:GetWorldPosition()
    end
    SpawnPrefab("poopcloud").Transform:SetPosition(x, y + 1, z)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.2, 0.80)

    inst.AnimState:SetBank("chasni_gas")
    inst.AnimState:SetBuild("chasni_gas")
    inst.AnimState:PlayAnimation("idle", true)

    inst.pickupsound = "metal"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("bait")
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_gas"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_gas.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    inst.components.fuel:SetOnTakenFn(FuelTaken)

    MakeHauntableLaunchAndSmash(inst)
    inst:ListenForEvent("on_landed", playidleanim)

    return inst
end

return Prefab("chasni_gas", fn, assets)