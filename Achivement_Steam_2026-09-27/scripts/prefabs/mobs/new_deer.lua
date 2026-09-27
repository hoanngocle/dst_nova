local assets1 =
{
    Asset("ANIM", "anim/deer_build_yellow_green.zip"),
    Asset("ANIM", "anim/deer_basic.zip"),
    Asset("ANIM", "anim/deer_action.zip"),
}

local assets2 =
{
    Asset("ANIM", "anim/deer_build_orange_red.zip"),
    Asset("ANIM", "anim/deer_basic.zip"),
    Asset("ANIM", "anim/deer_action.zip"),
}

local greenprefabs =
{
    "greengem",
    "meat",
    "deer_green_charge",
    "deer_unshackle_fx",
    "deer_green_circle"
}

local yellowprefabs =
{
    "yellowgem",
    "meat",
    "deer_yellow_charge",
    "deer_unshackle_fx",
    "deer_yellow_circle"
}

local orangeprefabs =
{
    "orangegem",
    "meat",
    "deer_orange_charge",
    "deer_unshackle_fx",
    "deer_orange_circle"
}

local purpleprefabs =
{
    "purplegem",
    "meat",
    "deer_orange_charge",
    "deer_unshackle_fx",
    "deer_purple_circle"
}

local brain_gemmed = require("brains/deergemmedbrain")

local function KeepTargetFn(inst, target)
    return target:IsValid() and inst:IsNear(target, TUNING.DEER_ATTACKER_REMEMBER_DIST)
end

local function ShareTargetFn(dude)
    return dude:HasTag("deer") and not dude.components.health:IsDead()
end

local function GemmedShouldSleep(inst) return false end
local function GemmedShouldWake(inst) return true end

local SPELL_OVERLAP_MIN = 3
local SPELL_OVERLAP_MAX = 6
local NOSPELLOVERLAP_ONEOF_TAGS = { "deer_ice_circle", "deer_fire_circle" }
local function NoSpellOverlap(x, y, z, r)
    return #TheSim:FindEntities(x, 0, z, r or SPELL_OVERLAP_MIN, nil, nil, NOSPELLOVERLAP_ONEOF_TAGS) <= 0
end

--Hard limit target list size since casting does multiple passes it
local SPELL_MAX_TARGETS = 20
local SPELLTARGET_MUST_TAGS = { "_combat", "_health" }
local SPELLTARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "playerghost", "deergemresistance" }
local function FindCastTargets(inst, target)
    if target then
        return target.components.health
                and not (target.components.health:IsDead() or
                target:HasTag("playerghost") or
                target:HasTag("deergemresistance"))
                and target:IsNear(inst, TUNING.DEER_GEMMED_CAST_RANGE)
                and NoSpellOverlap(target.Transform:GetWorldPosition())
                and { target }
                or nil
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = {}
    local priorityindex = 1
    for i, v in ipairs(TheSim:FindEntities(x, y, z, TUNING.DEER_GEMMED_CAST_RANGE, SPELLTARGET_MUST_TAGS, SPELLTARGET_CANT_TAGS)) do
        if not v.components.health:IsDead() then
            if v:HasTag("player") then
                table.insert(targets, priorityindex, v)
                if #targets >= SPELL_MAX_TARGETS then
                    return targets
                end
                priorityindex = priorityindex + 1
            elseif v.components.combat.target and v.components.combat.target:HasTag("deergemresistance") then
                table.insert(targets, v)
                if #targets >= SPELL_MAX_TARGETS then
                    return targets
                end
            end
        end
    end
    return #targets > 0 and targets or nil
end

local function SpawnSpell(inst, x, z)
    local spell = SpawnPrefab(inst.castfx)
    spell.Transform:SetPosition(x, 0, z)
    spell:DoTaskInTime(inst.castduration, spell.KillFX)
    return spell
end

