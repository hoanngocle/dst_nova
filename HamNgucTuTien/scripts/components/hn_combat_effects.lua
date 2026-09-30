local Effects=Class(function(self,inst)
    self.inst=inst;self.effects={}
    inst:ListenForEvent('death',function() self:RemoveAll() end)
end)
function Effects:Apply(id,source,duration,params)
    assert(id=='speed','unsupported dungeon effect')
    self:RemoveSource(source)
    local locomotor=self.inst.components.locomotor
    if not locomotor then return end
    locomotor:SetExternalSpeedMultiplier(source,'hn_speed',params.multiplier or 2)
    self.effects[source]={task=self.inst:DoTaskInTime(duration,function() self:RemoveSource(source) end)}
end
function Effects:RemoveSource(source)
    local e=self.effects[source];if not e then return end
    e.task:Cancel();self.effects[source]=nil
    if self.inst.components.locomotor then self.inst.components.locomotor:RemoveExternalSpeedMultiplier(source,'hn_speed') end
end
function Effects:RemoveAll()
    local sources={};for source in pairs(self.effects) do sources[#sources+1]=source end
    for _,source in ipairs(sources) do self:RemoveSource(source) end
end
Effects.OnRemoveFromEntity=Effects.RemoveAll
return Effects
