local definitions = require "constants/novaachievements"

local by_tracker = {}
for _, achievement in ipairs(definitions) do
    local group = by_tracker[achievement.tracker] or {}
    group[#group + 1] = achievement
    by_tracker[achievement.tracker] = group
end

local function contains(values, value)
    if values == nil then return false end
    for _, candidate in ipairs(values) do
        if candidate == value then return true end
    end
    return false
end

local function matches(achievement, prefab)
    local params = achievement.params
    return prefab ~= nil and (params.prefab == prefab or contains(params.prefabs, prefab))
end

local function record(inst, component, tracker, prefab, amount, predicate)
    for _, achievement in ipairs(by_tracker[tracker] or {}) do
        if not component[achievement.id]
            and (prefab == nil or matches(achievement, prefab))
            and (predicate == nil or predicate(achievement)) then
            component:CountAchievement(inst, achievement.id, false, amount)
        end
    end
end

local function set_progress(inst, component, achievement, amount)
    if component[achievement.id] or amount == nil then return end
    component[achievement.id .. "amount"] = math.min(amount, achievement.current)
    if amount >= achievement.current then
        component:CheckAchievement(inst, achievement.id)
    end
end

local function alive(inst)
    return inst.components.health ~= nil and not inst.components.health:IsDead()
        and not inst:HasTag("playerghost")
end

local function attach(inst, component)
    local latest_elixir_counts
    local function update_elixirs(_, data)
        if data and type(data.counts) == "table" then latest_elixir_counts = data.counts end
        local progress = inst.components.tbc_elixir_progress
        for _, achievement in ipairs(by_tracker.tbc_elixir_progress or {}) do
            local amount = progress and progress:GetCount(achievement.params.key)
                or latest_elixir_counts and latest_elixir_counts[achievement.params.key]
            if component[achievement.id] then
                component[achievement.id .. "amount"] = achievement.current
            elseif type(amount) == "number" and amount == amount then
                amount = math.max(0, math.min(achievement.current, math.floor(amount)))
                component[achievement.id .. "amount"] = amount
                if amount >= achievement.current then
                    if component.isready then
                        component:CheckAchievement(inst, achievement.id)
                    else
                        -- Re-read the current authority after save/reroll data has loaded.
                        inst:DoTaskInTime(3.01, update_elixirs)
                    end
                end
            end
        end
    end
    inst:ListenForEvent("tbc_elixir_progress", update_elixirs)
    inst:DoTaskInTime(0, update_elixirs)
    -- The original achievement component imports reroll data three seconds after Init.
    inst:DoTaskInTime(3.2, update_elixirs)

    inst:ListenForEvent("oneat", function(_, data)
        if data and data.food then record(inst, component, "eat_prefabs", data.food.prefab) end
    end)

    inst:ListenForEvent("killed", function(_, data)
        if data and data.victim then
            local prefab = data.victim.prefab
            record(inst, component, "kill_prefab", prefab)
            record(inst, component, "combat_event", prefab)
        end
    end)

    inst:ListenForEvent("gotnewitem", function(_, data)
        local item = data and data.item
        if item == nil or item.prefab == nil then return end
        local prefab = item.prefab
        local stack = item.components.stackable
        local count = stack and stack:StackSize() or 1
        record(inst, component, "collect_prefab", prefab, count)
        record(inst, component, "collect_prefabs", prefab, count)
        -- The Tu Tien machine gives items shortly after a successful interaction.
        if inst.nova_slotmachine_time and GetTime() - inst.nova_slotmachine_time < 10 then
            record(inst, component, "slotmachine_reward", prefab)
            local lower = string.lower(prefab)
            local kind
            if string.find(lower, "danyao") or string.find(lower, "^xd_dy_") or string.find(lower, "pill") then
                kind = "pill"
            elseif item.components.equippable or string.find(lower, "relic") then
                kind = "rare"
            elseif lower ~= "xd_lingshi2" and not item.components.edible then
                kind = "material"
            end
            if kind then
                record(inst, component, "slotmachine_reward", nil, nil, function(achievement)
                    return achievement.params.kind == kind
                end)
            end
        end
    end)

    local function update_owned()
        local inventory = inst.components.inventory
        if inventory == nil then return end
        for _, achievement in ipairs(by_tracker.own_prefab or {}) do
            local _, count = inventory:Has(achievement.params.prefab, achievement.current)
            set_progress(inst, component, achievement, count or 0)
        end
    end
    inst:ListenForEvent("itemget", update_owned)
    inst:ListenForEvent("itemlose", update_owned)
    inst:DoPeriodicTask(5, update_owned)

    local function built(_, data)
        local prefab = data and ((data.recipe and data.recipe.product) or (data.item and data.item.prefab))
        if prefab then
            record(inst, component, "craft_prefab", prefab)
            record(inst, component, "crafting_event", prefab)
        end
    end
    inst:ListenForEvent("builditem", built)
    inst:ListenForEvent("buildstructure", built)

    inst:ListenForEvent("working", function(_, data)
        if data == nil then return end
        for _, achievement in ipairs(by_tracker.work_action or {}) do
            local target = data.target
            local action = ACTIONS[achievement.params.action]
            local workable = target and target.components.workable
            if action ~= nil and data.action == action and
                workable and workable.workleft <= 0 and
                (not achievement.params.stump or target:HasTag("stump")) and
                (achievement.params.action ~= "HAMMER" or target:HasTag("structure")) then
                record(inst, component, "work_action", nil, nil, function(other)
                    return other == achievement
                end)
            end
        end
    end)

    local last_harvest_guid, last_harvest_time
    local function harvest(object)
        if object == nil or not (object:HasTag("farm_plant") or string.find(object.prefab or "", "^farm_plant_")) then return end
        local now = GetTime()
        if last_harvest_guid ~= object.GUID or last_harvest_time == nil or now - last_harvest_time > 0.2 then
            record(inst, component, "harvest_crop", nil)
            last_harvest_guid, last_harvest_time = object.GUID, now
        end
    end
    inst:ListenForEvent("picksomething", function(_, data)
        local object = data and data.object
        if object == nil then return end
        record(inst, component, "pick_prefab", object.prefab)
        harvest(object)
    end)
    inst:ListenForEvent("harvestsomething", function(_, data)
        harvest(data and data.object)
    end)
    inst:ListenForEvent("fishingcatch", function()
        record(inst, component, "fish_caught", nil)
    end)

    inst:ListenForEvent("nova_plant_seed", function(_, data)
        local prefab = data and data.prefab
        if prefab then record(inst, component, "plant_seed", prefab) end
    end)
    inst:ListenForEvent("nova_cookedproduct", function(_, data)
        if data and data.cooker == "cookpot" then
            record(inst, component, "cook_product", nil)
        end
    end)
    inst:ListenForEvent("nova_farm_action", function(_, data)
        local action = data and data.action
        if action then
            record(inst, component, "farm_action", nil, nil, function(achievement)
                return achievement.params.action == action
            end)
        end
    end)
    inst:ListenForEvent("nova_slotmachine_spin", function(_, data)
        local now = GetTime()
        local machine = data and data.machine
        if machine and inst.nova_last_spin_machine == machine
            and inst.nova_last_spin_time and now - inst.nova_last_spin_time < 0.2 then return end
        inst.nova_last_spin_machine, inst.nova_last_spin_time = machine, now
        inst.nova_slotmachine_time = GetTime()
        record(inst, component, "slotmachine_spin", nil)
    end)
    inst:ListenForEvent("nova_season_mission_assigned", function()
        record(inst, component, "season_mission_assigned", nil)
    end)
    inst:ListenForEvent("nova_season_mission_completed", function(_, data)
        record(inst, component, "season_mission_completed", nil)
        if data and data.repeated then
            record(inst, component, "season_mission_repeat", nil)
        end
    end)
    inst:ListenForEvent("nova_season_mission_claimed", function()
        record(inst, component, "season_mission_claimed", nil)
    end)

    inst:ListenForEvent("chasni_levelup", function()
        local level = inst.components.levelsystem and inst.components.levelsystem.level
        if level then
            for _, achievement in ipairs(by_tracker.level_reached or {}) do
                set_progress(inst, component, achievement, level)
            end
        end
    end)
    inst:DoTaskInTime(5, function()
        inst:PushEvent("chasni_levelup")
    end)

    inst:ListenForEvent("respawnfromghost", function()
        record(inst, component, "survival_event", nil, nil, function(achievement)
            return achievement.params.key == "revive"
        end)
    end)

    local previous_season = TheWorld.state.season
    inst:WatchWorldState("season", function(_, season)
        if previous_season and previous_season ~= season and alive(inst) then
            record(inst, component, "survival_event", nil, nil, function(achievement)
                return achievement.params.key == previous_season
            end)
        end
        previous_season = season
    end)
    local previous_phase = TheWorld.state.phase
    inst:WatchWorldState("phase", function(_, phase)
        if previous_phase == "night" and phase ~= "night" and alive(inst) then
            record(inst, component, "survival_event", nil, nil, function(achievement)
                return achievement.params.key == "night"
            end)
        end
        previous_phase = phase
    end)
    local previous_cycle = TheWorld.state.cycles
    inst:WatchWorldState("cycles", function(_, cycles)
        if cycles > previous_cycle and alive(inst) then
            record(inst, component, "survival_event", nil, nil, function(achievement)
                return achievement.params.key == "hundred_days" or achievement.params.key == "solo_days"
            end)
        end
        previous_cycle = cycles
    end)
    local was_hot, was_cold = false, false
    inst:DoPeriodicTask(1, function()
        if not alive(inst) or not inst.components.temperature then
            was_hot, was_cold = false, false
            return
        end
        local temperature = inst.components.temperature.current
        if was_hot and temperature < 70 then
            record(inst, component, "survival_event", nil, nil, function(achievement)
                return achievement.params.key == "heat"
            end)
        end
        if was_cold and temperature > 0 then
            record(inst, component, "survival_event", nil, nil, function(achievement)
                return achievement.params.key == "cold"
            end)
        end
        was_hot, was_cold = temperature >= 70, temperature <= 0
    end)
end

return { attach = attach }
