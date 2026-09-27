local mod_index = rawget(_G, "KnownModIndex")
local standalone_enabled = mod_index ~= nil
    and mod_index:IsModEnabled("TuTienMonsterScaling") or false
local scaling = standalone_enabled
    and require("realm_scaling") or require("tbc_monster_scaling")

local RealmMonsterWorld = Class(function(self, inst)
    self.inst = inst
    self.max_level = 0
end)

function RealmMonsterWorld:SetMaxLevel(level)
    level = tonumber(level)
    if level == nil then return false end
    level = math.min(15, math.max(0, math.floor(level)))
    if level <= self.max_level then return false end

    self.max_level = level
    for _, mob in pairs(Ents) do
        if mob:IsValid() and mob.components ~= nil
            and mob.components.xd_guaiwu_skills ~= nil then
            if standalone_enabled then
                scaling.ApplyMonster(mob, level)
            elseif mob._tbc_monster_kind ~= nil then
                scaling.ApplyMonster(mob, mob._tbc_monster_kind,
                    mob._tbc_monster_days, level)
            end
        end
    end
    self.inst:PushEvent("realm_monster_level_changed", { level = level })
    return true
end

function RealmMonsterWorld:OnSave()
    return { max_level = self.max_level }
end

function RealmMonsterWorld:OnLoad(data)
    if data ~= nil then self:SetMaxLevel(data.max_level) end
end

return RealmMonsterWorld
