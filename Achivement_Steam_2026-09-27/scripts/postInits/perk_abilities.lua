local UpvalueHacker = require "functions/upvaluehacker"

-- CC : set IsForceDry always true >> [Reward] nomoist
if not chasni_getperkexcludeconfig("nomoist") then
    AddComponentPostInit("moisture", function(Moisture)
        local _IsForceDry = Moisture.IsForceDry
        Moisture.IsForceDry = function(self)
            return (_IsForceDry and _IsForceDry(self)) or (self.inst.components.allachivcoin and self.inst.components.allachivcoin.nomoist)
        end
    end)
end

-- CC : SetTemperature changes >> [Reward] icemaster & firemaster
if not chasni_getperkexcludeconfig("icemaster", "firemaster") then
    AddComponentPostInit("temperature", function(temperature)
        local _SetTemperature = temperature.SetTemperature
        temperature.SetTemperature = function(self, value, ...)
            if self.inst.components.allachivcoin then
                if self.inst.components.allachivcoin.icemaster and value < 5 then
                    value = 5
                end
                local maxheattemp = temperature.overheattemp - 5
                if self.inst.components.allachivcoin.firemaster and value > maxheattemp then
                    value = maxheattemp
                end
            end
            return _SetTemperature(self, value, ...)
        end
    end)
end

-- CC : set dest action for PICK >> [Reward] fastworker
if not chasni_getperkexcludeconfig("fastworker") then
    local FASTWORKER_EXCEPTION_PREFABS = {
        junk_pile = true,
        junk_pile_big = true,
        junk_pile_side = true,
    }
    local function SetFastWorkerDestState(inst, action, originalDestState)
        inst.actionhandlers[action].deststate = function(_inst, _action, ...)
            if _inst and _inst.currentfastworker and _inst.currentfastworker:value() == 1 then
                local result
                if type(originalDestState) == "string" then
                    result = originalDestState
                else
                    result = originalDestState(_inst, _action, ...)
                end

                -- exception prefabs
                if _action.target ~= nil and FASTWORKER_EXCEPTION_PREFABS[_action.target.prefab] then
                    return result
                end

                if result == "dolongaction" then
                    return "doshortaction"
                else
                    return result
                end
            end

            if type(originalDestState) == "string" then
                return originalDestState
            else
                return originalDestState(_inst, _action, ...)
            end
        end
    end
    AddStategraphPostInit("wilson", function(inst)
        SetFastWorkerDestState(inst, ACTIONS.PICK, inst.actionhandlers[ACTIONS.PICK].deststate)
        SetFastWorkerDestState(inst, ACTIONS.TAKEITEM, inst.actionhandlers[ACTIONS.TAKEITEM].deststate)
        SetFastWorkerDestState(inst, ACTIONS.HARVEST, inst.actionhandlers[ACTIONS.HARVEST].deststate)
    end)
    GLOBAL.package.loaded["stategraphs/SGwilson"] = nil
end

-- CC : double healer heal >> [Reward] doublehealed
if not chasni_getperkexcludeconfig("doublehealed") then
    AddComponentPostInit("healer", function(self)
        local _Heal = self.Heal
        self.Heal = function(_self, target, doer, ...)
            local originheal = _self.health
            if target.components.allachivcoin and target.components.allachivcoin.doublehealed then
                _self.health = originheal * 2
            end
            if doer.components.allachivcoin and doer.components.allachivcoin.doublehealed then
                _self.health = originheal * 2
            end
            local active = _Heal(_self, target, doer, ...)
            _self.health = originheal
            return active
        end
    end)
end

