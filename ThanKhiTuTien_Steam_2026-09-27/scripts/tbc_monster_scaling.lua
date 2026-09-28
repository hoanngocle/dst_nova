local Rules = require("tbc_rules")
local M = {}

local REALMS = {
    { level = 12, health = 3, attack = 2 },
    { level = 9, health = 2.5, attack = 1.5 },
    { level = 6, health = 2, attack = 1.3 },
    { level = 3, health = 1.5, attack = 1.15 },
}

function M.GetRealmMultipliers(level)
    level = type(level) == "number" and level or 0
    for _, realm in ipairs(REALMS) do
        if level >= realm.level then
            return realm.health, realm.attack
        end
    end
    return 1, 1
end

function M.WatchHealth(inst)
    local health = inst.components ~= nil and inst.components.health or nil
    if health == nil or health._tbc_monster_watched then return end
    health._tbc_monster_watched = true

    local original_save = health.OnSave
    health.OnSave = function(self, ...)
        local data, refs = original_save(self, ...)
        local state = inst._tbc_monster_scaling
        if data ~= nil and state ~= nil then
            data.tbc_scaled_maxhealth = self.maxhealth
            data.tbc_total_hp_multiplier = state.hp_multiplier
        end
        return data, refs
    end

    local original_load = health.OnLoad
    health.OnLoad = function(self, data, ...)
        if data ~= nil then
            inst._tbc_loaded_monster_health = {
                prefab_max = self.maxhealth,
                current = data.health,
                native_max = data.maxhealth,
                scaled_max = data.tbc_scaled_maxhealth,
                multiplier = data.tbc_total_hp_multiplier,
                old_realm_max = data.tutien_realm_maxhealth,
                old_realm_multiplier = data.tutien_realm_multiplier,
            }
        end
        return original_load(self, data, ...)
    end
end

local function SetDefaultDamage(combat, value)
    if type(combat.SetDefaultDamage) == "function" then
        combat:SetDefaultDamage(value)
    else
        combat.defaultdamage = value
    end
end

local function SavedHealthBasis(loaded, current_max)
    local old_max = current_max
    local old_multiplier = 1
    local preserve_absolute = false
    if type(loaded.scaled_max) == "number" and loaded.scaled_max > 0
        and type(loaded.multiplier) == "number" and loaded.multiplier > 0 then
        old_max = loaded.scaled_max
        old_multiplier = loaded.multiplier
    elseif type(loaded.old_realm_max) == "number" and loaded.old_realm_max > 0 then
        -- An old realm save may also contain Thần Khí Tu Tiên's day bonus.
        old_max = loaded.old_realm_max
        old_multiplier = type(loaded.prefab_max) == "number"
            and loaded.prefab_max > 0
            and old_max / loaded.prefab_max or 1
        preserve_absolute = true
    elseif type(loaded.native_max) == "number" and loaded.native_max > 0 then
        -- Older health saves can already include a stat multiplier.
        old_max = loaded.native_max
        old_multiplier = type(loaded.prefab_max) == "number"
            and loaded.prefab_max > 0
            and old_max / loaded.prefab_max or 1
        preserve_absolute = true
    else
        preserve_absolute = true
    end
    return old_max, old_multiplier, preserve_absolute
end

function M.ApplyMonster(inst, kind, days, level)
    local components = inst.components
    local health = components ~= nil and components.health or nil
    local combat = components ~= nil and components.combat or nil
    if health == nil or (combat == nil and kind ~= "realm_only") or health.maxhealth == nil
        or health.maxhealth <= 0 or health.currenthealth == nil
        or health.currenthealth <= 0 then
        return false
    end

    local state = inst._tbc_monster_scaling
    if state == nil then
        local day_hp, day_attack = Rules.BaseHealthMultiplier(inst._tbc_monster_base_kind), 1
        if kind ~= "realm_only" then
            day_hp, day_attack = Rules.MonsterMultipliers(kind, days)
        end
        state = {
            kind = kind,
            days = days,
            day_hp = day_hp,
            day_attack = day_attack,
            hp_multiplier = 1,
            attack_multiplier = 1,
        }
        inst._tbc_monster_scaling = state
    end
    state.level = level

    local realm_hp, realm_attack = 1, 1
    if kind ~= "realm_only" or components.xd_guaiwu_skills ~= nil then
        realm_hp, realm_attack = M.GetRealmMultipliers(level)
    end
    local hp_multiplier = state.day_hp * realm_hp
    local attack_multiplier = state.day_attack * realm_attack

    local loaded = inst._tbc_loaded_monster_health
    if loaded ~= nil or state.hp_multiplier ~= hp_multiplier then
        local old_max = health.maxhealth
        local old_current = health.currenthealth
        local old_multiplier = state.hp_multiplier
        local preserve_absolute = false
        if loaded ~= nil then
            inst._tbc_loaded_monster_health = nil
            if type(loaded.current) == "number" then
                old_current = loaded.current
            end
            old_max, old_multiplier, preserve_absolute =
                SavedHealthBasis(loaded, old_max)
        end
        local target_max = old_max * hp_multiplier / old_multiplier
        local target_percent = preserve_absolute
            and math.min(1, old_current / target_max)
            or math.min(1, old_current / old_max)
        state.hp_multiplier = hp_multiplier
        health:SetMaxHealth(target_max)
        health:SetPercent(target_percent, true, "tbc_monster_scaling")
    end

    if combat == nil then return true end

    if not state.attack_events_installed and type(inst.ListenForEvent) == "function"
        and type(combat.GetWeapon) == "function" then
        state.attack_events_installed = true
        local function RefreshAttack()
            M.ApplyMonster(inst, state.kind, state.days, state.level)
        end
        inst:ListenForEvent("equip", RefreshAttack)
        inst:ListenForEvent("unequip", RefreshAttack)
    end

    local has_weapon = type(combat.GetWeapon) == "function"
        and combat:GetWeapon() ~= nil
    local use_default_damage = not has_weapon
        and type(combat.defaultdamage) == "number"
        and combat.defaultdamage > 0
    local external = combat.externaldamagemultipliers
    if use_default_damage then
        local old_factor = state.attack_mode == "default"
            and state.attack_multiplier or 1
        if state.attack_mode ~= "default" or old_factor ~= attack_multiplier then
            SetDefaultDamage(combat,
                combat.defaultdamage * attack_multiplier / old_factor)
        end
        state.attack_mode = "default"
        if external ~= nil then
            external:SetModifier("tbc_monster_scaling", 1,
                "tbc_monster_scaling")
        end
    else
        if state.attack_mode == "default" then
            SetDefaultDamage(combat,
                combat.defaultdamage / state.attack_multiplier)
        end
        state.attack_mode = "external"
        if external ~= nil then
            external:SetModifier("tbc_monster_scaling", attack_multiplier,
                "tbc_monster_scaling")
        end
    end
    state.attack_multiplier = attack_multiplier
    return true
end

return M
