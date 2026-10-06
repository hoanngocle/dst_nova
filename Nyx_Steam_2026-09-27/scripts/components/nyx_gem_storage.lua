local Storage = Class(function(self, inst)
    self.inst = inst
    self.box = nil
    inst:ListenForEvent('ms_becameghost', function() self:Close() end)
    inst:ListenForEvent('death', function() self:Close() end)
    inst:ListenForEvent('onremove', function() self:OnRemoveFromEntity() end)
    -- Klei's character-reroll save omits custom components. Return the items
    -- to the world before the old character and its transient box are removed.
    inst:ListenForEvent('ms_playerreroll', function()
        self:Close()
        if self.box ~= nil and self.box:IsValid() then
            self.box.components.container:DropEverything()
        end
    end)
    inst:ListenForEvent('player_despawn', function()
        self:Close()
        if self.box ~= nil and self.box:IsValid() then
            self.box:PushEvent('player_despawn')
        end
    end)
end)

function Storage:Attach(box)
    self.box = box
    -- The character save owns this record, including shard migration.
    box.persists = false
    box.nyx_owner = self.inst
    box.entity:SetParent(self.inst.entity)
    box.Transform:SetPosition(0, 0, 0)
    box.Network:SetClassifiedTarget(self.inst)
end

function Storage:Close()
    if self.box ~= nil and self.box:IsValid() then
        self.box.components.container:Close()
    end
end

function Storage:GetContainer()
    if not self.inst:IsValid() or self.inst:HasTag('playerghost')
        or self.inst.components.health ~= nil and self.inst.components.health:IsDead() then
        return nil
    end
    if self.box == nil or not self.box:IsValid() then
        local box = SpawnPrefab('nyx_gem_storage')
        if box == nil then return nil end
        self:Attach(box)
    end
    return self.box.components.container
end

function Storage:Toggle()
    local container = self:GetContainer()
    if container == nil then return false end
    if container:IsOpenedBy(self.inst) then
        container:Close(self.inst)
    else
        container:Open(self.inst)
    end
    return true
end

function Storage:OnSave()
    if self.box ~= nil and self.box:IsValid() then
        local record, refs = self.box:GetSaveRecord()
        return {box=record}, refs
    end
end

function Storage:OnLoad(data, newents)
    if data == nil or data.box == nil or self.box ~= nil then return end
    if data.box.prefab ~= 'nyx_gem_storage' then return end
    local box = SpawnSaveRecord(data.box, newents)
    if box ~= nil then self:Attach(box) end
end

function Storage:OnRemoveFromEntity()
    self:Close()
    if self.box ~= nil and self.box:IsValid() then self.box:Remove() end
    self.box = nil
end

return Storage
