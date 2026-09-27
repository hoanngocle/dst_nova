require("stategraphs/commonstates")

local function startaura(inst)
    inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_attack_LP", "angry")
end

local function stopaura(inst)
    inst.SoundEmitter:KillSound("angry")
end

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    EventHandler("startaura",  function(inst) startaura(inst) end),
    EventHandler("stopaura", function(inst) stopaura(inst) end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}

local states =
{
    State
    {
        name = "idle",
        tags = {"idle", "canrotate", "canslide"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },

    State
    {
        name = "appear",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl")
        end,
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/appear") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State
    {
        name = "taunt",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/taunt") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State
    {
        name = "summon",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("summon")
        end,
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/summon") end),
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/summon_2d") end),
            TimeEvent(30*FRAMES, function(inst) inst:DoSpawning() end)
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },
}

CommonStates.AddCombatStates(states,
        {
            attacktimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/attack") end),
                TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/attack_2d") end),
                TimeEvent(20*FRAMES, function(inst) inst:DoAoeAttack() end)
            },
            hittimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/hit") end),
            },
            deathtimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/death") end),
                TimeEvent(32*FRAMES, function(inst)
                    local product = GetRandomItem({"jellybean_yellow", "jellybean_green", "jellybean_green", "jellybean_red", "jellybean_red", "jellybean_red",})
                    local jellybean = SpawnPrefab(product)
                    jellybean:PushEvent("on_loot_dropped", {dropper = inst})
                    inst.components.lootdropper:FlingItem(jellybean)
                    inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition())) 
                end),
            },
        },
        {
            attack = "attack",
        })

CommonStates.AddWalkStates(states,
        {
            walktimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/breath_in") end),
                TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_ancient_herald/breath_out") end),
            }
        })

return StateGraph("chasni_ancientherald", states, events, "idle")