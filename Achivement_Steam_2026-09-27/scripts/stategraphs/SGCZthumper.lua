require("stategraphs/commonstates")
local function ShakeIfClose_Pound(inst) ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .025, 1.25, inst, 40) end
local states =
{
    State
    {
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle")
        end,
        events = { EventHandler("animover", function(inst) inst.sg:GoToState("idle") end), }
    },
    State
    {
        name = "raise",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/reset")
            inst.AnimState:PlayAnimation("reset")
            inst:AddTag("fueldepleted")
        end,
        timeline = {
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/steam") end),
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/steam") end),
            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/steam") end),
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/steam") end),
            TimeEvent(34 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/steam") end),
            TimeEvent(51 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/hit") end),
        },
        events = { EventHandler("animover", function(inst) inst.sg:GoToState("smash") end), }
    },
    State
    {
        name = "smash",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("smash")
        end,
        onexit = function(inst)
            inst.components.machine:TurnOff()
            inst:RemoveTag("fueldepleted")
        end,
        timeline = {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/thump")
                inst.components.groundpounder:GroundPound()
                ShakeIfClose_Pound(inst)
            end),
        },
        events = { EventHandler("animover", function(inst) inst.sg:GoToState("idle") end), }
    },
    State
    {
        name = "hit_low",
        tags = {"idle"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/hit")
            inst.AnimState:PlayAnimation("hit_low")
        end,
        events = { EventHandler("animover", function(inst) inst.sg:GoToState("idle") end), }
    },
    State
    {
        name = "place",
        tags = {"busy"},
        onenter = function(inst, data)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_thumper/place")
            inst.AnimState:PlayAnimation("deploy")
        end,
        events = { EventHandler("animover", function(inst) inst.sg:GoToState("idle") end) },
    },
    State
    {
        name = "hit",
        tags = {"busy"},
        onenter = function(inst, data)
            if inst.on then
                inst.AnimState:PlayAnimation("hit_on")
            else
                inst.AnimState:PlayAnimation("hit_off")
            end
        end,
        events = { EventHandler("animover", function(inst) inst.sg:GoToState("idle") end) },
    },
}

return StateGraph("chasni_thumper", states, {}, "idle")