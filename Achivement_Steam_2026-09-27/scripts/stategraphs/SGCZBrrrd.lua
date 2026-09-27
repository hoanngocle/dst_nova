require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "flyaway"),
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true),

    EventHandler("flyaway", function(inst)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("flyaway")
        end
    end),
}

local function SoundPath(inst, event, special)
    return special or "saltydog/creatures/boss/malbatross/" .. event
end

local function SummerSkill(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("orangefx_ring", x, y, z)
    inst:DoTaskInTime(0.2, function(inst)
        local ents = TheSim:FindEntities(x, 0, z, 12, nil, chasni_TAG_NOATTACK)
        for _, target in pairs(ents) do
            if target and target ~= inst and target.components.burnable and not target:HasTag("burnt") then
                target.components.burnable:Ignite(true, inst)
                if inst.components.combat and target.components.health and not target.components.health:IsDead() and target.components.combat then
                    local dmg, spdmg = inst.components.combat:CalcDamage(target)
                    local noimpactsound = target.components.combat.noimpactsound
                    target.components.combat.noimpactsound = true
                    target.components.combat:GetAttacked(inst, dmg, nil, nil, spdmg)
                    target.components.combat.noimpactsound = noimpactsound
                end
            end
        end
    end)
end
local function WinterSkill(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("bluefx_ring", x, y, z)
    inst:DoTaskInTime(0.2, function(inst)
        local ents = TheSim:FindEntities(x, 0, z, 12, nil, chasni_TAG_NOATTACK)
        for _, target in pairs(ents) do
            if target and target ~= inst and target.components.freezable then
                target.components.freezable:AddColdness(100, 25)
            end
        end
    end)
end
local function DoSkill(inst)
    if inst.Type == "summer" then
        SummerSkill(inst)
    else
        WinterSkill(inst)
    end
end
local function LayEgg(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("chasni_robin_egg", x, y, z)
end

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, data)
            inst.components.locomotor:StopMoving()
            if data and data.softstop then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "death"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State {
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_call"))
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
        end,
        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "beak"))
            end)
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "hit",
        tags = {"busy", "hit"},
        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hit"))
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "taunt",
        tags = { "busy", "taunting" },
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_call"))
            inst.sg.statemem.count = data and data.count or nil
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.count and inst.sg.statemem.count > 1 then
                    inst.sg:GoToState("taunt", {count=inst.sg.statemem.count - 1})
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "peck",
        tags = { "busy" },
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("peck")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hit"))
            inst.sg.statemem.count = data and data.count or nil
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.count and inst.sg.statemem.count > 1 then
                    inst.sg:GoToState("taunt", {count=inst.sg.statemem.count - 1})
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "skill",
        tags = { "busy" },
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pure_embarrassment")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_call"))
            inst.sg.statemem.count = data and data.count or nil
        end,
        timeline =
        {
            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_call")) end),
            TimeEvent(32 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_call")) end),
            TimeEvent(32 * FRAMES, function(inst)
                DoSkill(inst)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.count and inst.sg.statemem.count > 1 then
                    inst.sg:GoToState("taunt", {count=inst.sg.statemem.count - 1})
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "nest",
        tags = { "busy" },
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("nest")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_call"))
        end,
        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst)
                LayEgg(inst)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "glide",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("glide", true)
            inst.Physics:SetMotorVelOverride(0,-4.5,0)
            inst.flapSound = inst:DoPeriodicTask(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dontstarve_DLC001/creatures/moose/flap")) end)
        end,
        onupdate = function(inst)
            inst.Physics:SetMotorVelOverride(0,-6.1,0)
            local pt = Point(inst.Transform:GetWorldPosition())
            if pt.y < 2 or inst:IsAsleep() then
                inst.Physics:ClearMotorVelOverride()
                pt.y = 0
                inst.Physics:Stop()
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
                inst.AnimState:PlayAnimation("land")
                inst.DynamicShadow:Enable(true)
                inst.sg:GoToState("idle", {softstop = true})
            end
        end,
        onexit = function(inst)
            if inst.flapSound then
                inst.flapSound:Cancel()
                inst.flapSound = nil
            end
            if inst:GetPosition().y > 0 then
                local pos = inst:GetPosition()
                pos.y = 0
                inst.Transform:SetPosition(pos:Get())
            end
        end,
    },

    State {
        name = "flyaway",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.DynamicShadow:Enable(false)
            inst.AnimState:PlayAnimation("takeoff_pre_vertical")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dontstarve_DLC001/creatures/moose/flap"))
            inst.sg.statemem.flapSound = 9 * FRAMES
        end,
        onupdate = function(inst, dt)
            inst.sg.statemem.flapSound = inst.sg.statemem.flapSound - dt
            if inst.sg.statemem.flapSound <= 0 then
                inst.sg.statemem.flapSound = 6 * FRAMES
                inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dontstarve_DLC001/creatures/moose/flap"))
            end
        end,
        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                inst.AnimState:PushAnimation("takeoff_vertical", true)
                inst.Physics:SetMotorVel(math.random()*4,7+math.random()*2,math.random()*4)
                inst.DoDung(inst)
            end),
            TimeEvent(10, function(inst) inst:Remove() end)
        }
    },
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states,
        {
            runtimeline =
            {
                TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "hit")) end),
                TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "hit")) end),
            }
        })
CommonStates.AddFrozenStates(states)
CommonStates.AddHopStates(states, true, { pre = "walk_pre", loop = "idle", pst = "walk_pst"})
CommonStates.AddSleepStates(states,
        {
            sleeptimeline =
            {
                TimeEvent(46 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "", "turnoftides/creatures/together/fruit_dragon/sleep")) end)
            },
        })

return StateGraph("chasni_brrrd", states, events, "idle", actionhandlers)
