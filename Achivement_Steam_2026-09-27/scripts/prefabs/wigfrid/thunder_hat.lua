local assets =
{
    Asset("ANIM", "anim/thunder_hat.zip"),
    Asset("ATLAS", "images/inventoryimages/thunder_hat.xml"),
}

local ARMOR = chasni_getitemconfig("thunder_armor", "ARMOR") or 0.7
local USES = chasni_getitemconfig("thunder_armor", "DUR") or 2000
local SPEEDMULT = chasni_getitemconfig("thunder_hat", "SPD") or 1.25
local REPAIR_MULTIPLIER = chasni_getitemconfig("thunder_hat", "REP") or 0.1

local function selfrepairing(inst)
    local owner  = inst.components.inventoryitem:GetGrandOwner()
    if owner and chasni_hastag(inst, owner) then
        if owner and inst.components.armor and owner.components.combat then
            if owner.components.singinginspiration and owner.components.singinginspiration.current > 0 then
                inst.components.armor:Repair(owner.components.singinginspiration.current * REPAIR_MULTIPLIER)
            end
        end
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "thunder_hat", "swap_hat")
    owner.AnimState:Show("HAT")

    if inst.selfrepair then
        inst.selfrepair:Cancel()
        inst.selfrepair = nil
    end
    inst.selfrepair = inst:DoPeriodicTask(1, selfrepairing)
end

local function onunequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")

    if inst.selfrepair then
        inst.selfrepair:Cancel()
        inst.selfrepair = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("thunder_hat")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("thunder_hat")
    inst.AnimState:SetBuild("thunder_hat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    inst._restrictedtag = "expertwathg1"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(USES, ARMOR)
    inst.components.armor:SetTags({ "epic" })

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.EXPERTWATHG1)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "thunder_hat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/thunder_hat.xml"

    inst.components.equippable.walkspeedmult = SPEEDMULT
    return inst
end

return Prefab("thunder_hat", fn, assets)