-- CC : half loot dropped from Cut Corners for pocketwatch >> [Reward] buildcheaper
if not chasni_getperkexcludeconfig("buildcheaper") then
    local function halfLoot(arr)
        local counts = {}
        for _, value in ipairs(arr) do
            counts[value] = (counts[value] or 0) + 1
        end

        local result = {}
        for value, count in pairs(counts) do
            local reduced_count = math.max(math.floor(count / 2), 1)
            for _ = 1, reduced_count do
                table.insert(result, value)
            end
        end
        return result
    end

    AddComponentPostInit("lootdropper", function(lootdropper)
        local _GetFullRecipeLoot = lootdropper.GetFullRecipeLoot
        lootdropper.GetFullRecipeLoot = function(self, target, ...)
            local loot = _GetFullRecipeLoot(self, target, ...)
            if lootdropper._chasni_buildcheaper then
                return halfLoot(loot)
            end
            return loot
        end

        local _OnSave = lootdropper.OnSave
        lootdropper.OnSave = function(self, ...)
            local data = _OnSave and _OnSave(self, ...) or {}
            local chasni_buildcheaper = lootdropper._chasni_buildcheaper
            data._chasni_buildcheaper = chasni_buildcheaper
            return data
        end

        local _OnLoad = lootdropper.OnLoad
        lootdropper.OnLoad = function(self, data, ...)
            if _OnLoad then
                _OnLoad(self, data, ...)
            end
            self._chasni_buildcheaper = data._chasni_buildcheaper or false
        end
    end)

    if TheNet:GetIsServer() then
        AddPrefabPostInitAny(function(watch)
            if watch and watch:HasTag("pocketwatch") then
                local _OnBuiltFn = watch.OnBuiltFn
                watch.OnBuiltFn = function(inst, builder, ...)
                    if _OnBuiltFn then
                        _OnBuiltFn(inst, builder, ...)
                    end
                    if builder.components.allachivcoin and builder.components.allachivcoin.buildcheaper then
                        if inst.components.lootdropper then
                            inst.components.lootdropper._chasni_buildcheaper = true
                        end
                    end
                end
            end
        end)
    end
end

-- CC : add trinketslot >> [Reward] trinketowner
if not chasni_getperkexcludeconfig("trinketowner") then
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            inst:AddComponent("trinketowner")
        end)
    end
end

