require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnHop(),
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(false,true),
}

local function SoundPath(inst, event, special)
    return special or "dontstarve/beefalo/" .. event
end

local function SpawnSnare(inst, target)
    local x, _, z = target.Transform:GetWorldPosition()
    local islarge = target:HasTag("largecreature")
    local r = target:GetPhysicsRadius(0) + (islarge and 1.4 or .4)
    local num = islarge and 12 or 6
    
    local count = 0
    local dtheta = PI * 2 / num
    local delaytoggle = 0
    local map = TheWorld.Map
    for theta = math.random() * dtheta, PI * 2, dtheta do
        local x1 = x + r * math.cos(theta)
        local z1 = z + r * math.sin(theta)
        if map:IsPassableAtPoint(x1, 0, z1, false, true) and not map:IsPointNearHole(Vector3(x1, 0, z1)) then
            local snare = SpawnPrefab("ivy_snare")
            if snare and snare.components.health then
                snare.components.health:SetMaxHealth(250)
                snare.components.health:SetPercent(1)
            end
            snare.Transform:SetPosition(x1, 0, z1)

            local delay = delaytoggle == 0 and 0 or .2 + delaytoggle * math.random() * .2
            delaytoggle = delaytoggle == 1 and -1 or 1

            snare.owner = inst
            snare.target = target
            snare.target_max_dist = r + 1.0
            snare:RestartSnare(delay)

            count = count + 1
        end
    end

    return count > 0
end

local function SpawnSnares(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    local ents = FindPlayersInRange(x, 0, z, 15, true)
    for k,v in pairs(ents) do
        if v.prefab ~= "wormwood" then
            SpawnSnare(inst, v)
        end
    end
end

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
            inst.sg:SetTimeout(2 + 2 * math.random())
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dontstarve/creatures/spat/death"))
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
            inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dangerous_sea/creatures/water_plant/hit"))
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,
        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "taunt",
        tags = { "busy", "taunting" },
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "", "dangerous_sea/creatures/water_plant/death"))
            inst.sg.statemem.count = data and data.count or nil
        end,
        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.count == nil then
                    SpawnSnares(inst)
                end
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
}

CommonStates.AddWalkStates(states,
        {
            walktimeline =
            {
                TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
                TimeEvent(40 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
            }
        })
CommonStates.AddRunStates(states,
        {
            runtimeline =
            {
                TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
            }
        })
CommonStates.AddSimpleState(states,"hit", "hit")
CommonStates.AddFrozenStates(states)
CommonStates.AddHopStates(states, true, { pre = "walk_pre", loop = "idle", pst = "walk_pst"})
CommonStates.AddSleepStates(states,
        {
            sleeptimeline =
            {
                TimeEvent(46 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "grunt")) end)
            },
        })

return StateGraph("chasni_snapdragon", states, events, "idle")
