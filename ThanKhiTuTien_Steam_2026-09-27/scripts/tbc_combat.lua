local Math = require("tbc_combat_math")
local AffixCombat = require("tbc_affix/combat")
local AffixStatus = require("tbc_affix/status")
local StrengthenEffects = require("tbc_strengthen_effects")
local M = {}
local unpack_values = unpack or table.unpack

local function Pack(...)
    return {n = select("#", ...), ...}
end

local function UpgradeOf(item)
    return item ~= nil and item.components ~= nil and item.components.tbc_upgrade or nil
end

local function WeaponUpgrade(attacker, weapon)
    local source = weapon ~= nil and (weapon._tbc_source_item or weapon._source_weapon or weapon)
        or attacker ~= nil and attacker._tbc_current_weapon or nil
    local upgrade = UpgradeOf(source)
    return upgrade ~= nil and upgrade.IsWeaponMilestone ~= nil
        and upgrade:IsWeaponMilestone() and upgrade or nil
end

local function OwnerEffects(owner)
    return owner ~= nil and owner.components ~= nil
        and owner.components.tbc_player_effects or nil
end

function M.StatsForOwner(attacker, weapon)
    local source = weapon ~= nil and (weapon._tbc_source_item or weapon._source_weapon)
        or attacker ~= nil and attacker._tbc_current_weapon or nil
    local upgrade = UpgradeOf(source or weapon)
    local inventory = attacker ~= nil and attacker.components ~= nil and attacker.components.inventory or nil
    if upgrade == nil and inventory ~= nil and inventory.GetEquippedItem ~= nil
        and EQUIPSLOTS ~= nil then
        for _, slot in ipairs({EQUIPSLOTS.HANDS, EQUIPSLOTS.NECK, EQUIPSLOTS.BODY}) do
            if slot ~= nil then
                upgrade = UpgradeOf(inventory:GetEquippedItem(slot))
                if upgrade ~= nil then break end
            end
        end
    end
    local bonus = upgrade ~= nil and upgrade.GetCombatStats ~= nil
        and upgrade:GetCombatStats() or nil
    local effects = attacker ~= nil and attacker.components ~= nil
        and attacker.components.tbc_player_effects or nil
    if effects ~= nil then
        bonus = bonus or {}
        bonus.crit_rate = (bonus.crit_rate or 0) + effects:Get("criticalHitRate")
        bonus.crit_effect = (bonus.crit_effect or 0) + effects:Get("criticalHitEffect")
    end
    return Math.Stats(Math.BASE, bonus)
end

local TARGET_BONUSES = {
    pig = "addHitPigDamage", fish = "addHitFishDamage",
    monkey = "addHitMonkeyDamage", gear = "addHitGearDamage",
    spider = "addHitSpiderDamage", dog = "addHitDogDamage",
    frog = "addHitFrogDamage", insect = "addHitInsectDamage",
    shadow = "addHitShadowDamage", boss_monster = "addHitBossDamage",
    endgameboss_monster = "addHitBossDamage", plant = "addHitPlantDamage",
}

