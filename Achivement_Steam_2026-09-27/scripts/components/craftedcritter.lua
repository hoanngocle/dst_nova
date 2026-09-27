local CraftedCritter = Class(function(self, inst)
    self.inst = inst
    self.recipes = {}
end)

function CraftedCritter:AddRecipe(name)
    if not self.recipes[name] then
        self.recipes[name] = true
        self:Sync()
    end
end

function CraftedCritter:Sync()
    if self.inst and self.inst.craftedcritter then
        local parts = {}
        for k, _ in pairs(self.recipes) do
            table.insert(parts, k)
        end
        local str = table.concat(parts, ",")
        self.inst.craftedcritter:set(str)
        self.inst:DoTaskInTime(0.1, function()
            SendModRPCToClient(GetClientModRPC("CrafterChest", "RefreshCrafting"), self.inst)
        end)
    end
end

function CraftedCritter:OnSave()
    return { recipes = self.recipes }
end

function CraftedCritter:SaveForReroll()
    return { recipes = self.recipes }
end

function CraftedCritter:OnLoad(data)
    if data and data.recipes then
        self.recipes = data.recipes
        self:Sync()
    end
end

function CraftedCritter:LoadForReroll(data)
    if data and data.recipes then
        self.recipes = data.recipes
        self:Sync()
    end
end

return CraftedCritter