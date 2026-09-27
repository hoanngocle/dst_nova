require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "behaviours/wander"

local CHASE_DIST = 32
local CHASE_TIME = 20
local SUMMON_COOLDOWN = 15
local TAUNT_COOLDOWN = 60

local function CanSummon(inst)
    return not inst.components.health:IsDead() and GetTime() - inst.summon_time > SUMMON_COOLDOWN and (inst.components.combat.target and inst.components.combat.target:HasTag("player"))
end

local function DoSummon(inst)
    inst.sg:GoToState("summon")
    inst.summon_time = GetTime()
end

local function CanTaunt(inst)
    return not inst.components.health:IsDead() and GetTime() - inst.taunt_time > TAUNT_COOLDOWN and
            (inst.components.combat.target and inst.components.combat.target:HasTag("player")) and math.random() < 0.1
end

local function DoTaunt(inst)
    inst.sg:GoToState("taunt")
    inst.taunt_time = GetTime()
end

local Chasni_AncientHeraldBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_AncientHeraldBrain:OnStart()
    local root = PriorityNode({
        IfNode(function() return CanTaunt(self.inst) end, "CanTaunt",
                DoAction(self.inst, function() DoTaunt(self.inst) end)),

        IfNode(function() return CanSummon(self.inst) end, "CanSummon",
                DoAction(self.inst, function() DoSummon(self.inst) end)),

        WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
                ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST)),
        Wander(self.inst),
    },1)
    self.bt = BT(self.inst, root)
end

return Chasni_AncientHeraldBrain