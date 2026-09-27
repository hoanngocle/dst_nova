require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, false),
}

local function SoundPath(inst, event, special)
    return special or "dontstarve_DLC001/creatures/vargr/" .. event
end

local function SpawnHound(inst)
    local hounded = TheWorld.components.hounded
    if hounded then
        local num = inst:NumHoundsToSpawn()
        if inst.max_hound_spawns then
            num = math.min(num,inst.max_hound_spawns)
            inst.max_hound_spawns = inst.max_hound_spawns - num
        end
        local pt = inst:GetPosition()
        for _ = 1, num do
            local hound = hounded:SummonSpawn(pt)
            if hound and hound.components.follower then
                hound.components.follower:SetLeader(inst)
            end
        end
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    local firering = chasni_spawnprefab("wargfant_firering", x, 0, z)
    if firering and firering.SpawnFireRing then
        firering.SpawnFireRing(firering)
    end
end

local states =
{
    State {
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop")
            if not inst.noidlesound then
                inst.SoundEmitter:PlaySound(SoundPath(inst, "idle"))
            end
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "howl",
        tags = { "busy", "howling" },
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("howl")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "howl"))
            inst.sg.statemem.count = data and data.count or nil
        end,
        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.count == nil then
                    SpawnHound(inst)
                end
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.count and inst.sg.statemem.count > 1 then
                    inst.sg:GoToState("howl", {count=inst.sg.statemem.count - 1})
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
}

CommonStates.AddCombatStates(states,
        {
            hittimeline =
            {
                TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "hit")) end),
            },
            attacktimeline =
            {
                TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack")) end),
                TimeEvent(12 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
            },
            deathtimeline =
            {
                TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "death")) end),
            },
        })
CommonStates.AddRunStates(states,
        {
            starttimeline = {},
            runtimeline =
            {
                TimeEvent(5 * FRAMES, function(inst)
                    PlayFootstep(inst)
                    inst.SoundEmitter:PlaySound(SoundPath(inst, "idle"))
                end),
            },
            endtimeline = {},
        })
CommonStates.AddSleepStates(states,
        {
            starttimeline = {},
            sleeptimeline =
            {
                TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "sleep")) end),
            },
            endtimeline = {},
        })
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_wargfant", states, events, "idle")
