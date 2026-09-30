-- Mainland gate placement adapted from Solo Leveling 2.2.7 / Saikuno.
local M={}
local DUNGEON_RADIUS,MIN_GATE_RELOCATION_DISTANCE,MAX_GATE_CANDIDATES=45,64,200
local function HasTag(tags,tag)
    for _,v in ipairs(tags or {}) do if v==tag then return true end end
    return false
end
function M:FindMainlandSeedIndex()
    local seed = TheSim:FindFirstEntityWithTag("multiplayer_portal")
        or TheSim:FindFirstEntityWithTag("spawnpoint_multiplayer")
    if seed == nil or not seed:IsValid() or TheWorld.Map == nil then
        return nil
    end

    local x, y, z = seed.Transform:GetWorldPosition()
    local node, node_index = TheWorld.Map:FindVisualNodeAtPoint(x, 0, z)
    if node == nil or node_index == nil or node_index <= 0 then
        node, node_index = TheWorld.Map:FindNodeAtPoint(x, 0, z)
    end
    return node_index
end

function M:IsNonMainlandNode(node)
    return node == nil
        or HasTag(node.tags, "not_mainland")
        or HasTag(node.tags, "lunacyarea")
        or HasTag(node.tags, "hn_dungeon_arena")
end

function M:CollectMainlandNodes()
    if self.mainland_nodes_cache ~= nil then
        return self.mainland_nodes_cache
    end

    local topology = TheWorld.topology
    local seed_index = self:FindMainlandSeedIndex()
    if topology == nil or topology.nodes == nil or seed_index == nil then
        return {}
    end

    local seed = topology.nodes[seed_index]
    if self:IsNonMainlandNode(seed) then
        return {}
    end

    local result = {}
    local visited = {}
    local queue = {seed_index}
    local cursor = 1
    visited[seed_index] = true

    while cursor <= #queue do
        local node_index = queue[cursor]
        cursor = cursor + 1
        local node = topology.nodes[node_index]
        if not self:IsNonMainlandNode(node) then
            result[#result + 1] = node_index
            for _, neighbour_index in ipairs(node.neighbours or {}) do
                if not visited[neighbour_index] then
                    visited[neighbour_index] = true
                    queue[#queue + 1] = neighbour_index
                end
            end
        end
    end

    if #result > 0 then
        -- Forest topology is immutable after world generation.  This cache is
        -- runtime-only and intentionally never serialized.
        self.mainland_nodes_cache = result
    end
    return result
end

function M:IsValidGatePoint(x, z, ignore_relocation_distance)
    local map = TheWorld.Map
    if map == nil or x == nil or z == nil then
        return false
    end

    if not map:IsLandTileAtPoint(x, 0, z)
        or map:IsOceanAtPoint(x, 0, z, false)
        or map:IsImpassableTileAtPoint(x, 0, z)
        or not map:IsPassableAtPoint(x, 0, z, false) then
        return false
    end

    local point = Vector3(x, 0, z)
    if map:IsPointNearHole(point, 1.0) or map:IsGroundTargetBlocked(point, 1.0) then
        return false
    end

    local node = nil
    local node_index = nil
    node, node_index = map:FindVisualNodeAtPoint(x, 0, z)
    if node == nil or node_index == nil or node_index <= 0 or self:IsNonMainlandNode(node) then
        return false
    end

    local tagged_node = map:FindVisualNodeAtPoint(x, 0, z, "not_mainland")
    if tagged_node ~= nil then
        return false
    end

    if self.dungeon_center_x ~= 0 or self.dungeon_center_z ~= 0 then
        local arena_distance_sq = (x - self.dungeon_center_x)^2 + (z - self.dungeon_center_z)^2
        if arena_distance_sq <= (DUNGEON_RADIUS + 16)^2 then
            return false
        end
    end

    if not ignore_relocation_distance and self.previous_gate_x ~= nil and self.previous_gate_z ~= nil then
        local distance_sq = (x - self.previous_gate_x)^2 + (z - self.previous_gate_z)^2
        if distance_sq < MIN_GATE_RELOCATION_DISTANCE * MIN_GATE_RELOCATION_DISTANCE then
            return false
        end
    elseif self.previous_gate_x ~= nil and self.previous_gate_z ~= nil then
        local distance_sq = (x - self.previous_gate_x)^2 + (z - self.previous_gate_z)^2
        if distance_sq <= 0.25 then
            return false
        end
    end

    local blockers = TheSim:FindEntities(
        x,
        0,
        z,
        2.5,
        nil,
        {"FX", "NOCLICK", "DECOR", "INANIMATE", "player", "playerghost"}
    )
    for _, blocker in ipairs(blockers) do
        if blocker:IsValid()
            and blocker.prefab ~= "hn_dungeon_gate"
            and not blocker:HasTag("globalmapicon") then
            return false
        end
    end

    return true
end

function M:FindMainlandGatePoint(ignore_relocation_distance)
    local topology = TheWorld.topology
    local nodes = self:CollectMainlandNodes()
    if topology == nil or #nodes == 0 then
        return nil, nil
    end

    -- Shuffle the reachable node order without relying on pairs() order.
    for i = #nodes, 2, -1 do
        local j = math.random(i)
        nodes[i], nodes[j] = nodes[j], nodes[i]
    end

    local inspected = 0
    for _, node_index in ipairs(nodes) do
        local node = topology.nodes[node_index]
        if node ~= nil and node.poly ~= nil then
            local points_x, points_z = TheWorld.Map:GetRandomPointsForSite(
                node.x,
                node.y,
                node.poly,
                8
            )
            for i = 1, #(points_x or {}) do
                inspected = inspected + 1
                if inspected > MAX_GATE_CANDIDATES then
                    return nil, nil
                end

                local x = points_x[i]
                local z = points_z ~= nil and points_z[i] or nil
                if x ~= nil and z ~= nil and self:IsValidGatePoint(x, z, ignore_relocation_distance) then
                    return x, z
                end
            end
        end
    end

    return nil, nil
end


return M
