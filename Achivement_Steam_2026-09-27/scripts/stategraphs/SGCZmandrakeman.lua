require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(true),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true,true),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            if inst.components.health:GetPercent() < TUNING.BUNNYMAN_PANIC_THRESH then
                inst.AnimState:PlayAnimation("idle_happy")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/idle_happy", nil, 0.7)
            elseif inst.components.combat.target then
                inst.AnimState:PlayAnimation("idle_angry")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/idle_angry", nil, 0.7)
            else
                inst.AnimState:PlayAnimation("idle_creepy")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/idle_creepy", nil, 0.7)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name= "happy",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_happy")
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(34*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
            TimeEvent(52*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/clap", nil, 0.8) end),
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
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/death", nil, 0.7)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/eat", nil, 0.7)
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,
        timeline =
        {
            TimeEvent(13*FRAMES, function(inst)
                inst.components.combat:DoAttack() inst.sg:RemoveStateTag("attack")
                inst.sg:RemoveStateTag("busy")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "eat",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/eat", nil, 0.7)
        end,
        timeline =
        {
            TimeEvent(20*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State {
        name = "hit",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        timeline =
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/hit", nil, 0.7) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states,
        {
            walktimeline = {
                TimeEvent(0*FRAMES, PlayFootstep),
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/hop", nil, 0.7) end),
                TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/foley", nil, 0.7) end),
                -- TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/hop") end),
            },
        },
        {
            startwalk = "walk_pre",
            walk = "walk_loop",
            stopwalk = "walk_pst",
        }
)

CommonStates.AddRunStates(states,
        {
            runtimeline = {
                TimeEvent(0*FRAMES, PlayFootstep),
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/hop", nil, 0.7) end),
                TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/foley", nil, 0.7) end),
                -- TimeEvent(12*FRAMES, PlayFootstep),
                -- TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/hop") end),
            },
        },
        {
            startrun = "run_pre",
            run = "run_loop",
            stoprun = "run_pst",
        }
)
CommonStates.AddSleepStates(states,
        {
            sleeptimeline =
            {
                TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/sleep", nil, 0.7) end),
            },
        })
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_mandrakeman", states, events, "idle", actionhandlers)

