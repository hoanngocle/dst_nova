local RewardRuntime = {}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function HasMethod(component, name)
    return type(component) == "table" and type(component[name]) == "function"
end

function RewardRuntime.Prepare(inst, bundle)
    if type(inst) ~= "table" or type(inst.components) ~= "table" or type(bundle) ~= "table" then
        return nil, "invalid reward target"
    end
    local components = inst.components
    local stats = bundle.stats or {}
    if stats.health and not HasMethod(components.health, "DoDelta") then return nil, "health component unavailable" end
    if stats.sanity and not HasMethod(components.sanity, "DoDelta") then return nil, "sanity component unavailable" end
    if stats.hunger and not HasMethod(components.hunger, "DoDelta") then return nil, "hunger component unavailable" end
    if bundle.xp and not HasMethod(components.levelsystem, "xpDoDelta") then return nil, "level component unavailable" end
    if bundle.star and not HasMethod(components.allachivcoin, "coinDoDelta") then return nil, "Star component unavailable" end

    local items = bundle.items or {}
    if #items > 0 and type(rawget(_G, "SpawnPrefab")) ~= "function" then return nil, "item spawner unavailable" end
    for _, spec in ipairs(items) do
        if type(spec) ~= "table" or type(spec.prefab) ~= "string"
            or type(spec.amount) ~= "number" or spec.amount < 1 or spec.amount ~= math.floor(spec.amount) then
            return nil, "invalid reward item"
        end
        local prefabs = rawget(_G, "Prefabs")
        if type(prefabs) == "table" and prefabs[spec.prefab] == nil then
            return nil, "missing reward prefab: " .. spec.prefab
        end
    end
    if #items > 0 and (type(inst.Transform) ~= "table" or type(inst.Transform.GetWorldPosition) ~= "function") then
        return nil, "player position unavailable"
    end
    return {valid=true, granted=false, bundle=Copy(bundle)}
end

local function RemoveSpawned(items)
    for _, item in ipairs(items) do
        if item and type(item.Remove) == "function" then item:Remove() end
    end
end

local function SpawnItems(specs)
    local spawned = {}
    for _, spec in ipairs(specs or {}) do
        local remaining = spec.amount
        while remaining > 0 do
            local item = SpawnPrefab(spec.prefab)
            if item == nil then
                RemoveSpawned(spawned)
                return nil, "failed to spawn reward prefab: " .. spec.prefab
            end
            local stackable = item.components and item.components.stackable or nil
            local maximum = 1
            if stackable then
                if type(stackable.GetMaxSize) == "function" then maximum = stackable:GetMaxSize()
                elseif type(stackable.maxsize) == "number" then maximum = stackable.maxsize end
            end
            maximum = math.max(1, math.floor(tonumber(maximum) or 1))
            local amount = math.min(remaining, maximum)
            if stackable and type(stackable.SetStackSize) == "function" then stackable:SetStackSize(amount) end
            spawned[#spawned + 1] = item
            remaining = remaining - amount
        end
    end
    return spawned
end

local function DeliverItem(inst, item)
    local inventory = inst.components.inventory
    if inventory and type(inventory.GiveItem) == "function" then
        local ok, leftover = pcall(inventory.GiveItem, inventory, item)
        if ok and leftover == nil then return true end
        if ok and type(leftover) == "table" then item = leftover end
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    if item.Transform and type(item.Transform.SetPosition) == "function" then
        item.Transform:SetPosition(x, y, z)
        return true
    end
    return false
end

function RewardRuntime.Grant(inst, prepared)
    if type(prepared) ~= "table" or prepared.valid ~= true or prepared.granted then return false, "invalid prepared reward" end
    local bundle = prepared.bundle
    local items, err = SpawnItems(bundle.items)
    if items == nil then return false, err end

    local stats = bundle.stats or {}
    if stats.health then inst.components.health:DoDelta(stats.health) end
    if stats.sanity then inst.components.sanity:DoDelta(stats.sanity) end
    if stats.hunger then inst.components.hunger:DoDelta(stats.hunger) end
    if bundle.xp then inst.components.levelsystem:xpDoDelta(bundle.xp, inst, true) end
    if bundle.star then inst.components.allachivcoin:coinDoDelta(bundle.star) end

    for _, item in ipairs(items) do
        if not DeliverItem(inst, item) then return false, "failed to deliver reward item" end
    end
    prepared.granted = true
    return true
end

return RewardRuntime
