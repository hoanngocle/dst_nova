local brain = require "brains/chasni_wargfantbrain"

local assets =
{
    Asset("ANIM", "anim/wargfant.zip"),

    Asset("IMAGE", "images/minimap/wargfant.tex"),
    Asset("ATLAS", "images/minimap/wargfant.xml"),
}

local prefabs =
{
    "hound",
    "icehound",
    "firehound",
    "monstermeat",
    "houndstooth",
    "wargfant_firering",
}

SetSharedLootTable("chasni_wargfant", {
    {"monstermeat",             1.00},
    {"monstermeat",             1.00},
    {"monstermeat",             1.00},
    {"monstermeat",             0.50},
    {"chasni_wargfant_tooth",   1.00},
    {"chasni_wargfant_tooth",   1.00},
    {"chasni_wargfant_tooth",   1.00},
    {"chasni_wargfant_tooth",   0.50},
    {"chasni_wargfant_fur",     1.00},
    {"chasni_wargfant_fur",     1.00},
    {"chasni_wargfant_fur",     1.00},
    {"chasni_wargfant_fur",     0.50},
    {"trunk_summer",            0.50},
    {"trunk_winter",            0.50},

    {"jellybean_yellow",        0.10},
})

local HEALTH = chasni_getmobconfig("chasni_wargfant", "HP") or 3200
local DAMAGE = chasni_getmobconfig("chasni_wargfant", "DMG") or 70
local ATTACK_PERIOD = 3
local ATTACK_RANGE = 4
local SPEED = 5
local RETARGET_PERIOD = 5
local RETARGET_RANGE = 30
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "wall", "warg", "wargfant", "hound" }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 10
local SHARETARGET_MAX = 40
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "hound", SHARETARGET_MAX)
end

local TARGETS_MUST_TAGS = { "player" }
local TARGETS_CANT_TAGS = { "playerghost" }
local function NumHoundsToSpawn(inst)
    local numHounds = 4
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, TUNING.WARG_NEARBY_PLAYERS_DIST, TARGETS_MUST_TAGS, TARGETS_CANT_TAGS)
    for i,player in ipairs(ents) do
        local playerAge = player.components.age:GetAgeInDays()
        local addHounds = math.clamp(Lerp(1, 4, playerAge/100), 1, 4)
        numHounds = numHounds + addHounds
    end
    local numFollowers = inst.components.leader:CountFollowers()
    local num = math.min(numFollowers+numHounds/2, numHounds) -- only spawn half the hounds per howl
    num = (math.log(num)/0.4)+1 -- 0.4 is approx log(1.5)
    num = RoundToNearest(num, 1)
    return num - numFollowers
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetSixFaced()
    MakeCharacterPhysics(inst, 1000, 1)

    inst:AddTag("monster")
    inst:AddTag("warg")
    inst:AddTag("scarytoprey")
    inst:AddTag("houndfriend")
    inst:AddTag("largecreature")
    inst:AddTag("epic")

    inst.AnimState:SetBank("wargfant_actions")
    inst.AnimState:SetBuild("wargfant")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/vargr/hit")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2
    inst.components.locomotor:SetShouldRun(true)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_wargfant")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("leader")

    MakeLargeBurnableCharacter(inst)
    MakeLargeFreezableCharacter(inst)

    inst.NumHoundsToSpawn = NumHoundsToSpawn
    inst.base_hound_num = TUNING.WARG_BASE_HOUND_AMOUNT

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZwargfant")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_wargfant", fn, assets, prefabs)