-- CC : add critter logic >> [Perk] supercritter
if not chasni_getperkexcludeconfig("supercritter") then
    -- CC : add "petleash" _supercritter_ tagging >> [Perk] supercritter
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            if inst.components.petleash then
                local old_OnSpawnFn = inst.components.petleash.onspawnfn
                inst.components.petleash:SetOnSpawnFn(function(owner, pet, ...)
                    if pet:HasTag("critter") then
                        owner:AddTag("_supercritter_"..pet.prefab)
                    end
                    if old_OnSpawnFn then
                        return old_OnSpawnFn(owner, pet, ...)
                    end
                end)
                local old_OnDespawnFn = inst.components.petleash.ondespawnfn
                inst.components.petleash:SetOnDespawnFn(function(owner, pet, ...)
                    if pet:HasTag("critter") then
                        owner:RemoveTag("_supercritter_"..pet.prefab)
                    end
                    if old_OnDespawnFn then
                        return old_OnDespawnFn(owner, pet, ...)
                    end
                end)
                local old_OnRemovedFn = inst.components.petleash.onpetremoved
                inst.components.petleash:SetOnRemovedFn(function(owner, pet, ...)
                    if pet:HasTag("critter") then
                        owner:RemoveTag("_supercritter_"..pet.prefab)
                    end
                    if old_OnRemovedFn then
                        return old_OnRemovedFn(owner, pet, ...)
                    end
                end)
            end
        end)
    end

    -- CC : toggle "critter" _supercritter_ tagging on hungry >> [Perk] supercritter
    if TheNet:GetIsServer() then
        local function crittertagtoggle(Critter)
            Critter:ListenForEvent("perishchange", function(inst, data)
                local leader = inst.components.follower and inst.components.follower:GetLeader()
                if leader == nil then
                    return
                end
                if data and data.percent > 0.5 then
                    leader:AddTag("_supercritter_"..inst.prefab)
                    if leader and leader.components.allachivcoin and leader.components.allachivcoin.supercritter then
                        if not inst:HasDebuff("super_critter_buff") then
                            inst:AddDebuff("super_critter_buff", "super_critter_buff")
                        end
                    end
                else
                    leader:RemoveTag("_supercritter_"..inst.prefab)
                    if inst:HasDebuff("super_critter_buff") then
                        inst:RemoveDebuff("super_critter_buff")
                    end
                end
            end)
        end
        AddPrefabPostInit("critter_kitten", crittertagtoggle)
        AddPrefabPostInit("critter_puppy", crittertagtoggle)
        AddPrefabPostInit("critter_lamb", crittertagtoggle)
        AddPrefabPostInit("critter_dragonling", crittertagtoggle)
        AddPrefabPostInit("critter_glomling", crittertagtoggle)
        AddPrefabPostInit("critter_perdling", crittertagtoggle)
        AddPrefabPostInit("critter_lunarmothling", crittertagtoggle)
        AddPrefabPostInit("critter_eyeofterror", crittertagtoggle)
        AddPrefabPostInit("critter_bulbin", crittertagtoggle)
        AddPrefabPostInit("critter_eets", crittertagtoggle)
    end

    -- CC : gain xp on cast staff || critter_kitten >> [Perk] supercritter
    AddComponentPostInit("staffsanity", function(staffsanity)
        local _DoCastingDelta = staffsanity.DoCastingDelta
        staffsanity.DoCastingDelta = function(self, amount, ...)
            if self.inst.components.allachivcoin and self.inst.components.allachivcoin.supercritter and self.inst.components.levelsystem then
                if self.inst:HasTag("_supercritter_critter_kitten") then
                    self.inst.components.levelsystem:xpDoDelta(1, self.inst, false, true)
                end
            end
            return _DoCastingDelta(self, amount, ...)
        end
    end)

    -- CC : deal extra damage onhitother || critter_dragonling >> [Perk] supercritter
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(player)
            player:ListenForEvent("onhitother", function(inst, data)
                if inst.components.allachivcoin and inst.components.allachivcoin.supercritter and data.target then
                    if inst:HasTag("_supercritter_critter_dragonling") then
                        chasni_spawnprefab("lavaarena_firebomb_explosion", 0, 0, 0, 1, 1, 1, inst.entity)
                        if data.target.components.health and not data.target.components.health:IsDead() and inst.components.levelsystem then
                            local dmg = inst.components.levelsystem.level * 0.1
                            data.target.components.health:DoDelta(-dmg)
                        end
                    end
                end
            end)
        end)
    end

    -- CC : regain sanity if crazy || critter_glomling >> [Perk] supercritter
    local REGEN_COOLDOWN = TUNING.TOTAL_DAY_TIME * 2
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(player)
            player._supercritter_critter_glomling_regen = function(inst)
                if (inst.components.sanity and not inst.components.sanity:IsInsane()) or (inst.components.timer and inst.components.timer:TimerExists("_supercritter_critter_glomling_cooldown")) then
                    return
                end
                local fx = chasni_spawnprefab("toadstool_cap_absorbfx", 0, 0, 0, 1, 1, 1, inst.entity)
                fx.AnimState:SetMultColour(219/255,1/255,1/255,1)
                if inst.components.sanity then
                    inst.components.sanity:SetPercent(1)
                end
                if inst.components.timer then
                    inst.components.timer:StartTimer("_supercritter_critter_glomling_cooldown", REGEN_COOLDOWN)
                end
            end
            player:ListenForEvent("timerdone", function(inst, data)
                if data.name == "_supercritter_critter_glomling_cooldown" then
                    inst:_supercritter_critter_glomling_regen()
                end
            end)
            player:ListenForEvent("goinsane", function(inst, data)
                if inst.components.allachivcoin and inst.components.allachivcoin.supercritter then
                    if inst:HasTag("_supercritter_critter_glomling") and inst._supercritter_critter_glomling_regen then
                        inst:_supercritter_critter_glomling_regen()
                    end
                end
            end)
        end)
    end

    -- CC : give speedboost when attacked || critter_perdling >> [Perk] supercritter
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(player)
            player:ListenForEvent("attacked", function(inst, data)
                if inst.components.allachivcoin and inst.components.allachivcoin.supercritter and data.attacker and data.attacker ~= inst then
                    if inst:HasTag("_supercritter_critter_perdling") then
                        if inst.components.health and not inst.components.health:IsDead() and inst.components.locomotor and inst.components.combat then
                            if inst._supercritter_critter_perdling_speedboost then
                                inst._supercritter_critter_perdling_speedboost:Cancel()
                                inst._supercritter_critter_perdling_speedboost = nil
                            end
                            inst._supercritter_critter_perdling_speedboost = inst:DoTaskInTime(4, function()
                                inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "supercritter_critter_perdling")
                                inst.components.combat.externaldamagemultipliers:RemoveModifier("supercritter_critter_perdling")
                            end)
                            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "supercritter_critter_perdling", 1.4)
                            inst.components.combat.externaldamagemultipliers:SetModifier("supercritter_critter_perdling", 0.6)
                        end
                    end
                end
            end)
        end)
    end

    -- CC : bonus loot when killing || critter_bulbin >> [Perk] supercritter
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(player)
            player:ListenForEvent("killed", function(killer, data)
                if killer.components.allachivcoin and killer.components.allachivcoin.supercritter and data.victim and data.victim:HasTag("epic") then
                    if killer:HasTag("_supercritter_critter_bulbin") and data.victim.components.lootdropper then
                        if chasni_isValidVictim(data.victim) then
                            data.victim.components.lootdropper:DropLoot()
                        end
                    end
                end
            end)
        end)
    end

    -- CC : make critter_eyeofterror spawn milkywhites || critter_eyeofterror >> [Perk] supercritter
    if TheNet:GetIsServer() then
        AddPrefabPostInit("critter_eyeofterror", function(Critter)
            Critter:DoPeriodicTask(TUNING.TOTAL_DAY_TIME * 0.5, function(inst)
                local leader = inst.components.follower and inst.components.follower:GetLeader()
                if leader and leader.components.allachivcoin and leader.components.allachivcoin.supercritter and leader:HasTag("_supercritter_critter_eyeofterror") then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    chasni_spawnprefab("milkywhites", x, y, z)
                end
            end)
        end)
    end

    -- CC : critter_eets make eater cant eat food on ground || critter_eets >> [Perk] supercritter
    AddComponentPostInit("eater", function(self)
        local oldCanEat = self.CanEat
        function self:CanEat(food, ...)
            local foodowner = food and food.components.inventoryitem and food.components.inventoryitem:GetGrandOwner()
            if food and foodowner == nil then
                local x, y, z = food.Transform:GetWorldPosition()
                local ents = FindPlayersInRange(x, y, z, 20, true)
                for _, v in ipairs(ents) do
                    if v.components.allachivcoin and v.components.allachivcoin.supercritter then
                        if v:HasTag("_supercritter_critter_eets") then
                            return false
                        end
                    end
                end
            end
            return oldCanEat(self, food, ...)
        end
    end)
