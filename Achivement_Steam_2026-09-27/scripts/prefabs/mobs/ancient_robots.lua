local brain = require "brains/chasni_ancientrobotbrain"

local assets=
{
    Asset("ANIM", "anim/metal_spider.zip"),
    Asset("ANIM", "anim/metal_claw.zip"),
    Asset("ANIM", "anim/metal_leg.zip"),
    Asset("ANIM", "anim/metal_head.zip"),
    Asset("MINIMAP_IMAGE", "metal_spider"),
}

local prefabs =
{
    "sparks_green_fx",
    "chasni_laserring",
}

local DAMAGE = chasni_getmobconfig("chasni_wargfant", "DMG") or 34
local ATTACK_PERIOD = 3
local ATTACK_RANGE = 9
local SPEED = 3.3
local RETARGET_PERIOD = 1
local RETARGET_RANGE = 30
local RETARGET_MUST_TAGS = { "character", "_combat" }
local RETARGET_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "wall", "hulk" }
local KEEPTARGET_RANGE = ATTACK_RANGE + 6
local BASE_LIFETIME = 60
local RAND_LIFETIME = 20
local TICK = 1
local function RetargetFn(inst)
    return chasni_basicretarget(inst, RETARGET_RANGE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function setBlocker(inst, block)
    if block and not inst:HasTag("blocker") then
        inst:AddTag("blocker")
        inst.Physics:SetMass(0)
        inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
        inst.Physics:CollidesWith(COLLISION.GIANTS)
    elseif not block and inst:HasTag("blocker") then
        inst:RemoveTag("blocker")
        inst.Physics:SetMass(100)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:CollidesWith(COLLISION.WORLD)
    end
end

local function removemoss(inst)
    if inst:HasTag("mossy") then
        inst:RemoveTag("mossy")
        local x, y, z = inst.Transform:GetWorldPosition()
        for _ = 1,math.random(12,15) do
            inst:DoTaskInTime(math.random()*0.5,function()
                local fx = SpawnPrefab("robot_leaf_fx")
                fx.Transform:SetPosition(x + (math.random()*4) -2, y, z + (math.random()*4) -2)
            end)
        end
    end
end

local function TurnOff(inst)
    setBlocker(inst, true)
    if not inst:HasTag("dormant") then
        inst:PushEvent("deactivate")
    end
end

local function periodicupdate(inst)
    if inst.lifetime and inst.lifetime > 0 then
        setBlocker(inst, false)
        inst.lifetime = inst.lifetime - TICK
    else
        inst._wanttodeactivate = true
        if inst._updatetask then
            inst._updatetask:Cancel()
            inst._updatetask = nil
        end
    end
end

local function TurnOn(inst, lifetime, event)
    if inst:HasTag("dormant") then
        setBlocker(inst, false)
        inst._wanttodeactivate = false
        inst:RemoveTag("dormant")
        inst:PushEvent(event or "activate")
        inst.lifetime = lifetime or BASE_LIFETIME + math.random(-RAND_LIFETIME, RAND_LIFETIME)
        if inst._updatetask == nil then
            inst._updatetask = inst:DoPeriodicTask(TICK, periodicupdate)
        end
        return true
    end
end

local function OnLightning(inst, data)
    local lifetime = BASE_LIFETIME + BASE_LIFETIME + math.random(RAND_LIFETIME, RAND_LIFETIME + RAND_LIFETIME)
    TurnOn(inst, lifetime, "shock")
end

local function OnLoad(inst, data)
    inst.sg:GoToState("idle_dormant")
    inst:AddTag("dormant")
    inst.components.locomotor:Stop()

    setBlocker(inst, true)
end

local function canmerge(inst, part)
    if part == "leg" or part == "claw" then
        return true
    end
    return part ~= inst.part
end

local function mergeaction(act)
    if act.target then
        local target = act.target
        if not target:HasTag("chasni_hulk_assembly") then
            local x, y, z = act.target.Transform:GetWorldPosition()
            local hulk = chasni_spawnprefab("chasni_hulk_assembly", x, y, z)
            target.onmerge(target, hulk)
            target = hulk
            act.target:Remove()
        end
        act.doer.onmerge(act.doer, target)
        target:onmerge()
        act.doer:Remove()
    end
end

local function setFourFaced(inst)
    inst.Transform:SetFourFaced()
end

local function setSixFaced(inst)
    inst.Transform:SetSixFaced()
end

local function shouldJumpAttack(inst)
    if inst.sg:HasStateTag("leapattack") then
        return true
    end

    local target = inst.components.combat.target
    if target and target:IsValid() then
        local distsq = inst:GetDistanceSqToInst(target)
        if distsq < ATTACK_RANGE * ATTACK_RANGE then
            return true
        end
    else
        inst.components.combat.target = nil
    end
    return false
end

local function shouldLaserAttack(inst)
    if inst.components.combat.target and not inst.components.timer:TimerExists("laserbeam_cd") then
        local distsq = inst:GetDistanceSqToInst(inst.components.combat.target)
        if distsq < ATTACK_RANGE * ATTACK_RANGE then
            return true
        end
    end
    return false
end

local function doJumpAttack(inst)
    local target = inst.components.combat.target
    if target and not inst.sg:HasStateTag("leapattack") then
        inst:PushEvent("doleapattack", {target=target})
        inst:FacePoint(target.Transform:GetWorldPosition())
    end
end

local function doLaserAttack(inst)
    if inst.components.combat.target then
        inst:PushEvent("dobeamattack",{target = inst.components.combat.target})
    end
end

local function AlwaysRecoil(inst, worker, tool, numworks)
    return true, numworks
end

local function fn(part, bank, build, setfacefn, shouldspecialattackfn, dospecialattackfn)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.DynamicShadow:SetSize(6, 2)
    MakeCharacterPhysics(inst, 100, 2)

    inst.SetFace = setfacefn
    inst:SetFace()

    inst:AddTag("lightningrod")
    inst:AddTag("laser_immune")
    inst:AddTag("ancient_robot")
    inst:AddTag("monster")
    inst:AddTag("dormant")
    inst:AddTag("mossy")
    inst:AddTag("hulk_"..part)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0, 0)
    inst.Light:Enable(false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE) -- check
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD) -- check
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = SPEED
    inst.components.locomotor.runspeed = SPEED

    inst:AddComponent("timer")
    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetShouldRecoilFn(AlwaysRecoil)
    inst.components.workable:SetOnWorkCallback(function(inst, worker, workleft)
        local strongworker = worker:HasTag("toughworker")
        if not strongworker then
            local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
            strongworker = tool and tool.components.tool and tool.components.tool:CanDoToughWork()
        end
        if strongworker then
            local pos = chasni_getMiddlePos(inst, worker)
            chasni_spawnprefab("sparks_green_fx", pos.x,pos.y + 1,pos.z)
            inst.components.workable:SetWorkLeft(1)
            inst:PushEvent("mined")
        else
            inst.components.workable:SetWorkLeft(1)
            worker:PushEvent("tooltooweak", { workaction = ACTIONS.MINE })
        end
    end)

    inst.lightningpriority = 1
    inst.canmerge = canmerge
    inst.domerge = mergeaction
    inst.removemoss = removemoss
    inst.turnon = TurnOn
    inst.turnoff = TurnOff
    inst.setblocker = setBlocker
    inst.shouldspecialattack = shouldspecialattackfn
    inst.dospecialattack = dospecialattackfn
    inst.part = part
    inst.onmerge = function(_, hulk) hulk[inst.part] = (hulk[inst.part] or 0) + 1 end
    inst.OnLoad = OnLoad

    setBlocker(inst, true)
    inst:ListenForEvent("lightningstrike", OnLightning)

    inst:SetStateGraph("SGCZAncientRobot")
    inst.sg:GoToState("idle_dormant")
    inst:SetBrain(brain)
    return inst
end

local function spiderfn() return fn("spider", "metal_spider", "metal_spider", setFourFaced, shouldLaserAttack, doLaserAttack) end
local function clawfn() return fn("claw", "metal_claw", "metal_claw", setSixFaced, shouldLaserAttack, doLaserAttack) end
local function legfn() return fn("leg", "metal_leg", "metal_leg", setSixFaced, shouldJumpAttack, doJumpAttack) end
local function headfn() return fn("head", "metal_head", "metal_head", setSixFaced, shouldJumpAttack, doJumpAttack) end

return 
Prefab("chasni_hulk_spider", spiderfn, assets, prefabs),
Prefab("chasni_hulk_claw", clawfn, assets, prefabs),
Prefab("chasni_hulk_leg", legfn, assets, prefabs),
Prefab("chasni_hulk_head", headfn, assets, prefabs)
