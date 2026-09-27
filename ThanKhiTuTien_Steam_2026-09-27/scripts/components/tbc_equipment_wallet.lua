local TOOLS = {
    ac_refreshStone = true,
    ad_cleanStone = true,
}

local Wallet = Class(function(self, inst)
    self.inst = inst
    self.items = {}
end)

local function Allowed(id)
    return type(id) == "string" and TOOLS[id] == true
end

local function ValidCount(count)
    return type(count) == "number" and count % 1 == 0 and count > 0
end

function Wallet:Get(id)
    return Allowed(id) and (self.items[id] or 0) or 0
end

function Wallet:Add(id, count)
    if not Allowed(id) or not ValidCount(count) then return false end
    self.items[id] = math.min(9999, (self.items[id] or 0) + count)
    if self.inst.PushEvent ~= nil then self.inst:PushEvent("tbc_wallet_dirty") end
    return true
end

function Wallet:Spend(id, count)
    if not Allowed(id) or not ValidCount(count) or self:Get(id) < count then return false end
    self.items[id] = self.items[id] - count
    if self.inst.PushEvent ~= nil then self.inst:PushEvent("tbc_wallet_dirty") end
    return true
end

function Wallet:OnSave()
    local saved = {}
    for id, count in pairs(self.items) do saved[id] = count end
    return {items = saved}
end

function Wallet:OnLoad(data)
    self.items = {}
    local source = type(data) == "table" and data.items or nil
    if type(source) ~= "table" then return end
    for id, count in pairs(source) do
        if Allowed(id) and ValidCount(count) then
            self.items[id] = math.min(9999, count)
        end
    end
end

return Wallet
