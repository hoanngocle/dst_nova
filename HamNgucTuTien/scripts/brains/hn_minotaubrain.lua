-- Solo Guardian's health/phase attack selection, scoped to arena targets.
require('behaviours/chaseandattack')
require('behaviours/standstill')
local H=require('hn_dungeon/boss_hazards')
local Guardian=Class(Brain,function(self,inst) Brain._ctor(self,inst) end)
local function choose(inst)
    if not H.IsActive(inst) or inst.sg:HasStateTag('busy') or not H.CanTarget(inst,inst.components.combat.target) then return false end
    local hp=inst.components.health:GetPercent()
    local nightmare=inst:InNightmareMode()
    local timer=inst.components.timer
    local choice
    if nightmare and hp<=.2 and not timer:TimerExists('ringoffire_cd') then choice='ringoffire'
    elseif ((not nightmare and hp<=.5) or (nightmare and hp>=.4 and hp<=.7)) and not timer:TimerExists('slam_cd') then choice='slam'
    elseif hp<=.9 and not timer:TimerExists('charge_cd') then choice=nightmare and 'goring' or 'pinball'
    elseif nightmare and not inst.components.combat:InCooldown() then choice='teleport' end
    if choice then inst.sg:GoToState('attack',choice);return true end
    return false
end
function Guardian:OnStart()
    self.bt=BT(self.inst,PriorityNode({
        WhileNode(function() return choose(self.inst) end,'Special attack',StandStill(self.inst)),
        ChaseAndAttack(self.inst),StandStill(self.inst),
    },.25))
end
return Guardian
