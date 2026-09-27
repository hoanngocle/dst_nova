local brain = require "brains/chasni_ancienthulkbrain"
local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/metal_hulk_build.zip"),
    Asset("ANIM", "anim/metal_hulk_basic.zip"),
    Asset("ANIM", "anim/metal_hulk_attacks.zip"),
    Asset("ANIM", "anim/metal_hulk_actions.zip"),
    Asset("ANIM", "anim/metal_hulk_barrier.zip"),
    Asset("ANIM", "anim/metal_hulk_explode.zip"),
    Asset("ANIM", "anim/metal_hulk_bomb.zip"),
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),
    Asset("ANIM", "anim/laser_explode_sm.zip"),
    Asset("ANIM", "anim/smoke_aoe.zip"),
    Asset("ANIM", "anim/laser_explosion.zip"),
    Asset("ANIM", "anim/ground_chunks_breaking_brown.zip"),
}

local prefabs =
{
    "groundpound_fx",
    "groundpoundring_fx",
    "chasni_hulk_assembly",
    "chasni_basalt",
    "gears",
}

SetSharedLootTable("chasni_ancient_hulk", {
    {"chasni_hulk_metalbit",    1.0},
    {"chasni_hulk_metalbit",    0.5},
    {"chasni_hulk_metalbit",    0.5},
    {"chasni_hulk_metalbit",    0.1},
    {"chasni_hulk_metalbit",    0.1},
    {"chasni_hulk_metalbit",    0.1},
    {"chasni_hulk_metalbit",    0.1},
    {"trinket_11",              1.0},
    {"trinket_11",              0.7},
    {"trinket_11",              0.3},
    {"trinket_6",               1.0},
    {"trinket_6",               1.0},
    {"trinket_6",               0.6},
    {"trinket_6",               0.4},
    {"trinket_6",               0.4},
    {"gears",                   1.0},
    {"gears",                   1.0},
    {"gears",                   0.8},
    {"gears",                   0.2},
})

local HEALTH = chasni_getmobconfig("chasni_ancienthulk", "HP") or 50000
local DAMAGE = chasni_getmobconfig("chasni_ancienthulk", "DMG") or 200
local DAMAGE_MINE = chasni_getmobconfig("chasni_ancienthulk", "MDMG") or 100
local ATTACK_PERIOD = 3
local ATTACK_RANGE = 5.5
local LAUNCH_MINE_RANGE = 15
local SPEED = 3
local RETARGET_PERIOD = 3
local RETARGET_RANGE = 30
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", }
local KEEPTARGET_RANGE = 40
local SHARETARGET_RANGE = 40
local SHARETARGET_MAX = 40
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_basicsharetarget(inst, data, SHARETARGET_RANGE, "shadowthrall", SHARETARGET_MAX)
end

local function SetLightValue(inst, val1, val2, time)
    inst.components.fader:StopAll()
    if val1 and val2 and time then
        inst.Light:Enable(true)
        inst.components.fader:Fade(val1, val2, time, function(v) inst.Light:SetIntensity(v) end)
    else
        inst.Light:Enable(false)
    end
end

local function setfires(x,y,z, rad)
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end

local function applydamagetoent(inst, ent, targets, rad, hit)
    if not targets[ent] and ent:IsValid() and not ent:IsInLimbo() and not (ent.components.health and ent.components.health:IsDead()) and not ent:HasTag("laser_immune") then
        local range = (rad or 0) + (ent.Physics and ent.Physics:GetRadius() or 0)
        local x, y, z = inst.Transform:GetWorldPosition()
        if hit or ent:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
            if chasni_entWorkableIsCollapsible(ent) then
                targets[ent] = true
                ent:DoTaskInTime(0.6, function()
                    if ent.components.workable then
                        ent.components.workable:Destroy(inst)
                        local vx,vy,vz = ent.Transform:GetWorldPosition()
                        ent:DoTaskInTime(0.3, function() setfires(vx,vy,vz,1) end)
                    end
                end)
            end
            if ent.components.pickable and ent.components.pickable:CanBePicked() and not ent:HasTag("intense") then
                targets[ent] = true
                local num = ent.components.pickable.numtoharvest or 1
                local product = ent.components.pickable.product
                local x1, _, z1 = ent.Transform:GetWorldPosition()
                ent.components.pickable:Pick(inst)
                if product and num > 0 then
                    for _ = 1, num do
                        local loot = SpawnPrefab(product)
                        loot.Transform:SetPosition(x1, 0, z1)
                        targets[loot] = true
                    end
                end
            end
            if ent.components.health then
                inst.components.combat:DoAttack(ent)
            end
            if ent.components.freezable then
                if ent.components.freezable:IsFrozen() then
                    ent.components.freezable:Unfreeze()
                elseif ent.components.freezable.coldness > 0 then
                    ent.components.freezable:AddColdness(-2)
                end
            end
            if ent.components.temperature then
                local maxtemp = math.min(ent.components.temperature:GetMax(), 10)
                local curtemp = ent.components.temperature:GetCurrent()
                if maxtemp > curtemp then
                    ent.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                end
            end
            if ent.AnimState then
                SpawnPrefab("chasni_laserhit"):SetTarget(ent)
            end
        end
    end
    return targets
