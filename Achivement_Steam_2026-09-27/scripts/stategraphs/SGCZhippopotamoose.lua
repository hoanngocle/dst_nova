require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnStep(),
    CommonHandlers.OnHop(),
    EventHandler("doattack", function(inst)
        if inst.components.health and not inst.components.health:IsDead()
                and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("gore")
        end
    end),
    EventHandler("doleapattack", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("leap_attack_pre", data.target)
        end
    end),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("charge")
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
        timeline =
        {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/out", nil, 0.8) end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/in", nil, 0.8) end),
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/out", nil, 0.8) end),
            TimeEvent(57*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/in", nil, 0.8) end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if math.random()<0.05 and inst:HasTag("huff_idle") then
                    inst.sg:GoToState("huff")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "gore",
        tags = {"attack", "busy"},
        onenter = function(inst, target)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,
        timeline =
        {
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/leap_attack", nil, 0.8) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "leap_attack_pre",
        tags = {"attack", "canrotate", "busy","leapattack"},
        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_atk_pre")
            inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
            inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack",{startpos = inst.sg.statemem.startpos, targetpos = inst.sg.statemem.targetpos}) end),
        },
    },

    State {
        name = "leap_attack",
        tags = {"attack", "canrotate", "busy", "leapattack"},
        onenter = function(inst, data)
            inst.sg.statemem.startpos = data.startpos
            inst.sg.statemem.targetpos = data.targetpos
            inst.components.locomotor:Stop()
            inst.Physics:SetActive(false)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("jump_atk_loop")
        end,
        onupdate = function(inst)
            local percent = inst.AnimState:GetCurrentAnimationTime () / inst.AnimState:GetCurrentAnimationLength()
            local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
            local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z
            inst.Transform:SetPosition(inst.sg.statemem.startpos.x + (xdiff * percent),0,inst.sg.statemem.startpos.z + (zdiff * percent))
        end,
        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.sg.statemem.startpos = nil
            inst.sg.statemem.targetpos = nil
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/leap_attack", nil, 0.8) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack_pst") end),
        },
    },

    State {
        name = "leap_attack_pst",
        tags = {"busy"},
        onenter = function(inst)
            local map = TheWorld.Map
            local x, y, z = inst.Transform:GetWorldPosition()
            local ground = map:GetTile(map:GetTileCoordsAtPoint(x, y, z))
            if ground ~= GROUND.OCEAN_COASTAL and
                    ground ~= GROUND.OCEAN_COASTAL_SHORE and
                    ground ~= GROUND.OCEAN_SWELL and
                    ground ~= GROUND.OCEAN_ROUGH and
                    ground ~= GROUND.OCEAN_BRINEPOOL and
                    ground ~= GROUND.OCEAN_BRINEPOOL_SHORE and
                    ground ~= GROUND.OCEAN_WATERLOG and
                    ground ~= GROUND.OCEAN_HAZARDOUS then

                inst.components.groundpounder:GroundPound()
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound",nil,.5)
            else
                SpawnAttackWaves(inst:GetPosition(), nil, (inst.Physics and inst.Physics:GetRadius()) or nil, 6, 360, 4, nil, 2, nil)
                inst.components.groundpounder:GroundPound()
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_atk_pst")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State {
        name = "huff",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("charge")

            inst.AnimState:PlayAnimation("idle_huff")
        end,
        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/huff_in", nil, 0.7) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/huff_out", nil, 0.7) end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if math.random()<0.1 then
                    inst.sg:GoToState("huff")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "taunt",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,
        timeline =
        {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/taunt", nil, 0.8) end),
            TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/attack", nil, 0.8) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states,
        {
            starttimeline = { TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end), },
            walktimeline = {
                TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end),
                TimeEvent(7*FRAMES, function(inst) inst.components.locomotor:WalkForward() end),
                TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/in", nil, 0.8) end),
                TimeEvent(19*FRAMES, function(inst)
                    if not inst.onwater then
                        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/walk", nil, 0.8)
                    end
                end),
                TimeEvent(20*FRAMES, function(inst)
                    if not inst.onwater then
                        TheCamera:Shake("VERTICAL", 0.3, 0.05, 0.05)
                    end
                    inst.Physics:Stop()
                end),
            },
        }, nil,true)
CommonStates.AddRunStates(states,
        {
            starttimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end),
            },
            runtimeline = {
                TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end),
                TimeEvent(7*FRAMES, function(inst) inst.components.locomotor:WalkForward() end),
                TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/in", nil, 0.8) end),
                TimeEvent(19*FRAMES, function(inst) if not inst.onwater then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/walk", nil, 0.8) end end),
                TimeEvent(20*FRAMES, function(inst)
                    if not inst.onwater then
                        TheCamera:Shake("VERTICAL", 0.3, 0.05, 0.05)
                    end
                    inst.Physics:Stop()
                end),
            },
        }, {startrun="walk_pre",run="walk_loop",stoprun="walk_pst"}, true)
CommonStates.AddSleepStates(states,
        {
            sleeptimeline = {
                TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/huff_in", nil, 0.7) end),
            },
        })
CommonStates.AddCombatStates(states,
        {
            attacktimeline =
            {
                TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/attack", nil, 0.8) end),
                TimeEvent(17*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            },
            hittimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/hit", nil, 0.8) end),
            },
            deathtimeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hippo/death", nil, 0.8) end),
            },
        })
CommonStates.AddAmphibiousCreatureHopStates(states,
        {
            swimming_clear_collision_frame = 9 * FRAMES,
        },
        {
            pre = "walk_pre",
            loop = "walk_loop",
            pst = "walk_pst",
        },
        {
            hop_pre =
            {
                TimeEvent(0, function(inst)
                    if inst:HasTag("swimming") then
                        SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                end),
            },
            hop_pst = {
                TimeEvent(4 * FRAMES, function(inst)
                    if inst:HasTag("swimming") then
                        inst.components.locomotor:Stop()
                        SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                end),
                TimeEvent(6 * FRAMES, function(inst)
                    if not inst:HasTag("swimming") then
                        inst.components.locomotor:StopMoving()
                    end
                end),
            }
        })
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_hippopotamoose", states, events, "idle")