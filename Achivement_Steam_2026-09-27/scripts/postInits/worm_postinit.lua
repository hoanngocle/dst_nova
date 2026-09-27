-- CC : wormwood new item logic >> [Reward] expertworm1
if not chasni_getperkexcludeconfig("expertworm1") then
    -- CC : bloomness delay with nature_hat >> [Reward] expertworm1
    AddComponentPostInit("bloomness", function(self)
        local _OnUpdate = self.OnUpdate
        self.OnUpdate = function(_self, dt)
            if not _self.inst.components.inventory:EquipHasTag("nature_hat") then
                _OnUpdate(_self, dt)
            end
        end
    end)

    -- CC : set always nohasslers while using nature_hat >> [Reward] expertworm1
    AddComponentPostInit("areaaware", function(self)
        local _CurrentlyInTag = self.CurrentlyInTag
        self.CurrentlyInTag = function(_self, tag, ...)
            if _self.inst.components.inventory and _self.inst.components.inventory:EquipHasTag("nature_hat") and tag == "nohasslers" then
                return true
            end
            return _CurrentlyInTag(_self, tag, ...)
        end
    end)
end
-- CC : add fertilizer logic >> [Reward] expertworm2
if not chasni_getperkexcludeconfig("expertworm2") then
    -- CC : add self fertilize additional effect >> [Reward] expertworm2
    if TheNet:GetIsServer() then
        AddPrefabPostInit("wormwood", function(inst)
            local old_onfertlizedfn = inst.components.fertilizable.onfertlizedfn
            if old_onfertlizedfn then
                inst.components.fertilizable.onfertlizedfn = function(_inst, fertilizer_obj, ...)
                    if _inst.components.allachivcoin.expertworm2 and fertilizer_obj then
                        local chance = 0.2
                        if fertilizer_obj.prefab == "poop" then
                            if _inst.components.sanity then _inst.components.sanity:DoDelta(5) end
                        elseif fertilizer_obj.prefab == "fertilizer" then
                            _inst:AddDebuff("wormwood_sanity_buff", "wormwood_sanity_buff")
                            chance = 0.05
                        elseif fertilizer_obj.prefab == "guano" then
                            _inst:AddDebuff("wormwood_speed_buff", "wormwood_speed_buff")
                            chance = 0.4
                        elseif fertilizer_obj.prefab == "compost" then
                            if _inst.components.hunger then _inst.components.hunger:DoDelta(2.5) end
                            chance = 0.3
                        elseif fertilizer_obj.prefab == "compostwrap" then
                            _inst:AddDebuff("wormwood_hunger_buff", "wormwood_hunger_buff")
                            chance = 0.5
                        elseif fertilizer_obj.prefab == "spoiled_food" then
                            _inst:AddDebuff("wormwood_attack_buff", "wormwood_attack_buff")
                        elseif fertilizer_obj.prefab == "rottenegg" then
                            _inst:AddDebuff("wormwood_poop_shield_buff", "wormwood_poop_shield_buff")
                            chance = 0.7
                        elseif fertilizer_obj.prefab == "spoiled_fish_small" then
                            if _inst.components.moisture then _inst.components.moisture:SetMoistureLevel(0) end
                            chance = 0.6
                        elseif fertilizer_obj.prefab == "spoiled_fish" then
                            _inst:AddDebuff("wormwood_moisture_buff", "wormwood_moisture_buff")
                            chance = 0.8
                        elseif fertilizer_obj.prefab == "glommerfuel" then
                            _inst:AddDebuff("wormwood_glow_buff", "wormwood_glow_buff")
                            chance = 1
                        elseif fertilizer_obj.prefab == "treegrowthsolution" then
                            if _inst.components.sanity then _inst.components.sanity:DoDelta(30) end
                            if _inst.components.hunger then _inst.components.hunger:DoDelta(25) end
                            if _inst.components.health then _inst.components.health:DoDelta(20) end
                            chance = 1
                        elseif fertilizer_obj.prefab == "soil_amender" then
                            _inst._wormwood_soil_amender = (_inst._wormwood_soil_amender or 0) + 1
                            chance = 1
                        elseif fertilizer_obj.prefab == "soil_amender_fermented" then
                            _inst._wormwood_soil_amender = (_inst._wormwood_soil_amender or 0) + 1
                            chance = 1
                        end
                        if _inst.components.inventory and math.random() < chance then
                            chasni_giveItem(_inst, "seeds", 1)
                        end
                    end
                    return old_onfertlizedfn(_inst, fertilizer_obj, ...)
                end
            end
        end)
    end

    -- CC : add wormwood_soil_amender auto grow plants >> [Reward] expertworm2
    if TheNet:GetIsServer() then
        local function farmplantpostinit(inst)
            inst:ListenForEvent("on_planted", function(_inst, data)
                if data and data.doer and data.doer._wormwood_soil_amender and data.doer._wormwood_soil_amender > 0 and _inst.components.growable then
                    _inst.components.growable:DoMagicGrowth()
                    data.doer._wormwood_soil_amender = (data.doer._wormwood_soil_amender or 0) - 1
                    if data.doer._wormwood_soil_amender <= 0 then
                        data.doer._wormwood_soil_amender = nil
                    end
                end
            end)
        end

        for _, v in pairs(farmplantlist) do
            AddPrefabPostInit(v, farmplantpostinit)
        end
    end

    -- CC : add fertilize by hand to wormwood >> [Reward] expertworm2
    local function results(data, ...)
        return type(data) == "function" and {data(...)} or type(data) == "table" and data or {data}
    end

    local function insertinto(func, ante, post)
        return function(...)
            local res = results(ante, ...)
            if #res > 0 then return GLOBAL.unpack(res) end

            local results_original = results(func, ...)

            local results_post = results(post, ...)
            if #results_post > 0 then return GLOBAL.unpack(results_post) end

            return GLOBAL.unpack(results_original)
        end
    end

    local function overwrite(table, name, ante, post)
        if type(table) ~= "table" then return end
        local old = table[name]
        table[name] = insertinto(old, ante, post)
    end

    AddComponentAction("SCENE", "pickable", function(inst, doer, actions, right)
        if doer:HasTag("expertworm2") and inst:HasTag("barren") and right then
            table.insert(actions, ACTIONS.FERTILIZE)
        end
    end)

    for sg, _ in pairs{
        wilson = true,
        wilson_client = false
    } do
        AddStategraphPostInit(sg, function(self)
            for act, func in pairs{
                FERTILIZE = fertilize and function(inst, _act)
                    if not _act.invobject and inst:HasTag("expertworm2") then
                        return "dolongaction"
                    end
                end or nil,
            } do overwrite(self.actionhandlers[ACTIONS[act]], "deststate", func) end
        end)
    end

    overwrite(ACTIONS.FERTILIZE, "fn", function(act)
        if act.invobject == nil and act.doer:HasTag("expertworm2") then
            local x, y, z = act.target.Transform:GetWorldPosition()

            local poop = SpawnPrefab("poop")
            poop.Transform:SetPosition(x, y, z)
            poop:Hide()
            poop:DoTaskInTime(0, poop.Remove)

            local farm_plant_happy = SpawnPrefab("farm_plant_happy")
            farm_plant_happy.Transform:SetPosition(x, y, z)

            if act.doer.components.talker then
                act.doer.sg:AddStateTag("idle")
                act.doer.components.talker:Say(GetString(act.doer, "ANNOUNCE_TALK_TO_PLANTS"))
            end

            act.invobject = poop
        end
    end)
end
