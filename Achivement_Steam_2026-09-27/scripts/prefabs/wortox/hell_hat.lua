require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/hell_hat.zip"),
    Asset("ANIM", "anim/hat_snakeskin_scaly.zip"),
    Asset("ATLAS", "images/inventoryimages/hell_hat.xml"),
    Asset("ATLAS", "images/inventoryimages/hell_hat_evolved.xml"),
}

local ARMOR = chasni_getitemconfig("hell_hat", "ARMOR") or 0.69
local USES = chasni_getitemconfig("hell_hat", "DUR") or 2020
local EVASION = chasni_getitemconfig("hell_hat", "EVA1") or 0.1
local EVASION_EVOLVED = chasni_getitemconfig("hell_hat", "EVA2") or 0.4
local CRITDAMAGE = chasni_getitemconfig("hell_hat", "CRIT1") or 0.2
local CRITDAMAGE_EVOLVED = chasni_getitemconfig("hell_hat", "CRIT2") or 0.8
local function updateLook(inst)
    local isEvolved = inst.evolvedtime and inst.evolvedtime > 0

    local anim = isEvolved and "hat_snakeskin_scaly" or "hell_hat"
    local atlas = isEvolved and "hell_hat_evolved" or "hell_hat"
    inst.chasni_dodgechancegear = isEvolved and EVASION_EVOLVED or EVASION
    inst.chasni_critdamagegear = isEvolved and CRITDAMAGE_EVOLVED or CRITDAMAGE
    inst.AnimState:SetBank(anim)
    inst.AnimState:SetBuild(anim)

    local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or nil
    if owner and inst.components.equippable and inst.components.equippable:IsEquipped()  then
        owner.AnimState:OverrideSymbol("swap_hat", anim, "swap_hat")
    end
    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = atlas
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. atlas ..".xml"
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    updateLook(inst)
    chasni_hatswapequip(owner)
end

local function onunequip(inst, owner)
    updateLook(inst)
    chasni_hatswapunequip(owner)
end

local function onsave(inst, data)
    data.evolvedtime = inst.evolvedtime or 0
end

local function onload(inst, data)
    inst.evolvedtime = data and data.evolvedtime or 0
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("hat_snakeskin_scaly")
    inst.AnimState:SetBuild("hat_snakeskin_scaly")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("hell_hat")

    inst._restrictedtag = "expertwortox3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(USES, ARMOR)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hell_hat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hell_hat.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.EXPERTWORTOX1)

    inst:DoPeriodicTask(1, function()
        if inst.evolvedtime and inst.evolvedtime > 0 then
            inst.evolvedtime = math.max(0, inst.evolvedtime - 1)
        end
        updateLook(inst)
    end)

    inst.chasni_dodgechancegear = EVASION
    inst.chasni_critdamagegear = CRITDAMAGE
    inst.Evolve = function(inst_, time)
        inst_.evolvedtime = (inst_.evolvedtime or 0) + time
        updateLook(inst_)
    end
    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

return Prefab("hell_hat", fn, assets)