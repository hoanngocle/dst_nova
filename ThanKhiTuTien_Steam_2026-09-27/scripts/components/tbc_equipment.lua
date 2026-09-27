local Defs = require("tbc_equipment/solo_defs")

local Equip = Class(function(self, inst)
    self.inst = inst
    self.affix_limit = 1
    self.affixes = {}
end)

local function ValidIndex(list, index)
    return type(index) == "number" and index % 1 == 0
        and index >= 1 and index <= #list
end

local function HasId(list, id)
    for _, value in ipairs(list) do
        if value == id or type(value) == "table" and value.id == id then return true end
    end
    return false
end

function Equip:HasEffectByName(id)
    return HasId(self.affixes, id)
end

function Equip:Refresh()
    if self.inst ~= nil and self.inst._tbc_effect_owner ~= nil then
        require("tbc_equipment/effect_runtime").Sync(self.inst)
    end
    if self.inst ~= nil and self.inst._tbc_equip_state ~= nil then
        local affixes = {}
        for _, row in ipairs(self.affixes) do
            affixes[#affixes + 1] = row.id .. ":" .. tostring(row.value or 0)
        end
        self.inst._tbc_equip_state:set(table.concat(affixes, "|"))
    end
    if self.inst ~= nil and self.inst.PushEvent ~= nil then
        self.inst:PushEvent("tbc_equipment_dirty")
    end
end

function Equip:SetAffixLimit(limit)
    if type(limit) ~= "number" then return false end
    self.affix_limit = math.max(0, math.floor(limit))
    return true
end

function Equip:AddAffix(id, value)
    local row = type(id) == "string" and Defs.Affixes[id] or nil
    if row == nil then return false, "UNKNOWN_AFFIX" end
    if #self.affixes >= self.affix_limit then return false, "AFFIX_LIMIT" end
    if row.only_one and HasId(self.affixes, id) then return false, "DUPLICATE_AFFIX" end
    if row.is_suit then
        for _, affix in ipairs(self.affixes) do
            local current = Defs.Affixes[affix.id]
            if current ~= nil and current.is_suit then return false, "SUIT_EXISTS" end
        end
    end
    if row.check_equip_can_add ~= nil then
        local ok, reason = row.check_equip_can_add(self.inst)
        if not ok then return false, reason or "WRONG_EQUIPMENT" end
    end
    if row.value_range ~= nil then
        local low, high = row.value_range.min, row.value_range.max
        if type(value) ~= "number" or value < low or value > high then
            return false, "INVALID_AFFIX_VALUE"
        end
    end
    if row.start_fn ~= nil then row.start_fn(self.inst, value) end
    self.affixes[#self.affixes + 1] = {id = id, value = value}
    self:Refresh()
    return true
end

function Equip:RemoveAffix(index)
    if not ValidIndex(self.affixes, index) then return false, "INVALID_AFFIX_INDEX" end
    local affix = self.affixes[index]
    local row = Defs.Affixes[affix.id]
    if row ~= nil and row.end_fn ~= nil then row.end_fn(self.inst, affix.value) end
    table.remove(self.affixes, index)
    self:Refresh()
    return affix
end

function Equip:RerollAffixValues(rng)
    if #self.affixes == 0 then return false, "NO_AFFIX" end
    rng = rng or math.random
    for _, affix in ipairs(self.affixes) do
        local row = Defs.Affixes[affix.id]
        if row ~= nil and row.value_range ~= nil then
            local old = affix.value
            if row.end_fn ~= nil then row.end_fn(self.inst, old) end
            affix.value = rng(row.value_range.min, row.value_range.max)
            if row.start_fn ~= nil then row.start_fn(self.inst, affix.value) end
        end
    end
    self:Refresh()
    return true
end

function Equip:TransferTo(target)
    if target == nil or #self.affixes == 0 or #target.affixes > 0
        or #self.affixes > target.affix_limit then return false, "CANNOT_INHERIT" end
    for _, affix in ipairs(self.affixes) do
        local row = Defs.Affixes[affix.id]
        if row ~= nil and row.check_equip_can_add ~= nil then
            if not row.check_equip_can_add(target.inst) then return false, "WRONG_EQUIPMENT" end
        end
    end
    for _, affix in ipairs(self.affixes) do
        local ok, reason = target:AddAffix(affix.id, affix.value)
        if not ok then
            while #target.affixes > 0 do target:RemoveAffix(#target.affixes) end
            return false, reason
        end
    end
    target:Refresh()
    return true
end

function Equip:OnSave()
    return {affixes = self.affixes}
end

function Equip:OnLoad(data)
    if type(data) ~= "table" then return end
    self.affixes = {}
    for _, row in ipairs(type(data.affixes) == "table" and data.affixes or {}) do
        if type(row) == "table" then self:AddAffix(row.id, row.value) end
    end
    self:Refresh()
end

return Equip
