local assets =
{
    Asset("ANIM", "anim/chasni_staffice.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_staffice.xml"),
    Asset("SOUNDPACKAGE", "sound/winterwyvern.fev"),
    Asset("SOUND", "sound/winterwyvern.fsb"),
}

local prefabs =
{
    "crabstaff_ice_fx",
    "ckc_icestaffburst_fx",
    "ckc_icestaffburst2_fx",
}

local DAMAGE = chasni_getitemconfig("crabstaff_ice", "DMG") or 10
local USES = chasni_getitemconfig("crabstaff_ice", "USES") or 100
local USAGE = 15
local SANITY_COST = chasni_getitemconfig("crabstaff_ice", "SAN") or 15
local TEMP_DELTA = chasni_getitemconfig("crabstaff_ice", "TEMP") or -20
local COLDNESS = chasni_getitemconfig("crabstaff_ice", "COLD") or 3
local BASE_DAMAGE = chasni_getitemconfig("crabstaff_ice", "BDMG") or 17
local DAMAGE_MULT = chasni_getitemconfig("crabstaff_ice", "PDMG") or 2
local RANGE = chasni_getitemconfig("crabstaff_ice", "RNG") or 4
local BLAST_RANGE = chasni_getitemconfig("crabstaff_ice", "RNG") or 5
local BASE_HEAL = chasni_getitemconfig("crabstaff_ice", "BHEAL") or 1
local HEAL_PERCENTAGE = chasni_getitemconfig("crabstaff_ice", "PHEAL") or 0.03
local HEAL_TICK = chasni_getitemconfig("crabstaff_ice", "TICK") or 0.3
local COLDEMBRACE_DURATION = chasni_getitemconfig("crabstaff_ice", "DUR") or 3.1
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_staffice", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)
end

local TARGET_CANT_TAG = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "_coldembraced"}
local function oncast(inst, target, pos)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    pos = pos or (target and Vector3(target.Transform:GetWorldPosition())) or nil
    if pos then
        local players = FindPlayersInRange(pos.x, pos.y, pos.z, RANGE, true)
        chasni_spawnprefab("ckc_icestaffburst2_fx", pos.x, pos.y, pos.z)
        chasni_spawnprefab("ckc_icestaffburst2_fx", pos.x + 2, pos.y, pos.z - 2)
        chasni_spawnprefab("ckc_icestaffburst2_fx", pos.x - 2, pos.y, pos.z + 2)
        chasni_spawnprefab("ckc_icestaffburst2_fx", pos.x + 2, pos.y, pos.z + 2)
        chasni_spawnprefab("ckc_icestaffburst2_fx", pos.x - 2, pos.y, pos.z - 2)
        if #players <= 0 then
            owner.components.talker:Say(GetString(owner, "CRABSTAFF_ICE_FAIL"))
            return false, "NO_PLAYER"
        end
        for _, player in ipairs(players) do
            if not player.components.health:IsDead() and not player:HasTag("playerghost") and not player:HasTag("_coldembraced") and player.sg:HasState("coldembrace") then
                player.sg:GoToState("coldembrace")
                player.sg:SetTimeout(COLDEMBRACE_DURATION)
                player.components.freezable:SpawnShatterFX()

                player._coldembracetask = player:DoPeriodicTask(HEAL_TICK, function(p)
                    if p.components.health and not player.components.health:IsDead() and not player:HasTag("playerghost") then
                        local maxhealth = p.components.health:GetMaxWithPenalty()
                        local currenthealth = p.components.health.currenthealth
                        local healing = BASE_HEAL + (HEAL_PERCENTAGE * maxhealth)
                        if currenthealth + healing > maxhealth then
                            healing = currenthealth + healing - maxhealth
                        end
                        if maxhealth == currenthealth then
                            healing = 0
                        end
                        if healing > 0 then
                            p.components.health:DoDelta(healing)
                            p._coldembracetotaldamage = (p._coldembracetotaldamage or 0) + healing
                        end
                    end
                end)

                player:DoTaskInTime(COLDEMBRACE_DURATION, function(p)
                    p.components.freezable:SpawnShatterFX()
                    local px, py, pz = p.Transform:GetWorldPosition()
                    chasni_spawnprefab("ckc_icestaffburst_fx", px, py, pz, 1.5,1.5,1.5)
                    if p.components.temperature then
                        p.components.temperature:DoDelta(TEMP_DELTA)
                    end
                    local pt = p:GetPosition()
                    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, BLAST_RANGE, nil, TARGET_CANT_TAG, nil)
                    for _, ent in ipairs(ents) do
                        if ent.components.combat then
                            local damage = p._coldembracetotaldamage and p._coldembracetotaldamage > 0 and p._coldembracetotaldamage * DAMAGE_MULT or 0
                            ent.components.combat:GetAttacked(p, BASE_DAMAGE + (damage))
                            p._coldembracetotaldamage = 0
                        end
                        if ent.components.freezable then
                            ent.components.freezable:AddColdness(COLDNESS)
                            ent.components.freezable:SpawnShatterFX()
                        end
                    end
                    if p._coldembracetask then
                        p._coldembracetask:Cancel()
                    end
                end)
            end
        end

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
    return false
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

    inst.AnimState:SetBank("chasni_staffice")
    inst.AnimState:SetBuild("chasni_staffice")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("weapon")
    inst:AddTag("quickcast")

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
    inst._fxswap = SpawnPrefab("crabstaff_ice_fx")
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
    inst.components.inventoryitem.imagename = "chasni_staffice"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_staffice.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.quickcast = true
    inst.components.spellcaster:SetCanCastFn(function() return true  end)
    inst.components.spellcaster:SetSpellFn(oncast)

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

    inst.AnimState:SetBank("chasni_staffice")
    inst.AnimState:SetBuild("chasni_staffice")
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
Prefab("crabstaff_ice", fn, assets, prefabs),
Prefab("crabstaff_ice_fx", fxfn, assets)
