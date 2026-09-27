require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.HULK_MERGE, nil),
}

local function DoDamage(inst, rad)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, chasni_TAG_NOTARGET)) do
        if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health and v.components.health:IsDead()) and not v:HasTag("laser_immune") then
            local vradius = 0
            if v.Physics then
                vradius = v.Physics:GetRadius()
            end

            local range = rad + vradius
            if v:IsValid() and v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range and v.components.health and v.components.health:IsDead() then
                inst.components.combat:DoAttack(v)
                if v.AnimState then
                    SpawnPrefab("chasni_laserhit"):SetTarget(v)
                end
            end
        end
    end
end

local function UpdateHit(inst)
    if inst:IsValid() then
        local oldflash = inst.flash
        inst.flash = math.max(0, inst.flash - .075)
        if inst.flash > 0 then
            local c = math.min(1, inst.flash)
            if inst.components.colouradder then
                inst.components.colouradder:PushColour(inst, c, 0, 0, 0)
            else
                inst.AnimState:SetAddColour(c, 0, 0, 0)
            end
            if inst.flash < .3 and oldflash >= .3 then
                if inst.components.bloomer then
                    inst.components.bloomer:PopBloom(inst)
                else
                    inst.AnimState:ClearBloomEffectHandle()
                end
            end
        else
            inst.flashtask:Cancel()
            inst.flashtask = nil
        end
    end
end

local function powerglow(inst)
    if inst.components.bloomer then
        inst.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
    else
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    inst.flash = 1.7
    inst.flashtask = inst:DoPeriodicTask(0, UpdateHit, nil, inst)
end

local function SpawnLaser(inst)
    local numsteps = 10
    local xt = inst.sg.statemem.targetpos.x
    local yt = inst.sg.statemem.targetpos.y
    local zt = inst.sg.statemem.targetpos.z
    local dist =  math.sqrt(inst:GetDistanceSqToPoint(Vector3(xt, yt, zt))) -3
    local angle = (inst:GetAngleToPoint(xt, yt, zt) +90)* DEGREES

    local targets, skiptoss = {}, {}
    local noground = false
    local fx, delay, x1, z1
    local i = -1
    while i < numsteps do
        i = i + 1
        dist = dist + .75
        delay = math.max(0, i - 1)
        local x, _, z = inst.Transform:GetWorldPosition()
        x1 = x + dist * math.sin(angle)
        z1 = z + dist * math.cos(angle)
        local tile = TheWorld.Map:GetTileAtPoint(x1, 0, z1)

        if tile == 255 or tile < 2 then
            if i <= 0 then return end
            noground = true
        end
        fx = SpawnPrefab(i > 0 and "chasni_laser" or "chasni_laserempty")
        fx.caster = inst
        fx.Transform:SetPosition(x1, 0, z1)
        fx:Trigger(delay * FRAMES, targets, skiptoss)
        if noground then
            break
        end
    end

    local function delay_spawn(delay_offset)
        fx = SpawnPrefab("chasni_laser")
        fx.Transform:SetPosition(x1, 0, z1)
        fx:Trigger((delay + delay_offset) * FRAMES, targets, skiptoss)
    end

    delay_spawn(1)
    delay_spawn(2)
end

local function SetLightValue(inst, val, override)
    if inst.Light then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
        if override then
            inst.AnimState:SetLightOverride(override)
        end
    end
end

local function SetLightColour(inst, val)
    if inst.Light then
        inst.Light:SetColour(val, 0, 0)
    end
