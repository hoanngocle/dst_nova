-- Solo Leveling's weapon strengthen milestones, adapted to the local upgrade component.
local M = {}

local EXPLODE = {.02, .03, .04, .05, .10, .20, .30, .40, .50}
local SHADOW_CHANCE = {3, 5, 8, 12, 15, 18, 23, 30, 40}
local SHADOW_MULT = {2, 2, 3, 4, 5, 6, 7, 8, 9}
local CANT_HIT = {
    "INLIMBO", "NOCLICK", "notarget", "player", "noattack", "playerghost",
    "wall", "structure", "balloon", "companion", "glommer", "abigail", "shadowminion",
}

local function Tier(level)
    return math.min(9, math.max(1, math.floor(math.min(level, 13) * 9 / 12)))
end

local function Valid(entity)
    return entity ~= nil and (entity.IsValid == nil or entity:IsValid())
end

local function Position(entity)
    return entity.Transform:GetWorldPosition()
end

local function Fx(prefab, target)
    if SpawnPrefab == nil or not Valid(target) or target.Transform == nil then return end
    local fx = SpawnPrefab(prefab)
    if fx ~= nil and fx.Transform ~= nil then fx.Transform:SetPosition(Position(target)) end
end

local function Hit(attacker, target, amount)
    if not Valid(attacker) or not Valid(target) or amount <= 0 then return end
    local combat = target.components ~= nil and target.components.combat or nil
    local health = target.components ~= nil and target.components.health or nil
    if combat ~= nil and (health == nil or not health:IsDead()) then
        combat:GetAttacked(attacker, amount, nil, "tbc_strengthen_auxiliary")
    end
end

function M.TrueDamage(level)
    return type(level) == "number" and level >= 16 and 500 or 0
end

-- Values before target-specific damage reduction; damage is the current
-- weapon hit used for the item/player preview.
function M.Preview(level, damage)
    level = type(level) == "number" and level or 0
    local tier = Tier(level)
    local estimate = type(damage) == "number" and damage == damage
        and damage > 0 and damage < math.huge and damage or nil
    local result = {}
    if level >= 3 then
        result.splash_percent = EXPLODE[tier] * 100
        result.splash_damage = estimate ~= nil and estimate * EXPLODE[tier] or nil
    end
    if level >= 5 then result.bonus_damage = tier * 10 end
    if level >= 11 then result.stun_chance = SHADOW_CHANCE[tier] end
    if level >= 13 then
        result.shadow_chance = SHADOW_CHANCE[tier]
        result.shadow_multiplier = SHADOW_MULT[tier]
        result.shadow_damage = estimate ~= nil and estimate * SHADOW_MULT[tier] or nil
    end
    if level >= 16 then
        result.true_damage = M.TrueDamage(level)
        result.crit_effect = 50
    end
    return result
end

function M.OnHit(upgrade, attacker, target, damage, rng)
    if upgrade == nil or not upgrade:IsWeaponMilestone() or not Valid(target)
        or type(damage) ~= "number" or damage <= 0 then return end
    local level = upgrade.level or 0
    if level < 3 then return end
    rng = rng or math.random
    local tier = Tier(level)

    -- Bộc Liệt: splash around the struck target, retaining Solo's level curve.
    if TheSim ~= nil and target.Transform ~= nil then
        local x, y, z = Position(target)
        local nearby = TheSim:FindEntities(x, y, z, 4, {"_combat"}, CANT_HIT)
        local splashed = false
        for _, other in ipairs(nearby or {}) do
            if other ~= target and Valid(other) and other.components ~= nil
                and other.components.combat ~= nil
                and (attacker.components == nil or attacker.components.combat == nil
                    or attacker.components.combat.IsValidTarget == nil
                    or attacker.components.combat:IsValidTarget(other)) then
                Hit(attacker, other, damage * EXPLODE[tier])
                splashed = true
            end
        end
        if splashed then Fx("explode_small", target) end
    end

    if level >= 5 then Hit(attacker, target, tier * 10) end -- Bạo Vũ

    if level >= 11 and rng(0, 100) <= SHADOW_CHANCE[tier] then -- Địa Chấn
        Fx("groundpound_fx", target)
        Fx("groundpoundring_fx", target)
        if target.brain ~= nil then target.brain:Stop() end
        if target.components ~= nil and target.components.locomotor ~= nil then
            target.components.locomotor:Stop()
        end
        if target.Physics ~= nil then target.Physics:Stop() end
        if target._tbc_strengthen_stun_task ~= nil then
            target._tbc_strengthen_stun_task:Cancel()
        end
        if target.DoTaskInTime ~= nil then
            target._tbc_strengthen_stun_task = target:DoTaskInTime(2, function(victim)
                victim._tbc_strengthen_stun_task = nil
                if victim.brain ~= nil then victim.brain:Start() end
            end)
        end
    end

    if level >= 13 and rng(0, 100) <= SHADOW_CHANCE[tier]
        and target.DoTaskInTime ~= nil then -- Ảnh Tập
        local count = rng(4, 6)
        local each = damage * SHADOW_MULT[tier] / count
        for index = 1, count do
            target:DoTaskInTime(index * .07, function(victim)
                if Valid(victim) and SpawnPrefab ~= nil then
                    local shadow = SpawnPrefab("tbc_strengthen_shadow")
                    if shadow ~= nil and shadow.Init ~= nil then
                        shadow:Init(attacker, victim, each,
                            index * 2 * math.pi / count)
                    end
                end
            end)
        end
    end
