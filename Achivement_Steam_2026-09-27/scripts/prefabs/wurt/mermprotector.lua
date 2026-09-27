local brain = require "brains/chasni_mermprotectorbrain"

local assets =
{
    Asset("ANIM", "anim/merm_fisherman_build.zip"),
    Asset("ANIM", "anim/ds_pig_basic.zip"),
    Asset("ANIM", "anim/ds_pig_actions.zip"),
    Asset("ANIM", "anim/ds_pig_attacks.zip"),
    Asset("ANIM", "anim/merm_fishing.zip"),
    Asset("SOUND", "sound/merm.fsb"),
}

local loot =
{
    "pondfish",
    "froglegs",
}

local sounds =
{
    attack = "dontstarve/creatures/merm/attack",
    hit = "dontstarve/creatures/merm/hurt",
    death = "dontstarve/creatures/merm/death",
    talk = "dontstarve/creatures/merm/idle",
    buff = "dontstarve/characters/wurt/merm/warrior/yell",
}

local SLIGHTDELAY = 1
local TARGET_DIST = 1
local FOLLOW_DIST = 40
local ATTACK_ALERT = 25
local SHARE_TARGET_DIST = 40
local MAX_TARGET_SHARES = 5
local DEFAULT_HEALTH = chasni_getmobconfig("mermprotector", "HP") or 300
local DEFAULT_DAMAGE = chasni_getmobconfig("mermprotector", "DMG") or 30
local KING_HEALTH = chasni_getmobconfig("mermprotector", "HP2") or 1500
local KING_DAMAGE = chasni_getmobconfig("mermprotector", "DMG2") or 100
local MUTE_TALK = chasni_getmobconfig("mermprotector", "MUTE") or false
local RUN_SPEED = 7
local WALK_SPEED = 4
local HEALT_REGEN = 5
local HEALT_REGEN_PERIOD = 1
local ATTACK_PERIOD = 1.5
local WURT_TAG = { "expertwurt2" }

local function ontalk(inst, script)
    if not MUTE_TALK then
        inst.SoundEmitter:PlaySound(inst.sounds.talk)
    end
end

local function FindInvaderFn(guy, inst)
    if guy.components.combat and guy.components.combat:HasTarget() and guy.components.combat.target:HasTag('merm') then
        return true
    end

    local leader = inst.components.follower and inst.components.follower.leader

    local leader_guy = guy.components.follower and guy.components.follower.leader
    if leader_guy and leader_guy.components.inventoryitem then
        leader_guy = leader_guy.components.inventoryitem:GetGrandOwner()
    end

    return (guy:HasTag("character") and not (guy:HasTag("merm"))) and
            not ((TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:HasKingAnywhere())) and
            not (leader and leader:HasTag("player")) and
            not (leader_guy and (leader_guy:HasTag("merm")) and
                    not guy:HasTag("pig") and
                    not guy:HasTag("wonkey"))
end

local function RetargetFn(inst)
    if inst:HasTag("NPC_contestant") then
        return nil
    end
    return FindEntity(inst, SpringCombatMod(TARGET_DIST), FindInvaderFn)
end

local function KeepTargetFn(inst, target)
    local distsq = FOLLOW_DIST * FOLLOW_DIST
    return inst.components.combat:CanTarget(target) and target:GetPosition():DistSq(inst:GetPosition()) < distsq
end

local DECIDROOTTARGET_MUST_TAGS = { "_combat", "_health", "merm" }
local DECIDROOTTARGET_CANT_TAGS = { "INLIMBO" }
local function OnAttackedByDecidRoot(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, SpringCombatMod(SHARE_TARGET_DIST) * .5, DECIDROOTTARGET_MUST_TAGS, DECIDROOTTARGET_CANT_TAGS)
    local num_helpers = 0

    for i, v in ipairs(ents) do
        if v ~= inst and not v.components.health:IsDead() then
            v:PushEvent("suggest_tree_target", { tree = attacker })
            num_helpers = num_helpers + 1
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end
        end
    end
