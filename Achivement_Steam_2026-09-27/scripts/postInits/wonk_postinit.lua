-- CC : wonkey dig >> [Reward] expertwonk1
if not chasni_getperkexcludeconfig("expertwonk1") then
    local IsBurrowing = function(inst) return inst and inst.burrowing == true end

    local function StopBurrowing(inst)
        if inst and IsBurrowing(inst) then
            inst.burrowing = nil
        end
    end

    local oldPlayFootstep=GLOBAL.PlayFootstep
    GLOBAL.PlayFootstep=function(inst, ...)
        if inst and IsBurrowing(inst) then
            return
        end
        return oldPlayFootstep(inst, ...)
    end

    AddComponentPostInit("locomotor",function(self)
        local oldGetRunSpeed = self.GetRunSpeed
        function self:GetRunSpeed(...)
            if IsBurrowing(self.inst) then
                return 4
            end
            return oldGetRunSpeed(self, ...)
        end
    end)

    local function AddPlayerSG(self)
        local idle = self.states.idle
        if idle then
            local old_enter = idle.onenter
            function idle.ontimeout(inst) end
            function idle.onenter(inst, ...)
                if old_enter then
                    old_enter(inst, ...)
                end
                if IsBurrowing(inst) then
                    inst.AnimState:PlayAnimation("NONE",true)
                end
            end
        end

        local run = self.states.run
        if run then
            local old_enter = run.onenter
            function run.onenter(inst, ...)
                if old_enter then
                    old_enter(inst, ...)
                end
                if IsBurrowing(inst) then
                    if not inst.AnimState:IsCurrentAnimation("NONE") then
                        inst.AnimState:PlayAnimation("NONE", true)
                    end
                end
            end
        end

        local run_start = self.states.run_start
        if run_start then
            local old_enter = run_start.onenter
            function run_start.onenter(inst, ...)
                if old_enter then
                    old_enter(inst, ...)
                end
                if IsBurrowing(inst) then
                    inst.AnimState:PlayAnimation("NONE")
                end
            end
        end

        local run_stop = self.states.run_stop
        if run_stop then
            local old_enter = run_stop.onenter
            function run_stop.onenter(inst, ...)
                if old_enter then
                    old_enter(inst, ...)
                end
                if IsBurrowing(inst) then
                    inst.AnimState:PlayAnimation("NONE")
                end
            end
        end
    end
    AddStategraphPostInit('wilson', AddPlayerSG)
    AddStategraphPostInit('wilson_client', AddPlayerSG)

    if TheNet:GetIsServer() then
        AddPrefabPostInit("wonkey", function(inst)
            inst.burrowing = nil
            inst:AddComponent("wonkeyburrow")
            inst:ListenForEvent("death", function(_inst, data)
                if IsBurrowing(_inst) then
                    StopBurrowing(_inst,false)
                end
            end)
        end)
    end

    STRINGS.ACTIONS.BURROWING = "Đào hang"
    STRINGS.ACTIONS.UNBURROW = "Nhảy ra"
    local burrowactions = {
        {
            id = "BURROWING",
            priority = 10,
            str = GLOBAL.STRINGS.ACTIONS.BURROWING,
            fn = function(act)
                return true
            end,
            state = "burrowing"
        },
        {
            id = "UNBURROW",
            priority = 10,
            str = GLOBAL.STRINGS.ACTIONS.UNBURROW,
            fn = function(act)
                return true
            end,
            state = "unburrow"
        },
    }

    for _, act in pairs(burrowactions) do
        local ACTION = GLOBAL.Action({priority = act.priority})
        ACTION.id = act.id
        ACTION.str = act.str
        ACTION.fn = act.fn
        AddAction(ACTION)
        AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(ACTION, act.state))
        AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(ACTION, act.state))
    end

    local component_actions = {
        {
            type = "SCENE",
            component = "wonkeyburrow",
            tests = {
                {
                    action_id = "BURROWING",
                    testfn = function(inst, doer, actions, right)
                        return inst == doer and doer:HasTag("expertwonk1") and not doer:HasTag("burrowing")
                    end
                },
                {
                    action_id = "UNBURROW",
                    testfn = function(inst, doer, actions, right)
                        return doer:HasTag("burrowing")
                    end
                },
            }
        },
    }
    for _,v in pairs(component_actions) do
        local fn = function(...)
            local actions = GLOBAL.select (-2,...)
            for _,data in pairs(v.tests) do
                if data  then
                    if data.testfn and data.testfn(...) then
                        data.action_id = string.upper(data.action_id)
                        table.insert(actions, GLOBAL.ACTIONS[data.action_id])
                    end
                end
            end
        end
        AddComponentAction(v.type, v.component, fn)
    end

    local function BurrowingActionFilter(inst, action)
        return action.id == "UNBURROW"
    end
    local function Empty() end
    local burrow_states = {
        State {
            name = "burrowing",
            tags ={"idle", "busy", "doing", "notalking"},
            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst:ForceFacePoint(inst.Transform:GetWorldPosition())
                inst.sg.statemem.action = inst:GetBufferedAction()
                inst.AnimState:PlayAnimation("build_pre")
                inst.AnimState:PushAnimation("build_loop", true)
                inst._burrowtask = inst:DoTaskInTime(1,function()
                    inst.burrowing = true
                    inst:AddTag("burrowing")
                    inst:AddTag("debugnoattack")
                    inst:AddTag("notarget")
                    inst:AddTag("invisible")
                    inst.DynamicShadow:Enable(false)
                    if inst.components.inventory then
                        if inst.components.inventory:IsHeavyLifting() then
                            inst.components.inventory:DropItem(inst.components.inventory:Unequip(EQUIPSLOTS.BODY), true, true)
                        end
                        inst.components.inventory:Close(true)
                    end
                    if inst.components.locomotor then
                        inst.components.locomotor:SetAllowPlatformHopping(false)
                    end
                    if inst.components.combat then
                        inst._blankoutattacks_task = inst:DoPeriodicTask(10,function(_inst) _inst.components.combat:BlankOutAttacks(10) end,0)
                    end
                    if inst.components.playercontroller then
                        inst.components.playercontroller.actionbuttonoverride = Empty
                    end
                    if inst.components.catcher then
                        inst.components.catcher:SetEnabled(false)
                    end
                    if inst.components.playeractionpicker then
                        inst.components.playeractionpicker:PushActionFilter(BurrowingActionFilter, 999)
                    end

                    inst.sg:GoToState("idle")
                end)
            end,
            timeline = {
                TimeEvent(0 * FRAMES, function(inst) inst:PerformBufferedAction() end),
            },
            onexit = function(inst)
                if inst._burrowtask then
                    inst._burrowtask:Cancel()
                    inst._burrowtask = nil
                end
                if inst.burrowing then
                    inst._burrowingtask = inst:DoPeriodicTask(0.2, function()
                        if inst._burrow == nil then
                            local p = inst:GetPosition()
                            inst._burrow = chasni_spawnprefab("wonkey_burrow", p.x, p.y, p.z)
                            inst._burrow.Player = inst
                        end
                        if inst.components.locomotor.wantstomoveforward then
                            if inst._burrow.Move then
                                inst._burrow.Move(inst._burrow)
                                inst._burrow = nil
                            end
                        end
                    end)
                end
            end,
        },
        State {
            name = "unburrow",
            tags ={"idle", "busy", "doing", "notalking"},
            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst:ForceFacePoint(inst.Transform:GetWorldPosition())
                inst:RemoveTag("burrowing")
                inst:RemoveTag("debugnoattack")
                inst:RemoveTag("notarget")
                inst:RemoveTag("invisible")
                inst.burrowing = nil

                inst.AnimState:PlayAnimation("jumpout")
                if  inst.components.playercontroller then
                    inst.components.playercontroller:Enable(false)
                end
                if inst._burrowingtask then
                    inst._burrowingtask:Cancel()
                    inst._burrowingtask = nil
                end
                if inst._burrow and inst._burrow.Move then
                    inst._burrow.Move(inst._burrow)
                    inst._burrow = nil
                end
                inst.sg:SetTimeout(2)
            end,
            timeline = {
                TimeEvent(1* FRAMES, function(inst)inst:PerformBufferedAction() end)
            },
            events = {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end)
            },
            onexit = function(inst)
                if  inst.components.playercontroller then
                    inst.components.playercontroller:Enable(true)
                end

                inst.DynamicShadow:Enable(true)
                if inst.components.inventory and not inst.components.health:IsDead() then
                    inst.components.inventory:Open()
                end
                if inst.components.locomotor then
                    inst.components.locomotor:SetAllowPlatformHopping(true)
                end
                if inst._blankoutattacks_task then
                    inst._blankoutattacks_task:Cancel()
                    inst.components.combat:BlankOutAttacks(0)
                end
                if inst.components.playercontroller then
                    inst.components.playercontroller.actionbuttonoverride = nil
                end
                if inst.components.catcher then
                    inst.components.catcher:SetEnabled(true)
                end
                if inst.components.playeractionpicker then
                    inst.components.playeractionpicker:PopActionFilter(BurrowingActionFilter)
                end
            end,
        },
    }
    for _, state in pairs(burrow_states) do
        AddStategraphState("wilson", state)
        AddStategraphState("wilson_client", state)
    end

    AddStategraphPostInit("wilson", function(inst)
        local onhiattackedevent = inst.events["attacked"]
        local new_attackedevent = EventHandler("attacked", function(_inst, data)
            if _inst.burrowing ~= true then
                onhiattackedevent.fn(_inst, data)
            end
        end)
        inst.events["attacked"] = new_attackedevent
    end)
end

-- CC : add cursedtrinket checker >> [Reward] expertwonk2
if not chasni_getperkexcludeconfig("expertwonk2") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("wonkey", function(inst)
            local refreshInventory = function()
                if inst.components.allachivcoin and inst.components.allachivcoin.expertwonk2 == true then
                    local _, count = inst.components.inventory:Has("cursed_monkey_token", 1)
                    inst.components.combat.externaldamagemultipliers:RemoveModifier("expertwonk2")
                    inst.components.combat.externaldamagemultipliers:SetModifier("expertwonk2", 1 + (count * 0.05))
                end
            end
            local function refreshInventoryDelay(_inst) _inst:DoTaskInTime(.1, refreshInventory) end
            inst:ListenForEvent("itemget", refreshInventoryDelay)
            inst:ListenForEvent("gotnewitem", refreshInventoryDelay)
            inst:ListenForEvent("itemlose", refreshInventoryDelay)
            inst:ListenForEvent("dropitem", refreshInventoryDelay)
        end)
    end
end