end

-- CC : Using mastercookware | [Perk] warlychef
if not chasni_getperkexcludeconfig("warlychef") then
    local old_store_fn = ACTIONS.STORE.fn
    ACTIONS.STORE.fn = function(act)
        local retval1, retval2 = old_store_fn(act)
        if retval2 == "NOTMASTERCHEF" and act.doer.currentwarlychef and act.doer.currentwarlychef:value() == 1 then
            local target = act.target
            local proxy
            if target.components.container_proxy ~= nil then
                local master = target.components.container_proxy:GetMaster()
                if master ~= nil then
                    proxy = target
                    target = master
                end
            end

            if target.components.container ~= nil and act.invobject.components.inventoryitem ~= nil then
                if not target.components.container:IsOpenedBy(act.doer) then
                    if not target.components.container:CanOpen() then
                        return false, "INUSE"
                    end
                    target.components.container:Open(act.doer)
                end

                local item = act.invobject.components.inventoryitem:RemoveFromOwner(target.components.container.acceptsstacks)
                if item ~= nil then
                    if not target.components.container:GiveItem(item, nil, nil, false) then
                        act.doer.components.inventory:GiveItem(item)
                    end
                    return true
                end
            end
        end
        return retval1, retval2
    end
    local old_rummage_fn = ACTIONS.RUMMAGE.fn
    ACTIONS.RUMMAGE.fn = function(act)
        local retval1, retval2 = old_rummage_fn(act)
        if retval2 == "NOTMASTERCHEF" and act.doer.currentwarlychef and act.doer.currentwarlychef:value() == 1 then
            local targ = act.target or act.invobject
            if targ ~= nil and targ.components.container ~= nil then
                if not targ.components.container:IsOpenedBy(act.doer) and not targ.components.container:CanOpen() then
                    return false, "INUSE"
                end

                act.doer:PushEvent("opencontainer", { container = targ })
                targ.components.container:Open(act.doer)
                return true
            end
        end
        return retval1, retval2
    end

    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    local SCENE = COMPONENT_ACTIONS.SCENE
    local Scene_stewer = SCENE.stewer
    function SCENE.stewer(inst, doer, actions, right, ...)
        Scene_stewer(inst, doer, actions, right, ...)

        if not inst:HasTag("burnt") and not (doer.replica.rider and doer.replica.rider:IsRiding()) then
            if not inst:HasTag("donecooking") and right and (
                    (inst:HasTag("readytocook") and (inst:HasTag("mastercookware") and not doer:HasTag("masterchef") and doer.currentwarlychef:value() == 1)) and not
                    (inst.replica.container and inst.replica.container:IsFull() and inst.replica.container:IsOpenedBy(doer))
            ) then
                table.insert(actions, ACTIONS.COOK)
            end
        end
    end
end
