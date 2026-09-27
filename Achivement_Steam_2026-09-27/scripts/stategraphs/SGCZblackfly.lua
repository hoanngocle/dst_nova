require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(false, true),
}

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
            inst.AnimState:PlayAnimation("idle_angry", true)
        end,
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:KillSound("buzz")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_death"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "sleep",
        tags = { "busy", "sleeping" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
        end,
        timeline =
        {
            TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:KillSound("buzz") end)
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("sleeping") end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "sleeping",
        tags = { "sleeping" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_loop")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "wake",
        tags = { "busy", "waking" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end,
        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_fly_LP"), "buzz") end)
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
        end,
        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_attack"))
            end),
            TimeEvent(15 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        events =
        {
            EventHandler("onhitother", function(inst) inst.sg:GoToState("evade") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "evade",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("evade")
        end,
        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "mosquito_attack"))
                inst.Physics:SetMotorVel(-60, 0, 0)
                inst.components.health:SetInvincible(true)
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.Physics:Stop()
                inst.components.health:SetInvincible(false)
            end),
        },
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
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
}

CommonStates.AddWalkStates(states)
CommonStates.AddFrozenStates(states)
return StateGraph("chasni_blackfly", states, events, "idle")
