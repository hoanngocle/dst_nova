-- CC : add edible mooneye and mooneye eater >> [Reward] expertwilson1
if not chasni_getperkexcludeconfig("expertwilson1") then
    FOODTYPE.MOONEYE = "MOONEYE"
    if TheNet:GetIsServer() then
        AddPrefabPostInit("wilson", function(inst)
            if inst.components.eater then
                local old_OnEat = inst.components.eater.oneatfn
                local _onEat = function(_inst, food, ...)
                    if old_OnEat then
                        old_OnEat(_inst, food, ...)
                    end
                    if food and food.components.edible then
                        if food.components.edible.foodtype == FOODTYPE.MOONEYE then
                            if _inst.components.mooneyeeater then
                                _inst.components.mooneyeeater:OnEatmooneyefn(food.prefab, 1)
                            end
                        end
                    end
                end
                if inst.components.eater then
                    inst.components.eater:SetOnEatFn(_onEat)
                    table.insert(inst.components.eater.preferseating, FOODTYPE.MOONEYE)
                    table.insert(inst.components.eater.caneat, FOODTYPE.MOONEYE)
                end
                inst:AddComponent("mooneyeeater")
            end
        end)
    end

    if TheNet:GetIsServer() then
        local function commonMoonEyeInit(inst)
            if inst.components.edible == nil then
                inst:AddComponent("edible")
                inst.components.edible.healthvalue = 0
                inst.components.edible.sanityvalue = 0
                inst.components.edible.hungervalue = 0
            end
            if inst.components.edible then
                inst:AddTag("edible_"..FOODTYPE.MOONEYE)
                inst.components.edible.foodtype = FOODTYPE.MOONEYE
            end
        end
        AddPrefabPostInit("redmooneye", commonMoonEyeInit)
        AddPrefabPostInit("bluemooneye", commonMoonEyeInit)
        AddPrefabPostInit("greenmooneye", commonMoonEyeInit)
        AddPrefabPostInit("yellowmooneye", commonMoonEyeInit)
        AddPrefabPostInit("orangemooneye", commonMoonEyeInit)
        AddPrefabPostInit("purplemooneye", commonMoonEyeInit)
    end
end

-- CC : add gem inventory checker >> [Reward] expertwilson2
if not chasni_getperkexcludeconfig("expertwilson2") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("wilson", function(inst)
            inst.purplegem_count = 0
            inst.orangegem_count = 0
            inst.yellowgem_count = 0
            inst.greengem_count = 0
            local gemlist = { "purplegem", "orangegem", "yellowgem", "greengem",}
            local refreshInventory = function()
                for _, v in ipairs(gemlist) do
                    local _, count = inst.components.inventory:Has(v, 1)
                    inst[v.."_count"] = count
                end
                local _, count = inst.components.inventory:Has("opalpreciousgem", 1)
                inst.orangegem_count = inst.orangegem_count + count
                inst.yellowgem_count = inst.yellowgem_count + count
                inst.greengem_count = inst.greengem_count + count
            end
            local function refreshInventoryDelay(_inst) _inst:DoTaskInTime(.1, refreshInventory) end
            inst:ListenForEvent("itemget", refreshInventoryDelay)
            inst:ListenForEvent("gotnewitem", refreshInventoryDelay)
            inst:ListenForEvent("itemlose", refreshInventoryDelay)
            inst:ListenForEvent("dropitem", refreshInventoryDelay)
            inst:DoPeriodicTask(1, function()
                if inst.greengem_count > 0 and inst.components.allachivcoin and inst.components.allachivcoin.expertwilson2 then
                    inst.components.health:DoDelta(math.min(inst.greengem_count/100, 5), true, "regen")
                end
            end)
            inst:DoPeriodicTask(1, function()
                if inst.purplegem_count > 0 and inst.components.allachivcoin and inst.components.allachivcoin.expertwilson2 then
                    inst.components.sanity:DoDelta(math.max(-inst.purplegem_count/25, -20))
                end
            end)
            inst:DoPeriodicTask(1, function()
                if inst.yellowgem_count > 0 and inst.components.allachivcoin and inst.components.allachivcoin.expertwilson2 then
                    inst.components.sanity:DoDelta(math.min(inst.yellowgem_count/100, 15))
                end
            end)
            inst:DoPeriodicTask(1, function()
                if inst.orangegem_count > 0 and inst.components.allachivcoin and inst.components.allachivcoin.expertwilson2 then
                    inst.components.hunger:DoDelta(math.min(inst.orangegem_count/100, 10), true, "regen")
                end
            end)
        end)
    end

    AddComponentPostInit("temperature", function(self)
        local _GetInsulation = self.GetInsulation
        self.GetInsulation = function()
            local winterInsulation, summerInsulation = _GetInsulation(self)
            if self.inst.components.allachivcoin and self.inst.components.allachivcoin.expertwilson2 and self.inst.components.inventory then
                local has, count = self.inst.components.inventory:Has("opalpreciousgem", 1)
                local has1, count1 = self.inst.components.inventory:Has("redgem", 1)
                if has1 or has then summerInsulation = summerInsulation + math.min((count1 + count) * 5, 500) end
                local has2, count2 = self.inst.components.inventory:Has("bluegem", 1)
                if has2 or has then winterInsulation = winterInsulation + math.min((count2 + count) * 5, 500) end
            end
            return math.max(0, winterInsulation), math.max(0, summerInsulation)
        end
    end)
end
