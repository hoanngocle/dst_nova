-- Use Tu Tien 18.1 death-flower prefabs for original art and combat behavior.
local SkillDamage=require('util/nyx_skill_damage')
local NyxDomain=Class(function(self,inst)
    self.inst=inst
    self.active=false
    self.effects={}
    self._stop=function() self:Stop() end
    inst:ListenForEvent('death',self._stop)
    inst:ListenForEvent('ms_becameghost',self._stop)
    inst:ListenForEvent('onremove',self._stop)
end)
function NyxDomain:IsActive()
    if self.active and not self.effects[1]:IsValid() then
        self:Stop()
    end
    return self.active
end
function NyxDomain:Stop()
    self.active=false
    SkillDamage.End(self.inst,'absolute_domain')
    for _,fx in ipairs(self.effects) do if fx:IsValid() then fx:Remove() end end
    self.effects={}
end
function NyxDomain:Activate()
    local owner=self.inst
    if not TheWorld.ismastersim or owner.components.health:IsDead() or owner:HasTag('playerghost') then return false end
    self:Stop()
    local buff=SpawnPrefab('xd_luoshen_shentong_death_buff')
    local circle=SpawnPrefab('xd_luoshen_shentong_death_circle')
    if buff then self.effects[#self.effects+1]=buff end
    if circle then self.effects[#self.effects+1]=circle end
    if not buff or not circle or not buff.SetOwner or not circle.SetOwner then self:Stop(); return false end
    local old=owner._xd_luoshen_shentong_buff
    if old and old:IsValid() then old:Remove() end
    SkillDamage.Begin(owner,'absolute_domain')
    buff:SetOwner(owner)
    circle:SetOwner(owner)
    self.active=true
    return true
end
function NyxDomain:OnRemoveFromEntity()
    self:Stop()
    self.inst:RemoveEventCallback('death',self._stop)
    self.inst:RemoveEventCallback('ms_becameghost',self._stop)
    self.inst:RemoveEventCallback('onremove',self._stop)
end
return NyxDomain
