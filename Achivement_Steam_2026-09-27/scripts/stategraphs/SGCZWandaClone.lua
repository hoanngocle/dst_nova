require("stategraphs/commonstates")

local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function TryRepeatAction(inst, buffaction, right)
    if buffaction and
            buffaction:IsValid() and
            buffaction.target and
            buffaction.target.components.workable and
            buffaction.target.components.workable:CanBeWorked() and
            buffaction.target:IsActionValid(buffaction.action, right)
    then
        local otheraction = inst:GetBufferedAction()
        if otheraction == nil or (
                otheraction.target == buffaction.target and
                        otheraction.action == buffaction.action
        ) then
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst:PushBufferedAction(buffaction)
            return true
        end
    end
    return false
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.foleysound then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
end

local DoRunSounds = function(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end

local function ConfigureRunState(inst)
    inst.sg.statemem.normal = true
end

local function GetUnequipState(inst, data)
    return (data.eslot ~= EQUIPSLOTS.HANDS and "item_hat")
            or (not data.slip and "item_in")
            or (data.item and data.item:IsValid() and "tool_slip")
            or "toolbroke"
    , data.item
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function StartTeleporting(inst)
    inst.sg.statemem.isteleporting = true
    inst:Hide()
    inst.DynamicShadow:Enable(false)
end

local function DoneTeleporting(inst)
    inst.sg.statemem.isteleporting = false
    inst:Show()
    inst.DynamicShadow:Enable(true)
end

local actionhandlers =
{
    ActionHandler(ACTIONS.TILL, "till_start"),
    ActionHandler(ACTIONS.PLANTSOIL,
            function(inst, action)
                return (inst:HasTag("quagmire_farmhand") and "doshortaction")
                        or (inst:HasTag("quagmire_fasthands") and "domediumaction")
                        or "dolongaction"
            end),
    ActionHandler(ACTIONS.POUR_WATER,
            function(inst, action)
                return action.invobject
                        and (action.invobject:HasTag("wateringcan") and "pour")
                        or "dolongaction"
            end),
    ActionHandler(ACTIONS.POUR_WATER_GROUNDTILE,
            function(inst, action)
                return action.invobject
                        and (action.invobject:HasTag("wateringcan") and "pour")
                        or "dolongaction"
            end),
    ActionHandler(ACTIONS.FILL, "dolongaction"),
    ActionHandler(ACTIONS.ADDCOMPOSTABLE, "give"),
    ActionHandler(ACTIONS.ACTIVATE, "give"),
    ActionHandler(ACTIONS.DEPLOY, "doshortaction"),
    ActionHandler(ACTIONS.DEPLOY_TILEARRIVE, "doshortaction"),
    ActionHandler(ACTIONS.HAMMER,
            function(inst)
                return not inst.sg:HasStateTag("prehammer")
                        and (inst.sg:HasStateTag("hammering") and
                        "hammer" or
                        "hammer_start")
                        or nil
            end),
    ActionHandler(ACTIONS.PICK,
            function(inst, action)
                return (action.target
                        and action.target.components.pickable
                        and (   (action.target.components.pickable.jostlepick and "dojostleaction") or
                        (action.target.components.pickable.quickpick and "doshortaction") or
                        (inst:HasTag("fastpicker") and "doshortaction") or
                        (inst:HasTag("quagmire_fasthands") and "domediumaction") or
                        "dolongaction"  ))
                        or nil
            end),
    ActionHandler(ACTIONS.FERTILIZE,
            function(inst, action)
                return (((action.target and action.target ~= inst) or action:GetActionPoint()) and "doshortaction")
                        or (action.invobject and action.invobject:HasTag("slowfertilize") and "fertilize")
                        or "fertilize_short"
            end),
    ActionHandler(ACTIONS.SCYTHE, "scythe"),
    ActionHandler(ACTIONS.CHOP,
            function(inst)
                if not inst.sg:HasStateTag("prechop") then
                    return inst.sg:HasStateTag("chopping")
                            and "chop"
                            or "chop_start"
                end
            end),
    ActionHandler(ACTIONS.DIG,
            function(inst)
                if not inst.sg:HasStateTag("predig") then
                    return inst.sg:HasStateTag("digging")
                            and "dig"
                            or "dig_start"
                end
            end),
    ActionHandler(ACTIONS.HARVEST,
            function(inst)
                return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
            end),
    ActionHandler(ACTIONS.NET,
            function(inst)
                return not inst.sg:HasStateTag("prenet")
                        and (inst.sg:HasStateTag("netting") and
                        "bugnet" or
                        "bugnet_start")
                        or nil
            end),
    ActionHandler(ACTIONS.FISH, "fishing_pre"),
    ActionHandler(ACTIONS.MURDER,
            function(inst)
                return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
            end),
    ActionHandler(ACTIONS.OCEAN_FISHING_POND, "fishing_ocean_pre"),
    ActionHandler(ACTIONS.OCEAN_FISHING_CAST, "oceanfishing_cast"),
    ActionHandler(ACTIONS.OCEAN_FISHING_REEL,
            function(inst, action)
                local fishable = action.invobject and action.invobject.components.oceanfishingrod.target or nil
                if fishable and fishable.components.oceanfishable and fishable:HasTag("partiallyhooked") then
                    return "oceanfishing_sethook"
                elseif inst:HasTag("fishing_idle") and not (inst.sg:HasStateTag("reeling") and not inst.sg.statemem.allow_repeat) then
                    return "oceanfishing_reel"
                end
                return nil
            end),
    ActionHandler(ACTIONS.OCEAN_TRAWLER_LOWER, "doshortaction"),
    ActionHandler(ACTIONS.OCEAN_TRAWLER_RAISE, "doshortaction"),
    ActionHandler(ACTIONS.OCEAN_TRAWLER_FIX, "dolongaction"),
    ActionHandler(ACTIONS.RESETMINE, "dolongaction"),
    ActionHandler(ACTIONS.REPAIR, "dolongaction"),
    ActionHandler(ACTIONS.REPAIR_LEAK, "dolongaction"),
    ActionHandler(ACTIONS.ADDFUEL, "doshortaction"),
    ActionHandler(ACTIONS.TURNOFF, "give"),
    ActionHandler(ACTIONS.TURNON, "give"),
    ActionHandler(ACTIONS.MINE,
            function(inst)
                if not inst.sg:HasStateTag("premine") then
                    return inst.sg:HasStateTag("mining")
                            and "mine"
                            or "mine_start"
                end
            end),
    ActionHandler(ACTIONS.BUILD,
            function(inst, action)
                local rec = GetValidRecipe(action.recipe)
                return (rec and rec.sg_state)
                        or (inst:HasTag("hungrybuilder") and "dohungrybuild")
                        or (inst:HasTag("fastbuilder") and "domediumaction")
                        or (inst:HasTag("slowbuilder") and "dolongestaction")
                        or "dolongaction"
            end),
    ActionHandler(ACTIONS.STORE, "doshortaction"),
    ActionHandler(ACTIONS.RUMMAGE, "doshortaction"),
    ActionHandler(ACTIONS.JUMPIN, "jumpin_pre"),
    ActionHandler(ACTIONS.BRUSH, "dolongaction"),
    ActionHandler(ACTIONS.SHAVE, "dolongaction"),
    ActionHandler(ACTIONS.COOK, "dolongaction"),
    ActionHandler(ACTIONS.DRY, "doshortaction"),
    ActionHandler(ACTIONS.GIVE,
            function(inst, action)
                return action.invobject
                        and action.target
                        and (   (action.target:HasTag("moonportal") and action.invobject:HasTag("moonportalkey") and "dochannelaction") or
                        (action.invobject.prefab == "quagmire_portal_key" and action.target:HasTag("quagmire_altar") and "quagmireportalkey") or
                        (action.target:HasTag("give_dolongaction") and "dolongaction")
                )
                        or "give"
            end),
    ActionHandler(ACTIONS.TAKEITEM,
            function(inst, action)
                return action.target
                        and action.target.takeitem --added for quagmire
                        and "give"
                        or "dolongaction"
            end),
    ActionHandler(ACTIONS.PICKUP, "doshortaction"),
    ActionHandler(ACTIONS.DROP, "doshortaction"),
    ActionHandler(ACTIONS.MIGRATE, "migrate"),
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnHop(),
    CommonHandlers.OnLocomote(true, false),

    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) then
            local weapon = inst.components.combat and inst.components.combat:GetWeapon() or nil
            if weapon == nil then
                inst.sg:GoToState("attack")
            elseif weapon:HasTag("blowdart") then
                inst.sg:GoToState("blowdart")
            elseif weapon:HasTag("thrown") then
                inst.sg:GoToState("throw")
            elseif weapon:HasTag("speargun") then
                inst.sg:GoToState("speargun")
            elseif weapon:HasTag("blunderbuss") then
                inst.sg:GoToState("speargun")
            else
                inst.sg:GoToState("attack")
            end
        end
    end),

    EventHandler("equip", function(inst, data)
        if inst.sg:HasStateTag("idle") or inst.sg:HasStateTag("channeling") then
            inst.sg:GoToState(
                    (data.item and data.item.projectileowner and "catch_equip") or
                            (data.eslot == EQUIPSLOTS.HANDS and "item_out") or
                            "item_hat"
            )
        elseif data.item and data.item.projectileowner then
            SpawnPrefab("lucy_transform_fx").entity:AddFollower():FollowSymbol(inst.GUID, "swap_object", 50, -25, 0)
        end
    end),

    EventHandler("unequip", function(inst, data)
        if inst.sg:HasStateTag("idle") or inst.sg:HasStateTag("channeling") then
            inst.sg:GoToState(GetUnequipState(inst, data))
        end
    end),

    EventHandler("fishingcancel", function(inst)
        if inst.sg:HasStateTag("fishing") and not inst:HasTag("busy") then
            inst.sg:GoToState("fishing_pst")
        end
    end),

    EventHandler("oceanfishing_stoppedfishing", function(inst, data)
        if inst.sg:HasStateTag("fishing") then
            if data and data.reason then
                if data.reason == "linesnapped" or data.reason == "toofaraway" then
                    inst.sg:GoToState("oceanfishing_linesnapped", {escaped_str = "ANNOUNCE_OCEANFISHING_LINESNAP"})
                else
                    inst.sg:GoToState("oceanfishing_stop", {escaped_str = data.reason == "linetooloose" and "ANNOUNCE_OCEANFISHING_LINETOOLOOSE"
                            or data.reason == "badcast" and "ANNOUNCE_OCEANFISHING_BADCAST"
                            or (data.reason ~= "reeledin") and "ANNOUNCE_OCEANFISHING_GOTAWAY"
                            or nil})
                end
            else
                inst.sg:GoToState("oceanfishing_stop")
            end
        end
    end),

    EventHandler("onsink", function(inst, data)
        if data and data.ia_boat and not inst.sg:HasStateTag("drowning") and
                (inst.components.drownable and inst.components.drownable:ShouldDrown()) then
            inst.sg:GoToState("sink_boat", data.shore_pt)
        else
            if inst.components.drownable and inst.components.drownable:ShouldDrown() then
                if data and data.boat then
                    inst.sg:GoToState("sink", data.shore_pt)
                else
                    inst.sg:GoToState("sink_fast")
                end
            end
        end
    end),
}