end

local function DoDamage(inst, rad, startang, endang)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = 0
    if startang and endang then
        startang = startang + 90
        endang = endang + 90

        local down = TheCamera:GetDownVec()
        angle = math.atan2(down.z, down.x)/DEGREES
    end

    setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do
        local dodamage = true
        if startang and endang then
            local dif = angle - inst:GetAngleToPoint(Vector3(v.Transform:GetWorldPosition()))
            while dif > 450 do
                dif = dif - 360
            end
            while dif < 90 do
                dif = dif + 360
            end
            if dif < startang or dif > endang then
                dodamage = false
            end
        end
        if dodamage then
            targets = applydamagetoent(inst, v, targets, rad)
        end
    end
end

local function droppart(inst, part)
    local x, _, z = inst.Transform:GetWorldPosition()
    local map = TheWorld.Map
    x = math.random(x - 80, x + 80)
    z = math.random(z - 80, z + 80)
    if map:IsVisualGroundAtPoint(x,0,z) and map:IsVisualGroundAtPoint(x-4,0,z) and map:IsVisualGroundAtPoint(x+4,0,z) and map:IsVisualGroundAtPoint(x,0,z-4) and map:IsVisualGroundAtPoint(x,0,z+4) then
        local partprop = SpawnPrefab("chasni_hulk_claw")
        partprop:AddTag("dormant")
        partprop.sg:GoToState("idle_dormant")
        inst.DoDamage(partprop, 5)
        partprop.Transform:SetPosition(x, 0, z) 
    end
end

local function dropparts(inst)
    droppart(inst, "chasni_hulk_claw")
    droppart(inst, "chasni_hulk_claw")
    droppart(inst, "chasni_hulk_leg")
    droppart(inst, "chasni_hulk_leg")
    droppart(inst, "chasni_hulk_spider")
end

local function OnCollide(inst, other)
    if other == nil then return end
    if chasni_entWorkableIsCollapsible(other) then
        other:DoTaskInTime(0.6, function()
            if other.components.workable then
                other.components.workable:Destroy(inst)
            end
        end)
    elseif other.components.pickable and other.components.pickable:CanBePicked() and not other:HasTag("intense") then
        local num = other.components.pickable.numtoharvest or 1
        local product = other.components.pickable.product
        local x1, _, z1 = other.Transform:GetWorldPosition()
        other.components.pickable:Pick(inst)
        if product and num > 0 then
            for _ = 1, num do
                local loot = SpawnPrefab(product)
                loot.Transform:SetPosition(x1, 0, z1)
            end
        end
    end
end

local function LaunchMine(inst, dir)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local theta = dir - (PI/6) + (PI/3*math.random())

    local offset = FindWalkableOffset(pt, theta, 6 + math.random()*6, 12, true)
    if offset then
        local targetpos = pt + offset
        targetpos.y = 0

        local projectile = SpawnPrefab("chasni_ancient_hulk_mine")
        projectile.Transform:SetPosition(pt.x, 1, pt.z)
        projectile.AnimState:PlayAnimation("spin_loop",true)
        projectile.mineactive = false

        local rangesq = offset.x * offset.x + offset.z * offset.z
        local speed = easing.linear(rangesq, 15, 3, LAUNCH_MINE_RANGE * LAUNCH_MINE_RANGE)
        projectile.components.complexprojectile:SetHorizontalSpeed(speed)
        projectile.components.complexprojectile:SetGravity(-25)
        projectile.components.complexprojectile:Launch(targetpos, inst, inst)
        projectile.owner = inst
    end
end

local function ShootProjectile(inst, targetpos)
    local pt = inst.shotspawn:GetPosition()
    local projectile = SpawnPrefab("chasni_ancient_hulk_orb")
    projectile.Transform:SetPosition(pt.x, pt.y, pt.z)
    projectile.AnimState:PlayAnimation("spin_loop",true)
    projectile.mineactive = false
    projectile.components.complexprojectile:SetHorizontalSpeed(60)
    projectile.components.complexprojectile:SetGravity(-25)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    projectile.owner = inst
