require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/hat_lightdamager.zip"),
    Asset("ANIM", "anim/hat_strongdamager.zip"),
    Asset("ANIM", "anim/hat_crowndamager.zip"),
    Asset("ATLAS", "images/inventoryimages/lightdamager.xml"),
    Asset("ATLAS", "images/inventoryimages/crowndamager.xml"),
    Asset("ATLAS", "images/inventoryimages/strongdamager.xml"),
}

local SLOW = chasni_getitemconfig("marbled_hat", "SLOW") or 0.25
local ARMOR = {
    lightdamager = chasni_getitemconfig("marbled_hat", "ARMOR1") or 0.25,
    strongdamager = chasni_getitemconfig("marbled_hat", "ARMOR2") or 0.45,
    crowndamager = chasni_getitemconfig("marbled_hat", "ARMOR3") or 0.75,
}
local DAMAGE_REFLECTION = {
    lightdamager = chasni_getitemconfig("marbled_hat", "CRT1") or 1,
    strongdamager = chasni_getitemconfig("marbled_hat", "CRT2") or 2,
    crowndamager = chasni_getitemconfig("marbled_hat", "CRT3") or 5,
}
local MAX_DAMAGE_TAKEN          = 300
local DAMAGE_TAKEN_INCREMENT    = 3
local DAMAGE_TAKEN_CACHE        = TUNING.TOTAL_DAY_TIME * 0.5
local function setHat(inst, pfb_name)
    local armor = ARMOR[pfb_name]
    local build = "hat_" .. pfb_name
    local bank = pfb_name .. "hat"
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    if inst.components.inventoryitem then
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and inst.components.equippable and inst.components.equippable:IsEquipped()  then
            owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
        end
        if inst.components.armor then
            inst.components.armor:SetAbsorption(armor)
        end
        inst.components.inventoryitem.imagename = pfb_name
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. pfb_name ..".xml"
    end
end

local function updateHat(inst)
    setHat(inst, inst.components.fueled:GetPercent() > 0.66 and "crowndamager" or inst.components.fueled:GetPercent() > 0.33 and "strongdamager" or "lightdamager")
end

local function onfuelchange(section, oldsection, inst)
    setHat(inst, section == 3 and "crowndamager" or section == 2 and "strongdamager" or "lightdamager")
end

local function OnAttacked(owner, data, inst)
    if (data and data.damageresolved and data.attacker and not data.redirected) then
        if data.attacker.components.health and not data.attacker.components.health:IsDead() and data.attacker.components.combat then
            data.attacker.components.combat:GetAttacked(inst, data.damageresolved * DAMAGE_REFLECTION[inst.components.inventoryitem.imagename])
        end
        local increase = math.min((data.damageresolved * 0.05) + DAMAGE_TAKEN_INCREMENT, MAX_DAMAGE_TAKEN)
        inst.components.fueled:DoDelta(increase)
        inst.components.rechargeable:Discharge(DAMAGE_TAKEN_CACHE)
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    updateHat(inst)
    chasni_hatswapequip(owner)

    inst:ListenForEvent("blocked", inst._onattacked, owner)
    inst:ListenForEvent("attacked", inst._onattacked, owner)
end

local function onunequip(inst, owner)
    updateHat(inst)
    chasni_hatswapunequip(owner)

    inst:RemoveEventCallback("blocked", inst._onattacked, owner)
    inst:RemoveEventCallback("attacked", inst._onattacked, owner)
end

local function onload(inst, data)
    if inst.components.rechargeable:IsCharged() then
        inst.components.fueled:StartConsuming()
    else
        inst.components.fueled:StopConsuming()
    end
end

local function OnCharged(inst)
    inst.components.fueled:StartConsuming()
end

local function OnDischarged(inst)
    inst.components.fueled:StopConsuming()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lightdamagerhat")
    inst.AnimState:SetBuild("hat_lightdamager")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("marbled_hat")
    inst:AddTag("charges_percentage")
    inst:AddTag("rechargeable")
    inst:AddTag("chasni_hidearmorpctg")

    inst._restrictedtag = "expertwolf2"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(0)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = SLOW

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(MAX_DAMAGE_TAKEN)
    inst.components.fueled.accepting = false
    inst.components.fueled:SetSections(3)
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:StartConsuming()

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.imagename = "lightdamager"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/lightdamager.xml"
    updateHat(inst)

    inst._onattacked = function(owner, data)
        OnAttacked(owner, data, inst) 
    end

    inst.OnLoad = onload
    return inst
end

return Prefab("marbled_hat", fn, assets)