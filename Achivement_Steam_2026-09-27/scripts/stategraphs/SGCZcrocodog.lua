require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.HARVEST, "eat"),
}

local events =
{
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local should_moving = inst.components.locomotor:WantsToMoveForward()
        if is_moving and not should_moving then
            inst.sg:GoToState("idle")
        elseif (inst.sg:HasStateTag("idle") and should_moving) or (is_moving and should_moving) then
            inst.sg:GoToState("run")
        end
    end),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,
        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/bark", nil, 0.8) end),
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/bite", nil, 0.8) end),
            TimeEvent(20 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) if math.random() < .1 then inst.components.combat:SetTarget(nil) inst.sg:GoToState("taunt") else inst.sg:GoToState("idle", "atk_pst") end end),
        },
    },

    State {
        name = "eat",
        tags = {"busy"},
        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,
        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/bite", nil, 0.8) end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) if inst:PerformBufferedAction() then inst.components.combat:SetTarget(nil) inst.sg:GoToState("taunt") else inst.sg:GoToState("idle", "atk_pst") end end),
        },
    },

    State {
        name = "hit",
        tags = {"busy", "hit"},
        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
        end,
        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/hit", nil, 0.8) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "taunt",
        tags = {"busy"},
        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/taunt", nil, 0.7)
        end,
        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/taunt") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/death", nil, 0.8)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "run",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/run", nil, 0.9)
        end,
        timeline =
        {
            TimeEvent(0, function(inst) PlayFootstep(inst) end),
            TimeEvent(3 * FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(5 * FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(7 * FRAMES, function(inst) PlayFootstep(inst) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end),
        },
    },
}
CommonStates.AddSleepStates(states,
        {
            sleeptimeline = {
                TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/sleep", nil, 0.8) end),
                TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_crocodog/sleep", nil, 0.8) end),
            },
        })
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_crocodog", states, events, "idle", actionhandlers)