end

local function DoSpin(inst, rad, startangle, endangle)
    DoDamage(inst, rad, startangle, endangle)
    startangle = startangle * DEGREES
    endangle = endangle * DEGREES
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local down = TheCamera:GetDownVec()
    local angle = startangle + math.atan2(down.z, down.x)
    local angdiff = (endangle-startangle) / 5
    for _ = 1, 5 do
        local offset = Vector3(rad * math.cos(angle), 0, rad * math.sin(angle))
        local newpt = pt + offset
        local fx = chasni_spawnprefab("chasni_laser", newpt.x, newpt.y, newpt.z)
        fx:Trigger(0, {},{})
        chasni_spawnprefab("chasni_laserscorch", newpt.x, newpt.y, newpt.z)
        angle = angle + angdiff
    end
end

local function spawnbarrier(inst,pt)
    local angle = 0
    local radius = 13
    local number = 32
    for _ = 1,number do
        local offset = Vector3(radius * math.cos(angle), 0, -radius * math.sin(angle))
        local newpt = pt + offset
        if TheWorld.Map:IsPassableAtPoint(newpt.x, newpt.y, newpt.z) then
            TheWorld:DoTaskInTime(math.random()*0.3, function()
                local rock = SpawnPrefab("chasni_basalt")
                rock.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
                rock.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rock")
                rock.AnimState:PlayAnimation("emerge")
                rock.AnimState:PushAnimation("full")
            end)
        end
        angle = angle + (PI*2/number)
    end
end

local function teleport(inst)
    inst.teleportcooldown = 0
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local target = inst.components.combat.target
    if target then
        local tpt = Vector3(target.Transform:GetWorldPosition())
        if TheWorld.Map:IsPassableAtPoint(tpt.x, tpt.y, tpt.z) then
            pt = tpt
        end
    end

    local theta = math.random() * 2 * PI
    local offset
    while not offset do
        offset = FindWalkableOffset(pt, theta, 12 + math.random()*5, 12, true)
    end

    pt.x = pt.x + offset.x
    pt.z = pt.z + offset.z
    inst.Physics:SetActive(true)
    inst.Transform:SetPosition(pt.x,0,pt.z)
    inst.sg:GoToState("telportin")
end

local function checkforAttacks(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10, {"chasni_ancient_hulk_mine"})
    if #ents < 8 then
        inst.shouldthrowmine = true
    else
        inst.shouldthrowmine = nil
    end

    if inst.orbs > 0 then
        if inst.components.combat.target and inst.components.combat.target:IsValid() then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist > 10*10  and dist < 25*25 then
                inst.shouldthroworb = true
            else
                inst.shouldthroworb = nil
            end
        end
    else
        inst.orbcooldown = inst.orbcooldown -1
        if inst.orbcooldown <= 0 then
            inst.orbcooldown = nil
            inst.orbs = 2
        end
    end

    if inst.components.combat.target and inst.components.combat.target:IsValid() then
        local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
        if dist < 6*6 then
            if not inst.teleportcooldown then
                inst.teleportcooldown = 0
            end
            inst.teleportcooldown = inst.teleportcooldown + 1
            if inst.teleportcooldown > 5 then
                inst.shouldteleport = true
            end
        else
            inst.teleportcooldown =  nil
        end
    end

    if inst.components.combat.target and inst.components.combat.target:IsValid() and inst.components.health:GetPercent() < 0.8 then
        if not inst.spintime or inst.spintime <=0 then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist < 6*6 then
                inst.shouldspin = true
            else
                inst.shouldspin = nil
            end
        else
            inst.spintime = inst.spintime - 1
        end
    end

    if inst.components.combat.target and inst.components.combat.target:IsValid() and inst.components.health:GetPercent() < 0.6 then
        if not inst.barriertime or inst.barriertime <=0 then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist < 6*6 then
                inst.shouldspawnbasalt = true
            else
                inst.shouldspawnbasalt = nil
            end
        else
            inst.barriertime = inst.barriertime - 1
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

    inst.DynamicShadow:SetSize(6, 3.5)
    inst.Transform:SetSixFaced()
    MakeCharacterPhysics(inst, 1000, 2)

    inst.AnimState:SetBank("metal_hulk")
    inst.AnimState:SetBuild("metal_hulk_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:AddOverrideBuild("laser_explode_sm")
    inst.AnimState:AddOverrideBuild("smoke_aoe")
    inst.AnimState:AddOverrideBuild("laser_explosion")
    inst.AnimState:AddOverrideBuild("ground_chunks_breaking")

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("chasni_ancient_hulk")
    inst:AddTag("laser_immune")

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(false)

    inst:AddComponent("fader")

    inst.orbs = 2

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE, ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetAreaDamage(ATTACK_RANGE, 0.8)

    inst:AddComponent("health")
    inst.components.health.destroytime = 5
    inst.components.health:SetMaxHealth(HEALTH)
    inst.components.health.fire_damage_scale = 0

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED + 3
    inst.components.locomotor:SetShouldRun(true)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chasni_ancient_hulk")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 3
    inst.components.groundpounder.numRings = 3
    inst.components.groundpounder.groundpoundfx = "groundpound_fx_hulk"

    inst:AddComponent("inspectable")

    inst:ListenForEvent("onremove", function() inst.SoundEmitter:KillSound("gears") end, inst)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:DoPeriodicTask(1,function() checkforAttacks(inst) end)

    inst.LaunchMine = LaunchMine
    inst.ShootProjectile = ShootProjectile
    inst.DoSpin = DoSpin
    inst.DoDamage = DoDamage
    inst.spawnbarrier = spawnbarrier
    inst.dropparts = dropparts
    inst.SetLightValue = SetLightValue
    inst.teleport = teleport

    inst:SetStateGraph("SGCZancienthulk")
    inst:SetBrain(brain)

    if not inst.shotspawn then
        inst.shotspawn = SpawnPrefab("chasni_ancient_hulk_marker")
        inst.shotspawn:Hide()
        inst.shotspawn.persists = false
        local follower = inst.shotspawn.entity:AddFollower()
        follower:FollowSymbol(inst.GUID, "hand01", 0,0,0)
    end

    return inst
end

local function OnHit(inst, dist)
    inst.AnimState:PlayAnimation("land")
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/step_wires")
    inst.AnimState:PushAnimation("open")
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust")
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("open") then
            inst.mineactive  = true
            inst.AnimState:PlayAnimation("green_loop",true)
        end
    end)
