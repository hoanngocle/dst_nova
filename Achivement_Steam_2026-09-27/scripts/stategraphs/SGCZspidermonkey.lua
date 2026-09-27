require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
    EventHandler("agitated", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("taunt")
        end
    end),
}

local states =
{
    State
    {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if (inst.components.combat.target and
                        inst.components.combat.target:HasTag("player")) or inst:HasTag("agitated") then
                    if math.random() < 0.1 then
                        inst.sg:GoToState("taunt")
                        return
                    end
                end
                inst.sg:GoToState("idle")
            end),
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
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/taunt") end),
            TimeEvent(20 * FRAMES, function(inst)
                if inst.SlowingAttack then
                    inst.SlowingAttack(inst)
                end
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/step",nil,.5) 
            end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/step") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states,
        {
            walktimeline =
            {
                TimeEvent(1 * FRAMES, function(inst) PlayFootstep(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/step") end),
                TimeEvent(2 * FRAMES, function(inst) PlayFootstep(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/step") end),
            },
        })
CommonStates.AddSleepStates(states,
        {
            sleeptimeline =
            {
                TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/sleep") end),
            },
        })
CommonStates.AddCombatStates(states,
        {
            attacktimeline =
            {
                TimeEvent(1 * FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/swipe") end),
                TimeEvent(11 * FRAMES, function(inst) inst.components.combat:DoAttack() end)
            },
            hittimeline =
            {
                TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/hurt") end),
            },
            deathtimeline =
            {
                TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_spidermonkey/death") end),
            },
        })
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_spidermonkey", states, events, "idle")