if not chasni_getperkexcludeconfig("duppercritter") then
    -- CC : Add 2nd critter logic to PetLeash >> [Reward] duppercritter
    AddComponentPostInit("petleash", function(PetLeash)
        PetLeash.chasni_onremovepet = function(pet, ...)
            if PetLeash.pets[pet] ~= nil then
                PetLeash.pets[pet] = nil
            end

            if PetLeash.onpetremoved ~= nil then
                PetLeash.onpetremoved(PetLeash.inst, pet)
            end
        end

        local function LinkPet(self, pet)
            self.pets[pet] = pet
            self.inst:ListenForEvent("onremove", self.chasni_onremovepet, pet)
            pet.persists = false

            if self.inst.components.leader ~= nil then
                self.inst.components.leader:AddFollower(pet)
            end
        end

        local _SpawnPetAt = PetLeash.SpawnPetAt
        function PetLeash:SpawnPetAt(x, y, z, prefaboverride, ...)
            if prefaboverride and string.sub(prefaboverride, 1, #"chasni_critter_") == "chasni_critter_" then
                self:Chasni_DespawnPetsWithTag("chasni_critter")
                local pet = SpawnPrefab(prefaboverride, nil, nil, self.inst.userid)
                if pet ~= nil then
                    LinkPet(self, pet)

                    if pet.Physics ~= nil then
                        pet.Physics:Teleport(x, y, z)
                    elseif pet.Transform ~= nil then
                        pet.Transform:SetPosition(x, y, z)
                    end

                    if self.onspawnfn ~= nil then
                        self.onspawnfn(self.inst, pet)
                    end
                end

                return pet
            end
            return _SpawnPetAt and _SpawnPetAt(self, x, y, z, prefaboverride, ...)
        end

        local _AttachPet = PetLeash.AttachPet
        function PetLeash:AttachPet(pet, ...)
            if pet:HasTag("chasni_critter") then
                if self:HasPetWithTag("chasni_critter") then
                    return false
                else
                    LinkPet(self, pet)
                    return true
                end
            end
            return _AttachPet and _AttachPet(self, pet, ...)
        end

        local _DetachPet = PetLeash.DetachPet
        function PetLeash:DetachPet(pet, ...)
            if pet:HasTag("chasni_critter") then
                if self.pets[pet] ~= nil then
                    self.pets[pet] = nil
                    self.inst:RemoveEventCallback("onremove", self._onremovepet, pet)
                    return
                end
            end
            return _DetachPet and _DetachPet(self, pet, ...)
        end

        function PetLeash:GetChasniCritter()
            for k, v in pairs(self.pets) do
                if v:HasTag("chasni_critter") then
                    return v
                end
            end
            return nil
        end

        function PetLeash:Chasni_DespawnPetsWithTag(tag)
            local toremove = {}
            for _, v in pairs(self.pets) do
                if v:HasTag(tag) then
                    table.insert(toremove, v)
                end
            end
            for _, pet in ipairs(toremove) do
                self:DespawnPet(pet)
                if tag == "chasni_critter" and self.inst and self.inst.components.craftedcritter and pet and pet.prefab then
                    local craftedcrittertagpattern = "^chasni_critter_(.*)"
                    local craftedcrittertag = string.match(pet.prefab, craftedcrittertagpattern)
                    if craftedcrittertag then
                        self.inst.components.craftedcritter:AddRecipe(craftedcrittertag)
                    end
                end
            end
            if self.inst and self.inst.components.levelsystem then
                self.inst.components.levelsystem:resetpet(self.inst)
            end

        end
    end)

    -- CC : Critter buff size logic >> [Reward] duppercritter
    AddComponentPostInit("debuffable", function(Debuffable)
        local _AddDebuff = Debuffable.AddDebuff
        function Debuffable:AddDebuff(name, ...)
            local debuffent = _AddDebuff and _AddDebuff(self, name, ...)
            if Debuffable.inst and Debuffable.inst:HasTag("chasni_critter") and name ~= "critter_turtle_buff_self" and name ~= "chasni_didgerizoo_buff" then
                local sx, sy, sz = Debuffable.inst.Transform:GetScale()
                debuffent.Transform:SetScale((1 / sx) * 0.5, (1 / sy) * 0.5, (1 / sz) * 0.5)
            end
            return debuffent
        end
    end)

    -- CC : free crafting ex-pet >> [Reward] duppercritter
    AddPlayerPostInit(function(inst)
        inst.craftedcritter = net_string(inst.GUID, "craftedcritter", "craftedcritter_dirty")
        inst.craftedcritter:set("")
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("craftedcritter")

        return inst
    end)

    AddPlayerPostInit(function(inst)
        local old_SaveForReroll = inst.SaveForReroll
        inst.SaveForReroll = function(...)
            local data = old_SaveForReroll and old_SaveForReroll(...) or {}

            if inst.components.craftedcritter then
                data.seamlessplayerswapper = data.seamlessplayerswapper or {}
                data.seamlessplayerswapper.craftedcritter = inst.components.craftedcritter:SaveForReroll()
            end

            return data
        end

        local old_LoadForReroll = inst.LoadForReroll
        inst.LoadForReroll = function(_inst, data, ...)
            if data and data.seamlessplayerswapper and data.seamlessplayerswapper.craftedcritter then
                if _inst.components.craftedcritter then
                    _inst.components.craftedcritter:LoadForReroll(data.seamlessplayerswapper.craftedcritter)
                end
            end

            return old_LoadForReroll and old_LoadForReroll(_inst, data, ...)
        end
    end)

    -- CC : Damage Reflect & Lifesteal (bluegem, greengem) >> [Reward] chasni_critter_atops Passive
    local  ATOPS_BLUEGEM_MULT = 0.5
    local  ATOPS_GREENGEM_MULT = 0.0001
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            inst:ListenForEvent("attacked", function(_inst, data)
                local pet = _inst.components.petleash and _inst.components.petleash:GetChasniCritter()
                if chasni_ispetname(pet, "atops") then
                    if (data and data.damageresolved and data.attacker and not data.redirected) then
                        if data.attacker.components.health and not data.attacker.components.health:IsDead() and data.attacker.components.combat then
                            local _, bluegemcount = _inst.components.inventory:Has("bluegem", 1)
                            local _, opalcount = _inst.components.inventory:Has("opalpreciousgem", 1)
                            local damage = bluegemcount + opalcount
                            if damage > 0 then
                                data.attacker.components.combat:GetAttacked(_inst, ATOPS_BLUEGEM_MULT * damage)
                            end
                        end
                    end
                end
            end)

            inst:ListenForEvent("onhitother", function(_inst, data)
                local pet = _inst.components.petleash and _inst.components.petleash:GetChasniCritter()
                if chasni_ispetname(pet, "atops") then
                    if data.damageresolved > 0 and _inst.components.health and not _inst.components.health:IsDead() and chasni_isLifeDrainable(data.target) then
                        local _, greengemcount = _inst.components.inventory:Has("greengem", 1)
                        local _, opalcount = _inst.components.inventory:Has("opalpreciousgem", 1)
                        local lifesteal = greengemcount + opalcount
                        if lifesteal > 0 then
                            _inst.components.health:DoDelta(data.damageresolved * lifesteal * ATOPS_GREENGEM_MULT, false, "lifesteal")
                        end
                    end
                end
            end)
        end)
    end
    -- CC : add LuckItem components (purplegem, yellowgem) >> [Reward] chasni_critter_atops Passive
    if TheNet:GetIsServer() then
        local function AddAtopsGemLuck(prefab, luckmult)
            local function GetLuckFn(inst, owner)
                local pet = owner.components.petleash and owner.components.petleash:GetChasniCritter()
                return chasni_ispetname(pet, "atops") and luckmult or 0
            end

            AddPrefabPostInit(prefab, function(inst)
                if inst.components.luckitem then
                    local oldluck = inst.components.luckitem.luck
                    inst.components.luckitem:SetLuck(function(_inst, owner)
                        return (oldluck and FunctionOrValue(oldluck, _inst, owner) or 0) + GetLuckFn(_inst, owner)
                    end)
                else
                    inst:AddComponent("luckitem")
                    inst.components.luckitem:SetLuck(GetLuckFn)
                end
            end)
        end
        local  ATOPS_PURPLEGEM_MULT = -0.01
        local  ATOPS_YELLOWGEM_MULT = 0.01
        AddAtopsGemLuck("purplegem", ATOPS_PURPLEGEM_MULT)
        AddAtopsGemLuck("yellowgem", ATOPS_YELLOWGEM_MULT)
        AddAtopsGemLuck("opalpreciousgem", ATOPS_YELLOWGEM_MULT)
    end

    -- CC : Cashback On builditem >> [Reward] chasni_critter_bug Passive
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            local function onitemcrafted(_inst, data)
                local pet = _inst.components.petleash and _inst.components.petleash:GetChasniCritter()
                if chasni_ispetname(pet, "bug") then
                    local chance = pet:calculatePassiveValue()
                    if math.random() * 100 < chance then
                        if data and data.recipe and data.recipe.ingredients and _inst.components.inventory then
                            local choices = {}
                            for _, ingredient in ipairs(data.recipe.ingredients) do
                                if ingredient.type ~= CHARACTER_INGREDIENT.HEALTH and ingredient.type ~= CHARACTER_INGREDIENT.SANITY and not ingredient.deconstruct and ingredient.amount > 0 then
                                    choices[ingredient.type] = ingredient.amount
                                end
                            end
                            local cashback_item = next(choices) and weighted_random_choice(choices) or nil
                            if cashback_item then
                                local prd = SpawnPrefab(cashback_item)
                                local pt = Vector3(pet.Transform:GetWorldPosition()) + Vector3(0,2,0)
                                prd.Transform:SetPosition(pt:Get())
                                local down = TheCamera and TheCamera:GetDownVec()
                                local angle = math.atan2(down.z, down.x) + (math.random()*60)*DEGREES
                                prd.Physics:SetVel(math.cos(angle), math.random(), math.sin(angle))
                            end
                        end
                    end
                end
            end

            inst:ListenForEvent("builditem", onitemcrafted)
            inst:ListenForEvent("buildstructure", onitemcrafted)
        end)
    end

    -- CC : Increase Wetness (mostly  for electric damage) >> [Reward] chasni_critter_fish_wet Passive
    if TheNet:GetIsServer() then
        AddPrefabPostInitAny(function(inst)
            if inst.GetWetMultiplier then
                local _GetWetMultiplier = inst.GetWetMultiplier
                inst.GetWetMultiplier = function(...)
                    local retval = _GetWetMultiplier(inst, ...)
                    local debuff = inst:GetDebuff("chasni_critter_fish_wet_aura_buff")
                    return retval > 0 and debuff and debuff.wetmult and debuff.wetmult > 0 and (retval * (1 + debuff.wetmult)) or retval
                end
            end
        end)
    end

    -- CC : Give Additional Luck >> [Reward] chasni_critter_light Passive
    local _GetEntityLuck = GetEntityLuck
    GLOBAL.GetEntityLuck = function(inst, ...)
        local function GetBuffLuck(_inst, buffname)
            local buff = _inst:GetDebuff(buffname)
            return buff and buff.luck or 0
        end

        local retval = _GetEntityLuck(inst, ...)
        local luck = GetBuffLuck(inst, "chasni_critter_light_on_aura_buff") - GetBuffLuck(inst, "chasni_critter_light_off_aura_buff")
        return (retval or 0) + luck
    end

    -- CC : Chance to not Unthaw frozen mobs >> [Reward] chasni_critter_mamo Passive
    local UpvalueHacker = require "functions/upvaluehacker"
    local Freezable = require("components/freezable")
    local function NewOnAttacked(inst, data)
        local self = inst.components.freezable
        if self:IsFrozen() and inst:IsValid() then
            local debuff = inst:GetDebuff("chasni_critter_mamo_aura_buff")
            local chance = debuff and debuff.chance
            if chance and chance > 0 and math.random() * 100 < chance  then
                return
            end
            self.damagetotal = self.damagetotal + math.abs(data.damage)

            if self.damagetotal >= self.damagetobreak then
                self:Unfreeze()
            end
        end
    end

    UpvalueHacker.SetUpvalue(Freezable.OnRemoveFromEntity, NewOnAttacked, "OnAttacked")

    -- CC : Chance to avoid damage on full health >> [Reward] chasni_critter_puff_health Passive
    AddComponentPostInit("health", function(Health)
        local OldDoDelta = Health.DoDelta
        Health.DoDelta = function(self, amount, ...)
            if self.inst:HasDebuff("chasni_critter_puff_health_aura_buff") then
                if amount < 0 and not self:IsHurt() then
                    local debuff = self.inst:GetDebuff("chasni_critter_puff_health_aura_buff")
                    local chance = debuff and debuff.chance
                    if chance and chance > 0 and math.random() * 100 < chance  then
                        amount = -1
                    end
                end
            end
            return OldDoDelta(self, amount, ...)
        end
    end)

    -- CC : Increase electrocute duration >> [Reward] chasni_critter_elecfish Passive
    local _CalcEntityElectrocuteDuration = CalcEntityElectrocuteDuration
    GLOBAL.CalcEntityElectrocuteDuration = function(inst, ...)
        local debuff = inst:GetDebuff("chasni_critter_elecfish_aura_buff")
        local mult = debuff and debuff.elecmult and debuff.elecmult > 0 and ((debuff.elecmult / 100) + 1) or 1
        return (_CalcEntityElectrocuteDuration(inst, ...) * mult)
    end

    -- CC : reduce Rechargeable Discharge time >> [Reward] chasni_critter_turtle Passive
    AddComponentPostInit("rechargeable", function(Rechargeable)
        local OldDischarge = Rechargeable.Discharge
        Rechargeable.Discharge = function(self, chargetime, ...)
            local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
            if owner and owner:HasDebuff("chasni_critter_turtle_aura_buff_active") then
                if chargetime > 0 then
                    local debuff = owner:GetDebuff("chasni_critter_turtle_aura_buff_active")
                    local cdreduction = debuff and debuff.cdreduction
                    if cdreduction and cdreduction > 0 then
                        chargetime = chargetime * (1 - (cdreduction / 100))
                    end
                end
            end
            return OldDischarge(self, chargetime, ...)
        end
    end)

    -- CC : force action GIVE to chasni_critter_bot when given memorycard >> [Reward] chasni_critter_bot Passive
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    local USEITEM = COMPONENT_ACTIONS.USEITEM
    local Inventory_inventoryitem = USEITEM.inventoryitem
    function USEITEM.inventoryitem(inst, doer, target, actions, ...)
        if target.prefab == "chasni_critter_bot" and inst.prefab and inst.prefab:match("^chasni_memorycard_(.+)$") then
            table.insert(actions, ACTIONS.GIVE)
            return
        end
        Inventory_inventoryitem(inst, doer, target, actions, ...)
    end
end