local M = {}
local AURA = {.05, .1, .15, .25, .4, .55, .7, .85, 1}
local PUSHBACK = {.03, .05, .08, .12, .20, .30, .40, .50, .60}
local REFLECT = {.05, .10, .15, .20, .30, .40, .60, .80, 1}
local ABSORB = {.03, .05, .08, .12, .15, .18, .23, .30, .40}
local CANT_HIT = {"INLIMBO", "NOCLICK", "notarget", "player", "noattack",
    "playerghost", "wall", "structure", "balloon", "companion", "glommer",
    "friendlyfruitfly", "abigail", "shadowminion"}

local function Tier(level)
    return math.min(9, math.floor(math.min(level, 13) * 9 / 12))
end

local function Level(item)
    local upgrade = item ~= nil and item.components ~= nil and item.components.tbc_upgrade or nil
    return upgrade ~= nil and upgrade.level or 0
end

local function Targets(owner)
    if TheSim == nil or owner.Transform == nil then return {} end
    local x, y, z = owner.Transform:GetWorldPosition()
    return TheSim:FindEntities(x, y, z, 5, {"_combat"}, CANT_HIT) or {}
end

local function ValidTarget(owner, target)
    return target ~= nil and target ~= owner
        and (target.IsValid == nil or target:IsValid())
        and target.components ~= nil and target.components.combat ~= nil
        and target.components.health ~= nil and not target.components.health:IsDead()
end

local function Repel(owner, target)
    if target.HasTag ~= nil and target:HasTag("player") then
        if target.PushEvent ~= nil then
            target:PushEvent("repelled", {repeller = owner, radius = 300})
        end
        return
    end
    if target.Physics == nil or target.ForceFacePoint == nil or owner.Transform == nil then return end
    local x, y, z = owner.Transform:GetWorldPosition()
    target:ForceFacePoint(x, y, z)
    target.Physics:SetMotorVelOverride(-12, 0, 0)
    if target.DoTaskInTime ~= nil then
        target:DoTaskInTime(10 * (FRAMES or 1 / 30), function(victim)
            if victim.Physics ~= nil then victim.Physics:ClearMotorVelOverride() end
        end)
    end
end

local function ArmorDamaged(item, owner, level, slot, amount)
    if type(amount) ~= "number" or amount <= 0 or owner == nil
        or owner.IsValid ~= nil and not owner:IsValid() then return end
    local inventory = owner.components ~= nil and owner.components.inventory or nil
    if inventory == nil or inventory.GetEquippedItem == nil
        or inventory:GetEquippedItem(slot) ~= item then return end
    local tier = Tier(level)
    local targets = slot == EQUIPSLOTS.BODY and level >= 5 and Targets(owner) or nil
    if targets ~= nil and math.random() <= PUSHBACK[tier] then
        for _, target in ipairs(targets) do
            if ValidTarget(owner, target) then Repel(owner, target) end
        end
    end
    if targets ~= nil and level >= 7 then
        for _, target in ipairs(targets) do
            if ValidTarget(owner, target) then
                target.components.combat:GetAttacked(owner, amount * REFLECT[tier], nil,
                    "tbc_strengthen_reflect")
            end
        end
    end
    if level >= 13 and math.random() <= ABSORB[tier] then
        local health = owner.components.health
        if health ~= nil and health.DoDelta ~= nil
            and (health.IsDead == nil or not health:IsDead())
            and (owner.HasTag == nil or not owner:HasTag("playerghost")) then
            health:DoDelta(amount, false, "tbc_strengthen_absorb")
        end
    end
end

local function KeepDurability(item, player, slot)
    local updating = false
    return function()
        local inventory = player.components ~= nil and player.components.inventory or nil
        if updating or Level(item) < 13 or inventory == nil
            or inventory.GetEquippedItem == nil
            or inventory:GetEquippedItem(slot) ~= item then return end
        updating = true
        for _, name in ipairs({"finiteuses", "fueled", "perishable"}) do
            local component = item.components ~= nil and item.components[name] or nil
            if component ~= nil and component.GetPercent ~= nil
                and component.SetPercent ~= nil and component:GetPercent() < 1 then
                component:SetPercent(1)
            end
        end
        updating = false
    end
end

