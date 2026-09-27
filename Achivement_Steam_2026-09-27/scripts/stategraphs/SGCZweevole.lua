require("stategraphs/commonstates")

local WEEVOLE_MELEE_RANGE = 2.5
local events =
{
    CommonHandlers.OnFreeze(),
    EventHandler("entershield", function(inst)
        inst.sg:GoToState("burrow_sheild")
    end),
    EventHandler("exitshield", function(inst)
        inst.sg:GoToState("emerge")
    end),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            if not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("shielding") then
                inst.sg:GoToState("hit") -- can still attack
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState(
                    data.target:IsValid() and not inst:IsNear(data.target, WEEVOLE_MELEE_RANGE) and "leap_attack"
                            or "attack",
                    data.target
            )
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                inst.sg:GoToState(wants_to_move and "premoving" or "idle")
            end
        end
    end),
}

local states =
{
    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/death", nil, 0.7)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "premoving",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State {
        name = "moving",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,
        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/walk",nil, 0.8) end),
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/walk",nil, 0.8) end),
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/walk",nil, 0.8) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/idle") end),
        },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < 0.01 then
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },


    State {
        name = "burrow_sheild",
        tags = {"busy","shielding"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("burrow")
        end,
        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
                inst.sg:AddStateTag("invisible")
                if inst.components.burnable:IsBurning() then
                    inst.components.burnable:Extinguish()
                end
            end),
        },
    },

    State {
        name = "emerge",
        tags = {"busy", "invisible"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/burrow", "move", 0.8)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/dig", "move2",  0.8)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("unburrow")
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(.9, .2))

            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,
        onexit = function(inst)
            inst.SoundEmitter:KillSound("move")
            inst.SoundEmitter:KillSound("move2")
            inst.AnimState:SetDeltaTimeMultiplier(1)
            inst.DynamicShadow:Enable(true)
        end,
        timeline =
        {
            TimeEvent(0, function(inst)
                if inst.components.combat and inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),
            TimeEvent(32 * FRAMES, function(inst) inst.DynamicShadow:Enable(true) end),
        },

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
            inst.AnimState:PlayAnimation("taunt")
            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,
        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/taunt", nil, 0.8) end),
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
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("attack")
            inst.sg.statemem.target = target
        end,
        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/hit", nil, 0.8) end),
            TimeEvent(9 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "leap_attack",
        tags = {"attack", "canrotate", "busy", "jumping"},
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("leap_attack")
            inst.sg.statemem.target = target

            if target and target:IsValid() then
                inst:ForceFacePoint(target:GetPosition())
            end
        end,
        onexit = function(inst)
            inst.SoundEmitter:KillSound("buzz")
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
        end,
        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/fly_LP", "buzz", 0.7)
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("buzz")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/idle", nil, 0.8)
            end),

            TimeEvent(11 * FRAMES, function(inst)
                inst.Physics:SetMotorVelOverride(20,0,0)
            end),
            TimeEvent(18 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
            TimeEvent(19 * FRAMES, function(inst)
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
            end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State {
        name = "hit",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_weevole/hit", nil, 0.9)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_weevole", states, events, "emerge")
