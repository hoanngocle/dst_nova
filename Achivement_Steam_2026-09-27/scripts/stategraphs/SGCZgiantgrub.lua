require("stategraphs/commonstates")

local function ShouldAttack(inst)
    return inst.components.combat and inst.components.combat.target and inst:GetDistanceSqToInst(inst.components.combat.target) < inst.components.combat:CalcHitRangeSq(inst.components.combat.target)
end

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    EventHandler("doattack",
            function(inst, data)
                if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
                    if inst.IsDigging then
                        inst.sg:GoToState("enter")
                    else
                        inst.sg:GoToState("attack", data.target)
                    end
                end
            end),
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end
        if inst.components.locomotor:WantsToMoveForward() then
            if inst.IsDigging then
                if not inst.sg:HasStateTag("moving") then
                    inst.sg:GoToState("walk_pre")
                end
            else
                inst.sg:GoToState("exit")
            end
        elseif inst.sg:HasStateTag("moving") then
            inst.sg:GoToState("walk_pst")
        else
            if inst.IsDigging then
                inst.AnimState:PlayAnimation("idle_under", true)
            elseif inst.IsDigging then
                inst.AnimState:PlayAnimation("idle", true)
            end
        end
    end),
}

local function SoundPath(inst, event, special)
    return special or "DLChasni/DLChasni/chasni_giantgrub/" .. event
end

local states =
{
    State
    {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("walkloop")
            if inst.IsDigging then
                inst.AnimState:PlayAnimation("idle_under", true)
            elseif inst.IsDigging then
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State
    {
        name = "enter",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("enter")
            inst.SoundEmitter:KillSound("walkloop")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.components.combat and inst.components.combat.target == nil then
                    inst.sg:GoToState("idle")
                elseif ShouldAttack(inst) then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("exit")
                end
            end)
        },
        timeline =
        {
            TimeEvent(16* FRAMES,function (inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "emerge"))
                inst.GoDigging(inst, false)
            end),
        },
        onexit = function(inst)
            inst.GoDigging(inst, false)
        end,
    },

    State
    {
        name = "exit",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("exit")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
        timeline =
        {

            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "jump")) end),
            TimeEvent(22 * FRAMES, function(inst)
                inst.DoGroundPound(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dontstarve_DLC001/creatures/bearger/groundpound"))
            end),
            TimeEvent(20 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound(SoundPath(inst, "submerge"))
                inst.GoDigging(inst, true)
            end),
            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "dig")) end),
            TimeEvent(39 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "dig")) end),
            TimeEvent(49 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "dig")) end),
            TimeEvent(54 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "dig")) end),
        },
    },

    State
    {
        name = "walk_pre",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
            if not inst.SoundEmitter:PlayingSound("walkloop") then
                inst.SoundEmitter:PlaySound(SoundPath(inst,"", "dontstarve/creatures/worm/move"), "walkloop")
            end
            inst.components.locomotor:WalkForward()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
        }
    },

    State
    {
        name = "walk",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
        end,
    },

    State
    {
        name = "walk_pst",
        tags = {"canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
            inst.SoundEmitter:KillSound("walkloop")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        }
    },

    State {
        name = "hit",
        tags = {"hit", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hit"))
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State
    {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("action")
        end,
        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack")) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        }
    },

    State
    {
        name = "sleep",
        tags = {"busy", "sleeping"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if inst.IsDigging then
                inst.AnimState:PlayAnimation("enter")
                inst.SoundEmitter:PlaySound(SoundPath(inst, "emerge"))
                inst.AnimState:PushAnimation("sleep_pre", false)
            else
                inst.AnimState:PlayAnimation("sleep_pre")
            end
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("sleeping") end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
    },

    State
    {
        name = "sleeping",
        tags = {"busy", "sleeping"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_loop")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },
        timeline =
        {

            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "sleepin")) end),
            TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "sleepout")) end),
        },
    },

    State
    {
        name = "wake",
        tags = {"busy", "waking"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State
    {
        name = "death",
        tags = {"busy", "stunned"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            RemovePhysicsColliders(inst)
        end,
        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "death")) end),
        }
    },
}
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_giantgrub", states, events, "idle")
