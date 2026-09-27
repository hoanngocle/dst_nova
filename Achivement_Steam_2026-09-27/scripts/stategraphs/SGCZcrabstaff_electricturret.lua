require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnAttack(),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PushAnimation("idle")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst:triggerlight()
            inst.sg.statemem.target = target
            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/charge")
        end,
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/shoot")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

return StateGraph("chasni_crabstaff_electricturret", states, events, "idle")