end

local function onnearmine(inst, ent)
    local detonate = false
    if not ent:HasTag("chasni_ancient_hulk") then
        detonate = true
    end
    if inst.mineactive and detonate then
        inst.SetLightValue(inst, 0,0.75,0.2 )
        inst.AnimState:PlayAnimation("red_loop", true)
        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/active_LP","boom_loop", 0.3)
        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro", nil, 0.5)
        inst:DoTaskInTime(0.8,function()
            inst.SoundEmitter:KillSound("boom_loop")
            inst:Hide()
            local ring = SpawnPrefab("chasni_laserring")
            ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) inst:Remove() end)
            local explosion = SpawnPrefab("chasni_laserexplosion")
            explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/smash", nil, 0.5)
        end)
    end
end

local function minefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 75, 0.5)

    inst.AnimState:SetBank("metal_hulk_mine")
    inst.AnimState:SetBuild("metal_hulk_bomb")
    inst.AnimState:PlayAnimation("green_loop", true)

    inst:AddTag("chasni_ancient_hulk_mine")

    inst.mineactive = true

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(false)

    inst:AddComponent("fader")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile.yOffset = 2.5

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE_MINE)

    inst.SetLightValue = SetLightValue

    inst:AddComponent("proxcheck")
    inst.components.proxcheck.checkinterval = 0.1
    inst.components.proxcheck.range = 3
    inst.components.proxcheck.proxfn = onnearmine
    inst:DoTaskInTime(.1,function()
        inst.components.proxcheck:SetEnabled(true)
    end)

    return inst
end

local function OnHitOrb(inst, dist)
    inst.AnimState:PlayAnimation("impact")
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("impact") then
            inst:Remove()
        end
    end)
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("chasni_laserring", x, y, z)
    inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) end)
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/smash", nil, 0.5)
end

local function orbfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    MakeInventoryPhysics(inst, 75, 0.5)

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.persists = false

    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(true)

    inst:AddComponent("fader")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnHitOrb)
    inst.components.complexprojectile.yOffset = 2.5

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE_MINE)
    inst.components.combat.playerdamagepercent = 0.5

    inst.SetLightValue = SetLightValue

    return inst
end

local function markerfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst.persists = false
    return inst
end

return
Prefab("chasni_ancient_hulk", fn, assets, prefabs),
Prefab("chasni_ancient_hulk_mine", minefn, assets, prefabs),
Prefab("chasni_ancient_hulk_orb", orbfn, assets, prefabs),
Prefab("chasni_ancient_hulk_marker", markerfn, assets, prefabs)
