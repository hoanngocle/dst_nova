require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/chasnicircling"

local Brain = require "brains/moonbutterflybrain"
local BrainCommon = require "brains/braincommon"

local MAX_CIRCLE_RADIUS = 4
local function GetTargetPos(inst)
    if inst._moonbanner and inst._moonbanner:IsValid() then
        return inst._moonbanner:GetPosition()
    end
    return inst.components.knownlocations:GetLocation("home")
end

local Chasni_MoonButterflyFXBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chasni_MoonButterflyFXBrain:OnStart()
    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        WhileNode(function() return self.inst._moonbanner ~= nil and self.inst._moonbanner:IsValid() end,
                "CircleBanner",
                ChasniCircling(self.inst, function()
                    return self.inst._moonbanner 
                end, 20)
        ),
        Wander(self.inst, GetTargetPos, MAX_CIRCLE_RADIUS)
    }, 1)

    self.bt = BT(self.inst, root)
end

function Chasni_MoonButterflyFXBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return Chasni_MoonButterflyFXBrain