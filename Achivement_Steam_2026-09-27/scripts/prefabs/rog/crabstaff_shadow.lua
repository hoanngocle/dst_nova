local assets =
{
    Asset("ANIM", "anim/chasni_staffshadow.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_staffshadow.xml"),
}

local prefabs =
{
    "crabstaff_shadow_fx"
}

local SHADOW_LEVEL = 4
local DAMAGE = chasni_getitemconfig("crabstaff_shadow", "DMG") or 10
local USES = chasni_getitemconfig("crabstaff_shadow", "USES") or 100
local USAGE = 20
local SANITY_COST = chasni_getitemconfig("crabstaff_shadow", "SAN") or 50
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_staffshadow", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)
end

local NOTENTCHECK_CANT_TAGS = { "FX", "INLIMBO" }
local function noentcheckfn(pt)
    return not TheWorld.Map:IsPointNearHole(pt) and #TheSim:FindEntities(pt.x, pt.y, pt.z, 1, nil, NOTENTCHECK_CANT_TAGS) == 0
end

local function spawnPortal(pt, targetpt)
    local portal = SpawnPrefab("pocketwatch_portal_entrance")
    portal.Transform:SetPosition(pt:Get())
    portal:SpawnExit(TheShard:GetShardId(), targetpt.x, 0, targetpt.z)
    portal.components.inspectable:SetNameOverride("crabstaff_shadow_portal")
    portal.components.inspectable.nameoverride = "CRABSTAFF_SHADOW_PORTAL"
    portal:AddTag("crabstaff_shadow_portal")
end

local function oncast(inst, target, pos)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    local pt = owner:GetPosition()
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 3 + math.random(), 16, false, true, noentcheckfn, true, true)
            or FindWalkableOffset(pt, math.random() * 2 * PI, 5 + math.random(), 16, false, true, noentcheckfn, true, true)
            or FindWalkableOffset(pt, math.random() * 2 * PI, 7 + math.random(), 16, false, true, noentcheckfn, true, true)
    if offset then
        pt = pt + offset
    end
    spawnPortal(pt, pos)
    spawnPortal(pos, pt)

    inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")

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

local function CanSpellCastOnMap(_, doer)
    return true
end

local function reticule_target_function(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_staffshadow")
    inst.AnimState:SetBuild("chasni_staffshadow")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("weapon")
    inst:AddTag("mapcasting")
    inst:AddTag("shadow_item")
    inst:AddTag("shadowlevel")

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("complexprojectile_showoceanaction")
    inst:AddTag("action_pulls_up_map")
    inst.map_remap_min_dist = ACTIONS.TOSS.distance + TUNING.OCEANWHIRLPORTAL_BOAT_INTERACT_DISTANCE * 2
    inst.CanSpellCastOnMap = CanSpellCastOnMap

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
    inst._fxswap = SpawnPrefab("crabstaff_shadow_fx")
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
    inst.components.inventoryitem.imagename = "chasni_staffshadow"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_staffshadow.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster:SetSpellFn(oncast)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(SHADOW_LEVEL)

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

    inst.AnimState:SetBank("chasni_staffshadow")
    inst.AnimState:SetBuild("chasni_staffshadow")
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
Prefab("crabstaff_shadow", fn, assets, prefabs),
Prefab("crabstaff_shadow_fx", fxfn, assets)