local function SpawnSpells(inst, targets)
    local spells = {}
    local nextpass = {}
    for i, v in ipairs(targets) do
        if v:IsValid() and v:IsNear(inst, TUNING.DEER_GEMMED_CAST_MAX_RANGE) then
            local x, y, z = v.Transform:GetWorldPosition()
            if NoSpellOverlap(x, 0, z, SPELL_OVERLAP_MAX) then
                table.insert(spells, SpawnSpell(inst, x, z))
                if #spells >= TUNING.DEER_GEMMED_MAX_SPELLS then
                    return spells
                end
            else
                table.insert(nextpass, { x = x, z = z })
            end
        end
    end
    if #nextpass <= 0 then
        return spells
    end
    for range = SPELL_OVERLAP_MAX - 1, SPELL_OVERLAP_MIN, -1 do
        local i = 1
        while i <= #nextpass do
            local v = nextpass[i]
            if NoSpellOverlap(v.x, 0, v.z, range) then
                table.insert(spells, SpawnSpell(inst, v.x, v.z))
                if #spells >= TUNING.DEER_GEMMED_MAX_SPELLS or #nextpass <= 1 then
                    return spells
                end
                table.remove(nextpass, i)
            else
                i = i + 1
            end
        end
    end
    return #spells > 0 and spells or nil
end

local function DoCast(inst, targets)
    local spells = targets and SpawnSpells(inst, targets) or nil
    inst.components.timer:StopTimer("deercast_cd")
    inst.components.timer:StartTimer("deercast_cd", spells and inst.castcd or TUNING.DEER_GEMMED_FIRST_CAST_CD)
    return spells
end

local function OnNewTarget(inst, data)
    if data.target then
        inst:SetEngaged(true)
    end
end

local function IsDeadKeeper(keeper)
    return (keeper.IsUnchained == nil or keeper:IsUnchained())
            and keeper.components.health
            and keeper.components.health:IsDead()
end

local function GemmedRetargetFn(inst)
    local keeper = inst.components.entitytracker:GetEntity("keeper")
    return keeper
            and not IsDeadKeeper(keeper)
            and keeper.components.combat
            and keeper.components.combat.target
            or nil
end

local function GemmedOnAttacked(inst, data)
    local keeper = inst.components.entitytracker:GetEntity("keeper")
    if keeper == nil or not IsDeadKeeper(keeper) then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, 12, ShareTargetFn, 3)
    end
end

local function SetEngaged(inst, engaged)
    --NOTE: inst.engaged is nil at instantiation, and engaged must not be nil
    if inst.engaged ~= engaged then
        inst.engaged = engaged
        inst.components.timer:StopTimer("deercast_cd")
        if engaged then
            inst.components.timer:StartTimer("deercast_cd", TUNING.DEER_GEMMED_FIRST_CAST_CD)
            inst:RemoveEventCallback("newcombattarget", OnNewTarget)
        else
            inst:ListenForEvent("newcombattarget", OnNewTarget)
        end
    end
end

local function OnGotCommander(inst, data)
    local keeper = inst.components.entitytracker:GetEntity("keeper")
    if keeper ~= data.commander then
        inst.components.entitytracker:ForgetEntity("keeper")
        inst.components.entitytracker:TrackEntity("keeper", data.commander)

        inst.components.knownlocations:RememberLocation("keeperoffset", inst:GetPosition() - data.commander:GetPosition(), false)
        inst:AddTag("notaunt")
    end
end

local function OnLostCommander(inst, data)
    local keeper = inst.components.entitytracker:GetEntity("keeper")
    if keeper == data.commander then
        inst.components.entitytracker:ForgetEntity("keeper")
        inst.components.knownlocations:ForgetLocation("keeperoffset")
        inst:RemoveTag("notaunt")
    end
end

local function GemmedOnLoadPostPass(inst)
    local keeper = inst.components.entitytracker:GetEntity("keeper")
    if keeper and keeper.components.commander then
        keeper.components.commander:AddSoldier(inst)
    end
end

local function OnUpdateOffset(inst, offset)
    inst.components.knownlocations:RememberLocation("keeperoffset", offset)
end

--------------------------------------------------------------------------