local function StopDurability(item, callback)
    if callback ~= nil and item.RemoveEventCallback ~= nil then
        item:RemoveEventCallback("percentusedchange", callback)
        item:RemoveEventCallback("perishchange", callback)
    end
end

local function StartDurability(item, player, slot)
    if item.ListenForEvent == nil then return nil end
    local callback = KeepDurability(item, player, slot)
    item:ListenForEvent("percentusedchange", callback)
    item:ListenForEvent("perishchange", callback)
    return callback
end

local function HeadOff(player, state)
    if state.head == nil then return end
    local hunger = player.components.hunger
    if state.hunger and hunger ~= nil and hunger.burnratemodifiers ~= nil then
        hunger.burnratemodifiers:RemoveModifier(state.head, "tbc_strengthen_head")
    end
    if state.anti_storm and player.RemoveTag ~= nil then player:RemoveTag("anti_storm") end
    local sanity = player.components.sanity
    if state.aura ~= nil and sanity ~= nil and sanity.neg_aura_absorb == state.aura then
        sanity.neg_aura_absorb = state.old_aura
    end
    if state.light ~= nil and (state.light.IsValid == nil or state.light:IsValid()) then
        state.light:Remove()
    end
    if state.beefalo and player.RemoveTag ~= nil then player:RemoveTag("beefalo") end
    if state.monster and player.AddTag ~= nil then player:AddTag("monster") end
    if state.protect ~= nil and player.RemoveEventCallback ~= nil then
        player:RemoveEventCallback("healthdelta", state.protect)
    end
    if state.head_hit ~= nil and state.head.RemoveEventCallback ~= nil then
        state.head:RemoveEventCallback("armordamaged", state.head_hit)
    end
    StopDurability(state.head, state.head_durability)
    state.head = nil
    state.head_level = nil
    state.hunger, state.anti_storm, state.aura = nil, nil, nil
    state.light, state.beefalo, state.monster, state.protect, state.head_hit = nil, nil, nil, nil, nil
    state.head_durability = nil
end

local function HeadOn(player, state, item, level)
    state.head = item
    state.head_level = level
    local hunger = player.components.hunger
    if level >= 3 and hunger ~= nil and hunger.burnratemodifiers ~= nil then
        local tier = math.min(10, math.floor(math.min(level, 13) * 10 / 13))
        hunger.burnratemodifiers:SetModifier(item, 1 - tier * .1, "tbc_strengthen_head")
        state.hunger = true
    end
    if level >= 3 and player.AddTag ~= nil and player.HasTag ~= nil
        and not player:HasTag("anti_storm") then
        player:AddTag("anti_storm")
        state.anti_storm = true
    end
    if level >= 5 then
        local sanity = player.components.sanity
        if sanity ~= nil then
            state.old_aura = sanity.neg_aura_absorb or 0
            state.aura = (TUNING ~= nil and TUNING.ARMOR_HIVEHAT_SANITY_ABSORPTION or 1)
                * AURA[Tier(level)]
            sanity.neg_aura_absorb = state.aura
        end
    end
    if level >= 9 then
        if SpawnPrefab ~= nil then
            state.light = SpawnPrefab("tbc_strengthen_light")
            if state.light ~= nil and state.light.entity ~= nil then
                state.light.entity:SetParent(player.entity)
            end
        end
        if player.HasTag ~= nil and player.AddTag ~= nil then
            if not player:HasTag("beefalo") then
                player:AddTag("beefalo")
                state.beefalo = true
            end
            if player:HasTag("monster") then
                player:RemoveTag("monster")
                state.monster = true
            end
        end
    end
    if level >= 11 and player.ListenForEvent ~= nil then
        state.protect = function(owner)
            local health = owner.components ~= nil and owner.components.health or nil
            if health == nil or health.GetPercent == nil or health.SetPercent == nil
                or health.IsDead ~= nil and health:IsDead()
                or owner.HasTag ~= nil and owner:HasTag("playerghost")
                or health:GetPercent() >= .3 then return end
            local now = GetTime ~= nil and GetTime() or 0
            if now < (owner._tbc_strengthen_protect_ready or 0) then return end
            owner._tbc_strengthen_protect_ready = now + 600 - 50 * Tier(level)
            health:SetPercent(1)
        end
        player:ListenForEvent("healthdelta", state.protect)
    end
    if level >= 13 and item.ListenForEvent ~= nil then
        state.head_durability = StartDurability(item, player, EQUIPSLOTS.HEAD)
        state.head_hit = function(_, amount)
            ArmorDamaged(item, player, Level(item), EQUIPSLOTS.HEAD, amount)
        end
        item:ListenForEvent("armordamaged", state.head_hit)
    end
