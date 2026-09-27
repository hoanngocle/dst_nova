local brain = require "brains/chasni_ancientheraldbrain"

local assets =
{
    Asset("ANIM", "anim/ancient_spirit.zip"),
}

local prefabs =
{
    "chasni_laserring",
    "chasni_laserhit",
    "chasni_ancientherald_firerain",
    "shadowthrall_hands",
    "shadowthrall_horns",
    "shadowthrall_wings",
    "chasni_ancient_remnant",
    "voidcloth",
    "horrorfuel",
    "nightmarefuel",
}

SetSharedLootTable("chasni_ancientherald", {
    {"chasni_ancient_remnant",		1.00 },
    {"chasni_ancient_remnant",		1.00 },
    {"chasni_ancient_remnant",		0.33 },
    {"voidcloth",           		1.00 },
    {"voidcloth",           		1.00 },
    {"voidcloth",           		1.00 },
    {"voidcloth",           		1.00 },
    {"voidcloth",           		0.33 },
    {"horrorfuel",          		1.00 },
    {"horrorfuel",          	 	1.00 },
    {"horrorfuel",          	 	1.00 },
    {"horrorfuel",          	 	0.50 },
    {"nightmarefuel",           	1.00 },
    {"nightmarefuel",           	0.67 },
})

local HEALTH = chasni_getmobconfig("chasni_ancientherald", "HP") or 21000
local DAMAGE = chasni_getmobconfig("chasni_ancientherald", "DMG") or 5
local PLANAR_DAMAGE = chasni_getmobconfig("chasni_ancientherald", "PLN_DMG") or 80
local ATTACK_PERIOD = 4
local ATTACK_RANGE = 7
local SPEED = 4
local RETARGET_PERIOD = 5
local RETARGET_RANGE = 25
local RETARGET_MUST_TAGS = { "character", "_combat" }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 40
local SHARETARGET_MAX = 40
local ARMY_CHOICES =
{
    shadowthrall_hands = 0.25,
    shadowthrall_horns = 0.25,
    shadowthrall_wings = 0.25,
    shadowthrall_mouth = 0.25,
}
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, chasni_TAG_NOATTACK)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "shadowthrall", SHARETARGET_MAX)
end

local function getrandomoffset(pt)
    local theta = math.random() * 2 * PI
    local offset = FindWalkableOffset(pt, theta, 6, 12, true)
    if offset then
        return pt + offset
    end
end

local function DoAoeAttack(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local ring = SpawnPrefab("chasni_laserring")
    ring.Transform:SetPosition(x, y, z)
    ring.Transform:SetScale(1.2, 1.2, 1.2)

    for i, v in ipairs(TheSim:FindEntities(x, y, z, ATTACK_RANGE, nil, { "ancient_herald", "laser", "DECOR", "INLIMBO", "shadowthrall", "shadow_aligned" })) do
        if v:IsValid() and not v:HasTag("laser_immune") then
            if v.components.health and not v.components.health:IsDead() then
                inst.components.combat:DoAttack(v)
                if v.AnimState then
                    SpawnPrefab("chasni_laserhit"):SetTarget(v)
                end
            end
        end
    end
end

local function SpawnFireRain(inst)
    for i, v in ipairs(AllPlayers) do
        if v and v:IsValid() and v.components.health and not v.components.health:IsDead() then
            local count = math.random(3, 5)
            for _ = 1, count do
                local pt = Vector3(v.Transform:GetWorldPosition())
                local spawn_pt = getrandomoffset(pt)
                if spawn_pt then
                    local fire = SpawnPrefab("chasni_ancientherald_firerain")
                    fire.Transform:SetPosition(spawn_pt.x, spawn_pt.y, spawn_pt.z)
                    fire:StartStep()
                end
            end
        end
    end
end
local function SpawnThrall(inst)
    for _, v in ipairs(AllPlayers) do
        if v and v:IsValid() and v.components.health and not v.components.health:IsDead() then
            for i = 1, 2 do -- Loop twice to spawn two thralls
                local pt = Vector3(v.Transform:GetWorldPosition())
                local spawn_pt = getrandomoffset(pt)
                if spawn_pt then
                    local thrall = SpawnPrefab(weighted_random_choice(ARMY_CHOICES))
                    if thrall then
                        thrall.Transform:SetPosition(spawn_pt.x, spawn_pt.y, spawn_pt.z)
                        thrall.sg:GoToState("spawndelay", 0)
                        thrall.ancient_army = true
                        if thrall.components.lootdropper then
                            thrall.components.lootdropper:SetChanceLootTable("chasni_shadowthrall")
                        end
                        if thrall.components.health then
                            thrall.components.health:SetMaxHealth(thrall.components.health.maxhealth * 0.5)
                        end
                    end
                end
            end
        end
    end
end

local function DoSpawning(inst)
    if inst.components.health and inst.components.health:GetPercent() < .4 then
        SpawnThrall(inst)
    else
        SpawnFireRain(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.Transform:SetSixFaced()
    inst.DynamicShadow:SetSize(1, 1)
    MakeFlyingCharacterPhysics(inst, 1000, .5)

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ancient_herald")
    inst:AddTag("shadow_aligned")
    inst:AddTag("shadowthrall")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.AnimState:SetBank("ancient_spirit")
    inst.AnimState:SetBuild("ancient_spirit")
    inst.AnimState:PlayAnimation("idle", true)

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

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2
    inst.components.locomotor.pathcaps = { allowocean = true }

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_ancientherald")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

    inst:AddComponent("planarentity")
    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(PLANAR_DAMAGE)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZancientherald")
    inst.sg:GoToState("appear")
    inst:SetBrain(brain)

    inst.DoSpawning = DoSpawning
    inst.DoAoeAttack = DoAoeAttack
    inst.summon_time = GetTime()
    inst.taunt_time = GetTime()

    return inst
end

return Prefab("chasni_ancientherald", fn, assets, prefabs)