end

local function RemoveLightning(item)
    local owner = item._tbc_strengthen_lightning_owner
    if owner ~= nil and Valid(owner) then
        if item._tbc_strengthen_added_rod then owner:RemoveTag("lightningrod") end
        if item._tbc_strengthen_added_immune then owner:RemoveTag("electricdamageimmune") end
        owner.lightningpriority = item._tbc_strengthen_old_priority
    end
    item._tbc_strengthen_lightning_owner = nil
    item._tbc_strengthen_added_rod = nil
    item._tbc_strengthen_added_immune = nil
end

local function EquipLightning(item, owner)
    if item._tbc_strengthen_lightning_owner == owner then return end
    RemoveLightning(item)
    if not Valid(owner) then return end
    item._tbc_strengthen_lightning_owner = owner
    item._tbc_strengthen_added_rod = not owner:HasTag("lightningrod")
    item._tbc_strengthen_added_immune = not owner:HasTag("electricdamageimmune")
    item._tbc_strengthen_old_priority = owner.lightningpriority
    owner:AddTag("lightningrod")
    owner:AddTag("electricdamageimmune")
    owner.lightningpriority = 0
end

local function Refill(item)
    if item._tbc_strengthen_refilling then return end
    item._tbc_strengthen_refilling = true
    for _, key in ipairs({"finiteuses", "fueled", "perishable"}) do
        local part = item.components ~= nil and item.components[key] or nil
        if part ~= nil and part.GetPercent ~= nil and part.SetPercent ~= nil
            and part:GetPercent() < 1 then part:SetPercent(1) end
    end
    item._tbc_strengthen_refilling = nil
end

function M.Sync(item, level)
    if item == nil or item.components == nil or item.components.weapon == nil then return end
    local equippable = item.components.equippable
    local slot = equippable ~= nil and equippable.equipslot or nil
    if EQUIPSLOTS ~= nil and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
        return
    end
    if level >= 9 and not item._tbc_strengthen_events_installed and item.ListenForEvent ~= nil then
        item._tbc_strengthen_events_installed = true
        item:ListenForEvent("equipped", function(inst, data)
            if inst.components.tbc_upgrade ~= nil
                and inst.components.tbc_upgrade.level >= 9 then
                EquipLightning(inst, data ~= nil and data.owner or nil)
            end
        end)
        item:ListenForEvent("unequipped", function(inst) RemoveLightning(inst) end)
        item:ListenForEvent("percentusedchange", function(inst)
            if inst.components.tbc_upgrade ~= nil
                and inst.components.tbc_upgrade.level >= 13 then Refill(inst) end
        end)
        item:ListenForEvent("perishchange", function(inst)
            if inst.components.tbc_upgrade ~= nil
                and inst.components.tbc_upgrade.level >= 13 then Refill(inst) end
        end)
    end
    local equippable = item.components.equippable
    if level >= 9 and equippable ~= nil and equippable.IsEquipped ~= nil
        and equippable:IsEquipped() then
        local inventoryitem = item.components.inventoryitem
        EquipLightning(item, inventoryitem ~= nil and inventoryitem.GetGrandOwner ~= nil
            and inventoryitem:GetGrandOwner() or nil)
    else
        RemoveLightning(item)
    end
    local weapon = item.components.weapon
    if level >= 13 then
        if item._tbc_strengthen_old_attackwear == nil then
            item._tbc_strengthen_old_attackwear = weapon.attackwear or 1
        end
        weapon.attackwear = 0
        Refill(item)
    elseif item._tbc_strengthen_old_attackwear ~= nil then
        weapon.attackwear = item._tbc_strengthen_old_attackwear
        item._tbc_strengthen_old_attackwear = nil
    end
end

return M
