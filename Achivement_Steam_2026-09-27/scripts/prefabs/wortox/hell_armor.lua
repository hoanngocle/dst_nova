local assets =
{
    Asset("ANIM", "anim/hell_armor.zip"),
    Asset("ANIM", "anim/armor_snakeskin_scaly.zip"),
    Asset("ATLAS", "images/inventoryimages/hell_armor.xml"),
    Asset("ATLAS", "images/inventoryimages/hell_armor_evolved.xml"),
}

local ARMOR = chasni_getitemconfig("hell_armor", "ARMOR") or 0.69
local USES = chasni_getitemconfig("hell_armor", "DUR") or 2020
local EVASION = chasni_getitemconfig("hell_armor", "EVA1") or 0.1
local EVASION_EVOLVED = chasni_getitemconfig("hell_armor", "EVA2") or 0.4
local CRITCHANCE = chasni_getitemconfig("hell_armor", "CRIT1") or 0.1
local CRITCHANCE_EVOLVED = chasni_getitemconfig("hell_armor", "CRIT2") or 4
local function updateLook(inst)
    local isEvolved = inst.evolvedtime and inst.evolvedtime > 0

    local anim = isEvolved and "armor_snakeskin_scaly" or "hell_armor"
    local atlas = isEvolved and "hell_armor_evolved" or "hell_armor"
    inst.chasni_dodgechancegear = isEvolved and EVASION_EVOLVED or EVASION
    inst.chasni_critchancegear = isEvolved and CRITCHANCE_EVOLVED or CRITCHANCE
    inst.AnimState:SetBank(anim)
    inst.AnimState:SetBuild(anim)

    local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or nil
    if owner and inst.components.equippable and inst.components.equippable:IsEquipped()  then
        owner.AnimState:OverrideSymbol("swap_body", anim, "swap_body")
        owner.AnimState:OverrideSymbol("backpack", anim, "backpack")
    end
    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = atlas
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. atlas ..".xml"
    end
end

local function onsetbonus_enabled(inst)
    inst:AddTag("hell_set_bonus")
end

local function onsetbonus_disabled(inst)
    inst:RemoveTag("hell_set_bonus")
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    updateLook(inst)
    owner.AnimState:OverrideSymbol("swap_body", "hell_armor", "swap_body")
    owner.AnimState:OverrideSymbol("backpack", "hell_armor", "backpack")
end

local function onunequip(inst, owner)
    updateLook(inst)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
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

    inst.AnimState:SetBank("hell_armor")
    inst.AnimState:SetBuild("hell_armor")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hell_armor")

    inst._restrictedtag = "expertwortox3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        updateLook(inst)
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(USES, ARMOR)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hell_armor"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hell_armor.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.EXPERTWORTOX1)
    inst.components.setbonus:SetOnEnabledFn(onsetbonus_enabled)
    inst.components.setbonus:SetOnDisabledFn(onsetbonus_disabled)

    inst:DoPeriodicTask(1, function()
        if inst.evolvedtime and inst.evolvedtime > 0 then
            inst.evolvedtime = math.max(0, inst.evolvedtime - 1)
        end
        updateLook(inst)
    end)

    inst.chasni_dodgechancegear = EVASION
    inst.chasni_critchancegear = CRITCHANCE
    inst.Evolve = function(inst_, time)
        inst_.evolvedtime = (inst_.evolvedtime or 0) + time
        updateLook(inst_)
    end
    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

local function OnAttached_soulecho(inst, target, followsymbol, followoffset, data)
    local duration = data and data.duration or target and target.GetSoulEchoCooldownTime and target:GetSoulEchoCooldownTime() or TUNING.WORTOX_FREEHOP_TIMELIMIT
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)
    inst.components.timer:StartTimer("buffover", duration)
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
    if target ~= nil and target:IsValid() and target.components.combat ~= nil then
        local modifier = math.random(5, 25) / 100
        target.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + modifier)
    end
end

local function OnDetached_soulecho(inst, target)
    if target ~= nil and target:IsValid() and target.components.combat ~= nil then
        target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
    end
    inst:Remove()
end

local function OnExtendedBuff_soulecho(inst, target, followsymbol, followoffset, data)
    local duration = data and data.duration or target and target.GetSoulEchoCooldownTime and target:GetSoulEchoCooldownTime() or TUNING.WORTOX_FREEHOP_TIMELIMIT
    local time_remaining = inst.components.timer:GetTimeLeft("buffover")
    if time_remaining == nil or duration > time_remaining then
        inst.components.timer:SetTimeLeft("buffover", duration)
    end
end

local function OnTimerDone_soulecho(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function hell_armor_buff_fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached_soulecho)
    inst.components.debuff:SetDetachedFn(OnDetached_soulecho)
    inst.components.debuff:SetExtendedFn(OnExtendedBuff_soulecho)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone_soulecho)

    return inst
end

return Prefab("hell_armor", fn, assets),
Prefab("chasni_hell_armor_buff", hell_armor_buff_fn)

