local UpvalueHacker = require "functions/upvaluehacker"

-- CC : add "bosshunter" component to create new kind of dirtpile >> [Reward] Boss Hunter
if not chasni_getperkexcludeconfig("bosshunting") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("world", function(inst)
            inst:AddComponent("bosshunter")
        end)
    end
end

-- CC : add "icyweed" to tumbleweedspawner child >> [Reward] Icy-Breezy
if not chasni_getperkexcludeconfig("icyweed") then
    AddComponentPostInit("childspawner", function(self)
        local oldSpawnChild = self.SpawnChild
        function self:SpawnChild(target, prefab, radius, ...)
            if self.winterable == true and TUNING.ACH["icyweed"] == 1 and TheWorld.state.iswinter then
                prefab = self.winterchild
            end
            return oldSpawnChild(self,target, prefab, radius, ...)
        end
        function self:Chasni_SetWinterChild(prefab)
            self.winterable = true
            self.winterchild = prefab
        end
    end)
    if TheNet:GetIsServer() then
        AddPrefabPostInit("tumbleweedspawner", function(inst)
            if inst.components.childspawner then
                inst.components.childspawner:Chasni_SetWinterChild("chasni_icyweed")
            end
        end)
    end

    -- CC : spawn "icyweed" when digging tree >> [Reward] Icy-Breezy
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            inst:ListenForEvent("finishedwork", function(_inst, data)
                if data.action == ACTIONS.DIG and data.target:HasTag("stump") and TUNING.ACH["icyweed"] == 1 and TheWorld.state.iswinter then
                    local x, y, z = data.target.Transform:GetWorldPosition()
                    chasni_spawnprefab("chasni_icyweed", x, y, z)
                end
            end)
        end)
    end
end

-- CC : rift toggle logic >> [Perk] Global Rift Control
if not chasni_getperkexcludeconfig("riftcontroller") then
    -- CC : add "forcerift" logic to yes >> [Perk] Global Rift Control
    AddComponentPostInit("riftspawner", function(self)
        local oldIsLunarPortalActive = self.IsLunarPortalActive
        function self:IsLunarPortalActive(target, prefab, radius, ...)
            if not self.inst:HasTag("cave") then
                if TUNING.ACH["riftcontroller"] == 1 then
                    return true
                elseif TUNING.ACH["riftcontroller"] == -1 then
                    return false
                end
            end
            return oldIsLunarPortalActive(self,target, prefab, radius, ...)
        end

        local oldIsShadowPortalActive = self.IsShadowPortalActive
        function self:IsShadowPortalActive(target, prefab, radius, ...)
            if self.inst:HasTag("cave") then
                if TUNING.ACH["riftcontroller"] == 1 then
                    return true
                elseif TUNING.ACH["riftcontroller"] == -1 then
                    return false
                end
            end
            return oldIsShadowPortalActive(self,target, prefab, radius, ...)
        end
    end)

    -- CC : make daywalker2 behave if lunar rift enabled (drop blueprints) || daywalker2->lootdropper:SetLootSetupFn >> [Perk] Global Rift Control
    local WAGPUNK_ITEMS = {
        "wagpunkhat",
        "armorwagpunk",
        "chestupgrade_stacksize",
        "wagpunkbits_kit",
    }
    AddSimPostInit(function()
        if GLOBAL.Prefabs["daywalker2"] then
            local oldlootsetfn = UpvalueHacker.GetUpvalue(GLOBAL.Prefabs.daywalker2.fn, "lootsetfn")
            local function lootsetfn(lootdropper, ...)
                if TUNING.ACH["riftcontroller"] == 1 then
                    local needstoknow
                    local inst_ = lootdropper.inst
                    for _, player in ipairs(AllPlayers) do
                        if player:GetDistanceSqToInst(inst_) <= 256 then -- 16 * 16 = 256 = 4 tiles
                            local builder = player.components.builder
                            for _, recipename in ipairs(WAGPUNK_ITEMS) do
                                if not builder:KnowsRecipe(recipename) then
                                    if needstoknow == nil then
                                        needstoknow = {}
                                    end
                                    needstoknow[recipename] = (needstoknow[recipename] or 0) + 1
                                end
                            end
                        end
                    end
                    if needstoknow then
                        -- Some one needs something make it only potentially drop these.
                        for recipename, _ in pairs(needstoknow) do
                            lootdropper:AddRandomLoot(recipename .. "_blueprint", 1)
                        end
                    else
                        -- No one needs anything make it random.
                        for _, recipename in ipairs(WAGPUNK_ITEMS) do
                            lootdropper:AddRandomLoot(recipename .. "_blueprint", 1)
                        end
                    end
                elseif TUNING.ACH["riftcontroller"] == -1 then
                    lootdropper:AddRandomLoot("wagpunkbits_kit", 1)
                else
                    return oldlootsetfn(lootdropper, ...)
                end
                lootdropper.numrandomloot = 1
            end
            UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.daywalker2.fn, lootsetfn, "lootsetfn")
        end
    end)
