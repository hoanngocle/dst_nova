local Catalog = require("tbc_catalog")
local Defs = require("tbc_affix/defs")
local Slots = require("tbc_affix/slots")
local Display = require("tbc_display")
local StrengthenMath = require("tbc_strengthen_math")
local StrengthenEffects = require("tbc_strengthen_effects")

local function IsRanged(inst, weapon)
    return inst.prefab == "elderwand"
        or (weapon.CanRangedAttack ~= nil and weapon:CanRangedAttack())
end

local function IsRangedException(inst)
    return inst.prefab == "hh_daogam3" or inst.prefab == "hh_daogam4"
end

local Upgrade = Class(function(self, inst)
    self.inst = inst
    self.level = 0
    self.affixes = {}
    local weapon = inst.components.weapon
    local armor = inst.components.armor
    self.base_damage = weapon ~= nil and weapon.damage or nil
    self.base_absorb = armor ~= nil and armor.absorb_percent or nil
    self.last_damage = nil
    self.last_absorb = nil
end)

function Upgrade:GetKind()
    if self.inst.components.weapon ~= nil then return "weapon" end
    if self.inst.components.armor ~= nil then return "armor" end
    local equippable = self.inst.components.equippable
    local slot = equippable ~= nil and equippable.equipslot or nil
    if EQUIPSLOTS ~= nil and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
        return "equipment"
    end
    return nil
end

function Upgrade:IsWeaponMilestone()
    local equippable = self.inst.components.equippable
    local slot = equippable ~= nil and equippable.equipslot or nil
    return self:GetKind() == "weapon" and (EQUIPSLOTS == nil
        or slot ~= EQUIPSLOTS.HEAD and slot ~= EQUIPSLOTS.BODY)
end

function Upgrade:GetStrengthenPreview()
    local kind = self:GetKind()
    if kind == "weapon" then
        local weapon = self.inst.components.weapon
        local current = weapon.damage
        local base = self.base_damage
        if type(current) == "number" and type(base) == "number" then
            local ranged = IsRanged(self.inst, weapon)
            local exception = IsRangedException(self.inst)
            local old_value = StrengthenMath.Weapon(base, self.level, ranged, exception)
            local new_value = StrengthenMath.Weapon(base, self.level + 1, ranged, exception)
            return kind, current, current + new_value - old_value
        end
        if type(base) == "function" then
            local ok, sampled = pcall(base, self.inst)
            if ok and type(sampled) == "number" then
                local ranged = IsRanged(self.inst, weapon)
                local exception = IsRangedException(self.inst)
                return "weapon_bonus",
                    StrengthenMath.Weapon(sampled, self.level, ranged, exception) - sampled,
                    StrengthenMath.Weapon(sampled, self.level + 1, ranged, exception) - sampled
            end
            return "weapon_bonus", nil, nil
        end
    elseif kind == "armor" then
        local current = self.inst.components.armor.absorb_percent
        local base = self.base_absorb
        if type(current) == "number" and type(base) == "number" then
            local old_value = StrengthenMath.Armor(base, self.level)
            local new_value = StrengthenMath.Armor(base, self.level + 1)
            return kind, current * 100, math.min(99.99, (current + new_value - old_value) * 100)
        end
    end
    return kind or "unknown", nil, nil
end

function Upgrade:ApplyStats()
    local weapon = self.inst.components.weapon
    if weapon ~= nil then
        if weapon.damage ~= self.last_damage and weapon.damage ~= nil then
            self.base_damage = weapon.damage
        end
        if self.base_damage ~= nil then
            local base = self.base_damage
            local ranged = IsRanged(self.inst, weapon)
            local exception = IsRangedException(self.inst)
            local damage = nil
            if type(base) == "function" then
                local level = self.level
                damage = function(...)
                    local raw = base(...)
                    if type(raw) ~= "number" then return raw end
                    return StrengthenMath.Weapon(raw, level, ranged, exception)
                end
            elseif type(base) == "number" then
                damage = StrengthenMath.Weapon(base, self.level, ranged, exception)
            end
            if damage ~= nil then
                if weapon.SetDamage ~= nil then weapon:SetDamage(damage) else weapon.damage = damage end
                self.last_damage = weapon.damage
            end
        end
    end
    local armor = self.inst.components.armor
    if armor ~= nil then
        if armor.absorb_percent ~= self.last_absorb and type(armor.absorb_percent) == "number" then
            self.base_absorb = armor.absorb_percent
        end
        if type(self.base_absorb) == "number" then
            armor.absorb_percent = math.min(0.9999,
                StrengthenMath.Armor(self.base_absorb, self.level))
            self.last_absorb = armor.absorb_percent
        end
    end
    self:UpdateDisplay()
end

function Upgrade:GetCombatStats()
    local stats = { crit_rate = 0, crit_effect = 0, pierce = 0 }
    if self:IsWeaponMilestone() and self.level >= 16 then
        stats.crit_effect = 50
    end
    for _, affix in ipairs(self.affixes) do
        local row = Catalog.affixes[affix.id]
        if row ~= nil and row.stat == "crit" then
            stats.crit_rate = stats.crit_rate + affix.value
            stats.crit_effect = stats.crit_effect + affix.value
        elseif row ~= nil and row.stat == "pierce" then
            stats.pierce = stats.pierce + affix.value
        end
    end
    return stats
