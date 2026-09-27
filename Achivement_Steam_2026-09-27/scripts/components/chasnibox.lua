local ChasniBox = Class(function(self, inst)
    self.inst = inst
    self.inst:AddTag("chasnibox")
    self.boxedprefab = nil
    self.boxablefn = nil
    self.onboxfn = nil
    self.onunboxfn = nil
end)

function ChasniBox:OnLoad(data)
    self.boxedprefab = data.boxedprefab or nil
    if self.inst._boxedprefab then
        self.inst._boxedprefab:set(self.boxedprefab)
    end
end

function ChasniBox:OnSave()
    local data = {}
    data.boxedprefab = self.boxedprefab or nil
    return data
end

function ChasniBox:SetBoxablefn(fn)
    self.boxablefn = fn
end

function ChasniBox:SetOnBoxfn(fn)
    self.onboxfn = fn
end

function ChasniBox:SetOnUnboxfn(fn)
    self.onunboxfn = fn
end

function ChasniBox:IsBoxable(item)
    return self.boxablefn and self.boxablefn(item) or false, "CANNOT_BE_BOX"
end

function ChasniBox:DoBox(item)
    if self.boxablefn and self.boxablefn(item) then
        self.boxedprefab = item.prefab
        if self.inst._boxedprefab then
            self.inst._boxedprefab:set(self.boxedprefab)
        end
        self.onboxfn(self.inst, item)
        if item.components.stackable then
            item.components.stackable:Get(1):Remove()
        else
            item:Remove()
        end
        return true
    end
    return false
end

function ChasniBox:UnBox(unboxer, remove)
    local iteminside = nil
    if not remove then
        iteminside = chasni_giveItem(unboxer, self.boxedprefab, 1)
    end

    self.boxedprefab = nil
    if self.inst._boxedprefab then
        self.inst._boxedprefab:set("")
    end

    self.onunboxfn(self.inst, iteminside)
    return iteminside
end

return ChasniBox