-- CC : set Were Transforming UI cooldown >> [Reward] expertwoodie1
if not chasni_getperkexcludeconfig("expertwoodie1") then
    local function ExpertWoodie1_getWereCD(inst, wereform)
        local timer = inst.components.timer:GetTimeLeft("werecd"..wereform) or 0
        local maxcd = TUNING.EXPERT_WOODIE1_COOLDOWN[wereform]
        return (maxcd - timer) / maxcd
    end

    local function ExpertWoodie1_ontimerdone(inst, data)
        if data.name == "werecdgoose" then
            inst.net_goosecd:set(1)
        elseif data.name == "werecdbeaver" then
            inst.net_beavercd:set(1)
        elseif data.name == "werecdmoose" then
            inst.net_moosecd:set(1)
        end
    end

    AddPrefabPostInit("woodie", function(inst)
        inst.net_goosecd = GLOBAL.net_float(inst.GUID, "woodie.goosecd", "goosecddirty")
        inst.net_beavercd = GLOBAL.net_float(inst.GUID, "woodie.beavercd", "beavercddirty")
        inst.net_moosecd = GLOBAL.net_float(inst.GUID, "woodie.moosecd", "moosecddirty")

        if TheNet:GetIsServer() then
            if inst.components.timer == nil then
                inst:AddComponent("timer")
            end
            inst:ListenForEvent("timerdone", ExpertWoodie1_ontimerdone)
            inst.getWereCD = ExpertWoodie1_getWereCD
            local old_OnLoad = inst.OnLoad
            inst.OnLoad = function(inst, data, ...)
                inst.net_goosecd:set(inst:getWereCD("goose"))
                inst.net_beavercd:set(inst:getWereCD("beaver"))
                inst.net_moosecd:set(inst:getWereCD("moose"))
                old_OnLoad(inst, data, ...)
            end
        end
    end)
end

-- CC : add edible log and log eater >> [Reward] expertwoodie2
if not chasni_getperkexcludeconfig("expertwoodie2") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("woodie", function(inst)
            if inst.components.eater then
                local old_OnEat = inst.components.eater.oneatfn
                local _onEat = function(inst, food, ...)
                    if old_OnEat then
                        old_OnEat(inst, food, ...)
                    end
                    if food and food.components.edible then
                        if food.components.edible.foodtype == FOODTYPE.WOOD then
                            local hunger_delta = 0
                            local sanity_delta = 0
                            local health_delta = 0
                            if food.prefab == "log" then
                                hunger_delta = inst.components.hunger:IsStarving() and 10 or 2.5
                            elseif food.prefab == "driftwood_log" then
                                sanity_delta = inst.components.sanity:IsInsane() and 50 or 15
                            elseif food.prefab == "boards" then
                                hunger_delta = inst.components.hunger:IsStarving() and 20 or 10
                            elseif food.prefab == "livinglog" then
                                sanity_delta = -100
                                health_delta = 50
                            end
                            inst.components.hunger:DoDelta(hunger_delta)
                            inst.components.sanity:DoDelta(sanity_delta)
                            inst.components.health:DoDelta(health_delta, nil, food.prefab)
                        end
                    end
                end
                if inst.components.eater then
                    inst.components.eater:SetOnEatFn(_onEat)
                    table.insert(inst.components.eater.preferseating, FOODTYPE.WOOD)
                    table.insert(inst.components.eater.caneat, FOODTYPE.WOOD)
                end
            end
        end)
    end
end

