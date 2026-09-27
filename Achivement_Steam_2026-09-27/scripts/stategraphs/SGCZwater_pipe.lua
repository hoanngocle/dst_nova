require("stategraphs/commonstates")

local actionhandlers =
{
}
local events =
{
}
local states =
{
    State
    {
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst:Show()
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },

    State
    {
        name = "hidden",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst:Hide()
        end,
    },

    State
    {
        name = "extend",
        tags = {"canrotate"},

        onenter = function(inst)
            inst:Show()
            inst.AnimState:PlayAnimation("place", false)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_sprinkler/pipe_craft","pipesound_on")
        end,

        events =
        {
            EventHandler("animover",
                function(inst)
                    if inst.nextPipe then
                        inst.nextPipe.sg:GoToState("extend")
                    end

                    inst.sg:GoToState("idle")
                end),
        }
    },

	State
	{
		name = "retract",
		tags = {"canrotate"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("retract", false)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_sprinkler/pipe_craft","pipesound_off")
		end,

        events =
        {
            EventHandler("animover",
                function(inst)
                    if inst.prevPipe then
                        inst.prevPipe.sg:GoToState("retract")
                    end

                    inst:Remove()
                end),
        }
	},
}

return StateGraph("water_pipe", states, events, "hidden", actionhandlers)
