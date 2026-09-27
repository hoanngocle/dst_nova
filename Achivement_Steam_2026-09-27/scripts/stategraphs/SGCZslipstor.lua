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
    return "dontstarve/creatures/leif" .. event
end

local states =
{
    State {
        name = "sleep",
        tags = { "busy", "sleeping" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("heal_pre")
                    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                        inst.components.sleeper:WakeUp()
                    end
                end
            end),
            EventHandler("onwakeup", function(inst)
                inst.sg:GoToState("heal_pre")
                if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
            end),
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("anim")
            inst.sg.statemem.target = target
        end,
        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(26 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "foley")) end),
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_VO")) end),
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "swipe")) end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "foley")) end),
            TimeEvent(23 * FRAMES, function(inst) inst.AnimState:PlayAnimation("idle_loop") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "hit",
        tags = {"hit", "busy"},
        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_pre")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hurt_VO"))
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound(SoundPath(inst, "foley"))
                inst.spawnslip(inst)
            end),
        },
    },

    State {
        name = "transform",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("transform")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "heal_pre",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("heal") end),
        },
    },

    State {
        name = "heal",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_loop")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("heal_pst") end),
        },
    },

    State {
        name = "heal_pst",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_pst")
            if inst.components.health then
                inst.components.health:SetPercent(1)
            end
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states)
CommonStates.AddIdle(states)
CommonStates.AddDeathState(states)
CommonStates.AddFrozenStates(states)
return StateGraph("chasni_slipstor", states, events, "idle")

