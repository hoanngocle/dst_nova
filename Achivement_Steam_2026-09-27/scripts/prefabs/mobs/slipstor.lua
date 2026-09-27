local brain = require "brains/chasni_slipstorbrain"

local assets =
{
    Asset("ANIM", "anim/slipstor_build.zip"),
    Asset("ANIM", "anim/slipstor_basic.zip"),
    Asset("ANIM", "anim/slipstor_actions.zip"),
    Asset("ANIM", "anim/slipstor_attacks.zip"),
}

local prefabs =
{
    "chasni_slip",
    "monstermeat",
    "jellybean_red",
}

SetSharedLootTable("chasni_slipstor", {
    {"monstermeat",         0.05},
    {"chasni_slipstor_fur", 0.03},
})

local HEALTH = chasni_getmobconfig("chasni_slipstor", "HP") or 777
local DAMAGE = chasni_getmobconfig("chasni_slipstor", "DMG") or 77
local ATTACK_PERIOD = 4
local ATTACK_RANGE = 3
local SPEED = 2
local RETARGET_RANGE = 4
local RETARGET_PERIOD = 1
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "slip", "slipstor" }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 30
local SHARETARGET_MAX = 100
local function Retarget(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "slip", SHARETARGET_MAX)
end

local function SpawnSlip(inst)
    if inst.components.health and inst.components.health.currenthealth > 0 then
        local angle = (inst.Transform:GetRotation() + 180) * DEGREES
        local slip = SpawnPrefab("chasni_slip")
        if slip then
            local rad = slip:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + .25
            local x, _, z = inst.Transform:GetWorldPosition()
            slip.Transform:SetPosition(x + rad * math.cos(angle), 0, z - rad * math.sin(angle))
            inst.components.leader:AddFollower(slip)
            if inst.components.combat.target then
                slip.components.combat:SetTarget(inst.components.combat.target)
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(4, 1.5)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 200, .5)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("slipstor")
    inst:AddTag("epic")

    inst.AnimState:SetBank("slipstor")
    inst.AnimState:SetBuild("slipstor_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)
    inst.components.health:StartRegen(1, 10)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 2

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_slipstor")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper:SetNocturnal(true)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")
    inst:AddComponent("leader")

    MakeSmallBurnableCharacter(inst, "slipstor_torso_lower")
    MakeHugeFreezableCharacter(inst, "slipstor_torso_lower")

    inst.spawnloot = false
    inst.spawnslip = SpawnSlip
    inst.Transforming = function() inst.sg:GoToState("transform") end

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("minhealth", function(inst, data)
        if inst.components.health.currenthealth <= 0 then
            if inst.components.leader and inst.components.leader:CountFollowers() > 0 then
                inst:RemoveTag("epic")
                local followers = inst.components.leader.followers
                local newleader = nil
                for v,b in pairs(followers) do
                    if newleader == nil then
                        local x, y, z = v.Transform:GetWorldPosition()
                        v:Remove()
                        newleader = SpawnPrefab("chasni_slipstor")
                        if newleader then
                            newleader.Transform:SetPosition(x, y, z)
                            newleader.Transforming()
                        end
                    else
                        newleader.components.leader:AddFollower(v)
                        if newleader.components.combat.target then
                            v.components.combat:SetTarget(newleader.components.combat.target)
                        end
                    end
                end
            elseif inst.spawnloot == false then
                inst.spawnloot = true
                local jellybean = SpawnPrefab("jellybean_red")
                jellybean:PushEvent("on_loot_dropped", {dropper = inst})
                inst.components.lootdropper:FlingItem(jellybean)
                local fur = SpawnPrefab("chasni_slipstor_fur")
                inst.components.lootdropper:FlingItem(fur)
                local fur2 = SpawnPrefab("chasni_slipstor_fur")
                inst.components.lootdropper:FlingItem(fur2)
                local fur3 = SpawnPrefab("chasni_slipstor_fur")
                inst.components.lootdropper:FlingItem(fur3)
                inst.components.lootdropper:DropLoot(inst:GetPosition())
            end
        end
    end)

    inst:SetStateGraph("SGCZslipstor")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_slipstor", fn, assets, prefabs)
