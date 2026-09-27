require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.PANGO_POOP, "poop"),
}

local PANGOLDEN_BALL_DEFENCE = 0.99
local PANGOLDEN_BALL_REGEN = 10
local PANGOLDEN_BALL_COOLDOWN = 15
local PANGOLDEN_BALL_SMALL_COOLDOWN = 1
local events =
{
    CommonHandlers.OnAttack(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("attack") then
            if inst.components.health:GetPercent() <= 0.5 and not inst.sg:HasStateTag("ball") and not inst.components.timer:TimerExists("ball_cd") then
                inst.sg:GoToState("ball_pre")
            elseif inst.components.health:GetPercent() > 0.9 and inst.sg:HasStateTag("ball") then
                inst.sg:GoToState("idle", "ball_pst")
            elseif inst.sg:HasStateTag("ball") then
                inst.sg:GoToState("ball_hit")
            else
                inst.sg:GoToState("hit")
            end
        end
    end),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            if not pushanim and math.random() < 0.1 then
                if math.random() < 0.4 then
                    inst.sg:GoToState("shake")
                else
                    inst.sg:GoToState("preen")
                end
            else
                if pushanim then
                    inst.AnimState:PlayAnimation(pushanim)
                    inst.AnimState:PushAnimation("idle_loop", true)
                else
                    inst.AnimState:PlayAnimation("idle_loop", true)
                end
                inst.sg:SetTimeout(2 + 2 * math.random())
            end
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State {
        name = "shake",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shake")
        end,
        timeline =
        {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "preen",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("preen_pre")
            for i=1, math.random(1,4)  do
                inst.AnimState:PushAnimation("preen_loop",false)
            end
        end,
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt",nil,.5) end),
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/lick") end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/lick") end),
            TimeEvent(57*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/lick") end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("preen_pst") end),
        },
    },

    State {
        name = "preen_pst",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("preen_pst")
        end,
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/lick") end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "ball_pre",
        tags = {"ball", "busy"},
        onenter = function(inst, target)
            inst.components.health:SetAbsorptionAmount(PANGOLDEN_BALL_DEFENCE)
            inst.components.health:StartRegen(PANGOLDEN_BALL_REGEN, 1)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("ball_pre")
            inst.components.timer:StartTimer("ball_cd", PANGOLDEN_BALL_COOLDOWN)
        end,
        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", .01)
            end),
            TimeEvent(6*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", .33)
            end),
            TimeEvent(9*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", .66)
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk")
            end),
            TimeEvent(30*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
            inst.components.health:StopRegen()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("ball") end),
        },
    },

    State {
        name = "ball",
        tags = {"ball", "busy"},
        onenter = function(inst)
            inst.components.health:SetAbsorptionAmount(PANGOLDEN_BALL_DEFENCE)
            inst.components.health:StartRegen(PANGOLDEN_BALL_REGEN, 1)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("ball_idle", true)
            inst.sg:SetTimeout(3 + (7 * math.random()))
        end,
        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
            inst.components.health:StopRegen()
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("ball_pst")
        end,
    },

    State {
        name = "ball_pst",
        tags = {"ball", "busy"},
        onenter = function(inst, target)
            inst.AnimState:PlayAnimation("ball_pst")
        end,
        timeline =
        {
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", .88)
            end),
            TimeEvent(14*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", .44)
            end),
            TimeEvent(17*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", .22)
                inst.components.timer:StopTimer("ball_cd")
                inst.components.timer:StartTimer("ball_cd", PANGOLDEN_BALL_SMALL_COOLDOWN)
            end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk") end),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "ball_hit",
        tags = {"ball", "busy"},
        onenter = function(inst, target)
            inst.components.health:SetAbsorptionAmount(PANGOLDEN_BALL_DEFENCE)
            inst.components.health:StartRegen(PANGOLDEN_BALL_REGEN, 1)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("ball_hit")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit")
        end,
        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
            inst.components.health:StopRegen()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("ball") end),
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk", false)
        end,
        timeline =
        {
            TimeEvent(17*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "poop",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("poop")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/poop")
        end,
        timeline =
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/fart") end),
            TimeEvent(45*FRAMES, PlayFootstep),
            TimeEvent(43*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit")
                local gold = SpawnPrefab("goldnugget")
                local x,y,z = inst.Transform:GetWorldPosition()
                gold.Transform:SetPosition(x,y,z)
            end),
            TimeEvent(56*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/step") end),
            TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(59*FRAMES, PlayFootstep),
            TimeEvent(67*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            TimeEvent(68*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/step") end),
            TimeEvent(70*FRAMES, PlayFootstep),
            TimeEvent(68*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/step") end),
            TimeEvent(81*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),

        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(
        states,
        {
            walktimeline =
            {
                TimeEvent(0*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk","steps")
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit")
                end),
                TimeEvent(2*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", .9)
                end),
                TimeEvent(2*FRAMES, PlayFootstep),
                TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
                TimeEvent(20*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk","steps")
                end),
                TimeEvent(21*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk","steps")
                    inst.SoundEmitter:SetParameter("steps", "intensity", .9)
                end),
                TimeEvent(21*FRAMES, PlayFootstep),
                TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            },
            endtimeline =
            {
                TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
                TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk") end),
            }
        })
CommonStates.AddRunStates(
        states,
        {
            runtimeline =
            {
                TimeEvent(0*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk","steps")
                    inst.SoundEmitter:SetParameter("steps", "timeoffset", math.random())

                end),
                TimeEvent(2*FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/walk","steps")
                    inst.SoundEmitter:SetParameter("steps", "timeoffset", math.random())

                end),
                TimeEvent(0*FRAMES, PlayFootstep),
                TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
                TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
            }
        })
CommonStates.AddSleepStates(states,
        {
            starttimeline =
            {
                TimeEvent(11*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/yawn") end),
            },
            sleeptimeline =
            {
                TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/sleep") end),
            },
            waketimeline =
            {
                TimeEvent(22*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/ball_hit") end),
                TimeEvent(28*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pangolden/step") end),
            },
        })
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_pangolden", states, events, "idle", actionhandlers)

