local assets =
{
    Asset("ANIM", "anim/cork_bat.zip"),
    Asset("ANIM", "anim/swap_cork_bat.zip"),
    Asset("ATLAS", "images/inventoryimages/cork_bat.xml")
}

local prefabs =
{
    "groundpound_fx",
    "groundpoundring_fx",
}

local SLOW = chasni_getitemconfig("marbled_spear", "SLOW") or 0.25
local MIGHTY_DELTA = chasni_getitemconfig("marbled_spear", "MGH") or 25
local HUNGER_DELTA = chasni_getitemconfig("marbled_spear", "HNG") or 25
local HEALTH_DELTA = chasni_getitemconfig("marbled_spear", "HP") or 25
local USES = chasni_getitemconfig("marbled_spear", "USE") or 400
local CAST_USES = chasni_getitemconfig("marbled_spear", "USE") or 5
local DAMAGE = chasni_getitemconfig("marbled_spear", "DMG") or 34
local COOLDOWN = chasni_getitemconfig("marbled_spear", "CD") or 45
local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_cork_bat", "swap_cork_bat")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.ownerAttackPeriod = owner.components.combat.min_attack_period
    inst.ownerAreaHitRange = owner.components.combat.areahitrange

    if chasni_hastag(inst, owner) then
        owner.components.combat:SetAreaDamage(5)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner.components.combat:SetAreaDamage(nil)

    owner.components.combat:SetAttackPeriod(inst.ownerAttackPeriod)
    owner.components.combat:SetAreaDamage(inst.ownerAreaHitRange)

    inst.ownerAreaHitRange = nil
end

local function OnAttack(inst, attacker, target, projectile)
    local pos = target:GetPosition()
    if chasni_hastag2(attacker, "expertwolf2") then
        local fx = SpawnPrefab("groundpound_fx")
        fx.Transform:SetPosition(pos.x, pos.y, pos.z)
        local fx2 = SpawnPrefab("groundpoundring_fx")
        fx2.Transform:SetPosition(pos.x, pos.y, pos.z)
        fx2.Transform:SetScale(0.7, 0.7, 0.7)
    end
end

local function getDamage(inst, attacker, target)
    local mightiness = attacker.components.mightiness and attacker.components.mightiness:GetCurrent() or 0
    local increment = (0.001 * mightiness * mightiness) + (0.05 * mightiness) - 10
    return DAMAGE + increment
end

local function eat(inst, target, position)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    owner.sg:GoToState("eat", { chews = 1 })
    if owner.components.mightiness then
        owner.components.mightiness:DoDelta(MIGHTY_DELTA)
    end
    if owner.components.hunger then
        owner.components.hunger:DoDelta(HUNGER_DELTA)
    end
    if owner.components.health then
        owner.components.health:DoDelta(HEALTH_DELTA)
    end
    inst.components.rechargeable:Discharge(COOLDOWN)
    inst.components.finiteuses:Use(CAST_USES)
end

local function OnCharged(inst)
    inst.components.spellcaster:SetSpellFn(eat)
end

local function OnDischarged(inst)
    inst.components.spellcaster:SetSpellFn(nil)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.4, 0.80)

    inst.AnimState:SetBank("cork_bat")
    inst.AnimState:SetBuild("cork_bat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("quickcast")
    inst:AddTag("weapon")
    inst:AddTag("rechargeable")

    inst._restrictedtag = "expertwolf2"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.AttackNum = 0

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(getDamage)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "cork_bat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/cork_bat.xml"

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = SLOW

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canusefrominventory = true
    inst.components.spellcaster.quickcast = true
    inst.components.spellcaster:SetSpellFn(eat)

    inst.ownerAttackPeriod = TUNING.WILSON_ATTACK_PERIOD
    inst.ownerAreaHitRange = nil
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("marbled_spear", fn, assets, prefabs)
