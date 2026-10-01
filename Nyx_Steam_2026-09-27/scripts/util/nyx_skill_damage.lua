local SkillDamage = {}

local LEVEL_RATES = {
    absolute_domain = 0.3,
    triflame_fan = 0.25,
    yellow_river = 0.3,
    eternal_night = 0.25,
    spirit_sword = 0.15,
}

local function IsFiniteNonnegative(value)
    return type(value) == "number" and value == value
        and value >= 0 and value < math.huge
end

function SkillDamage.Begin(owner, skill)
    owner._nyx_skill_damage_bonus = owner._nyx_skill_damage_bonus or {}
    owner._nyx_skill_damage_bonus[skill] = true
end

local function WeaponDamage(owner, target)
    local inventory = owner.components ~= nil and owner.components.inventory or nil
    local weapon = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local component = weapon ~= nil and weapon.components ~= nil and weapon.components.weapon or nil
    if component ~= nil and component.GetDamage ~= nil then
        local ok, result = pcall(component.GetDamage, component, owner, target)
        if ok and IsFiniteNonnegative(result) then return result end
    end
    return component ~= nil and IsFiniteNonnegative(component.damage) and component.damage or 0
end

function SkillDamage.End(owner, skill)
    if owner ~= nil and owner._nyx_skill_damage_bonus ~= nil then
        owner._nyx_skill_damage_bonus[skill] = nil
        if next(owner._nyx_skill_damage_bonus) == nil then
            owner._nyx_skill_damage_bonus = nil
        end
    end
end

local function LevelMultiplier(owner, skill)
    local rate = LEVEL_RATES[skill]
    local level = owner ~= nil and owner.components ~= nil
        and owner.components.levelsystem ~= nil and owner.components.levelsystem.level or nil
    if rate == nil or not IsFiniteNonnegative(level) then return 1 end
    local steps = level >= 100 and 10 or math.min(8, math.floor(level / 10))
    return 1 + rate * steps
end

local function SkillBase(owner, skill, damage, target)
    local active = owner ~= nil and owner._nyx_skill_damage_bonus or nil
    return damage * LevelMultiplier(owner, skill)
        + (active ~= nil and active[skill] and WeaponDamage(owner, target) or 0)
end

function SkillDamage.Calculate(owner, skill, damage, target, ...)
    -- Native Tu Tien applies potion, Achievement and target modifiers once,
    -- including to the weapon contribution. Never add damage after that call:
    -- doing so bypasses both attack buffs and native alwaysblock/PvP handling.
    return Xd_CalcDamage(owner, SkillBase(owner, skill, damage, target), target, ...)
end

function SkillDamage.MarkNative(effect, owner, skill)
    effect._nyx_damage_owner = owner
    effect._nyx_damage_skill = skill
end

local installed_hook
function SkillDamage.InstallNativeHook(global)
    local original = global.Xd_CalcDamage
    if type(original) ~= 'function' or original == installed_hook then return end
    installed_hook = function(owner, damage, target, ...)
        if owner ~= nil and owner.prefab == 'nyx'
            and owner._nyx_skill_damage_bonus ~= nil and type(damage) == 'number'
            and debug ~= nil and debug.getlocal ~= nil then
            -- Tu Tien 18.1 domain/river/flame callbacks expose their effect as
            -- local `inst`. Flame hitboxes have the marked emitter as owner.
            -- Use instance identity, not filenames: the flame code is shared
            -- by other attacks and all three skills may run simultaneously.
            local index = 1
            while true do
                local name, effect = debug.getlocal(2, index)
                if name == nil then break end
                if name == 'inst' and type(effect) == 'table' then
                    local marked = effect._nyx_damage_skill ~= nil and effect or effect.owner
                    if type(marked) == 'table' and marked._nyx_damage_owner == owner then
                        local skill = marked._nyx_damage_skill
                        if LEVEL_RATES[skill] ~= nil and owner._nyx_skill_damage_bonus[skill] then
                            damage = SkillBase(owner, skill, damage, target)
                        end
                    end
                    break
                end
                index = index + 1
            end
        end
        return original(owner, damage, target, ...)
    end
    global.Xd_CalcDamage = installed_hook
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
