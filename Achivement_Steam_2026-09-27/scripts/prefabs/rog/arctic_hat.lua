local assets =
{
    Asset("ANIM", "anim/hat_recharger.zip"),
    Asset("ATLAS", "images/inventoryimages/hat_recharger.xml"),
}

local COOLING = chasni_getitemconfig("arctic_hat", "TEMP") or 70
local function onequip(inst, owner)
    if inst.heater == nil then
        inst.heater = chasni_spawnprefab("arctic_hat_heater", 0, 0, 0, 1, 1, 1, owner.entity)
    end
    owner.AnimState:OverrideSymbol("swap_hat", "hat_recharger", "swap_hat")
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

    inst.AnimState:SetBank("rechargerhat")
    inst.AnimState:SetBuild("hat_recharger")
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
    inst.components.inventoryitem.imagename = "hat_recharger"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_recharger.xml"

    return inst
end

local function cold_emitter_fn()
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
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.heat = COOLING

    inst.persists = false

    return inst
end

return Prefab("arctic_hat", fn, assets),
Prefab("arctic_hat_heater", cold_emitter_fn)