end

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("dobeamattack", function(inst, data)
        if not inst.sg:HasStateTag("activating") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("laserbeam", data.target)
        end
    end),
    EventHandler("doleapattack", function(inst,data)
        if not inst.sg:HasStateTag("activating") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("leap_attack_pre", data.target)
        end
    end),
    CommonHandlers.OnDeath(),
    EventHandler("mined", function(inst)
        inst.removemoss(inst)
        if inst:HasTag("dormant") then
            if math.random() < 0.6 then
                inst:turnon()
            end
        end
        if inst:HasTag("dormant") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("hit_dormant")
        end
    end),
    EventHandler("shock", function(inst)
        inst:RemoveTag("dormant")
        inst.setblocker(inst, false)
        inst.sg:GoToState("shock")
    end),
    EventHandler("activate", function(inst)
        inst:RemoveTag("dormant")
        inst.setblocker(inst, false)
        inst.sg:GoToState("activate")
    end),
    EventHandler("deactivate", function(inst)
        inst.components.combat.target = nil
        inst._wanttodeactivate = false
        inst.setblocker(inst, true)
        inst:AddTag("dormant")
        inst.sg:GoToState("deactivate")
    end),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
            inst.sg:SetTimeout(2 + 2*math.random())
            inst.Light:Enable(false)
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("taunt")
        end,
    },

    State {
        name = "idle_dormant",
        tags = {"idle","dormant"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:SetParameter("gears", "intensity", 1)
            inst.SoundEmitter:KillSound("gears")
            inst.Light:Enable(false)
            if inst:HasTag("mossy") then
                inst.AnimState:PlayAnimation("mossy_full")
            else
                inst.AnimState:PlayAnimation("full")
            end
        end,
        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_leg") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(27*FRAMES, function(inst) if inst:HasTag("hulk_leg") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo_small",nil,0.5) end end),
            TimeEvent(31*FRAMES, function(inst) if inst:HasTag("hulk_leg") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo_small",nil,0.5) end end),
            TimeEvent(45*FRAMES, function(inst) if inst:HasTag("hulk_leg") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo",nil,0.6) end end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst.Light:Enable(false)
                inst.sg:GoToState("idle_dormant")
            end),
        },

    },

    State {
        name = "fall",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0,-35,0)
            inst.AnimState:PlayAnimation("idle_fall", true)
        end,
        onupdate = function(inst)
            local pt = Point(inst.Transform:GetWorldPosition())
            if pt.y < 2 then
                inst.Physics:SetMotorVel(0,0,0)
            end
            if pt.y <= 0.1 then
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/explode_small",nil,.25)
                inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/step")
                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(pt.x,0,pt.z)
                inst._dead = true
                inst.sg:GoToState("separate")    
            end
        end,
        onexit = function(inst)
            local pt = inst:GetPosition()
            pt.y = 0
            inst.Transform:SetPosition(pt:Get())
        end,
    },

    State {
        name = "separate",
        tags = {"busy","dormant"},
        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("separate")
        end,
        events =
        {
            EventHandler("animover", function(inst) if not inst._dead then inst:turnon() end inst._dead = nil end),
        },
    },

    State {
        name = "hit_dormant",
        tags = {"busy", "dormant"},
        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("dormant_hit")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },
    },

    State {
        name = "shock",
        tags = {"busy","activating"},
        onenter = function(inst, pushanim)
            inst.removemoss(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shock")
        end,
        timeline =
        {
            TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(13*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(10*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(10*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(2*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(5*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(7*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro",nil,0.5) end end),
            TimeEvent(10*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("activate") end),
        },
    },

    State {
        name = "activate",
        tags = {"busy", "activating"},
        onenter = function(inst)
            inst.removemoss(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/gears_LP","gears")
            inst.SoundEmitter:SetParameter("gears", "intensity", .5)
            inst:AddTag("hostile")
        end,
        timeline =
        {
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/start") end end),
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(4*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(8*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(16*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/active") end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(37*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(41*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(50*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(51*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(53*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(62*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(70*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/start") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(1*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(5*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(16*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/active") end end),
            TimeEvent(17*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(27*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(37*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(40*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(54*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(57*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/start") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end end),
            TimeEvent(4*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end end),
            TimeEvent(5*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end end),
            TimeEvent(13*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/active") end end),
            TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(17*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(27*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(44*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(58*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.06) end end),
            TimeEvent(2*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/start") end end),
            TimeEvent(2*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(4*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(8*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(10*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(13*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(16*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/active") end end),
            TimeEvent(18*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(21*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(33*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(36*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
            TimeEvent(39*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/electro") end end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State {
        name = "deactivate",
        tags = {"busy", "deactivating"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("deactivate")
            if inst:HasTag("hulk_claw") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/stop") end
            if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/stop") end
            if inst:HasTag("hulk_leg") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/stop") end
            if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/stop") end
            inst:RemoveTag("hostile")
        end,
        timeline =
        {
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/green") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/green") end end),
            TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/green") end end),
            TimeEvent(21*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/green") end end),
            TimeEvent(38*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/green") end end),
            TimeEvent(36*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(5*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/green") end end),
            TimeEvent(13*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/green") end end),
            TimeEvent(19*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/green") end end),
            TimeEvent(23*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/green") end end),
            TimeEvent(38*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/green") end end),
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/green") end end),
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/green") end end),
            TimeEvent(16*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/green") end end),
            TimeEvent(23*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/green") end end),
            TimeEvent(31*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/green") end end),
            TimeEvent(43*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/green") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/green") end end),
            TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/green") end end),
            TimeEvent(21*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/green") end end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },
    },

    State {
        name = "taunt",
        tags = {"busy","canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        timeline =
        {
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(7*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(15*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/taunt") end end),
            TimeEvent(29*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(33*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(4*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/servo") end end),
            TimeEvent(17*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/servo") end end),
            TimeEvent(21*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/taunt") end end),
            TimeEvent(45*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/servo") end end),
            TimeEvent(5*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(15*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(42*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            TimeEvent(2*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/taunt") end end),
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_head/step", { intensity = .05 }) end end),
            TimeEvent(17*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            TimeEvent(19*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/taunt") end end),
            TimeEvent(24*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_head/step", { intensity = .08 }) end end),
            TimeEvent(32*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            --------------------------------------------------
            TimeEvent(23 * FRAMES, function(inst)
                if inst:HasTag("hulk_leg") then
                    local pos = Vector3(inst.Transform:GetWorldPosition())
                    SpawnPrefab("lightning").Transform:SetPosition(pos:Get())
                end
            end),
        },
    },

    State {
        name = "laserbeam",
        tags = { "busy","attack" },
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
            if inst:HasTag("hulk_spider") then
                inst.Transform:SetEightFaced()
            end
            if target and target:IsValid() then
                if inst.components.combat:TargetIs(target) then
                    inst.components.combat:StartAttack()
                end
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
            end
            inst.components.timer:StopTimer("laserbeam_cd")
            inst.components.timer:StartTimer("laserbeam_cd", TUNING.DEERCLOPS_ATTACK_PERIOD * (math.random(3) - .5))
        end,
        onupdate = function(inst)
            if inst.sg.statemem.target then
                if inst.sg.statemem.target:IsValid() then
                    local x, _, z = inst.Transform:GetWorldPosition()
                    local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
                    local dx, dz = x1 - x, z1 - z
                    if dx * dx + dz * dz < 256 and math.abs(anglediff(inst.Transform:GetRotation(), math.atan2(-dz, dx) / DEGREES)) < 45 then
                        inst:ForceFacePoint(x1, y1, z1)
                        return
                    end
                end
                inst.sg.statemem.target = nil
            end
            if inst.sg.statemem.lightval then
                inst.sg.statemem.lightval = inst.sg.statemem.lightval * .99
                SetLightValue(inst, inst.sg.statemem.lightval, (inst.sg.statemem.lightval - 1) * 3)
            end
        end,
        timeline =
        {
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(7*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/laser_pre") end end),
            TimeEvent(19*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .12 }) end end),
            TimeEvent(32*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .24 }) end end),
            TimeEvent(34*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .48 }) end end),
            TimeEvent(36*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .60 }) end end),
            TimeEvent(38*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .72 }) end end),
            TimeEvent(40*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .84 }) end end),
            TimeEvent(42*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .96 }) end end),
            TimeEvent(44*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = 1 }) end end),
            TimeEvent(47*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/step") end end),
            TimeEvent(4*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/servo") end end),
            TimeEvent(4*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/servo") end end),
            TimeEvent(2*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/laser_pre") end end),
            TimeEvent(19*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_rib/servo") end end),
            TimeEvent(22*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .12 }) end end),
            TimeEvent(24*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .24 }) end end),
            TimeEvent(26*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .48 }) end end),
            TimeEvent(28*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .60 }) end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .72 }) end end),
            TimeEvent(32*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .84 }) end end),
            TimeEvent(34*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = .96 }) end end),
            TimeEvent(36*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_hulk/laser", { intensity = 1 }) end end),

            TimeEvent(6 *  FRAMES, function(inst) SetLightValue(inst, .97) end),
            TimeEvent(7 *  FRAMES, function(inst) inst.Light:Enable(true) end),
            TimeEvent(8 *  FRAMES, function(inst) SetLightValue(inst, 0.05, .2) end),
            TimeEvent(9 *  FRAMES, function(inst) SetLightValue(inst, 0.1, .15) end),
            TimeEvent(10 * FRAMES, function(inst) SetLightValue(inst, 0.15, .05) end),
            TimeEvent(11 * FRAMES, function(inst) SetLightValue(inst, 0.20, 0) end),
            TimeEvent(12 * FRAMES, function(inst) SetLightValue(inst, 0.25, .35) end),
            TimeEvent(13 * FRAMES, function(inst) SetLightValue(inst, 0.30, .3) end),
            TimeEvent(14 * FRAMES, function(inst) SetLightValue(inst, 0.35, .05) end),
            TimeEvent(15 * FRAMES, function(inst) SetLightValue(inst, 0.40, 0) end),
            TimeEvent(16 * FRAMES, function(inst) SetLightValue(inst, 0.45, .3) end),
            TimeEvent(17 * FRAMES, function(inst) SetLightValue(inst, 0.50, .15) end),
            TimeEvent(18 * FRAMES, function(inst) SetLightValue(inst, 0.55, .05) end),
            TimeEvent(19 * FRAMES, function(inst) SetLightValue(inst, 0.60, 0) end),
            TimeEvent(20 * FRAMES, function(inst) SetLightValue(inst, 0.65, .35) end),
            TimeEvent(21 * FRAMES, function(inst) SetLightValue(inst, 0.70, .3) end),
            TimeEvent(22 * FRAMES, function(inst) SetLightValue(inst, 0.75, .05) end),
            TimeEvent(23 * FRAMES, function(inst) SetLightValue(inst, 0.80, 0) end),
            TimeEvent(24 * FRAMES, function(inst) SetLightValue(inst, 0.85, .3) end),
            TimeEvent(25 * FRAMES, function(inst) SetLightValue(inst, 0.90, .15) end),
            TimeEvent(26 * FRAMES, function(inst) SetLightValue(inst, 0.95, .05) end),
            TimeEvent(27 * FRAMES, function(inst) SetLightValue(inst, 1, 0) end),
            TimeEvent(28 * FRAMES, function(inst) SetLightValue(inst, 1.01, .35) end),
            TimeEvent(29 * FRAMES, function(inst) SetLightValue(inst, .9, 0) end),
            TimeEvent(30 * FRAMES, function(inst)
                SpawnLaser(inst)
                inst.sg.statemem.target = nil
                SetLightValue(inst, 1.08, .7)
            end),
            TimeEvent(31 * FRAMES, function(inst) SetLightValue(inst, 1.12, 1) end),
            TimeEvent(32 * FRAMES, function(inst) SetLightValue(inst, 1.1, .9) end),
            TimeEvent(33 * FRAMES, function(inst) SetLightValue(inst, 1.06, .4) end),
            TimeEvent(34 * FRAMES, function(inst) SetLightValue(inst, 1.1, .6) end),
            TimeEvent(35 * FRAMES, function(inst) inst.sg.statemem.lightval = 1.1 end),
            TimeEvent(36 * FRAMES, function(inst)
                inst.sg.statemem.lightval = 1.035
                SetLightColour(inst, .9)
            end),
            TimeEvent(37 * FRAMES, function(inst)
                inst.sg.statemem.lightval = nil
                SetLightValue(inst, .9, 0)
                SetLightColour(inst, .9)
            end),
            TimeEvent(38 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                SetLightValue(inst, 1)
                SetLightColour(inst, 1)
                inst.Light:Enable(false)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        onexit = function(inst)
            inst:SetFace()
            SetLightValue(inst, 1, 0)
            SetLightColour(inst, 1)
        end,
    },

    State {
        name = "leap_attack_pre",
        tags = {"attack", "canrotate", "busy", "leapattack"},
        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
            inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
        end,
        timeline =
        {
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(7*FRAMES,  function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            TimeEvent(9*FRAMES,  function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            TimeEvent(11*FRAMES, function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
        },
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
            inst.components.locomotor:StopMoving()
            inst.Physics:SetActive(false)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_loop")
        end,
        timeline =
        {
            TimeEvent(18*FRAMES, function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/attack") end end),
            TimeEvent(25*FRAMES, function(inst) powerglow(inst) end),
        },
        onupdate = function(inst)
            local percent = inst.AnimState:GetCurrentAnimationTime () / inst.AnimState:GetCurrentAnimationLength() -- substitui o inst.AnimState:GetPercent()
            local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
            local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z
            inst.Transform:SetPosition(inst.sg.statemem.startpos.x+(xdiff*percent), 0, inst.sg.statemem.startpos.z+(zdiff*percent))
        end,
        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.components.locomotor:StopMoving()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.sg.statemem.startpos = nil
            inst.sg.statemem.targetpos = nil
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack_pst") end),
        },
    },

    State {

        name = "leap_attack_pst",
        tags = {"busy"},
        onenter = function(inst, target)
            local ring = SpawnPrefab("chasni_laserring")
            ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_pst")
        end,
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)DoDamage(inst, 1.5) end),
            TimeEvent(10*FRAMES, function(inst)DoDamage(inst, 2.5) end),
            TimeEvent(15*FRAMES, function(inst)DoDamage(inst, 3.3) end),
            TimeEvent(2*FRAMES,  function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/smash") end end),
            TimeEvent(12*FRAMES, function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(18*FRAMES, function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(28*FRAMES, function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/step",nil,.06) end end),
            TimeEvent(30*FRAMES, function(inst) if inst:HasTag("hulk_leg")  then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo") end end),
            TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_hulk/smash") end end),
            TimeEvent(13*FRAMES, function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/servo") end end),
            TimeEvent(17*FRAMES, function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_head/step") end end),
            TimeEvent(31*FRAMES, function(inst) if inst:HasTag("hulk_head") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_head/step", { intensity = .08 }) end end),
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
            inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk", false)
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
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
        end,
    },
}

CommonStates.AddRunStates(
        states,
        {
            starttimeline =
            {
                TimeEvent(0*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_head/servo", { intensity =  math.random() }) end end),
                TimeEvent(1*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step", { intensity =  math.random() }) end end),
                TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end),
            },
            runtimeline =
            {
                TimeEvent(0*FRAMES, function(inst)
                    inst.Physics:Stop()
                    inst.components.locomotor:WalkForward()
                end),
                TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_arm/servo", { intensity =  math.random() }) end end),
                TimeEvent(0*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_arm/drag", { intensity =  math.random() }) end end),
                TimeEvent(1*FRAMES,  function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_head/servo", { intensity =  math.random() }) end end),
                TimeEvent(5*FRAMES,  function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_leg/servo",nil,0.8) end end),
                TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_arm/step", { intensity = math.random() }) end end),
                TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step", { intensity = math.random() }) end end),
                TimeEvent(6*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/servo", { intensity =  math.random() }) end end),
                TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_arm/servo", { intensity =  math.random() }) end end),
                TimeEvent(14*FRAMES, function(inst) if inst:HasTag("hulk_leg")    then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_leg/step", { intensity = math.random() }) end end),
                TimeEvent(16*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step_wires", { intensity = math.random() }) end end),
                TimeEvent(16*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/servo", { intensity =  math.random() }) end end),
                TimeEvent(17*FRAMES, function(inst) if inst:HasTag("hulk_head")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_head/step", { intensity = math.random() }) end end),
                TimeEvent(21*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step", { intensity = math.random() }) end end),
                TimeEvent(21*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/servo", { intensity =  math.random() }) end end),
                TimeEvent(25*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_arm/step", { intensity = math.random() }) end end),
                TimeEvent(25*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step", { intensity = math.random() }) end end),
                TimeEvent(25*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/servo", { intensity =  math.random() }) end end),
                TimeEvent(28*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_arm/servo", { intensity =  math.random() }) end end),
                TimeEvent(38*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step", { intensity = math.random() }) end end),
                TimeEvent(38*FRAMES, function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/servo", { intensity =  math.random() }) end end),
                TimeEvent(48*FRAMES, function(inst) inst.Physics:Stop() end),
            },
            endtimeline =
            {
                TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/step", { intensity = math.random() }) end end),
                TimeEvent(3*FRAMES,  function(inst) if inst:HasTag("hulk_spider") then inst.SoundEmitter:PlaySoundWithParams("DLChasni/DLChasni/chasni_metal_rib/servo", { intensity =  math.random() }) end end),
                TimeEvent(33*FRAMES, function(inst) if inst:HasTag("hulk_claw")   then inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_metal_arm/servo") end end),
                TimeEvent(48*FRAMES, function(inst) inst.Physics:Stop() end),
            },

        },
        { startrun="walk_pre", run="walk_loop", stoprun="walk_pst" },
        true,
        {
            startexit = function(inst) if not inst.cleantransition then inst.SoundEmitter:KillSound("robo_walk_LP") end end,
            loopexit = function(inst) if not inst.cleantransition then inst.SoundEmitter:KillSound("robo_walk_LP") end end,
            endexit = function(inst) inst.SoundEmitter:KillSound("robo_walk_LP") end,
        })

CommonStates.AddSimpleState(states,"hit", "hit")
CommonStates.AddFrozenStates(states)

return StateGraph("chasni_ancientrobot", states, events, "idle", actionhandlers)