-- Pure selection/transaction rules, shared by the runtime and tests.
local M = {}
function M.Eligible(groups, exists, solo)
    local result = {}
    for _, group in ipairs(groups) do
        local entry = {key=group.key,weight=group.weight,bundles={}}
        for _, bundle in ipairs(group.bundles) do
            local valid = not bundle.solo or solo
            if bundle.adapter == 'twins' and not exists('twinmanager') then valid = false end
            for _, item in ipairs(bundle.items) do
                if not exists(item.prefab) then valid = false; break end
            end
            if valid then entry.bundles[#entry.bundles+1] = bundle end
        end
        if #entry.bundles == 0 then return nil end
        result[#result+1] = entry
    end
    return result
end
function M.Choose(entries, random)
    local total = 0
    for _, entry in ipairs(entries) do total = total + entry.weight end
    local roll = (random or math.random)() * total
    for _, entry in ipairs(entries) do
        roll = roll - entry.weight
        if roll < 0 then return entry end
    end
    return entries[#entries]
end
function M.SpawnBundle(bundle, spawn, configure)
    local created = {}
    local function track(entity)
        assert(entity, 'reward prefab failed to spawn')
        created[#created+1] = entity
        return entity
    end
    local ok, err = pcall(function()
        if bundle.adapter == 'twins' then
            configure(track(spawn('twinmanager')), {prefab='twinmanager'}, 1, track)
        else
            local index = 0
            for _, item in ipairs(bundle.items) do
                for _ = 1, item.count do
                    index = index + 1
                    configure(track(spawn(item.prefab)), item, index, track)
                end
            end
        end
    end)
    if not ok then
        for i=#created,1,-1 do
            if created[i]:IsValid() then created[i]:Remove() end
        end
        return false, err
    end
    return true, created
end
return M
