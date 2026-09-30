-- Adapted from Solo Leveling 2.2.7 / Saikuno.
-- Issue 4: dynamic dungeon walls are registered in Pathfinder, while some
-- custom attack/knockback states move with motor velocity. Validate only
-- those active movement states; normal locomotion remains vanilla physics.
local function HHIsDungeonMotionEntity(inst)
    if inst == nil or inst.Transform == nil then
        return false
    end
    if inst:HasTag("in_hn_dungeon")
        or inst.hn_is_dungeon_monster == true
        or inst.hn_is_dungeon_boss == true
        or inst:HasTag("hn_dungeon_mob") then
        return true
    end

    local follower = inst.components ~= nil and inst.components.follower or nil
    local leader = follower ~= nil and follower:GetLeader() or nil
    return leader ~= nil and leader:IsValid() and leader:HasTag("in_hn_dungeon")
end

local function HHIsDungeonPathClear(inst, from_pos, x, z)
    if not HHIsDungeonMotionEntity(inst) then
        return true
    end
    local pathfinder = TheWorld ~= nil and TheWorld.Pathfinder or nil
    if pathfinder == nil then
        return false
    end

    local sx, sz
    if from_pos ~= nil then
        sx, sz = from_pos.x, from_pos.z
    else
        local px, _, pz = inst.Transform:GetWorldPosition()
        sx, sz = px, pz
    end
    return pathfinder:IsClear(sx, 0, sz, x, 0, z)
end

local function HHGetDungeonMotionStateMem(inst)
    return inst ~= nil and inst.sg ~= nil and inst.sg.statemem or nil
end

local function HHBeginDungeonMotion(inst)
    if not HHIsDungeonMotionEntity(inst) then
        return
    end
    local statemem = HHGetDungeonMotionStateMem(inst)
    if statemem == nil then
        return
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    statemem._hh_dungeon_motion_last_clear_pos = Vector3(x, 0, z)
end

local function HHStopAtDungeonMotionPosition(inst)
    local statemem = HHGetDungeonMotionStateMem(inst)
    local safe = statemem ~= nil and statemem._hh_dungeon_motion_last_clear_pos or nil
    if inst.Physics == nil then
        return
    end
    inst.Physics:Stop()
    inst.Physics:ClearMotorVelOverride()
    if safe ~= nil then
        inst.Physics:Teleport(safe.x, 0, safe.z)
    end
end

local function HHCheckDungeonMotion(inst)
    if not HHIsDungeonMotionEntity(inst) then
        return true
    end

    local statemem = HHGetDungeonMotionStateMem(inst)
    if statemem == nil then
        return true
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    local safe = statemem._hh_dungeon_motion_last_clear_pos
    if safe == nil then
        statemem._hh_dungeon_motion_last_clear_pos = Vector3(x, 0, z)
        return true
    end

    local dx = x - safe.x
    local dz = z - safe.z
    if dx * dx + dz * dz < 0.0001 then
        return true
    end

    if not HHIsDungeonPathClear(inst, safe, x, z) then
        HHStopAtDungeonMotionPosition(inst)
        return false
    end

    safe.x, safe.y, safe.z = x, 0, z
    return true
end

local function HHWrapDungeonMotionState(state_name, state)
    local old_onenter = state.onenter
    local old_onupdate = state.onupdate
    local old_onexit = state.onexit
    state._hh_dungeon_motion_guarded = true

    state.onenter = function(inst, data)
        HHBeginDungeonMotion(inst)

        if old_onenter ~= nil then
            old_onenter(inst, data)
        end

        if inst.sg ~= nil and inst.sg.currentstate == state then
            HHCheckDungeonMotion(inst)
        end
    end

    state.onupdate = function(inst, dt)
        if old_onupdate ~= nil then
            old_onupdate(inst, dt)
        end
        if inst.sg == nil or inst.sg.currentstate ~= state then
            return
        end
        HHCheckDungeonMotion(inst)
    end

    state.onexit = function(inst)
        if inst.sg ~= nil and inst.sg.currentstate == state then
            local statemem = HHGetDungeonMotionStateMem(inst)
            if statemem ~= nil then
                statemem._hh_dungeon_motion_last_clear_pos = nil
            end
        end
        if old_onexit ~= nil then
            old_onexit(inst)
        end
    end
end

local function HHInstallDungeonMotionStates(sg, state_names)
    if sg.states == nil then
        return
    end
    for _, state_name in ipairs(state_names) do
        local state = sg.states ~= nil and sg.states[state_name] or nil
        if state ~= nil and not state._hh_dungeon_motion_guarded then
            HHWrapDungeonMotionState(state_name, state)
        end
    end
end

