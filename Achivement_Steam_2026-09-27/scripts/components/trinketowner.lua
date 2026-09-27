local function OnRespawn(inst)
    inst.components.trinketowner:Reset()
end

local TrinketOwner = Class(function(self, inst)
    self.inst = inst
    self.trinketslot = nil
    inst:ListenForEvent("ms_respawnedfromghost", OnRespawn)

    self:UpdateInventory()
end)

function TrinketOwner:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("ms_respawnedfromghost", OnRespawn)
end

function TrinketOwner:Reset()
    self:UpdateInventory()
end

function TrinketOwner:LoadPostPass()
    self:UpdateInventory()
end

function TrinketOwner:GetTrinketSlot()
    return self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem("chasni_trinket_container")
end

function TrinketOwner:UpdateInventory(remove)
    local trinketslot = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem("chasni_trinket_container")
    if remove and trinketslot then
        trinketslot.components.container:DropEverything()
        trinketslot:Remove()
        trinketslot = nil
    end
    if not trinketslot and self.inst.components.allachivcoin and self.inst.components.allachivcoin.trinketowner then
        local newtrinketslot = SpawnPrefab("trinketslot")
        self.inst.components.inventory:Equip(newtrinketslot)
        newtrinketslot.components.container:Close(self.inst)
        newtrinketslot.components.container:Open(self.inst)
        self.trinketslot = newtrinketslot
    else
        self.trinketslot = trinketslot
    end
end

return TrinketOwner