-- CC : stronger wereform >> [Reward] expertwoodie3 [RoG] Axe_axe woodie were effect
if not chasni_getperkexcludeconfig("bosshunting") then
    local TAUNT_DIST = 7
    local TAUNT_TICK = 12
    local TAUNT_MUST_TAGS = { "_combat", "locomotor" }
    local TAUNT_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "player", "companion", "notaunt" }
    local PICKUP_TICK = 0.5
    local CULLING_BLADE_THRESHOLD = 0.05
    local function beaverperiodictask(inst)
        local item = FindPickupableItem(inst, 5, false)
        if item and inst:HasTag("beaver") then
            local didpickup = false
            if item.components.trap then
                item.components.trap:Harvest(inst)
                didpickup = true
            end

            if inst.components.minigame_participator then
                local minigame = inst.components.minigame_participator:GetMinigame()
                if minigame then
                    minigame:PushEvent("pickupcheat", { cheater = inst, item = item })
                end
            end
            SpawnPrefab("lucy_transform_fx").Transform:SetPosition(item.Transform:GetWorldPosition())

            if not didpickup then
                local item_pos = item:GetPosition()
                if item.components.stackable then
                    item = item.components.stackable:Get()
                end

                inst.components.inventory:GiveItem(item, nil, item_pos)
            end
        end
    end
    local function mooseonhitother(inst, data)
        local target = data.target
        if target and target:HasTag("epic") and target.components.health:GetPercent() < CULLING_BLADE_THRESHOLD and not target._mooseaxeboost then
            if inst and inst.components.levelsystem and inst:HasTag("weremoose") then
                local increased = inst.components.levelsystem:absorblevelpick(inst, true)
                if increased then
                    inst.SoundEmitter:PlaySound("axe/axe/culling")
                    target._mooseaxeboost = true
                end
            end
        end
    end
    local function IsTauntable(inst, target)
        return target.components.combat and not target.components.combat:TargetIs(inst) and target.components.combat:CanTarget(inst)
    end
    local function gooseperiodictask(inst)
        if not inst.components.health:IsDead() and inst:HasTag("weregoose") then
            local x, y, z = inst.Transform:GetWorldPosition()
            chasni_spawnprefab("bramblefx_ring", x, y, z)
            inst.SoundEmitter:PlaySound("axe/axe/call")
            for i, v in ipairs(TheSim:FindEntities(x, y, z, TAUNT_DIST, TAUNT_MUST_TAGS, TAUNT_CANT_TAGS)) do
                if IsTauntable(inst, v) then
                    v.components.combat:SetTarget(inst)
                end
            end
        end
    end
    local function resetaxeaxe(inst)
        if inst._axetask then
            inst._axetask:Cancel()
            inst._axetask = nil
        end
        inst:RemoveEventCallback("onhitother", mooseonhitother)
    end
    if TheNet:GetIsServer() then
        AddPrefabPostInit("woodie", function(inst)
            local function beaverbonusdamagefn(inst, target, damage, weapon)
                return inst:HasTag("beaver") and (target:HasTag("tree") or target:HasTag("beaverchewable")) and target.components.health and target.components.health.currenthealth or 0
            end
            local function moosebonusdamagefn(inst, target, damage, weapon)
                return inst:HasTag("weremoose") and target.components.health and target.components.health:GetPercent() < 0.08 and target.components.health.currenthealth or 0
            end
            local transformevent = function(inst, data, forced)
                inst.components.combat.externaldamagemultipliers:RemoveModifier("mooseperkbuff")
                inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("mooseperkbuff")
                inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "gooseperkbuff")
                resetaxeaxe(inst)
                if inst.components.allachivcoin and inst.components.allachivcoin.expertwoodie3 then
                    inst:DoTaskInTime(1, function()
                        local level = inst.components.levelsystem and inst.components.levelsystem.level or 0
                        resetaxeaxe(inst)
                        if (data and data.mode == "beaver" or forced) and inst:HasTag("beaver") then
                            inst.components.sanity.custom_rate_fn = function() return 0 end
                            local bonus = level * 2
                            inst.components.temperature.inherentinsulation = TUNING.INSULATION_LARGE + bonus
                            inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_LARGE + bonus
                            inst.components.combat.bonusdamagefn = beaverbonusdamagefn
                            if inst.components.inventory:FindItem(function(item) return item.prefab == "axe_axe" end) then
                                inst._axetask = inst:DoPeriodicTask(PICKUP_TICK, beaverperiodictask)
                            end
                        elseif (data and data.mode == "moose" or forced) and inst:HasTag("weremoose") then
                            inst.components.sanity.custom_rate_fn = function() return 0 end
                            local bonus = level * 0.001
                            inst.components.combat.externaldamagemultipliers:SetModifier("mooseperkbuff", 1 + bonus)
                            inst.components.combat.externaldamagetakenmultipliers:SetModifier("mooseperkbuff", 1 - math.min(bonus, 0.2))
                            if inst.components.inventory:FindItem(function(item) return item.prefab == "axe_axe" end) then
                                inst.components.combat.bonusdamagefn = moosebonusdamagefn
                                inst:ListenForEvent("onhitother", mooseonhitother)
                            end
                        elseif (data and data.mode == "goose" or forced) and inst:HasTag("weregoose") then
                            inst.components.sanity.custom_rate_fn = function() return 0 end
                            local bonus = math.min(level * 0.01, 1)
                            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "gooseperkbuff", 1 + bonus)
                            if inst.components.inventory:FindItem(function(item) return item.prefab == "axe_axe" end) then
                                inst._axetask = inst:DoPeriodicTask(TAUNT_TICK, gooseperiodictask)
                            end
                        end
                    end)
                end

            end
            local detransformevent = function(inst)
                inst:DoTaskInTime(1, function()
                    resetaxeaxe(inst)
                    inst.components.combat.externaldamagemultipliers:RemoveModifier("mooseperkbuff")
                    inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("mooseperkbuff")
                    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "gooseperkbuff")
                end)
            end
            inst:ListenForEvent("transform_wereplayer", function(i, data) transformevent(i, data, false) end)
            inst:ListenForEvent("ms_respawnedfromghost", function(i, data) transformevent(i, data, true) end)
            inst:ListenForEvent("transform_person", detransformevent)
            inst:ListenForEvent("ms_becameghost", detransformevent)
        end)
    end
end