local function DoChainIdleSound(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/chain_idle", nil, volume)
end

local function DoBellIdleSound(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell_idle", nil, volume)
end

local function DoChainSound(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/chain", nil, volume)
end

local function DoBellSound(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell", nil, volume)
end

local function SetupSounds(inst)
    inst.DoChainSound = DoChainSound
    inst.DoChainIdleSound = DoChainIdleSound
    inst.DoBellSound = DoBellSound
    inst.DoBellIdleSound = DoBellIdleSound
end

--------------------------------------------------------------------------

local function getstatus(inst)
    return inst.charged and "ANTLER" or nil
end

local function common_fn(gem, build, castfx)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.75, .75)

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 100, .5)

    inst.AnimState:SetBank("deer")
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle_loop", true)

    if gem == "yellow" or gem == "orange" then
        inst.AnimState:OverrideSymbol("swap_antler_red", build, "swap_antler_blue") --yellow or orange use blue swap
    end
    inst.AnimState:OverrideSymbol("swap_neck_collar", build, "swap_neck_collar_winter")
    inst.AnimState:OverrideSymbol("klaus_deer_chain", build, "klaus_deer_chain_winter")
    inst:AddTag("deergemresistance")
    inst:SetPrefabNameOverride("deer_gemmed")

    inst:AddComponent("spawnfader")

    inst:AddTag("deer")
    inst:AddTag("animal")
    inst:AddTag("newklaus")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.gem = gem

    ------------------------------------------

    inst:AddComponent("timer")
    inst:AddComponent("knownlocations")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DEER_GEMMED_HEALTH / 2) -- DIFF

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.DEER_GEMMED_DAMAGE * 3) -- DIFF
    inst.components.combat.hiteffectsymbol = "deer_torso"
    inst.components.combat:SetRange(TUNING.DEER_ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.DEER_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetHurtSound("dontstarve/creatures/together/deer/hit")
    inst.components.combat:SetRetargetFunction(3, GemmedRetargetFn)
    inst:ListenForEvent("attacked", GemmedOnAttacked)
    SetEngaged(inst, false)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetSleepTest(GemmedShouldSleep)
    inst.components.sleeper:SetWakeTest(GemmedShouldWake)
    inst.components.sleeper.diminishingreturns = true
    inst.components.sleeper.testperiod = 1

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("deer")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.DEER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.DEER_RUN_SPEED

    MakeMediumBurnableCharacter(inst, "deer_torso")
    inst.components.burnable:SetBurnTime(TUNING.DEER_ICE_BURN_PANIC_TIME)
    MakeMediumFreezableCharacter(inst, "deer_torso")
    inst.components.freezable:SetResistance(1)
    inst.components.freezable:SetDefaultWearOffTime(TUNING.DEER_FIRE_FREEZE_WEAR_OFF_TIME)

    MakeHauntablePanic(inst)

    SetupSounds(inst)
    inst:SetStateGraph("SGdeer")

    inst:AddComponent("entitytracker")

    inst:ListenForEvent("gotcommander", OnGotCommander)
    inst:ListenForEvent("lostcommander", OnLostCommander)

    inst.castfx = castfx
    inst.castduration = 5
    inst.castcd = 5
    inst.SetEngaged = SetEngaged
    inst.FindCastTargets = FindCastTargets
    inst.DoCast = DoCast
    inst.OnLoadPostPass = GemmedOnLoadPostPass
    inst.OnUpdateOffset = OnUpdateOffset

    inst:SetBrain(brain_gemmed)

    return inst
end

local function greenfn()
    return common_fn("green", "deer_build_yellow_green", "deer_green_circle")
end

local function yellowfn()
    return common_fn("yellow", "deer_build_yellow_green", "deer_yellow_circle")
end

local function orangefn()
    return common_fn("orange", "deer_build_orange_red", "deer_orange_circle")
end

local function purplefn()
    return common_fn("purple", "deer_build_orange_red", "deer_purple_circle")
end

return 
Prefab("deer_green", greenfn, assets1, greenprefabs), 
Prefab("deer_yellow", yellowfn, assets1, yellowprefabs),
Prefab("deer_orange", orangefn, assets2, orangeprefabs),
Prefab("deer_purple", purplefn, assets2, purpleprefabs)
