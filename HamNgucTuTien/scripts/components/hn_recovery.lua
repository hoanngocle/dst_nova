local Recovery=Class(function(self,inst) self.inst=inst end)
function Recovery:OnSave() return {owner=self.owner,recovery_id=self.recovery_id} end
function Recovery:OnLoad(data) if data then self.owner=data.owner;self.recovery_id=data.recovery_id end end
return Recovery
