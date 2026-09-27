local assets =
{
    Asset("ANIM", "anim/upgraded_batbat.zip"),
    Asset("ANIM", "anim/swap_upgraded_batbat.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_batbat.xml"),
}

local prefabs =
{
    "batbat_batfx1",
    "batbat_batfx2",
    "batbat_batfx3",
    "batbat_batfx4",
}

local DAMAGE = chasni_getitemconfig("upgraded_batbat", "DMG") or 68
local DAMAGE_EMPTY = chasni_getitemconfig("upgraded_batbat", "EMPT") or 10
local COOLDOWN = chasni_getitemconfig("upgraded_batbat", "CD") or 30
local CRITCHANCE = chasni_getitemconfig("upgraded_batbat", "CRIT") or 1
local USES = TUNING.LARGE_FUEL * (chasni_getitemconfig("upgraded_batbat", "USES") or 400)
local USAGE = TUNING.LARGE_FUEL * (chasni_getitemconfig("upgraded_batbat", "USAGE") or 10)
local HEAL = chasni_getitemconfig("upgraded_batbat", "HEAL") or 1.5
local SHADOW_LEVEL = 4
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_upgraded_batbat", "swap_upgraded_batbat")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function getDamage(inst)
    return inst.components.fueled and inst.components.fueled:IsEmpty() and DAMAGE_EMPTY or DAMAGE
end

local function onattack(inst, attacker, target)
    if inst.components.fueled and not inst.components.fueled:IsEmpty() then
        if chasni_isLifeDrainable(target) then
            if attacker.components.health then
                attacker.components.health:DoDelta(HEAL, false, "batbat")
            end
        end
    end

    if inst.components.rechargeable and inst.components.rechargeable:IsCharged() then
        inst.components.rechargeable:Discharge(COOLDOWN)
        inst.components.fueled:DoDelta(-USAGE)
        local randombat = math.random(4)
        local fx = SpawnPrefab("batbat_batfx"..randombat)
        if fx then
            local x, _, z = target.Transform:GetWorldPosition()
            local radius = target:GetPhysicsRadius(.5)
            local angle = (inst.Transform:GetRotation() - 90) * DEGREES
            fx.Transform:SetPosition(x + math.sin(angle) * radius, 0, z + math.cos(angle) * radius)
        end
        inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/shadow_attack")
    end
end

local function OnCharged(inst)
    inst.chasni_critchancegear = CRITCHANCE
end

local function OnDischarged(inst)
    inst.chasni_critchancegear = 0
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("upgraded_batbat")
    inst.AnimState:SetBuild("upgraded_batbat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("shadow_item")
    inst:AddTag("shadow")
    inst:AddTag("sharp")
    inst:AddTag("weapon")
	inst:AddTag("shadowlevel")
    inst:AddTag("rechargeable")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.65)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(getDamage)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "upgraded_batbat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_batbat.xml"

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(USES)
    inst.components.fueled.accepting = true

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.dapperness = TUNING.CRAZINESS_MED * 2
    inst.components.equippable.is_magic_dapperness = true

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(SHADOW_LEVEL)

    inst.chasni_critchancegear = CRITCHANCE

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("upgraded_batbat", fn, assets, prefabs)
