require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"


local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local MAX_CHASE_TIME = 15

local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    return target and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function shouldSpecialAttack(inst)
    return inst:shouldspecialattack()
end

local function doSpecialAttack(inst)
    inst:dospecialattack()
end

local MERGE_RANGE = 15
local function shouldmerge(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local mergetarget, foundhulk
    local distance = math.huge
    local ents = TheSim:FindEntities(x,y,z, MERGE_RANGE, {"ancient_robot"})
    for i, ent in ipairs(ents) do
        if ent ~= inst and ent.canmerge and ent:canmerge(inst.part) then
            if ent:HasTag("chasni_hulk_assembly") or (ent:HasTag("dormant") and not foundhulk) then
                if ent:HasTag("chasni_hulk_assembly") then
                    if not foundhulk then
                        mergetarget = nil
                        distance = math.huge
                    end
                    foundhulk = true
                end
                local testdist = inst:GetDistanceSqToInst(ent)
                if testdist < distance then
                    mergetarget = ent
                    distance = testdist
                end
            end
            if not ent:HasTag("chasni_hulk_assembly") and not ent:HasTag("dormant") then
                inst.mergetarget = nil
                return false
            end
        end
    end

    if not inst.doneprint then
    end
    inst.mergetarget = mergetarget
    if inst.mergetarget then
        if not inst.doneprint then
            inst.doneprint = true
        end
        return true
    end
    return false
end

local function domerge(inst)
    return BufferedAction(inst, inst.mergetarget, ACTIONS.HULK_MERGE)
end

local function deactivate(inst)
    if not inst:HasTag("dormant") then
        inst:PushEvent("deactivate")
    end
end

local function notarget(inst)
    local target = inst.components.combat and inst.components.combat.target
    if target then
        return false
    end
    return true
end

local function godormant(inst)
    if inst.lifetime and inst.lifetime > 0 then
        inst.lifetime = 0
    end
end

local Chasni_AncientRobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_AncientRobotBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return self.inst:HasTag("dormant") or self.inst._wanttodeactivate == true end, "deactivate",
                DoAction(self.inst, function() return deactivate(self.inst) end, "deactivate", true)
        ),
        WhileNode(function() return not self.inst:HasTag("dormant") and not self.inst._wanttodeactivate end, "activate", PriorityNode({
            IfNode(function() return notarget(self.inst) end, "idling",
                    DoAction(self.inst, function() return godormant(self.inst) end, "idling", true)
            ),
            WhileNode(function() return shouldmerge(self.inst) end, "merge",
                    DoAction(self.inst, function() return domerge(self.inst) end, "merge", true)
            ),
            WhileNode(function() return shouldSpecialAttack(self.inst) end, "specialattack", 
                    DoAction(self.inst, function() return doSpecialAttack(self.inst) end, "specialattack", true)
            ),
            ChaseAndAttack(self.inst, MAX_CHASE_TIME),
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
            Wander(self.inst)
        }, .25)),
    }, .25)
    self.bt = BT(self.inst, root)
end

return Chasni_AncientRobotBrain