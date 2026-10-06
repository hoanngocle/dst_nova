local SkillDamage = {}

local LEVEL_RATES = {
    absolute_domain = 0.3,
    triflame_fan = 0.25,
    yellow_river = 0.3,
    eternal_night = 0.25,
    spirit_sword = 0.15,
}
local DAMAGE_SCALES={triflame_fan=2,eternal_night=2,spirit_sword=3}

local function OwnerLevel(owner)
    local component=owner and owner.components and owner.components.levelsystem
    local level=component and component.level
    return type(level)=='number' and level==level and level<math.huge
        and level>-math.huge and math.max(1,math.floor(level)) or 1
end

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
    -- Luc Mach's command carrier suppresses the basic hit with GetDamage=0.
    -- Its numeric damage still includes weapon strengthening and gem changes.
    if component ~= nil and weapon._ttk_attack_command ~= nil
        and IsFiniteNonnegative(component.damage) then
        return component.damage
    end
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
    if skill=='bean_soldiers' then damage=20*OwnerLevel(owner)
    elseif skill=='bean_explosion' then damage=200+100*math.floor(OwnerLevel(owner)/10) end
    return (damage * LevelMultiplier(owner, skill) + WeaponDamage(owner, target))
        * (DAMAGE_SCALES[skill] or 1)
end

local function Pack(...)
    return {n = select("#", ...), ...}
end

local prepared_owner
local function CallPrepared(calculator, owner, damage, target, ...)
    -- Explicit calculations and nested calculator hooks share this guard so
    -- the level rate and weapon contribution enter the native calculator once.
    local previous = prepared_owner
    prepared_owner = owner
    local result = Pack(pcall(calculator, owner, damage, target, ...))
    prepared_owner = previous
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
end

function SkillDamage.Calculate(owner, skill, damage, target, ...)
    -- Native Tu Tien applies potion, Achievement and target modifiers once,
    -- including to the weapon contribution. Never add damage after that call:
    -- doing so bypasses both attack buffs and native alwaysblock/PvP handling.
    return CallPrepared(Xd_CalcDamage, owner, SkillBase(owner, skill, damage, target), target, ...)
end

function SkillDamage.InstallSummonHook(api)
    api.AddPrefabPostInit('xd_wmz_db',function(inst)
        if not TheWorld.ismastersim or inst._nyx_summon_damage_hook
            or type(inst.CopyFromPlayer)~='function' then return end
        inst._nyx_summon_damage_hook=true
        local copy=inst.CopyFromPlayer
        inst.CopyFromPlayer=function(summon,...)
            local results=Pack(copy(summon,...))
            local combat=summon.components.combat
            if combat then
                -- Upstream CopyFromPlayer reinstalls owner-based CalcDamage.
                -- Add Nyx's weapon contribution only after that native setup.
                local native=combat.CalcDamage
                combat.CalcDamage=function(self,target,...)
                    local owner=summon.owner or (summon.components.follower
                        and summon.components.follower.leader)
                    if owner and owner.prefab=='nyx' and owner:IsValid()
                        and owner.components.combat then
                        -- Bean base grows 20 per level without a cap; the
                        -- owner calculator supplies all live bonuses once.
                        return SkillDamage.Calculate(owner,'bean_soldiers',self.defaultdamage,target)
                    end
                    return native(self,target,...)
                end
                if type(combat.DoAttack)=='function' and not combat._nyx_summon_attack_hook then
                    combat._nyx_summon_attack_hook=true
                    local attack=combat.DoAttack
                    combat.DoAttack=function(self,target,...)
                        local owner=summon.owner or (summon.components.follower
                            and summon.components.follower.leader)
                        local victim=target or self.target
                        local victimcombat=victim and victim.components and victim.components.combat
                        if not owner or owner.prefab~='nyx' or not owner:IsValid()
                            or not victimcombat then return attack(self,target,...) end
                        -- Native DoAttack still owns the soldier's range, AI,
                        -- cooldown and attack events. Attribute just this hit
                        -- to Nyx before the final target-side mod wrappers.
                        local getattacked=victimcombat.GetAttacked
                        victimcombat.GetAttacked=function(component,attacker,damage,weapon,...)
                            if attacker==summon then
                                local inventory=owner.components.inventory
                                local held=inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                                return getattacked(component,owner,damage,held,...)
                            end
                            return getattacked(component,attacker,damage,weapon,...)
                        end
                        local hit=Pack(pcall(attack,self,target,...))
                        victimcombat.GetAttacked=getattacked
                        if not hit[1] then error(hit[2],0) end
                        return unpack(hit,2,hit.n)
                    end
                end
            end
            return unpack(results,1,results.n)
        end
    end)
end

function SkillDamage.MarkNative(effect, owner, skill)
    effect._nyx_damage_owner = owner
    effect._nyx_damage_skill = skill
end

local function MarkedSkill(effect, owner)
    if type(effect) ~= 'table' then return nil end
    local marked = effect._nyx_damage_skill ~= nil and effect or effect.owner
    if type(marked) ~= 'table' or marked._nyx_damage_owner ~= owner then return nil end
    local skill = marked._nyx_damage_skill
    if (LEVEL_RATES[skill] ~= nil or skill=='bean_explosion')
        and owner._nyx_skill_damage_bonus[skill] then return skill end
end

local installed_hook
function SkillDamage.InstallNativeHook(global)
    local original = global.Xd_CalcDamage
    if type(original) ~= 'function' or original == installed_hook then return end
    installed_hook = function(owner, damage, target, ...)
        if owner ~= nil and owner ~= prepared_owner and owner.prefab == 'nyx'
            and owner._nyx_skill_damage_bonus ~= nil and type(damage) == 'number'
            and debug ~= nil and debug.getlocal ~= nil and debug.getinfo ~= nil then
            -- Tu Tien callbacks use inst as a parameter or captured upvalue.
            -- Find that callback through calculator wrappers, then stop there:
            -- outer callers may hold other active effects unrelated to this hit.
            for depth = 2, 10 do
                local info = debug.getinfo(depth, 'f')
                if info == nil then break end
                local index = 1
                while true do
                    local name, effect = debug.getlocal(depth, index)
                    if name == nil then break end
                    if name == 'inst' and type(effect) == 'table' and effect ~= owner then
                        local skill = MarkedSkill(effect, owner)
                        if skill ~= nil then
                            return CallPrepared(original, owner, SkillBase(owner, skill, damage, target), target, ...)
                        end
                        return original(owner, damage, target, ...)
                    end
                    index = index + 1
                end
                if debug.getupvalue ~= nil and type(info.func) == 'function' then
                    index = 1
                    while true do
                        local name, effect = debug.getupvalue(info.func, index)
                        if name == nil then break end
                        if name == 'inst' and type(effect) == 'table' and effect ~= owner then
                            local skill = MarkedSkill(effect, owner)
                            if skill ~= nil then
                                return CallPrepared(original, owner, SkillBase(owner, skill, damage, target), target, ...)
                            end
                            return original(owner, damage, target, ...)
                        end
                        index = index + 1
                    end
                end
            end
        end
        return original(owner, damage, target, ...)
    end
    global.Xd_CalcDamage = installed_hook
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
