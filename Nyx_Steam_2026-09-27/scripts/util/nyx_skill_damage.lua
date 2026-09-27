local SkillDamage = {}

local NATIVE_SOURCES = {
    absolute_domain = {"luoshen", "shentong_fx"},
    triflame_fan = {"htz_firefx"},
    yellow_river = {"yunxiao", "jjj_aoeent"},
}

local function IsFiniteNonnegative(value)
    return type(value) == "number" and value == value
        and value >= 0 and value < math.huge
end

function SkillDamage.Begin(owner, skill)
    local components = owner.components or {}
    local inventory = components.inventory
    local weapon = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS ~= nil and EQUIPSLOTS.HANDS or nil) or nil
    local weapon_component = weapon ~= nil and weapon.components ~= nil
        and weapon.components.weapon or nil
    local damage = 0
    local found = false
    if weapon_component ~= nil and weapon_component.GetDamage ~= nil then
        local ok, result = pcall(weapon_component.GetDamage, weapon_component, owner)
        if ok and IsFiniteNonnegative(result) then
            damage = result
            found = true
        end
    end
    if not found and weapon_component ~= nil
        and IsFiniteNonnegative(weapon_component.damage) then
        damage = weapon_component.damage
    end
    owner._nyx_skill_damage_bonus = owner._nyx_skill_damage_bonus or {}
    owner._nyx_skill_damage_bonus[skill] = damage
end

function SkillDamage.End(owner, skill)
    if owner ~= nil and owner._nyx_skill_damage_bonus ~= nil then
        owner._nyx_skill_damage_bonus[skill] = nil
        if next(owner._nyx_skill_damage_bonus) == nil then
            owner._nyx_skill_damage_bonus = nil
        end
    end
end

function SkillDamage.Scale(owner, skill, damage)
    local bonuses = owner ~= nil and owner._nyx_skill_damage_bonus or nil
    return damage + (bonuses ~= nil and bonuses[skill] or 0)
end

function SkillDamage.ScaleNative(owner, damage, source)
    if owner == nil or owner.prefab ~= "nyx" or type(source) ~= "string" then
        return damage
    end
    local bonuses = owner._nyx_skill_damage_bonus
    if bonuses == nil then return damage end
    source = string.lower(source)
    for skill, fragments in pairs(NATIVE_SOURCES) do
        if bonuses[skill] ~= nil then
            local correct_domain_buff = true
            if skill == "absolute_domain" then
                local domain = owner.components ~= nil and owner.components.nyx_domain or nil
                local buff = domain ~= nil and domain.effects[1] or nil
                correct_domain_buff = buff ~= nil and buff:IsValid()
            end
            local matches = true
            for _, fragment in ipairs(fragments) do
                if not string.find(source, fragment, 1, true) then
                    matches = false
                    break
                end
            end
            if matches and correct_domain_buff then return damage + bonuses[skill] end
        end
    end
    return damage
end

function SkillDamage.InstallNativeHook(add_component_post_init)
    add_component_post_init("combat", function(combat)
        local original = combat.GetAttacked
        combat.GetAttacked = function(self, attacker, damage, weapon, stimuli, ...)
            if attacker ~= nil and attacker.prefab == "nyx"
                and attacker._nyx_skill_damage_bonus ~= nil
                and type(damage) == "number" and weapon == nil
                and debug ~= nil and debug.getinfo ~= nil then
                local caller = debug.getinfo(2, "S")
                damage = SkillDamage.ScaleNative(attacker, damage,
                    caller ~= nil and caller.source or nil)
            end
            return original(self, attacker, damage, weapon, stimuli, ...)
        end
    end)
end

local function Pack(...)
    return {n = select("#", ...), ...}
end

function SkillDamage.Apply(owner, target, damage, stimuli)
    local combat = target.components.combat
    if owner.components.hh_player == nil then
        return combat:GetAttacked(owner, damage, nil, stimuli)
    end

    -- Solo treats weapon=nil as melee in its onhitother splash handler.
    -- Borrow its splash recursion guard for this synchronous skill hit only;
    -- keep the normal combat path (crit, armor, other procs and kill credit).
    -- Preserve an outer guard, including nil/false, on nested hits or errors.
    local previous = owner._is_splashing_aoe
    owner._is_splashing_aoe = true
    local result = Pack(pcall(combat.GetAttacked, combat, owner, damage, nil, stimuli))
    owner._is_splashing_aoe = previous
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
end

return SkillDamage
