local brain = require "brains/generic_staticbrain"

local assets =
{
    Asset("ANIM", "anim/venus_flytrap_lg_build.zip"),
    Asset("ANIM", "anim/venus_flytrap_planted.zip"),
}

local prefabs =
{
    "plantmeat",
    "chasni_grabbingvine",
    "dug_trap_flytrap"
}

SetSharedLootTable("chasni_adultflytrap", {
    {"dug_trap_flytrap",   1.00},
    {"plantmeat",          1.00},
    {"plantmeat",          0.20},
    {"jellybean_red",      0.15},
})

local HEALTH = chasni_getmobconfig("chasni_adultflytrap", "HP") or 800
local DAMAGE = chasni_getmobconfig("chasni_adultflytrap", "DMG") or 30
local RETARGET_PERIOD = 1
local ATTACK_PERIOD = 3
local ATTACK_RANGE = 4
local ATTACK_DIST = 4
local MAX_VINE = 15
local STOPATTACK_DIST = 6

local function SpawnVine(inst, range)
    if inst.components.combat.target and inst.components.combat.target.Transform then
        local pt = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
        local angle = math.random() * 360
        if angle > 360 then angle = angle - 360 end
        local radius = 15
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, radius, {"grabbingvine"})
        if #ents < MAX_VINE then
            local offset = FindWalkableOffset(pt, angle * DEGREES, range, 20, true, false)
            if offset then
                local plant = SpawnPrefab("chasni_grabbingvine")
                pt = pt + offset
                plant.Transform:SetPosition(pt.x,pt.y,pt.z)
                plant.sg:GoToState("down")
            end
        end
    end
end

local function retargetfn(inst)
    return FindEntity(inst, ATTACK_DIST, function(guy)
        if guy.components.combat and guy.components.health and not guy.components.health:IsDead() then
            return (inst.components.combat:CanTarget(guy)) and not guy:HasTag("flytrap") and not guy:HasTag("grabbingvine") and not (guy.prefab == inst.prefab) and not guy:HasTag("plantkin")
        end
    end)
end

local function KeepTarget(inst, target)
    if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
        local distsq = target:GetDistanceSqToInst(inst)
        return distsq < STOPATTACK_DIST * STOPATTACK_DIST
    else
        return false
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetFourFaced()
    MakeObstaclePhysics(inst, .25)

    inst.AnimState:Hide("root")
    inst.AnimState:Hide("leaf")

    inst.AnimState:SetBank("venus_flytrap_planted")
    inst.AnimState:SetBuild("venus_flytrap_lg_build")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("flytrap")
    inst:AddTag("hostile")
    inst:AddTag("epic")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, retargetfn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_adultflytrap")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")

    MakeMediumBurnableCharacter(inst, "stem")
    MakeLargeFreezableCharacter(inst)

    inst.SpawnVine = SpawnVine

    inst:SetStateGraph("SGCZadultflytrap")
    inst:SetBrain(brain)

    return inst
end

return Prefab("chasni_adultflytrap", fn, assets, prefabs) 
