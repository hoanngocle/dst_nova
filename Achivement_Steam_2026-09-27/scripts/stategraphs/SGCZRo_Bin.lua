require("stategraphs/commonstates")

local function OnWaterSound(inst)
    if inst.onwater then
        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5)
        inst.components.locomotor:WalkForward()
    end
end

local events =
{
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnStep(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnHop(),
    CommonHandlers.OnDeath(),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < 0.03 then
                    inst.sg:GoToState("emote_idle")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) OnWaterSound(inst) end),
            TimeEvent(8*FRAMES, function(inst) OnWaterSound(inst) end),
            TimeEvent(15*FRAMES, function(inst) OnWaterSound(inst) end),
            TimeEvent(22*FRAMES, function(inst) OnWaterSound(inst) end),
            TimeEvent(29*FRAMES, function(inst) OnWaterSound(inst) end),
        },
    },

    State {
        name = "emote_idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emote_idle")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/emote_idle",nil,.5) end),
            TimeEvent(7*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5) end),
            TimeEvent(8*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.25) end),
            TimeEvent(14*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5) end),
            TimeEvent(16*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.25) end),
            TimeEvent(18*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/emote_idle",nil,.5) end),
            TimeEvent(21*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5) end),
            TimeEvent(22*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.25) end),
        },
    },

    State {
        name = "emote_down",
        tags = {"busy", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emote")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/close",nil,.5) end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/cook", nil, .3) end),
        },
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.container:Close()
            inst.components.container:DropEverything()
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/death",nil,.5)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
        end,
    },

    State {
        name = "open",
        tags = {"busy", "open"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.sleeper:WakeUp()
            inst.AnimState:PlayAnimation("open")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/close",nil,.5)
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("open_idle") end),
        },
    },

    State {
        name = "open_idle",
        tags = {"busy", "open"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_loop_open")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("open_idle") end),
        },
    },

    State {
        name = "close",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("closed")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/close",nil,.5)
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "take_off",
        tags = {"canrotate", "busy"},
        onenter = function(inst)
            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("robin_flight")
            inst.AnimState:PlayAnimation("takeoff")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "land",
        tags = {"canrotate", "busy"},
        onenter = function(inst)
            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("robin_land")
            inst.AnimState:PlayAnimation("takeoff")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/mouth_open",nil,.5) end),
            TimeEvent(8*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/mouth_open",nil,.25) end),
        },
    },


    State {
        name = "spawn",
        tags = {"canrotate", "busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "land",
        tags = {"canrotate", "busy"},
        onenter = function(inst)
            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("ro_bin_water")
            inst.AnimState:PlayAnimation("land")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.AnimState:SetBank("ro_bin")
                inst.sg:GoToState("idle")
            end),
        },

    },

    State {
        name = "takeoff",
        tags = {"canrotate", "busy"},
        onenter = function(inst)
            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end

            inst.AnimState:SetBank("ro_bin_water")
            inst.AnimState:PlayAnimation("takeoff")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states,
        {
            starttimeline =
            {
                TimeEvent(1*FRAMES, function(inst)
                    if inst.onwater then
                        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5)
                        inst.components.locomotor:WalkForward()
                    end
                end),
            },
            walktimeline =
            {
                TimeEvent(0*FRAMES, function(inst)
                    if inst.altstep  then
                        inst.altstep = nil
                    else
                        if not inst.onwater then
                            inst.altstep = true
                        end
                    end
                end),
                TimeEvent(1*FRAMES, function(inst)
                    if inst.onwater then
                        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5)
                        inst.components.locomotor:WalkForward()
                    else
                        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/step",nil,.5)
                        inst.components.locomotor:RunForward()
                    end
                end),
                TimeEvent(13*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/bounce",nil,.5)
                end),
                TimeEvent(8*FRAMES, function(inst)
                    if inst.onwater then
                        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5)
                    end
                end),
                TimeEvent(12*FRAMES, function(inst)
                    if not inst.onwater then
                        PlayFootstep(inst)
                    end
                end),
            },
            endtimeline =
            {
                TimeEvent(1*FRAMES, function(inst)
                    if inst.onwater then
                        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/flap",nil,.5)
                        inst.components.locomotor:WalkForward()
                    end
                end),
            },
        }, nil, true)

CommonStates.AddSleepStates(states,
        {
            starttimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/hit",nil,.5) end)
            },
            waketimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_robin/hit",nil,.5) end)
            },
        })

CommonStates.AddSimpleState(states, "hit", "hit", {"busy"})
CommonStates.AddHopStates(states, true, { pre = "takeoff_test", loop = "fly_loop_test", pst = "land_test"})

return StateGraph("chasni_ro_bin", states, events, "idle")