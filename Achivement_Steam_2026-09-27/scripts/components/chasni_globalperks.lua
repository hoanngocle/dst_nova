local State = require "functions/globalperkstate"
local removed = require "constants/removedperks"

local GlobalPerks = Class(function(self, inst)
    self.inst = inst
    -- Native world data and changes in this session outrank legacy files/player backups.
    self.known = {}
    self.authority = {}
    State.Initialize()
end)

function GlobalPerks:Apply(name, value, restore, authority)
    TUNING.ACH[name] = value
    self.known[name] = true
    self.authority[name] = authority
    for _, player in ipairs(AllPlayers or {}) do
        local coin = player.components and player.components.allachivcoin
        if coin then
            coin[name] = value
            if restore and coin[name .. "fn"] then coin[name .. "fn"](coin, player) end
        end
    end
end

function GlobalPerks:Set(name, value)
    if removed.isRemoved(name) then return end
    self:Apply(name, value, false, 3)
    State.SaveLegacy()
end

function GlobalPerks:OnSave()
    local data = {}
    for name, perk in pairs(perk_lists) do
        if perk.global and not removed.isRemoved(name) and self.known[name] then
            data[name] = TUNING.ACH[name]
        end
    end
    return data
end

function GlobalPerks:OnLoad(data)
    if type(data) ~= "table" then return end
    for name, perk in pairs(perk_lists) do
        local value = State.Normalize(data[name])
        if perk.global and not removed.isRemoved(name) and value ~= nil then
            self:Apply(name, value, true, 3)
        end
    end
end

function GlobalPerks:RecoverPlayer(data)
    if type(data) ~= "table" then return end
    for name, perk in pairs(perk_lists) do
        local value = State.Normalize(data[name])
        if perk.global and not removed.isRemoved(name) and not self.known[name]
            and value ~= nil and value ~= 0 then
            self:Apply(name, value, true, 1)
        end
    end
end

function GlobalPerks:LoadLegacy(success, encoded)
    if not success or not encoded then return end
    local ok, data = pcall(json.decode, encoded)
    if not ok or type(data) ~= "table" then
        print("CZ-ERROR : Invalid legacy global Perk file; keeping world/player data")
        return
    end
    -- World/session > valid legacy file > player backup. A recreated legacy zero
    -- cannot hide an unlock recovered from the player.
    for name, perk in pairs(perk_lists) do
        local value = State.Normalize(data[name])
        if perk.global and not removed.isRemoved(name) and (self.authority[name] or 0) < 2
            and value ~= nil and value ~= 0 then
            self:Apply(name, value, true, 2)
        end
    end
end

return GlobalPerks
