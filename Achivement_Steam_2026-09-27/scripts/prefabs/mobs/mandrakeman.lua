local brain = require "brains/chasni_mandrakemanbrain"

local assets =
{
    Asset("ANIM", "anim/elderdrake_basic.zip"),
    Asset("ANIM", "anim/elderdrake_actions.zip"),
    Asset("ANIM", "anim/elderdrake_attacks.zip"),
    Asset("ANIM", "anim/elderdrake_build.zip"),
}

local prefabs =
{
    "mandrake_planted",
    "plantmeat",
}

SetSharedLootTable("chasni_mandrakeman", {
    {"mandrake_planted",       1.0},
    {"plantmeat",              0.5},
    {"plantmeat",              0.3},

    {"jellybean_green",        0.1},
})

local PANIC_THRESH = .333
local HEALTH = chasni_getmobconfig("chasni_mandrakeman", "HP") or 550
local HEALTH_REGEN_PERIOD = 1
local HEALTH_REGEN_AMOUNT = chasni_getmobconfig("chasni_mandrakeman", "HP_RGN") or 25
local DAMAGE = chasni_getmobconfig("chasni_mandrakeman", "DMG") or 34
local ATTACK_PERIOD = 1
local ATTACK_RANGE = 2.5
local SPEED = 3
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 5
local SLEEP_TIME = 5
local SLEEP_TIME_DEATH = 60
local SLEEP_VALUE = 1
local SLEEP_VALUE_DEATH = 10
local SLEEP_RANGE = 15
local function KeepTarget(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    if data and data.attacker then
        if data.attacker.components.sleeper then
            data.attacker.components.sleeper:AddSleepiness(SLEEP_VALUE, SLEEP_TIME, inst)
        end
        if data.attacker.components.grogginess then
            data.attacker.components.grogginess:AddGrogginess(SLEEP_VALUE, SLEEP_TIME)
        end
    end

    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "mandrakeman", SHARETARGET_MAX)
end


local function ontalk(inst, script)
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/no", nil, 0.8)
end

local function giveupstring(combatcmp, target)
    return STRINGS.MANDRAKEMAN_GIVEUP[math.random(#STRINGS.MANDRAKEMAN_GIVEUP)]
end

local function battlecry(combatcmp, target)
    if target and target.components.inventory then
        local item = target.components.inventory:FindItem(function(item) return item:HasTag("mandrake") end)
        if item then
            return STRINGS.MANDRAKEMAN_MANDRAKE_BATTLECRY[math.random(#STRINGS.MANDRAKEMAN_MANDRAKE_BATTLECRY)]
        end
    end
    return STRINGS.MANDRAKEMAN_BATTLECRY[math.random(4)]
end

local function DoAreaSleep(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/death")
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, SLEEP_RANGE)
    for k,v in pairs(ents) do
        if v.components.sleeper then
            v.components.sleeper:AddSleepiness(SLEEP_VALUE_DEATH, SLEEP_TIME_DEATH)
        end
        if v:HasTag("player") then
            v:PushEvent("yawn", { grogginess = SLEEP_VALUE_DEATH, knockoutduration = SLEEP_TIME_DEATH })
        end
    end
end

local function transform(inst, angry)
    if angry then
        inst.AnimState:Show("head_angry")
        inst.AnimState:Hide("head_happy")
        inst:AddTag("angry")
    else
        inst.AnimState:Hide("head_angry")
        inst.AnimState:Show("head_happy")
        inst.sg:GoToState("happy")
        inst:RemoveTag("angry")
    end
end

local function transformtest(inst)
    inst:DoTaskInTime(1+(math.random()*1) , function()
        if TheWorld.state.isfullmoon and TheWorld.state.isnight then
            transform(inst)
        else
            transform(inst,true)
        end
    end)
end

local function OnWake(inst)
    transformtest(inst)
end

local function ShouldSleep(inst)
    if TheWorld.state.isfullmoon then return false end
end

local function CalcSanityAura(inst, observer)
    if inst:HasTag("angry") then
        return -TUNING.SANITYAURA_MED
    end
    return TUNING.SANITYAURA_MED
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetFourFaced()
    --inst.Transform:SetScale(1.25, 1.25, 1.25)
    MakeCharacterPhysics(inst, 50, .5)

    inst.AnimState:SetBank("elderdrake")
    inst.AnimState:SetBuild("elderdrake_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("head_happy")

    inst:AddTag("animal")
    inst:AddTag("mandrake")
    inst:AddTag("mandrakeman")
    inst:AddTag("angry")
    inst:AddTag("epic")

    inst:AddComponent("talker")
    inst.components.talker.ontalk = ontalk
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0,-500,0)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat.panic_thresh = PANIC_THRESH
    inst.components.combat.GetBattleCryString = battlecry
    inst.components.combat.GetGiveUpString = giveupstring

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)
    inst.components.health:StartRegen(HEALTH_REGEN_AMOUNT, HEALTH_REGEN_PERIOD)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_mandrakeman")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(10)
    inst.components.sleeper.nocturnal = true
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("inspectable")
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })

    MakeHauntablePanic(inst)
    MakeMediumFreezableCharacter(inst)
    MakeSmallBurnableCharacter(inst, "torso")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", DoAreaSleep)
    inst:WatchWorldState("isdusk", transformtest)
    inst:WatchWorldState("isnight", transformtest)

    inst.OnEntityWake = OnWake

    inst:SetStateGraph("SGCZmandrakeman")
    inst:SetBrain(brain)

    inst:DoTaskInTime(0.2, function(inst) transformtest(inst) end)

    return inst
end

return Prefab("chasni_mandrakeman", fn, assets, prefabs) 
