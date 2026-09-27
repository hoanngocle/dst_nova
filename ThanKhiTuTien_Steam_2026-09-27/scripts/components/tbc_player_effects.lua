local Effects = Class(function(self, inst)
    self.inst = inst
    self.sources = {}
    self.active_source = nil
end)

function Effects:SetSource(source)
    self.active_source = source
end

function Effects:Add(source, key, value)
    if type(source) ~= "string" or type(key) ~= "string"
        or type(value) ~= "number" or value ~= value then return false end
    local values = self.sources[source]
    if values == nil then values = {}; self.sources[source] = values end
    values[key] = (values[key] or 0) + value
    return true
end

function Effects:Remove(source, key)
    local values = self.sources[source]
    if values == nil or values[key] == nil then return false end
    values[key] = nil
    if next(values) == nil then self.sources[source] = nil end
    return true
end

function Effects:ClearSource(source)
    self.sources[source] = nil
end

function Effects:Get(key)
    if type(key) ~= "string" then return 0 end
    local total = 0
    for _, values in pairs(self.sources) do total = total + (values[key] or 0) end
    return total
end

function Effects:Has(key)
    return self:Get(key) > 0
end

function Effects:AddEffectValueByKey(key, value)
    return self:Add(self.active_source or "unsourced", key, value)
end

function Effects:ReduceEffectValueByKey(key, value)
    local source = self.active_source or "unsourced"
    local values = self.sources[source]
    if values == nil or type(values[key]) ~= "number" then return false end
    values[key] = values[key] - (tonumber(value) or 0)
    if values[key] <= 0 then return self:Remove(source, key) end
    return true
end

function Effects:GetEffectValueByKey(key)
    return self:Get(key)
end

function Effects:HasSpecialEffect(key)
    return self:Has(key)
end

return Effects
