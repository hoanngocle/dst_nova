require "behaviours/standandattack"
require "behaviours/standstill"

local GenericStaticBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local START_FACE_DIST = 10
local KEEP_FACE_DIST = 15

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST)
    return target and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

function GenericStaticBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function()
            return self.inst.components.combat.target
                    and self.inst.components.combat:CanAttack(self.inst.components.combat.target)
                    and not self.inst.components.combat:InCooldown()
        end, "AttackIfNearby", StandAndAttack(self.inst, nil, 1)),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
    }, .25)

    self.bt = BT(self.inst, root)
end

return GenericStaticBrain
