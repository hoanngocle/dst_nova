local assets =
{
    Asset("ANIM", "anim/chasni_staffwater.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_staffwater.xml"),
}

local prefabs =
{
    "crabstaff_water_fx"
}

local DAMAGE = chasni_getitemconfig("crabstaff_water", "DMG") or 10
local USES = chasni_getitemconfig("crabstaff_water", "USES") or 100
local RECHARGETIME = chasni_getitemconfig("crabstaff_water", "RCR") or 40
local USAGE = 10
local SANITY_COST = chasni_getitemconfig("crabstaff_water", "SAN") or 1
local MOISTURE = chasni_getitemconfig("crabstaff_water", "MOIS") or 1
local function DoRipple(inst)
    if inst.components.drownable and inst.components.drownable:IsOverWater() and not inst:HasTag("playerghost") then
        SpawnPrefab("weregoose_ripple"..tostring(math.random(2))).entity:SetParent(inst.entity)
    end
end

local function DoSplash(inst)
    if inst.components.drownable and inst.components.drownable:IsOverWater() and inst.sg:HasStateTag("moving") and not inst:HasTag("playerghost") then
        SpawnPrefab("weregoose_splash_med"..tostring(math.random(2))).entity:SetParent(inst.entity)
    end
end

local function ShouldNotDrown(inst)
    if inst.components.drownable and inst.components.drownable.enabled ~= false then
        inst.components.drownable.enabled = false
        if not inst:HasTag("playerghost") then
            inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
        end
    end
end

local function ShouldDrown(inst)
    if inst._crabstaffwater_notdrowntask then
        inst._crabstaffwater_notdrowntask:Cancel()
        inst._crabstaffwater_notdrowntask = nil
    end
    if inst.components.drownable and inst.components.drownable.enabled == false then
        inst.components.drownable.enabled = true
        if not inst:HasTag("playerghost") then
            inst.Physics:CollidesWith(COLLISION.LIMITS)
        end
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_staffwater", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)

    if owner.rippletask == nil then
        owner.rippletask = owner:DoPeriodicTask(.7, DoRipple, FRAMES)
    end
    if owner.splashtask == nil then
        owner.splashtask = owner:DoPeriodicTask(.3, DoSplash, FRAMES)
    end

    owner._crabstaffwater_notdrowntask = owner:DoPeriodicTask(0, ShouldNotDrown)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)

    if owner.rippletask then
        owner.rippletask:Cancel()
        owner.rippletask = nil
    end
    if owner.splashtask then
        owner.splashtask:Cancel()
        owner.splashtask = nil
    end
    ShouldDrown(owner)
end
local function SpawnEffect(inst, target, prefab)
    local x, y, z = target.Transform:GetWorldPosition()
    SpawnPrefab(prefab).Transform:SetPosition(x, y + .1, z, 0.8, 0.8, 0.8)
    inst.components.wateryprotection:SpreadProtectionAtPoint(x, y, z)
end

local function OnBlinked(caster, staff, dpt)
    if caster.sg == nil then
        caster:Show()
        if caster.components.health then
            caster.components.health:SetInvincible(false)
        end
        if caster.DynamicShadow then
            caster.DynamicShadow:Enable(true)
        end
    elseif caster.sg.statemem.onstopblinking then
        caster.sg.statemem.onstopblinking()
    end
    local pt = dpt:GetPosition()
    if pt then
        caster.Physics:Teleport(pt:Get())
    end
    SpawnEffect(staff, caster, "crab_king_waterspout")
end

local function oncast(inst, target, pos)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if inst._blinktask then 
        inst._blinktask:Cancel()
    end

    SpawnEffect(inst, owner, "crab_king_waterspout")
    if owner.sg == nil then
        owner:Hide()
        if owner.DynamicShadow then
            owner.DynamicShadow:Enable(false)
        end
        if owner.components.health then
            owner.components.health:SetInvincible(true)
        end
    elseif owner.sg.statemem.onstartblinking then
        owner.sg.statemem.onstartblinking()
    end
    inst.blinktask = owner:DoTaskInTime(0.25, OnBlinked, inst, DynamicPosition(pos))

    inst.components.rechargeable:Discharge(RECHARGETIME)
    inst.components.finiteuses:Use(USAGE)
    if owner then
        if owner.components.staffsanity then
            owner.components.staffsanity:DoCastingDelta(-SANITY_COST)
        elseif owner.components.sanity then
            owner.components.sanity:DoDelta(-SANITY_COST)
        end
    end
    return true
end

local function reticule_target_function(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function OnCharged(inst)
    inst.components.finiteuses:SetPercent(1)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_staffwater")
    inst.AnimState:SetBuild("chasni_staffwater")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("weapon")
    inst:AddTag("quickcast")
    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("rechargeable")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = reticule_target_function
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("crabstaff_water_fx")
    inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_staffwater"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_staffwater.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.quickcast = true
    inst.components.spellcaster:SetSpellFn(oncast)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("wateryprotection")
    inst.components.wateryprotection.addwetness = MOISTURE
    inst.components.wateryprotection.protection_dist = TUNING.TRIDENT.SPELL.RADIUS * 0.8

    MakeHauntableLaunch(inst)

    return inst
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("chasni_staffwater")
    inst.AnimState:SetBuild("chasni_staffwater")
    inst.AnimState:PlayAnimation("swap_energy", true)
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colouradder")

    inst.persists = false

    return inst
end

return
Prefab("crabstaff_water", fn, assets, prefabs),
Prefab("crabstaff_water_fx", fxfn, assets)
