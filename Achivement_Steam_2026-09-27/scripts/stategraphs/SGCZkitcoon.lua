require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local events =
{
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnHop(),
    CommonHandlers.OnSink(),
}

local states =
{
    State {
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("idle_loop")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    local r = math.random()
                    inst.sg:GoToState(r < 0.4 and "emote_lick" or r < 0.3 and "emote_stretch" or "idle")
                end
            end),
        },
    },

    State {
        name = "castspell",
        tags = {"busy", "canrotate"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.sg.mem.prevcasttime = GetTime()
            inst.AnimState:PlayAnimation("interact_passive")

            inst.sg.statemem.blobfx = SpawnPrefab("bloblight_fx")
            inst.sg.statemem.blobfx.entity:SetParent(inst.entity)

            inst.sg.statemem.stafflight = SpawnPrefab("staff_castinglight")
            inst.sg.statemem.stafflight.Transform:SetScale(0.5, 0.5, 0.5)
            inst.sg.statemem.stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.sg.statemem.stafflight:SetUp({ 1, 1, 1 }, 1.9, .33)
        end,
        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/yawn") end),
            TimeEvent(33*FRAMES, function(inst)
                if inst.sg.statemem.blobfx then
                    inst.sg.statemem.blobfx.KillFX(inst.sg.statemem.blobfx)
                end
                if inst.CastSpell then
                    inst.CastSpell(inst)
                end
            end)
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst:PerformBufferedAction()
            inst:ClearBufferedAction()
        end,
    },
}

CommonStates.AddSimpleState(states, "emote_stretch", "emote_stretch", {"idle", "canrotate"}, nil,
        {
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/yawn") end),
        }
)

CommonStates.AddSimpleState(states, "emote_lick", "emote_lick", {"idle", "canrotate"}, nil,
        {
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/emote_lick") end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/emote_lick") end),
            TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/emote_lick") end),
        }
)

CommonStates.AddHopStates(states, true)
CommonStates.AddSinkAndWashAsoreStates(states)
CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states, nil,
        {
            startrun = "walk_pre",
            run = "walk_loop",
            stoprun = "walk_pst",
        })
CommonStates.AddSleepExStates(states,
        {
            starttimeline =
            {
                TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/yawn") end),
            },
            sleeptimeline =
            {
                TimeEvent(31*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/sleep") end),
            },
        })

return StateGraph("chasni_kitcoon", states, events, "idle")
