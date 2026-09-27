local assets =
{
    Asset("ANIM", "anim/thunder_armor.zip"),
    Asset("ATLAS", "images/inventoryimages/thunder_armor.xml")
}

local ARMOR = chasni_getitemconfig("thunder_armor", "ARMOR") or 0.8
local USES = chasni_getitemconfig("thunder_armor", "DUR") or 1500
local REPAIR_MULTIPLIER = chasni_getitemconfig("thunder_armor", "REP") or 0.1
local BATTLEBORN_MULT = chasni_getitemconfig("thunder_armor", "BAT") or 4
local MAX_HEALTH_DAMAGE = chasni_getitemconfig("thunder_armor", "HPD") or 0.01
local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

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

local function dosparkdamage(inst, data)
    SpawnPrefab("electrichitsparks"):AlignToTarget(data.target, inst, true)
    if inst.components.armor and data.target.components.health and not data.target.components.health:IsDead() then
        local dmg = data.target.components.health.currenthealth * MAX_HEALTH_DAMAGE * inst.components.armor:GetPercent()
        data.target.components.health:DoDelta(-dmg)
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "thunder_armor", "swap_body")

    inst:ListenForEvent("blocked", OnBlocked, owner)

    if inst.selfrepair then
        inst.selfrepair:Cancel()
        inst.selfrepair = nil
    end
    inst.selfrepair = inst:DoPeriodicTask(1, selfrepairing)
    owner:ListenForEvent("onhitother", dosparkdamage)
end

local function onunequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)

    if inst.selfrepair then
        inst.selfrepair:Cancel()
        inst.selfrepair = nil
    end
    owner:RemoveEventCallback("onhitother", dosparkdamage)
end

local function onsetbonus_enabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if chasni_hastag(inst, owner) then
        if owner.components.battleborn then
            owner._chasni_originalbattleborn_zeusset = owner.components.battleborn.battleborn_bonus
            owner.components.battleborn:SetBattlebornBonus(BATTLEBORN_MULT * owner._chasni_originalbattleborn_zeusset)
        end
    end
end

local function onsetbonus_disabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner.components.battleborn then
        if owner._chasni_originalbattleborn_zeusset then
            owner.components.battleborn:SetBattlebornBonus(owner._chasni_originalbattleborn_zeusset)
            owner._chasni_originalbattleborn_zeusset = nil
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("thunder_armor")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.AnimState:SetBank("thunder_armor")
    inst.AnimState:SetBuild("thunder_armor")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/logarmour"
    inst._restrictedtag = "expertwathg1"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "thunder_armor"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/thunder_armor.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(USES, ARMOR)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.EXPERTWATHG1)
    inst.components.setbonus:SetOnEnabledFn(onsetbonus_enabled)
    inst.components.setbonus:SetOnDisabledFn(onsetbonus_disabled)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("thunder_armor", fn, assets) 
