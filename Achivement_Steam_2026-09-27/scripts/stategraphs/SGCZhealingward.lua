require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, true),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("walk_loop", true)
        end,
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            ErodeAway(inst)
        end,
    },
}
CommonStates.AddWalkStates(states,
        {},{
            startwalk = "walk_loop",
            walk = "walk_loop",
            stopwalk = "walk_loop",
        })
CommonStates.AddRunStates(states,
        {},{
            startrun = "walk_loop",
            run = "walk_loop",
            stoprun = "walk_loop",
        })
return StateGraph("healingward", states, events, "idle")
