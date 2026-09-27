require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"

local TARGET_FOLLOW_DIST = 2.5
local MAX_FOLLOW_DIST = 4
local MIN_FOLLOW_DIST = 1

local AVOID_SCARY_DIST = 6
local AVOID_SCARY_STOP = 10

local function GetOwner(inst)
    return inst.components.follower.leader
end

local function CanCastSpell(inst)
    return inst.CanCastSpell and inst.CanCastSpell(inst)
end

local function CastSpell(inst)
    local owner = GetOwner(inst)
    if inst.sg:HasStateTag("busy") and owner and not owner:HasTag("playerghost") then
        return nil
    end

    inst.sg:GoToState("castspell")
end

local Chasni_KitcoonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_KitcoonBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return CanCastSpell(self.inst) end, "Cast Spell",
                DoAction(self.inst, CastSpell)),
        IfNode(function() return not self.inst.sg:HasStateTag("busy") end, "want to run",
                RunAway(self.inst, {tags={"scarytoprey"}, notags={"player"}}, AVOID_SCARY_DIST, AVOID_SCARY_STOP)),
        Follow(self.inst, GetOwner, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),
        StandStill(self.inst),
    }, .25)
    self.bt = BT(self.inst, root)
end

return Chasni_KitcoonBrain
