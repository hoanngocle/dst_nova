--------------------------------------------------------------------------
--[[ ChasniMoonButterflySpawner class definition ]]
--------------------------------------------------------------------------
--[[
    Spawns moon butterflies at half the rate of normal butterflies.
    - Spawn source: Lune Trees (any time) or flowers (night only)
    - Rate: 20s + random(20s) (half the original 10s+rand(10s))
    - Max: half of TUNING.MAX_BUTTERFLIES
    - Runs on the master server only.
--]]

return Class(function(self, inst)

    assert(TheWorld.ismastersim, "ChasniMoonButterflySpawner should not exist on client")

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    self.inst = inst

    local _worldstate = TheWorld.state
    local _activeplayers = {}
    local _tasks = {}                -- player -> task
    local _moonbutterflies = {}      -- entity -> bool (tracked)
    local _max_moonbutterflies = math.floor((TUNING.MAX_BUTTERFLIES or 4) * 0.5)

    local FLOWER_TAGS = { "flower" }
    local LUNETREE_TAGS = { "moon_tree" }
    local MOONBUTTERFLY_TAGS = { "moonbutterfly" }

    --------------------------------------------------------------------------
    --[[ Private functions ]]
    --------------------------------------------------------------------------

    local function GetSpawnPoint(player)
        local rad = 25
        local mindistance = 36
        local x, y, z = player.Transform:GetWorldPosition()
        local is_night = _worldstate.isnight

        local lune_trees = TheSim:FindEntities(x, y, z, rad, LUNETREE_TAGS)
        for i, v in ipairs(lune_trees) do
            while v ~= nil and player:GetDistanceSqToInst(v) <= mindistance do
                table.remove(lune_trees, i)
                v = lune_trees[i]
            end
        end
        if next(lune_trees) ~= nil then
            return lune_trees[math.random(1, #lune_trees)]
        end

        if is_night then
            local flowers = TheSim:FindEntities(x, y, z, rad, FLOWER_TAGS)
            for i, v in ipairs(flowers) do
                while v ~= nil and player:GetDistanceSqToInst(v) <= mindistance do
                    table.remove(flowers, i)
                    v = flowers[i]
                end
            end
            if next(flowers) ~= nil then
                return flowers[math.random(1, #flowers)]
            end
        end

        return nil
    end

    local function SpawnMoonButterflyForPlayer(player, reschedule)
        local pt = player:GetPosition()
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 64, MOONBUTTERFLY_TAGS)
        if #ents < _max_moonbutterflies then
            local spawnpoint = GetSpawnPoint(player)
            if spawnpoint ~= nil then
                local moonbutterfly = SpawnPrefab("moonbutterfly")
                if moonbutterfly.components.pollinator ~= nil then
                    moonbutterfly.components.pollinator:Pollinate(spawnpoint)
                end
                if moonbutterfly.components.homeseeker ~= nil then
                    moonbutterfly.components.homeseeker:SetHome(spawnpoint)
                end
                moonbutterfly.Physics:Teleport(spawnpoint.Transform:GetWorldPosition())
                _moonbutterflies[moonbutterfly] = true
                inst:ListenForEvent("onremove", function()
                    _moonbutterflies[moonbutterfly] = nil
                end, moonbutterfly)
            end
        end
        _tasks[player] = nil
        reschedule(player)
    end

    local function ScheduleSpawn(player, initialspawn)
        if _tasks[player] == nil then
            local basedelay = initialspawn and 0.3 or 20
            local rand = math.random() * 20
            _tasks[player] = player:DoTaskInTime(basedelay + rand, SpawnMoonButterflyForPlayer, ScheduleSpawn)
        end
    end

    local function CancelSpawn(player)
        if _tasks[player] ~= nil then
            _tasks[player]:Cancel()
            _tasks[player] = nil
        end
    end

    --------------------------------------------------------------------------
    --[[ Public tracking functions ]]
    --------------------------------------------------------------------------

    function self:StartTracking(target)
        if _moonbutterflies[target] == nil then
            _moonbutterflies[target] = true
            inst:ListenForEvent("onremove", function()
                _moonbutterflies[target] = nil
            end, target)
        end
    end

    function self:StopTracking(target)
        if _moonbutterflies[target] ~= nil then
            _moonbutterflies[target] = nil
        end
    end

    --------------------------------------------------------------------------
    --[[ Toggle updates ]]
    --------------------------------------------------------------------------

    local function ToggleUpdates(force)
        if chasni_checkifgroundedexists("chesspiece_butterfly_stone") then
            if not self._active then
                self._active = true
                for i, v in ipairs(_activeplayers) do
                    ScheduleSpawn(v, true)
                end
            elseif force then
                for i, v in ipairs(_activeplayers) do
                    CancelSpawn(v)
                    ScheduleSpawn(v, true)
                end
            end
        elseif self._active then
            self._active = false
            for i, v in ipairs(_activeplayers) do
                CancelSpawn(v)
            end
        end
    end

    --------------------------------------------------------------------------
    --[[ Event handlers ]]
    --------------------------------------------------------------------------

    local function OnPlayerJoined(src, player)
        for i, v in ipairs(_activeplayers) do
            if v == player then return end
        end
        table.insert(_activeplayers, player)
        if self._active then
            ScheduleSpawn(player, true)
        end
    end

    local function OnPlayerLeft(src, player)
        for i, v in ipairs(_activeplayers) do
            if v == player then
                CancelSpawn(player)
                table.remove(_activeplayers, i)
                return
            end
        end
    end

    local function OnWorldStateChanged()
        ToggleUpdates(true)   -- restart schedules to adapt spawn points
    end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    for i, v in ipairs(AllPlayers) do
        table.insert(_activeplayers, v)
    end

    self._active = false

    inst:WatchWorldState("isday", OnWorldStateChanged)
    inst:WatchWorldState("isnight", OnWorldStateChanged)
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

    ToggleUpdates(true)

    --------------------------------------------------------------------------
    --[[ Public functions (optional) ]]
    --------------------------------------------------------------------------

    function self:SetMax(max)
        _max_moonbutterflies = max
    end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------

    function self:GetDebugString()
        local count = 0
        for k, v in pairs(_moonbutterflies) do count = count + 1 end
        return string.format("moonbutterflies:%d/%d", count, _max_moonbutterflies)
    end

    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
end)