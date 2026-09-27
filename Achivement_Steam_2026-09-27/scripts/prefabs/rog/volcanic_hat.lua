local assets =
{
    Asset("ANIM", "anim/hat_volcano.zip"),
    Asset("ATLAS", "images/inventoryimages/hat_volcano.xml"),
}

local HEATING = chasni_getitemconfig("volcanic_hat", "TEMP") or 70
local function onequip(inst, owner)
    if inst.heater == nil then
        inst.heater = chasni_spawnprefab("volcanic_hat_heater", 0, 0, 0, 1, 1, 1, owner.entity)
    end
    owner.AnimState:OverrideSymbol("swap_hat", "hat_volcano", "swap_hat")
    chasni_hatswapequip(owner)
end

local function onunequip(inst, owner)
    if inst.heater ~= nil then
        inst.heater:Remove()
        inst.heater = nil
    end
    chasni_hatswapunequip(owner)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("hat_volcano")
    inst.AnimState:SetBuild("hat_volcano")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hat_volcano"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_volcano.xml"

    return inst
end

local function heat_emitter_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("heater")
    inst.components.heater:SetThermics(true, false)
    inst.components.heater.heat = HEATING

    inst.persists = false

    return inst
end

return Prefab("volcanic_hat", fn, assets),
Prefab("volcanic_hat_heater", heat_emitter_fn)