function M.SoloDamage(attacker, target, damage, rng)
    local effects = OwnerEffects(attacker)
    if effects == nil or type(damage) ~= "number" or damage <= 0 then return damage end
    rng = rng or math.random
    local flat = effects:Get("addComDamage")
    local world = TheWorld
    local state = world ~= nil and world.state or nil
    if state ~= nil then
        flat = flat + (state.isday and effects:Get("sunlightStrike") or 0)
            + (state.isdusk and effects:Get("afterglowStrike") or 0)
            + (state.isnight and effects:Get("nightMenace") or 0)
    end
    if target ~= nil then
        for tag, key in pairs(TARGET_BONUSES) do
            if target.HasHHTag ~= nil and target:HasHHTag(tag)
                or target.HasTag ~= nil and target:HasTag(tag) then
                flat = flat + effects:Get(key)
            end
        end
        local health = target.components ~= nil and target.components.health or nil
        if health ~= nil and type(health.currenthealth) == "number" then
            damage = damage + math.max(0, health.currenthealth)
                * math.min(3, math.max(0, effects:Get("targetPercentDamage"))) / 100
        end
    end
    local moisture = attacker.components.moisture
    if moisture ~= nil and moisture.GetMoisturePercent ~= nil
        and moisture:GetMoisturePercent() >= 50 then
        flat = flat + effects:Get("soakStrike")
    end
    local percent = effects:Get("addComDamagePercent")
    for _, condition in ipairs({
        {"bloodOutburst", attacker.components.health},
        {"hungerAssault", attacker.components.hunger},
        {"spiritFade", attacker.components.sanity},
    }) do
        local component = condition[2]
        if effects:Has(condition[1]) and component ~= nil
            and component.GetPercent ~= nil then
            percent = percent + (1 - component:GetPercent()) * 50
        end
    end
    damage = (damage + flat) * (1 + percent / 100)
    for _, proc in ipairs({
        {"moreDamage30To150", .30}, {"moreDamage20To200", .20},
        {"moreDamage10To300", .10}, {"moreDamage8To500", .08},
    }) do
        if effects:Has(proc[1]) and rng() <= proc[2] then
            damage = damage * math.max(1, effects:Get(proc[1]) / 100)
        end
    end
    return damage
end

function M.SoloArmorPierce(attacker)
    local effects = OwnerEffects(attacker)
    return effects ~= nil and math.max(0, effects:Get("trueDamageNum")) or 0
end

-- Read-only, target-independent preview. Never roll procs or invoke GetAttacked.
function M.PreviewAttack(attacker, weapon, damage)
    local preview = M.SoloDamage(attacker, nil, damage, function() return 1 end)
    preview = AffixCombat.AdjustDamage(attacker, weapon, preview)
    local packet = AffixCombat.AugmentHit(attacker, nil, weapon, preview)
    local stats = M.StatsForOwner(attacker, weapon)
    return {damage = preview, pierce_percent = stats.pierce,
        affix_pierce = packet.tbc_armor_pierce or 0}
end

function M.SoloOnHit(attacker, damage)
    local effects = OwnerEffects(attacker)
    if effects == nil or type(damage) ~= "number" or damage <= 0 then return end
    local health = attacker.components.health
    local sanity = attacker.components.sanity
    local life = math.max(0, effects:Get("bloodSuck"))
    local spirit = math.max(0, effects:Get("restoreSpirit"))
    if life > 0 and health ~= nil and health.DoDelta ~= nil then
        health:DoDelta(damage * life / 100, false, "bloodSuck")
    end
    if spirit > 0 and sanity ~= nil and sanity.DoDelta ~= nil then
        sanity:DoDelta(damage * spirit / 100)
    end
end

function M.SoloDefense(victim, damage)
    local effects = OwnerEffects(victim)
    if effects == nil or type(damage) ~= "number" or damage <= 0 then return damage end
    damage = math.max(0, damage - math.max(0, effects:Get("reduceAttackedDamage")))
    local absorb = math.min(80, math.max(0, effects:Get("absorbDamage")))
    return damage * (1 - absorb / 100)
end

-- Defined as a special damage type so armor is skipped while DST's damage
-- resistance and the other mods' existing special damage remain in the packet.
function M.RegisterSpDamage()
    local util = require("components/spdamageutil")
    local function TakenMult(victim)
        local combat = victim.components ~= nil and victim.components.combat or nil
        local mult = combat ~= nil and combat.externaldamagetakenmultipliers ~= nil
            and combat.externaldamagetakenmultipliers:Get() or 1
        local hit = victim._tbc_damage_context
        if hit ~= nil and combat ~= nil
            and combat.conditionexternaldamagetakenmultipliers ~= nil
            and combat.ApplyConditionExternalDamageTakenMultiplier ~= nil then
            mult = mult * combat:ApplyConditionExternalDamageTakenMultiplier(
                1, hit.attacker, hit.weapon)
        end
        return mult
    end
    for _, kind in ipairs({"tbc_armor_pierce", "tbc_affix_poison"}) do
        if util._SpTypeMap[kind] == nil then
            util.DefineSpType(kind, {
                GetDamage = function() return 0 end,
                GetDefense = function() return 0 end,
                GetTakenMult = TakenMult,
            })
        end
    end
