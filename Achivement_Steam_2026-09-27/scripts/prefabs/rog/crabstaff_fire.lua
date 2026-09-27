local assets =
{
    Asset("ANIM", "anim/chasni_stafffire.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_stafffire.xml"),
}

local prefabs =
{
    "crabstaff_fire_fx"
}

local USES = chasni_getitemconfig("crabstaff_fire", "USES") or 100
local USAGE = 0.25
local SANITY_COST = chasni_getitemconfig("crabstaff_fire", "SAN") or 3
local TEMP_DELTA = chasni_getitemconfig("crabstaff_ice", "TEMP") or 3
local DAMAGE = chasni_getitemconfig("crabstaff_fire", "DMG") or 34
local DAMAGEMULT = chasni_getitemconfig("crabstaff_fire", "DMGM") or 0.3
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_stafffire", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)
end

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function getDamage(inst, attacker, target)
    if attacker and attacker and attacker.components.levelsystem then
        return DAMAGE + (attacker.components.levelsystem.level * DAMAGEMULT)
    end
    return DAMAGE
end

local function onattack(inst, attacker, target)
    inst.components.finiteuses:Use(USAGE)
    if attacker then
        if target and target:IsValid() and target.components.burnable and not target.components.burnable:IsBurning() then
            if target.components.fueled == nil or (target.components.fueled.fueltype ~= FUELTYPE.BURNABLE and target.components.fueled.secondaryfueltype ~= FUELTYPE.BURNABLE) then
                if target.components.burnable.canlight or target.components.combat then
                    target.components.burnable:Ignite(true, attacker)
                end
            elseif target.components.fueled.accepting then
                local fuel = SpawnPrefab("cutgrass")
                if fuel then
                    if fuel.components.fuel and fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
                        target.components.fueled:TakeFuelItem(fuel)
                    else
                        fuel:Remove()
                    end
                end
            end
        end
    end
    inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
end

local function projectilelaunched(inst, attacker, target, proj)
    if proj.components.weapon then
        proj:RemoveComponent("weapon")
    end
    if attacker.components.temperature then
        attacker.components.temperature:DoDelta(TEMP_DELTA)
    end
    if attacker.components.staffsanity then
        attacker.components.staffsanity:DoCastingDelta(-SANITY_COST)
    elseif attacker.components.sanity then
        attacker.components.sanity:DoDelta(-SANITY_COST)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_stafffire")
    inst.AnimState:SetBuild("chasni_stafffire")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("weapon")
    inst:AddTag("rangedweapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("crabstaff_fire_fx")
    inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(getDamage)
    inst.components.weapon:SetRange(12, 15)
    inst.components.weapon:SetOnAttack(onattack)
    inst.components.weapon:SetProjectile("chasni_crabking_claw_fire_proj")
    inst.components.weapon:SetOnProjectileLaunched(projectilelaunched)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_stafffire"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_stafffire.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

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

    inst.AnimState:SetBank("chasni_stafffire")
    inst.AnimState:SetBuild("chasni_stafffire")
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
Prefab("crabstaff_fire", fn, assets, prefabs),
Prefab("crabstaff_fire_fx", fxfn, assets)
