local Owned=Class(function(self,inst)
    self.inst=inst
    inst:ListenForEvent('onputininventory',function()
        local item=inst.components.inventoryitem
        local owner=item and item:GetGrandOwner()
        if owner and owner:HasTag('player') then self.claimed=true end
    end)
end)
function Owned:OnSave()
    if self.run_id or self.inst.hn_detached then
        return {run_id=self.run_id,claimed=self.claimed,detached=self.inst.hn_detached,
            detached_total=self.inst.hn_detached_total,
            health_percent=self.inst.hn_detached and self.inst.components.health:GetPercent() or nil}
    end
end
function Owned:OnLoad(data)
    if data then
        self.run_id=data.run_id;self.claimed=data.claimed
        if data.detached then self.inst:DoTaskInTime(0,function(inst)
            require('hn_dungeon/spawner').ConfigureDetached(inst,data.detached_total or 3)
            if data.health_percent then inst.components.health:SetPercent(data.health_percent) end
        end) end
    end
end
return Owned
