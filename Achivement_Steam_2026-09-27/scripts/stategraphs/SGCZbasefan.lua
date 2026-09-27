require("stategraphs/commonstates")

local events = {}

local states = 
{
    State
    {
        name = "turn_on",
        tags = {"idle"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("basefan/basefan_sound/On", nil, 0.3)
            inst.AnimState:PlayAnimation("activate")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end),
        }
    },

    State
    {
        name = "turn_off",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("deactivate")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_off") end),
        }
    },

    State
    {
        name = "idle_on",
        tags = {"idle"},
        onenter = function(inst)
            if not inst.SoundEmitter:PlayingSound("idle_loop") then
                inst.SoundEmitter:PlaySound("basefan/basefan_sound/idleloop", "idle_loop", 0.5)
            end
            inst.AnimState:PlayAnimation("idle_loop")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end),
        }
    },

    State
    {
        name = "idle_off",
        tags = {"idle"},
        onenter = function(inst)
            --Stop some loop sound
            inst.SoundEmitter:KillSound("idle_loop")
            inst.SoundEmitter:PlaySound("basefan/basefan_sound/Off", nil, 0.2)
            inst.AnimState:PlayAnimation("off", true)
        end,
    },

    State
    {
        name = "spin_up",
        tags = {"busy"},
        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("launch_pre")
            inst.sg.statemem.data = data
        end,
        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("shoot", inst.sg.statemem.data) end)
        },
    },

    State
    {
        name = "spin_down",
        tags = {"busy"},
        onenter = function(inst, data) inst.AnimState:PlayAnimation("launch_pst") end,
        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_loop") end)
        },
    },

    State
    {  
        name = "place",
        tags = {"busy"},
        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("place")
            inst.SoundEmitter:PlaySound("basefan/basefan_sound/Place", nil, 0.2)
        end,
        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_loop") end)
        },
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
            inst.SoundEmitter:PlaySound("basefan/basefan_sound/Hit", nil, 0.2)
        end,
        events = 
        {
            EventHandler("animover", function(inst) 
                if inst.on then 
                    inst.sg:GoToState("idle_loop")
                else
                    inst.sg:GoToState("idle_off")
                end
            end)
        },
    },
}

return StateGraph("chasni_basefan", states, events, "idle_off")