end

function Upgrade:UpdateDisplay()
    if self.inst._tbc_detail ~= nil then
        self.inst._tbc_detail:set(Display.Encode(self))
    end
    if self.inst._tbc_strengthen_stat ~= nil then
        local kind, current = self:GetStrengthenPreview()
        local stat = ""
        if type(current) == "number" then
            if kind == "weapon" then
                stat = "Sát thương hiện tại: " .. string.format("%g", current)
                if type(self.base_damage) == "number" then
                    local weapon = self.inst.components.weapon
                    local bonus = StrengthenMath.Weapon(self.base_damage, self.level,
                        IsRanged(self.inst, weapon), IsRangedException(self.inst)) - self.base_damage
                    stat = stat .. " (+" .. string.format("%g", math.max(0, bonus)) .. " từ cường hóa)"
                end
            elseif kind == "weapon_bonus" then
                stat = "Sát thương cộng thêm: +" .. string.format("%g", current)
            elseif kind == "armor" then
                stat = "Giảm sát thương hiện tại: " .. string.format("%.2f%%", current)
            end
        end
        self.inst._tbc_strengthen_stat:set(stat)
    end
end

function Upgrade:SetLevel(level)
    if self:GetKind() == nil or type(level) ~= "number" then return false end
    self.level = math.min(16, math.max(0, math.floor(level)))
    self:ApplyStats()
    StrengthenEffects.Sync(self.inst, self.level)
    require("tbc_affix/coordinator").OnItemChanged(self.inst)
    return true
end

function Upgrade:NotifyAffixesChanged()
    if self.inst.PushEvent ~= nil then self.inst:PushEvent("tbc_affixes_changed") end
    require("tbc_affix/coordinator").OnItemChanged(self.inst)
end

function Upgrade:AddAffix(id, value)
    local row = Defs.by_code[id]
    if not Slots.CanAdd(self.inst, self.affixes, row)
        or not Defs.IsValidValue(id, value) then return false end
    self.affixes[#self.affixes + 1] = { id = id, value = value }
    self:ApplyStats()
    StrengthenEffects.Sync(self.inst, self.level)
    self:NotifyAffixesChanged()
    return true
end

function Upgrade:RemoveAffix()
    return self:RemoveAffixAt(#self.affixes)
end

function Upgrade:RemoveAffixAt(index)
    if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #self.affixes then return false end
    table.remove(self.affixes, index)
    self:ApplyStats()
    self:NotifyAffixesChanged()
    return true
end

function Upgrade:RemoveRandomAffix()
    if #self.affixes == 0 then return false end
    table.remove(self.affixes, math.random(1, #self.affixes))
    self:ApplyStats()
    self:NotifyAffixesChanged()
    return true
end

function Upgrade:RerollAffix(rng)
    if #self.affixes == 0 then return false end
    rng = rng or math.random
    local values = {}
    for index, affix in ipairs(self.affixes) do
        local row = Defs.by_code[affix.id]
        if row == nil then return false end
        if row.fixed then
            values[index] = 0
        else
            local count = math.floor((row.max - row.min) / row.step) + 1
            local pick = rng(count)
            if type(pick) ~= "number" or pick ~= math.floor(pick)
                or pick < 1 or pick > count then return false end
            values[index] = row.min + (pick - 1) * row.step
        end
    end
    for index, affix in ipairs(self.affixes) do affix.value = values[index] end
    self:ApplyStats()
    self:NotifyAffixesChanged()
    return true
end

function Upgrade:OnSave()
    return {
        level = self.level,
        affixes = self.affixes,
        base_damage = type(self.base_damage) == "number" and self.base_damage or nil,
        base_absorb = self.base_absorb,
    }
end

function Upgrade:OnLoad(data)
    if type(data) ~= "table" then return end
    self.level = math.min(16, math.max(0, math.floor(tonumber(data.level) or 0)))
    if type(data.base_damage) == "number" then self.base_damage = data.base_damage end
    local revised_base = self.inst.prefab == "ttk_lucnguyenkiemdong" and 88
        or self.inst.prefab == "ttk_vankiemquytong" and 93 or nil
    if revised_base ~= nil and (self.base_damage == 0
        or self.base_damage == 50 or self.base_damage == 100) then
        -- Migrate both original values and the brief 100-damage version.
        self.base_damage = revised_base
        self.last_damage = self.inst.components.weapon.damage
    end
    if type(data.base_absorb) == "number" then self.base_absorb = data.base_absorb end
    self.affixes = {}
    for _, row in ipairs(type(data.affixes) == "table" and data.affixes or {}) do
        local def = type(row) == "table" and Defs.by_code[row.id] or nil
        if Slots.CanAdd(self.inst, self.affixes, def)
            and Defs.IsValidValue(row.id, row.value) then
            self.affixes[#self.affixes + 1] = { id = row.id, value = row.value }
        end
    end
    self:ApplyStats()
    StrengthenEffects.Sync(self.inst, self.level)
    self:NotifyAffixesChanged()
end

return Upgrade