end

function M.Install(combat, achievement_enabled, rng)
    if combat._tbc_damage_wrapper ~= nil then return end
    local original = combat.GetAttacked
    local wrapper = function(self, attacker, damage, weapon, stimuli, spdamage, ...)
        if self.inst ~= nil and self.inst.HasTag ~= nil and self.inst:HasTag('player') then
            damage = M.SoloDefense(self.inst, damage)
        end
        if attacker == nil or attacker.HasTag == nil or not attacker:HasTag("player")
            or type(damage) ~= "number" or damage <= 0
            or stimuli == "ttk_lucnguyen_auxiliary"
            or stimuli == "tbc_affix_burn"
            or stimuli == "tbc_affix_poison"
            or stimuli == "tbc_strengthen_reflect"
            or stimuli == "tbc_strengthen_auxiliary" then
            return original(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end
        if self.inst ~= nil and self.inst.HasTag ~= nil and self.inst:HasTag("player") then
            return original(self, attacker, damage,
                weapon, stimuli, spdamage, ...)
        end
        damage = M.SoloDamage(attacker, self.inst, damage, rng)
        damage = AffixCombat.AdjustDamage(attacker, weapon, damage)
        local status_base_damage = damage
        local stats = M.StatsForOwner(attacker, weapon)
        local strengthen = WeaponUpgrade(attacker, weapon)
        local pierce = Math.PierceDamage(damage, stats) + M.SoloArmorPierce(attacker)
            + (strengthen ~= nil and StrengthenEffects.TrueDamage(strengthen.level) or 0)
        if pierce > 0 then
            local copy = {}
            if type(spdamage) == "table" then
                for kind, amount in pairs(spdamage) do copy[kind] = amount end
            end
            copy.tbc_armor_pierce = (copy.tbc_armor_pierce or 0) + pierce
            spdamage = copy
        end
        local augmented = AffixCombat.AugmentHit(attacker, self.inst, weapon, damage, spdamage)
        if next(augmented) ~= nil then spdamage = augmented end
        local critical = false
        if not achievement_enabled then
            damage, critical = Math.RollCrit(damage, stats, rng)
        end
        local victim = self.inst
        local previous = victim ~= nil and victim._tbc_damage_context or nil
        local previous_source = attacker._tbc_current_weapon
        attacker._tbc_current_weapon = weapon ~= nil
            and (weapon._tbc_source_item or weapon._source_weapon) or nil
        if victim ~= nil then
            victim._tbc_damage_context = {attacker = attacker, weapon = weapon}
        end
        local results = Pack(pcall(original, self, attacker, damage, weapon, stimuli, spdamage, ...))
        if victim ~= nil then victim._tbc_damage_context = previous end
        attacker._tbc_current_weapon = previous_source
        if not results[1] then error(results[2], 0) end
        local landed = results[2]
        if landed ~= false then
            M.SoloOnHit(attacker, damage)
            AffixStatus.OnLandedHit(attacker, self.inst, weapon, damage, rng)
            StrengthenEffects.OnHit(strengthen, attacker, self.inst, status_base_damage, rng)
        end
        if critical and landed ~= false and attacker.PushEvent ~= nil then
            attacker:PushEvent("tbc_docriticalhit", {target = self.inst, weapon = weapon})
        end
        return unpack_values(results, 2, results.n)
    end
    combat._tbc_damage_wrapper = wrapper
    combat.GetAttacked = wrapper
end

return M
