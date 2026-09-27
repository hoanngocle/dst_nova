local TIERS = {
    [1] = { bonus = 0.05, duration = 30 },
    [2] = { bonus = 0.15, duration = 90 },
    [3] = { bonus = 0.25, duration = 270 },
}

local Luck = Class(function(self, inst)
    self.inst = inst
    self.tier = 0
    self.expires_at = 0
end)

function Luck:GetBonus()
    local row = TIERS[self.tier]
    return row ~= nil and GetTime() < self.expires_at and row.bonus or 0
end

function Luck:Apply(tier)
    local row = TIERS[tier]
    if row == nil then return false end
    if self:GetBonus() > row.bonus then return false end
    self.tier = tier
    self.expires_at = GetTime() + row.duration
    return true
end

function Luck:OnSave()
    return { tier = self.tier, remaining = math.max(0, self.expires_at - GetTime()) }
end

function Luck:OnLoad(data)
    if type(data) ~= "table" or TIERS[data.tier] == nil then return end
    self.tier = data.tier
    self.expires_at = GetTime() + math.max(0, tonumber(data.remaining) or 0)
end

return Luck
