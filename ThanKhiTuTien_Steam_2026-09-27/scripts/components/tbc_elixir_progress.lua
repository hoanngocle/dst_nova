local Defs=require('tbc_elixir/defs')
local Resources=require('tbc_elixir/resources')
local Immunity=require('tbc_affix/immunity')
local function Count(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return 0 end
    return math.max(0,math.min(Defs.LIMIT,math.floor(value)))
end
local Progress=Class(function(self,inst) self.inst=inst; self.counts={} end)
function Progress:GetCount(key) return Count(self.counts[key]) end
function Progress:GetBonus(stat)
    local total=0
    for key,row in pairs(Defs.BY_KEY) do
        local count=self:GetCount(key)
        if row.stat==stat then total=total+count*row.gain end
        if row.effect==stat and count==Defs.LIMIT then total=total+row.effect_value end
    end
    return total
end
function Progress:HasImmunity(status)
    for key,row in pairs(Defs.BY_KEY) do
        if row.immunity==status and self:GetCount(key)==Defs.LIMIT then return true end
    end
    return false
end
function Progress:CanConsume(key)
    local row=Defs.BY_KEY[key]
    local c=self.inst.components
    if not row or self.inst:HasTag('playerghost') or not c.health or c.health:IsDead() then return false end
    if key=='mana' and not c.xd_htz_lq then return false end
    return self:GetCount(key)<Defs.LIMIT or row.recovery==true
end
function Progress:Snapshot()
    local counts={}
    for _,key in ipairs(Defs.ORDER) do counts[key]=self:GetCount(key) end
    return counts
end
function Progress:Refresh()
    local inst=self.inst
    Resources.Refresh(inst)
    local effects=inst.components.tbc_player_effects
    if effects then
        effects:ClearSource('tbc_elixir')
        for _,key in ipairs({'trueDamageNum','reduceAttackedDamage','criticalHitEffect'}) do
            effects:Add('tbc_elixir',key,self:GetBonus(key))
        end
    end
    if inst.components.locomotor then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst,'tbc_elixir',1+self:GetBonus('speed')/100)
    end
    Immunity.Install(inst)
    for _,key in ipairs(Defs.ORDER) do
        local net=inst['_tbc_elixir_'..key]
        if net then net:set(self:GetCount(key)) end
    end
    inst:PushEvent('tbc_elixir_progress',{counts=self:Snapshot()})
end
function Progress:Consume(key)
    if not self:CanConsume(key) then return false end
    local count=self:GetCount(key)
    if count<Defs.LIMIT then
        self.counts[key]=count+1
        self:Refresh()
    elseif key=='health' then
        self.inst.components.health:DoDelta(100,false,'tbc_elixir_health')
    elseif key=='mana' then
        self.inst.components.xd_htz_lq:DoDelta(100)
    end
    return true,self:GetCount(key)
end
function Progress:OnSave() return {version=1,counts=self:Snapshot()} end
function Progress:OnLoad(data)
    self.counts={}
    local counts=type(data)=='table' and type(data.counts)=='table' and data.counts or {}
    for _,key in ipairs(Defs.ORDER) do self.counts[key]=Count(counts[key]) end
    self.inst:DoTaskInTime(0,function(inst)
        if inst:IsValid() and inst.components.tbc_elixir_progress==self then self:Refresh() end
    end)
end
function Progress:TransferComponent(newinst)
    local target=newinst.components and newinst.components.tbc_elixir_progress
    if target then target.counts=self:Snapshot(); target:Refresh() end
end
return Progress
