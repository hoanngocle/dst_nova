require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, false),
}
local BASE_ATTACK_DURATION = 4
local ATTACK_DURATION = 3
local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "notarget", "noattack", "invisible", "playerghost", "wall" }
local function SoundPath(inst, event)
    return "dontstarve/creatures/mosquito/" .. event
end

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_death"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "spawn",
        tags = {"waking", "busy", "noattack"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spawn")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_death"))
            end),
            TimeEvent(18*FRAMES, function(inst)
                inst.sg:RemoveStateTag("noattack")
            end),
        },
    },

    State {
        name = "attack_pre",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk_pre", false)
        end,
        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/taunt") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack") end),
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_loop", true)
            local attackduration = BASE_ATTACK_DURATION + (math.random() * ATTACK_DURATION)
            inst.sg:SetTimeout(attackduration)
            inst._attack_task = inst:DoPeriodicTask(0.3, function(i)
                i.components.combat:DoAreaAttack(inst, 6, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
            end)
            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/attack_LP", "spinning")
            inst.sg.statemem.position = inst:GetPosition()
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("attack_pst")
        end,
        onexit = function(inst)
            inst.SoundEmitter:KillSound("spinning")
            if inst._attack_task then
                inst._attack_task:Cancel()
                inst._attack_task = nil
            end
        end,
    },

    State {
        name = "attack_pst",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk_pst", false)
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/taunt") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "hit",
        tags = {"hit", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_hurt"))
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "run_start",
        tags = { "moving", "running", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("hover_hover_1_0_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("run")
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("hover_hover_1_0_loop")
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "idle" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hover_hover_1_0_pst")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

return StateGraph("chasni_plasmablob", states, events, "idle")