end

local HOUSE_TAGS = {"mermhouse"}
local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    local leader = inst.components.follower and inst.components.follower.leader
    if attacker and attacker == leader then
        return
    end
    if attacker and attacker.prefab == "deciduous_root" and attacker.owner then
        OnAttackedByDecidRoot(inst, attacker.owner)

    elseif attacker and inst.components.combat:CanTarget(attacker) and attacker.prefab ~= "deciduous_root" then
        inst.components.combat:SetTarget(attacker)

        local pt = inst:GetPosition()
        local homes = TheSim:FindEntities(pt.x, pt.y, pt.z, ATTACK_ALERT, HOUSE_TAGS, chasni_TAG_NOTARGET)

        for k,v in pairs(homes) do
            if v and v.components.childspawner then
                v.components.childspawner:ReleaseAllChildren(attacker)
            end
        end

        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(friend)
            return friend:HasTag("mermprotector")
        end, MAX_TARGET_SHARES)
    end
end

local function OnNewTarget(inst, data)
    if data and data.target then
        inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(friend)
            return friend:HasTag("mermprotector")
        end, MAX_TARGET_SHARES)
    end

end

local function SuggestTreeTarget(inst, data)
    local ba = inst:GetBufferedAction()
    if data and data.tree and (ba == nil or ba.action ~= ACTIONS.CHOP) then
        inst.tree_target = data.tree
    end
end

local function RoyalUpgrade(inst)
    if not inst.components.health:IsDead() then
        inst.components.health:SetMaxHealth(KING_HEALTH)
        inst.components.combat:SetDefaultDamage(KING_DAMAGE)
        inst.Transform:SetScale(1.5, 1.5, 1.5)
    end
end

local function RoyalDowngrade(inst)
    if not inst.components.health:IsDead() then
        inst.components.health:SetMaxHealth(DEFAULT_HEALTH)
        inst.components.combat:SetDefaultDamage(DEFAULT_DAMAGE)
        inst.Transform:SetScale(1, 1, 1)
    end
end

local function ResolveMermChatter(inst, strid, strtbl)
    local stringtable = STRINGS[strtbl:value()]
    if stringtable then
        if stringtable[strid:value()] then
            if ThePlayer and ThePlayer:HasTag("mermfluent") then
                return stringtable[strid:value()][1]
            else
                return stringtable[strid:value()][2]
            end
        end
    end
end

local function ondeath(inst)
    local leader = inst.components.follower and inst.components.follower.leader or inst._wurt
    if leader and leader.components.mermprotectorspawner then
        leader.components.mermprotectorspawner:ReSpawnProtector()
    end
end

local function ShouldSleep(inst) return false end
local function ShouldWake(inst) return true end

local function OnTimerDone(inst, data)
    if data.name == "facetime" then
        inst.components.timer:StartTimer("dontfacetime", 10)
    end
end

local function StopFindLeaderTask(inst)
    if inst._findleadertask then
        inst._findleadertask:Cancel()
        inst._findleadertask = nil
    end
end

local function FindNewLeader(inst)
    inst.components.follower:SetLeader(inst._wurt)
    StopFindLeaderTask(inst)
end

local function StartFindLeaderTask(inst)
    if inst._findleadertask == nil then
        inst._findleadertask = inst:DoPeriodicTask(1, FindNewLeader)
    end
end

