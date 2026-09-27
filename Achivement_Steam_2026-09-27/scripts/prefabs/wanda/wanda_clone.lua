local brain = require "brains/chasni_wandaclonebrain"

local assets = {
}

local RETARGET_PERIOD = 1
local RETARGET_RANGE = 15
local RETARGET_MUST_TAGS = { "character", "_combat" }
local KEEPTARGET_RANGE = 40
local CLONE_DURATION = 180
local EVILCLONE_DURATION = 60
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, chasni_TAG_NOATTACK)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function CopySkin(inst, player)
    if inst.components.skinner then
        inst.components.skinner:CopySkinsFromPlayer(player)
    end
end

local function GetHopDistance(inst, speed_mult)
    return speed_mult < 0.8 and TUNING.WILSON_HOP_DISTANCE_SHORT
            or speed_mult >= 1.2 and TUNING.WILSON_HOP_DISTANCE_FAR
            or TUNING.WILSON_HOP_DISTANCE
end

local function GetStatus(inst, viewer)
    return (inst:HasTag("playerghost") and "GHOST")
            or (inst.hasRevivedPlayer and "REVIVER")
            or (inst.hasKilledPlayer and "MURDERER")
            or (inst.hasAttackedPlayer and "ATTACKER")
            or (inst.hasStartedFire and "FIRESTARTER")
            or nil
end

local function TryDescribe(descstrings, modifier)
    return descstrings and (
            type(descstrings) == "string" and
                    descstrings or
                    descstrings[modifier] or
                    descstrings.GENERIC
    ) or nil
end

local function TryCharStrings(inst, charstrings, modifier)
    return charstrings and (
            TryDescribe(charstrings.DESCRIBE[string.upper(inst.prefab)], modifier) or
                    TryDescribe(charstrings.DESCRIBE.PLAYER, modifier)
    ) or nil
end

local function GetDescription(inst, viewer)
    local modifier = inst.components.inspectable:GetStatus(viewer) or "GENERIC"
    return string.format(
            TryCharStrings(inst, STRINGS.CHARACTERS[string.upper(viewer.prefab)], modifier) or
                    TryCharStrings(inst, STRINGS.CHARACTERS.GENERIC, modifier),
            "Phân thân Wanda"
    )
end
local function createClone(type, weapon, hat)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        inst.DynamicShadow:SetSize(6, 2)
        inst.Transform:SetFourFaced()
        MakeCharacterPhysics(inst, 100, .5)

        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("wilson")
        inst.AnimState:PlayAnimation("idle_loop", true)

        inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
        inst.AnimState:SetMultColour(1, 1, 1, 0.5)
        inst.AnimState:UsePointFiltering(true)

        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Hide("HAT")
        inst.AnimState:Hide("HAIR_HAT")
        inst.AnimState:Show("HAIR_NOHAT")
        inst.AnimState:Show("HAIR")
        inst.AnimState:Show("HEAD")
        inst.AnimState:Hide("HEAD_HAT")

        if type then
            inst:AddTag("clone_"..type)
        end

        inst.CopySkin = CopySkin

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
        inst.components.combat.hiteffectsymbol = "torso"
        inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
        inst.components.combat:SetRange(TUNING.DEFAULT_ATTACK_RANGE)
        inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
        inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

        inst:AddComponent("locomotor")
        inst.components.locomotor.walkspeed = type == "evil" and (TUNING.WILSON_WALK_SPEED - 1) or TUNING.WILSON_WALK_SPEED
        inst.components.locomotor.runspeed = type == "evil" and (TUNING.WILSON_RUN_SPEED - 2) or TUNING.WILSON_RUN_SPEED
        inst.components.locomotor.fasteronroad = true
        inst.components.locomotor.pathcaps = { player = true, ignorecreep = true }
        inst.components.locomotor:SetAllowPlatformHopping(true)
        inst.components.locomotor:EnableHopDelay(true)
        inst.components.locomotor:SetTriggersCreep(true)
        inst.components.locomotor.hop_distance_fn = GetHopDistance

        inst:AddComponent("inventory")
        inst:AddComponent("drownable")
        inst:AddComponent("timer")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.getspecialdescription = GetDescription

        inst:AddComponent("embarker")
        inst.components.embarker.embark_speed = TUNING.WILSON_RUN_SPEED

        inst:AddComponent("skinner")
        inst.components.skinner:SetupNonPlayerData()

        inst:AddComponent("follower")
        inst.components.follower:CancelLoyaltyTask()
        inst.components.follower.keepdeadleader = true

        inst:AddComponent("efficientuser")
        inst.components.efficientuser:AddMultiplier(ACTIONS.CHOP,     0, inst)
        inst.components.efficientuser:AddMultiplier(ACTIONS.MINE,     0, inst)
        inst.components.efficientuser:AddMultiplier(ACTIONS.ATTACK,   0, inst)

        inst:SetStateGraph("SGCZWandaClone")
        inst:SetBrain(brain)

        if weapon then
            local handslot = SpawnPrefab(weapon)
            inst.components.inventory:GiveItem(handslot)
            inst.components.inventory:Equip(handslot)
        end
        if hat then
            local headslot = SpawnPrefab(hat)
            inst.components.inventory:GiveItem(headslot)
            inst.components.inventory:Equip(headslot)
        end

        inst._owner = nil
        inst.persists = false
        inst.sg:GoToState("pocketwatch_portal_land")
        inst:DoTaskInTime(type == "evil" and EVILCLONE_DURATION or CLONE_DURATION, function(inst)
            inst.sg:GoToState("pocketwatch_warpback_pre")
            inst:ListenForEvent("animover", inst.Remove)
        end)

        return inst
    end
    return Prefab("wanda_clone_" .. type, fn, assets)
end

return
createClone("miner", "pickaxe", "minerhat"),
createClone("chopper", "axe", "strawhat"),
createClone("worker", "multitool_axe_pickaxe", "ruinshat"),
createClone("fighter", "pocketwatch_weapon", "footballhat"),
createClone("normal", nil, "flowerhat"),
createClone("evil", "nightsword", "skeletonhat")