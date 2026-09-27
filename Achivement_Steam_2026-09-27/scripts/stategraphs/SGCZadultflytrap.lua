require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PushAnimation("idle")
        end,
        timeline =
        {
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/breath_out") end),
            TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/breath_in") end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State {
        name = "taunt",
        tags = {"taunting"},
        onenter = function(inst, spawning)
            inst.AnimState:PlayAnimation("taunt")
            if spawning and inst.components.combat.target then
                inst:DoTaskInTime(10*FRAMES, function(_inst) _inst:SpawnVine(0.5) end)
                inst:DoTaskInTime(15*FRAMES, function(_inst) _inst:SpawnVine(2.5) end)
                inst:DoTaskInTime(20*FRAMES, function(_inst) _inst:SpawnVine(4) end)
            end
        end,
        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/taunt") end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.components.combat.target then
                    inst.sg:GoToState("attack")
                elseif inst.components.combat.target == nil then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.AnimState:PushAnimation("atk_pst", false)
        end,
        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/taunt") end),
            TimeEvent(14*FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/attack")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/bite")
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/bite2")
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                local target = inst.components.combat.target
                if target and target:GetDistanceSqToInst(inst) > 6 then
                    inst.sg:GoToState("taunt", true)
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/death_pre",nil,.5) end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/death") end),
        },
    },

    State {
        name = "hit",
        tags = {"busy", "hit"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_flytrap/breath_out")
        end,
        events =
        {
            EventHandler("animover", function(inst) 
                local target = inst.components.combat.target
                if target and target:GetDistanceSqToInst(inst) < 3 * 3 then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
}
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_adultflytrap", states, events, "idle")
