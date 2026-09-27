local Logic = {}

function Logic.FindLocation(world, sim, random)
    random = random or math.random
    local map = world.Map
    local width, height = map:GetSize()
    local half_width = width * TILE_SCALE / 2
    local half_height = height * TILE_SCALE / 2

    for _ = 1, 100 do
        local x = (random() * 2 - 1) * half_width
        local z = (random() * 2 - 1) * half_height
        local point = Vector3(x, 0, z)
        if map:IsPassableAtPoint(x, 0, z)
            and not map:IsOceanTileAtPoint(x, 0, z)
            and (map.IsGroundTargetBlocked == nil or not map:IsGroundTargetBlocked(point))
            and map:IsDeployPointClear(point, nil, 1)
            and #sim:FindEntities(x, 0, z, 8, { "nova_treasure_site" }) == 0
        then
            return x, z
        end
    end
    return nil
end

local function RevealToPlayer(player, x, z)
    local classified = player.player_classified
    if classified == nil then return end
    classified.revealmapspot_worldx:set(x)
    classified.revealmapspot_worldz:set(z)
    classified.revealmapspotevent:push()
    player:DoTaskInTime(4 * FRAMES, function(inst)
        local c = inst.player_classified
        if c ~= nil and c.MapExplorer ~= nil then
            c.MapExplorer:RevealArea(x, 0, z)
        end
    end)
end

function Logic.OpenScroll(scroll, player, world, sim, spawn, random)
    if scroll == nil or player == nil or world == nil or sim == nil then return false end
    local x, z = Logic.FindLocation(world, sim, random)
    if x == nil then return false end

    local site = spawn("nova_treasure_site")
    if site == nil then return false end
    site.Transform:SetPosition(x, 0, z)
    RevealToPlayer(player, x, z)

    local stackable = scroll.components and scroll.components.stackable
    if stackable ~= nil and stackable:IsStack() then
        local one = stackable:Get()
        if one ~= nil then one:Remove() end
    else
        scroll:Remove()
    end
    return true, x, z
end

function Logic.ResolveSite(site, digger, rewards, spawn, is_available, roll)
    if site._nova_resolved then return false end
    local outcome = rewards.ChooseOutcome(is_available, roll)
    local result = outcome ~= nil and spawn(outcome.prefab) or nil
    if result == nil or result.Transform == nil then
        site.components.workable:SetWorkLeft(1)
        return false
    end

    local x, _, z = site.Transform:GetWorldPosition()
    result.Transform:SetPosition(x, 0, z)
    site._nova_resolved = true
    site:Remove()
    return true, outcome
end

return Logic