local states =
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            if inst.components.drownable and inst.components.drownable:ShouldDrown() then
                inst.sg:GoToState("sink_fast")
                return
            end

            local equippedArmor = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if equippedArmor and equippedArmor:HasTag("band") then
                inst.sg:GoToState("enter_onemanband", pushanim)
                return
            end

            if pushanim then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,
    },

    State {
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
            inst.sg.mem.footsteps = 0
        end,
        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State {
        name = "run",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()

            if not inst.AnimState:IsCurrentAnimation("run_loop") then
                inst.AnimState:PlayAnimation("run_loop", true)
            end

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                DoRunSounds(inst)
                DoFoleySounds(inst)
            end),
            TimeEvent(15 * FRAMES, function(inst)
                DoRunSounds(inst)
                DoFoleySounds(inst)
            end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State {
        name = "run_stop",
        tags = {"canrotate", "idle"},

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("run_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "doequippedaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give_equipped")
            inst.AnimState:PushAnimation("give_equipped_pst", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(14 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(12 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        ontimeout = function(inst)
            --give_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "catch_equip",
        tags = { "idle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("catch_pre")
            inst.AnimState:PushAnimation("catch", false)
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                inst.sg.statemem.playedfx = true
                SpawnPrefab("lucy_transform_fx").entity:AddFollower():FollowSymbol(inst.GUID, "swap_object", 50, -25, 0)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_catch")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.playedfx then
                SpawnPrefab("lucy_transform_fx").entity:AddFollower():FollowSymbol(inst.GUID, "swap_object", 50, -25, 0)
            end
        end,
    },

    State {
        name = "item_hat",
        tags = { "idle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_hat")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "item_in",
        tags = { "idle", "nodangle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_in")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.followfx then
                for i, v in ipairs(inst.sg.statemem.followfx) do
                    v:Remove()
                end
            end
        end,
    },

    State {
        name = "item_out",
        tags = { "idle", "nodangle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_out")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "give",
        tags = { "giving" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give")
            inst.AnimState:PushAnimation("give_pst", false)
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "doshortaction",
        tags = { "doing", "busy" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(10 * FRAMES)
        end,
        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(6 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "domediumaction",
        onenter = function(inst)
            inst.sg:GoToState("dolongaction", .5)
        end,
    },

    State {
        name = "dolongaction",
        tags = { "doing", "busy", "nodangle" },
        onenter = function(inst, timeout)
            if timeout == nil then
                timeout = 1
            elseif timeout > 1 then
                inst.sg:AddStateTag("slowaction")
            end
            inst.sg:SetTimeout(timeout)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
            if inst.bufferedaction then
                inst.sg.statemem.action = inst.bufferedaction
                if inst.bufferedaction.action.actionmeter then
                    inst.sg.statemem.actionmeter = true
                    StartActionMeter(inst, timeout)
                end
                if inst.bufferedaction.target and inst.bufferedaction.target:IsValid() then
                    inst.bufferedaction.target:PushEvent("startlongaction")
                end
            end
        end,
        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },
        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
            inst.AnimState:PlayAnimation("build_pst")
            if inst.sg.statemem.actionmeter then
                inst.sg.statemem.actionmeter = nil
                StopActionMeter(inst, true)
            end
            inst:PerformBufferedAction()
        end,
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
            if inst.sg.statemem.actionmeter then
                StopActionMeter(inst, false)
            end
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "dojostleaction",
        tags = { "doing", "busy" },
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.locomotor:Stop()
            local cooldown
            if equip and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_large")
                cooldown = 17 * FRAMES
            elseif equip and equip:HasTag("pocketwatch") then
                inst.AnimState:PlayAnimation("pocketwatch_atk_pre" )
                inst.AnimState:PushAnimation("pocketwatch_atk", false)
                inst.sg.statemem.ispocketwatch = true
                cooldown = 19 * FRAMES
                if equip:HasTag("shadow_item") then
                    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre_shadow")
                    inst.AnimState:Show("pocketwatch_weapon_fx")
                    inst.sg.statemem.ispocketwatch_fueled = true
                else
                    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre")
                    inst.AnimState:Hide("pocketwatch_weapon_fx")
                end
            elseif equip and equip:HasTag("jab") then
                inst.AnimState:PlayAnimation("spearjab_pre")
                inst.AnimState:PushAnimation("spearjab", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                cooldown = 21 * FRAMES
            elseif equip and equip.components.weapon and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                cooldown = 13 * FRAMES
            elseif equip and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                cooldown = 13 * FRAMES
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                cooldown = 24 * FRAMES
            end

            if target and target:IsValid() then
                inst:FacePoint(target:GetPosition())
            end

            inst.sg.statemem.action = buffaction
            inst.sg:SetTimeout(cooldown)
        end,
        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                if not (inst.sg.statemem.iswhip or
                        inst.sg.statemem.ispocketwatch) then
                    inst.sg:RemoveStateTag("busy")
                    inst:PerformBufferedAction()
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip or inst.sg.statemem.ispocketwatch then
                    inst.sg:RemoveStateTag("busy")
                    inst:PerformBufferedAction()
                end
            end),
            TimeEvent(17*FRAMES, function(inst)
                if inst.sg.statemem.ispocketwatch then
                    inst.SoundEmitter:PlaySound(inst.sg.statemem.ispocketwatch_fueled and "wanda2/characters/wanda/watch/weapon/pst_shadow" or "wanda2/characters/wanda/watch/weapon/pst")
                end
            end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        },
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "migrate",
        tags = { "doing", "busy" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")

            inst.sg.statemem.action = inst.bufferedaction
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() and
                        not inst:PerformBufferedAction() then
                    inst.AnimState:PlayAnimation("pickup_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "attack",
        tags = {"attack", "notalking", "abouttoattack", "busy"},

        onenter = function(inst)
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
            end
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            local cooldown = 0
            if equip and equip:HasTag("toolpunch") then
                inst.AnimState:PlayAnimation("toolpunch")
                inst.sg.statemem.istoolpunch = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                cooldown = math.max(cooldown, 17 * FRAMES)
            elseif equip and equip:HasTag("pocketwatch") then
                inst.AnimState:PlayAnimation(inst.sg.statemem.chained and "pocketwatch_atk_pre_2" or "pocketwatch_atk_pre" )
                inst.AnimState:PushAnimation("pocketwatch_atk", false)
                inst.sg.statemem.ispocketwatch = true
                cooldown = math.max(cooldown, 15 * FRAMES)
                if equip:HasTag("shadow_item") then
                    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre_shadow", nil, nil, true)
                    inst.AnimState:Show("pocketwatch_weapon_fx")
                    inst.sg.statemem.ispocketwatch_fueled = true
                else
                    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre", nil, nil, true)
                    inst.AnimState:Hide("pocketwatch_weapon_fx")
                end
            elseif equip and equip:HasTag("book") then
                inst.AnimState:PlayAnimation("attack_book")
                inst.sg.statemem.isbook = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 19 * FRAMES)
            elseif equip and equip.components.weapon and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                if (equip.projectiledelay or 0) > 0 then
                    --V2C: Projectiles don't show in the initial delayed frames so that
                    --     when they do appear, they're already in front of the player.
                    --     Start the attack early to keep animation in sync.
                    inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                    if inst.sg.statemem.projectiledelay > FRAMES then
                        inst.sg.statemem.projectilesound =
                        (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                "dontstarve/wilson/attack_weapon"
                    elseif inst.sg.statemem.projectiledelay <= 0 then
                        inst.sg.statemem.projectiledelay = nil
                    end
                end
                if inst.sg.statemem.projectilesound == nil then
                    inst.SoundEmitter:PlaySound(
                            (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                    (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                                    (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                    "dontstarve/wilson/attack_weapon",
                            nil, nil, true
                    )
                end
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 24 * FRAMES)
            end

            inst.sg:SetTimeout(cooldown)

            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst:FacePoint(inst.components.combat.target.Transform:GetWorldPosition())
            end
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
            TimeEvent(12*FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(13*FRAMES, function(inst)
                inst.sg:RemoveStateTag("attack")
            end),
        },

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "blowdart",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end
            local buffaction = inst:GetBufferedAction()
            local target = buffaction and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dart_pre")
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetTime(5 * FRAMES)
            end
            inst.AnimState:PushAnimation("dart", false)

            inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES, inst.components.combat.min_attack_period + .5 * FRAMES))

            if target and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
            end

            if (equip and equip.projectiledelay or 0) > 0 then
                --V2C: Projectiles don't show in the initial delayed frames so that
                --     when they do appear, they're already in front of the player.
                --     Start the attack early to keep animation in sync.
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES - equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
        end,
        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,
        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if not inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
        },
        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,
        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State {
        name = "throw",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },
        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end
            local buffaction = inst:GetBufferedAction()
            local target = buffaction and buffaction.target or nil
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = math.max(inst.components.combat.min_attack_period + .5 * FRAMES, 11 * FRAMES)

            inst.AnimState:PlayAnimation("throw")

            inst.sg:SetTimeout(cooldown)

            if target and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
            end
        end,
        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.sg.statemem.thrown = true
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
        },
        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,
        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst, data)
                if data.eslot ~= EQUIPSLOTS.HANDS or not inst.sg.statemem.thrown then
                    inst.sg:GoToState("idle")
                end
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State {
        name = "chop_start",
        tags = {"prechop", "working"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("chop_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("chop")
                end
            end),
        },
    },

    State {
        name = "chop",
        tags = {"prechop", "chopping", "working"},
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("chop_loop")
        end,
        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
            TimeEvent(14 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("prechop")
                TryRepeatAction(inst, inst.sg.statemem.action)
            end),
            TimeEvent(16*FRAMES, function(inst)
                inst.sg:RemoveStateTag("chopping")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "dig_start",
        tags = {"predig", "working"},
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            inst.sg.statemem.target = buffaction and buffaction.target or nil

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("dig")
                end
            end),
        },
    },

    State {
        name = "dig",
        tags = {"predig", "digging", "working"},
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            inst.sg.statemem.target = buffaction and buffaction.target or nil

            inst.AnimState:PlayAnimation("shovel_loop")
        end,
        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),

            TimeEvent(35 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("predig")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("shovel_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State {
        name = "mine_start",
        tags = {"premine", "working"},
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            inst.sg.statemem.target = buffaction and buffaction.target or nil

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mine")
                end
            end),
        },
    },

    State {
        name = "mine",
        tags = {"premine", "mining", "working"},
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            inst.sg.statemem.target = buffaction and buffaction.target or nil

            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,
        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                local buffaction = inst:GetBufferedAction()
                if buffaction then
                    local target = buffaction.target
                    if target and target:IsValid() then
                        if target.Transform then
                            SpawnPrefab("mining_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
                        end
                        inst.SoundEmitter:PlaySound(target:HasTag("frozen") and "dontstarve_DLC001/common/iceboulder_hit" or "dontstarve/wilson/use_pick_rock")
                    end
                    inst:PerformBufferedAction()
                end
            end),

            TimeEvent(14 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("premine")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State {
        name = "till_start",
        tags = { "doing", "busy" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.tool and equippedTool.components.tool:CanDoAction(ACTIONS.DIG) then
                --upside down tool build
                inst.AnimState:PlayAnimation("till2_pre")
            else
                inst.AnimState:PlayAnimation("till_pre")
            end
        end,
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("till")
                end
            end),
        },
    },

    State {
        name = "till",
        tags = { "doing", "busy" },
        onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.tool and equippedTool.components.tool:CanDoAction(ACTIONS.DIG) then
                --upside down tool build
                inst.sg.statemem.fliptool = true
                inst.AnimState:PlayAnimation("till2_loop")
            else
                inst.AnimState:PlayAnimation("till_loop")
            end
        end,
        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/dig") end),
            TimeEvent(11 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge") end),
            TimeEvent(22 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation(inst.sg.statemem.fliptool and "till2_pst" or "till_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State {
        name = "pour",
        tags = { "doing", "busy" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("water_pre")
            inst.AnimState:PushAnimation("water", false)

            inst.AnimState:Show("water")

            inst.sg.statemem.action = inst:GetBufferedAction()

            if inst.sg.statemem.action then
                local pt = inst.sg.statemem.action:GetActionPoint()
                if pt then
                    local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(pt.x, 0, pt.z)
                    inst.Transform:SetRotation(inst:GetAngleToPoint(tx, ty, tz))
                end

                local invobject = inst.sg.statemem.action.invobject
                if invobject.components.finiteuses and invobject.components.finiteuses:GetUses() <= 0 then
                    inst.AnimState:Hide("water")
                    inst.sg.statemem.nosound = true
                end
            end

            inst.sg:SetTimeout(26 * FRAMES)
        end,
        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(5 * FRAMES, function(inst)
                if not inst.sg.statemem.nosound then
                    inst.SoundEmitter:PlaySound("farming/common/watering_can/use")
                end
            end),
            TimeEvent(24 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "fertilize",
        tags = { "doing", "busy", "nomorph", "self_fertilizing" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fertilize_pre")
            inst.AnimState:PushAnimation("fertilize", false)
        end,
        timeline =
        {
            TimeEvent(27 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/characters/wormwood/fertalize_LP", "rub")
                inst.SoundEmitter:SetParameter("rub", "start", math.random())
            end),
            TimeEvent(82 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("rub")
            end),
            TimeEvent(88 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
            TimeEvent(90 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("rub")
        end,
    },

    State {
        name = "fertilize_short",
        tags = { "doing", "busy", "nomorph", "self_fertilizing" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("short_fertilize_pre")
            inst.AnimState:PushAnimation("short_fertilize", false)
        end,
        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/characters/wormwood/fertalize_LP", "rub")
                inst.SoundEmitter:SetParameter("rub", "start", math.random())
            end),
            TimeEvent(18 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
            TimeEvent(31 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("rub")
            end),
            TimeEvent(33 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("rub")
        end,
    },

    State {
        name = "hammer_start",
        tags = { "prehammer", "working" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("hammer")
                end
            end),
        },
    },

    State {
        name = "hammer",
        tags = { "prehammer", "hammering", "working" },
        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,
        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("prehammer")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("prehammer")
            end),
        },
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State {
        name = "enter_onemanband",
        tags = { "playing", "idle" },
        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            if pushanim then
                inst.AnimState:PushAnimation("idle_onemanband1_pre", false)
            else
                inst.AnimState:PlayAnimation("idle_onemanband1_pre")
            end

            if inst.AnimState:IsCurrentAnimation("idle_onemanband1_pre") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
                inst.sg.statemem.soundplayed = true
            end
        end,
        onupdate = function(inst)
            if not inst.sg.statemem.soundplayed and inst.AnimState:IsCurrentAnimation("idle_onemanband1_pre") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
                inst.sg.statemem.soundplayed = true
            end
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() and inst.AnimState:IsCurrentAnimation("idle_onemanband1_pre") then
                    inst.sg:GoToState("play_onemanband")
                end
            end),
        },
    },

    State {
        name = "play_onemanband",
        tags = { "playing", "idle" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_onemanband1_loop")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(math.random() < 0.15 and "play_onemanband_stomp" or "play_onemanband")
                end
            end),
        },
    },

    State {
        name = "play_onemanband_stomp",
        tags = { "playing", "idle" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_onemanband1_pst")
            inst.AnimState:PushAnimation("idle_onemanband2_pre")
            inst.AnimState:PushAnimation("idle_onemanband2_loop")
            inst.AnimState:PushAnimation("idle_onemanband2_pst", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
        end,
        timeline =
        {
            TimeEvent(20*FRAMES, function( inst ) inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband") end),
            TimeEvent(25*FRAMES, function( inst ) inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband") end),
            TimeEvent(30*FRAMES, function( inst ) inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband") end),
            TimeEvent(35*FRAMES, function( inst ) inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband") end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "scythe",
        tags = { "busy" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("scythe_pre")
            inst.AnimState:PushAnimation("scythe_loop", false)
        end,
        timeline =
        {
            FrameEvent(14, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh") end),
            FrameEvent(15, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                inst:PerformBufferedAction()
            end),
            FrameEvent(18, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            FrameEvent(25, function(inst)
                inst.sg:GoToState("idle", true)
            end),
        },
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "bugnet_start",
        tags = { "prenet", "working", "autopredict" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("bugnet_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("bugnet")
                end
            end),
        },
    },

    State {
        name = "bugnet",
        tags = { "prenet", "netting", "working", "autopredict" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bugnet")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bugnet", nil, nil, true)
        end,
        timeline =
        {
            TimeEvent(10*FRAMES, function(inst)
                local buffaction = inst:GetBufferedAction()
                local tool = buffaction and buffaction.invobject or nil
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("prenet")
                inst.SoundEmitter:PlaySound(tool and tool.overridebugnetsound or "dontstarve/wilson/dig")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "fishing_pre",
        tags = { "prefish", "fishing" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pre")
            inst.AnimState:PushAnimation("fishing_cast", false)
        end,
        timeline =
        {
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast") end),
            TimeEvent(15*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_baitsplash")
                    inst.sg:GoToState("fishing")
                end
            end),
        },
    },

    State {
        name = "fishing",
        tags = { "fishing" },
        onenter = function(inst, pushanim)
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation("fishing_idle", true)
            else
                inst.AnimState:PlayAnimation("fishing_idle", true)
            end
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:WaitForFish()
            end
        end,
        events =
        {
            EventHandler("fishingnibble", function(inst) inst.sg:GoToState("fishing_nibble") end),
        },
    },

    State {
        name = "fishing_pst",
        tags = { "fishing" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pst")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "fishing_nibble",
        tags = { "fishing", "nibble" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_light_pre")
            inst.AnimState:PushAnimation("bite_light_loop", true)
            inst.sg:SetTimeout(1 + math.random())
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("fishing", "bite_light_pst")
        end,
        events =
        {
            EventHandler("fishingstrain", function(inst) inst.sg:GoToState("fishing_strain") end),
        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
        end,
    },

    State {
        name = "fishing_strain",
        tags = { "fishing" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_heavy_pre")
            inst.AnimState:PushAnimation("bite_heavy_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_strain", "strain")
        end,
        events =
        {
            EventHandler("fishingcatch", function(inst, data)
                inst.sg:GoToState("catchfish", data.build)
            end),
            EventHandler("fishingloserod", function(inst)
                inst.sg:GoToState("loserod")
            end),

        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
            inst.SoundEmitter:KillSound("strain")
        end,
    },

    State {
        name = "catchfish",
        tags = { "fishing", "catchfish", "busy" },
        onenter = function(inst, build)
            inst.AnimState:PlayAnimation("fish_catch")
            inst.AnimState:OverrideSymbol("fish01", build, "fish01")
        end,
        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishcaught") end),
            TimeEvent(10*FRAMES, function(inst) inst.sg:RemoveStateTag("fishing") end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland") end),
            TimeEvent(24*FRAMES, function(inst)
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool and equippedTool.components.fishingrod then
                    equippedTool.components.fishingrod:Collect()
                end
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("fish01")
        end,
    },

    State {
        name = "loserod",
        tags = { "busy", "nopredict" },
        onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:Release()
                equippedTool:Remove()
            end
            inst.AnimState:PlayAnimation("fish_nocatch")
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_lostrod") end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "sink",
        tags = { "busy", "nopredict", "nomorph", "drowning", "nointerrupt" },
        onenter = function(inst, shore_pt)
            inst:ClearBufferedAction()
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst.AnimState:PlayAnimation("sink")
            inst.SoundEmitter:PlaySound("dontstarve/characters/"..(inst.soundsname or inst.prefab).."/sinking")
            if shore_pt then
                inst.components.drownable:OnFallInOcean(shore_pt:Get())
            else
                inst.components.drownable:OnFallInOcean()
            end
            inst.DynamicShadow:Enable(false)
        end,
        timeline =
        {
            TimeEvent(75 * FRAMES, function(inst)
                inst.components.drownable:DropInventory()
                inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    StartTeleporting(inst)
                    inst.components.drownable:WashAshore() -- TODO: try moving this into the timeline
                end
            end),
            EventHandler("on_washed_ashore", function(inst)
                inst.sg:GoToState("washed_ashore")
            end),
        },
        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end

            if inst.sg.statemem.isteleporting then
                DoneTeleporting(inst)
            end

            inst.DynamicShadow:Enable(true)
        end,
    },

    State {
        name = "sink_fast",
        tags = { "busy", "nopredict", "nomorph", "drowning", "nointerrupt" },
        onenter = function(inst, data)
            inst:ClearBufferedAction()

            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            inst.AnimState:PlayAnimation("sink")
            inst.AnimState:SetFrame(60)
            inst.AnimState:Hide("plank")
            inst.AnimState:Hide("float_front")
            inst.AnimState:Hide("float_back")

            inst.components.drownable:OnFallInOcean()
            inst.DynamicShadow:Enable(false)
        end,
        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst)
                inst.AnimState:Show("float_front")
                inst.AnimState:Show("float_back")
            end),
            TimeEvent(16 * FRAMES, function(inst)
                inst.components.drownable:DropInventory()
            end),
        },


        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    StartTeleporting(inst)
                    inst.components.drownable:WashAshore()
                end
            end),
            EventHandler("on_washed_ashore", function(inst)
                inst.sg:GoToState("washed_ashore")
            end),
        },
        onexit = function(inst)
            inst.AnimState:Show("plank")
            inst.AnimState:Show("float_front")
            inst.AnimState:Show("float_back")
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end
            if inst.sg.statemem.isteleporting then
                DoneTeleporting(inst)
            end
            inst.DynamicShadow:Enable(true)
        end,
    },

    State {
        name = "washed_ashore",
        tags = { "busy", "canrotate", "nopredict", "nomorph", "drowning", "nointerrupt" },
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wakeup")
            if inst.components.drownable then
                inst.components.drownable:TakeDrowningDamage()
            end

            local puddle = SpawnPrefab("washashore_puddle_fx")
            puddle.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "oceanfishing_cast",
        tags = { "prefish", "fishing" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_ocean_pre")
            inst.AnimState:PushAnimation("fishing_ocean_cast", false)
            inst.AnimState:PushAnimation("fishing_ocean_cast_loop", true)
        end,
        timeline =
        {
            TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast")
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast_ocean")
                inst.sg:RemoveStateTag("prefish")
                inst:PerformBufferedAction()
            end),
        },
        events =
        {
            EventHandler("newfishingtarget", function(inst, data)
                if data and data.target and not data.target:HasTag("projectile") then
                    inst.sg.statemem.hooklanded = true
                    inst.AnimState:PushAnimation("fishing_ocean_cast_pst", false)
                end
            end),

            EventHandler("animqueueover", function(inst)
                if inst.sg.statemem.hooklanded and inst.AnimState:AnimDone() then
                    inst.sg:GoToState("oceanfishing_idle")
                end
            end),
        },
    },

    State {
        name = "oceanfishing_idle",
        tags = { "fishing", "canrotate" },

        onenter = function(inst)
            inst:AddTag("fishing_idle")
            local rod = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local target = (rod and rod.components.oceanfishingrod) and rod.components.oceanfishingrod.target or nil
            if target and target.components.oceanfishinghook and TUNING.OCEAN_FISHING.IDLE_QUOTE_TIME_MIN > 0 then
                inst.sg:SetTimeout(TUNING.OCEAN_FISHING.IDLE_QUOTE_TIME_MIN + math.random() * TUNING.OCEAN_FISHING.IDLE_QUOTE_TIME_VAR)
            end
        end,
        onupdate = function(inst)
            local rod = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            rod = (rod and rod.components.oceanfishingrod) and rod or nil
            local target = rod and rod.components.oceanfishingrod.target or nil
            if target then
                if target.components.oceanfishinghook then
                    inst.SoundEmitter:KillSound("unreel_loop")
                    if not inst.AnimState:IsCurrentAnimation("hooked_loose_idle") then
                        inst.AnimState:PlayAnimation("hooked_loose_idle", true)
                    end
                else
                    if rod.components.oceanfishingrod:IsLineTensionLow() then
                        inst.SoundEmitter:KillSound("unreel_loop")
                        if not inst.AnimState:IsCurrentAnimation("hooked_loose_idle") then
                            inst.AnimState:PlayAnimation("hooked_loose_idle", true)
                        end
                    elseif rod.components.oceanfishingrod:IsLineTensionGood() then
                        if target.components.oceanfishable and target.components.oceanfishable:IsStruggling() then
                            if not inst.SoundEmitter:PlayingSound("unreel_loop") then
                                inst.SoundEmitter:PlaySound("dontstarve/common/fishpole_strain", "unreel_loop")
                            end
                            inst.SoundEmitter:SetParameter("unreel_loop", "tension", 0.0)
                        else
                            inst.SoundEmitter:KillSound("unreel_loop")
                        end
                        if not inst.AnimState:IsCurrentAnimation("hooked_good_idle") then
                            inst.AnimState:PlayAnimation("hooked_good_idle", true)
                        end
                    else
                        if not inst.SoundEmitter:PlayingSound("unreel_loop") then
                            inst.SoundEmitter:PlaySound("dontstarve/common/fishpole_strain", "unreel_loop")
                        end
                        inst.SoundEmitter:SetParameter("unreel_loop", "tension", 1.0)
                        if not inst.AnimState:IsCurrentAnimation("hooked_tight_idle") then
                            inst.AnimState:PlayAnimation("hooked_tight_idle", true)
                        end
                    end
                end
            end
        end,
        onexit = function(inst)
            inst.SoundEmitter:KillSound("unreel_loop")
            inst:RemoveTag("fishing_idle")
        end,
    },

    State {
        name = "oceanfishing_reel",
        tags = { "fishing", "doing", "reeling", "canrotate" },

        onenter = function(inst)
            inst:AddTag("fishing_idle")
            inst.components.locomotor:Stop()

            local rod = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            rod = (rod and rod.components.oceanfishingrod) and rod or nil
            local target = rod and rod.components.oceanfishingrod.target or nil
            if target == nil then
                inst:ClearBufferedAction()
            else
                if inst:PerformBufferedAction() then
                    if target.components.oceanfishinghook or rod.components.oceanfishingrod:IsLineTensionLow() then
                        inst.SoundEmitter:KillSound("reel_loop")
                        inst.SoundEmitter:PlaySound("dontstarve/common/fishpole_reel_in1_LP", "reel_loop")
                        if not inst.AnimState:IsCurrentAnimation("hooked_loose_reeling") then
                            inst.AnimState:PlayAnimation("hooked_loose_reeling", true)
                        end
                    elseif rod.components.oceanfishingrod:IsLineTensionGood() then
                        inst.SoundEmitter:KillSound("reel_loop")
                        inst.SoundEmitter:PlaySound("dontstarve/common/fishpole_reel_in2_LP", "reel_loop")
                        if not inst.AnimState:IsCurrentAnimation("hooked_good_reeling") then
                            inst.AnimState:PlayAnimation("hooked_good_reeling", true)
                        end
                    else
                        inst.SoundEmitter:KillSound("reel_loop")
                        inst.SoundEmitter:PlaySound("dontstarve/common/fishpole_reel_in3_LP", "reel_loop")
                        if not inst.AnimState:IsCurrentAnimation("hooked_tight_reeling") then
                            inst.AnimState:PlayAnimation("hooked_tight_reeling", true)
                        end
                    end

                    inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
                end

            end
        end,
        timeline =
        {
            TimeEvent(TUNING.OCEAN_FISHING.REEL_ACTION_REPEAT_DELAY, function(inst) inst.sg.statemem.allow_repeat = true end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("oceanfishing_idle")
        end,
        onexit = function(inst)
            inst.SoundEmitter:KillSound("reel_loop")
            inst:RemoveTag("fishing_idle")
        end,
    },

    State {
        name = "oceanfishing_sethook",
        tags = { "fishing", "doing", "busy" },
        onenter = function(inst)
            inst:AddTag("fishing_idle")
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("fishing_ocean_bite_heavy_pre")
            inst.AnimState:PushAnimation("fishing_ocean_bite_heavy_loop", false)

            inst:PerformBufferedAction()
        end,
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("oceanfishing_idle") end),
        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("sethook_loop")
            inst:RemoveTag("fishing_idle")
        end,
    },

    State {
        name = "oceanfishing_catch",
        tags = { "fishing", "catchfish", "busy" },
        onenter = function(inst, build)
            inst.AnimState:PlayAnimation("fishing_ocean_catch")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("fish01")
        end,
    },

    State {
        name = "oceanfishing_stop",
        tags = { "fishing" },
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_ocean_pst")
        end,
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "oceanfishing_linesnapped",
        tags = { "busy", "nomorph" },
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("line_snap")
            inst.sg.statemem.escaped_str = data and data.escaped_str or nil
        end,
        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_linebreak")
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "jumpin_pre",
        tags = { "doing", "busy", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_pre", false)
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.bufferedaction then
                        inst:PerformBufferedAction()
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },
    },

    State {
        name = "pocketwatch_portal_land",
        tags = { "busy", "nopredict", "nomorph", "nodangle", "jumping", "noattack" },
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            StartTeleporting(inst)

            inst.AnimState:PlayAnimation("jumpportal_out")

            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("pocketwatch_portal_exit_fx")
            fx.Transform:SetPosition(x, 4, z)
        end,
        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst:Show() -- hidden by StartTeleporting
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("wanda1/wanda/jump_whoosh")
            end),
            TimeEvent(20 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
            TimeEvent(22 * FRAMES, function(inst)
                PlayFootstep(inst)
            end),
            TimeEvent(28 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("jumping")
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nomorph")
                inst.sg:RemoveStateTag("noattack")

                DoneTeleporting(inst)
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            if inst.sg.statemem.isteleporting then
                DoneTeleporting(inst)
            end
        end,
    },

    State {
        name = "pocketwatch_portal_fallout",
        tags = { "busy", "nopredict", "nomorph", "nodangle", "jumping", "noattack" },
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            StartTeleporting(inst)

            inst.AnimState:PlayAnimation("jumpportal2_out")
            inst.AnimState:PushAnimation("jumpportal2_out_pst", false)

            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("pocketwatch_portal_exit_fx")
            fx.Transform:SetPosition(x, 4, z)
        end,
        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst:Show() -- hidden by StartTeleporting
            end),
            TimeEvent(19 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("wanda1/wanda/jump_whoosh")
            end),
            TimeEvent(23 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
            TimeEvent(27 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
            TimeEvent(59 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("jumping")
                inst.sg:RemoveStateTag("busy")
                DoneTeleporting(inst)
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            if inst.sg.statemem.isteleporting then
                DoneTeleporting(inst)
            end
        end,
    },

    State {
        name = "pocketwatch_warpback_pre",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pocketwatch_warp")
            inst.sg.statemem.stafffx = SpawnPrefab("pocketwatch_warpback_fx")
            inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
            inst.sg.statemem.stafffx:SetUp({ 1, 1, 1 })
        end,
        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/warp") end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg.statemem.stafffx then
                        inst.sg.statemem.stafffx.entity:SetParent(nil)
                        inst.sg.statemem.stafffx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst.sg.statemem.stafffx = nil
                    end
                    inst:Remove()
                end
            end),
        },
    },
}

local hop_timelines =
{
    hop_pre =
    {
        TimeEvent(0, function(inst)
            inst.components.embarker.embark_speed = math.clamp(inst.components.locomotor:RunSpeed() * inst.components.locomotor:GetSpeedMultiplier() + TUNING.WILSON_EMBARK_SPEED_BOOST, TUNING.WILSON_EMBARK_SPEED_MIN, TUNING.WILSON_EMBARK_SPEED_MAX)
        end),
    },
    hop_loop =
    {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
        end),
    },
}

local function landed_in_water_state(inst)
    return (inst.components.drownable and inst.components.drownable:ShouldDrown() and "sink") or nil
end

local hop_anims = { pre = "boat_jump_pre", loop = "boat_jump_loop", pst = "boat_jump_pst" }

CommonStates.AddHopStates(states, true, hop_anims, hop_timelines, "turnoftides/common/together/boat/jump_on", landed_in_water_state, {start_embarking_pre_frame = 4*FRAMES})

return StateGraph("wanda_clone", states, events, "idle", actionhandlers)