local Hazards=require('hn_dungeon/boss_hazards')
local T=require('hn_dungeon/minotau_tuning')
local Phases=Class(function(self,inst)
    self.inst=inst;self.phase=1
    inst.components.health:SetMinHealth(1)
    inst:ListenForEvent('minhealth',function() self:BeginTransition() end)
    inst:ListenForEvent('death',function() self.phase='finaldeath';self:Cancel() end)
    inst:ListenForEvent('onremove',function() self:Cancel() end)
end)
function Phases:Cancel()
    if self.task then self.task:Cancel();self.task=nil end
end
function Phases:BeginTransition()
    local inst=self.inst
    if self.phase~=1 or not Hazards.IsActive(inst) then return end
    self.phase='transitioning'
    inst.components.health:SetInvincible(true)
    inst.components.locomotor:Stop()
    if inst.brain then inst.brain:Stop() end
    inst.sg:GoToState('phase_transition')
    local epoch=inst.hn_dungeon_run_epoch
    self.task=inst:DoTaskInTime(T.TRANSITION_TIME,function()
        self.task=nil
        if self.phase~='transitioning' or inst.hn_dungeon_run_epoch~=epoch or not Hazards.IsActive(inst) then return end
        self.phase=2
        inst.components.health:SetPercent(1)
        inst.components.health:SetMinHealth(0)
        inst:ActivateNightmareMode()
        inst.components.health:SetInvincible(false)
        inst.sg:GoToState('initnightmare')
        if inst.brain then inst.brain:Start() end
    end)
end
Phases.OnRemoveFromEntity=Phases.Cancel
return Phases
