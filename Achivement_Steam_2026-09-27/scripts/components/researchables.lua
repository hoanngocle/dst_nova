local Researchables = Class(function(self, inst)
    self.inst = inst
    self.iswater = false
    self.spawned = false
    self.researchtimer = 0
    self.inst:StartUpdatingComponent(self)
end)

function Researchables:OnLoad(data)
    self.spawned = data.spawned or false
    self.researchtimer = data.researchtimer or 0

    if self.spawned then
        self.inst:AddTag("chasni_researchproduct")
    else
        self.inst:RemoveTag("chasni_researchproduct")
    end
end

function Researchables:OnSave()
    local data = {}
    data.spawned = self.spawned or false
    data.researchtimer = self.researchtimer or 0
    return data
end

function Researchables:OnUpdate(dt)
    if self.researchtimer > 0 then
        self.researchtimer = self.researchtimer - dt
    else
        self.inst:StopUpdatingComponent(self)
    end
end

return Researchables