end

-- CC : make heatrock fueled did not changed with infinite thermalstone >> [Perk] Global Thermal Stone Redux
if not chasni_getperkexcludeconfig("eternalthermal") then
    AddComponentPostInit("fueled", function(self)
        local oldSetPercent = self.SetPercent
        function self:SetPercent(amount, ...)
            if TUNING.ACH["eternalthermal"] == 1 and amount < self:GetPercent() then
                return
            end
            return oldSetPercent(self,amount, ...)
        end
    end)
end

-- CC : force stackable to ignore IgnoreMaxSize >> [Perk] Global Max Stack
if not chasni_getperkexcludeconfig("stackinfinite") then
    AddPrefabPostInitAny(function(inst)
        if inst.components.inventoryitem and inst.components.stackable and TUNING.ACH["stackinfinite"] == 1 then
            inst.components.stackable:SetIgnoreMaxSize(true)
        end
    end)
    AddComponentPostInit("inventory", function(self)
        local _GiveItem = self.GiveItem
        self.GiveItem = function(_self, item, ...)
            if item and item.components.stackable and TUNING.ACH["stackinfinite"] == 1 then
                item.components.stackable:SetIgnoreMaxSize(true)
            end
            return _GiveItem(_self, item, ...)
        end
    end)
end

-- CC : force Insight Value by XP to 99 >> [Perk] Global insightinfinite
if not chasni_getperkexcludeconfig("insightinfinite") then
    local SkillTreeData = require("skilltreedata")
    local old_GetPointsForSkillXP = SkillTreeData.GetPointsForSkillXP
    function SkillTreeData:GetPointsForSkillXP(...)
        if AllPlayers and AllPlayers[1] and AllPlayers[1].currentinsightinfinite and AllPlayers[1].currentinsightinfinite:value() == 1 then
            return 99
        end
        return old_GetPointsForSkillXP(self, ...)
    end
    -- CC : forcing skilltreetoast to not show up when insightinfinite >> [Reward] Global insightinfinite
    AddClassPostConstruct("widgets/skilltreetoast",function(self)
        local _UpdateElements = self.UpdateElements
        function self:UpdateElements(...)
            _UpdateElements(self, ...)
            if AllPlayers and AllPlayers[1] and AllPlayers[1].currentinsightinfinite and AllPlayers[1].currentinsightinfinite:value() == 1 then
                local from = Vector3(0, -1, 0)
                self.opened = false
                local to = Vector3(0, 0, 0)
                self:DisableClick()
                if from ~= to then
                    if self:IsVisible() then
                        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/skin_drop_slide_gift_UP")
                    end

                    self.root:MoveTo(from, to, 0.5, function() self.controls:ManageToast(self, true) end)
                end
            end
        end
    end)
end