end

local function BodyOff(player, state)
    if state.body == nil then return end
    local locomotor = player.components.locomotor
    if state.speed and locomotor ~= nil and locomotor.RemoveExternalSpeedMultiplier ~= nil then
        locomotor:RemoveExternalSpeedMultiplier(state.body, "tbc_strengthen_body")
    end
    if state.fire then
        local health = player.components.health
        if health ~= nil and health.externalfiredamagemultipliers ~= nil then
            health.externalfiredamagemultipliers:RemoveModifier(state.body)
        end
    end
    if state.acid and player.RemoveTag ~= nil then player:RemoveTag("acidrainimmune") end
    if state.heavyarmor and player.RemoveTag ~= nil then player:RemoveTag("heavyarmor") end
    if state.heavybody and player.RemoveTag ~= nil then player:RemoveTag("heavybody") end
    if state.body_hit ~= nil and state.body.RemoveEventCallback ~= nil then
        state.body:RemoveEventCallback("armordamaged", state.body_hit)
    end
    StopDurability(state.body, state.body_durability)
    state.body = nil
    state.body_level = nil
    state.speed, state.fire, state.acid = nil, nil, nil
    state.heavyarmor, state.heavybody = nil, nil
    state.body_hit = nil
    state.body_durability = nil
end

local function BodyOn(player, state, item, level)
    state.body = item
    state.body_level = level
    local locomotor = player.components.locomotor
    if level >= 3 and locomotor ~= nil and locomotor.SetExternalSpeedMultiplier ~= nil then
        local capped = math.min(level, 13)
        local speed = math.floor((1 + (1 + capped) / (34 + capped)) * 100) / 100
        locomotor:SetExternalSpeedMultiplier(item, "tbc_strengthen_body", speed)
        state.speed = true
    end
    if level >= 9 then
        local health = player.components.health
        if health ~= nil and health.externalfiredamagemultipliers ~= nil then
            local resistance = TUNING ~= nil and TUNING.ARMORDRAGONFLY_FIRE_RESIST or 0
            health.externalfiredamagemultipliers:SetModifier(item, 1 - resistance)
            state.fire = true
        end
        if player.HasTag ~= nil and player.AddTag ~= nil
            and not player:HasTag("acidrainimmune") then
            player:AddTag("acidrainimmune")
            state.acid = true
        end
    end
    if level >= 11 and player.HasTag ~= nil and player.AddTag ~= nil then
        if not player:HasTag("heavyarmor") then
            player:AddTag("heavyarmor")
            state.heavyarmor = true
        end
        if not player:HasTag("heavybody") then
            player:AddTag("heavybody")
            state.heavybody = true
        end
    end
    if level >= 5 and item.ListenForEvent ~= nil then
        state.body_hit = function(_, amount)
            ArmorDamaged(item, player, Level(item), EQUIPSLOTS.BODY, amount)
        end
        item:ListenForEvent("armordamaged", state.body_hit)
    end
    if level >= 13 then
        state.body_durability = StartDurability(item, player, EQUIPSLOTS.BODY)
    end
end

function M.Reconcile(player, items)
    if player == nil or player.components == nil then return end
    local head, body = nil, nil
    for _, item in ipairs(items or {}) do
        local equippable = item.components ~= nil and item.components.equippable or nil
        if equippable ~= nil then
            if equippable.equipslot == EQUIPSLOTS.HEAD then head = item end
            if equippable.equipslot == EQUIPSLOTS.BODY then body = item end
        end
    end
    local state = player._tbc_strengthen_armor_state
    if state == nil then state = {}; player._tbc_strengthen_armor_state = state end
    if state.head ~= head or state.head_level ~= Level(head) then
        HeadOff(player, state)
        if head ~= nil then HeadOn(player, state, head, Level(head)) end
    end
    if state.body ~= body or state.body_level ~= Level(body) then
        BodyOff(player, state)
        if body ~= nil then BodyOn(player, state, body, Level(body)) end
    end
end

return M
