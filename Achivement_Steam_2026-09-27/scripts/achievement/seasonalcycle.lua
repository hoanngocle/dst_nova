local Catalog = require "constants/seasonaltaskcatalog"
local Rewards = require "constants/seasonalrewarddata"

local Cycle = {}
local SCHEMA = 2

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function EmptyRewards()
    local rewards = {}
    for _, milestone in ipairs(Rewards.MILESTONES) do
        rewards[milestone] = {id=nil, claimed=false, receipt=nil}
    end
    return rewards
end

local function AssignRound(state, random_fn)
    local definitions, err = Catalog.Draw(state.season, state.used_ids, random_fn)
    if definitions == nil then return false, err end
    state.slots = {}
    for index, definition in ipairs(definitions) do
        state.used_ids[definition.id] = true
        state.slots[index] = {id=definition.id, progress=0, complete=false}
    end
    state.rewards = EmptyRewards()
    return true
end

function Cycle.New(season, season_key, random_fn)
    assert(Catalog.IsSeason(season), "invalid seasonal cycle season")
    assert(type(season_key) == "string" and season_key ~= "", "invalid seasonal cycle key")
    local state = {
        schema = SCHEMA,
        season = season,
        season_key = season_key,
        round = 1,
        status = "active",
        used_ids = {},
        slots = {},
        rewards = EmptyRewards(),
    }
    local ok, err = AssignRound(state, random_fn)
    assert(ok, err)
    return state
end

local function IsValid(saved, season, season_key)
    if type(saved) ~= "table" or saved.schema ~= SCHEMA then return false end
    if saved.season ~= season or saved.season_key ~= season_key then return false end
    if type(saved.round) ~= "number" or saved.round < 1 or saved.round > 4 or saved.round ~= math.floor(saved.round) then return false end
    if saved.status ~= "active" and saved.status ~= "finished" then return false end
    if saved.status == "finished" and saved.round ~= 4 then return false end
    if type(saved.used_ids) ~= "table" or type(saved.slots) ~= "table" or #saved.slots ~= 6 then return false end
    local seen = {}
    for _, slot in ipairs(saved.slots) do
        if type(slot) ~= "table" or type(slot.id) ~= "string" or seen[slot.id] then return false end
        local definition = Catalog.ById(slot.id)
        if definition == nil or definition.season ~= season then return false end
        if type(slot.progress) ~= "number" or slot.progress < 0 or slot.progress > definition.target then return false end
        if type(slot.complete) ~= "boolean" or slot.complete ~= (slot.progress >= definition.target) then return false end
        if saved.used_ids[slot.id] ~= true then return false end
        seen[slot.id] = true
    end
    if type(saved.rewards) ~= "table" then return false end
    for _, milestone in ipairs(Rewards.MILESTONES) do
        local reward = saved.rewards[milestone]
        if type(reward) ~= "table" or type(reward.claimed) ~= "boolean" then return false end
        if reward.id ~= nil and not Rewards.IsAllowed(reward.id, milestone) then return false end
        if reward.claimed and reward.id == nil then return false end
    end
    return true
end

function Cycle.Load(saved, season, season_key, random_fn)
    if IsValid(saved, season, season_key) then return Copy(saved), false end
    return Cycle.New(season, season_key, random_fn), true
end

function Cycle.Advance(state, task_id, amount)
    if type(state) ~= "table" or state.status ~= "active" or type(task_id) ~= "string" then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false end
    for _, slot in ipairs(state.slots or {}) do
        if slot.id == task_id then
            if slot.complete then return false end
            local definition = Catalog.ById(task_id)
            if definition == nil then return false end
            slot.progress = math.min(definition.target, slot.progress + amount)
            if slot.progress >= definition.target then
                slot.complete = true
                return true
            end
            return false
        end
    end
    return false
end

function Cycle.CompletedCount(state)
    local count = 0
    for _, slot in ipairs(type(state) == "table" and state.slots or {}) do
        if slot.complete then count = count + 1 end
    end
    return count
end

function Cycle.EnsureRewardRolls(state, roll_fn)
    if type(state) ~= "table" or type(roll_fn) ~= "function" then return false end
    local completed = Cycle.CompletedCount(state)
    local changed = false
    for _, milestone in ipairs(Rewards.MILESTONES) do
        local reward = state.rewards and state.rewards[milestone] or nil
        if completed >= milestone and reward and reward.id == nil then
            local id = roll_fn(state.season, milestone)
            if type(id) == "string" and id ~= "" then
                reward.id = id
                changed = true
            end
        end
    end
    return changed
end

function Cycle.CanClaim(state, milestone)
    local reward = type(state) == "table" and state.rewards and state.rewards[milestone] or nil
    return state.status == "active" and Cycle.CompletedCount(state) >= milestone
        and type(reward) == "table" and type(reward.id) == "string" and not reward.claimed
end

function Cycle.MarkClaimed(state, milestone, receipt)
    if not Cycle.CanClaim(state, milestone) then return false end
    local reward = state.rewards[milestone]
    reward.claimed = true
    reward.receipt = receipt
    return true
end

function Cycle.CanAdvanceRound(state)
    if type(state) ~= "table" or state.status ~= "active" or Cycle.CompletedCount(state) ~= 6 then return false end
    for _, milestone in ipairs(Rewards.MILESTONES) do
        local reward = state.rewards and state.rewards[milestone] or nil
        if type(reward) ~= "table" or not reward.claimed then return false end
    end
    return true
end

function Cycle.NextRound(state, random_fn)
    if not Cycle.CanAdvanceRound(state) then return false end
    if state.round >= 4 then
        state.status = "finished"
        return true
    end
    state.round = state.round + 1
    local ok = AssignRound(state, random_fn)
    return ok == true
end

return Cycle
