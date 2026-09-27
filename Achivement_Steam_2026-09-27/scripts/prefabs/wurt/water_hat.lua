local assets =
{
    Asset("ANIM", "anim/water_hat.zip"),
    Asset("ATLAS", "images/inventoryimages/water_hat.xml"),
}

local MAX_ARMOR = chasni_getitemconfig("water_hat", "ARMOR") or 0.8
local function OnWetnessChanged(inst, data)
    local equippedHat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    if equippedHat and equippedHat.prefab == "water_hat" and equippedHat.components.armor then
        local abs = math.min(data.new * 0.01, MAX_ARMOR)
        equippedHat.components.armor:SetAbsorption(abs)
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "water_hat", "swap_hat")
    owner.AnimState:Show("HAT")

    local moisture = 0
    if owner.components.moisture then
        moisture = owner.components.moisture:GetMoisture()
    end
    local abs = math.min(moisture * 0.01, MAX_ARMOR)
    inst.components.armor:SetAbsorption(abs)
    owner:ListenForEvent("moisturedelta", OnWetnessChanged)
end
local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")

    owner:RemoveEventCallback("moisturedelta", OnWetnessChanged)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("water_hat")
    inst.AnimState:SetBuild("water_hat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("hide_percentage")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(MAX_ARMOR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "water_hat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/water_hat.xml"

    return inst
end

return Prefab("water_hat", fn, assets)