local function battlecry(combatcmp, target)
    local strtbl =
    combatcmp.inst:HasTag("guard") and
            "MERM_BATTLECRY" or
            "MERM_BATTLECRY"
    return strtbl, math.random(#STRINGS[strtbl])
end

local function IsAbleToAccept(inst, item, giver)
    if inst.components.health and inst.components.health:IsDead() then
        return false, "DEAD"
    elseif inst.sg and inst.sg:HasStateTag("busy") then
        if inst.sg:HasStateTag("sleeping") then
            return true
        else
            return false, "BUSY"
        end
    else
        return true
    end
end

local function ShouldAcceptItem(inst, item, giver)
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end

    return item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.components.equippable and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")

    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function OnLoad(inst, data)
    local leader = inst.components.follower and inst.components.follower.leader
    if leader then
        inst._wurt = leader
    else
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("pigman")
    inst.AnimState:Hide("hat")
    inst.AnimState:SetBuild("merm_fisherman_build")

    inst.sounds = sounds

    inst:AddTag("character")
    --inst:AddTag("merm") -- cannot be mermking
    --inst:AddTag("mermguard") -- cannot be mermking
    inst:AddTag("merm_npc")
    inst:AddTag("mermprotector")
    inst:AddTag("wet")
    inst:AddTag("companion")
    inst:AddTag("notraptrigger")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -400, 0)
    inst.components.talker.resolvechatterfn = ResolveMermChatter
    inst.components.talker:MakeChatter()

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.talker.ontalk = ontalk

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = RUN_SPEED
    inst.components.locomotor.walkspeed = WALK_SPEED
    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")
    inst:AddComponent("timer")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.VEGETARIAN }, { FOODGROUP.VEGETARIAN })
    inst:AddComponent("foodaffinity")
    inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.VEGGIE, 1)
    inst.components.foodaffinity:AddPrefabAffinity  ("kelp",          1) -- prevents the negative stats
    inst.components.foodaffinity:AddPrefabAffinity  ("kelp_cooked",   1) -- prevents the negative stats
    inst.components.foodaffinity:AddPrefabAffinity  ("durian",        1) -- prevents the negative stats
    inst.components.foodaffinity:AddPrefabAffinity  ("durian_cooked", 1) -- prevents the negative stats

    inst:AddComponent("health")
    inst.components.health:StartRegen(HEALT_REGEN, HEALT_REGEN_PERIOD)
    inst.components.health:SetMaxHealth(DEFAULT_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat.GetBattleCryString = battlecry
    inst.components.combat.hiteffectsymbol = "pig_torso"
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetDefaultDamage(DEFAULT_DAMAGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetNoAggroTags(WURT_TAG)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:AddComponent("follower")
    inst.components.follower:CancelLoyaltyTask()
    inst.components.follower.keepdeadleader = true

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetNocturnal(false)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    local trader = inst:AddComponent("trader")
    trader:SetAcceptTest(ShouldAcceptItem)
    trader:SetAbleToAcceptTest(IsAbleToAccept)
    trader.onaccept = OnGetItemFromPlayer
    trader.onrefuse = OnRefuseItem
    trader.deleteitemonaccept = false

    MakeMediumBurnableCharacter(inst, "pig_torso")
    MakeMediumFreezableCharacter(inst, "pig_torso")

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("suggest_tree_target", SuggestTreeTarget)
    inst:ListenForEvent("startfollowing", StopFindLeaderTask)
    inst:ListenForEvent("stopfollowing", StartFindLeaderTask)
    inst:ListenForEvent("loseloyalty", StartFindLeaderTask)
    inst:ListenForEvent("stopfollowing", StartFindLeaderTask)
    inst:ListenForEvent("onmermkingcreated_anywhere", function()
        inst:DoTaskInTime(math.random()*SLIGHTDELAY,function()
            RoyalUpgrade(inst)
        end)
    end, TheWorld)
    inst:ListenForEvent("onmermkingdestroyed_anywhere", function()
        inst:DoTaskInTime(math.random()*SLIGHTDELAY,function()
            RoyalDowngrade(inst)
        end)
    end, TheWorld)

    if TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:HasKingAnywhere() then
        RoyalUpgrade(inst)
    else
        RoyalDowngrade(inst)
    end

    inst:ListenForEvent("death", ondeath)

    inst:SetStateGraph("SGmerm")
    inst:SetBrain(brain)

    inst.OnLoad = OnLoad

    return inst
end

return Prefab("mermprotector", fn, assets)