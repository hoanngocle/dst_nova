
-- CC : woby hunger drain is paused >> [Reward] expertwalter1
if not chasni_getperkexcludeconfig("expertwalter1") then
    if TheNet:GetIsServer() then
        AddComponentPostInit("hunger", function(Hunger)
            local old_IsPaused = Hunger.IsPaused
            Hunger.IsPaused = function(...)
                if Hunger.inst and (Hunger.inst.prefab == "wobysmall" or Hunger.inst and Hunger.inst.prefab == "wobybig") then
                    local leader = Hunger.inst.components.follower and Hunger.inst.components.follower.leader
                    if leader and leader.components.allachivcoin and leader.components.allachivcoin.expertwalter1 then
                        if (Hunger.current / Hunger.max) <= 0.99 then
                            return true
                        end
                    end
                end
                if old_IsPaused then
                    return old_IsPaused(...)
                end
            end
        end)
    end
end

-- CC : walter new item logic >> [Reward] expertwalter3
if not chasni_getperkexcludeconfig("expertwalter3") then
    -- CC : walter wet paper >> [Reward] expertwalter3
    local old_give_fn = ACTIONS.GIVE.fn
    ACTIONS.GIVE.fn = function(act)
        if act.invobject and act.invobject:HasTag("wetpaper") and act.target and act.target:HasTag("chasni_researchproduct") then
            act.target:Remove()
            act.invobject.components.stackable:Get():Remove()
            return true
        end
        return old_give_fn(act)
    end
    local give_stroverridefn = ACTIONS.GIVE.stroverridefn
    ACTIONS.GIVE.stroverridefn = function(act)
        if act.invobject and act.invobject:HasTag("wetpaper") and act.target and act.target:HasTag("chasni_researchproduct") then
            return STRINGS.ACTIONS.CHASNI_WIPE
        end
        if give_stroverridefn then
            return give_stroverridefn(act)
        end
    end
    AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions)
        if inst.replica.inventoryitem and inst.replica.inventoryitem:IsGrandOwner(doer) then
            if inst and inst:HasTag("wetpaper") and target and target:HasTag("chasni_researchproduct") then
                table.insert(actions, ACTIONS.GIVE)
            end
        end
    end)

    -- CC : walter magnifying glass >> [Reward] expertwalter3
    local CHASNI_RESEARCH = GLOBAL.Action({priority = 10, distance = 2.5, mount_valid = true})
    CHASNI_RESEARCH.str = GLOBAL.STRINGS.ACTIONS.CHASNI_RESEARCH
    CHASNI_RESEARCH.id = "CHASNI_RESEARCH"
    CHASNI_RESEARCH.fn = function(act)
        if act.target and act.doer and chasni_hastag2(act.doer, "expertwalter3") then
            local magnifying_glass = act.doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
            if magnifying_glass and magnifying_glass.ResearchThings then
                magnifying_glass.ResearchThings(magnifying_glass, act.target)
                return true
            end
        end
    end
    AddAction(CHASNI_RESEARCH)

    AddComponentAction("SCENE", "researchables", function(inst, doer, actions, right)
        if not right then
            local magnifying_glass = doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
            if magnifying_glass and magnifying_glass:HasTag("chasni_magnifying_glass") and not doer.replica.rider:IsRiding() then
                table.insert(actions, ACTIONS.CHASNI_RESEARCH)
            end
        end
    end)
    AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.CHASNI_RESEARCH, "investigate_start"))
    AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.CHASNI_RESEARCH, "investigate_start"))

    local investigate_start = State {
        name = "investigate_start",
        tags = {"preinvestigate", "investigating", "working", "busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.sg:GoToState("investigate")
        end,
        events =
        {
            GLOBAL.EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            GLOBAL.EventHandler("animover", function(inst) inst.sg:GoToState("investigate") end),
        },
    }
    local function GetActiveScreenName()
        local screen = TheFrontEnd:GetActiveScreen()
        return screen and screen.name or ""
    end

    local function IsDefaultScreen()
        return GetActiveScreenName():find("HUD")
    end
    local investigate = State {
        name = "investigate",
        tags = {"preinvestigate", "investigating", "working", "busy"},
        onenter = function(inst)
            if IsDefaultScreen() and GLOBAL.ThePlayer then
                GLOBAL.ThePlayer:EnableMovementPrediction(false)
                GLOBAL.Profile:SetMovementPredictionEnabled(false)
                inst:DoTaskInTime(3,function()
                    if IsDefaultScreen() and GLOBAL.ThePlayer then
                        GLOBAL.ThePlayer:EnableMovementPrediction(true)
                        GLOBAL.Profile:SetMovementPredictionEnabled(true)
                    end
                end)
            else
                inst.sg.statemem.action = inst:GetBufferedAction()
            end
            inst.AnimState:PlayAnimation("lens")
        end,
        timeline =
        {
            GLOBAL.TimeEvent(9*GLOBAL.FRAMES, function(inst) inst.sg:RemoveStateTag("preinvestigate") end),
            GLOBAL.TimeEvent(16*GLOBAL.FRAMES, function(inst) inst.sg:RemoveStateTag("investigating") end),
            GLOBAL.TimeEvent(45*GLOBAL.FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        events =
        {
            GLOBAL.EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            GLOBAL.EventHandler("animover", function(inst) inst.sg:GoToState("investigate_post") end),
        },
    }

    local investigate_post = State {
        name = "investigate_post",
        tags = {"investigating", "working", "busy"},
        onenter = function(inst) inst.AnimState:PlayAnimation("lens_pst")
            if IsDefaultScreen() and GLOBAL.ThePlayer then
                GLOBAL.ThePlayer:EnableMovementPrediction(true)
                GLOBAL.Profile:SetMovementPredictionEnabled(true)
            end
        end,
        events =
        {
            GLOBAL.EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            GLOBAL.EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    }
    AddStategraphState("wilson", investigate_start)
    AddStategraphState("wilson_client", investigate_start)
    AddStategraphState("wilson", investigate)
    AddStategraphState("wilson_client", investigate)
    AddStategraphState("wilson", investigate_post)
    AddStategraphState("wilson_client", investigate_post)

    -- CC : add researchables to researchable items >> [Reward] expertwalter3
    local function researchablesinit(inst, iswater)
        inst:AddTag("researchables")
        if TheWorld.ismastersim then
            inst:AddComponent("researchables")
            inst.components.researchables.iswater = iswater
        end
    end

    for _, v in ipairs(investigateablelist) do
        AddPrefabPostInit(v, function(inst) researchablesinit(inst, false) end)
    end

    for _, v in ipairs(investigateablelist_water) do
        AddPrefabPostInit(v, function(inst) researchablesinit(inst, true) end)
    end
end