local function HHWrapDungeonKnockbackState(state_name, state)
    local old_onenter = state.onenter
    local old_onupdate = state.onupdate
    local old_onexit = state.onexit
    state._hh_dungeon_knockback_guarded = true

    state.onenter = function(inst, data)
        HHBeginDungeonMotion(inst)
        if old_onenter ~= nil then
            old_onenter(inst, data)
        end
        if inst.sg ~= nil and inst.sg.currentstate == state then
            HHCheckDungeonMotion(inst)
        end
    end

    state.onupdate = function(inst, dt)
        if old_onupdate ~= nil then
            old_onupdate(inst, dt)
        end
        if inst.sg == nil or inst.sg.currentstate ~= state then
            return
        end
        HHCheckDungeonMotion(inst)
    end

    state.onexit = function(inst)
        if inst.sg ~= nil and inst.sg.currentstate == state then
            local statemem = HHGetDungeonMotionStateMem(inst)
            if statemem ~= nil then
                statemem._hh_dungeon_motion_last_clear_pos = nil
            end
        end
        if old_onexit ~= nil then
            old_onexit(inst)
        end
    end
end

local function HHInstallDungeonKnockbackGuard(sg)
    for _, state_name in ipairs({"knockback", "knockbacklanded"}) do
        local state = sg.states ~= nil and sg.states[state_name] or nil
        if state ~= nil and not state._hh_dungeon_knockback_guarded then
            HHWrapDungeonKnockbackState(state_name, state)
        end
    end
end

AddStategraphPostInit("wilson", HHInstallDungeonKnockbackGuard)

local function HHInstallNamedDungeonMotionStates(state_names)
    return function(sg)
        HHInstallDungeonMotionStates(sg, state_names)
    end
end

-- The player shadow-knife leap uses a motor burst followed by a direct
-- Physics:Teleport. It is guarded only while the player is inside a dungeon.
AddStategraphPostInit(
    "wilson",
    HHInstallNamedDungeonMotionStates({"hh_knife_aoe"})
)

AddStategraphPostInit(
    "hh_igris_shadow",
    HHInstallNamedDungeonMotionStates({
        "attack3",
        "relentless_dash_1",
        "relentless_dash_2",
        "relentless_attack3",
        "attack_rotate",
    })
)
AddStategraphPostInit(
    "hn_igris",
    HHInstallNamedDungeonMotionStates({
        "attack3",
        "relentless_dash_1",
        "relentless_dash_2",
        "relentless_attack3",
        "attack_rotate",
    })
)
AddStategraphPostInit(
    "hh_beru_shadow",
    HHInstallNamedDungeonMotionStates({"attack3", "attack_jump"})
)
AddStategraphPostInit(
    "hn_beru",
    HHInstallNamedDungeonMotionStates({"attack3", "attack_jump"})
)
AddStategraphPostInit(
    "hh_beetle_pig",
    HHInstallNamedDungeonMotionStates({"attack3", "attack_jump"})
)
AddStategraphPostInit(
    "hh_dual_wield_pig",
    HHInstallNamedDungeonMotionStates({"attack3", "attack_rotate"})
)
AddStategraphPostInit(
    "hn_sharkboi",
    HHInstallNamedDungeonMotionStates({
        "spawn",
        "attack3",
        "torpedo_jump",
        "torpedo",
        "dive_jump_delay",
        "dive_jump",
        "dive_dig_stun",
    })
)

-- The dungeon spider's evade state is injected in hh_dungeon_mobs_sg.lua and
-- uses both SetMotorVelOverride and SetMotorVel. Guard that state only.
AddStategraphPostInit(
    "spider",
    HHInstallNamedDungeonMotionStates({"evade_loop", "warrior_attack"})
)

-- Vanilla dungeon mobs with state-local dash/joust motor bursts. Keep the
-- guard limited to those states so ordinary locomotion remains untouched.
AddStategraphPostInit(
    "bearger",
    HHInstallNamedDungeonMotionStates({
        "attack_combo1",
        "attack_combo2",
        "attack_combo1a",
        "butt",
        "butt_pst",
    })
)
AddStategraphPostInit(
    "rook",
    HHInstallNamedDungeonMotionStates({"run_stop"})
)
AddStategraphPostInit(
    "knight",
    HHInstallNamedDungeonMotionStates({
        "joust_pre",
        "joust_loop",
        "joust_pst",
        "joust_collide",
    })
)
AddStategraphPostInit(
    "minotaur",
    HHInstallNamedDungeonMotionStates({"leap_attack"})
)
AddStategraphPostInit(
    "dragonfly",
    HHInstallNamedDungeonMotionStates({"flyaway"})
)

