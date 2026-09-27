require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnSink(),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            if not inst.sg:HasStateTag("attack") then
                inst.sg:GoToState("hit")
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            --inst.sg:GoToState(data.target:IsValid()
            --        and not inst:IsNear(data.target, TUNING.SPIDER_SPITTER_MELEE_RANGE)
            --        and "spitter_attack" --Do spit attack
            --        or "attack",
            --        data.target
            --)
            inst.sg:GoToState("attack", data.target)
        end
    end),
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("premoving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}

local function SoundPath(event)
    return "dontstarve/creatures/cavespider/" .. event
end

local states =
{
    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath("die"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            if inst.components.lootdropper then
                inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            end
        end,
    },

    State {
        name = "premoving",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,
        timeline =
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("walk_spider")) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State {
        name = "moving",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("walk_spider")) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("walk_spider")) end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("walk_spider")) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("walk_spider")) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            if math.random() < 0.3 then
                inst.sg:SetTimeout(math.random()*2 + 2)
            end
            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State {
        name = "eat",
        tags = {"busy"},
        onenter = function(inst, forced)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_down_pre")
            inst.sg.statemem.forced = forced
            inst.SoundEmitter:PlaySound(SoundPath("eat"), "eating")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                local state = (inst:PerformBufferedAction() or inst.sg.statemem.forced) and "eat_loop" or "idle"
                if state == "idle" then
                    inst.SoundEmitter:KillSound("eating")
                end
                inst.sg:GoToState(state)
            end),
        },
    },

    State {
        name = "eat_loop",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_down_loop", true)
            inst.sg:SetTimeout(2+math.random()*1)
        end,
        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("eating")
            inst.sg:GoToState("idle", "eat_down_pst")
        end,
    },

    State {
        name = "born",
        tags = {"busy"},
        onenter = function(inst) inst.AnimState:PlayAnimation("taunt") end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "taunt",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spit")
            inst.SoundEmitter:PlaySound(SoundPath("scream"))
        end,
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
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,
        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("Attack")) end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("attack_grunt")) end),
            TimeEvent(25*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "spitter_attack",
        tags = {"attack", "canrotate", "busy", "spitting"},
        onenter = function(inst, target)
            if inst.weapon and inst.components.inventory then
                inst.components.inventory:Equip(inst.weapon)
            end
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("spit")
            inst.sg.statemem.target = target
        end,
        onexit = function(inst)
            if inst.components.inventory then
                inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
            end
        end,
        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("spit_web")) end),
            TimeEvent(14*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.SoundEmitter:PlaySound(SoundPath("spit_voice"))
            end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "hit",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "hit_stunlock",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath("hit_response"))
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddSleepStates(states,
        {
            starttimeline = {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("fallAsleep")) end),
            },
            sleeptimeline =
            {
                TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("sleeping")) end),
            },
            waketimeline = {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath("wakeUp")) end),
            },
        })
CommonStates.AddFrozenStates(states)
CommonStates.AddSinkAndWashAsoreStates(states)

return StateGraph("chasni_spider", states, events, "idle", actionhandlers)
