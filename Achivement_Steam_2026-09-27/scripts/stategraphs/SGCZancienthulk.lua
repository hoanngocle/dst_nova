require("stategraphs/commonstates")

local BEAMRAD = 7

local actionhandlers =
{
    ActionHandler(ACTIONS.HULK_MERGE, nil),
}

local events =
{
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnAttack(),
    EventHandler("activate", function(inst) inst.sg:GoToState("activate") end),
}

local function DoFootstep(inst)
    inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/step", { intensity=math.random() })
end

local states =
{
    State {
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")

            if inst.shouldspawnbasalt then
                inst.shouldspawnbasalt = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("barrier")
                end
            elseif inst.shouldspin then
                inst.shouldspin = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("spin")
                end
            elseif inst.shouldthrow then
                inst.shouldthrow = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("launch_laser")
                end
            elseif inst.shouldteleport then
                inst.shouldteleport = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("telportout_pre")
                end
            elseif inst.shouldthrowmine then
                inst.shouldthrowmine = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("bomb_pre")
                end
            end
        end,
        timeline =
        {
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", .2) end),
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", .5) end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "activate",
        tags = {"busy"},
        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/gears_LP","gears")
        end,
        timeline =
        {
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/start") end),
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.2) end),
            TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.3) end),
            TimeEvent(50*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 0.4) end),
            TimeEvent(75*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", 1) end),
            TimeEvent(100*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", .7) end),

            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(39*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(42*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(65*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(83*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(86*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(103*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(106*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.25) end),
            TimeEvent(113*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.25) end),

            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active",nil,.5) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end),
            TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end),
            TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end),
            TimeEvent(56*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end),
            TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end),
            TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end),

            TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step") end),
            TimeEvent(101*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step") end),

            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),
            TimeEvent(64*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),
            TimeEvent(84*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),
            TimeEvent(128*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),

            TimeEvent(106*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/taunt") end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "hit",
        tags = {"hit"},
        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/hit")
            inst.AnimState:PlayAnimation("hit")
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "attack",
        tags = {"attack", "busy", "canrotate"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_chomp")
        end,
        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/dig") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/drag") end),
            TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("death_explode")
            inst.Physics:ClearCollisionMask()
        end,
        timeline =
        {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= .2}) end),
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= .3}) end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= .4}) end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= .6}) end),
            TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= .8}) end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= 1}) end),

            TimeEvent(17*FRAMES, function (inst) inst.SoundEmitter:KillSound("gears") end),

            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/death") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/taunt") end),

            TimeEvent(61*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/explode",nil,.5) end),
            TimeEvent(67*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/explode",nil,.6) end),
            TimeEvent(77*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/explode",nil,.7) end),
            TimeEvent(79*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/explode",nil,.6) end),
            TimeEvent(82*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/explode") end),

            TimeEvent(81*FRAMES, function(inst)
                local x,y,z = inst.Transform:GetWorldPosition()
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x, 0, z)
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x+1, 0, z-1)
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x-1, 0, z+1)
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x+1, 0, z)
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x, 0, z+1)
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x, 0, z-1)
                SpawnPrefab("chasni_laserscorch").Transform:SetPosition(x-1, 0, z)
                inst.DoDamage(inst, 6)
                local product = GetRandomItem({"jellybean_yellow", "jellybean_green", "jellybean_green", "jellybean_red", "jellybean_red", "jellybean_red",})
                local jellybean = SpawnPrefab(product)
                jellybean:PushEvent("on_loot_dropped", {dropper = inst})
                inst.components.lootdropper:FlingItem(jellybean)
                inst.components.lootdropper:DropLoot()
                inst.dropparts(inst)
            end),
        },
    },

    State {
        name = "telportout_pre",
        tags = {"busy"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out_pre")

        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("telportout") end),
        },
        timeline =
        {
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/teleport_out") end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.25) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.25) end),
        },
    },

    State {
        name = "telportout",
        tags = {"busy"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_out")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst:Hide()
                inst:DoTaskInTime(0.5,function() inst.teleport(inst)  end)
            end),
        },
        timeline =
        {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),

            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.15) end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.25) end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.25) end),
            TimeEvent(39*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step") end),

            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:SetParameter("gears", "intensity", .2) end),
            TimeEvent(5*FRAMES, function(inst) 
                inst.DoDamage(inst, 4)
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.Physics:SetActive(false)
                inst.DynamicShadow:Enable(false)
                inst.DoDamage(inst, 5)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.DoDamage(inst, 5)
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.DoDamage(inst, 4)
            end),
        },
    },

    State {
        name = "telportin",
        tags = {"busy"},
        onenter = function(inst)
            inst:Show()
            inst.DynamicShadow:Enable(true)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("teleport_in")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/teleport_in") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),
            TimeEvent(16*FRAMES, function(inst) TheMixer:PushMix("boom") end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound") end),
            TimeEvent(19*FRAMES, function(inst) TheMixer:PopMix("boom") end),
            TimeEvent(17*FRAMES, function(inst)
                inst.components.groundpounder:GroundPound()
            end),
        },
    },

    State {
        name = "bomb_pre",
        tags = {"busy"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("bomb") end),
        },
        timeline =
        {
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),

            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),

            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,.5) end),
        },
    },

    State {
        name = "bomb",
        tags = {"busy"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_loop")
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/mine_shot") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/mine_shot") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/mine_shot") end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/mine_shot") end),

            TimeEvent(1*FRAMES, function(inst)
                inst.LaunchMine(inst, 0)
            end),
            TimeEvent(6*FRAMES, function(inst)
                inst.LaunchMine(inst, PI*0.5)
            end),
            TimeEvent(11*FRAMES, function(inst)
                inst.LaunchMine(inst, PI)
            end),
            TimeEvent(16*FRAMES, function(inst)
                inst.LaunchMine(inst, PI*1.5)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("bomb_pst") end),
        },
    },

    State {
        name = "bomb_pst",
        tags = {"busy"},
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_bomb_pst")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

        timeline =
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/rust",nil,.5) end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/ting") end),

            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", { intensity=math.random() }) end),
        },
    },

    State {
        name = "launch_laser",
        tags = {"busy","canrotate"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk_lob")

            inst.lobtarget = nil
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst.lobtarget = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
            else
                local angle = inst.Transform:GetRotation() * DEGREES
                local offset = Vector3(15 * math.cos(angle), 0, -15 * math.sin(angle))
                local pt = Vector3(inst.Transform:GetWorldPosition())

                inst.lobtarget = Vector3(pt.x + offset.x,pt.y + offset.y,pt.z + offset.z)
            end
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
        end,
        timeline =
        {
            TimeEvent(30*FRAMES, function(inst)
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst.lobtarget = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
                end
                inst.orbs = inst.orbs -1
                if inst.orbs == 0 then
                    inst.orbcooldown = 10
                end
                inst.ShootProjectile(inst, inst.lobtarget)
            end),
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/laser_pre") end),
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity=math.random()}) end),
        },
        onupdate = function(inst)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(Vector3(inst.components.combat.target.Transform:GetWorldPosition()))
            end
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "spin",
        tags = {"busy"},
        onenter = function(inst)
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_circle")
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),
            TimeEvent(68*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),
            TimeEvent(70*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),
            TimeEvent(82*FRAMES, function(inst)inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),
            TimeEvent(90*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.5) end),

            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),
            TimeEvent(62*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),

            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end),

            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/spin") end),
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/burn_LP","laserburn") end),
            TimeEvent(49*FRAMES, function(inst) inst.SoundEmitter:KillSound("laserburn") end),

            TimeEvent(49*FRAMES, function(inst) TheMixer:PushMix("boom") end),

            TimeEvent(37*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= 0})
                inst.DoSpin(inst,BEAMRAD,0,45,5)
            end),
            TimeEvent(39*FRAMES, function(inst)
                inst.DoSpin(inst,BEAMRAD,45,90,5)
            end),
            TimeEvent(40*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= .3})
                inst.DoSpin(inst,BEAMRAD,90,135,5)
            end),
            TimeEvent(41*FRAMES, function(inst)
                inst.DoSpin(inst,BEAMRAD,135,180,5)
            end),
            TimeEvent(42*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= 0.5})
                inst.DoSpin(inst,BEAMRAD,180,225,5)
            end),
            TimeEvent(45*FRAMES, function(inst)
                inst.DoSpin(inst,BEAMRAD,225,270,5)
            end),
            TimeEvent(47*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= 0.7})
                inst.DoSpin(inst,BEAMRAD,270,315,5)
            end),
            TimeEvent(48*FRAMES, function(inst)
                inst.DoSpin(inst,BEAMRAD,315,360,5)
            end),
            TimeEvent(50*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", {intensity= 1})
                inst.DoSpin(inst,BEAMRAD,0,45,5)
            end),

            TimeEvent(51*FRAMES, function(inst) TheMixer:PopMix("boom") end),
        },
        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.spintime = 10
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    ----------------------BARRIER--------------------

    State {
        name = "barrier",
        tags = {"busy"},
        onenter = function(inst)
            inst.Transform:SetNoFaced()
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("atk_barrier")
        end,
        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step") end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/barrier") end),
            TimeEvent(67*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound") end),
            TimeEvent(67*FRAMES, function(inst) TheMixer:PushMix("boom") end),
            TimeEvent(90*FRAMES, function(inst) TheMixer:PopMix("boom") end),

            TimeEvent(64*FRAMES, function(inst)
                inst.components.groundpounder.damageRings = 4
                inst.components.groundpounder.destructionRings = 4
                inst.components.groundpounder.numRings = 4
                inst.components.groundpounder:GroundPound()
                local pt = Vector3(inst.Transform:GetWorldPosition())
                TheWorld:DoTaskInTime(0.6,function() inst.spawnbarrier(inst,pt) end)
                local fx = SpawnPrefab("chasni_metalhulk_ringfx")
                fx.Transform:SetPosition(pt.x,pt.y,pt.z)
            end),
        },
        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.barriertime = 10
            inst.components.groundpounder.damageRings = 2
            inst.components.groundpounder.destructionRings = 3
            inst.components.groundpounder.numRings = 3
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "walk_start",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            local anim = "walk_pre"
            inst.AnimState:PlayAnimation(anim)
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end),
        },
    },

    State {
        name = "walk",
        tags = {"moving", "canrotate"},
        onenter = function(inst)
            local anim = "walk_loop"
            inst.AnimState:PlayAnimation(anim)
            inst.components.locomotor:WalkForward()
            if inst.components.combat and inst.components.combat.target and math.random() < .5 then
            end
        end,
        onupdate = function(inst)
            if inst.shouldthrow then
                inst.shouldthrow = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("launch_laser")
                end
            end
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("walk") end),
        },

        timeline =
        {
            TimeEvent(12*FRAMES, function(inst)
                DoFootstep(inst)
            end),
            TimeEvent(16*FRAMES, function(inst)
                DoFootstep(inst)
            end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/step", {intensity=math.random()}) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/servo", {intensity=math.random()}) end),
        },
    },

    State {
        name = "walk_stop",
        tags = {"canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            local anim = "walk_pst"
            DoFootstep(inst)
            inst.AnimState:PlayAnimation(anim)
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "run_start",
        tags = {"moving", "running", "atk_pre", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("charge_pre")
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end),
        },
    },

    State {
        name = "run",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("charge_roar_loop")
        end,
        onupdate = function(inst)
            if inst.shouldthrow then
                inst.shouldthrow = nil
                if inst.components.combat.target then
                    inst.sg:GoToState("launch_laser")
                end
            end
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("run") end),
        },
    },

    State {
        name = "run_stop",
        tags = {"canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("charge_pst")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddFrozenStates(states)

return StateGraph("chasni_ancient_hulk", states, events, "idle", actionhandlers)