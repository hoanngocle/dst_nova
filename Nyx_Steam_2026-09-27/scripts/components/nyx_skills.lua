local Source=require('nyx/source18')
local Effects=require('nyx/effects')
local Net=require('nyx/skillnet')
local Skills=Class(function(self,inst)
    self.inst=inst
    self.controller=require('nyx/casting').New({
        clock=GetTime,read=function() return Source.Read(inst) end,
        alive=function() return inst:IsValid() and not inst:HasTag('playerghost') and not inst.components.health:IsDead() end,
        valid=function(def,p)
            if inst.sg and ((inst.sg:HasStateTag('busy') and not inst._nyx_cast_authorized) or inst.sg:HasStateTag('frozen') or inst.sg:HasStateTag('knockout')) then return false,'Đang bận.' end
            if def.target=='point' then
                if inst:GetDistanceSqToPoint(p.x,0,p.z)>def.range*def.range then return false,'Ngoài tầm thi triển.' end
                local allowwater=def.id~='purple_gather'
                if not TheWorld.Map:IsPassableAtPoint(p.x,0,p.z,allowwater) and not TheWorld.Map:GetPlatformAtPoint(p.x,p.z) then return false,'Địa hình không hợp lệ.' end
                if TheWorld.Map:IsGroundTargetBlocked(Vector3(p.x,0,p.z)) then return false,'Vị trí bị chắn.' end
            end
            return true
        end,
        spend=function(n) return Source.Spend(inst,n) end,
        refund=function(n) Source.Refund(inst,n) end,
        prepare=function(id,p) return Effects.Prepare(inst,id,p) end,
    })
    self._stop=function() self:StopAll('lifecycle') end
    inst:ListenForEvent('_xd_htz_lqdelta',function(_,data)
        if data and data.current<=0 then
            self.controller:Stop('purple_eye','no_resource')
            self.controller:Stop('moon_wings','no_resource')
        end
    end)
    for _,e in ipairs({'death','ms_becameghost','onremove'}) do inst:ListenForEvent(e,self._stop) end
    self.tick=inst:DoPeriodicTask(1,function() self.controller:Tick(); self:Publish() end)
    self.publish=inst:DoPeriodicTask(.25,function() self:Publish() end)
end)
function Skills:Request(id,p,request_id)
    local ok,reason=self.controller:Request(id,p,request_id)
    if not ok and reason and self.inst.components.talker then self.inst.components.talker:Say(reason) end
    self:Publish(); return ok,reason
end
function Skills:Publish()
    local s=self.controller:Snapshot()
    s.blink_cd=self.inst.components.nyx_blink:GetCooldownRemaining()
    local domain=self.inst.components.nyx_domain
    s.active.absolute_domain=domain~=nil and domain:IsActive() or false
    Net.Publish(self.inst,s)
end
function Skills:StopAll(reason) self.controller:StopAll(reason) end
function Skills:OnSave() return self.controller:Save() end
function Skills:OnLoad(data) self.controller:Load(data) end
function Skills:OnRemoveFromEntity()
    self:StopAll('removed')
    self.tick:Cancel(); self.publish:Cancel()
    for _,e in ipairs({'death','ms_becameghost','onremove'}) do self.inst:RemoveEventCallback(e,self._stop) end
end
return Skills
